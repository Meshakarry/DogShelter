using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using DogShelter.Model;
using DogShelter.Services.Constants;
using DogShelter.Services.Services;
using static DogShelter.Model.Spol;

namespace DogShelter.Services.Database;

public static class DatabaseSeeder
{
    public static async Task SeedAllAsync(DogShelterContext context, ILogger logger, string wwwrootPath)
    {
        await EnsureGradoviAsync(context, logger);
        await EnsureVelicinePsaAsync(context, logger);
        await EnsureStatusPsaAsync(context, logger);
        await EnsureStatusZahtjevaAsync(context, logger);
        await EnsureStatusPosjeteAsync(context, logger);
        await EnsureRaseAsync(context, logger);
        await EnsurePsiAsync(context, logger, wwwrootPath);
        await EnsureZahtjeviAsync(context, logger);
        await EnsurePosjeteAsync(context, logger);
        await EnsurePregledPsaAsync(context, logger);
        await EnsureStatusDonacijeAsync(context, logger);
        await EnsureTipDonacijeAsync(context, logger);
        await EnsureKategorijeDonacijeAsync(context, logger);
        await EnsureJediniceMjereAsync(context, logger);
        await EnsureKategorijaDozvoljeneJediniceAsync(context, logger);
        await EnsurePrioritetiPotrebeAsync(context, logger);
        await EnsurePotrebeAzilaAsync(context, logger);
        await EnsureDonacijeAsync(context, logger);
        await EnsureObavijestiAsync(context, logger, wwwrootPath);
        await EnsureTipAktivnostiAsync(context, logger);
        await EnsureVolonteriAsync(context, logger);
        await EnsureDogadjajiAsync(context, logger, wwwrootPath);
        await EnsureAktivnostiVolonteraAsync(context, logger);
        await EnsureDogadjajVolonteriAsync(context, logger);
        await EnsureNotifikacijeAsync(context, logger);
    }

