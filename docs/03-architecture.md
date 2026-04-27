# 03 — Architektur

## High-Level

```
┌──────────────────────────────────────────────────────────────────┐
│                       Browser / PWA Client                       │
│  Blazor WASM   ServiceWorker   IndexedDB   WebBluetooth/HID JS   │
└─────────────┬─────────────────────────────────────┬──────────────┘
              │ HTTPS REST (typed clients)          │ WebSocket (SignalR)
              ▼                                     ▼
┌──────────────────────────────────────────────────────────────────┐
│                     Sheetstorm.Api (ASP.NET)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐    │
│  │ Identity     │  │ Domain APIs  │  │ Realtime (SignalR)   │    │
│  │ /signin /me  │  │ /pieces /... │  │ ConductorHub         │    │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘    │
│         │                 │                     │                 │
│         ▼                 ▼                     ▼                 │
│   Application Services (CQRS-light: Commands & Queries)          │
│         │                 │                     │                 │
│         ▼                 ▼                     ▼                 │
│   Domain Model (Entities, Value Objects, Domain Events)          │
└─────┬──────────────┬───────────────┬─────────────────┬───────────┘
      │              │               │                 │
      ▼              ▼               ▼                 ▼
┌──────────┐  ┌─────────────┐  ┌──────────┐     ┌─────────────┐
│ Postgres │  │ Hangfire JQ │  │ S3/MinIO │     │ Audiveris   │
│ (EF Core)│  │ (Postgres)  │  │ (Blobs)  │     │ Sidecar     │
└──────────┘  └─────────────┘  └──────────┘     └─────────────┘
```

## Solution-Layout

```
Sheetstorm.slnx
├── apphost/
│   ├── Sheetstorm.AppHost                  Aspire 13.2
│   └── Sheetstorm.ServiceDefaults
├── src/
│   ├── Sheetstorm.Domain                   Entities, VOs, Events
│   ├── Sheetstorm.Application              Use-Cases, DTOs, Validators
│   ├── Sheetstorm.Infrastructure           EF, Storage, Mail, Audiveris
│   ├── Sheetstorm.Api                      ASP.NET Core hostable
│   └── Sheetstorm.Web                      Blazor WASM Client + Server
├── tests/
│   ├── Sheetstorm.Domain.Tests
│   ├── Sheetstorm.Application.Tests
│   ├── Sheetstorm.Api.Tests                Integration + Testcontainers
│   └── Sheetstorm.Web.Tests                bUnit
└── e2e/
    ├── package.json
    ├── playwright.config.ts
    └── specs/                               Playwright tests in TS
```

## Schicht-Konventionen

* **Domain**: Pure C#, keine EF/ASP.NET-Abhängigkeit. Entities
  schützen Invarianten in Konstruktoren / Methoden.
* **Application**: Orchestriert Use-Cases. Definiert Interfaces
  für Infrastruktur (Repository, FileStore, AudiverisGateway).
  CQRS-light: separate Command-Handler und Query-Handler, kein
  MediatR-Zwang — direkter DI-Aufruf.
* **Infrastructure**: Implementiert Application-Interfaces, EF
  DbContext, Repositories, externe Adapter.
* **Api**: Endpoints (Minimal API) gruppiert per Feature, dünner
  Wrapper um Application-Calls. Auth-Policies, Rate-Limit.
* **Web**: Blazor WASM (Client + Server-Hosting für Auth-Cookies +
  Statische Files).

Strikte Abhängigkeitsrichtung: `Web → Api ← Application → Domain`,
`Infrastructure → Application + Domain`, `Api → Infrastructure`.

## API-Stil

* REST mit Versionierung in URL: `/api/v1/...`
* Resource-orientiert: `/pieces`, `/pieces/{id}/parts`, `/bands`,
  `/bands/{id}/members`, `/events`, `/sets`.
* Pagination: Cursor-basiert (Base64-JSON-Cursor, Default 20, Max
  100).
