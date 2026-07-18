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

public class AktivnostVolonteraService : IAktivnostVolonteraService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;

    public AktivnostVolonteraService(DogShelterContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    private IQueryable<Database.AktivnostVolontera> BaseQuery() =>
        _context.AktivnostVolonteras
            .Include(a => a.Volonter).ThenInclude(v => v.Korisnik)
            .Include(a => a.TipAktivnosti)
            .AsNoTracking();

    public async Task<PagedResult<Model.AktivnostVolontera>> Get(AktivnostVolonteraSearchRequest search, int callerKorisnikId, bool isAdmin)
    {
        var query = BaseQuery();

        if (isAdmin)
        {
            if (search.VolonterId.HasValue)
                query = query.Where(a => a.VolonterId == search.VolonterId.Value);
        }
        else
        {
            var volonterId = await GetVolonterIdForKorisnikAsync(callerKorisnikId);
            query = query.Where(a => a.VolonterId == volonterId);
        }

        if (search.TipAktivnostiId.HasValue)
            query = query.Where(a => a.TipAktivnostiId == search.TipAktivnostiId.Value);

        if (search.DatumOd.HasValue)
            query = query.Where(a => a.DatumAktivnosti >= search.DatumOd.Value);

        if (search.DatumDo.HasValue)
            query = query.Where(a => a.DatumAktivnosti <= search.DatumDo.Value);

        query = query.OrderByDescending(a => a.DatumAktivnosti);

        return await PagedQueryHelper.ToPagedResultAsync<Database.AktivnostVolontera, Model.AktivnostVolontera>(query, search, _mapper);
    }

    public async Task<Model.AktivnostVolontera> GetById(int id)
    {
        var entity = await BaseQuery().FirstOrDefaultAsync(a => a.AktivnostVolonteraId == id)
            ?? throw new NotFoundException($"Aktivnost volontera s ID {id} nije pronađena.");

        return _mapper.Map<Model.AktivnostVolontera>(entity);
    }

    public async Task<Model.AktivnostVolontera> Insert(AktivnostVolonteraInsertRequest request, int callerKorisnikId, bool isAdmin)
    {
        int volonterId;
        if (isAdmin && request.VolonterId.HasValue)
        {
            volonterId = request.VolonterId.Value;
            if (!await _context.Volonters.AnyAsync(v => v.VolonterId == volonterId))
                throw new ValidationException("Odabrani volonter ne postoji.", nameof(request.VolonterId), "Volonter ne postoji.");
        }
        else
        {
            volonterId = await GetVolonterIdForKorisnikAsync(callerKorisnikId);
        }

        if (!await _context.TipAktivnostis.AnyAsync(t => t.TipAktivnostiId == request.TipAktivnostiId))
            throw new ValidationException("Odabrani tip aktivnosti ne postoji.", nameof(request.TipAktivnostiId), "Tip aktivnosti ne postoji.");

        var entity = new Database.AktivnostVolontera
        {
            VolonterId = volonterId,
            TipAktivnostiId = request.TipAktivnostiId,
            DatumAktivnosti = request.DatumAktivnosti,
            BrojSati = request.BrojSati,
            Opis = request.Opis
        };

        _context.AktivnostVolonteras.Add(entity);
        await _context.SaveChangesAsync();

        return await GetById(entity.AktivnostVolonteraId);
    }

    public async Task<bool> Delete(int id)
    {
        var entity = await _context.AktivnostVolonteras.FindAsync(id)
            ?? throw new NotFoundException($"Aktivnost volontera s ID {id} nije pronađena.");

        _context.AktivnostVolonteras.Remove(entity);
        await _context.SaveChangesAsync();

        return true;
    }

    private async Task<int> GetVolonterIdForKorisnikAsync(int korisnikId)
    {
        var volonter = await _context.Volonters.FirstOrDefaultAsync(v => v.KorisnikId == korisnikId)
            ?? throw new BusinessException("Nemate evidentiran volonterski profil.");

        return volonter.VolonterId;
    }

    public async Task<AktivnostVolonteraIzvjestaj> GenerirajIzvjestaj(DateTime? datumOd, DateTime? datumDo)
    {
        var query = _context.AktivnostVolonteras.AsNoTracking().AsQueryable();

        if (datumOd.HasValue)
        {
            var od = DateOnly.FromDateTime(datumOd.Value);
            query = query.Where(a => a.DatumAktivnosti >= od);
        }

        if (datumDo.HasValue)
        {
            var doDatuma = DateOnly.FromDateTime(datumDo.Value);
            query = query.Where(a => a.DatumAktivnosti <= doDatuma);
        }

        var podaci = await query
            .Select(a => new { a.DatumAktivnosti, a.BrojSati })
            .ToListAsync();

        var poMjesecu = podaci
            .GroupBy(p => new { p.DatumAktivnosti.Year, p.DatumAktivnosti.Month })
            .Select(g => new MjesecSatiStavka
            {
                Godina = g.Key.Year,
                Mjesec = g.Key.Month,
                MjesecNaziv = MjeseciNazivi.Naziv(g.Key.Month),
                BrojAktivnosti = g.Count(),
                UkupnoSati = g.Sum(x => x.BrojSati)
            })
            .OrderBy(x => x.Godina).ThenBy(x => x.Mjesec)
            .ToList();

        return new AktivnostVolonteraIzvjestaj
        {
            DatumOd = datumOd,
            DatumDo = datumDo,
            PoMjesecima = poMjesecu,
            UkupnoAktivnosti = podaci.Count,
            UkupnoSati = podaci.Sum(p => p.BrojSati)
        };
    }
}
