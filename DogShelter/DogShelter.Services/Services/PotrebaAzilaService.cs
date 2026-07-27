using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class PotrebaAzilaService : IPotrebaAzilaService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;

    public PotrebaAzilaService(DogShelterContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    private IQueryable<Database.PotrebaAzila> BaseQuery() =>
        _context.PotrebeAzila
            .Include(p => p.PrioritetPotrebe)
            .AsNoTracking();

    public async Task<PagedResult<Model.PotrebaAzila>> Get(PotrebaAzilaSearchRequest search, bool isAdmin)
    {
        var query = BaseQuery();

        // Donors only ever see currently-active needs; admins can see everything and filter,
        // same visibility split precedent as Obavijest (draft/published).
        if (!isAdmin)
            query = query.Where(p => p.Aktivna);
        else if (search.Aktivna.HasValue)
            query = query.Where(p => p.Aktivna == search.Aktivna.Value);

        if (!string.IsNullOrWhiteSpace(search.Naziv))
            query = query.Where(p => p.Naziv.Contains(search.Naziv));

        if (search.PrioritetPotrebeId.HasValue)
            query = query.Where(p => p.PrioritetPotrebeId == search.PrioritetPotrebeId.Value);

        query = query.OrderByDescending(p => p.DatumKreiranja);

        return await PagedQueryHelper.ToPagedResultAsync<Database.PotrebaAzila, Model.PotrebaAzila>(query, search, _mapper);
    }

    public async Task<Model.PotrebaAzila> GetById(int id)
    {
        var entity = await BaseQuery().FirstOrDefaultAsync(p => p.PotrebaAzilaId == id)
            ?? throw new NotFoundException($"Potreba azila s ID {id} nije pronađena.");

        return _mapper.Map<Model.PotrebaAzila>(entity);
    }

    public async Task<Model.PotrebaAzila> Insert(PotrebaAzilaInsertRequest request)
    {
        if (!await _context.PrioritetPotrebes.AnyAsync(p => p.PrioritetPotrebeId == request.PrioritetPotrebeId))
            throw new ValidationException("Odabrani prioritet ne postoji.", nameof(request.PrioritetPotrebeId), "Prioritet ne postoji.");

        var entity = _mapper.Map<Database.PotrebaAzila>(request);
        entity.DatumKreiranja = DateTime.UtcNow;

        _context.PotrebeAzila.Add(entity);
        await _context.SaveChangesAsync();

        return await GetById(entity.PotrebaAzilaId);
    }

    public async Task<Model.PotrebaAzila> Update(int id, PotrebaAzilaUpdateRequest request)
    {
        var entity = await _context.PotrebeAzila.FindAsync(id)
            ?? throw new NotFoundException($"Potreba azila s ID {id} nije pronađena.");

        if (!await _context.PrioritetPotrebes.AnyAsync(p => p.PrioritetPotrebeId == request.PrioritetPotrebeId))
            throw new ValidationException("Odabrani prioritet ne postoji.", nameof(request.PrioritetPotrebeId), "Prioritet ne postoji.");

        _mapper.Map(request, entity);
        await _context.SaveChangesAsync();

        return await GetById(id);
    }

    public async Task<bool> Delete(int id)
    {
        var entity = await _context.PotrebeAzila.FindAsync(id)
            ?? throw new NotFoundException($"Potreba azila s ID {id} nije pronađena.");

        _context.PotrebeAzila.Remove(entity);
        await _context.SaveChangesAsync();
        return true;
    }
}
