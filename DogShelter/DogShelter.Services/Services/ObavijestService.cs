using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Constants;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class ObavijestService : IObavijestService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;
    private readonly IFileUploadService _fileUpload;
    private readonly INotifikacijaService _notifikacijaService;

    public ObavijestService(DogShelterContext context, IMapper mapper, IFileUploadService fileUpload, INotifikacijaService notifikacijaService)
    {
        _context = context;
        _mapper = mapper;
        _fileUpload = fileUpload;
        _notifikacijaService = notifikacijaService;
    }

    public async Task<PagedResult<Model.ObavijestListItem>> Get(ObavijestSearchRequest search, bool isAdmin)
    {
        // List view omits Sadrzaj (full text) to keep payloads small; full text is returned
        // only by GetById.
        var query = _context.Obavijests
            .Include(o => o.Autor)
            .AsNoTracking()
            .AsQueryable();

        if (!isAdmin)
            query = query.Where(o => o.Aktivna);
        else if (search.Aktivna.HasValue)
            query = query.Where(o => o.Aktivna == search.Aktivna.Value);

        if (!string.IsNullOrWhiteSpace(search.Naslov))
            query = query.Where(o => o.Naslov.Contains(search.Naslov));

        if (search.AutorId.HasValue)
            query = query.Where(o => o.AutorId == search.AutorId.Value);

        if (search.DatumOd.HasValue)
            query = query.Where(o => o.DatumObjave >= search.DatumOd.Value);

        if (search.DatumDo.HasValue)
            query = query.Where(o => o.DatumObjave <= search.DatumDo.Value);

        query = query.OrderByDescending(o => o.DatumObjave);

        return await PagedQueryHelper.ToPagedResultAsync<Database.Obavijest, Model.ObavijestListItem>(query, search, _mapper);
    }

    public async Task<Model.Obavijest> GetById(int id, bool isAdmin)
    {
        var entity = await _context.Obavijests
            .Include(o => o.Autor)
            .AsNoTracking()
            .FirstOrDefaultAsync(o => o.ObavijestId == id)
            ?? throw new NotFoundException($"Obavijest s ID {id} nije pronađena.");

        // Non-admins may never see drafts, including by direct ID guess.
        if (!isAdmin && !entity.Aktivna)
            throw new NotFoundException($"Obavijest s ID {id} nije pronađena.");

        return _mapper.Map<Model.Obavijest>(entity);
    }

    public async Task<Model.Obavijest> InsertWithImage(ObavijestInsertRequest request, int autorId, IFormFile? slika)
    {
        if (!await _context.Korisniks.AnyAsync(k => k.KorisnikId == autorId))
            throw new ValidationException("Autor ne postoji.", nameof(autorId), "Korisnik ne postoji.");

        if (slika == null)
            throw new ValidationException("Slika je obavezna.", "slika", "Slika je obavezna za objavu.");

        var entity = _mapper.Map<Database.Obavijest>(request);
        entity.AutorId = autorId;
        entity.DatumObjave = DateTime.UtcNow;
        entity.SlikaPutanja = await _fileUpload.SaveImageAsync(slika, "obavijesti");

        // Notifying requires ObavijestId, which EF only assigns after the insert commits —
        // wrapped in a transaction since this is genuinely two SaveChangesAsync calls.
        await using var transaction = await _context.Database.BeginTransactionAsync();

        _context.Obavijests.Add(entity);
        await _context.SaveChangesAsync();

        if (entity.Aktivna)
        {
            await StageObavijestObjavljenaNotifikacijeAsync(entity);
            await _context.SaveChangesAsync();
        }

        await transaction.CommitAsync();

        return await GetById(entity.ObavijestId, isAdmin: true);
    }

    public async Task<Model.Obavijest> UpdateWithImage(int id, ObavijestUpdateRequest request, IFormFile? slika)
    {
        var entity = await _context.Obavijests.FindAsync(id)
            ?? throw new NotFoundException($"Obavijest s ID {id} nije pronađena.");

        var wasPublished = entity.Aktivna;
        var oldSlika = entity.SlikaPutanja;

        _mapper.Map(request, entity);

        // Publishing a draft stamps the publish date; editing an already-published
        // announcement must not bump it.
        if (!wasPublished && request.Aktivna)
        {
            entity.DatumObjave = DateTime.UtcNow;
            await StageObavijestObjavljenaNotifikacijeAsync(entity);
        }

        if (slika != null)
        {
            _fileUpload.DeleteImage(oldSlika);
            entity.SlikaPutanja = await _fileUpload.SaveImageAsync(slika, "obavijesti");
        }
        else
        {
            entity.SlikaPutanja = oldSlika;
        }

        await _context.SaveChangesAsync();

        return await GetById(id, isAdmin: true);
    }

    public async Task<bool> Delete(int id)
    {
        var entity = await _context.Obavijests.FindAsync(id)
            ?? throw new NotFoundException($"Obavijest s ID {id} nije pronađena.");

        _fileUpload.DeleteImage(entity.SlikaPutanja);
        _context.Obavijests.Remove(entity);
        await _context.SaveChangesAsync();
        return true;
    }

    private async Task StageObavijestObjavljenaNotifikacijeAsync(Database.Obavijest entity)
    {
        var tekst = $"Objavljena je nova obavijest: \"{entity.Naslov}\".";

        await _notifikacijaService.StageCreateForRoleAsync(RoleNames.Korisnik, NotifikacijaTipovi.ObavijestObjavljena, "Nova obavijest", tekst, entity.ObavijestId);
        await _notifikacijaService.StageCreateForRoleAsync(RoleNames.Volonter, NotifikacijaTipovi.ObavijestObjavljena, "Nova obavijest", tekst, entity.ObavijestId);
    }
}
