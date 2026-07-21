#Requires -Version 5.1
<#
.SYNOPSIS
  Kreira password-zasticeni ZIP sa .env za predaju na DL sistem.

.DESCRIPTION
  1. Provjerava da postoji .env u istom folderu kao docker-compose.yml
  2. Pakira .env u .env-tajne.zip sa zadatom lozinkom

.PARAMETER ZipPassword
  Lozinka za ZIP - istu postavite na DL sistem u zadatke.

.PARAMETER OutputZip
  Ime izlaznog ZIP fajla (default: .env-tajne.zip).

.EXAMPLE
  .\scripts\create-secrets-zip.ps1 -ZipPassword "MojaLozinkaZaDL2026"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPassword,

    [string]$OutputZip = ".env-tajne.zip"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root ".env"

if (-not (Test-Path $envFile)) {
    throw "Nije pronadjen .env u $root. Kreiraj ga prije pokretanja skripte."
}

$placeholders = @(
    'REPLACE_WITH_'
)
$content = Get-Content $envFile -Raw
if ($content -match 'REPLACE_WITH_') {
    Write-Warning ".env jos sadrzi placeholder vrijednosti - popunite prije predaje."
}
if ($content -match '(?m)^JWTSettings__Key=\s*$') {
    Write-Warning ".env: JWTSettings__Key je prazan."
}

$zipPath = Join-Path $root $OutputZip
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

$sevenZip = @(
    "${env:ProgramFiles}\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($sevenZip) {
    $tempDir = Join-Path $env:TEMP "dogshelter-secrets-$([Guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    try {
        Copy-Item $envFile (Join-Path $tempDir ".env")
        # ZipCrypto (bez AES) - Windows Explorer moze raspakirati; AES256 ne podrzava.
        & $sevenZip a -tzip "-p$ZipPassword" $zipPath (Join-Path $tempDir ".env") | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "7-Zip nije uspio kreirati ZIP." }
    }
    finally {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Kreiran: $zipPath (lozinka postavljena, kompatibilno s Windows Explorer)" -ForegroundColor Green
}
else {
    Write-Warning "7-Zip nije instaliran - kreiram nezasticeni ZIP. Instalirajte 7-Zip za password ZIP."
    Compress-Archive -Path $envFile -DestinationPath $zipPath -Force
    Write-Host "Kreiran: $zipPath (BEZ lozinke - instalirajte 7-Zip za DL zahtjev)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Commitaj $OutputZip u repozitorij. NE commituj .env." -ForegroundColor Cyan
