# Preporuka pasa (recommender sistem) — dokumentacija

## 1. Pregled

DogShelter uključuje sistem preporuke pasa korisnicima aplikacije: `GET /api/Preporuka/psi` vraća listu psi koje je sistem procijenio kao relevantne za trenutno prijavljenog korisnika, zajedno s numeričkim skorom i **tekstualnim objašnjenjem zašto je baš taj pas preporučen**.

Pristup je **content-based** (preporuke se zasnivaju na osobinama pasa — rasa, veličina, starost — koje korisnik pokazuje da preferira kroz vlastito ponašanje u aplikaciji), uz **popularnost** kao dodatni signal i **fallback za nove korisnike** bez historije (cold-start). Sistem je potpuno deterministički — nema crne kutije, nasumičnosti niti mašinskog učenja; svaki doprinos skoru se može pratiti do konkretnog signala i taj signal se uvijek pojavljuje u objašnjenju (`razlog`) koje korisnik vidi.

Sistem je namjerno **jednostavniji od collaborative filteringa** (ne postoji "korisnici slični vama" logika) jer aplikacija nema dovoljno korisnika/interakcija za takav pristup da bude smislen na ovoj razini podataka — content-based pristup na osnovu stvarnih osobina pasa je i transparentniji i lakše objasniv krajnjem korisniku, što je eksplicitan zahtjev.

## 2. Signali koji se koriste

Svi signali dolaze iz podataka koje aplikacija **stvarno bilježi tokom normalne upotrebe** — ništa nije izmišljeno posebno za ovaj modul:

| Signal | Izvor (tabela) | Šta znači | Težina |
|---|---|---|---|
| Pregled detalja psa | `PregledPsa` (automatski se bilježi pri svakom `GET /api/Pas/{id}`) | Korisnik je pogledao profil psa — najslabiji signal, samo pregledavanje | **1.0** |
| Zakazana posjeta | `Posjeta` | Korisnik je rezervisao posjetu tom psu — jača namjera od pregleda | **2.0** |
| Zahtjev za udomljavanje | `ZahtjevZaUdomljavanje` (bilo koji status) | Korisnik je formalno zatražio udomljavanje — jaka namjera, bez obzira na ishod | **3.0** |
| Realizovano udomljavanje | `Udomljavanje` | Korisnik je stvarno udomio psa te rase/veličine — najjači mogući dokaz preferencije, dodaje se **povrh** težine iz odgovarajućeg zahtjeva | **3.0** |

Za svakog korisnika, sistem prolazi kroz sve četiri tabele i za svaki zabilježeni signal akumulira težinu na **rasu** (`RasaId`) i **veličinu** (`VelicinaPsaId`) psa na kojeg se signal odnosi. Ako korisnik ima više signala za istu rasu (npr. pogledao je i kasnije zatražio udomljavanje istog psa), težine se **zbrajaju** — to je namjerno, jer ponovljeni signal znači jaču preferenciju.

Dodatno se prati i **prosječna starost** (u mjesecima) pasa iz svih signala korisnika, kao osnova za bonus na sličnu starost kod kandidata.

## 3. Algoritam

### Korak 1 — profil korisnika

Za `KorisnikId` iz JWT tokena, sistem gradi:
- `rasaTezine`: rječnik `RasaId → zbir težina`
- `velicinaTezine`: rječnik `VelicinaPsaId → zbir težina`
- `preferiranaStarost`: prosjek starosti (mjeseci) svih pasa iz signala, ako barem jedan signal ima poznat datum rođenja

### Korak 2 — kandidati

Kandidati su svi psi koji su:
- `Aktivan = true` (nisu obrisani/arhivirani),
- imaju status `StatusPsa.Naziv = "Dostupan"` (nisu već udomljeni),
- **nisu** predmet trenutno aktivnog (`Na čekanju`) zahtjeva za udomljavanje istog korisnika — ne preporučuje se pas kojeg je korisnik već formalno zatražio.

(Psi koje je korisnik već udomio ili čiji je zahtjev odobren automatski otpadaju jer im status više nije "Dostupan" — nema potrebe za posebnim filterom.)

### Korak 3 — bodovanje

Ako korisnik ima **barem jedan** signal (bilo koja težina u `rasaTezine` ili `velicinaTezine`), za svakog kandidata:

