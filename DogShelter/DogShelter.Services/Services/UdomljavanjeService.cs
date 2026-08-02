using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Reports;
using DogShelter.Model.Requests;
using DogShelter.Services.Constants;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class UdomljavanjeService : IUdomljavanjeService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;

    public UdomljavanjeService(DogShelterContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    private IQueryable<Database.Udomljavanje> BaseQuery() =>
        _context.Udomljavanjes
            .Include(u => u.ZahtjevZaUdomljavanje).ThenInclude(z => z.Pas)
            .Include(u => u.ZahtjevZaUdomljavanje).ThenInclude(z => z.Korisnik)
            .AsNoTracking();

    public async Task<PagedResult<Model.Udomljavanje>> Get(UdomljavanjeSearchRequest search, int currentKorisnikId, bool isAdmin)
    {
        var query = BaseQuery();

        var korisnikFilter = isAdmin ? search.KorisnikId : currentKorisnikId;
        if (korisnikFilter.HasValue)
            query = query.Where(u => u.ZahtjevZaUdomljavanje.KorisnikId == korisnikFilter.Value);

        if (search.PasId.HasValue)
            query = query.Where(u => u.ZahtjevZaUdomljavanje.PasId == search.PasId.Value);

        if (search.DatumOd.HasValue)
        {
            var od = DateOnly.FromDateTime(search.DatumOd.Value);
            query = query.Where(u => u.DatumUdomljavanja >= od);
        }

        if (search.DatumDo.HasValue)
        {
            var doDatuma = DateOnly.FromDateTime(search.DatumDo.Value);
            query = query.Where(u => u.DatumUdomljavanja <= doDatuma);
        }

        query = query.OrderByDescending(u => u.DatumUdomljavanja);

        return await PagedQueryHelper.ToPagedResultAsync<Database.Udomljavanje, Model.Udomljavanje>(query, search, _mapper);
    }

    public async Task<Model.Udomljavanje> GetById(int id, int currentKorisnikId, bool isAdmin)
    {
        var entity = await BaseQuery().FirstOrDefaultAsync(u => u.UdomljavanjeId == id)
            ?? throw new NotFoundException($"Udomljavanje s ID {id} nije pronađeno.");

        if (!isAdmin && entity.ZahtjevZaUdomljavanje.KorisnikId != currentKorisnikId)
            throw new ForbiddenException("Nemate pristup ovom zapisu.");

        return _mapper.Map<Model.Udomljavanje>(entity);
    }

    public async Task<UdomljavanjeIzvjestaj> GenerirajIzvjestaj(DateTime? datumOd, DateTime? datumDo)
    {
        var query = _context.Udomljavanjes
            .Include(u => u.ZahtjevZaUdomljavanje).ThenInclude(z => z.Pas).ThenInclude(p => p.Rasa)
            .AsNoTracking()
            .AsQueryable();

        if (datumOd.HasValue)
        {
            var od = DateOnly.FromDateTime(datumOd.Value);
            query = query.Where(u => u.DatumUdomljavanja >= od);
        }

        if (datumDo.HasValue)
        {
            var doDatuma = DateOnly.FromDateTime(datumDo.Value);
            query = query.Where(u => u.DatumUdomljavanja <= doDatuma);
        }

        var podaci = await query
            .Select(u => new { Rasa = u.ZahtjevZaUdomljavanje.Pas.Rasa.Naziv, u.DatumUdomljavanja })
            .ToListAsync();

        var poRasi = podaci
            .GroupBy(p => p.Rasa)
            .Select(g => new RasaBrojStavka { Rasa = g.Key, Broj = g.Count() })
            .OrderByDescending(x => x.Broj)
            .ThenBy(x => x.Rasa)
            .ToList();

        var poMjesecu = podaci
            .GroupBy(p => new { p.DatumUdomljavanja.Year, p.DatumUdomljavanja.Month })
            .Select(g => new MjesecBrojStavka
            {
                Godina = g.Key.Year,
                Mjesec = g.Key.Month,
                MjesecNaziv = MjeseciNazivi.Naziv(g.Key.Month),
                Broj = g.Count()
            })
            .OrderBy(x => x.Godina).ThenBy(x => x.Mjesec)
            .ToList();

        return new UdomljavanjeIzvjestaj
        {
            DatumOd = datumOd,
            DatumDo = datumDo,
            NajcescePoRasi = poRasi,
            PoMjesecima = poMjesecu,
            Ukupno = podaci.Count
        };
    }
}
