using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class VolonterService : IVolonterService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;

    public VolonterService(DogShelterContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    private IQueryable<Database.Volonter> BaseQuery() =>
        _context.Volonters
            .Include(v => v.Korisnik)
            .AsNoTracking();

    public async Task<PagedResult<Model.Volonter>> Get(VolonterSearchRequest search)
    {
        var query = BaseQuery();

        if (search.Aktivan.HasValue)
            query = query.Where(v => v.Aktivan == search.Aktivan.Value);

        if (!string.IsNullOrWhiteSpace(search.Ime))
            query = query.Where(v => v.Korisnik.Ime.Contains(search.Ime) || v.Korisnik.Prezime.Contains(search.Ime));

        query = query.OrderByDescending(v => v.VolonterId);

        var result = await PagedQueryHelper.ToPagedResultAsync<Database.Volonter, Model.Volonter>(query, search, _mapper);

        await AttachUkupnoSatiAsync(result.Items);

        return result;
    }

    public async Task<Model.Volonter> GetById(int id)
    {
        var entity = await BaseQuery().FirstOrDefaultAsync(v => v.VolonterId == id)
            ?? throw new NotFoundException($"Volonter s ID {id} nije pronađen.");

        var model = _mapper.Map<Model.Volonter>(entity);
        await AttachUkupnoSatiAsync([model]);

        return model;
    }

    public async Task<Model.Volonter?> GetByKorisnikId(int korisnikId)
    {
        var entity = await BaseQuery().FirstOrDefaultAsync(v => v.KorisnikId == korisnikId);
        if (entity == null) return null;

        var model = _mapper.Map<Model.Volonter>(entity);
        await AttachUkupnoSatiAsync([model]);

        return model;
    }

    public async Task<Model.Volonter> Insert(VolonterInsertRequest request)
    {
        var korisnik = await _context.Korisniks.FindAsync(request.KorisnikId)
            ?? throw new ValidationException("Odabrani korisnik ne postoji.", nameof(request.KorisnikId), "Korisnik ne postoji.");

        if (await _context.Volonters.AnyAsync(v => v.KorisnikId == request.KorisnikId))
            throw new BusinessException("Korisnik je već registrovan kao volonter.");

        var entity = new Database.Volonter
        {
            KorisnikId = request.KorisnikId,
            DatumPridruzivanja = request.DatumPridruzivanja,
            Aktivan = true,
            Napomena = request.Napomena
        };

        _context.Volonters.Add(entity);

        var volonterRole = await _context.Ulogas.FirstOrDefaultAsync(r => r.Naziv == RoleNames.Volonter)
            ?? throw new BusinessException("Uloga 'Volonter' nije podešena u sistemu.");

        var hasRole = await _context.KorisnikUlogas
            .AnyAsync(ur => ur.KorisnikId == request.KorisnikId && ur.UlogaId == volonterRole.UlogaId);

        if (!hasRole)
            _context.KorisnikUlogas.Add(new Database.KorisnikUloga { KorisnikId = request.KorisnikId, UlogaId = volonterRole.UlogaId });

        await _context.SaveChangesAsync();

        return await GetById(entity.VolonterId);
    }

    public async Task<Model.Volonter> Update(int id, VolonterUpdateRequest request)
    {
        var entity = await _context.Volonters.FindAsync(id)
            ?? throw new NotFoundException($"Volonter s ID {id} nije pronađen.");

        var wasActive = entity.Aktivan;
        entity.Aktivan = request.Aktivan;
        entity.Napomena = request.Napomena;

        // Keeps the Korisnik.Volonter role in sync with the volunteer profile's Aktivan flag -
        // without this, a deactivated volunteer keeps the role (and, via a still-valid JWT, the
        // access that comes with it) even though AktivnostVolonteraService now also refuses them
        // at the profile-lookup level. Deactivating and reactivating both bump the user's
        // security stamp so any already-issued token picks up the role change immediately
        // instead of on its next natural expiry (same mechanism as KorisnikService.Update()).
        if (wasActive != request.Aktivan)
        {
            var volonterRole = await _context.Ulogas.FirstOrDefaultAsync(r => r.Naziv == RoleNames.Volonter)
                ?? throw new BusinessException("Uloga 'Volonter' nije podešena u sistemu.");

            var korisnik = await _context.Korisniks.FindAsync(entity.KorisnikId)
                ?? throw new NotFoundException("Korisnik povezan sa volonterom nije pronađen.");

            if (!request.Aktivan)
            {
                var ku = await _context.KorisnikUlogas
                    .FirstOrDefaultAsync(x => x.KorisnikId == entity.KorisnikId && x.UlogaId == volonterRole.UlogaId);
                if (ku != null)
                    _context.KorisnikUlogas.Remove(ku);
            }
            else
            {
                var hasRole = await _context.KorisnikUlogas
                    .AnyAsync(x => x.KorisnikId == entity.KorisnikId && x.UlogaId == volonterRole.UlogaId);
                if (!hasRole)
                    _context.KorisnikUlogas.Add(new Database.KorisnikUloga { KorisnikId = entity.KorisnikId, UlogaId = volonterRole.UlogaId });
            }

            korisnik.SigurnosniPecat = Guid.NewGuid();
        }

        await _context.SaveChangesAsync();

        return await GetById(id);
    }

    private async Task AttachUkupnoSatiAsync(IReadOnlyCollection<Model.Volonter> volonteri)
    {
        if (volonteri.Count == 0) return;

        var ids = volonteri.Select(v => v.VolonterId).ToList();
        var sati = await _context.AktivnostVolonteras
            .Where(a => ids.Contains(a.VolonterId))
            .GroupBy(a => a.VolonterId)
            .Select(g => new { VolonterId = g.Key, Ukupno = g.Sum(a => a.BrojSati) })
            .ToDictionaryAsync(x => x.VolonterId, x => x.Ukupno);

        foreach (var v in volonteri)
            v.UkupnoSati = sati.TryGetValue(v.VolonterId, out var ukupno) ? ukupno : 0;
    }
}