```
skor = 0

ako rasaTezine sadrži rasu kandidata:
    skor += rasaTezine[RasaId] × 5.0        (RasaMatchMultiplier)

ako velicinaTezine sadrži veličinu kandidata:
    skor += velicinaTezine[VelicinaPsaId] × 3.0   (VelicinaMatchMultiplier)

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

Ako korisnik **nema nijedan signal** (novi korisnik koji nikad nije pregledao, posjetio, tražio ili udomio psa), preskaču se članovi bodovanja vezani za rasu/veličinu/starost i koristi se **samo popularnost**:

```
skor = brojPregleda(kandidat) × 0.2 + brojZahtjeva(kandidat) × 0.5
```

Ovo garantuje da preporuke nikad nisu prazna lista (osim ako u sistemu doslovno nema nijednog dostupnog psa) — čak i potpuno nov korisnik odmah dobija smislenu, popularnošću vođenu listu.

## 4. Objašnjenje preporuke (`razlog`)

Svaki element odgovora nosi polje `razlog` — čitljivu rečenicu koja **nabraja svaki signal koji je stvarno doprinio skoru** tog konkretnog kandidata, ne samo najjači. U DogShelteru, ako podudaranje rase, veličine, slična starost i popularnost svi doprinesu skoru, sve četiri klauzule se pojavljuju u `razlog`, spojene sa "; ".

Primjer stvarnog odgovora (iz `korisnik`/`test` test naloga):

```json
{
  "pasId": 3,
  "naziv": "Bella",
  "rasaNaziv": "Mješanac",
  "velicinaNaziv": "Srednja",
  "slikaNaslovna": "/images/psi/pas3.jpg",
  "datumRodjenja": null,
  "skor": 144.5,
  "razlog": "Rasa \"Mješanac\" odgovara vašim ranijim pregledima, posjetama ili zahtjevima; veličina \"Srednja\" odgovara vašim preferencijama; trenutno popularan (0 pregleda, 1 zahtjeva).",
  "personalizovano": true
}
```

Za cold-start korisnike, `razlog` je uvijek popularity-klauzula (npr. `"Trenutno popularan izbor (14 pregleda, 3 zahtjeva)."`) i `personalizovano` je `false` — front-end prikazuje diskretnu oznaku "Popularno" na takvim karticama, tako da korisnik zna da preporuka još nije lična.

## 5. Integracija u aplikaciju

### Backend (ASP.NET Core)

| Komponenta | Putanja |
|---|---|
| Kontroler | `DogShelter/DogShelter/Controllers/PreporukaController.cs` |
| Servis (implementacija + konstante) | `DogShelter/DogShelter.Services/Services/PreporukaService.cs` |
| Interfejs | `DogShelter/DogShelter.Services/Interfaces/IPreporukaService.cs` |
| DTO | `DogShelter/DogShelter.Model/PreporuceniPas.cs` |
| Seed (view-historija za test naloge) | `DogShelter/DogShelter.Services/Database/DatabaseSeeder.cs` (`EnsurePregledPsaAsync`) |

Endpoint:

```
GET /api/Preporuka/psi?take=5
Authorization: Bearer <token>   (bilo koja rola — Korisnik ili Volonter)
```

`KorisnikId` se uvijek uzima iz JWT-a (`ClaimTypes.NameIdentifier`), nikad iz query stringa ili tijela zahtjeva — korisnik ne može zatražiti tuđe preporuke.

Nema posebne tabele za "signale" — sve se računa u realnom vremenu iz postojećih tabela (`PregledPsa`, `Posjeta`, `ZahtjevZaUdomljavanje`, `Udomljavanje`, `Pas`), bez dodatnog skladištenja ili predproračunavanja.

### Flutter (mobilna aplikacija)

| Komponenta | Putanja |
|---|---|
| Domenski model | `dogshelter_shared/lib/preporuke/domain/preporuceni_pas.dart` |
| API klijent | `dogshelter_shared/lib/preporuke/data/preporuke_api.dart` |
| Riverpod provider | `dogshelter_shared/lib/preporuke/application/preporuke_providers.dart` |
| Prikaz (početni ekran, sekcija "Preporučeno za vas") | `dogshelter_mobile/lib/features/home/presentation/home_screen.dart` |

Preporuke se prikazuju kao horizontalni karusel kartica na početnom ekranu mobilne aplikacije (samo za korisnike, ne za volontere — volonterski početni ekran prikazuje njihove statistike umjesto toga). Svaka kartica prikazuje sliku, ime, rasu i veličinu psa te skraćeni `razlog` ispod — čime je preporuka objašnjena direktno u interfejsu, ne samo u API odgovoru. Desktop aplikacija (administrativni dio sistema) ne prikazuje preporuke — one su koncept namijenjen krajnjem korisniku/posjetitelju, ne administratoru.

## 6. Konstante algoritma

Sve žive kao `private const` polja u `PreporukaService.cs` (namjerno dokumentovane komentarom koji upućuje na ovaj fajl):

```csharp
PregledTypeWeight        = 1.0
PosjetaTypeWeight         = 2.0
ZahtjevTypeWeight         = 3.0
UdomljavanjeTypeWeight    = 3.0

RasaMatchMultiplier       = 5.0
VelicinaMatchMultiplier   = 3.0
AgeSimilarityBonus        = 3.0
AgeToleranceMonths        = 24
ViewPopularityMultiplier      = 0.2
ZahtjevPopularityMultiplier   = 0.5
```

## 7. Dijagram toka

```
JWT → KorisnikId
        │
        ▼
Učitaj signale (PregledPsa, Posjeta, ZahtjevZaUdomljavanje, Udomljavanje)
        │
        ▼
Izgradi profil: rasaTezine, velicinaTezine, preferiranaStarost
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
