# 02 — Tech Stack

## Pflicht-Vorgaben (vom Auftraggeber)
* **.NET Aspire 13.x** als Orchestrierung für lokale Entwicklung
  und Service-Komposition.
* **ASP.NET Core Web API** als Backend.
* **PostgreSQL** als primäre Datenbank.
* **ASP.NET Core Identity** für Benutzer- und Rollen­verwaltung
  (kein externes IdP-Pflichtteil).
* **Playwright** für End-to-End-Tests, Pflicht für jede
  benutzersichtbare Funktion.

## Backend

| Bereich | Wahl | Begründung |
|---|---|---|
| Sprache/Runtime | C# 13 / .NET 10 | Vorhandenes Toolchain, LTS, Aspire 13.2 nativ |
| Web Framework | ASP.NET Core Minimal APIs + Endpoints | Schlank, performant, gut dokumentiert |
| ORM | Entity Framework Core 10 + Npgsql | Standard für PostgreSQL in .NET |
| Auth | ASP.NET Core Identity + Bearer-Tokens (Cookie für Web, JWT für API/Mobile) | Pflicht; Cookies vermeiden Token-Storage-Issues im Browser |
| Realtime | SignalR | Conductor-Sync-Fallback (iOS) und Notification-Push-down |
| Background Jobs | Hangfire (PostgreSQL-Storage) | OMR-Pipeline, Mail-Versand, Cleanup |
| File Storage | Pluggable: Lokal (Dev), S3-kompatibel (Prod, MinIO als Aspire-Container für Dev) | Trennung Datenbank/Blobs |
| Mail | MailKit + SMTP (Dev: MailHog im Aspire) | Standard |
| OMR | Audiveris (Java, als Sidecar-Container im Aspire-Stack, REST-Wrapper) | Beste OSS-OMR; Java-Isolation via Container |
| OpenAPI | NSwag oder Microsoft.AspNetCore.OpenApi | API-Doku + Client-Generierung |
| Logging | Serilog → OpenTelemetry → Aspire Dashboard | Aspire-Standard |
| Validierung | FluentValidation | Bewährt |

### Aspire-AppHost-Topologie

```
Sheetstorm.AppHost
├── postgres (Aspire.Hosting.PostgreSQL)
├── pgadmin (Dev only)
├── mailhog (Dev only, SMTP)
├── minio (S3-kompatibel)
├── audiveris (Custom Container, REST-Wrapper über CLI)
├── api (Sheetstorm.Api, Projekt)
└── web (Sheetstorm.Web, Projekt)
```

Aspire ServiceDefaults: OpenTelemetry, Health-Endpoints, Resilience.

## Frontend

### Technologie­wahl

**Blazor WebAssembly + PWA** als primärer Client.

