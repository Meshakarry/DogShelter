# Preporuka pasa (recommender sistem) — dokumentacija

## 1. Pregled

DogShelter uključuje sistem preporuke pasa korisnicima aplikacije: `GET /api/Preporuka/psi` vraća listu psi koje je sistem procijenio kao relevantne za trenutno prijavljenog korisnika, zajedno s numeričkim skorom i **tekstualnim objašnjenjem zašto je baš taj pas preporučen**.

Pristup je **content-based** (preporuke se zasnivaju na osobinama pasa — rasa, veličina, starost, spol, nivo aktivnosti — koje korisnik pokazuje da preferira kroz vlastito ponašanje u aplikaciji: preglede, favorite, posjete, zahtjeve za udomljavanje, udomljenja i korištene filtere pri pretrazi), uz **popularnost** kao dodatni signal i **fallback za nove korisnike** bez historije (cold-start). Sistem je potpuno deterministički — nema crne kutije, nasumičnosti niti mašinskog učenja; svaki doprinos skoru se može pratiti do konkretnog signala i taj signal se uvijek pojavljuje u objašnjenju (`razlog`) koje korisnik vidi.

Sistem je namjerno **jednostavniji od collaborative filteringa** (ne postoji "korisnici slični vama" logika) jer aplikacija nema dovoljno korisnika/interakcija za takav pristup da bude smislen na ovoj razini podataka — content-based pristup na osnovu stvarnih osobina pasa je i transparentniji i lakše objasniv krajnjem korisniku, što je eksplicitan zahtjev.

Skup signala i osobina je usklađen sa originalnom prijavom teme: pregledi pasa, favoriti, zahtjevi za udomljavanje, korišteni filteri, te afiniteti prema rasi, starosti, veličini, spolu i nivou aktivnosti.

## 2. Signali koji se koriste

Svi signali dolaze iz podataka koje aplikacija **stvarno bilježi tokom normalne upotrebe** — ništa nije izmišljeno posebno za ovaj modul:

| Signal | Izvor (tabela) | Šta znači | Težina |
|---|---|---|---|
| Pregled detalja psa | `PregledPsa` (automatski se bilježi pri svakom `GET /api/Pas/{id}`) | Korisnik je pogledao profil psa — najslabiji signal, samo pregledavanje | **1.0** |
| Zakazana posjeta | `Posjeta` | Korisnik je rezervisao posjetu tom psu — jača namjera od pregleda | **2.0** |
| Favorit | `Favorit` (dodaje se preko srce-dugmeta na detalju psa) | Korisnik je eksplicitno sačuvao psa kao favorita — svjesna odluka, jača od pukog pregleda ili posjete | **2.5** |
| Zahtjev za udomljavanje | `ZahtjevZaUdomljavanje` (bilo koji status) | Korisnik je formalno zatražio udomljavanje — jaka namjera, bez obzira na ishod | **3.0** |
| Realizovano udomljavanje | `Udomljavanje` | Korisnik je stvarno udomio psa te rase/veličine — najjači mogući dokaz preferencije, dodaje se **povrh** težine iz odgovarajućeg zahtjeva | **3.0** |
| Korištena pretraga (filter) | `PretragaLog` (bilježi se pri `GET /api/Pas` čim je postavljen bar jedan filter: rasa, veličina, spol ili nivo aktivnosti) | Korisnik je tražio pse s određenom osobinom — ne pokazuje na jednog konkretnog psa, pa je slabiji signal od stvarne interakcije s psom | **0.75** |

Prvih pet signala (pregled, posjeta, favorit, zahtjev, udomljenje) su vezani za **jednog konkretnog psa**, pa doprinose sve četiri osobine tog psa odjednom: rasu, veličinu, spol i nivo aktivnosti. `PretragaLog` ne pokazuje na jednog psa — svaki red nosi samo one filtere koje je korisnik te pretrage stvarno postavio (npr. samo veličinu, bez rase), pa doprinosi samo onim osobinama koje su u tom redu popunjene.

Za svakog korisnika, sistem prolazi kroz svih šest izvora i za svaki zabilježeni signal akumulira težinu na **rasu** (`RasaId`), **veličinu** (`VelicinaPsaId`), **spol** (`Spol`) i **nivo aktivnosti** (`NivoAktivnostiId`) psa na kojeg se signal odnosi. Ako korisnik ima više signala za istu vrijednost (npr. pogledao je i kasnije zatražio udomljavanje istog psa, ili više puta pretražio iste veličine), težine se **zbrajaju** — to je namjerno, jer ponovljeni signal znači jaču preferenciju.