    /// <summary>
    /// Copies a seed image from SeedData/Images/{baseName}.jpg into wwwroot/images/{folder}/,
    /// optionally under a different destination file name (defaults to baseName). Returns the
    /// relative URL stored in DB, or null if source file not found.
    /// </summary>
    private static string? CopySeedImage(string baseName, string wwwrootPath, ILogger logger, string folder = "psi", string? destName = null)
    {
        destName ??= baseName;

        var sourceDirs = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "SeedData", "Images"),
            Path.Combine(Directory.GetCurrentDirectory(), "SeedData", "Images"),
        };

        var destDir = Path.Combine(wwwrootPath, "images", folder);
        Directory.CreateDirectory(destDir);

        var destFile = Path.Combine(destDir, destName + ".jpg");
        if (File.Exists(destFile))
            return $"/images/{folder}/{destName}.jpg";

        foreach (var dir in sourceDirs)
        {
            var source = Path.Combine(dir, baseName + ".jpg");
            if (!File.Exists(source)) continue;
            File.Copy(source, destFile);
            return $"/images/{folder}/{destName}.jpg";
        }

        logger.LogWarning("Seed image not found: {BaseName}.jpg", baseName);
        return null;
    }

    private static async Task EnsureGradoviAsync(DogShelterContext context, ILogger logger)
    {
        var gradovi = new (string Naziv, string PostanskiBroj)[]
        {
            ("Bugojno", "70230"),
            ("Sarajevo", "71000"),
            ("Zenica", "72000"),
            ("Travnik", "72270"),
            ("Donji Vakuf", "70220"),
            ("Gornji Vakuf-Uskoplje", "70240"),
            ("Novi Travnik", "72290"),
            ("Jajce", "70101"),
            ("Mostar", "88000"),
            ("Tuzla", "75000"),
        };
        foreach (var (naziv, postanskiBroj) in gradovi)
        {
            if (!await context.Grads.AnyAsync(g => g.Naziv == naziv))
                context.Grads.Add(new Grad { Naziv = naziv, PostanskiBroj = postanskiBroj });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded Grad.");
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
        var names = new[] { StatusZahtjevaNazivi.NaCekanju, StatusZahtjevaNazivi.Odobren, StatusZahtjevaNazivi.Odbijen, StatusZahtjevaNazivi.Otkazan };
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
            // 5 ── Zlatko (Udomljen, Velika, mužjak, 2 god)
            new() { Naziv = "Zlatko",  RasaId = rGolden.RasaId,     Spol = Muzjak, StatusPsaId = sUdomljen.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 29.5m, DatumPrijema = new DateOnly(2024,  6,  1), DatumRodjenja = new DateOnly(2023,  1, 10), Vakcinisan = true,  Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas5"),  Opis = "Mlad i bezbrižan, Zlatko je štene u tijelu odraslog psa. Žvače sve do čega dođe, ali ne možeš mu se naljutiti. Obožava vodu, bacanje loptice i beskonačno grljenje. Sada uživa u novom domu s aktivnom porodicom koja mu svaki dan pruža šetnje, vodu i beskonačno grljenje." },
            // 6 ── Maci (U tretmanu, Srednja, ženka, 4 god)
            new() { Naziv = "Maci",    RasaId = rBorder.RasaId,     Spol = Zenka,  StatusPsaId = sTretman.StatusPsaId,  VelicinaPsaId = vSrednja.VelicinaPsaId,   Tezina = 15.5m, DatumPrijema = new DateOnly(2024,  4,  8), DatumRodjenja = new DateOnly(2021,  9,  5), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas6"),  Opis = "Maci je bila pronađena na putu s ozljedom prednje šape. Šapa je operisana i sada je na fizioterapiji. Izrazito pametan border koli koji treba mentalnu stimulaciju. Veterinar procjenjuje da će biti potpuno zdrava za tri do četiri sedmice." },
            // 7 ── Vuk (Dostupan, Velika, mužjak, 4 god)
            new() { Naziv = "Vuk",     RasaId = rHusky.RasaId,      Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 26.5m, DatumPrijema = new DateOnly(2023,  9, 15), DatumRodjenja = new DateOnly(2021, 12,  1), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas7"),  Opis = "Vuk se voli činiti ozbiljnim, ali je u stvari potpuna dramska diva. Huče, glasno razgovara i traži pažnju svake sekunde. Odrastao je na otvorenom i treba dvorište – nije za stan. S psima ide sjajno, ali mačkama je nepredvidiv. Nije za početnike." },
            // 8 ── Roki (Dostupan, Velika, mužjak, 5 god)
            new() { Naziv = "Roki",    RasaId = rBokser.RasaId,     Spol = Muzjak, StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vVelika.VelicinaPsaId,    Tezina = 31.0m, DatumPrijema = new DateOnly(2024,  2, 28), DatumRodjenja = new DateOnly(2020,  7,  4), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas8"),  Opis = "Roki je prava stara duša – miran, uglađen i zna svoja pravila. Idealan za mir i tišinu kućnog života. Voli kratke šetnje ujutro i dugačka drijemanja poslijepodne. Nervozni ambijent ga umori, pa nije idealan za domove s malom djecom." },
            // 9 ── Pahulja (Dostupan, Mala, ženka, 2 god)
            new() { Naziv = "Pahulja", RasaId = rPudl.RasaId,       Spol = Zenka,  StatusPsaId = sDostupan.StatusPsaId, VelicinaPsaId = vMala.VelicinaPsaId,      Tezina =  6.0m, DatumPrijema = new DateOnly(2024,  7, 18), DatumRodjenja = new DateOnly(2023,  5, 15), Vakcinisan = true,  Sterilizovan = true,  Aktivan = true, SlikaNaslovna = Img("pas9"),  Opis = "Pahulja brine o svojoj frizuri više nego o mišima u dvorištu. Mala, elegantna i pametna do bola. Jako je vezana za ljude i ne podnosi dugo ostati sama. Podučena je čistim manirima i voli rutinu. Savršena za stan i za vlasnike koji imaju vremena za njenu pažnju." },
            // 10 ── Šaki (Udomljen, Mala, mužjak, nepoznata starost)
            new() { Naziv = "Šaki",    RasaId = rCivava.RasaId,     Spol = Muzjak, StatusPsaId = sUdomljen.StatusPsaId, VelicinaPsaId = vMala.VelicinaPsaId,      Tezina =  2.8m, DatumPrijema = new DateOnly(2024,  8,  3), DatumRodjenja = null,                      Vakcinisan = false, Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas10"), Opis = "Šaki je primljen bez ikakvog dokumenta – nađen je u kartonskoj kutiji kod tržnog centra. Starost se procjenjuje na 2-4 godine. Nije bio vakcinisan ni registrovan. Zna biti glasaša i mrzovoljan prema nepoznatima, ali s poznatim ljudima je topla i privržena maža. Sada mirno živi kod starijeg bračnog para koji mu posvećuje punu pažnju." },
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
            // 19 ── Piki (Udomljen, Srednja, mužjak, 1 god)
            new() { Naziv = "Piki",    RasaId = rBeagle.RasaId,     Spol = Muzjak, StatusPsaId = sUdomljen.StatusPsaId, VelicinaPsaId = vSrednja.VelicinaPsaId,   Tezina = 11.5m, DatumPrijema = new DateOnly(2024,  9, 12), DatumRodjenja = new DateOnly(2023,  9,  1), Vakcinisan = true,  Sterilizovan = false, Aktivan = true, SlikaNaslovna = Img("pas19"), Opis = "Piki je štene u punom smislu te riječi. Nos mu uvijek ide naprijed, a glava se tek kasnije javi. Beagle rasa traži puno kretanja i mentalne stimulacije. Sada trči po dvorištu svoje nove porodice i igra se s njihovo dvoje djece cijeli dan." },
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
    /// Seeds pending/rejected/approved ZahtjevZaUdomljavanje records and backfills Udomljavanje
    /// for dogs already marked Udomljen (Max, Lola, Nera) so they have an adoption audit trail.
    /// </summary>
    private static async Task EnsureZahtjeviAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.ZahtjevZaUdomljavanjes.AnyAsync()) return;

        var admin = await context.Korisniks.OrderBy(k => k.KorisnikId).FirstOrDefaultAsync();
        var trazilac = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == "korisnik") ?? admin;
        if (admin == null || trazilac == null) return;

        var sNaCekanju = await context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.NaCekanju);
        var sOdobren = await context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.Odobren);
        var sOdbijen = await context.StatusZahtjevas.FirstAsync(s => s.Naziv == StatusZahtjevaNazivi.Odbijen);

        var bella = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Bella");
        var pahulja = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Pahulja");
        var roki = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Roki");
        var max = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Max");
        var lola = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Lola");
        var nera = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Nera");
        var zlatko = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Zlatko");
        var piki = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Piki");
        var saki = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Šaki");

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
                ObradioKorisnikId = admin.KorisnikId,
                RazlogOdbijanja = "Nema odgovarajući prostor za psa ove veličine."
            });
        }

        await context.SaveChangesAsync();

        var udomljeni = new (Database.Pas? Pas, DateOnly Datum)[]
        {
            (max, DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-1))),
            (lola, DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-1).AddDays(-12))),
            (nera, DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-2))),
            (zlatko, DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-3))),
            (piki, DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-4))),
            (saki, DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-6))),
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
                ObradioKorisnikId = admin.KorisnikId
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
    /// Seeds Posjeta records covering all four statuses (Na čekanju, Potvrđena, Otkazana,
    /// Završena) for both the admin and the "korisnik" test account.
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

    /// <summary>
    /// Seeds PregledPsa (dog-detail-view log) rows for the "korisnik" and "volonter" test
    /// accounts so the recommender has a real browsing-history signal from first login,
    /// rather than only ever populating this table via live GetById calls. Inserted
    /// directly via context (bypassing PregledPsaService.LogPregled), same as other
    /// no-side-effect seed rows elsewhere in this file.
    /// </summary>
    private static async Task EnsurePregledPsaAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.PregledPsas.AnyAsync()) return;

        var korisnik = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == "korisnik");
        var volonter = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == "volonter");
        if (korisnik == null || volonter == null) return;

        var vuk = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Vuk");
        var zara = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Zara");
        var djuro = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Đuro");
        var bella = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Bella");
        var pahulja = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Pahulja");

        var now = DateTime.UtcNow;

        var pregledi = new List<PregledPsa>();

        // "korisnik" also has Zahtjev/Posjeta/Udomljavanje history (see EnsureZahtjeviAsync/
        // EnsurePosjeteAsync) — these views add the weakest signal layer on top, partly
        // reinforcing large-breed interest (Vuk, Zara) and partly showing variety (Đuro).
        foreach (var (pas, daysAgo) in new[] { (vuk, 6), (vuk, 1), (zara, 4), (djuro, 9) })
        {
            if (pas == null) continue;
            pregledi.Add(new PregledPsa { KorisnikId = korisnik.KorisnikId, PasId = pas.PasId, DatumPregleda = now.AddDays(-daysAgo) });
        }

        // "volonter" has no Zahtjev/Posjeta history at all, so this is their only signal —
        // concentrated on small/medium mixed-breed dogs to show a distinct profile from korisnik.
        foreach (var (pas, daysAgo) in new[] { (bella, 5), (djuro, 3), (pahulja, 2) })
        {
            if (pas == null) continue;
            pregledi.Add(new PregledPsa { KorisnikId = volonter.KorisnikId, PasId = pas.PasId, DatumPregleda = now.AddDays(-daysAgo) });
        }

        context.PregledPsas.AddRange(pregledi);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} pregleda psa.", pregledi.Count);
    }

    private static async Task EnsureStatusDonacijeAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[] { StatusDonacijeNazivi.NaCekanju, StatusDonacijeNazivi.Uspjesna, StatusDonacijeNazivi.Neuspjesna, StatusDonacijeNazivi.Vracena };
        foreach (var naziv in names)
        {
            if (!await context.StatusDonacijes.AnyAsync(s => s.Naziv == naziv))
                context.StatusDonacijes.Add(new StatusDonacije { Naziv = naziv });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded StatusDonacije.");
    }

    private static async Task EnsureTipDonacijeAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[] { TipDonacijeNazivi.Novcana, TipDonacijeNazivi.Materijalna };
        foreach (var naziv in names)
        {
            if (!await context.TipDonacijes.AnyAsync(t => t.Naziv == naziv))
                context.TipDonacijes.Add(new TipDonacije { Naziv = naziv });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded TipDonacije.");
    }

    private static async Task EnsureKategorijeDonacijeAsync(DogShelterContext context, ILogger logger)
    {
        var kategorije = new (string Naziv, string IkonaKljuc)[]
        {
            (KategorijaDonacijeNazivi.HranaZaPse, "hrana_psi"),
            (KategorijaDonacijeNazivi.HranaZaStenad, "hrana_stenad"),
            (KategorijaDonacijeNazivi.DekeIPosteljina, "deke"),
            (KategorijaDonacijeNazivi.Igracke, "igracke"),
            (KategorijaDonacijeNazivi.PovodciIOgrlice, "povodci"),
            (KategorijaDonacijeNazivi.Posude, "posude"),
            (KategorijaDonacijeNazivi.Lijekovi, "lijekovi"),
            (KategorijaDonacijeNazivi.SredstvaZaCiscenje, "cistoca"),
            (KategorijaDonacijeNazivi.Ostalo, "ostalo"),
        };

        foreach (var (naziv, ikona) in kategorije)
        {
            if (!await context.KategorijaDonacijes.AnyAsync(k => k.Naziv == naziv))
                context.KategorijaDonacijes.Add(new KategorijaDonacije { Naziv = naziv, IkonaKljuc = ikona });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded KategorijaDonacije.");
    }

    private static async Task EnsureJediniceMjereAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[] { "kom", "vreće", "kg", "kutije", "boce" };
        foreach (var naziv in names)
        {
            if (!await context.JedinicaMjeres.AnyAsync(j => j.Naziv == naziv))
                context.JedinicaMjeres.Add(new JedinicaMjere { Naziv = naziv });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded JedinicaMjere.");
    }

    /// <summary>
    /// Restricts each Materijalna category to units that make sense (e.g. Deke i posteljina ->
    /// kom only). "Ostalo" intentionally keeps an empty allowed-list — the client treats that as
    /// unrestricted. Idempotent: re-running reassigns the same sets, which EF no-ops when
    /// unchanged.
    /// </summary>
    private static async Task EnsureKategorijaDozvoljeneJediniceAsync(DogShelterContext context, ILogger logger)
    {
        var kategorije = await context.KategorijaDonacijes.Include(k => k.DozvoljeneJedinice).ToListAsync();
        var jedinice = await context.JedinicaMjeres.ToListAsync();

        JedinicaMjere J(string naziv) => jedinice.First(j => j.Naziv == naziv);

        var mapping = new Dictionary<string, (string[] Dozvoljene, string? Podrazumijevana)>
        {
            [KategorijaDonacijeNazivi.HranaZaPse] = (["vreće", "kg"], "vreće"),
            [KategorijaDonacijeNazivi.HranaZaStenad] = (["vreće", "kg"], "vreće"),
            [KategorijaDonacijeNazivi.DekeIPosteljina] = (["kom"], "kom"),
            [KategorijaDonacijeNazivi.Igracke] = (["kom"], "kom"),
            [KategorijaDonacijeNazivi.PovodciIOgrlice] = (["kom"], "kom"),
            [KategorijaDonacijeNazivi.Posude] = (["kom"], "kom"),
            [KategorijaDonacijeNazivi.Lijekovi] = (["kutije", "kom"], "kutije"),
            [KategorijaDonacijeNazivi.SredstvaZaCiscenje] = (["boce"], "boce"),
            [KategorijaDonacijeNazivi.Ostalo] = ([], null),
        };

        foreach (var kategorija in kategorije)
        {
            if (!mapping.TryGetValue(kategorija.Naziv, out var rule)) continue;

            kategorija.DozvoljeneJedinice = rule.Dozvoljene.Select(J).ToList();
            kategorija.PodrazumijevanaJedinicaMjereId = rule.Podrazumijevana != null ? J(rule.Podrazumijevana).JedinicaMjereId : null;
        }

        await context.SaveChangesAsync();
        logger.LogInformation("Assigned allowed units per KategorijaDonacije.");
    }

    private static async Task EnsurePrioritetiPotrebeAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[] { PrioritetPotrebeNazivi.Hitno, PrioritetPotrebeNazivi.PotrebnoUskoro, PrioritetPotrebeNazivi.NaStanju };
        foreach (var naziv in names)
        {
            if (!await context.PrioritetPotrebes.AnyAsync(p => p.Naziv == naziv))
                context.PrioritetPotrebes.Add(new PrioritetPotrebe { Naziv = naziv });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded PrioritetPotrebe.");
    }

    /// <summary>
    /// Seeds the admin-curated "what the shelter currently needs" board shown read-only to donors
    /// on the mobile Materijalna donation screen - never editable by donors themselves.
    /// </summary>
    private static async Task EnsurePotrebeAzilaAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.PotrebeAzila.AnyAsync()) return;

        var hitno = await context.PrioritetPotrebes.FirstAsync(p => p.Naziv == PrioritetPotrebeNazivi.Hitno);
        var uskoro = await context.PrioritetPotrebes.FirstAsync(p => p.Naziv == PrioritetPotrebeNazivi.PotrebnoUskoro);
        var naStanju = await context.PrioritetPotrebes.FirstAsync(p => p.Naziv == PrioritetPotrebeNazivi.NaStanju);

        var potrebe = new List<PotrebaAzila>
        {
            new()
            {
                Naziv = "Hrana za pse",
                Opis = "Trenutno nam je potrebna suha hrana za odrasle pse.",
                PrioritetPotrebeId = hitno.PrioritetPotrebeId,
                IkonaKljuc = "hrana_psi",
                Aktivna = true
            },
            new()
            {
                Naziv = "Sredstva za čišćenje",
                Opis = "Deterdženti i dezinfekciona sredstva za svakodnevno održavanje azila.",
                PrioritetPotrebeId = hitno.PrioritetPotrebeId,
                IkonaKljuc = "cistoca",
                Aktivna = true
            },
            new()
            {
                Naziv = "Deke",
                Opis = "Tople deke za štenad i pse tokom hladnijih noći.",
                PrioritetPotrebeId = uskoro.PrioritetPotrebeId,
                IkonaKljuc = "deke",
                Aktivna = true
            },
            new()
            {
                Naziv = "Lijekovi",
                Opis = "Osnovni lijekovi i previjački materijal za veterinarsku njegu.",
                PrioritetPotrebeId = uskoro.PrioritetPotrebeId,
                IkonaKljuc = "lijekovi",
                Aktivna = true
            },
            new()
            {
                Naziv = "Posude za hranu i vodu",
                Opis = "Trenutne zalihe posuda su dovoljne, ali su uvijek dobrodošle.",
                PrioritetPotrebeId = naStanju.PrioritetPotrebeId,
                IkonaKljuc = "posude",
                Aktivna = true
            }
        };

        context.PotrebeAzila.AddRange(potrebe);
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded {Count} potrebe azila.", potrebe.Count);
    }

    /// <summary>
    /// Seeds Donacija records covering the in-kind (Materijalna) state machine end-to-end
    /// (Na čekanju/Uspješna/Neuspješna via admin potvrdi/odbij) plus pending monetary (Novčana)
    /// donations with no StripePaymentIntentId — a real "Uspješna" monetary record can only be
    /// produced by an actual Stripe test-mode payment, never fabricated in seed data.
    /// </summary>
    private static async Task EnsureDonacijeAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.Donacijas.AnyAsync()) return;

        var admin = await context.Korisniks.OrderBy(k => k.KorisnikId).FirstOrDefaultAsync();
        var korisnik = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == "korisnik") ?? admin;
        var volonter = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == "volonter") ?? admin;
        if (admin == null || korisnik == null || volonter == null) return;

        var tipNovcana = await context.TipDonacijes.FirstAsync(t => t.Naziv == TipDonacijeNazivi.Novcana);
        var tipMaterijalna = await context.TipDonacijes.FirstAsync(t => t.Naziv == TipDonacijeNazivi.Materijalna);

        var sNaCekanju = await context.StatusDonacijes.FirstAsync(s => s.Naziv == StatusDonacijeNazivi.NaCekanju);
        var sUspjesna = await context.StatusDonacijes.FirstAsync(s => s.Naziv == StatusDonacijeNazivi.Uspjesna);
        var sNeuspjesna = await context.StatusDonacijes.FirstAsync(s => s.Naziv == StatusDonacijeNazivi.Neuspjesna);

        var now = DateTime.UtcNow;

        var donacije = new List<Donacija>
        {
            new()
            {
                KorisnikId = korisnik.KorisnikId,
                TipDonacijeId = tipMaterijalna.TipDonacijeId,
                StatusDonacijeId = sNaCekanju.StatusDonacijeId,
                DatumDonacije = now.AddDays(-1),
                Napomena = "20kg hrane za pse i dvije deke, dostava dogovorena za vikend."
            },
            new()
            {
                KorisnikId = korisnik.KorisnikId,
                TipDonacijeId = tipMaterijalna.TipDonacijeId,
                StatusDonacijeId = sUspjesna.StatusDonacijeId,
                DatumDonacije = now.AddDays(-10),
                Napomena = "Deset vreća hrane i ogrlice.",
                ObradioKorisnikId = admin.KorisnikId,
                DatumObrade = now.AddDays(-9)
            },
            new()
            {
                KorisnikId = volonter.KorisnikId,
                TipDonacijeId = tipMaterijalna.TipDonacijeId,
                StatusDonacijeId = sNeuspjesna.StatusDonacijeId,
                DatumDonacije = now.AddDays(-6),
                Napomena = "Ponuđena stara kavezna oprema.",
                ObradioKorisnikId = admin.KorisnikId,
                DatumObrade = now.AddDays(-5),
                RazlogOdbijanja = "Oprema ne zadovoljava sigurnosne standarde azila."
            },
            new()
            {
                KorisnikId = korisnik.KorisnikId,
                TipDonacijeId = tipNovcana.TipDonacijeId,
                StatusDonacijeId = sNaCekanju.StatusDonacijeId,
                Iznos = 25.00m,
                DatumDonacije = now.AddHours(-2)
            },
            new()
            {
                KorisnikId = volonter.KorisnikId,
                TipDonacijeId = tipNovcana.TipDonacijeId,
                StatusDonacijeId = sNaCekanju.StatusDonacijeId,
                Iznos = 50.00m,
                DatumDonacije = now.AddHours(-1)
            }
        };

        context.Donacijas.AddRange(donacije);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} donacije.", donacije.Count);
    }

    /// <summary>
    /// Seeds a handful of Obavijest (announcement) records, covering both published
    /// (Aktivna = true) and draft (Aktivna = false) status, with and without a cover image.
    /// </summary>
    private static async Task EnsureObavijestiAsync(DogShelterContext context, ILogger logger, string wwwrootPath)
    {
        if (await context.Obavijests.AnyAsync()) return;

        var admin = await context.Korisniks.OrderBy(k => k.KorisnikId).FirstOrDefaultAsync();
        if (admin == null) return;

        var bella = await context.Pas.FirstOrDefaultAsync(p => p.Naziv == "Bella");
        var now = DateTime.UtcNow;

        // Dedicated seed photos (not dog reuse) - obavijest1/2/3 map to the 3 published
        // articles by recency, newest first; obavijest3.jpg (volunteers examining a dog) is a
        // clear content match for the volunteer call-out regardless of pure date order.
        string Img(string name) => CopySeedImage(name, wwwrootPath, logger, folder: "obavijesti") ?? string.Empty;

        var obavijesti = new List<Obavijest>
        {
            new()
            {
                AutorId = admin.KorisnikId,
                Naslov = "Azil dobio novu opremu zahvaljujući donatorima",
                Sadrzaj = "Ovih sedmica primili smo veliku donaciju hrane, deka i kaveza od naših dragih donatora. Hvala svima koji su prepoznali da se svaka pomoć broji – zahvaljujući vama naši štićenici imaju toplije zime i punije stomake.",
                SlikaPutanja = Img("obavijest2"),
                DatumObjave = now.AddDays(-14),
                Aktivna = true
            },
            new()
            {
                AutorId = admin.KorisnikId,
                Naslov = "Lola pronašla svoj dom!",
                Sadrzaj = "Sa velikim zadovoljstvom javljamo da je Lola, naša labradorica koja je čekala godinu dana, konačno udomljena. Nova porodica joj je pripremila prostrano dvorište i toplu dobrodošlicu. Hvala svima koji su navijali za nju!",
                SlikaPutanja = Img("obavijest1"),
                DatumObjave = now.AddDays(-8),
                Aktivna = true
            },
            new()
            {
                AutorId = admin.KorisnikId,
                Naslov = "Otvoren poziv za volontere ovog vikenda",
                Sadrzaj = "Tražimo volontere za šetnju pasa i pomoć oko čišćenja azila subotom i nedjeljom od 9 do 13 sati. Prijave su moguće putem aplikacije u sekciji Volontiranje. Svaka pomoć je dobrodošla!",
                SlikaPutanja = Img("obavijest3"),
                DatumObjave = now.AddDays(-3),
                Aktivna = true
            },
            new()
            {
                AutorId = admin.KorisnikId,
                Naslov = "Nacrt: najava zimske akcije prikupljanja donacija",
                Sadrzaj = "Radna verzija teksta za predstojeću zimsku akciju prikupljanja hrane i deka – još uvijek čeka odobrenje uprave prije objave.",
                SlikaPutanja = bella?.SlikaNaslovna ?? throw new InvalidOperationException("Seed pas 'Bella' nije pronađen za Obavijest sliku."),
                DatumObjave = now,
                Aktivna = false
            }
        };

        context.Obavijests.AddRange(obavijesti);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} obavijesti.", obavijesti.Count);
    }

    private static async Task EnsureTipAktivnostiAsync(DogShelterContext context, ILogger logger)
    {
        var names = new[] { "Šetanje pasa", "Njega i hranjenje pasa", "Čišćenje prostora", "Pomoć na događajima", "Administrativni poslovi" };
        foreach (var naziv in names)
        {
            if (!await context.TipAktivnostis.AnyAsync(t => t.Naziv == naziv))
                context.TipAktivnostis.Add(new TipAktivnosti { Naziv = naziv });
        }
        await context.SaveChangesAsync();
        logger.LogInformation("Seeded TipAktivnosti.");
    }

    /// <summary>
    /// Seeds the "volonter" test account (created in Program.cs) plus three fake Korisnik
    /// accounts as Volonter roster data. Role is granted the same way VolonterService.Insert
    /// does it. One volunteer is seeded inactive to cover status handling.
    /// </summary>
    private static async Task EnsureVolonteriAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.Volonters.AnyAsync()) return;

        var volonterRole = await context.Ulogas.FirstOrDefaultAsync(r => r.Naziv == RoleNames.Volonter);
        if (volonterRole == null) return;

        var fakeVolonteri = new[]
        {
            new { Ime = "Amina", Prezime = "Hodžić", Email = "amina.hodzic@dogshelter.ba", KorisnickoIme = "amina.hodzic" },
            new { Ime = "Ahmed", Prezime = "Bešić", Email = "ahmed.besic@dogshelter.ba", KorisnickoIme = "ahmed.besic" },
            new { Ime = "Lejla", Prezime = "Kovač", Email = "lejla.kovac@dogshelter.ba", KorisnickoIme = "lejla.kovac" },
        };

        var korisnici = new List<Korisnik>();
        foreach (var v in fakeVolonteri)
        {
            var korisnik = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == v.KorisnickoIme);
            if (korisnik == null)
            {
                korisnik = new Korisnik
                {
                    Ime = v.Ime,
                    Prezime = v.Prezime,
                    Email = v.Email,
                    KorisnickoIme = v.KorisnickoIme,
                    LozinkaHash = KorisnikService.HashPassword("test"),
                    LozinkaSalt = string.Empty,
                    Aktivan = true
                };
                context.Korisniks.Add(korisnik);
                await context.SaveChangesAsync();
            }
            korisnici.Add(korisnik);
        }

        foreach (var korisnik in korisnici)
        {
            var hasRole = await context.KorisnikUlogas.AnyAsync(ur => ur.KorisnikId == korisnik.KorisnikId && ur.UlogaId == volonterRole.UlogaId);
            if (!hasRole)
                context.KorisnikUlogas.Add(new KorisnikUloga { KorisnikId = korisnik.KorisnikId, UlogaId = volonterRole.UlogaId });
        }
        await context.SaveChangesAsync();

        var testVolonter = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == "volonter");

        var danas = DateOnly.FromDateTime(DateTime.UtcNow);
        var volonteri = new List<Volonter>();

        if (testVolonter != null)
            volonteri.Add(new Volonter { KorisnikId = testVolonter.KorisnikId, DatumPridruzivanja = danas.AddMonths(-8), Aktivan = true });

        volonteri.Add(new Volonter { KorisnikId = korisnici[0].KorisnikId, DatumPridruzivanja = danas.AddMonths(-5), Aktivan = true });
        volonteri.Add(new Volonter { KorisnikId = korisnici[1].KorisnikId, DatumPridruzivanja = danas.AddMonths(-3), Aktivan = true });
        volonteri.Add(new Volonter { KorisnikId = korisnici[2].KorisnikId, DatumPridruzivanja = danas.AddYears(-1), Aktivan = false });

        context.Volonters.AddRange(volonteri);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} volontera.", volonteri.Count);
    }

    /// <summary>
    /// Seeds Dogadjaj records spanning open days, humanitarian actions, and adoption
    /// promotions, plus one cancelled (Aktivan = false) past event so the non-admin
    /// "upcoming only" visibility filter has something to hide.
    /// </summary>
    private static async Task EnsureDogadjajiAsync(DogShelterContext context, ILogger logger, string wwwrootPath)
    {
        if (await context.Dogadjajs.AnyAsync()) return;

        // Dedicated seed photos, matched to each event by actual content: dogadjaj3 (a dog in
        // an "adopt me" bandana) -> the adoption promo; dogadjaj4 (large group + hosing down
        // the yard) -> the cleaning weekend; dogadjaj1 (kennel/cleaning-supplies scene, general
        // humanitarian-care feel) -> both "humanitarna akcija"-titled events (reused across the
        // two, same deliberate-reuse precedent as Obavijest's seed); dogadjaj2 (puppies) -> the
        // open house as a generic welcoming photo.
        string Img(string name) => CopySeedImage(name, wwwrootPath, logger, folder: "dogadjaji") ?? string.Empty;

        var now = DateTime.UtcNow;
        var dogadjaji = new List<Dogadjaj>
        {
            new() { Naziv = "Dan otvorenih vrata", Opis = "Posjetite azil, upoznajte pse i osoblje, i saznajte kako možete pomoći.", Datum = now.AddDays(10).Date.AddHours(10), Lokacija = "Azil za pse Bugojno", Aktivan = true, SlikaPutanja = Img("dogadjaj2") },
            new() { Naziv = "Humanitarna akcija - Sakupljanje hrane", Opis = "Akcija sakupljanja hrane i opreme za pse u centru grada.", Datum = now.AddDays(20).Date.AddHours(9), Lokacija = "Gradski trg, Bugojno", Aktivan = true, SlikaPutanja = Img("dogadjaj1") },
            new() { Naziv = "Promotivni dan udomljavanja", Opis = "Dovodimo nekoliko pasa na promociju udomljavanja u park.", Datum = now.AddDays(30).Date.AddHours(11), Lokacija = "Gradski park, Bugojno", Aktivan = true, SlikaPutanja = Img("dogadjaj3") },
            new() { Naziv = "Volonterski vikend čišćenja", Opis = "Zajedničko čišćenje i uređenje prostora azila.", Datum = now.AddDays(45).Date.AddHours(9), Lokacija = "Azil za pse Bugojno", Aktivan = true, SlikaPutanja = Img("dogadjaj4") },
            new() { Naziv = "Zimska humanitarna akcija (otkazano)", Opis = "Akcija je otkazana zbog vremenskih uslova.", Datum = now.AddDays(-15).Date.AddHours(10), Lokacija = "Azil za pse Bugojno", Aktivan = false, SlikaPutanja = Img("dogadjaj1") },
        };

        context.Dogadjajs.AddRange(dogadjaji);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} dogadjaja.", dogadjaji.Count);
    }

    /// <summary>
    /// Seeds AktivnostVolontera records across the seeded volunteers so the hours-tracking
    /// aggregation (Volonter.UkupnoSati) has real data to sum, not just an empty roster.
    /// </summary>
    private static async Task EnsureAktivnostiVolonteraAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.AktivnostVolonteras.AnyAsync()) return;

        var volonteri = await context.Volonters.OrderBy(v => v.VolonterId).ToListAsync();
        if (volonteri.Count == 0) return;

        var tSetanje = await context.TipAktivnostis.FirstOrDefaultAsync(t => t.Naziv == "Šetanje pasa");
        var tNjega = await context.TipAktivnostis.FirstOrDefaultAsync(t => t.Naziv == "Njega i hranjenje pasa");
        var tCiscenje = await context.TipAktivnostis.FirstOrDefaultAsync(t => t.Naziv == "Čišćenje prostora");
        var tDogadjaji = await context.TipAktivnostis.FirstOrDefaultAsync(t => t.Naziv == "Pomoć na događajima");
        if (tSetanje == null || tNjega == null || tCiscenje == null || tDogadjaji == null) return;

        var danas = DateOnly.FromDateTime(DateTime.UtcNow);
        var aktivnosti = new List<AktivnostVolontera>();

        var v0 = volonteri[0];
        aktivnosti.Add(new AktivnostVolontera { VolonterId = v0.VolonterId, TipAktivnostiId = tSetanje.TipAktivnostiId, DatumAktivnosti = danas.AddDays(-14), BrojSati = 2.5m, Opis = "Šetanje pasa u dvorištu azila." });
        aktivnosti.Add(new AktivnostVolontera { VolonterId = v0.VolonterId, TipAktivnostiId = tNjega.TipAktivnostiId, DatumAktivnosti = danas.AddDays(-7), BrojSati = 3m, Opis = "Hranjenje i njega pasa u jutarnjoj smjeni." });

        if (volonteri.Count > 1)
        {
            var v1 = volonteri[1];
            aktivnosti.Add(new AktivnostVolontera { VolonterId = v1.VolonterId, TipAktivnostiId = tCiscenje.TipAktivnostiId, DatumAktivnosti = danas.AddDays(-10), BrojSati = 4m, Opis = "Čišćenje bokseva i dvorišta." });
            aktivnosti.Add(new AktivnostVolontera { VolonterId = v1.VolonterId, TipAktivnostiId = tSetanje.TipAktivnostiId, DatumAktivnosti = danas.AddDays(-3), BrojSati = 2m });
        }

        if (volonteri.Count > 2)
        {
            var v2 = volonteri[2];
            aktivnosti.Add(new AktivnostVolontera { VolonterId = v2.VolonterId, TipAktivnostiId = tDogadjaji.TipAktivnostiId, DatumAktivnosti = danas.AddDays(-20), BrojSati = 5m, Opis = "Pomoć na promotivnom danu udomljavanja." });
        }

        context.AktivnostVolonteras.AddRange(aktivnosti);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} aktivnosti volontera.", aktivnosti.Count);
    }

    /// <summary>
    /// Seeds DogadjajVolonter (zaduženje) rows linking active volunteers to upcoming active
    /// events, so the admin roster view and the volunteer's "my assignments" view both have
    /// real data. Written directly via DbContext like every other seeder, so no email is
    /// sent during seeding (only DogadjajVolonterService.Zaduzi sends one, in normal use).
    /// </summary>
    private static async Task EnsureDogadjajVolonteriAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.DogadjajVolonters.AnyAsync()) return;

        var aktivniVolonteri = await context.Volonters.Where(v => v.Aktivan).OrderBy(v => v.VolonterId).ToListAsync();
        if (aktivniVolonteri.Count == 0) return;

        var dogadjaji = await context.Dogadjajs.Where(d => d.Aktivan).OrderBy(d => d.Datum).ToListAsync();
        if (dogadjaji.Count == 0) return;

        var zaduzenja = new List<DogadjajVolonter>();
        var otvorenaVrata = dogadjaji.ElementAtOrDefault(0);
        var humanitarna = dogadjaji.ElementAtOrDefault(1);

        if (otvorenaVrata != null)
        {
            zaduzenja.Add(new DogadjajVolonter { DogadjajId = otvorenaVrata.DogadjajId, VolonterId = aktivniVolonteri[0].VolonterId });
            if (aktivniVolonteri.Count > 1)
                zaduzenja.Add(new DogadjajVolonter { DogadjajId = otvorenaVrata.DogadjajId, VolonterId = aktivniVolonteri[1].VolonterId });
        }

        if (humanitarna != null && aktivniVolonteri.Count > 2)
            zaduzenja.Add(new DogadjajVolonter { DogadjajId = humanitarna.DogadjajId, VolonterId = aktivniVolonteri[2].VolonterId });

        context.DogadjajVolonters.AddRange(zaduzenja);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} zaduzenja volontera za dogadjaje.", zaduzenja.Count);
    }

    /// <summary>
    /// Seeds a mix of read/unread Notifikacija rows across several trigger types for the
    /// test accounts.
    /// </summary>
    private static async Task EnsureNotifikacijeAsync(DogShelterContext context, ILogger logger)
    {
        if (await context.Notifikacijas.AnyAsync()) return;

        var korisnik = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == "korisnik");
        var volonter = await context.Korisniks.FirstOrDefaultAsync(k => k.KorisnickoIme == "volonter");
        if (korisnik == null || volonter == null) return;

        var now = DateTime.UtcNow;
        var notifikacije = new List<Notifikacija>
        {
            new() { KorisnikId = korisnik.KorisnikId, Tip = NotifikacijaTipovi.PosjetaPotvrdjena, Naslov = "Posjeta potvrđena", Tekst = "Vaša posjeta zakazana za 22.07.2026 10:00 je potvrđena.", Procitano = false, DatumKreiranja = now.AddHours(-2) },
            new() { KorisnikId = korisnik.KorisnikId, Tip = NotifikacijaTipovi.DonacijaUspjesna, Naslov = "Donacija uspješna", Tekst = "Vaše plaćanje je uspješno obrađeno. Hvala Vam na donaciji!", Procitano = false, DatumKreiranja = now.AddDays(-1) },
            new() { KorisnikId = korisnik.KorisnikId, Tip = NotifikacijaTipovi.ZahtjevOdobren, Naslov = "Zahtjev za udomljavanje odobren", Tekst = "Vaš zahtjev za udomljavanje psa \"Max\" je odobren.", Procitano = true, DatumKreiranja = now.AddDays(-5) },
            new() { KorisnikId = korisnik.KorisnikId, Tip = NotifikacijaTipovi.PosjetaOtkazana, Naslov = "Posjeta otkazana", Tekst = "Vaša posjeta zakazana za 10.07.2026 14:00 je otkazana. Razlog: Bolest psa.", Procitano = true, DatumKreiranja = now.AddDays(-8) },
            new() { KorisnikId = volonter.KorisnikId, Tip = NotifikacijaTipovi.DogadjajZaduzenje, Naslov = "Zaduženje za događaj", Tekst = "Zaduženi ste za događaj \"Dan otvorenih vrata\".", Procitano = false, DatumKreiranja = now.AddHours(-6) },
            new() { KorisnikId = volonter.KorisnikId, Tip = NotifikacijaTipovi.DogadjajZaduzenje, Naslov = "Zaduženje za događaj", Tekst = "Zaduženi ste za događaj \"Humanitarna akcija - Sakupljanje hrane\".", Procitano = true, DatumKreiranja = now.AddDays(-3) },
        };

        context.Notifikacijas.AddRange(notifikacije);
        await context.SaveChangesAsync();

        logger.LogInformation("Seeded {Count} notifikacija.", notifikacije.Count);
    }
}
