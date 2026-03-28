#Requires -Version 7.0
<#
.SYNOPSIS
    Sheetstorm — One-time dev environment setup.
.DESCRIPTION
    Run this once after cloning. Checks prerequisites, restores dependencies,
    runs EF Core migrations, and prepares the Flutter app.
    Safe to re-run (idempotent).
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = $PSScriptRoot
$ApiProject = Join-Path $RepoRoot 'src' 'Sheetstorm.Api'
$InfraProject = Join-Path $RepoRoot 'src' 'Sheetstorm.Infrastructure'
$FlutterApp = Join-Path $RepoRoot 'sheetstorm_app'

function Write-Step  { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$msg) Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-Warn  { param([string]$msg) Write-Host "    WARN: $msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$msg) Write-Host "    FAIL: $msg" -ForegroundColor Red }

# ── Helper: refresh PATH from registry ──────────────────────────────
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

# ── Helper: check if winget is available ────────────────────────────
$HasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)

# ── 1. Check & install prerequisites ────────────────────────────────
Write-Step 'Checking prerequisites'

# ── 1a. .NET SDK ────────────────────────────────────────────────────
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    $dotnetVersion = (dotnet --version)
    Write-Ok "dotnet $dotnetVersion"
} else {
    Write-Warn '.NET SDK not found — installing'
    if ($HasWinget) {
        winget install --id Microsoft.DotNet.SDK.10 -e --accept-source-agreements --accept-package-agreements
        Refresh-Path
        if (Get-Command dotnet -ErrorAction SilentlyContinue) {
            Write-Ok "dotnet $(dotnet --version) installed"
        } else {
            Write-Fail '.NET SDK install succeeded but dotnet not found in PATH.'
            Write-Host '    Close and reopen your terminal, then re-run this script.'
            exit 1
        }
    } else {
        Write-Fail '.NET SDK is missing and winget is not available.'
        Write-Host '    Install manually from: https://dotnet.microsoft.com/download'
        exit 1
    }
}

# ── 1b. Flutter SDK (includes Dart) ─────────────────────────────────
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterVersion = (flutter --version --machine 2>$null | ConvertFrom-Json).frameworkVersion
    if (-not $flutterVersion) { $flutterVersion = 'unknown' }
    Write-Ok "flutter $flutterVersion"
} else {
    Write-Warn 'Flutter SDK not found — installing via git clone'
    $FlutterInstallDir = Join-Path $env:LOCALAPPDATA 'flutter'
    if (-not (Test-Path $FlutterInstallDir)) {
        Write-Host '    Cloning Flutter SDK (this may take a few minutes)...'
        git clone https://github.com/flutter/flutter.git -b stable $FlutterInstallDir
    }
    # Add to User PATH permanently
    $currentUserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $flutterBin = Join-Path $FlutterInstallDir 'bin'
    if ($currentUserPath -notlike "*$flutterBin*") {
        [System.Environment]::SetEnvironmentVariable('Path', "$currentUserPath;$flutterBin", 'User')
        Write-Ok 'Flutter added to User PATH'
    }
    Refresh-Path
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        # Run flutter precache to download engine artifacts
        flutter precache 2>$null
        Write-Ok "flutter installed at $FlutterInstallDir"
    } else {
        Write-Fail 'Flutter install completed but flutter not found in PATH.'
        Write-Host "    Add $flutterBin to your PATH manually, then re-run this script."
        exit 1
    }
}

# Accept Android licenses non-interactively (ignore errors if no Android SDK)
try { flutter doctor --android-licenses 2>$null | Out-Null } catch { }

# Dart ships with Flutter — verify it's on PATH
if (Get-Command dart -ErrorAction SilentlyContinue) {
    $dartVersion = (dart --version 2>&1) -replace '.*version:\s*', '' -replace '\s.*', ''
    Write-Ok "dart $dartVersion"
} else {
    Write-Warn 'dart not on PATH — it should come with Flutter. You may need to restart your terminal.'
}

# ── 1c. PostgreSQL (optional — do NOT auto-install) ─────────────────
$PgAvailable = $false
if (Get-Command psql -ErrorAction SilentlyContinue) {
    Write-Ok 'PostgreSQL client found'
    $PgAvailable = $true
} else {
    Write-Warn 'PostgreSQL not found — using in-memory database for dev.'
    Write-Host '    Install PostgreSQL for production-like testing.'
}

# ── 2. Restore .NET dependencies ────────────────────────────────────
Write-Step 'Restoring .NET dependencies'
dotnet restore (Join-Path $RepoRoot 'Sheetstorm.slnx')
Write-Ok '.NET packages restored'

# ── 3. Ensure dotnet-ef tool is available ────────────────────────────
Write-Step 'Checking dotnet-ef tool'

