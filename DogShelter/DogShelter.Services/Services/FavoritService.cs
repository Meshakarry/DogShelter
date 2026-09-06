using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class FavoritService : Interfaces.IFavoritService
{
    private readonly DogShelterContext _context;

    public FavoritService(DogShelterContext context)
    {
        _context = context;
    }

    public async Task<List<Model.Favorit>> GetMineAsync(int korisnikId)
    {
        var entities = await FavoritQuery().Where(f => f.KorisnikId == korisnikId)
            .OrderByDescending(f => f.DatumDodavanja)
            .ToListAsync();

        return entities.Select(ToModel).ToList();
    }

    public async Task<Model.Favorit> AddAsync(int korisnikId, int pasId)
    {
        if (!await _context.Pas.AnyAsync(p => p.PasId == pasId))
            throw new NotFoundException($"Pas s ID {pasId} nije pronađen.");

        // Idempotent - a double-tap or a stale toggle-button state re-adding an already-favorited
        // dog just returns the existing row instead of failing on the unique index.
        var favoritId = await _context.Favorits
            .Where(f => f.KorisnikId == korisnikId && f.PasId == pasId)
            .Select(f => (int?)f.FavoritId)
            .FirstOrDefaultAsync();

        if (favoritId == null)
        {
            var entity = new Database.Favorit { KorisnikId = korisnikId, PasId = pasId };
            _context.Favorits.Add(entity);
            await _context.SaveChangesAsync();
            favoritId = entity.FavoritId;
        }

        var favorit = await FavoritQuery().FirstAsync(f => f.FavoritId == favoritId);
        return ToModel(favorit);
    }

    private IQueryable<Database.Favorit> FavoritQuery() => _context.Favorits
        .Include(f => f.Pas).ThenInclude(p => p.Rasa)
        .Include(f => f.Pas).ThenInclude(p => p.VelicinaPsa)
        .Include(f => f.Pas).ThenInclude(p => p.StatusPsa)
        .AsNoTracking();

    private static Model.Favorit ToModel(Database.Favorit f) => new()
    {
        FavoritId = f.FavoritId,
        KorisnikId = f.KorisnikId,
        PasId = f.PasId,
        DatumDodavanja = f.DatumDodavanja,
        PasNaziv = f.Pas.Naziv,
        RasaNaziv = f.Pas.Rasa.Naziv,
        VelicinaNaziv = f.Pas.VelicinaPsa.Naziv,
        SlikaNaslovna = f.Pas.SlikaNaslovna,
        StatusNaziv = f.Pas.StatusPsa.Naziv,
        PasAktivan = f.Pas.Aktivan
    };

    public async Task RemoveAsync(int korisnikId, int pasId)
    {
        var existing = await _context.Favorits
            .FirstOrDefaultAsync(f => f.KorisnikId == korisnikId && f.PasId == pasId);

        if (existing == null) return;

        _context.Favorits.Remove(existing);
        await _context.SaveChangesAsync();
    }
}
