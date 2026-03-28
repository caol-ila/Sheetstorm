# start-remote-copilot.ps1
# Startet Copilot CLI mit cli-tunnel fuer Remote-Zugriff vom Handy.
# Verwendung: .\scripts\start-remote-copilot.ps1 [-Model <modell>] [-Port <port>] [-Name <name>]

param(
    [string]$Model = "",
    [int]$Port = 0,
    [string]$Name = "sheetstorm"
)

# Pruefen ob cli-tunnel verfuegbar ist
if (-not (Get-Command cli-tunnel -ErrorAction SilentlyContinue)) {
    Write-Error "cli-tunnel ist nicht installiert. Bitte ausfuehren: npm install -g cli-tunnel"
    exit 1
}

# Pruefen ob devtunnel verfuegbar ist
if (-not (Get-Command devtunnel -ErrorAction SilentlyContinue)) {
    Write-Error "devtunnel ist nicht installiert. Bitte ausfuehren: winget install Microsoft.devtunnel"
    exit 1
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Sheetstorm - Copilot CLI Remote Start" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starte cli-tunnel fuer Remote-Zugriff vom Handy..." -ForegroundColor Yellow
Write-Host "Nach dem Start den QR-Code mit dem Handy scannen." -ForegroundColor Yellow
Write-Host ""

# Argumente aufbauen
$cliTunnelArgs = @()

if ($Port -gt 0) {
    $cliTunnelArgs += "--port"
    $cliTunnelArgs += $Port
}

if ($Name) {
    $cliTunnelArgs += "--name"
    $cliTunnelArgs += $Name
}

# Copilot-Befehl und Argumente
$cliTunnelArgs += "copilot"
$cliTunnelArgs += "--yolo"

if ($Model) {
    $cliTunnelArgs += "--model"
    $cliTunnelArgs += $Model
}

# Starten
cli-tunnel @cliTunnelArgs
