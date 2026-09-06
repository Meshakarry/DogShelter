using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;

namespace DogShelter.Services.Services;

public class PretragaLogService : IPretragaLogService
{
    private readonly DogShelterContext _context;

    public PretragaLogService(DogShelterContext context)
    {
        _context = context;
    }

    public async Task LogPretragaAsync(PasSearchRequest search, int korisnikId, bool isAdmin)
    {
        if (isAdmin) return;

        var hasFilter = search.RasaId.HasValue || search.VelicinaPsaId.HasValue
            || search.NivoAktivnostiId.HasValue || search.Spol.HasValue;
        if (!hasFilter) return;

        _context.PretragaLogs.Add(new PretragaLog
        {
            KorisnikId = korisnikId,
            RasaId = search.RasaId,
            VelicinaPsaId = search.VelicinaPsaId,
            NivoAktivnostiId = search.NivoAktivnostiId,
            Spol = search.Spol
        });

        await _context.SaveChangesAsync();
    }
}
