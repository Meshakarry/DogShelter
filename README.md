# DogShelter — Seminarski rad

Sistem za upravljanje azilom za pse (Azil za pse Bugojno) — digitalizacija procesa udomljavanja, posjeta, donacija, volonterskog rada i obavijesti. ASP.NET Core API, RabbitMQ email servis, Flutter (mobile + desktop).

## Arhitektura

| Komponenta | Opis |
|------------|------|
| `DogShelter` | REST API (ASP.NET Core, .NET 10) |
| `DogShelter.Worker` | RabbitMQ radnik (slanje emaila — reset lozinke, obavijesti o zaduženju) |
| `dogshelter_mobile` | Flutter mobilna aplikacija (korisnici, volonteri) |
| `dogshelter_desktop` | Flutter desktop (Windows) aplikacija (administratori) |

## Preduvjeti

- Docker & Docker Compose
- .NET 10 SDK — za lokalni razvoj bez Dockera
- Flutter SDK (najnovija stable verzija)
- Android Studio (AVD emulator) — za mobilnu verziju
- SQL Server / LocalDB — za lokalni razvoj bez Dockera

## Pokretanje s Dockerom (preporučeno)

1. Kloniraj repozitorij
2. U folderu `DogShelter`:
   - raspakiraj `.env-tajne.zip` (šifra: **fit**)
   - ako Windows Explorer ne uspije, koristi **7-Zip** (desni klik → 7-Zip → Extract)
   - postavi `.env` u isti folder gdje je `docker-compose.yml`
3. Pokreni:

```bash
cd DogShelter
docker compose up --build
```

Pri prvom pokretanju API automatski čeka bazu, primjenjuje EF Core migracije i seeda uloge, test korisnike i demo podatke — nije potrebna nikakva ručna izmjena koda, porta ili konekcionog stringa.

| Servis | URL |
|--------|-----|
| API | http://localhost:8080 |
| Swagger | http://localhost:8080/swagger |
| RabbitMQ management | http://localhost:15672 |
| SQL Server | localhost:1433 |

### Flutter → dockerizirani backend

```bash
cd dogshelter_mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080    # Android emulator

cd dogshelter_desktop
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```

## Lokalni razvoj (bez Dockera)

`.env` se automatski učitava (`DotNetEnv`, traži se u nadređenim folderima) — nije potrebno ručno postavljati environment varijable prije `dotnet run`, dovoljno je da `.env` postoji u `DogShelter` folderu (isti korak kao za Docker, gore).

### API

```powershell
cd DogShelter\DogShelter
dotnet run
```

API sluša na `http://localhost:5265` (vidi `Properties/launchSettings.json`).

### Worker (email servis)

```powershell
cd DogShelter\DogShelter.Worker
dotnet run
```

Nema izloženi port — konzumira poruke sa RabbitMQ i šalje email preko SMTP-a.

### Desktop (Flutter)

```bash
cd dogshelter_desktop
flutter run -d windows
```

Bez `--dart-define`, desktop aplikacija se po defaultu povezuje na `http://localhost:5265`.

### Mobile (Flutter) — Android emulator

```bash
cd dogshelter_mobile
flutter run
```

Bez `--dart-define`, mobilna aplikacija se po defaultu povezuje na `http://10.0.2.2:5265` (Android emulator loopback ka hostu).

### Release build (za predaju)

```bash
cd dogshelter_mobile && flutter build apk --release
cd dogshelter_desktop && flutter build windows --release
```

Build fajlovi se ne commit-uju u repozitorij — prilažu se kao ZIP arhiva kroz GitHub Releases.

## Login podaci (seed)

Svi nalozi se seeduju automatski pri prvom pokretanju backenda.

| Uloga | Korisničko ime | Lozinka | Aplikacija |
|-------|----------------|---------|------------|
| Admin | admin | vrijednost iz `.env` (`AdminSeed__Password`, podrazumijevano `Admin123!`) | dogshelter_desktop |
| Korisnik | korisnik | test | dogshelter_mobile |
| Volonter | volonter | test | dogshelter_mobile |

## Stripe test kartica

- Broj: **4242 4242 4242 4242**
- Datum isteka: bilo koji budući (npr. 12/34)
- CVC: bilo koja 3 broja

## Konfiguracija i tajne

Tajne (JWT ključ, connection string, RabbitMQ, SMTP, Stripe) **nisu** u `appsettings.json` — sve dolaze iz `DogShelter/.env`, koji se u repozitoriju nalazi kao **`DogShelter/.env-tajne.zip`**.

**Šifra za raspakiranje: `fit`**

Detaljnije Docker upute (worker provjera, potpuni reset baze): [`DogShelter/README.docker.md`](DogShelter/README.docker.md)

## Dodatna dokumentacija

- [`recommender-dokumentacija.md`](recommender-dokumentacija.md) — opis sistema preporuke pasa
