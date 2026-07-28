using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class DogadjajService : IDogadjajService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;
    private readonly IFileUploadService _fileUpload;

    public DogadjajService(DogShelterContext context, IMapper mapper, IFileUploadService fileUpload)
    {
        _context = context;
        _mapper = mapper;
        _fileUpload = fileUpload;
    }

    public async Task<PagedResult<Model.Dogadjaj>> Get(DogadjajSearchRequest search, bool isAdmin)
    {
        var query = _context.Dogadjajs.AsNoTracking().AsQueryable();

        if (!isAdmin)
        {
            // Non-admins may browse past events too (mobile's "Nadolazeći"/"Prošli" tabs both use
            // this endpoint via DatumOd/DatumDo below) — cancelled events stay hidden though, the
            // same way Obavijest hides drafts.
            query = query.Where(d => d.Aktivan);
        }
        else if (search.Aktivan.HasValue)
        {
            query = query.Where(d => d.Aktivan == search.Aktivan.Value);
        }

        if (!string.IsNullOrWhiteSpace(search.Naziv))
            query = query.Where(d => d.Naziv.Contains(search.Naziv));

        if (search.DatumOd.HasValue)
            query = query.Where(d => d.Datum >= search.DatumOd.Value);

        if (search.DatumDo.HasValue)
            query = query.Where(d => d.Datum <= search.DatumDo.Value);

        // A DatumDo-only filter (no DatumOd) means "browsing past events" (mobile's Prošli tab) —
        // most-recent-first reads more naturally there than the default soonest-first order.
        var isPastOnlyQuery = search.DatumDo.HasValue && !search.DatumOd.HasValue;
        query = isPastOnlyQuery ? query.OrderByDescending(d => d.Datum) : query.OrderBy(d => d.Datum);

        var result = await PagedQueryHelper.ToPagedResultAsync<Database.Dogadjaj, Model.Dogadjaj>(query, search, _mapper);

        await AttachBrojVolonteraAsync(result.Items);

        return result;
    }

    public async Task<Model.Dogadjaj> GetById(int id, bool isAdmin)
    {
        var entity = await _context.Dogadjajs.AsNoTracking().FirstOrDefaultAsync(d => d.DogadjajId == id)
            ?? throw new NotFoundException($"Događaj s ID {id} nije pronađen.");

        if (!isAdmin && !entity.Aktivan)
            throw new NotFoundException($"Događaj s ID {id} nije pronađen.");

        var model = _mapper.Map<Model.Dogadjaj>(entity);
        await AttachBrojVolonteraAsync([model]);

        return model;
    }

    public async Task<Model.Dogadjaj> InsertWithImage(DogadjajInsertRequest request, IFormFile? slika)
    {
        var entity = _mapper.Map<Database.Dogadjaj>(request);

        if (slika != null)
            entity.SlikaPutanja = await _fileUpload.SaveImageAsync(slika, "dogadjaji");

        _context.Dogadjajs.Add(entity);
        await _context.SaveChangesAsync();

        return await GetById(entity.DogadjajId, isAdmin: true);
    }

    public async Task<Model.Dogadjaj> UpdateWithImage(int id, DogadjajUpdateRequest request, IFormFile? slika)
    {
        var entity = await _context.Dogadjajs.FindAsync(id)
            ?? throw new NotFoundException($"Događaj s ID {id} nije pronađen.");

        var oldSlika = entity.SlikaPutanja;
        _mapper.Map(request, entity);

        if (slika != null)
        {
            _fileUpload.DeleteImage(oldSlika);
            entity.SlikaPutanja = await _fileUpload.SaveImageAsync(slika, "dogadjaji");
        }
        else
        {
            entity.SlikaPutanja = oldSlika;
        }

        await _context.SaveChangesAsync();

        return await GetById(id, isAdmin: true);
    }

    public async Task<bool> Otkazi(int id)
    {
        var entity = await _context.Dogadjajs.FindAsync(id)
            ?? throw new NotFoundException($"Događaj s ID {id} nije pronađen.");

        if (!entity.Aktivan)
            throw new BusinessException("Događaj je već otkazan.");

        entity.Aktivan = false;
        await _context.SaveChangesAsync();

        return true;
    }

    private async Task AttachBrojVolonteraAsync(IReadOnlyCollection<Model.Dogadjaj> dogadjaji)
    {
        if (dogadjaji.Count == 0) return;

        var ids = dogadjaji.Select(d => d.DogadjajId).ToList();
        var brojevi = await _context.DogadjajVolonters
            .Where(dv => ids.Contains(dv.DogadjajId))
            .GroupBy(dv => dv.DogadjajId)
            .Select(g => new { DogadjajId = g.Key, Broj = g.Count() })
            .ToDictionaryAsync(x => x.DogadjajId, x => x.Broj);

        foreach (var d in dogadjaji)
            d.BrojZaduzenihVolontera = brojevi.TryGetValue(d.DogadjajId, out var broj) ? broj : 0;
    }
}
