using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Constants;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DogShelter.Services.Services;

public class ZahtjevZaUdomljavanjeService : IZahtjevZaUdomljavanjeService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;
    private readonly INotifikacijaService _notifikacijaService;
    private readonly IEmailSender _emailSender;
    private readonly ILogger<ZahtjevZaUdomljavanjeService> _logger;

    public ZahtjevZaUdomljavanjeService(
        DogShelterContext context,
        IMapper mapper,
        INotifikacijaService notifikacijaService,
        IEmailSender emailSender,
        ILogger<ZahtjevZaUdomljavanjeService> logger)
    {
        _context = context;
        _mapper = mapper;
        _notifikacijaService = notifikacijaService;
        _emailSender = emailSender;
        _logger = logger;
    }

    private IQueryable<Database.ZahtjevZaUdomljavanje> BaseQuery() =>
        _context.ZahtjevZaUdomljavanjes
            .Include(z => z.Korisnik)
            .Include(z => z.ObradioKorisnik)
            .Include(z => z.Pas).ThenInclude(p => p.StatusPsa)
            .Include(z => z.StatusZahtjeva)
            .Include(z => z.Udomljavanje)
            .AsNoTracking();

    public async Task<PagedResult<Model.ZahtjevZaUdomljavanje>> Get(ZahtjevZaUdomljavanjeSearchRequest search, int currentKorisnikId, bool isAdmin)
    {
        var query = BaseQuery();

        var korisnikFilter = isAdmin ? search.KorisnikId : currentKorisnikId;
        if (korisnikFilter.HasValue)
            query = query.Where(z => z.KorisnikId == korisnikFilter.Value);

        if (search.PasId.HasValue)
            query = query.Where(z => z.PasId == search.PasId.Value);

        if (search.StatusZahtjevaId.HasValue)
            query = query.Where(z => z.StatusZahtjevaId == search.StatusZahtjevaId.Value);

        query = query.OrderByDescending(z => z.DatumPodnosenja);

        return await PagedQueryHelper.ToPagedResultAsync<Database.ZahtjevZaUdomljavanje, Model.ZahtjevZaUdomljavanje>(query, search, _mapper);
    }

    public async Task<Model.ZahtjevZaUdomljavanje> GetById(int id)
    {
        var entity = await BaseQuery().FirstOrDefaultAsync(z => z.ZahtjevZaUdomljavanjeId == id)
            ?? throw new NotFoundException($"Zahtjev za udomljavanje s ID {id} nije pronađen.");

        return _mapper.Map<Model.ZahtjevZaUdomljavanje>(entity);
    }

    public async Task<Model.ZahtjevZaUdomljavanje> Insert(ZahtjevZaUdomljavanjeInsertRequest request, int korisnikId)
    {
        var pas = await _context.Pas.FirstOrDefaultAsync(p => p.PasId == request.PasId)
            ?? throw new ValidationException("Odabrani pas ne postoji.", nameof(request.PasId), "Pas ne postoji.");

        if (!pas.Aktivan)
            throw new BusinessException("Pas trenutno nije dostupan za udomljavanje.");

        var statusDostupan = await _context.StatusPsas.FirstOrDefaultAsync(s => s.Naziv == StatusPsaNazivi.Dostupan);
        if (statusDostupan == null || pas.StatusPsaId != statusDostupan.StatusPsaId)
            throw new BusinessException("Pas trenutno nije dostupan za udomljavanje.");

        var statusNaCekanju = await _context.StatusZahtjevas.FirstOrDefaultAsync(s => s.Naziv == StatusZahtjevaNazivi.NaCekanju)
            ?? throw new BusinessException("Status 'Na čekanju' nije podešen u sistemu.");

        var duplicate = await _context.ZahtjevZaUdomljavanjes.AnyAsync(z =>
            z.KorisnikId == korisnikId && z.PasId == request.PasId && z.StatusZahtjevaId == statusNaCekanju.StatusZahtjevaId);
        if (duplicate)
            throw new BusinessException("Već imate aktivan zahtjev za ovog psa.");

        var entity = new Database.ZahtjevZaUdomljavanje
        {
            KorisnikId = korisnikId,
            PasId = request.PasId,
            StatusZahtjevaId = statusNaCekanju.StatusZahtjevaId,
            DatumPodnosenja = DateTime.UtcNow,
            Napomena = request.Napomena
        };

        // Notifications need entity.ZahtjevZaUdomljavanjeId, which EF only assigns after this
        // first SaveChangesAsync commits - staging them before that (as this used to) captured
        // VezaniEntitetId as 0. Same fix as ObavijestService.InsertWithImage: save first, then
        // stage, then save again, wrapped in one transaction.
        await using var tx = await _context.Database.BeginTransactionAsync();

        _context.ZahtjevZaUdomljavanjes.Add(entity);
        await _context.SaveChangesAsync();

        _notifikacijaService.StageCreate(
            korisnikId,
            NotifikacijaTipovi.ZahtjevPodnesen,
            "Zahtjev za udomljavanje poslan",
            $"Vaš zahtjev za udomljavanje psa \"{pas.Naziv}\" je zaprimljen i čeka obradu.",
            entity.ZahtjevZaUdomljavanjeId);
        await _notifikacijaService.StageCreateForRoleAsync(
            RoleNames.Admin,
            NotifikacijaTipovi.ZahtjevPodnesen,
            "Novi zahtjev za udomljavanje",
            $"Korisnik je poslao zahtjev za udomljavanje psa \"{pas.Naziv}\".",
            entity.ZahtjevZaUdomljavanjeId);

        await _context.SaveChangesAsync();
        await tx.CommitAsync();

        return await GetById(entity.ZahtjevZaUdomljavanjeId);
    }

    public async Task<Model.ZahtjevZaUdomljavanje> Odobri(int id, int adminKorisnikId)
    {
        var entity = await _context.ZahtjevZaUdomljavanjes.FindAsync(id)
            ?? throw new NotFoundException($"Zahtjev za udomljavanje s ID {id} nije pronađen.");

        var statusNaCekanju = await _context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.NaCekanju);
        if (entity.StatusZahtjevaId != statusNaCekanju.StatusZahtjevaId)
            throw new BusinessException("Zahtjev je već obrađen i ne može se ponovo odobriti.");

        var statusOdobren = await _context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.Odobren);
        var statusOdbijen = await _context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.Odbijen);
        var statusRezervisan = await _context.StatusPsas.FirstOrDefaultAsync(s => s.Naziv == StatusPsaNazivi.Rezervisan)
            ?? throw new BusinessException("Status 'Rezervisan' nije podešen u sistemu.");

        var pas = await _context.Pas.FindAsync(entity.PasId)
            ?? throw new NotFoundException("Pas povezan sa zahtjevom nije pronađen.");

        // Re-validated here, not just at submission time (Insert already checked this when the
        // request was created) - the dog may have been deactivated in the meantime.
        if (!pas.Aktivan)
            throw new BusinessException($"Pas \"{pas.Naziv}\" više nije aktivan i zahtjev se ne može odobriti.");

        // Other users may have a still-pending request for the same dog — approving this one
        // means the dog is no longer available, so those are auto-rejected in the same
        // transaction instead of being silently left "Na čekanju" for a dog that's already gone.
        var ostaliNaCekanju = await _context.ZahtjevZaUdomljavanjes
            .Where(z => z.PasId == entity.PasId
                && z.ZahtjevZaUdomljavanjeId != entity.ZahtjevZaUdomljavanjeId
                && z.StatusZahtjevaId == statusNaCekanju.StatusZahtjevaId)
            .ToListAsync();

        await using var tx = await _context.Database.BeginTransactionAsync();
        try
        {
            entity.StatusZahtjevaId = statusOdobren.StatusZahtjevaId;
            entity.ObradioKorisnikId = adminKorisnikId;
            entity.DatumObrade = DateTime.UtcNow;

            // Reserved, not yet adopted - see FinalizirajUdomljenje() below.
            pas.StatusPsaId = statusRezervisan.StatusPsaId;

            _notifikacijaService.StageCreate(
                entity.KorisnikId,
                NotifikacijaTipovi.ZahtjevOdobren,
                "Zahtjev za udomljavanje odobren",
                $"Vaš zahtjev za udomljavanje psa \"{pas.Naziv}\" je odobren i pas je rezervisan za Vas. Udomljavanje će biti finalizovano uskoro.",
                entity.ZahtjevZaUdomljavanjeId);

            foreach (var ostali in ostaliNaCekanju)
            {
                ostali.StatusZahtjevaId = statusOdbijen.StatusZahtjevaId;
                ostali.ObradioKorisnikId = adminKorisnikId;
                ostali.DatumObrade = DateTime.UtcNow;
                ostali.RazlogOdbijanja = "Zahtjev je automatski odbijen jer je pas rezervisan za drugog korisnika.";

                _notifikacijaService.StageCreate(
                    ostali.KorisnikId,
                    NotifikacijaTipovi.ZahtjevOdbijen,
                    "Zahtjev za udomljavanje odbijen",
                    $"Vaš zahtjev za udomljavanje psa \"{pas.Naziv}\" je automatski odbijen jer je pas u međuvremenu rezervisan za drugog korisnika.",
                    ostali.ZahtjevZaUdomljavanjeId);
            }

            await _context.SaveChangesAsync();
            await tx.CommitAsync();
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }

        await SendOdlukaEmailAsync(entity.KorisnikId, pas.Naziv, odobreno: true);
        foreach (var ostali in ostaliNaCekanju)
            await SendOdlukaEmailAsync(ostali.KorisnikId, pas.Naziv, odobreno: false, ostali.RazlogOdbijanja);

        return await GetById(id);
    }

    // Second, separate step from Odobri(): moves an already-approved request's reserved dog to
    // Udomljen and creates the Udomljavanje record (see StatusPsaNazivi.Rezervisan for why).
    public async Task<Model.ZahtjevZaUdomljavanje> FinalizirajUdomljenje(int id, int adminKorisnikId)
    {
        var entity = await _context.ZahtjevZaUdomljavanjes.FindAsync(id)
            ?? throw new NotFoundException($"Zahtjev za udomljavanje s ID {id} nije pronađen.");

        var statusOdobren = await _context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.Odobren);
        if (entity.StatusZahtjevaId != statusOdobren.StatusZahtjevaId)
            throw new BusinessException("Samo odobren zahtjev (pas u statusu 'Rezervisan') može biti finaliziran kao udomljavanje.");

        if (await _context.Udomljavanjes.AnyAsync(u => u.ZahtjevZaUdomljavanjeId == entity.ZahtjevZaUdomljavanjeId))
            throw new BusinessException("Udomljavanje za ovaj zahtjev je već finalizovano.");

        var pas = await _context.Pas.Include(p => p.StatusPsa).FirstOrDefaultAsync(p => p.PasId == entity.PasId)
            ?? throw new NotFoundException("Pas povezan sa zahtjevom nije pronađen.");

        if (pas.StatusPsa.Naziv != StatusPsaNazivi.Rezervisan)
            throw new BusinessException($"Pas \"{pas.Naziv}\" nije u statusu 'Rezervisan'.");

        var statusUdomljen = await _context.StatusPsas.FirstOrDefaultAsync(s => s.Naziv == StatusPsaNazivi.Udomljen)
            ?? throw new BusinessException("Status 'Udomljen' nije podešen u sistemu.");

        await using var tx = await _context.Database.BeginTransactionAsync();
        try
        {
            pas.StatusPsaId = statusUdomljen.StatusPsaId;

            _context.Udomljavanjes.Add(new Database.Udomljavanje
            {
                ZahtjevZaUdomljavanjeId = entity.ZahtjevZaUdomljavanjeId,
                DatumUdomljavanja = DateOnly.FromDateTime(DateTime.UtcNow)
            });

            _notifikacijaService.StageCreate(
                entity.KorisnikId,
                NotifikacijaTipovi.UdomljenjeFinalizovano,
                "Udomljavanje finalizovano",
                $"Udomljavanje psa \"{pas.Naziv}\" je finalizovano. Čestitamo na novom članu porodice!",
                entity.ZahtjevZaUdomljavanjeId);

            await _context.SaveChangesAsync();
            await tx.CommitAsync();
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }

        return await GetById(id);
    }

    public async Task<Model.ZahtjevZaUdomljavanje> Odbij(int id, ZahtjevZaUdomljavanjeOdbijRequest request, int adminKorisnikId)
    {
        var entity = await _context.ZahtjevZaUdomljavanjes.FindAsync(id)
            ?? throw new NotFoundException($"Zahtjev za udomljavanje s ID {id} nije pronađen.");

        var statusNaCekanju = await _context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.NaCekanju);
        if (entity.StatusZahtjevaId != statusNaCekanju.StatusZahtjevaId)
            throw new BusinessException("Zahtjev je već obrađen i ne može se ponovo odbiti.");

        var statusOdbijen = await _context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.Odbijen);

        entity.StatusZahtjevaId = statusOdbijen.StatusZahtjevaId;
        entity.ObradioKorisnikId = adminKorisnikId;
        entity.DatumObrade = DateTime.UtcNow;
        entity.RazlogOdbijanja = request.RazlogOdbijanja;

        _notifikacijaService.StageCreate(
            entity.KorisnikId,
            NotifikacijaTipovi.ZahtjevOdbijen,
            "Zahtjev za udomljavanje odbijen",
            $"Vaš zahtjev za udomljavanje je odbijen. Razlog: {request.RazlogOdbijanja}",
            entity.ZahtjevZaUdomljavanjeId);

        await _context.SaveChangesAsync();

        var pasNaziv = await _context.Pas.Where(p => p.PasId == entity.PasId).Select(p => p.Naziv).FirstOrDefaultAsync() ?? "-";
        await SendOdlukaEmailAsync(entity.KorisnikId, pasNaziv, odobreno: false, request.RazlogOdbijanja);

        return await GetById(id);
    }

    public async Task<Model.ZahtjevZaUdomljavanje> Otkazi(int id, ZahtjevZaUdomljavanjeOtkaziRequest request, int callerKorisnikId, bool isAdmin)
    {
        var entity = await _context.ZahtjevZaUdomljavanjes.FindAsync(id)
            ?? throw new NotFoundException($"Zahtjev za udomljavanje s ID {id} nije pronađen.");

        if (!isAdmin && entity.KorisnikId != callerKorisnikId)
            throw new ForbiddenException("Nemate pristup ovom zahtjevu.");

        var statusNaCekanju = await _context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.NaCekanju);
        if (entity.StatusZahtjevaId != statusNaCekanju.StatusZahtjevaId)
            throw new BusinessException("Zahtjev je već obrađen i ne može se otkazati.");

        var statusOtkazan = await _context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.Otkazan);

        entity.StatusZahtjevaId = statusOtkazan.StatusZahtjevaId;
        entity.ObradioKorisnikId = callerKorisnikId;
        entity.DatumObrade = DateTime.UtcNow;
        entity.RazlogOdbijanja = request.RazlogOtkazivanja;

        if (isAdmin)
        {
            _notifikacijaService.StageCreate(
                entity.KorisnikId,
                NotifikacijaTipovi.ZahtjevOtkazan,
                "Zahtjev za udomljavanje otkazan",
                $"Vaš zahtjev za udomljavanje je otkazan. Razlog: {request.RazlogOtkazivanja}",
                entity.ZahtjevZaUdomljavanjeId);
        }
        else
        {
            await _notifikacijaService.StageCreateForRoleAsync(
                RoleNames.Admin,
                NotifikacijaTipovi.ZahtjevOtkazan,
                "Zahtjev za udomljavanje povučen",
                $"Korisnik je povukao svoj zahtjev za udomljavanje. Razlog: {request.RazlogOtkazivanja}",
                entity.ZahtjevZaUdomljavanjeId);
        }

        await _context.SaveChangesAsync();

        return await GetById(id);
    }

    // Mirrors the in-app notification with an email, same fire-and-log-on-failure pattern as
    // DogadjajVolonterService's zaduženje emails - a failed send must not undo the decision that
    // was already committed.
    private async Task SendOdlukaEmailAsync(int korisnikId, string pasNaziv, bool odobreno, string? razlog = null)
    {
        var korisnik = await _context.Korisniks.AsNoTracking()
            .Where(k => k.KorisnikId == korisnikId)
            .Select(k => new { k.Ime, k.Email })
            .FirstOrDefaultAsync();
        if (korisnik == null) return;

        try
        {
            var subject = odobreno
                ? $"Zahtjev za udomljavanje odobren: {pasNaziv}"
                : $"Zahtjev za udomljavanje odbijen: {pasNaziv}";

            var body = odobreno
                ? $"Poštovani/a {korisnik.Ime},\n\n" +
                  $"Vaš zahtjev za udomljavanje psa \"{pasNaziv}\" je odobren i pas je rezervisan za Vas. " +
                  "O finalizaciji udomljavanja bit ćete dodatno obaviješteni.\n\nAzil za pse Bugojno"
                : $"Poštovani/a {korisnik.Ime},\n\n" +
                  $"Vaš zahtjev za udomljavanje psa \"{pasNaziv}\" je odbijen." +
                  (string.IsNullOrWhiteSpace(razlog) ? "" : $" Razlog: {razlog}") +
                  "\n\nAzil za pse Bugojno";

            await _emailSender.SendAsync(korisnik.Email, subject, body);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send zahtjev decision email to {Email}.", korisnik.Email);
        }
    }
}
