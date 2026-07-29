using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Constants;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class PosjetaService : IPosjetaService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;
    private readonly INotifikacijaService _notifikacijaService;

    public PosjetaService(DogShelterContext context, IMapper mapper, INotifikacijaService notifikacijaService)
    {
        _context = context;
        _mapper = mapper;
        _notifikacijaService = notifikacijaService;
    }

    private IQueryable<Database.Posjeta> BaseQuery() =>
        _context.Posjeta
            .Include(p => p.Korisnik)
            .Include(p => p.Pas)
            .Include(p => p.StatusPosjete)
            .Include(p => p.ObradioKorisnik)
            .AsNoTracking();

    public async Task<PagedResult<Model.Posjeta>> Get(PosjetaSearchRequest search, int currentKorisnikId, bool isAdmin)
    {
        var query = BaseQuery();

        var korisnikFilter = isAdmin ? search.KorisnikId : currentKorisnikId;
        if (korisnikFilter.HasValue)
            query = query.Where(p => p.KorisnikId == korisnikFilter.Value);

        if (search.PasId.HasValue)
            query = query.Where(p => p.PasId == search.PasId.Value);

        if (search.StatusPosjeteId.HasValue)
            query = query.Where(p => p.StatusPosjeteId == search.StatusPosjeteId.Value);

        if (search.DatumOd.HasValue)
            query = query.Where(p => p.DatumVrijeme >= search.DatumOd.Value);

        if (search.DatumDo.HasValue)
            query = query.Where(p => p.DatumVrijeme <= search.DatumDo.Value);

        query = query.OrderByDescending(p => p.DatumVrijeme);

        return await PagedQueryHelper.ToPagedResultAsync<Database.Posjeta, Model.Posjeta>(query, search, _mapper);
    }

    public async Task<Model.Posjeta> GetById(int id)
    {
        var entity = await BaseQuery().FirstOrDefaultAsync(p => p.PosjetaId == id)
            ?? throw new NotFoundException($"Posjeta s ID {id} nije pronađena.");

        return _mapper.Map<Model.Posjeta>(entity);
    }

    public async Task<Model.Posjeta> Insert(PosjetaInsertRequest request, int korisnikId)
    {
        if (request.DatumVrijeme <= DateTime.UtcNow)
            throw new ValidationException("Datum i vrijeme posjete moraju biti u budućnosti.", nameof(request.DatumVrijeme), "Odaberite termin u budućnosti.");

        if (request.PasId.HasValue && !await _context.Pas.AnyAsync(p => p.PasId == request.PasId.Value))
            throw new ValidationException("Odabrani pas ne postoji.", nameof(request.PasId), "Pas ne postoji.");

        await EnsureSlotAvailableAsync(request.DatumVrijeme);

        var statusNaCekanju = await _context.StatusPosjetes.FirstOrDefaultAsync(s => s.Naziv == StatusPosjeteNazivi.NaCekanju)
            ?? throw new BusinessException("Status 'Na čekanju' nije podešen u sistemu.");

        var entity = new Database.Posjeta
        {
            KorisnikId = korisnikId,
            PasId = request.PasId,
            DatumVrijeme = request.DatumVrijeme,
            StatusPosjeteId = statusNaCekanju.StatusPosjeteId,
            Napomena = request.Napomena,
            DatumKreiranja = DateTime.UtcNow
        };

        _context.Posjeta.Add(entity);
        await _context.SaveChangesAsync();

        return await GetById(entity.PosjetaId);
    }

    public async Task<Model.Posjeta> InsertAdmin(PosjetaAdminInsertRequest request, int adminKorisnikId)
    {
        if (!await _context.Korisniks.AnyAsync(k => k.KorisnikId == request.KorisnikId))
            throw new ValidationException("Odabrani korisnik ne postoji.", nameof(request.KorisnikId), "Korisnik ne postoji.");

        if (request.PasId.HasValue && !await _context.Pas.AnyAsync(p => p.PasId == request.PasId.Value))
            throw new ValidationException("Odabrani pas ne postoji.", nameof(request.PasId), "Pas ne postoji.");

        await EnsureSlotAvailableAsync(request.DatumVrijeme);

        var statusPotvrdjena = await _context.StatusPosjetes.FirstOrDefaultAsync(s => s.Naziv == StatusPosjeteNazivi.Potvrdjena)
            ?? throw new BusinessException("Status 'Potvrđena' nije podešen u sistemu.");

        var entity = new Database.Posjeta
        {
            KorisnikId = request.KorisnikId,
            PasId = request.PasId,
            DatumVrijeme = request.DatumVrijeme,
            StatusPosjeteId = statusPotvrdjena.StatusPosjeteId,
            Napomena = request.Napomena,
            DatumKreiranja = DateTime.UtcNow,
            ObradioKorisnikId = adminKorisnikId,
            DatumObrade = DateTime.UtcNow
        };

        _context.Posjeta.Add(entity);
        await _context.SaveChangesAsync();

        return await GetById(entity.PosjetaId);
    }

    public async Task<Model.Posjeta> Potvrdi(int id, int adminKorisnikId)
    {
        var entity = await _context.Posjeta.FindAsync(id)
            ?? throw new NotFoundException($"Posjeta s ID {id} nije pronađena.");

        var statusNaCekanju = await _context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.NaCekanju);
        if (entity.StatusPosjeteId != statusNaCekanju.StatusPosjeteId)
            throw new BusinessException("Samo posjeta na čekanju može biti potvrđena.");

        var statusPotvrdjena = await _context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.Potvrdjena);

        entity.StatusPosjeteId = statusPotvrdjena.StatusPosjeteId;
        entity.ObradioKorisnikId = adminKorisnikId;
        entity.DatumObrade = DateTime.UtcNow;

        _notifikacijaService.StageCreate(
            entity.KorisnikId,
            NotifikacijaTipovi.PosjetaPotvrdjena,
            "Posjeta potvrđena",
            $"Vaša posjeta zakazana za {entity.DatumVrijeme:dd.MM.yyyy HH:mm} je potvrđena.",
            entity.PosjetaId);

        await _context.SaveChangesAsync();

        return await GetById(id);
    }

    public async Task<Model.Posjeta> Otkazi(int id, PosjetaOtkaziRequest request, int callerKorisnikId, bool isAdmin)
    {
        var entity = await _context.Posjeta.FindAsync(id)
            ?? throw new NotFoundException($"Posjeta s ID {id} nije pronađena.");

        if (!isAdmin && entity.KorisnikId != callerKorisnikId)
            throw new ForbiddenException("Nemate pristup ovoj posjeti.");

        var statusNaCekanju = await _context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.NaCekanju);
        var statusPotvrdjena = await _context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.Potvrdjena);

        if (entity.StatusPosjeteId != statusNaCekanju.StatusPosjeteId && entity.StatusPosjeteId != statusPotvrdjena.StatusPosjeteId)
            throw new BusinessException("Posjeta je već obrađena i ne može se otkazati.");

        var statusOtkazana = await _context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.Otkazana);

        entity.StatusPosjeteId = statusOtkazana.StatusPosjeteId;
        entity.RazlogOtkazivanja = request.RazlogOtkazivanja;
        entity.ObradioKorisnikId = callerKorisnikId;
        entity.DatumObrade = DateTime.UtcNow;

        _notifikacijaService.StageCreate(
            entity.KorisnikId,
            NotifikacijaTipovi.PosjetaOtkazana,
            "Posjeta otkazana",
            $"Vaša posjeta zakazana za {entity.DatumVrijeme:dd.MM.yyyy HH:mm} je otkazana. Razlog: {request.RazlogOtkazivanja}",
            entity.PosjetaId);

        await _context.SaveChangesAsync();

        return await GetById(id);
    }

    public async Task<Model.Posjeta> Zavrsi(int id, int adminKorisnikId)
    {
        var entity = await _context.Posjeta.FindAsync(id)
            ?? throw new NotFoundException($"Posjeta s ID {id} nije pronađena.");

        var statusPotvrdjena = await _context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.Potvrdjena);
        if (entity.StatusPosjeteId != statusPotvrdjena.StatusPosjeteId)
            throw new BusinessException("Samo potvrđena posjeta može biti označena kao završena.");

        var statusZavrsena = await _context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.Zavrsena);

        entity.StatusPosjeteId = statusZavrsena.StatusPosjeteId;
        entity.ObradioKorisnikId = adminKorisnikId;
        entity.DatumObrade = DateTime.UtcNow;

        _notifikacijaService.StageCreate(
            entity.KorisnikId,
            NotifikacijaTipovi.PosjetaZavrsena,
            "Posjeta završena",
            $"Vaša posjeta zakazana za {entity.DatumVrijeme:dd.MM.yyyy HH:mm} je označena kao završena.",
            entity.PosjetaId);

        await _context.SaveChangesAsync();

        return await GetById(id);
    }

    private static readonly string[] AktivniStatusi = [StatusPosjeteNazivi.NaCekanju, StatusPosjeteNazivi.Potvrdjena];

    private async Task EnsureSlotAvailableAsync(DateTime datumVrijeme)
    {
        var zauzeto = await _context.Posjeta
            .Include(p => p.StatusPosjete)
            .AnyAsync(p => p.DatumVrijeme == datumVrijeme && AktivniStatusi.Contains(p.StatusPosjete.Naziv));

        if (zauzeto)
            throw new BusinessException("Odabrani termin je već zauzet. Molimo odaberite drugi termin.");
    }

    public async Task<List<DateTime>> GetZauzetiTermini(DateTime datum)
    {
        var datumOd = datum.Date;
        var datumDo = datumOd.AddDays(1);

        return await _context.Posjeta
            .Include(p => p.StatusPosjete)
            .Where(p => p.DatumVrijeme >= datumOd && p.DatumVrijeme < datumDo && AktivniStatusi.Contains(p.StatusPosjete.Naziv))
            .Select(p => p.DatumVrijeme)
            .ToListAsync();
    }
}