**Begründung:**
* Eine Sprache (C#) für Backend & Frontend ⇒ shared DTOs/Validierung,
  einfacheres Refactoring, kleines Team.
* Aspire-natives Hosting + Debug-Story.
* PWA-Installable, Service-Worker, Offline-Cache (als
  Blazor-WASM Standard-Pattern mit IndexedDB für Daten).
* Web Bluetooth + Web HID via JS-Interop verfügbar.
* Plattformen: Chrome/Edge (Desktop alle, Android), Safari iOS
  (PWA „Zum Home-Bildschirm"), Firefox.

**Verworfen:**
* *Flutter Web* — vorhandener Vorlauf im Archiv, aber CanvasKit-DOM
  blockiert seriöses E2E-Testing mit Playwright (siehe Helpers im
  Archiv: alles über Shadow-DOM-Hacks). Außerdem .NET-Bruch.
* *React/Vue + separates JS-Frontend* — Doppel­stack, mehr Wartung,
  kein DTO-Sharing.
* *MAUI* — Multi-Plattform-Schmerz, Web-Browser-Nutzung schwierig,
  iOS-Updates langsam.

### Frontend-Bausteine

| Bereich | Wahl |
|---|---|
| UI Komponenten | MudBlazor (Material Design, deutsch lokalisiert, sehr aktiv) |
| Routing | Blazor Built-in |
| State | Fluxor (oder einfacher: scoped Services + cascading values, abhängig von Komplexität) |
| Forms/Validation | Blazor EditForm + FluentValidation (gleiche Validatoren wie Backend) |
| HTTP | typisierte Clients via NSwag-Generated Code |
| Offline-DB | IndexedDB via `Blazored.LocalStorage` + `MagicStorage` (oder direkt JS-Interop; SQLite-WASM Phase 2) |
| Annotation-Canvas | HTML5 Canvas + JS-Interop (oder `Excubo.Blazor.Canvas`) |
| PDF-Anzeige | PDF.js via JS-Interop (zuverlässig, gut testbar) |

### Native-Brücken (nur wo nötig)

* **iOS BLE-Empfang**: Phase-2-Companion via .NET MAUI Hybrid
  oder native Swift-Mini-App, die nur als BLE-Forwarder zur PWA
  agiert. Nicht Tag-1.
* **Pedal**: Keyboard-Modus deckt 95% ab, Web HID für Custom-Modes.

## DevOps / CI

| Bereich | Wahl |
|---|---|
| Versionsverwaltung | Git (GitHub) |
| CI | GitHub Actions |
| Container | Docker (Aspire generiert Manifeste) |
| E2E | Playwright Test Runner (.NET-Variante: `Microsoft.Playwright.NUnit` oder TS-Variante mit eigenen Specs) |
| Test (Backend) | xUnit + FluentAssertions + Testcontainers für PostgreSQL |
| Test (Blazor) | bUnit für Komponenten-Unit-Tests |
| Lint/Format | `dotnet format`, EditorConfig (vorhanden) |

### E2E-Konkretisierung

Playwright in **TypeScript** (Standard-Toolchain, beste DX, riesige
Community). Pro Funktion mindestens ein Happy-Path und ein
Edge-Case. Tests laufen gegen voll gestarteten Aspire-Stack mit
seeded Test-User.

## Wichtige Entscheidungen festgehalten

1. **Blazor WASM statt Flutter** — weil DOM-Testbarkeit mit
   Playwright + .NET-Sprachgleichheit + PWA out-of-the-box.
2. **PostgreSQL einzige relationale DB** — kein zweites
   SQLite-Schema im Frontend; Offline-Cache ist KV/IndexedDB,
   keine Query-Engine im Browser.
3. **Cookie-Auth für Web, Bearer für API** — vermeidet
   localStorage-XSS-Risiko bei Standard-Pfad.
4. **Audiveris als isolierter Container** — kein .NET-OMR, JVM
   bleibt im eigenen Sandbox-Prozess.
5. **Web Bluetooth nur Best-Effort** — Funktionalität, aber nicht
   Lock-In; Polling-Fallback ist immer da.
6. **Hangfire statt selbst­gebautes Scheduler** — ausgereift,
   Dashboard, Recurring Jobs, retry-policy.

## Audio / Playback (siehe Spec 17)

| Bereich | Wahl | Begründung |
|---|---|---|
| Audio-Engine | Web Audio API direkt (nativer `AudioContext` + `AudioWorklet`) | Niedrigste Latenz, keine Framework-Schicht. Bestehender `metronome.js` nutzt bereits Lookahead-Pattern. |
| Sample-Player | **`smplr`** (BSP, MIT-Lizenz) als Primär-Wahl | Aktiv gepflegter SF2/SFZ-Loader für Browser, lazy chunk-loading, polyphon, kleines Bundle (~30 KB). |
| Fallback-Player | `soundfont-player` | Wenn `smplr` zu kantig wird; älter, aber stabil; nur SF2. |
| **Bewusst nicht:** Tone.js | — | Großer Footprint, primär Sequencer-zentriert; wir brauchen einen reinen Sample-Renderer mit eigener Position-Logik (kommt aus BLE-Sync). |
| SF2-Parser | `sf2-parser` (npm, MIT) | Falls wir Patches selektiv extrahieren wollen. |
| SFZ-Parser | `@sfz-tools/core` | Für VCSL/Sonatina-Patches. |
| MusicXML → Note-Events | OSMD (`opensheetmusicdisplay`) liefert bereits `IGraphicalNote` mit Timing; wir konvertieren in eigene Event-Liste pro Stimme. | Vermeidet zweiten XML-Parser. |
| Soundfont-Hosting | Eigener S3-Bucket (MinIO in Dev), CDN in Prod. SF3 statt SF2 wegen ~3× kleinerer Größe. | Lizenz-Footer im UI „Sounds: MuseScore General (MIT)". |
