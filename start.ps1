#Requires -Version 7.0
<#
.SYNOPSIS
    Sheetstorm — Start the full dev stack (backend + frontend).
.DESCRIPTION
    Starts the ASP.NET Core backend (background job) and the Flutter app.
    Use -BackendOnly or -FrontendOnly to start just one part.
.PARAMETER BackendOnly
    Start only the ASP.NET Core backend.
.PARAMETER FrontendOnly
    Start only the Flutter app (assumes backend is already running).
.PARAMETER Web
    Run the Flutter app in Chrome (web mode) instead of default device.
#>

param(
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [switch]$Web
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = $PSScriptRoot
$ApiProject = Join-Path $RepoRoot 'src' 'Sheetstorm.Api'
$FlutterApp = Join-Path $RepoRoot 'sheetstorm_app'

$BackendUrl = 'https://localhost:5001'
$HealthUrl  = "$BackendUrl/health"
$SwaggerUrl = "$BackendUrl/openapi/v1.json"

function Write-Step  { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$msg) Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-Warn  { param([string]$msg) Write-Host "    WARN: $msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$msg) Write-Host "    FAIL: $msg" -ForegroundColor Red }

$backendJob = $null

function Start-Backend {
    Write-Step 'Starting ASP.NET Core backend'
    Write-Host "    Project: $ApiProject"

    $script:backendJob = Start-Job -ScriptBlock {
        param($proj)
        Set-Location $proj
        dotnet run
    } -ArgumentList $ApiProject

    Write-Ok "Backend starting (Job ID: $($script:backendJob.Id))"

    # Wait for backend to become healthy
    Write-Host '    Waiting for backend to be ready...' -NoNewline
    $maxAttempts = 30
    $ready = $false

    for ($i = 1; $i -le $maxAttempts; $i++) {
        Start-Sleep -Seconds 2
        Write-Host '.' -NoNewline
        try {
            $response = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 3 -SkipCertificateCheck -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $ready = $true
                break
            }
        } catch {
            # Backend not ready yet
        }
    }

    Write-Host ''
    if ($ready) {
        Write-Ok "Backend is healthy at $BackendUrl"
    } else {
        Write-Warn "Backend did not respond to health check within 60s"
        Write-Host '    It may still be starting. Check logs with: Receive-Job -Id' $script:backendJob.Id
        Write-Host '    Make sure PostgreSQL is running and connection string is correct.'
    }
}

function Start-Frontend {
    Write-Step 'Starting Flutter app'
    Write-Host "    Project: $FlutterApp"

    Push-Location $FlutterApp
    if ($Web) {
        # Find available web browser (Edge fallback if Chrome not installed)
        $webDevice = 'chrome'
        $devices = flutter devices --machine 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($devices) {
            $hasChrome = $devices | Where-Object { $_.id -eq 'chrome' }
            if (-not $hasChrome) {
                $edgeDevice = $devices | Where-Object { $_.id -eq 'edge' }
                if ($edgeDevice) { $webDevice = 'edge' }
            }
        }
        Write-Host "    Mode: Web ($webDevice)"
        flutter run -d $webDevice
    } else {
        # Auto-detect best available device
        Write-Host '    Mode: default device'
        Write-Host '    Tip: Use -Web flag to run in browser'
        flutter run -d windows
    }
    Pop-Location
}

# ── Main ─────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '  Sheetstorm Dev Environment' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan

if ($FrontendOnly) {
    Start-Frontend
} elseif ($BackendOnly) {
    Start-Backend
    Write-Host ''
    Write-Host '  Backend running in background job.' -ForegroundColor Green
    Write-Host "  Health:  $HealthUrl"
    Write-Host "  OpenAPI: $SwaggerUrl"
    Write-Host ''
    Write-Host '  Commands:'
    Write-Host "    Receive-Job -Id $($backendJob.Id)     — view backend logs"
    Write-Host "    Stop-Job -Id $($backendJob.Id)        — stop backend"
    Write-Host "    Remove-Job -Id $($backendJob.Id)      — clean up job"
    Write-Host ''
} else {
    Start-Backend

    Write-Host ''
    Write-Host '  URLs:' -ForegroundColor Green
    Write-Host "    Backend:  $BackendUrl"
    Write-Host "    Health:   $HealthUrl"
    Write-Host "    OpenAPI:  $SwaggerUrl"
    Write-Host ''
    Write-Host "  Backend is running in background (Job ID: $($backendJob.Id))"
    Write-Host "  Stop backend: Stop-Job -Id $($backendJob.Id)"
    Write-Host ''

    Start-Frontend

    # Clean up backend when Flutter exits
    if ($backendJob) {
        Write-Step 'Cleaning up'
        Stop-Job -Id $backendJob.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $backendJob.Id -ErrorAction SilentlyContinue
        Write-Ok 'Backend stopped'
    }
}
