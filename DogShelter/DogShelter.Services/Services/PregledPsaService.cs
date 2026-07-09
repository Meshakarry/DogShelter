using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class PregledPsaService : IPregledPsaService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;

    public PregledPsaService(DogShelterContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<PagedResult<Model.PregledPsa>> Get(PregledPsaSearchRequest search)
    {
        var query = _context.PregledPsas.AsNoTracking().AsQueryable();

        if (search.KorisnikId.HasValue)
            query = query.Where(p => p.KorisnikId == search.KorisnikId.Value);

        if (search.PasId.HasValue)
            query = query.Where(p => p.PasId == search.PasId.Value);

        if (search.OdDatuma.HasValue)
            query = query.Where(p => p.DatumPregleda >= search.OdDatuma.Value);

        if (search.DoDatuma.HasValue)
            query = query.Where(p => p.DatumPregleda <= search.DoDatuma.Value);

        query = query.OrderByDescending(p => p.DatumPregleda);

        var (page, pageSize) = PaginationHelper.Normalize(search);
        var total = await query.CountAsync();
        var entities = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        return new PagedResult<Model.PregledPsa>
        {
            Items = _mapper.Map<List<Model.PregledPsa>>(entities),
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<Model.PregledPsa> LogPregled(int pasId, int korisnikId)
    {
        if (!await _context.Pas.AnyAsync(p => p.PasId == pasId))
            throw new NotFoundException($"Pas s ID {pasId} nije pronađen.");

        if (!await _context.Korisniks.AnyAsync(k => k.KorisnikId == korisnikId))
            throw new NotFoundException($"Korisnik s ID {korisnikId} nije pronađen.");

        var pregled = new Database.PregledPsa
        {
            PasId = pasId,
            KorisnikId = korisnikId,
            DatumPregleda = DateTime.UtcNow
        };

        _context.PregledPsas.Add(pregled);
        await _context.SaveChangesAsync();

        return _mapper.Map<Model.PregledPsa>(pregled);
    }
}