`PretragaLog` se ne bilježi za administratore niti za pretrage bez ijednog filtera (nefiltrirano pregledavanje ne govori ništa o preferenciji) — samo za obične korisnike koji su stvarno suzili pretragu po nekoj osobini.

Dodatno se prati i **prosječna starost** (u mjesecima) pasa iz pet signala vezanih za konkretnog psa (`PretragaLog` nema dodijeljenog psa pa ne nosi datum rođenja), kao osnova za bonus na sličnu starost kod kandidata.

## 3. Algoritam

### Korak 1 — profil korisnika

Za `KorisnikId` iz JWT tokena, sistem gradi:
- `rasaTezine`: rječnik `RasaId → zbir težina`
- `velicinaTezine`: rječnik `VelicinaPsaId → zbir težina`
- `spolTezine`: rječnik `Spol → zbir težina`
- `nivoAktivnostiTezine`: rječnik `NivoAktivnostiId → zbir težina`
- `preferiranaStarost`: prosjek starosti (mjeseci) svih pasa iz signala vezanih za konkretnog psa, ako barem jedan ima poznat datum rođenja

### Korak 2 — kandidati

Kandidati su svi psi koji su:
- `Aktivan = true` (nisu obrisani/arhivirani),
- imaju status `StatusPsa.Naziv = "Dostupan"` (nisu već udomljeni ili rezervisani),
- **nisu** predmet trenutno aktivnog (`Na čekanju`) zahtjeva za udomljavanje istog korisnika — ne preporučuje se pas kojeg je korisnik već formalno zatražio.

(Psi koje je korisnik već udomio, rezervisao ili čiji je zahtjev odobren automatski otpadaju jer im status više nije "Dostupan" — nema potrebe za posebnim filterom.)

### Korak 3 — bodovanje

Ako korisnik ima **barem jedan** signal (bilo koja težina u `rasaTezine`, `velicinaTezine`, `spolTezine` ili `nivoAktivnostiTezine`), za svakog kandidata:

```
skor = 0

ako rasaTezine sadrži rasu kandidata:
    skor += rasaTezine[RasaId] × 5.0        (RasaMatchMultiplier)

ako velicinaTezine sadrži veličinu kandidata:
    skor += velicinaTezine[VelicinaPsaId] × 3.0   (VelicinaMatchMultiplier)

ako spolTezine sadrži spol kandidata:
    skor += spolTezine[Spol] × 2.0          (SpolMatchMultiplier)

ako nivoAktivnostiTezine sadrži nivo aktivnosti kandidata:
    skor += nivoAktivnostiTezine[NivoAktivnostiId] × 2.0   (NivoAktivnostiMatchMultiplier)

ako postoji preferiranaStarost i kandidat ima poznat datum rođenja:
    odstupanje = |starost(kandidat) − preferiranaStarost|  (u mjesecima)
    ako odstupanje <= 24 mjeseca:
        skor += 3.0 × (1 − odstupanje / 24)   (AgeSimilarityBonus, linearno opada)

skor += brojPregleda(kandidat) × 0.2      (ViewPopularityMultiplier)
skor += brojZahtjeva(kandidat) × 0.5      (ZahtjevPopularityMultiplier)
```

`brojPregleda`/`brojZahtjeva` su **ukupni** brojevi za tog psa u cijelom sistemu (svi korisnici), ne samo trenutnog korisnika — predstavljaju opću popularnost. Oba se računaju jednim `GROUP BY` upitom po psu (ne pojedinačnim upitom po kandidatu), radi performansi.

Rezultati se sortiraju opadajuće po skoru, uz `PasId` kao deterministički tie-breaker, i vraća se prvih `take` (podrazumijevano 5).

### Korak 4 — cold-start (korisnici bez historije)

Ako korisnik **nema nijedan signal** (novi korisnik koji nikad nije pregledao, favorizovao, posjetio, tražio, udomio psa niti pretraživao s filterom), preskaču se članovi bodovanja vezani za rasu/veličinu/spol/nivo aktivnosti/starost i koristi se **samo popularnost**:

```
skor = brojPregleda(kandidat) × 0.2 + brojZahtjeva(kandidat) × 0.5
```

Ovo garantuje da preporuke nikad nisu prazna lista (osim ako u sistemu doslovno nema nijednog dostupnog psa) — čak i potpuno nov korisnik odmah dobija smislenu, popularnošću vođenu listu.

## 4. Objašnjenje preporuke (`razlog`)

Svaki element odgovora nosi polje `razlog` — čitljivu rečenicu koja **nabraja svaki signal koji je stvarno doprinio skoru** tog konkretnog kandidata, ne samo najjači. Ako podudaranje rase, veličine, spola, nivoa aktivnosti, slična starost i popularnost svi doprinesu skoru, sve klauzule se pojavljuju u `razlog`, spojene sa "; ".