$toolManifest = Join-Path $RepoRoot '.config' 'dotnet-tools.json'
if (-not (Test-Path $toolManifest)) {
    Write-Warn 'No local tool manifest found — creating one'
    Push-Location $RepoRoot
    dotnet new tool-manifest 2>$null
    Pop-Location
}

$efInstalled = dotnet tool list --local 2>$null | Select-String 'dotnet-ef'
if (-not $efInstalled) {
    # Try local install first, fall back to global
    Write-Warn 'dotnet-ef not installed — installing'
    Push-Location $RepoRoot
    try {
        dotnet tool install dotnet-ef --local
        Write-Ok 'dotnet-ef installed (local tool)'
    } catch {
        Write-Warn 'Local install failed — trying global install'
        dotnet tool install --global dotnet-ef
        Refresh-Path
        Write-Ok 'dotnet-ef installed (global tool)'
    }
    Pop-Location
} else {
    Write-Ok 'dotnet-ef is available'
}

# ── 4. EF Core migrations ───────────────────────────────────────────
Write-Step 'Checking EF Core migrations'

$migrationsDir = Join-Path $InfraProject 'Migrations'
$hasMigrations = (Test-Path $migrationsDir) -and
                 (Get-ChildItem $migrationsDir -Filter '*.cs' -Exclude '*Snapshot*' | Measure-Object).Count -gt 0

if (-not $hasMigrations) {
    Write-Warn 'No migrations found — creating initial migration'
    Push-Location $RepoRoot
    dotnet ef migrations add Initial `
        --project $InfraProject `
        --startup-project $ApiProject
    Pop-Location
    Write-Ok 'Initial migration created'
} else {
    Write-Ok 'Migrations already exist — skipping creation'
}

# ── 5. Apply migrations (requires PostgreSQL running) ────────────────
Write-Step 'Applying EF Core migrations'
if (-not $PgAvailable) {
    Write-Warn 'Skipping database migration — PostgreSQL not detected.'
    Write-Host '    The app will use an in-memory database for development.'
    Write-Host '    To apply migrations later:  dotnet ef database update --project src/Sheetstorm.Infrastructure --startup-project src/Sheetstorm.Api'
} else {
    Write-Host '    (Requires PostgreSQL running on localhost:5432)'
    try {
        Push-Location $RepoRoot
        dotnet ef database update `
            --project $InfraProject `
            --startup-project $ApiProject
        Pop-Location
        Write-Ok 'Database updated'
    } catch {
        Write-Warn "Could not apply migrations: $_"
        Write-Host '    Make sure PostgreSQL is running and connection string is correct.'
        Write-Host '    You can apply later with: dotnet ef database update --project src/Sheetstorm.Infrastructure --startup-project src/Sheetstorm.Api'
    }
}

# ── 6. Enrich appsettings.Development.json ───────────────────────────
Write-Step 'Checking appsettings.Development.json'

$devSettings = Join-Path $ApiProject 'appsettings.Development.json'
if (Test-Path $devSettings) {
    $json = Get-Content $devSettings -Raw | ConvertFrom-Json
    if (-not ($json.PSObject.Properties.Name -contains 'ConnectionStrings')) {
        Write-Warn 'appsettings.Development.json exists but has no ConnectionStrings — leaving as-is'
        Write-Host '    Edit it manually if you need custom dev overrides.'
    } else {
        Write-Ok 'appsettings.Development.json already configured'
    }
} else {
    Write-Warn 'Creating appsettings.Development.json with local defaults'
    @'
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information",
      "Microsoft.EntityFrameworkCore": "Information"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=sheetstorm;Username=sheetstorm;Password=sheetstorm_dev"
  },
  "Jwt": {
    "Key": "DevOnlyKey_ChangeInProduction_AtLeast32Chars!!"
  }
}
'@ | Set-Content $devSettings -Encoding utf8
    Write-Ok 'Created with local dev defaults'
}

# ── 7. Flutter pub get ───────────────────────────────────────────────
Write-Step 'Installing Flutter dependencies'
Push-Location $FlutterApp
flutter pub get
Pop-Location
Write-Ok 'Flutter packages installed'

# ── 8. Flutter build_runner ──────────────────────────────────────────
Write-Step 'Running build_runner (code generation)'
Push-Location $FlutterApp
dart run build_runner build --delete-conflicting-outputs
Pop-Location
Write-Ok 'Code generation complete'

# ── Done ─────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host '  Sheetstorm setup complete!' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host ''
Write-Host 'Next steps:'
if (-not $PgAvailable) {
    Write-Host '  NOTE: PostgreSQL was not found. The app can run with an in-memory database.'
    Write-Host '        Install PostgreSQL for production-like testing.'
}
Write-Host '  1. Run: .\start.ps1              — start backend + frontend'
Write-Host '  2. Run: .\start.ps1 -BackendOnly — start backend only'
Write-Host '  3. Run: .\start.ps1 -FrontendOnly — start Flutter only'
Write-Host ''
