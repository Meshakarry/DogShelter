using DogShelter.Services.Constants;
using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services;

// Content-based dog recommender: scoring weights/multipliers below and the algorithm they
// implement are documented in full (with a worked example) in recommender-dokumentacija.md
// at the repo root. Keep the two in sync if these constants change.
public class PreporukaService : IPreporukaService
{
    private const double PregledTypeWeight = 1.0;
    private const double PosjetaTypeWeight = 2.0;
    private const double ZahtjevTypeWeight = 3.0;
    private const double UdomljavanjeTypeWeight = 3.0;

    private const double RasaMatchMultiplier = 5.0;
    private const double VelicinaMatchMultiplier = 3.0;
    private const double AgeSimilarityBonus = 3.0;
    private const int AgeToleranceMonths = 24;
    private const double ViewPopularityMultiplier = 0.2;
    private const double ZahtjevPopularityMultiplier = 0.5;

    private readonly DogShelterContext _context;

    public PreporukaService(DogShelterContext context)
    {
        _context = context;
    }

    public async Task<List<Model.PreporuceniPas>> PreporuceniPsi(int korisnikId, int take)
    {
        var howMany = take > 0 ? take : 5;

        var pregledi = await _context.PregledPsas
            .Where(p => p.KorisnikId == korisnikId)
            .Select(p => new { p.Pas.RasaId, p.Pas.VelicinaPsaId, p.Pas.DatumRodjenja })
            .ToListAsync();

        var posjete = await _context.Posjeta
            .Where(p => p.KorisnikId == korisnikId && p.PasId != null)
            .Select(p => new { p.Pas!.RasaId, p.Pas.VelicinaPsaId, p.Pas.DatumRodjenja })
            .ToListAsync();

        var zahtjevi = await _context.ZahtjevZaUdomljavanjes
            .Where(z => z.KorisnikId == korisnikId)
            .Select(z => new { z.Pas.RasaId, z.Pas.VelicinaPsaId, z.Pas.DatumRodjenja })
            .ToListAsync();

        var udomljavanja = await _context.Udomljavanjes
            .Where(u => u.ZahtjevZaUdomljavanje.KorisnikId == korisnikId)
            .Select(u => new
            {
                u.ZahtjevZaUdomljavanje.Pas.RasaId,
                u.ZahtjevZaUdomljavanje.Pas.VelicinaPsaId,
                u.ZahtjevZaUdomljavanje.Pas.DatumRodjenja
            })
            .ToListAsync();

        var rasaTezine = new Dictionary<int, double>();
        var velicinaTezine = new Dictionary<int, double>();
        var starosti = new List<double>();

        void Akumuliraj(int rasaId, int velicinaId, DateOnly? datumRodjenja, double tezina)
        {
            rasaTezine[rasaId] = rasaTezine.GetValueOrDefault(rasaId) + tezina;
            velicinaTezine[velicinaId] = velicinaTezine.GetValueOrDefault(velicinaId) + tezina;
            if (datumRodjenja.HasValue)
                starosti.Add(StarostUMjesecima(datumRodjenja.Value));
        }

        foreach (var p in pregledi) Akumuliraj(p.RasaId, p.VelicinaPsaId, p.DatumRodjenja, PregledTypeWeight);
        foreach (var p in posjete) Akumuliraj(p.RasaId, p.VelicinaPsaId, p.DatumRodjenja, PosjetaTypeWeight);
        foreach (var z in zahtjevi) Akumuliraj(z.RasaId, z.VelicinaPsaId, z.DatumRodjenja, ZahtjevTypeWeight);
        foreach (var u in udomljavanja) Akumuliraj(u.RasaId, u.VelicinaPsaId, u.DatumRodjenja, UdomljavanjeTypeWeight);

        var imaSignala = rasaTezine.Count > 0 || velicinaTezine.Count > 0;
        double? preferiranaStarost = starosti.Count > 0 ? starosti.Average() : null;

        // A dog the caller already has a pending request for shouldn't be re-recommended;
        // already-approved/adopted dogs are excluded for free by the Dostupan status filter below.
        var naCekanjuPasIds = await _context.ZahtjevZaUdomljavanjes
            .Where(z => z.KorisnikId == korisnikId && z.StatusZahtjeva.Naziv == StatusZahtjevaNazivi.NaCekanju)
            .Select(z => z.PasId)
            .ToListAsync();

        var kandidati = await _context.Pas
            .Include(p => p.Rasa)
            .Include(p => p.VelicinaPsa)
            .Where(p => p.Aktivan && p.StatusPsa.Naziv == StatusPsaNazivi.Dostupan && !naCekanjuPasIds.Contains(p.PasId))
            .AsNoTracking()
            .ToListAsync();

        if (kandidati.Count == 0)
            return new List<Model.PreporuceniPas>();

        var candidateIds = kandidati.Select(k => k.PasId).ToList();

        var pregledBrojevi = await _context.PregledPsas
            .Where(p => candidateIds.Contains(p.PasId))
            .GroupBy(p => p.PasId)
            .Select(g => new { PasId = g.Key, Broj = g.Count() })
            .ToDictionaryAsync(x => x.PasId, x => x.Broj);

        var zahtjevBrojevi = await _context.ZahtjevZaUdomljavanjes
            .Where(z => candidateIds.Contains(z.PasId))
            .GroupBy(z => z.PasId)
            .Select(g => new { PasId = g.Key, Broj = g.Count() })
            .ToDictionaryAsync(x => x.PasId, x => x.Broj);

        var rezultati = new List<Model.PreporuceniPas>();
        foreach (var pas in kandidati)
        {
            var pregledBroj = pregledBrojevi.GetValueOrDefault(pas.PasId);
            var zahtjevBroj = zahtjevBrojevi.GetValueOrDefault(pas.PasId);

            var (skor, razlozi) = imaSignala
                ? IzracunajPersonalizovaniSkor(pas, rasaTezine, velicinaTezine, preferiranaStarost, pregledBroj, zahtjevBroj)
                : IzracunajPopularnostSkor(pregledBroj, zahtjevBroj);

            rezultati.Add(new Model.PreporuceniPas
            {
                PasId = pas.PasId,
                Naziv = pas.Naziv,
                RasaNaziv = pas.Rasa.Naziv,
                VelicinaNaziv = pas.VelicinaPsa.Naziv,
                SlikaNaslovna = pas.SlikaNaslovna,
                DatumRodjenja = pas.DatumRodjenja,
                Skor = Math.Round(skor, 2),
                Razlog = razlozi.Count > 0 ? CapitalizeFirst(string.Join("; ", razlozi)) + "." : "Preporučeno za vas.",
                Personalizovano = imaSignala
            });
        }

        return rezultati
            .OrderByDescending(r => r.Skor)
            .ThenBy(r => r.PasId)
            .Take(howMany)
            .ToList();
    }