Primjer odgovora nakon što je korisnik favorizovao psa ženskog spola, male veličine i niskog nivoa aktivnosti (rasa Pudl), pa je drugi pas — različite rase, ali istog spola i nivoa aktivnosti — skočio na vrh preporuka:

```json
{
  "pasId": 3,
  "naziv": "Bella",
  "rasaNaziv": "Mješanac",
  "velicinaNaziv": "Srednja",
  "slikaNaslovna": "/images/psi/pas3.jpg",
  "datumRodjenja": null,
  "skor": 11.1,
  "razlog": "Spol \"Zenka\" odgovara vašim ranijim pregledima, favoritima, posjetama, zahtjevima ili pretragama; nivo aktivnosti \"Nizak\" odgovara vašim ranijim pregledima, favoritima, posjetama, zahtjevima ili pretragama; trenutno popularan (3 pregleda, 1 zahtjeva).",
  "personalizovano": true
}
```

Isto tako, samo ponavljanje pretrage s filterom "veličina = Džinovska" (bez ijedne stvarne interakcije s konkretnim psom) dovoljno je da `personalizovano` postane `true` i da džinovski psi skoče na vrh, s objašnjenjem `"Veličina \"Džinovska\" odgovara vašim ranijim pregledima, favoritima, posjetama, zahtjevima ili pretragama; ..."` — ovo je "korišteni filteri" signal u čistom obliku.

Napomena o formulaciji: razlog namjerno kaže "odgovara vašim ranijim pregledima, favoritima, posjetama, zahtjevima ili pretragama", a ne "odgovara vašoj preferenciji" — svaka od `rasaTezine`/`velicinaTezine`/`spolTezine`/`nivoAktivnostiTezine` mapa čuva po jednu težinu za svaku vrijednost s kojom je korisnik ikad imao interakciju, ne jednu fiksnu preferencu. Korisnik s izmiješanom historijom (npr. zahtjevi i za "Nizak" i za "Visok" nivo aktivnosti) će legitimno dobiti pse s obje vrijednosti među preporukama, svaki sa svojim tačnim objašnjenjem — to nije greška, nego stvarno stanje dvije odvojene, istinite težine. Formulacija "vašoj historiji" (množina, različiti tipovi) to jasno komunicira; "vašoj preferenciji" (jednina) bi to isto ponašanje učinilo da izgleda kontradiktorno.

Za cold-start korisnike, `razlog` je uvijek popularity-klauzula (npr. `"Trenutno popularan izbor (14 pregleda, 3 zahtjeva)."`) i `personalizovano` je `false` — front-end prikazuje diskretnu oznaku "Popularno" na takvim karticama, tako da korisnik zna da preporuka još nije lična.

## 5. Integracija u aplikaciju

### Backend (ASP.NET Core)

| Komponenta | Putanja |
|---|---|
| Kontroler (preporuke) | `DogShelter/DogShelter/Controllers/PreporukaController.cs` |
| Servis (implementacija + konstante) | `DogShelter/DogShelter.Services/Services/PreporukaService.cs` |
| Interfejs | `DogShelter/DogShelter.Services/Interfaces/IPreporukaService.cs` |
| DTO | `DogShelter/DogShelter.Model/PreporuceniPas.cs` |
| Favoriti — kontroler/servis | `DogShelter/DogShelter/Controllers/FavoritController.cs`, `DogShelter/DogShelter.Services/Services/FavoritService.cs` |
| Nivo aktivnosti — šifarnik | `DogShelter/DogShelter/Controllers/NivoAktivnostiController.cs`, `DogShelter/DogShelter.Services/Services/NivoAktivnostiService.cs` |
| Bilježenje korištenih filtera | `DogShelter/DogShelter.Services/Services/PretragaLogService.cs` (poziva se iz `PasController.Get`) |
| Seed (view-historija, nivoi aktivnosti za test naloge) | `DogShelter/DogShelter.Services/Database/DatabaseSeeder.cs` (`EnsurePregledPsaAsync`, `EnsureNivoAktivnostiAsync`) |

Endpoint:

```
GET /api/Preporuka/psi?take=5
Authorization: Bearer <token>   (bilo koja rola — Korisnik ili Volonter)
```

`KorisnikId` se uvijek uzima iz JWT-a (`ClaimTypes.NameIdentifier`), nikad iz query stringa ili tijela zahtjeva — korisnik ne može zatražiti tuđe preporuke.

