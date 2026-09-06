using System.Data;
using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Constants;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.Data.SqlClient;
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

        if (request.PasId.HasValue)
            await EnsurePasAvailableForVisitAsync(request.PasId.Value);

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

        await ExecuteConcurrencySafeBookingAsync(request.DatumVrijeme, async () =>
        {
            // Notifications need entity.PosjetaId, only assigned after this first
            // SaveChangesAsync - staging them before that (as this used to) captured
            // VezaniEntitetId as 0. Both saves still run inside the same transaction.
            _context.Posjeta.Add(entity);
            await _context.SaveChangesAsync();

            _notifikacijaService.StageCreate(
                korisnikId,
                NotifikacijaTipovi.PosjetaZakazana,
                "Posjeta zakazana",
                $"Vaša posjeta za {request.DatumVrijeme:dd.MM.yyyy. HH:mm} je zaprimljena i čeka potvrdu.",
                entity.PosjetaId);
            await _notifikacijaService.StageCreateForRoleAsync(
                RoleNames.Admin,
                NotifikacijaTipovi.PosjetaZakazana,
                "Nova posjeta zakazana",
                $"Korisnik je zakazao posjetu za {request.DatumVrijeme:dd.MM.yyyy. HH:mm}.",
                entity.PosjetaId);

            await _context.SaveChangesAsync();
        });

        return await GetById(entity.PosjetaId);
    }

    public async Task<Model.Posjeta> InsertAdmin(PosjetaAdminInsertRequest request, int adminKorisnikId)
    {
        // Same rule as the self-service Insert() below - this was previously only enforced
        // client-side in the desktop form, which made it a UI convention rather than a server
        // invariant. A booking API is supposed to guarantee this regardless of caller.
        if (request.DatumVrijeme <= DateTime.UtcNow)
            throw new ValidationException("Datum i vrijeme posjete moraju biti u budućnosti.", nameof(request.DatumVrijeme), "Odaberite termin u budućnosti.");

        var korisnikAktivan = await _context.Korisniks
            .Where(k => k.KorisnikId == request.KorisnikId)
            .Select(k => (bool?)k.Aktivan)
            .FirstOrDefaultAsync();

        if (korisnikAktivan is null)
            throw new ValidationException("Odabrani korisnik ne postoji.", nameof(request.KorisnikId), "Korisnik ne postoji.");

        if (korisnikAktivan == false)
            throw new ValidationException("Odabrani korisnik nije aktivan.", nameof(request.KorisnikId), "Korisnik nije aktivan.");

        if (request.PasId.HasValue)
            await EnsurePasAvailableForVisitAsync(request.PasId.Value);

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

        await ExecuteConcurrencySafeBookingAsync(request.DatumVrijeme, async () =>
        {
            _context.Posjeta.Add(entity);
            await _context.SaveChangesAsync();

            // The self-service Insert() above notifies the booking user; this admin-created
            // posjeta is already Potvrdjena on arrival, so the user should still hear about it.
            _notifikacijaService.StageCreate(
                request.KorisnikId,
                NotifikacijaTipovi.PosjetaPotvrdjena,
                "Posjeta zakazana",
                $"Zakazana Vam je i potvrđena posjeta za {request.DatumVrijeme:dd.MM.yyyy. HH:mm}.",
                entity.PosjetaId);

            await _context.SaveChangesAsync();
        });

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

        // Same recipient split as ZahtjevZaUdomljavanjeService.Otkazi(): an admin cancelling
        // notifies the visitor; the visitor cancelling their own posjeta notifies admins instead
        // (they don't need to be told about their own action) so the freed-up slot gets noticed.
        if (isAdmin)
        {
            _notifikacijaService.StageCreate(
                entity.KorisnikId,
                NotifikacijaTipovi.PosjetaOtkazana,
                "Posjeta otkazana",
                $"Vaša posjeta zakazana za {entity.DatumVrijeme:dd.MM.yyyy HH:mm} je otkazana. Razlog: {request.RazlogOtkazivanja}",
                entity.PosjetaId);
        }
        else
        {
            await _notifikacijaService.StageCreateForRoleAsync(
                RoleNames.Admin,
                NotifikacijaTipovi.PosjetaOtkazana,
                "Posjeta otkazana od strane korisnika",
                $"Korisnik je otkazao posjetu zakazanu za {entity.DatumVrijeme:dd.MM.yyyy HH:mm}. Razlog: {request.RazlogOtkazivanja}",
                entity.PosjetaId);
        }

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

        if (entity.DatumVrijeme > DateTime.UtcNow)
            throw new BusinessException("Posjeta se ne može označiti završenom prije zakazanog termina.");

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

    private async Task EnsurePasAvailableForVisitAsync(int pasId)
    {
        var pas = await _context.Pas.Include(p => p.StatusPsa).FirstOrDefaultAsync(p => p.PasId == pasId)
            ?? throw new ValidationException("Odabrani pas ne postoji.", nameof(pasId), "Pas ne postoji.");

        if (!pas.Aktivan)
            throw new BusinessException($"Pas \"{pas.Naziv}\" više nije aktivan i nije moguće zakazati posjetu za njega.");

        // Whitelist ("Dostupan" only), not a blacklist of specific unavailable statuses - a
        // blacklist of just Udomljen/Rezervisan silently let visits be booked for a dog
        // "U tretmanu" or "Ugašen" too. Mirrors ZahtjevZaUdomljavanjeService.Insert().
        if (pas.StatusPsa.Naziv != StatusPsaNazivi.Dostupan)
            throw new BusinessException($"Pas \"{pas.Naziv}\" trenutno nije dostupan i nije moguće zakazati posjetu za njega.");
    }

    private async Task EnsureSlotAvailableAsync(DateTime datumVrijeme)
    {
        var zauzeto = await _context.Posjeta
            .Include(p => p.StatusPosjete)
            .AnyAsync(p => p.DatumVrijeme == datumVrijeme && AktivniStatusi.Contains(p.StatusPosjete.Naziv));

        if (zauzeto)
            throw new BusinessException("Odabrani termin je već zauzet. Molimo odaberite drugi termin.");
    }

    // EnsureSlotAvailableAsync alone is a plain check-then-insert (TOCTOU): two concurrent
    // requests for the same slot can both pass the check before either commits. Serializable
    // isolation closes that window — SQL Server takes a range lock on the check's predicate, so
    // a genuinely concurrent insert for the same DatumVrijeme conflicts at the DB level instead
    // of silently succeeding twice, surfacing here as a DbUpdateException/SqlException that gets
    // translated into the same friendly message the happy-path check already uses.
    private async Task ExecuteConcurrencySafeBookingAsync(DateTime datumVrijeme, Func<Task> insertAndSave)
    {
        await using var tx = await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable);

        try
        {
            await EnsureSlotAvailableAsync(datumVrijeme);
            await insertAndSave();
            await tx.CommitAsync();
        }
        catch (Exception ex) when (IsConcurrencyConflict(ex))
        {
            throw new BusinessException("Odabrani termin je već zauzet. Molimo odaberite drugi termin.");
        }
    }

    // A losing race under Serializable isolation surfaces as a SQL deadlock wrapped in
    // DbUpdateException or SqlException somewhere in the InnerException chain, not necessarily
    // as the outermost exception type.
    private static bool IsConcurrencyConflict(Exception ex)
    {
        for (var e = ex; e != null; e = e.InnerException)
        {
            if (e is DbUpdateException or SqlException)
                return true;
        }
        return false;
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
