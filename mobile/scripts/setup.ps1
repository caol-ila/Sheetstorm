# Initialisiert die nativen Capacitor-Plattformen.
# Muss einmalig nach Klon ausgefuehrt werden.
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot/..
try {
  Write-Host "📦 npm install …"
  npm install
  Write-Host "🔨 Web-Bundle erzeugen …"
  npm run build:www
  Write-Host "🤖 Android-Plattform hinzufuegen …"
  if (-not (Test-Path "android")) { npx cap add android } else { Write-Host "  android/ existiert schon, ueberspringe" }
  Write-Host "🍎 iOS-Plattform hinzufuegen (nur auf macOS möglich)…"
  if (-not (Test-Path "ios") -and ($IsMacOS)) { npx cap add ios } else { Write-Host "  ios/ uebersprungen" }
  Write-Host "🔁 cap sync …"
  npx cap sync
  Write-Host "✓ Capacitor initialisiert. Naechste Schritte siehe README."
} finally { Pop-Location }
