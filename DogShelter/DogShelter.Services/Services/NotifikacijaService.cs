using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class NotifikacijaService : INotifikacijaService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;

    public NotifikacijaService(DogShelterContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public void StageCreate(int korisnikId, string tip, string naslov, string tekst, int? vezaniEntitetId = null)
    {
        _context.Notifikacijas.Add(new Database.Notifikacija
        {
            KorisnikId = korisnikId,
            Tip = tip,
            Naslov = naslov,
            Tekst = tekst,
            VezaniEntitetId = vezaniEntitetId,
            Procitano = false,
            DatumKreiranja = DateTime.UtcNow
        });
    }

    public async Task CreateAsync(int korisnikId, string tip, string naslov, string tekst, int? vezaniEntitetId = null)
    {
        StageCreate(korisnikId, tip, naslov, tekst, vezaniEntitetId);
        await _context.SaveChangesAsync();
    }

    public async Task<PagedResult<Model.Notifikacija>> Get(NotifikacijaSearchRequest search, int korisnikId)
    {
        var query = _context.Notifikacijas
            .AsNoTracking()
            .Where(n => n.KorisnikId == korisnikId);

        if (search.Procitano.HasValue)
            query = query.Where(n => n.Procitano == search.Procitano.Value);

        query = query.OrderByDescending(n => n.DatumKreiranja);

        return await PagedQueryHelper.ToPagedResultAsync<Database.Notifikacija, Model.Notifikacija>(query, search, _mapper);
    }

    public Task<int> GetUnreadCount(int korisnikId) =>
        _context.Notifikacijas.CountAsync(n => n.KorisnikId == korisnikId && !n.Procitano);

    public async Task<bool> OznaciProcitano(int korisnikId, int notifikacijaId)
    {
        var entity = await _context.Notifikacijas
            .FirstOrDefaultAsync(n => n.NotifikacijaId == notifikacijaId && n.KorisnikId == korisnikId);
        if (entity == null)
            return false;

        entity.Procitano = true;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task OznaciSveProcitano(int korisnikId)
    {
        var neprocitane = await _context.Notifikacijas
            .Where(n => n.KorisnikId == korisnikId && !n.Procitano)
            .ToListAsync();

        if (neprocitane.Count == 0)
            return;

        foreach (var n in neprocitane)
            n.Procitano = true;

        await _context.SaveChangesAsync();
    }
}
