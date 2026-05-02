# Startet Sheetstorm mit AUDIVERIS als aktiver OMR-Engine.
#
# Audiveris ist die ältere, langsamere aber etablierte Java-OMR-Engine
# (https://github.com/Audiveris/audiveris). Wir nutzen sie zum
# Vergleichen mit unserer eigenen Sheetstorm-OMR (Rust).
#
# Beim ersten Start wird das Audiveris-Docker-Image gebaut (~5-10 Minuten).
# Danach geht der Start schnell.
#
# Optionen:
#   -BothEngines: laesst auch die Sheetstorm-OMR (Rust) parallel laufen,
#                 sodass Vergleichs-Calls moeglich sind.

param(
    [switch]$BothEngines
)

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
    $appHostArgs = @("--enable-audiveris", "--use-engine=audiveris")
    if ($BothEngines) {
        $appHostArgs += "--enable-omr"
    }

    Write-Host "🎼 Sheetstorm mit Audiveris als OMR-Engine starten..."
    Write-Host "   AppHost-Args: $($appHostArgs -join ' ')"
    Write-Host ""
    Write-Host "   Wenn das Docker-Image fehlt, dauert der erste Start ~5-10 min."
    Write-Host "   Audiveris läuft auf http://localhost:8081 (POST /recognize)."
    if ($BothEngines) {
        Write-Host "   Sheetstorm-OMR (Rust) läuft auf http://localhost:8091 (parallel)."
    }
    Write-Host ""

    dotnet run --project src/Sheetstorm.AppHost -- @appHostArgs
}
finally {
    Pop-Location
}
