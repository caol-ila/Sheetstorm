# Sheetstorm

> Noten- & Vereinsverwaltung für Blaskapellen — Web, Desktop, Mobile.

## Status

**Foundation Phase** — Rahmenanwendung und DevLoop sind aufgebaut, Features folgen.

## Tech-Stack

- **Backend:** ASP.NET Core 10 + EF Core + PostgreSQL
- **Orchestrierung:** .NET Aspire 9
- **Frontend:** Flutter 3.x (Android, iOS, Windows, Web)
- **i18n:** ARB (Deutsch default, Englisch zweite)
- **E2E:** Playwright (TypeScript)
- **CI:** GitHub Actions (Ubuntu + Windows Matrix)

## Repo-Struktur

```
Sheetstorm/
├── src/                          # Backend (ASP.NET Core)
│   ├── Sheetstorm.Api/           # REST API, Controller, Middleware
│   ├── Sheetstorm.Domain/        # Entities, Interfaces, Value Objects
│   ├── Sheetstorm.Infrastructure/# EF Core, Repositories, externe Services
│   ├── Sheetstorm.AppHost/       # Aspire Orchestrator
│   └── Sheetstorm.ServiceDefaults/# Shared Aspire-Konfiguration
├── sheetstorm_app/               # Frontend (Flutter/Dart)
│   ├── lib/
│   │   ├── core/                 # Routing, Config, Themes
│   │   ├── features/             # Feature-Module (Auth, Noten, Kapelle...)
│   │   ├── shared/               # Geteilte Widgets, Services, Models
│   │   └── l10n/                 # ARB-Dateien (i18n)
│   ├── test/                     # Flutter Tests
│   └── e2e/                      # Playwright E2E-Tests
├── tests/                        # Backend Tests (xUnit)
│   ├── Sheetstorm.Api.Tests/
│   ├── Sheetstorm.Domain.Tests/
│   └── Sheetstorm.Infrastructure.Tests/
├── docs/
│   ├── specs/                    # Framework-Spec, Foundation-Plan
│   └── operations/               # DevLoop-Guides
├── .github/
│   └── workflows/                # CI/CD
└── .squad/                       # AI-Team Setup (Squad Framework)
```

## DevLoop (Quickstart)

### Voraussetzungen

- **.NET 10 SDK** (oder .NET 9, falls 10 noch nicht verfügbar)
- **Flutter 3.5+ SDK**
- **Docker Desktop** (für Testcontainers)
- **Node.js 20+** (für Playwright)
- **PowerShell 7+**
- **.NET Aspire Workload** (optional, für AppHost): `dotnet workload install aspire`

### Backend starten

```powershell
Set-Location src\Sheetstorm.AppHost
dotnet run
```

Aspire-Dashboard verfügbar auf `https://localhost:17001`  
API erreichbar auf `https://localhost:7001/api/v1/ping`

### Flutter Web starten

```powershell
Set-Location sheetstorm_app
flutter run -d chrome --web-port 8080 `
  --dart-define=API_BASE_URL=https://localhost:7001
```

### Tests ausführen

**Backend:**
```powershell
dotnet test Sheetstorm.sln
```

**Flutter:**
```powershell
Set-Location sheetstorm_app
flutter test
```

**E2E (Playwright):**
```powershell
Set-Location sheetstorm_app
npm run test:e2e
```
*(Voraussetzung: Backend + Flutter Web müssen laufen)*

## Erste Schritte

Detaillierte Anleitung für neue Contributors: **[docs/operations/devloop.md](docs/operations/devloop.md)**

## Referenzen

- **Framework-Spec:** `docs/specs/00-framework-and-process.md`
- **Foundation-Plan:** `docs/specs/app-foundation-plan.md`
- **DevLoop-Guide:** `docs/operations/devloop.md`
- **Markt-Analyse:** Branch `docs/market-analysis` (separate Dokumentation)

## Mitwirken

- **Conventional Commits** + Issue-Ref + Co-authored-by Trailer
- **TDD für Geschäftslogik** — kein Produktionscode ohne Test
- **Alle User-Strings via i18n** (ARB-Dateien in `sheetstorm_app/lib/l10n/`)
- **Accessibility-Smoke-Checks** (Semantics-Tests in Flutter)
- **Branch-per-Feature**, Worktrees für Parallelarbeit (siehe `.squad/`)

## Lizenz

Proprietär — Privates Projekt.
