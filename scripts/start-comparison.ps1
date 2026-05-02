# Startet Sheetstorm mit BEIDEN OMR-Engines parallel + UI nutzt die explizit
# gewaehlte. Erlaubt:
# - Engine via UI/API zu vergleichen (beide Endpoints sind erreichbar)
# - Schnellen Wechsel via Env: SHEETSTORM_USE_ENGINE=audiveris|sheetstorm
#
# Default-Engine: sheetstorm (Rust), faster.

param(
    [ValidateSet("sheetstorm", "audiveris", "stub")]
    [string]$Engine = "sheetstorm"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
    Write-Host "🎼🚀 Sheetstorm mit BEIDEN OMR-Engines starten..."
    Write-Host "   Aktive Engine fuer Web-UI: $Engine"
    Write-Host ""
    Write-Host "   Audiveris      → http://localhost:8081"
    Write-Host "   Sheetstorm-OMR → http://localhost:8091"
    Write-Host ""
    Write-Host "   Beide HTTP-APIs sind kompatibel (POST /recognize multipart)."
    Write-Host "   Vergleichs-Calls direkt via curl moeglich."
    Write-Host ""

    dotnet run --project src/Sheetstorm.AppHost -- `
        --enable-audiveris `
        --enable-omr `
        --use-engine=$Engine
}
finally {
    Pop-Location
}
