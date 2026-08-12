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

public class DonacijaService : IDonacijaService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;
    private readonly IStripePaymentService _stripePaymentService;
    private readonly INotifikacijaService _notifikacijaService;

    public DonacijaService(DogShelterContext context, IMapper mapper, IStripePaymentService stripePaymentService, INotifikacijaService notifikacijaService)
    {
        _context = context;
        _mapper = mapper;
        _stripePaymentService = stripePaymentService;
        _notifikacijaService = notifikacijaService;
    }

    private IQueryable<Database.Donacija> BaseQuery() =>
        _context.Donacijas
            .Include(d => d.Korisnik)
            .Include(d => d.TipDonacije)
            .Include(d => d.StatusDonacije)
            .Include(d => d.ObradioKorisnik)
            .Include(d => d.KategorijaDonacije)
            .Include(d => d.JedinicaMjere)
            .AsNoTracking();

    public async Task<PagedResult<Model.Donacija>> Get(DonacijaSearchRequest search, int currentKorisnikId, bool isAdmin)
    {
        var query = BaseQuery();

        var korisnikFilter = isAdmin ? search.KorisnikId : currentKorisnikId;
        if (korisnikFilter.HasValue)
            query = query.Where(d => d.KorisnikId == korisnikFilter.Value);

        if (search.TipDonacijeId.HasValue)
            query = query.Where(d => d.TipDonacijeId == search.TipDonacijeId.Value);

        if (search.StatusDonacijeId.HasValue)
            query = query.Where(d => d.StatusDonacijeId == search.StatusDonacijeId.Value);

        if (search.DatumOd.HasValue)
            query = query.Where(d => d.DatumDonacije >= search.DatumOd.Value);

        if (search.DatumDo.HasValue)
            query = query.Where(d => d.DatumDonacije <= search.DatumDo.Value);

        query = query.OrderByDescending(d => d.DatumDonacije);

        return await PagedQueryHelper.ToPagedResultAsync<Database.Donacija, Model.Donacija>(query, search, _mapper);
    }

    public async Task<Model.Donacija> GetById(int id)
    {
        var entity = await BaseQuery().FirstOrDefaultAsync(d => d.DonacijaId == id)
            ?? throw new NotFoundException($"Donacija s ID {id} nije pronađena.");

        return _mapper.Map<Model.Donacija>(entity);
    }

    public async Task<DonacijaPaymentResponse> Insert(DonacijaInsertRequest request, int korisnikId)
    {
        var tip = await _context.TipDonacijes.FirstOrDefaultAsync(t => t.TipDonacijeId == request.TipDonacijeId)
            ?? throw new ValidationException("Odabrani tip donacije ne postoji.", nameof(request.TipDonacijeId), "Tip donacije ne postoji.");

        var statusNaCekanju = await _context.StatusDonacijes.FirstOrDefaultAsync(s => s.Naziv == StatusDonacijeNazivi.NaCekanju)
            ?? throw new BusinessException("Status 'Na čekanju' nije podešen u sistemu.");

        var isNovcana = tip.Naziv == TipDonacijeNazivi.Novcana;

        if (isNovcana)
        {
            if (!request.Iznos.HasValue || request.Iznos.Value <= 0)
                throw new ValidationException("Iznos je obavezan za novčanu donaciju.", nameof(request.Iznos), "Unesite iznos veći od 0.");
        }
        else
        {
            if (request.Iznos.HasValue)
                throw new ValidationException("Iznos nije dozvoljen za materijalnu donaciju.", nameof(request.Iznos), "Materijalna donacija nema novčani iznos.");

            if (!request.KategorijaDonacijeId.HasValue)
                throw new ValidationException("Kategorija je obavezna za materijalnu donaciju.", nameof(request.KategorijaDonacijeId), "Odaberite kategoriju donacije.");

            var kategorija = await _context.KategorijaDonacijes.FirstOrDefaultAsync(k => k.KategorijaDonacijeId == request.KategorijaDonacijeId.Value)
                ?? throw new ValidationException("Odabrana kategorija ne postoji.", nameof(request.KategorijaDonacijeId), "Kategorija ne postoji.");

            var isOstalo = kategorija.Naziv == KategorijaDonacijeNazivi.Ostalo;
            if (isOstalo && string.IsNullOrWhiteSpace(request.PrilagodjenNaziv))
                throw new ValidationException("Naziv stavke je obavezan kada je odabrana kategorija 'Ostalo'.", nameof(request.PrilagodjenNaziv), "Opišite šta donirate.");
            if (!isOstalo && !string.IsNullOrWhiteSpace(request.PrilagodjenNaziv))
                throw new ValidationException("Naziv stavke je dozvoljen samo za kategoriju 'Ostalo'.", nameof(request.PrilagodjenNaziv), "Ovo polje se popunjava samo za kategoriju 'Ostalo'.");

            if (!request.Kolicina.HasValue || request.Kolicina.Value <= 0)
                throw new ValidationException("Količina je obavezna za materijalnu donaciju.", nameof(request.Kolicina), "Unesite količinu veću od 0.");

            if (!request.JedinicaMjereId.HasValue)
                throw new ValidationException("Jedinica mjere je obavezna za materijalnu donaciju.", nameof(request.JedinicaMjereId), "Odaberite jedinicu mjere.");

            if (!await _context.JedinicaMjeres.AnyAsync(j => j.JedinicaMjereId == request.JedinicaMjereId.Value))
                throw new ValidationException("Odabrana jedinica mjere ne postoji.", nameof(request.JedinicaMjereId), "Jedinica mjere ne postoji.");

            if (request.TrebaPreuzimanje)
            {
                if (string.IsNullOrWhiteSpace(request.AdresaPreuzimanja))
                    throw new ValidationException("Adresa preuzimanja je obavezna.", nameof(request.AdresaPreuzimanja), "Unesite adresu za preuzimanje.");

                if (string.IsNullOrWhiteSpace(request.TelefonPreuzimanja))
                    throw new ValidationException("Broj telefona je obavezan.", nameof(request.TelefonPreuzimanja), "Unesite kontakt telefon.");

                if (!request.DatumPreuzimanja.HasValue || request.DatumPreuzimanja.Value <= DateTime.UtcNow)
                    throw new ValidationException("Željeni termin preuzimanja mora biti u budućnosti.", nameof(request.DatumPreuzimanja), "Odaberite termin u budućnosti.");

                if (request.ZeljeniDatumDostave.HasValue)
                    throw new ValidationException("Željeni datum dostave nije primjenjiv kada azil preuzima donaciju.", nameof(request.ZeljeniDatumDostave), "Ovo polje se popunjava samo ako sami dostavljate donaciju.");
            }
            else
            {
                if (!string.IsNullOrWhiteSpace(request.AdresaPreuzimanja) || !string.IsNullOrWhiteSpace(request.TelefonPreuzimanja) || request.DatumPreuzimanja.HasValue)
                    throw new ValidationException("Podaci za preuzimanje su dozvoljeni samo ako je odabrano preuzimanje.", nameof(request.TrebaPreuzimanje), "Podaci o preuzimanju nisu primjenjivi.");

                if (request.ZeljeniDatumDostave.HasValue && request.ZeljeniDatumDostave.Value <= DateTime.UtcNow)
                    throw new ValidationException("Željeni datum dostave mora biti u budućnosti.", nameof(request.ZeljeniDatumDostave), "Odaberite datum u budućnosti.");
            }
        }

        var entity = new Database.Donacija
        {
            KorisnikId = korisnikId,
            TipDonacijeId = tip.TipDonacijeId,
            StatusDonacijeId = statusNaCekanju.StatusDonacijeId,
            Iznos = request.Iznos,
            DatumDonacije = DateTime.UtcNow,
            Napomena = request.Napomena,
            KategorijaDonacijeId = isNovcana ? null : request.KategorijaDonacijeId,
            PrilagodjenNaziv = isNovcana ? null : request.PrilagodjenNaziv,
            Kolicina = isNovcana ? null : request.Kolicina,
            JedinicaMjereId = isNovcana ? null : request.JedinicaMjereId,
            TrebaPreuzimanje = !isNovcana && request.TrebaPreuzimanje,
            AdresaPreuzimanja = isNovcana ? null : request.AdresaPreuzimanja,
            TelefonPreuzimanja = isNovcana ? null : request.TelefonPreuzimanja,
            DatumPreuzimanja = isNovcana ? null : request.DatumPreuzimanja,
            ZeljeniDatumDostave = isNovcana ? null : request.ZeljeniDatumDostave
        };

        string? clientSecret = null;

        await using var tx = await _context.Database.BeginTransactionAsync();
        try
        {
            _context.Donacijas.Add(entity);
            await _context.SaveChangesAsync();

            if (isNovcana)
            {
                var (paymentIntentId, secret) = await _stripePaymentService.CreatePaymentIntentAsync(request.Iznos!.Value, entity.DonacijaId, korisnikId);
                entity.StripePaymentIntentId = paymentIntentId;
                await _context.SaveChangesAsync();
                clientSecret = secret;
            }

            await tx.CommitAsync();
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }

        return new DonacijaPaymentResponse
        {
            Donacija = await GetById(entity.DonacijaId),
            ClientSecret = clientSecret
        };
    }

    public async Task<DonacijaPaymentResponse> RetryPlacanje(int id, int callerKorisnikId, bool isAdmin)
    {
        var entity = await _context.Donacijas
            .Include(d => d.TipDonacije)
            .Include(d => d.StatusDonacije)
            .FirstOrDefaultAsync(d => d.DonacijaId == id)
            ?? throw new NotFoundException($"Donacija s ID {id} nije pronađena.");

        if (!isAdmin && entity.KorisnikId != callerKorisnikId)
            throw new ForbiddenException("Nemate pristup ovoj donaciji.");

        if (entity.TipDonacije.Naziv != TipDonacijeNazivi.Novcana)
            throw new BusinessException("Ponovno plaćanje je moguće samo za novčane donacije.");

        if (entity.StatusDonacije.Naziv == StatusDonacijeNazivi.Uspjesna)
            throw new BusinessException("Donacija je već uspješno plaćena.");

        if (entity.StatusDonacije.Naziv == StatusDonacijeNazivi.Vracena)
            throw new BusinessException("Donacija je vraćena i ne može se ponovo platiti.");

        if (!string.IsNullOrEmpty(entity.StripePaymentIntentId))
        {
            var remote = await _stripePaymentService.GetPaymentIntentAsync(entity.StripePaymentIntentId);
            if (remote != null)
            {
                if (remote.Status == "succeeded")
                {
                    await HandlePaymentSucceededAsync(entity.StripePaymentIntentId);
                    throw new BusinessException("Donacija je već uspješno plaćena.");
                }

                await _stripePaymentService.TryCancelPaymentIntentAsync(entity.StripePaymentIntentId);
            }
        }

        var (paymentIntentId, clientSecret) = await _stripePaymentService.CreatePaymentIntentAsync(entity.Iznos!.Value, entity.DonacijaId, entity.KorisnikId);

        var statusNaCekanju = await _context.StatusDonacijes.FirstAsync(s => s.Naziv == StatusDonacijeNazivi.NaCekanju);
        entity.StripePaymentIntentId = paymentIntentId;
        entity.StatusDonacijeId = statusNaCekanju.StatusDonacijeId;
        await _context.SaveChangesAsync();

        return new DonacijaPaymentResponse
        {
            Donacija = await GetById(entity.DonacijaId),
            ClientSecret = clientSecret
        };
    }

    public async Task<Model.Donacija> Potvrdi(int id, int adminKorisnikId)
    {
        var entity = await _context.Donacijas
            .Include(d => d.TipDonacije)
            .Include(d => d.StatusDonacije)
            .FirstOrDefaultAsync(d => d.DonacijaId == id)
            ?? throw new NotFoundException($"Donacija s ID {id} nije pronađena.");

        if (entity.TipDonacije.Naziv != TipDonacijeNazivi.Materijalna)
            throw new BusinessException("Samo materijalna donacija se potvrđuje ručno.");

        if (entity.StatusDonacije.Naziv != StatusDonacijeNazivi.NaCekanju)
            throw new BusinessException("Donacija je već obrađena.");

        var statusUspjesna = await _context.StatusDonacijes.FirstAsync(s => s.Naziv == StatusDonacijeNazivi.Uspjesna);

        entity.StatusDonacijeId = statusUspjesna.StatusDonacijeId;
        entity.ObradioKorisnikId = adminKorisnikId;
        entity.DatumObrade = DateTime.UtcNow;

        _notifikacijaService.StageCreate(
            entity.KorisnikId,
            NotifikacijaTipovi.DonacijaPotvrdjena,
            "Donacija potvrđena",
            "Vaša materijalna donacija je potvrđena. Hvala Vam na doprinosu!",
            entity.DonacijaId);

        await _context.SaveChangesAsync();
        return await GetById(id);
    }

    public async Task<Model.Donacija> Odbij(int id, DonacijaOdbijRequest request, int adminKorisnikId)
    {
        var entity = await _context.Donacijas
            .Include(d => d.TipDonacije)
            .Include(d => d.StatusDonacije)
            .FirstOrDefaultAsync(d => d.DonacijaId == id)
            ?? throw new NotFoundException($"Donacija s ID {id} nije pronađena.");

        if (entity.TipDonacije.Naziv != TipDonacijeNazivi.Materijalna)
            throw new BusinessException("Samo materijalna donacija se odbija ručno.");

        if (entity.StatusDonacije.Naziv != StatusDonacijeNazivi.NaCekanju)
            throw new BusinessException("Donacija je već obrađena.");

        var statusNeuspjesna = await _context.StatusDonacijes.FirstAsync(s => s.Naziv == StatusDonacijeNazivi.Neuspjesna);

        entity.StatusDonacijeId = statusNeuspjesna.StatusDonacijeId;
        entity.ObradioKorisnikId = adminKorisnikId;
        entity.DatumObrade = DateTime.UtcNow;
        entity.RazlogOdbijanja = request.RazlogOdbijanja;

        _notifikacijaService.StageCreate(
            entity.KorisnikId,
            NotifikacijaTipovi.DonacijaOdbijena,
            "Donacija odbijena",
            $"Vaša materijalna donacija je odbijena. Razlog: {request.RazlogOdbijanja}",
            entity.DonacijaId);

        await _context.SaveChangesAsync();
        return await GetById(id);
    }

    public async Task<Model.Donacija> Refund(int id, DonacijaRefundRequest request, int adminKorisnikId)
    {
        var entity = await _context.Donacijas
            .Include(d => d.TipDonacije)
            .Include(d => d.StatusDonacije)
            .FirstOrDefaultAsync(d => d.DonacijaId == id)
            ?? throw new NotFoundException($"Donacija s ID {id} nije pronađena.");

        if (entity.TipDonacije.Naziv != TipDonacijeNazivi.Novcana)
            throw new BusinessException("Vraćanje sredstava je moguće samo za novčane donacije.");

        if (entity.StatusDonacije.Naziv != StatusDonacijeNazivi.Uspjesna)
            throw new BusinessException("Vraćanje sredstava je moguće samo za uspješno plaćene donacije.");

        if (!string.IsNullOrEmpty(entity.StripeRefundId))
            throw new ConflictException("Donacija je već vraćena.");

        if (string.IsNullOrEmpty(entity.StripePaymentIntentId))
            throw new BusinessException("Donacija nema povezano Stripe plaćanje.");

        var remotePaymentIntent = await _stripePaymentService.GetPaymentIntentAsync(entity.StripePaymentIntentId)
            ?? throw new BusinessException("Stripe plaćanje povezano s ovom donacijom više ne postoji.");
        var amountReceived = remotePaymentIntent.AmountReceived;
        if (amountReceived <= 0)
            throw new BusinessException("Stripe plaćanje nema naplaćen iznos za vraćanje.");

        var refundId = await _stripePaymentService.RefundAsync(entity.StripePaymentIntentId, amountReceived);

        var statusVracena = await _context.StatusDonacijes.FirstAsync(s => s.Naziv == StatusDonacijeNazivi.Vracena);

        entity.StripeRefundId = refundId;
        entity.StatusDonacijeId = statusVracena.StatusDonacijeId;
        entity.ObradioKorisnikId = adminKorisnikId;
        entity.DatumObrade = DateTime.UtcNow;
        entity.RazlogVracanja = request.RazlogVracanja;

        _notifikacijaService.StageCreate(
            entity.KorisnikId,
            NotifikacijaTipovi.DonacijaVracena,
            "Sredstva vraćena",
            $"Sredstva za Vašu donaciju su vraćena. Razlog: {request.RazlogVracanja}",
            entity.DonacijaId);

        await _context.SaveChangesAsync();
        return await GetById(id);
    }

    public async Task HandlePaymentSucceededAsync(string paymentIntentId)
    {
        var entity = await _context.Donacijas
            .Include(d => d.StatusDonacije)
            .FirstOrDefaultAsync(d => d.StripePaymentIntentId == paymentIntentId);

        if (entity == null || entity.StatusDonacije.Naziv != StatusDonacijeNazivi.NaCekanju)
            return;

        var statusUspjesna = await _context.StatusDonacijes.FirstAsync(s => s.Naziv == StatusDonacijeNazivi.Uspjesna);

        entity.StatusDonacijeId = statusUspjesna.StatusDonacijeId;
        entity.DatumObrade = DateTime.UtcNow;

        _notifikacijaService.StageCreate(
            entity.KorisnikId,
            NotifikacijaTipovi.DonacijaUspjesna,
            "Donacija uspješna",
            "Vaše plaćanje je uspješno obrađeno. Hvala Vam na donaciji!",
            entity.DonacijaId);

        await _context.SaveChangesAsync();
    }

    public async Task HandlePaymentFailedAsync(string paymentIntentId, string? reason)
    {
        var entity = await _context.Donacijas
            .Include(d => d.StatusDonacije)
            .FirstOrDefaultAsync(d => d.StripePaymentIntentId == paymentIntentId);

        if (entity == null || entity.StatusDonacije.Naziv != StatusDonacijeNazivi.NaCekanju)
            return;

        var statusNeuspjesna = await _context.StatusDonacijes.FirstAsync(s => s.Naziv == StatusDonacijeNazivi.Neuspjesna);

        entity.StatusDonacijeId = statusNeuspjesna.StatusDonacijeId;
        entity.DatumObrade = DateTime.UtcNow;
        entity.RazlogOdbijanja = reason;

        _notifikacijaService.StageCreate(
            entity.KorisnikId,
            NotifikacijaTipovi.DonacijaNeuspjesna,
            "Plaćanje nije uspjelo",
            "Vaše plaćanje nije uspjelo. Pokušajte ponovo ili kontaktirajte azil.",
            entity.DonacijaId);

        await _context.SaveChangesAsync();
    }

    public async Task<DonacijaIzvjestaj> GenerirajIzvjestaj(DateTime? datumOd, DateTime? datumDo)
    {
        var query = _context.Donacijas
            .Include(d => d.TipDonacije)
            .Include(d => d.StatusDonacije)
            .AsNoTracking()
            .AsQueryable();

        if (datumOd.HasValue)
            query = query.Where(d => d.DatumDonacije >= datumOd.Value);

        if (datumDo.HasValue)
            query = query.Where(d => d.DatumDonacije <= datumDo.Value);

        var podaci = await query
            .Select(d => new { d.DatumDonacije, d.Iznos, TipNaziv = d.TipDonacije.Naziv, StatusNaziv = d.StatusDonacije.Naziv })
            .ToListAsync();

        var uspjesneNovcane = podaci
            .Where(d => d.TipNaziv == TipDonacijeNazivi.Novcana && d.StatusNaziv == StatusDonacijeNazivi.Uspjesna)
            .ToList();

        var poMjesecu = uspjesneNovcane
            .GroupBy(d => new { d.DatumDonacije.Year, d.DatumDonacije.Month })
            .Select(g => new MjesecDonacijaStavka
            {
                Godina = g.Key.Year,
                Mjesec = g.Key.Month,
                MjesecNaziv = MjeseciNazivi.Naziv(g.Key.Month),
                Broj = g.Count(),
                Iznos = g.Sum(x => x.Iznos ?? 0)
            })
            .OrderBy(x => x.Godina).ThenBy(x => x.Mjesec)
            .ToList();

        List<StatusBrojStavka> PoStatusuZaTip(string tipNaziv) => podaci
            .Where(d => d.TipNaziv == tipNaziv)
            .GroupBy(d => d.StatusNaziv)
            .Select(g => new StatusBrojStavka { Status = g.Key, Broj = g.Count() })
            .OrderByDescending(x => x.Broj)
            .ToList();

        var novcanoPoStatusu = PoStatusuZaTip(TipDonacijeNazivi.Novcana);
        var materijalnoPoStatusu = PoStatusuZaTip(TipDonacijeNazivi.Materijalna);

        return new DonacijaIzvjestaj
        {
            DatumOd = datumOd,
            DatumDo = datumDo,
            NovcanePoMjesecima = poMjesecu,
            UkupnoBrojNovcanih = uspjesneNovcane.Count,
            UkupanIznos = uspjesneNovcane.Sum(d => d.Iznos ?? 0),
            NovcanoPoStatusu = novcanoPoStatusu,
            MaterijalnoPoStatusu = materijalnoPoStatusu,
            UkupnoSvih = podaci.Count
        };
    }
}
