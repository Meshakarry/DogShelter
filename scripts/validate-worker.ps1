# Validacija RabbitMQ / Worker integracije
# Preduslov: API i Worker moraju biti pokrenuti (docker compose up -d, ili oba nativno
# preko `dotnet run` uz kontejnerizovani RabbitMQ)
#
# Zatim pokreni ovaj skript: .\scripts\validate-worker.ps1 -Email "test@example.com"
# Default BaseUrl je docker-compose portal (8080). Za nativni `dotnet run` API
# proslijedi -BaseUrl "http://localhost:5265".

param(
    [string]$BaseUrl = "http://localhost:8080",
    [Parameter(Mandatory = $true)]
    [string]$Email
)

$ErrorActionPreference = "Stop"
$RequestBody = @{ Email = $Email } | ConvertTo-Json

Write-Host "=== Validacija RabbitMQ / Worker ===" -ForegroundColor Cyan
Write-Host "1. Trigger reset lozinke (publish na RabbitMQ)..." -ForegroundColor Yellow

try {
    Invoke-RestMethod -Uri "$BaseUrl/api/PasswordReset/request" `
        -Method Post -ContentType "application/json" -Body $RequestBody | Out-Null
    Write-Host "   OK - zahtjev prihvacen." -ForegroundColor Green
} catch {
    Write-Host "   GRESKA: API nije dostupan na $BaseUrl ili je rate limit pogodjen." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== API dio uspjesan ===" -ForegroundColor Green
Write-Host "Ako RabbitMQ i Worker rade, provjeri:"
Write-Host "  - docker compose logs -f dogshelter_worker (trebalo bi da vidis konzumiranu poruku)" -ForegroundColor Cyan
Write-Host "  - inbox za $Email (stize email sa kodom za reset lozinke)" -ForegroundColor Cyan
Write-Host ""
Write-Host "RabbitMQ Management: http://localhost:15672 (korisnicko ime/lozinka iz .env)" -ForegroundColor Gray
