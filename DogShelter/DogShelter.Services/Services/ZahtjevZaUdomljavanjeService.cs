using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Constants;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class ZahtjevZaUdomljavanjeService : IZahtjevZaUdomljavanjeService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;
    private readonly INotifikacijaService _notifikacijaService;

    public ZahtjevZaUdomljavanjeService(DogShelterContext context, IMapper mapper, INotifikacijaService notifikacijaService)
    {
        _context = context;
        _mapper = mapper;
        _notifikacijaService = notifikacijaService;
    }

    private IQueryable<Database.ZahtjevZaUdomljavanje> BaseQuery() =>
        _context.ZahtjevZaUdomljavanjes
            .Include(z => z.Korisnik)
            .Include(z => z.ObradioKorisnik)
            .Include(z => z.Pas)
            .Include(z => z.StatusZahtjeva)
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

        _context.ZahtjevZaUdomljavanjes.Add(entity);
        await _context.SaveChangesAsync();

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
        var statusUdomljen = await _context.StatusPsas.FirstOrDefaultAsync(s => s.Naziv == StatusPsaNazivi.Udomljen)
            ?? throw new BusinessException("Status 'Udomljen' nije podešen u sistemu.");

        var pas = await _context.Pas.FindAsync(entity.PasId)
            ?? throw new NotFoundException("Pas povezan sa zahtjevom nije pronađen.");

        await using var tx = await _context.Database.BeginTransactionAsync();
        try
        {
            entity.StatusZahtjevaId = statusOdobren.StatusZahtjevaId;
            entity.ObradioKorisnikId = adminKorisnikId;
            entity.DatumObrade = DateTime.UtcNow;

            pas.StatusPsaId = statusUdomljen.StatusPsaId;

            _context.Udomljavanjes.Add(new Database.Udomljavanje
            {
                ZahtjevZaUdomljavanjeId = entity.ZahtjevZaUdomljavanjeId,
                DatumUdomljavanja = DateOnly.FromDateTime(DateTime.UtcNow)
            });

            _notifikacijaService.StageCreate(
                entity.KorisnikId,
                NotifikacijaTipovi.ZahtjevOdobren,
                "Zahtjev za udomljavanje odobren",
                $"Vaš zahtjev za udomljavanje psa \"{pas.Naziv}\" je odobren.",
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

        return await GetById(id);
    }
}
