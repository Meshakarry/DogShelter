using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class PasService : IPasService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;
    private readonly IFileUploadService _fileUpload;

    public PasService(DogShelterContext context, IMapper mapper, IFileUploadService fileUpload)
    {
        _context = context;
        _mapper = mapper;
        _fileUpload = fileUpload;
    }

    public async Task<PagedResult<Model.PasListItem>> Get(PasSearchRequest search)
    {
        // List view: no SlikaPsas include and no Opis mapping — full gallery/description
        // are only returned by GetById, per the "list endpoints must not return large payloads" rule.
        var query = _context.Pas
            .Include(p => p.Rasa)
            .Include(p => p.StatusPsa)
            .Include(p => p.VelicinaPsa)
            .AsNoTracking()
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search.Naziv))
            query = query.Where(p => p.Naziv.Contains(search.Naziv));

        if (search.RasaId.HasValue)
            query = query.Where(p => p.RasaId == search.RasaId.Value);

        if (search.StatusPsaId.HasValue)
            query = query.Where(p => p.StatusPsaId == search.StatusPsaId.Value);

        if (search.VelicinaPsaId.HasValue)
            query = query.Where(p => p.VelicinaPsaId == search.VelicinaPsaId.Value);

        if (search.Spol.HasValue)
            query = query.Where(p => p.Spol == search.Spol.Value);

        if (search.Aktivan.HasValue)
            query = query.Where(p => p.Aktivan == search.Aktivan.Value);

        if (search.Vakcinisan.HasValue)
            query = query.Where(p => p.Vakcinisan == search.Vakcinisan.Value);

        if (search.Sterilizovan.HasValue)
            query = query.Where(p => p.Sterilizovan == search.Sterilizovan.Value);

        query = query.OrderByDescending(p => p.DatumPrijema);

        return await PagedQueryHelper.ToPagedResultAsync<Database.Pas, Model.PasListItem>(query, search, _mapper);
    }

    public async Task<Model.Pas> GetById(int id)
    {
        var entity = await _context.Pas
            .Include(p => p.Rasa)
            .Include(p => p.StatusPsa)
            .Include(p => p.VelicinaPsa)
            .Include(p => p.SlikaPsas)
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.PasId == id)
            ?? throw new NotFoundException($"Pas s ID {id} nije pronađen.");

        return _mapper.Map<Model.Pas>(entity);
    }

    public async Task<Model.Pas> InsertWithImage(PasInsertRequest request, IFormFile? cover)
    {
        await ValidateForeignKeysAsync(request.RasaId, request.StatusPsaId, request.VelicinaPsaId);

        var entity = _mapper.Map<Database.Pas>(request);
        entity.Aktivan = true;

        if (cover != null)
            entity.SlikaNaslovna = await _fileUpload.SaveImageAsync(cover, "psi");

        _context.Pas.Add(entity);
        await _context.SaveChangesAsync();

        return await GetById(entity.PasId);
    }

    public async Task<Model.Pas> UpdateWithImage(int id, PasUpdateRequest request, IFormFile? cover)
    {
        var entity = await _context.Pas.FindAsync(id)
            ?? throw new NotFoundException($"Pas s ID {id} nije pronađen.");

        await ValidateForeignKeysAsync(request.RasaId, request.StatusPsaId, request.VelicinaPsaId);

        var oldCover = entity.SlikaNaslovna;
        _mapper.Map(request, entity);

        if (cover != null)
        {
            _fileUpload.DeleteImage(oldCover);
            entity.SlikaNaslovna = await _fileUpload.SaveImageAsync(cover, "psi");
        }
        else
        {
            // preserve existing cover when no new file is provided
            entity.SlikaNaslovna = oldCover;
        }

        await _context.SaveChangesAsync();

        return await GetById(id);
    }

    public async Task<bool> Delete(int id)
    {
        var entity = await _context.Pas.FindAsync(id)
            ?? throw new NotFoundException($"Pas s ID {id} nije pronađen.");

        entity.Aktivan = false;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<Model.SlikaPsa> AddSlika(int pasId, IFormFile file, int redniBroj)
    {
        if (!await _context.Pas.AnyAsync(p => p.PasId == pasId))
            throw new NotFoundException($"Pas s ID {pasId} nije pronađen.");

        var path = await _fileUpload.SaveImageAsync(file, "psi");

        var slika = new Database.SlikaPsa
        {
            PasId = pasId,
            Putanja = path,
            RedniBroj = redniBroj
        };

        _context.SlikaPsas.Add(slika);
        await _context.SaveChangesAsync();

        return _mapper.Map<Model.SlikaPsa>(slika);
    }

    public async Task<bool> RemoveSlika(int slikaId)
    {
        var slika = await _context.SlikaPsas.FindAsync(slikaId)
            ?? throw new NotFoundException($"Slika s ID {slikaId} nije pronađena.");

        _fileUpload.DeleteImage(slika.Putanja);
        _context.SlikaPsas.Remove(slika);
        await _context.SaveChangesAsync();
        return true;
    }

    private async Task ValidateForeignKeysAsync(int rasaId, int statusPsaId, int velicinaPsaId)
    {
        if (!await _context.Rasas.AnyAsync(r => r.RasaId == rasaId))
            throw new ValidationException("Odabrana rasa ne postoji.", nameof(rasaId), "Rasa ne postoji.");

        if (!await _context.StatusPsas.AnyAsync(s => s.StatusPsaId == statusPsaId))
            throw new ValidationException("Odabrani status ne postoji.", nameof(statusPsaId), "Status ne postoji.");

        if (!await _context.VelicinaPsas.AnyAsync(v => v.VelicinaPsaId == velicinaPsaId))
            throw new ValidationException("Odabrana veličina ne postoji.", nameof(velicinaPsaId), "Veličina ne postoji.");
    }
}
