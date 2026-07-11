using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using DogShelter.Services.Constants;
using static DogShelter.Model.Spol;

namespace DogShelter.Services.Database;

public static class DatabaseSeeder
{
    public static async Task SeedAllAsync(DogShelterContext context, ILogger logger, string wwwrootPath)
    {
        await EnsureVelicinePsaAsync(context, logger);
        await EnsureStatusPsaAsync(context, logger);
        await EnsureStatusZahtjevaAsync(context, logger);
        await EnsureStatusPosjeteAsync(context, logger);
        await EnsureRaseAsync(context, logger);
        await EnsurePsiAsync(context, logger, wwwrootPath);
        await EnsureZahtjeviAsync(context, logger);
        await EnsurePosjeteAsync(context, logger);
    }

    /// <summary>
    /// Copies a seed image from SeedData/Images/{baseName}.jpg into wwwroot/images/psi/.
    /// Returns the relative URL stored in DB, or null if source file not found.
    /// </summary>
    private static string? CopySeedImage(string baseName, string wwwrootPath, ILogger logger)
    {
        var sourceDirs = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "SeedData", "Images"),
            Path.Combine(Directory.GetCurrentDirectory(), "SeedData", "Images"),
        };

        var destDir = Path.Combine(wwwrootPath, "images", "psi");
        Directory.CreateDirectory(destDir);

        var destFile = Path.Combine(destDir, baseName + ".jpg");
        if (File.Exists(destFile))
            return $"/images/psi/{baseName}.jpg";

        foreach (var dir in sourceDirs)
        {
            var source = Path.Combine(dir, baseName + ".jpg");
            if (!File.Exists(source)) continue;
            File.Copy(source, destFile);
            return $"/images/psi/{baseName}.jpg";
        }

        logger.LogWarning("Seed image not found: {BaseName}.jpg", baseName);
        return null;
    }

    private static async Task EnsureVelicinePsaAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[] { "Mala", "Srednja", "Velika", "Džinovska" };
        foreach (var naziv in names)
        {
            if (!await context.VelicinaPsas.AnyAsync(v => v.Naziv == naziv))
                context.VelicinaPsas.Add(new VelicinaPsa { Naziv = naziv });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded VelicinaPsa.");
    }

    private static async Task EnsureStatusPsaAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[] { "Dostupan", "Udomljen", "U tretmanu", "Ugašen" };
        foreach (var naziv in names)
        {
            if (!await context.StatusPsas.AnyAsync(s => s.Naziv == naziv))
                context.StatusPsas.Add(new StatusPsa { Naziv = naziv });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded StatusPsa.");
    }

    private static async Task EnsureStatusZahtjevaAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[] { StatusZahtjevaNazivi.NaCekanju, StatusZahtjevaNazivi.Odobren, StatusZahtjevaNazivi.Odbijen };
        foreach (var naziv in names)
        {
            if (!await context.StatusZahtjevas.AnyAsync(s => s.Naziv == naziv))
                context.StatusZahtjevas.Add(new StatusZahtjeva { Naziv = naziv });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded StatusZahtjeva.");
    }

    private static async Task EnsureStatusPosjeteAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[] { StatusPosjeteNazivi.NaCekanju, StatusPosjeteNazivi.Potvrdjena, StatusPosjeteNazivi.Otkazana, StatusPosjeteNazivi.Zavrsena };
        foreach (var naziv in names)
        {
            if (!await context.StatusPosjetes.AnyAsync(s => s.Naziv == naziv))
                context.StatusPosjetes.Add(new StatusPosjete { Naziv = naziv });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded StatusPosjete.");
    }

    private static async Task EnsureRaseAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[]
        {
            "Labrador retriver", "Njemački ovčar", "Mješanac", "Dalmatinac",
            "Pudl", "Boksač", "Zlatni retriver", "Čivava", "Border koli", "Husky",
            "Tornjak", "Rottweiler", "Beagle"
        };
        foreach (var naziv in names)
        {
            if (!await context.Rasas.AnyAsync(r => r.Naziv == naziv))
                context.Rasas.Add(new Rasa { Naziv = naziv, Aktivan = true });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded Rasa.");
    }

    private static async Task EnsurePsiAsync(DogShelterContext context, ILogger logger, string wwwrootPath)
    {
        if (await context.Pas.AnyAsync()) return;

        var sDostupan  = await context.StatusPsas.FirstAsync(s => s.Naziv == "Dostupan");
        var sTretman   = await context.StatusPsas.FirstAsync(s => s.Naziv == "U tretmanu");
        var sUdomljen  = await context.StatusPsas.FirstAsync(s => s.Naziv == "Udomljen");
        var sUgasen    = await context.StatusPsas.FirstAsync(s => s.Naziv == "Ugašen");

        var vMala      = await context.VelicinaPsas.FirstAsync(v => v.Naziv == "Mala");
        var vSrednja   = await context.VelicinaPsas.FirstAsync(v => v.Naziv == "Srednja");
        var vVelika    = await context.VelicinaPsas.FirstAsync(v => v.Naziv == "Velika");
        var vDzinovska = await context.VelicinaPsas.FirstAsync(v => v.Naziv == "Džinovska");

        var rLab        = await context.Rasas.FirstAsync(r => r.Naziv == "Labrador retriver");
        var rNjemacki   = await context.Rasas.FirstAsync(r => r.Naziv == "Njemački ovčar");
        var rMjesanac   = await context.Rasas.FirstAsync(r => r.Naziv == "Mješanac");
        var rDalma      = await context.Rasas.FirstAsync(r => r.Naziv == "Dalmatinac");
        var rPudl       = await context.Rasas.FirstAsync(r => r.Naziv == "Pudl");
        var rBokser     = await context.Rasas.FirstAsync(r => r.Naziv == "Boksač");
        var rGolden     = await context.Rasas.FirstAsync(r => r.Naziv == "Zlatni retriver");
        var rCivava     = await context.Rasas.FirstAsync(r => r.Naziv == "Čivava");
        var rBorder     = await context.Rasas.FirstAsync(r => r.Naziv == "Border koli");
        var rHusky      = await context.Rasas.FirstAsync(r => r.Naziv == "Husky");
        var rTornjak    = await context.Rasas.FirstAsync(r => r.Naziv == "Tornjak");
        var rRottweiler = await context.Rasas.FirstAsync(r => r.Naziv == "Rottweiler");
        var rBeagle     = await context.Rasas.FirstAsync(r => r.Naziv == "Beagle");

        string Img(string name) => CopySeedImage(name, wwwrootPath, logger) ?? string.Empty;

        var psi = new Pas[]
        {
            // 1 ── Luna (Dostupan, Velika, ženka, 3 god)
            new() { Naziv = "Luna",    RasaId = rLab.RasaId,        Spol = Zenka,  StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 27.5m, DatumPrijema = new DateOnly(2024,  3, 10), DatumRodjenja = new DateOnly(2022,  6,  1), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas1"),  Opis = "Lunica je pravi ljubimac azila – odmah priđe svakom posjetitelju, zamahne repom i traži mazanje. Jako se slaže s djecom i navikla je na kućni život. Morala je doći k nama zbog selidbe vlasnika u inostranstvo. Zna osnovne komande i čista je u kući. Traži topao dom s puno pažnje." },
            // 2 ── Rex (Dostupan, Velika, mužjak, 4 god)
            new() { Naziv = "Rex",     RasaId = rNjemacki.RasaId,   Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 34.0m, DatumPrijema = new DateOnly(2024,  5, 20), DatumRodjenja = new DateOnly(2021,  4, 15), Vakcinisan = true,  Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas2"),  Opis = "Rex je bio u obuci za policijskog psa, ali zbog prevelike igrivosti nije prošao selekciju. Izrazito inteligentan i lojalan, ali treba vlasnika koji ima iskustva s pastirskim rasama. Odlično reaguje na nagrade i konsistentnu obuku. Nije preporučljiv za porodice s malom djecom bez prethodne socijalizacije." },
            // 3 ── Bella (Dostupan, Srednja, ženka, nepoznata starost)
            new() { Naziv = "Bella",   RasaId = rMjesanac.RasaId,   Spol = Zenka,  StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vSrednja.VelicinaPsaId,   Tezina = 17.5m, DatumPrijema = new DateOnly(2024,  1,  5), DatumRodjenja = null,                      Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas3"),  Opis = "Bella je pronađena uz cestu u lošem stanju – uplašena i iscrpljena. Sada je puna snage i sreće. Malo je stidljiva pri prvom susretu, ali brzo se opusti uz mirne ljude. Voli šetnje i sunčanje ispred azila, a s ostalim psima se slaže bez imalo problema." },
            // 4 ── Max (Udomljen, Srednja, mužjak, 3 god)
            new() { Naziv = "Max",     RasaId = rDalma.RasaId,      Spol = Muzjak, StatusPsaId = sUdomljen.StatusPsaId, VelicinaPsaId = vSrednja.VelicinaPsaId,   Tezina = 23.0m, DatumPrijema = new DateOnly(2023, 11, 12), DatumRodjenja = new DateOnly(2022,  3, 20), Vakcinisan = true,  Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas4"),  Opis = "Max je pronašao svoju porodicu! Energičan i bezbrižan dalmatinac otišao je u dom s troje djece i prostranim dvorištem. Odrastao je uz trčanje i igru – nova porodica mu pruža upravo to." },
            // 5 ── Zlatko (Dostupan, Velika, mužjak, 2 god)
            new() { Naziv = "Zlatko",  RasaId = rGolden.RasaId,     Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 29.5m, DatumPrijema = new DateOnly(2024,  6,  1), DatumRodjenja = new DateOnly(2023,  1, 10), Vakcinisan = true,  Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas5"),  Opis = "Mlad i bezbrižan, Zlatko je štene u tijelu odraslog psa. Žvače sve do čega dođe, ali ne možeš mu se naljutiti. Obožava vodu, bacanje loptice i beskonačno grljenje. S psima ide odlično, a mačke još upoznaje uz nadzor. Idealan za aktivne porodice." },
            // 6 ── Maci (U tretmanu, Srednja, ženka, 4 god)
            new() { Naziv = "Maci",    RasaId = rBorder.RasaId,     Spol = Zenka,  StatusPsaId = sTretman.StatusPsaId,  VelicinaPsaId = vSrednja.VelicinaPsaId,   Tezina = 15.5m, DatumPrijema = new DateOnly(2024,  4,  8), DatumRodjenja = new DateOnly(2021,  9,  5), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas6"),  Opis = "Maci je bila pronađena na putu s ozljedom prednje šape. Šapa je operisana i sada je na fizioterapiji. Izrazito pametan border koli koji treba mentalnu stimulaciju. Veterinar procjenjuje da će biti potpuno zdrava za tri do četiri sedmice." },
            // 7 ── Vuk (Dostupan, Velika, mužjak, 4 god)
            new() { Naziv = "Vuk",     RasaId = rHusky.RasaId,      Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 26.5m, DatumPrijema = new DateOnly(2023,  9, 15), DatumRodjenja = new DateOnly(2021, 12,  1), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas7"),  Opis = "Vuk se voli činiti ozbiljnim, ali je u stvari potpuna dramska diva. Huče, glasno razgovara i traži pažnju svake sekunde. Odrastao je na otvorenom i treba dvorište – nije za stan. S psima ide sjajno, ali mačkama je nepredvidiv. Nije za početnike." },
            // 8 ── Roki (Dostupan, Velika, mužjak, 5 god)
            new() { Naziv = "Roki",    RasaId = rBokser.RasaId,     Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 31.0m, DatumPrijema = new DateOnly(2024,  2, 28), DatumRodjenja = new DateOnly(2020,  7,  4), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas8"),  Opis = "Roki je prava stara duša – miran, uglađen i zna svoja pravila. Idealan za mir i tišinu kućnog života. Voli kratke šetnje ujutro i dugačka drijemanja poslijepodne. Nervozni ambijent ga umori, pa nije idealan za domove s malom djecom." },
            // 9 ── Pahulja (Dostupan, Mala, ženka, 2 god)
            new() { Naziv = "Pahulja", RasaId = rPudl.RasaId,       Spol = Zenka,  StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vMala.VelicinaPsaId,      Tezina =  6.0m, DatumPrijema = new DateOnly(2024,  7, 18), DatumRodjenja = new DateOnly(2023,  5, 15), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas9"),  Opis = "Pahulja brine o svojoj frizuri više nego o mišima u dvorištu. Mala, elegantna i pametna do bola. Jako je vezana za ljude i ne podnosi dugo ostati sama. Podučena je čistim manirima i voli rutinu. Savršena za stan i za vlasnike koji imaju vremena za njenu pažnju." },
            // 10 ── Šaki (Dostupan, Mala, mužjak, nepoznata starost)
            new() { Naziv = "Šaki",    RasaId = rCivava.RasaId,     Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vMala.VelicinaPsaId,      Tezina =  2.8m, DatumPrijema = new DateOnly(2024,  8,  3), DatumRodjenja = null,                      Vakcinisan = false, Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas10"), Opis = "Šaki je primljen bez ikakvog dokumenta – nađen je u kartonskoj kutiji kod tržnog centra. Starost se procjenjuje na 2-4 godine. Nije bio vakcinisan ni registrovan. Zna biti glasaša i mrzovoljan prema nepoznatima, ali s poznatim ljudima je topla i privržena maža." },
            // 11 ── Bora (Dostupan, Džinovska, mužjak, 5 god)
            new() { Naziv = "Bora",    RasaId = rTornjak.RasaId,    Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vDzinovska.VelicinaPsaId, Tezina = 52.0m, DatumPrijema = new DateOnly(2023,  6, 10), DatumRodjenja = new DateOnly(2020, 11, 10), Vakcinisan = true,  Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas11"), Opis = "Bora je pravi tornjak – čuva, pazi i laje na sve nepoznato. Nije pas za stan ni za lančanje uz kuću. Treba imanje, ograđeno dvorište i vlasnika koji razumije pastirske rase. U azilu je miran i omiljen kod osoblja, ali zaslužuje pravi dom u prirodi." },
            // 12 ── Sjena (U tretmanu, Srednja, ženka, nepoznata starost)
            new() { Naziv = "Sjena",   RasaId = rMjesanac.RasaId,   Spol = Zenka,  StatusPsaId = sTretman.StatusPsaId,  VelicinaPsaId = vSrednja.VelicinaPsaId,   Tezina = 13.0m, DatumPrijema = new DateOnly(2024,  9,  1), DatumRodjenja = null,                      Vakcinisan = false, Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas12"), Opis = "Sjena je dovedena u veoma lošem stanju – pothranjujuća i jako uplašena. Sada je na veterinarskom oporavku i polako gradi povjerenje prema ljudima. Traži posebno strpljivog vlasnika koji razumije pse s traumom i zna da je put do srca nekad dug." },
            // 13 ── Hektor (Dostupan, Džinovska, mužjak, 4 god)
            new() { Naziv = "Hektor",  RasaId = rRottweiler.RasaId, Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vDzinovska.VelicinaPsaId, Tezina = 48.0m, DatumPrijema = new DateOnly(2024,  3, 22), DatumRodjenja = new DateOnly(2021,  8, 22), Vakcinisan = true,  Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas13"), Opis = "Hektor izgleda zastrašujuće, ali uz pravu osobu je potpuno drugačiji. Socijaliziran je s odraslim psima i nema agresivnih ispada. Zna sjesti, leći i javiti se šapom. Treba iskusnog vlasnika koji zna postaviti granice. Zaslužuje drugu šansu u toplom domu." },
            // 14 ── Lola (Udomljen, Velika, ženka, 3 god)
            new() { Naziv = "Lola",    RasaId = rLab.RasaId,        Spol = Zenka,  StatusPsaId = sUdomljen.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 25.0m, DatumPrijema = new DateOnly(2023,  8, 14), DatumRodjenja = new DateOnly(2022, 11, 30), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas14"), Opis = "Lola je pronašla dom! Otišla je živjeti s porodicom koja ju je čekala skoro godinu dana. Sada šeta po prostranom dvorištu i spava pored dječjeg kreveta. Laboratori doista zaslužuju sve što im se da." },
            // 15 ── Medo (Ugašen, Velika, mužjak, 11 god)
            new() { Naziv = "Medo",    RasaId = rMjesanac.RasaId,   Spol = Muzjak, StatusPsaId = sUgasen.StatusPsaId,   VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 22.0m, DatumPrijema = new DateOnly(2014,  4,  1), DatumRodjenja = new DateOnly(2013,  4,  1), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas15"), Opis = "Medo je preminuo prirodnom smrću u svojoj jedanaestoj godini, okružen osobljem azila koje ga je voljelo kao da je bio kućni ljubimac. Proveo je skoro deset godina u azilu jer ga niko nije htio, ali nikada nije ostao bez ljubavi. Čuvamo ga u sjećanju." },
            // 16 ── Zara (Dostupan, Velika, ženka, 2 god)
            new() { Naziv = "Zara",    RasaId = rNjemacki.RasaId,   Spol = Zenka,  StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 28.0m, DatumPrijema = new DateOnly(2024,  7,  5), DatumRodjenja = new DateOnly(2023,  3, 18), Vakcinisan = true,  Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas16"), Opis = "Zara je mlada štenerka koja još uči šta znači biti pas. Primljena je kao lutalica s nepunih godinu dana. Divlja, radoznala i puna energije koja nikad ne prestaje. Treba dosljednu obuku i socijalizaciju. Nije preporučljiva za prvu adopciju, ali uz iskusnog vlasnika ima ogroman potencijal." },
            // 17 ── Đuro (Dostupan, Mala, mužjak, nepoznata starost)
            new() { Naziv = "Đuro",    RasaId = rMjesanac.RasaId,   Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vMala.VelicinaPsaId,      Tezina =  8.5m, DatumPrijema = new DateOnly(2024,  5, 30), DatumRodjenja = null,                      Vakcinisan = false, Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas17"), Opis = "Đuro je mali mješanac koji si nikad ne daje mira. Skakuće, trčkara i hvata sve što mu se nađe pred nosom. Procjenjuje se da ima između jedne i tri godine. Nije bio vakcinisan pri dolasku. S psima u azilu se odlično slaže i uvijek je raspoložen za igru." },
            // 18 ── Nera (Udomljen, Džinovska, ženka, 5 god)
            new() { Naziv = "Nera",    RasaId = rTornjak.RasaId,    Spol = Zenka,  StatusPsaId = sUdomljen.StatusPsaId, VelicinaPsaId = vDzinovska.VelicinaPsaId, Tezina = 44.0m, DatumPrijema = new DateOnly(2023,  4, 20), DatumRodjenja = new DateOnly(2020,  6, 15), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas18"), Opis = "Nera je udomljena i otišla je živjeti na farmu u blizini Kiseljaka. Tornjak kakav treba biti – mirna, dostojanstvena i puna prirodne inteligencije. Čuvamo fotografije od prvog dana do odlaska." },
            // 19 ── Piki (Dostupan, Srednja, mužjak, 1 god)
            new() { Naziv = "Piki",    RasaId = rBeagle.RasaId,     Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vSrednja.VelicinaPsaId,   Tezina = 11.5m, DatumPrijema = new DateOnly(2024,  9, 12), DatumRodjenja = new DateOnly(2023,  9,  1), Vakcinisan = true,  Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas19"), Opis = "Piki je štene u punom smislu te riječi. Nos mu uvijek ide naprijed, a glava se tek kasnije javi. Beagle rasa traži puno kretanja i mentalne stimulacije. Odlično s djecom – može se igrati satima bez prestanka. Idealan za aktivne porodice sa dvorištem." },
        };

        context.Pas.AddRange(psi);
        await context.SaveChangesAsync();

        var slikePse = new List<SlikaPsa>();
        for (int i = 0; i < psi.Length; i++)
            slikePse.Add(new SlikaPsa { PasId = psi[i].PasId, Putanja = Img($"pas{i + 1}"), RedniBroj = 1 });

        var galerijaExtra = new (int Idx, int Redni, string BaseName)[]
        {
            (0,  2, "pas1_2"),
            (0,  3, "pas1_3"),
            (4,  2, "pas5_2"),
            (4,  3, "pas5_3"),
            (6,  2, "pas7_2"),
            (6,  3, "pas7_3"),
            (10, 2, "pas11_2"),
            (10, 3, "pas11_3"),
            (12, 2, "pas13_2"),
            (18, 2, "pas19_2"),
        };

        foreach (var (idx, redni, baseName) in galerijaExtra)
            slikePse.Add(new SlikaPsa { PasId = psi[idx].PasId, Putanja = Img(baseName), RedniBroj = redni });

        context.SlikaPsas.AddRange(slikePse);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} pasa i {SlikaCount} slika.", psi.Length, slikePse.Count);
    }

    /// <summary>
    /// Seeds a handful of ZahtjevZaUdomljavanje records (pending, rejected, approved) so the
    /// state machine has data to exercise. Also backfills Udomljavanje for the dogs that
    /// EnsurePsiAsync already seeded with StatusPsa "Udomljen" (Max, Lola, Nera), so their
    /// adoption has a proper audit trail instead of a bare status flag.
    /// No dedicated "Korisnik" test account exists yet, so the shelter admin is used as the
    /// requester/processor here purely for demo data.
    /// </summary>
    private static async Task EnsureZahtjeviAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.ZahtjevZaUdomljavanjes.AnyAsync()) return;

        var trazilac = await context.Korisniks.OrderBy(k => k.KorisnikId).FirstOrDefaultAsync();
        if (trazilac == null) return;

        var sNaCekanju = await context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.NaCekanju);
        var sOdobren = await context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.Odobren);
        var sOdbijen = await context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.Odbijen);

        var bella = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Bella");
        var pahulja = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Pahulja");
        var roki = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Roki");
        var max = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Max");
        var lola = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Lola");
        var nera = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Nera");

        var pending = new[] { bella, pahulja };
        foreach (var pas in pending)
        {
            if (pas == null) continue;
            context.ZahtjevZaUdomljavanjes.Add(new ZahtjevZaUdomljavanje
            {
                KorisnikId = trazilac.KorisnikId,
                PasId = pas.PasId,
                StatusZahtjevaId = sNaCekanju.StatusZahtjevaId,
                DatumPodnosenja = DateTime.UtcNow.AddDays(-2),
                Napomena = "Zainteresovan/a sam za udomljavanje ovog psa."
            });
        }

        if (roki != null)
        {
            context.ZahtjevZaUdomljavanjes.Add(new ZahtjevZaUdomljavanje
            {
                KorisnikId = trazilac.KorisnikId,
                PasId = roki.PasId,
                StatusZahtjevaId = sOdbijen.StatusZahtjevaId,
                DatumPodnosenja = DateTime.UtcNow.AddDays(-10),
                DatumObrade = DateTime.UtcNow.AddDays(-9),
                ObradioKorisnikId = trazilac.KorisnikId,
                RazlogOdbijanja = "Nema odgovarajući prostor za psa ove veličine."
            });
        }

        await context.SaveChangesAsync();

        var udomljeni = new (Database.Pas? Pas, DateOnly Datum)[]
        {
            (max, new DateOnly(2024, 11, 20)),
            (lola, new DateOnly(2024, 9, 2)),
            (nera, new DateOnly(2024, 5, 10)),
        };

        var udomljavanja = new List<Udomljavanje>();
        foreach (var (pas, datum) in udomljeni)
        {
            if (pas == null) continue;

            var zahtjev = new ZahtjevZaUdomljavanje
            {
                KorisnikId = trazilac.KorisnikId,
                PasId = pas.PasId,
                StatusZahtjevaId = sOdobren.StatusZahtjevaId,
                DatumPodnosenja = datum.ToDateTime(TimeOnly.MinValue).AddDays(-7),
                DatumObrade = datum.ToDateTime(TimeOnly.MinValue),
                ObradioKorisnikId = trazilac.KorisnikId
            };
            context.ZahtjevZaUdomljavanjes.Add(zahtjev);
            await context.SaveChangesAsync();

            udomljavanja.Add(new Udomljavanje { ZahtjevZaUdomljavanjeId = zahtjev.ZahtjevZaUdomljavanjeId, DatumUdomljavanja = datum });
        }

        context.Udomljavanjes.AddRange(udomljavanja);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded zahtjeve za udomljavanje i {Count} udomljavanja.", udomljavanja.Count);
    }

    /// <summary>
    /// Seeds a handful of Posjeta records spanning all four statuses (Na čekanju, Potvrđena,
    /// Otkazana, Završena) across both the admin and the "korisnik" test account, so the
    /// confirm/cancel/complete state machine and overlap check have data to exercise.
    /// </summary>
    private static async Task EnsurePosjeteAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.Posjeta.AnyAsync()) return;

        var admin = await context.Korisniks.OrderBy(k => k.KorisnikId).FirstOrDefaultAsync();
        var korisnik = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == "korisnik") ?? admin;
        if (admin == null || korisnik == null) return;

        var sNaCekanju = await context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.NaCekanju);
        var sPotvrdjena = await context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.Potvrdjena);
        var sOtkazana = await context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.Otkazana);
        var sZavrsena = await context.StatusPosjetes.FirstAsync(s => s.Naziv == StatusPosjeteNazivi.Zavrsena);

        var luna = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Luna");
        var rex = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Rex");
        var zlatko = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Zlatko");
        var pahulja = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Pahulja");

        var now = DateTime.UtcNow;

        var posjete = new List<Posjeta>
        {
            new()
            {
                KorisnikId = korisnik.KorisnikId,
                PasId = luna?.PasId,
                DatumVrijeme = now.AddDays(3).Date.AddHours(10),
                StatusPosjeteId = sNaCekanju.StatusPosjeteId,
                DatumKreiranja = now.AddDays(-1),
                Napomena = "Željeli bismo upoznati Lunu prije donošenja odluke o udomljavanju."
            },
            new()
            {
                KorisnikId = korisnik.KorisnikId,
                PasId = rex?.PasId,
                DatumVrijeme = now.AddDays(5).Date.AddHours(14),
                StatusPosjeteId = sPotvrdjena.StatusPosjeteId,
                DatumKreiranja = now.AddDays(-3),
                ObradioKorisnikId = admin.KorisnikId,
                DatumObrade = now.AddDays(-2),
                Napomena = "Posjeta radi upoznavanja sa psom Rex."
            },
            new()
            {
                KorisnikId = admin.KorisnikId,
                PasId = zlatko?.PasId,
                DatumVrijeme = now.AddDays(-4).Date.AddHours(11),
                StatusPosjeteId = sOtkazana.StatusPosjeteId,
                DatumKreiranja = now.AddDays(-7),
                ObradioKorisnikId = admin.KorisnikId,
                DatumObrade = now.AddDays(-6),
                RazlogOtkazivanja = "Korisnik je otkazao zbog bolesti."
            },
            new()
            {
                KorisnikId = korisnik.KorisnikId,
                PasId = pahulja?.PasId,
                DatumVrijeme = now.AddDays(-10).Date.AddHours(9),
                StatusPosjeteId = sZavrsena.StatusPosjeteId,
                DatumKreiranja = now.AddDays(-14),
                ObradioKorisnikId = admin.KorisnikId,
                DatumObrade = now.AddDays(-10),
                Napomena = "Posjeta uspješno realizovana."
            },
            new()
            {
                KorisnikId = admin.KorisnikId,
                PasId = null,
                DatumVrijeme = now.AddDays(-1).Date.AddHours(15),
                StatusPosjeteId = sZavrsena.StatusPosjeteId,
                DatumKreiranja = now.AddDays(-1).Date.AddHours(15),
                ObradioKorisnikId = admin.KorisnikId,
                DatumObrade = now.AddDays(-1).Date.AddHours(15),
                Napomena = "Walk-in posjeta azilu bez prethodne rezervacije."
            }
        };

        context.Posjeta.AddRange(posjete);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} posjeta.", posjete.Count);
    }
}
