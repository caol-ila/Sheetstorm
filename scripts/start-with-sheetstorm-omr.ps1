# Startet Sheetstorm mit der EIGENEN Sheetstorm-OMR (Rust) als aktiver Engine.
#
# Sheetstorm-OMR ist unsere eigene Rust-basierte OMR-Engine
# (siehe src/omr-rust/). Schnell (~1s/Seite), produziert Detections-JSON
# mit Bbox-Daten + SIG (Symbol Interpretation Graph).
#
# Optionen:
#   -BothEngines: laesst Audiveris parallel mitlaufen fuer Vergleich.

param(
    [switch]$BothEngines
)

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
    $appHostArgs = @("--enable-omr", "--use-engine=sheetstorm")
    if ($BothEngines) {
        $appHostArgs += "--enable-audiveris"
    }

    Write-Host "🚀 Sheetstorm mit Sheetstorm-OMR (Rust) als Engine starten..."
    Write-Host "   AppHost-Args: $($appHostArgs -join ' ')"
    Write-Host ""
    Write-Host "   Sheetstorm-OMR läuft auf http://localhost:8091."
    if ($BothEngines) {
        Write-Host "   Audiveris läuft auf http://localhost:8081 (parallel)."
    }
    Write-Host ""

    dotnet run --project src/Sheetstorm.AppHost -- @appHostArgs
}
finally {
    Pop-Location
}