* Filter: Query-Params, dokumentiert via OpenAPI.
* Errors: `application/problem+json` (RFC 7807) mit konsistenten
  Codes (`VALIDATION`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`,
  `INTERNAL`).

## Auth-Flow

1. **Web**: Cookie-Auth (HttpOnly, SameSite=Lax, Secure). Login-Form
   POST `/auth/login` → setzt Cookie → Blazor-WASM lädt mit Cookie.
2. **Mobile/CLI/Native (Phase 2)**: Bearer-JWT, ausgegeben via
   `/auth/token` mit Refresh-Token-Rotation.
3. **Multi-Verein**: Active Verein in Cookie/Claim oder
   `X-Band-Id`-Header. Authorization-Policy prüft Membership +
   Rolle.

## Autorisierungs-Modell

```
[Authorize(Policy = "BandMember")]
[Authorize(Policy = "BandRole:Conductor,Admin,Owner")]
```

Policy-Handler liest `bandId` aus Route, prüft `Membership` + Rolle
gegen DB. Performance: Per-Request-Cache, optional Memory-Cache mit
Eviction bei Membership-Änderung (Domain-Event).

## Datenflüsse — Beispiele

### Werk hochladen
1. POST `/pieces` mit Metadaten → `pieceId`.
2. POST `/pieces/{id}/files` (multipart) → S3-Upload, `fileId`.
3. POST `/pieces/{id}/omr-jobs` → Hangfire-Job queued.
4. Hangfire-Worker ruft Audiveris-Sidecar, bekommt MusicXML +
   erkannte Stimmen, schreibt DB.
5. SignalR-Notification an Uploader: „Bereit zur Review".
6. UI zeigt Vorschau, User bestätigt Stimm-Zuordnung →
   PUT `/pieces/{id}/parts`.

### Conductor-Sync (Web Bluetooth Pfad)
1. Dirigent: POST `/events/{id}/sync-session` → Server gibt
   Event-Schlüsselpaar zurück (siehe Spec 05) und markiert Event als
   live.
2. Mitglieder pollen `/events/{id}/sync-session` (oder SignalR-Push)
   → bekommen Public Key.
3. Dirigent öffnet Stück → JS sendet BLE-Advertisement
   `{eventId, pieceId, ts, sig}` jede 500ms.
4. Musiker-Browser empfängt via Web Bluetooth Scanning → prüft
   Signatur → zeigt Pop-up.

### Conductor-Sync (Fallback iOS)
1–2 wie oben.
3. Dirigent öffnet Stück → POST `/events/{id}/now-playing`.
4. Server pusht via SignalR `nowPlayingChanged` an alle Mitglieder
   im Event-Group.
5. Musiker-UI zeigt Pop-up.

## Datenbank-Migrations
* EF Core Migrations, Auto-Apply nur in Dev.
* Prod: explizit via Aspire-Manifest-Hook oder `dotnet ef database
  update` im Deploy.
* Seed-Daten (Stimm-Taxonomie, Demo-Verein) via separates
  `Sheetstorm.Seed`-Tool.

## Beobachtbarkeit
* OpenTelemetry → Aspire Dashboard (lokal), OTLP-Endpoint für Prod
  (Grafana/Tempo/Loki oder Azure Monitor — Wahl bei Deployment).
* Strukturierte Logs in JSON, Correlation-IDs propagiert über
  HTTP + SignalR + Hangfire-Job-Context.

## Sicherheit (Querschnitt)
* TLS überall (Aspire generiert Dev-Zertifikate).
* CSP striktes Default für Web; Inline-Scripts nur über Nonces.
* Rate-Limit pro IP+User auf Auth-Endpoints.
* DSGVO: Daten­export pro Nutzer, Löschauftrag mit Verifizierung.
* Audit-Log für Admin-Aktionen (Mitglied entfernt, Rolle geändert,
  Werk gelöscht).
