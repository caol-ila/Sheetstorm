# Audiveris-Integration

## Was

Audiveris ist eine Open-Source-OMR-Engine (Optical Music Recognition):
PDF/Bild → MusicXML. Sheetstorm nutzt es als Sidecar-Container im
Aspire-Stack, um aus hochgeladenen Noten-PDFs automatisch die
Stimmen zu erkennen.

## Status

* `IOmrEngine` ist die Plug-in-Schnittstelle.
* `StubOmrEngine` (Default) liefert Heuristik-basierte Vorschläge.
* `AudiverisOmrEngine` ruft Audiveris im Container über HTTP auf
  und parst die zurückgelieferte MusicXML.

## Aktivieren

```pwsh
# Lokal mit Audiveris-Container (Erst-Build dauert mehrere Minuten,
# braucht Docker und ~1 GB freien Speicher)
dotnet run --project src\Sheetstorm.AppHost -- --enable-audiveris

# Oder über Env-Variable
$env:SHEETSTORM_ENABLE_AUDIVERIS = 'true'
dotnet run --project src\Sheetstorm.AppHost
```

Im Web-Service wird automatisch `Audiveris__BaseUrl` gesetzt, sobald
der Container läuft. `Program.cs` switched dann auf `AudiverisOmrEngine`.

## Container-Komponenten

`docker/audiveris/`:

* `Dockerfile` — basiert auf `eclipse-temurin:21-jre-jammy`,
  installiert Audiveris 5.6.1 + Tesseract (deutsch+englisch) +
  Python+Flask für den HTTP-Wrapper.
* `server.py` — Flask-Server mit `/health` und `/recognize`.

## Performance-Erwartung

| PDF | Audiveris-Zeit |
|---|---|
| Einseitig sauber | ~5–10s |
| 4 Seiten Verlag | ~20–40s |
| 10 Seiten Scan | ~60–120s |

Der `OmrBackgroundWorker` verarbeitet sequentiell, also einen Job
zur Zeit. Für mehr Durchsatz: mehrere Worker-Instanzen oder
Audiveris-Container mit mehr Threads.

## MusicXML-Parser

`AudiverisOmrEngine.ParseMusicXml` extrahiert:

* `<work-title>` oder `<movement-title>` als Werk-Titel
* `<creator type="composer">` als Komponist
* `<part-list><score-part><part-name>` als Stimm-Vorschläge
* Fuzzy-Match gegen Sheetstorm-Stimmen-Taxonomie (Klarinette in B etc.)

## Limitierungen

* **Container-Build**: ~800 MB Image, daher nicht in der Standard-CI.
* **Genauigkeit**: ~90% bei sauberen Verlags-PDFs, deutlich
  schlechter bei handschriftlichen oder stark gescannten Noten.
* **Sprache**: Tesseract-Sprachpakete sind DE+EN. Für andere
  Sprachen das Dockerfile erweitern.
* **Stimmen-Trennung in PDF**: Audiveris erkennt MusicXML-Parts,
  aber für Sheetstorm-spezifisches PDF-Splitting pro Stimme braucht
  es einen zusätzlichen Schritt (Roadmap).

## Roadmap

* PDF-Splitting pro erkannter Stimme (aktuell wird Original-PDF
  jeder Stimme angehängt)
* AI-Tagging via LLM nach OMR (Genre, Schwierigkeit aus MusicXML)
* Manuelle Korrektur-UI im OMR-Wizard für falsche Stimm-Zuordnungen
* Batch-Upload mehrerer PDFs gleichzeitig
