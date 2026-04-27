# Sheetstorm

Notenmanagement-Plattform für Blasmusikvereine.

Vollständige Spezifikation in [`docs/`](./docs):

* [00 — Vision & Marktanalyse](docs/00-vision-and-market-analysis.md)
* [01 — Funktionale Spezifikation](docs/01-functional-spec.md)
* [02 — Tech Stack](docs/02-tech-stack.md)
* [03 — Architektur](docs/03-architecture.md)
* [04 — Datenmodell](docs/04-data-model.md)
* [05 — Conductor-Sync-Protokoll](docs/05-conductor-sync-protocol.md)
* [06 — Roadmap](docs/06-roadmap.md)

## Status

**Iteration 0 — Foundation** ✅
Aspire-13.2-Stack mit ASP.NET Core API + Blazor Web + PostgreSQL
ist gescaffoldet. Smoke-Tests grün.

Nächste Iteration: **1 — Identität & Mitgliedschaft**.

## Voraussetzungen

* .NET 10 SDK
* Node.js 20+ (für Playwright-E2E)
* Docker Desktop (für vollen Aspire-Run mit PostgreSQL)
* `aspire` CLI 13.2+ (`dotnet tool install -g Aspire.Cli`)

## Entwicklungs-Loop

### Vollen Stack starten (mit Docker)

```pwsh
aspire run --project src/Sheetstorm.AppHost
```

Aspire-Dashboard öffnet sich automatisch mit Links zu Web,
API, PgAdmin, Logs, Traces.

### Web-Frontend allein starten (ohne Docker, für Smoke-Tests)

```pwsh
cd src/Sheetstorm.Web
dotnet run --launch-profile https
```

Dann: <https://localhost:7170>

### Build / Tests

```pwsh
dotnet build
dotnet test
```

### E2E-Tests

```pwsh
cd e2e
npm install
npx playwright install chromium
$env:E2E_WEB_URL = 'https://localhost:7170'   # oder URL aus Aspire-Dashboard
npx playwright test
```

## Projektstruktur

```
src/
  Sheetstorm.AppHost          Aspire-Orchestrierung
  Sheetstorm.ServiceDefaults  Aspire ServiceDefaults
  Sheetstorm.ApiService       ASP.NET Core Web API
  Sheetstorm.Web              Blazor Web Frontend
e2e/                          Playwright-E2E-Tests
docs/                         Spezifikationen
```
