using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

public class PretragaLogService : IPretragaLogService
{
    private readonly DogShelterContext _context;

    public PretragaLogService(DogShelterContext context)
    {
        _context = context;
    }

    private static readonly TimeSpan DedupWindow = TimeSpan.FromHours(24);

    public async Task LogPretragaAsync(PasSearchRequest search, int korisnikId, bool isAdmin)
    {
        if (isAdmin) return;

        var hasFilter = search.RasaId.HasValue || search.VelicinaPsaId.HasValue
            || search.NivoAktivnostiId.HasValue || search.Spol.HasValue;
        if (!hasFilter) return;

        // Dedup: the same filter combo within 24h is one preference signal, not many. Without
        // this, flicking a filter dropdown back and forth accumulates unbounded weight
        // (FilterTypeWeight each time) that can outrank a real visit/favorite/request in
        // PreporukaService's scoring.
        var cutoff = DateTime.UtcNow.Subtract(DedupWindow);
        var alreadyLogged = await _context.PretragaLogs.AnyAsync(p =>
            p.KorisnikId == korisnikId
            && p.RasaId == search.RasaId
            && p.VelicinaPsaId == search.VelicinaPsaId
            && p.NivoAktivnostiId == search.NivoAktivnostiId
            && p.Spol == search.Spol
            && p.DatumPretrage >= cutoff);
        if (alreadyLogged) return;

        _context.PretragaLogs.Add(new PretragaLog
        {
            KorisnikId = korisnikId,
            RasaId = search.RasaId,
            VelicinaPsaId = search.VelicinaPsaId,
            NivoAktivnostiId = search.NivoAktivnostiId,
            Spol = search.Spol,
            DatumPretrage = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
    }
}
