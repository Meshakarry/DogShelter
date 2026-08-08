# Docker — running the DogShelter API + Worker

## Priprema

1. Raspakiraj `.env-tajne.zip` (lozinka: `fit`). Ako Windows Explorer javi grešku, koristi 7-Zip.
2. Postavi `.env` u ovaj folder (gdje je `docker-compose.yml`).

## Pokretanje

```bash
docker compose up -d --build
```

| Servis | URL / port |
|--------|------------|
| API | http://localhost:8080 |
| Swagger | http://localhost:8080/swagger |
| RabbitMQ management | http://localhost:15672 |
| SQL Server | localhost:1433 |

## Baza podataka (automatski)

Pri **prvom** pokretanju (ili nakon `docker compose down -v`) API:

1. čeka da SQL Server bude spreman
2. pokreće EF migracije — kreira bazu `180026` i tabele
3. seeda uloge, admin korisnika i demo podatke

**Admin prijava (seed):** vrijednosti iz `.env` (`AdminSeed__UserName` / `AdminSeed__Password`, default `admin` / `Admin123!`).

## Worker

`dogshelter_worker` konzumira poruke sa RabbitMQ (reset lozinke, obavijesti o zaduženju) i šalje email preko SMTP-a. Nema izloženi port — provjeri njegov rad preko `docker compose logs -f dogshelter_worker` ili `scripts/validate-worker.ps1` iz root foldera repozitorija.

## Zaustavljanje

```bash
docker compose down
```

Za potpuno čist start (briše bazu i RabbitMQ podatke):

```bash
docker compose down -v
```