Sve se računa u realnom vremenu iz postojećih tabela (`PregledPsa`, `Posjeta`, `Favorit`, `ZahtjevZaUdomljavanje`, `Udomljavanje`, `Pas`) bez dodatnog predproračunavanja. Jedina tabela posebno napravljena radi ovog modula je `PretragaLog` — bilježi filtere korištene pri pretrazi, jer ta informacija se nigdje drugo prirodno ne pamti.

### Flutter (mobilna aplikacija)

| Komponenta | Putanja |
|---|---|
| Domenski model (preporuke) | `dogshelter_shared/lib/preporuke/domain/preporuceni_pas.dart` |
| API klijent (preporuke) | `dogshelter_shared/lib/preporuke/data/preporuke_api.dart` |
| Riverpod provider (preporuke) | `dogshelter_shared/lib/preporuke/application/preporuke_providers.dart` |
| Prikaz (početni ekran, sekcija "Preporučeno za vas") | `dogshelter_mobile/lib/features/home/presentation/home_screen.dart` |
| Favoriti — domen/API/provider | `dogshelter_shared/lib/favorit/domain/favorit.dart`, `data/favorit_api.dart`, `application/favorit_providers.dart` |
| Favoriti — srce-dugme i ekran "Moji favoriti" | `dogshelter_mobile/lib/features/dogs/presentation/dog_detail_screen.dart`, `favoriti_list_screen.dart` |
| Nivo aktivnosti — filter i prikaz na detalju psa | `dogshelter_mobile/lib/features/dogs/presentation/dog_filter_sheet.dart`, `dog_detail_screen.dart` |

Preporuke se prikazuju kao horizontalni karusel kartica na početnom ekranu mobilne aplikacije (samo za korisnike, ne za volontere — volonterski početni ekran prikazuje njihove statistike umjesto toga). Svaka kartica prikazuje sliku, ime, rasu i veličinu psa te skraćeni `razlog` ispod — čime je preporuka objašnjena direktno u interfejsu, ne samo u API odgovoru.

Favoriti i filter po nivou aktivnosti su korisniku vidljive funkcije same za sebe (srce-dugme, "Moji favoriti" ekran, dropdown u filterima) — recommender ih koristi kao nusprodukt, korisnik ih ne dodaje "radi preporuka".

### Flutter (desktop aplikacija)

Desktop (administrativni dio sistema) ne prikazuje preporuke niti favorite — oni su koncept namijenjen krajnjem korisniku/posjetitelju, ne administratoru. Desktop administrira samo šifarnik `NivoAktivnosti` (Postavke → "Nivo aktivnosti psa", isti obrazac kao ostali šifarnici poput veličine psa) i postavlja tu vrijednost pri unosu/izmjeni psa (`dogshelter_desktop/lib/features/psi/presentation/psi_form_screen.dart`) — bez tog koraka, novi psi ne bi imali osobinu na osnovu koje recommender računa afinitet prema nivou aktivnosti.

## 6. Konstante algoritma

Sve žive kao `private const` polja u `PreporukaService.cs` (namjerno dokumentovane komentarom koji upućuje na ovaj fajl):

```csharp
PregledTypeWeight        = 1.0
PosjetaTypeWeight        = 2.0
FavoritTypeWeight        = 2.5
ZahtjevTypeWeight        = 3.0
UdomljavanjeTypeWeight   = 3.0
FilterTypeWeight         = 0.75

RasaMatchMultiplier             = 5.0
VelicinaMatchMultiplier         = 3.0
SpolMatchMultiplier             = 2.0
NivoAktivnostiMatchMultiplier   = 2.0
AgeSimilarityBonus              = 3.0
AgeToleranceMonths              = 24
ViewPopularityMultiplier        = 0.2
ZahtjevPopularityMultiplier     = 0.5
```

## 7. Dijagram toka

```
JWT → KorisnikId
        │
        ▼
Učitaj signale (PregledPsa, Posjeta, Favorit, ZahtjevZaUdomljavanje,
                Udomljavanje, PretragaLog)
        │
        ▼
Izgradi profil: rasaTezine, velicinaTezine, spolTezine,
                nivoAktivnostiTezine, preferiranaStarost
        │
        ▼
   ima li korisnik signala?
        │
   ┌────┴────┐
  DA          NE
   │           │
   ▼           ▼
Bodovanje   Bodovanje
(rasa+       (samo
velicina+    popularnost)
spol+
nivo aktivnosti+
starost+
popularnost)
   │           │
   └────┬──────┘
        ▼
Filtriraj kandidate (Dostupan, Aktivan, bez "Na čekanju" zahtjeva korisnika)
        │
        ▼
Izračunaj skor + razlog po kandidatu
        │
        ▼
Sortiraj opadajuće po skoru, uzmi prvih `take`
        │
        ▼
   Vrati listu PreporuceniPas (JSON)
```