    private static (double skor, List<string> razlozi) IzracunajPersonalizovaniSkor(
        Database.Pas pas,
        Dictionary<int, double> rasaTezine,
        Dictionary<int, double> velicinaTezine,
        double? preferiranaStarost,
        int pregledBroj,
        int zahtjevBroj)
    {
        double skor = 0;
        var razlozi = new List<string>();

        if (rasaTezine.TryGetValue(pas.RasaId, out var rTezina) && rTezina > 0)
        {
            skor += rTezina * RasaMatchMultiplier;
            razlozi.Add($"rasa \"{pas.Rasa.Naziv}\" odgovara vašim ranijim pregledima, posjetama ili zahtjevima");
        }

        if (velicinaTezine.TryGetValue(pas.VelicinaPsaId, out var vTezina) && vTezina > 0)
        {
            skor += vTezina * VelicinaMatchMultiplier;
            razlozi.Add($"veličina \"{pas.VelicinaPsa.Naziv}\" odgovara vašim preferencijama");
        }

        if (preferiranaStarost.HasValue && pas.DatumRodjenja.HasValue)
        {
            var starost = StarostUMjesecima(pas.DatumRodjenja.Value);
            var odstupanje = Math.Abs(starost - preferiranaStarost.Value);
            if (odstupanje <= AgeToleranceMonths)
            {
                skor += AgeSimilarityBonus * (1 - odstupanje / AgeToleranceMonths);
                razlozi.Add("slična starost psima koje ste ranije pregledali, posjetili ili tražili");
            }
        }

        if (pregledBroj > 0 || zahtjevBroj > 0)
        {
            skor += pregledBroj * ViewPopularityMultiplier + zahtjevBroj * ZahtjevPopularityMultiplier;
            razlozi.Add($"trenutno popularan ({pregledBroj} pregleda, {zahtjevBroj} zahtjeva)");
        }

        return (skor, razlozi);
    }

    private static (double skor, List<string> razlozi) IzracunajPopularnostSkor(int pregledBroj, int zahtjevBroj)
    {
        var skor = pregledBroj * ViewPopularityMultiplier + zahtjevBroj * ZahtjevPopularityMultiplier;
        var razlozi = new List<string> { $"trenutno popularan izbor ({pregledBroj} pregleda, {zahtjevBroj} zahtjeva)" };
        return (skor, razlozi);
    }

    private static double StarostUMjesecima(DateOnly datumRodjenja)
    {
        var danas = DateOnly.FromDateTime(DateTime.UtcNow);
        return ((danas.Year - datumRodjenja.Year) * 12) + (danas.Month - datumRodjenja.Month);
    }

    private static string CapitalizeFirst(string text)
        => string.IsNullOrEmpty(text) ? text : char.ToUpper(text[0]) + text[1..];
}
