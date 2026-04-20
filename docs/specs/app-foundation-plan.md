# Sheetstorm App Foundation — File Structure Plan

> **Issue:** #126  
> **Scope:** Rahmenanwendung-Skelett (Backend 3-Schichten, Aspire, Flutter, E2E, CI)  
> **Phase:** Foundation Session — vor jeglichem Feature-Code  
> **Basiert auf:** Framework-Spec (Branch `docs/framework-and-process-spec`)

---

## 1. Übersicht

Diese Datei ist der **File-Structure-Mapping**-Plan für die gesamte Foundation-Session. Sie dokumentiert **alle** Dateien, die erstellt, modifiziert oder gelöscht werden, sowie deren Abhängigkeiten und Reihenfolge.

**Ziel:** Skeleton-App ohne Geschäftslogik, aber mit allen Architektur-Ebenen, Tools und Patterns, die laut Framework-Spec verbindlich sind.

**Abhängigkeiten:**
- Framework-Spec §3 (Tech-Stack)
- Framework-Spec §4 (Qualität: responsive, a11y, i18n)
- Framework-Spec §5 (Test-Strategie)
- Framework-Spec §7 (CI/CD, Worktrees)
- Copilot-Instructions (TDD, 3-Schichten, E2E)

---

## 2. File-Structure-Map

### 2.1 Backend (ASP.NET Core + Aspire)

#### CREATE

**Aspire AppHost & ServiceDefaults:**

- `src/Sheetstorm.AppHost/Sheetstorm.AppHost.csproj`  
  **Zweck:** Aspire-Orchestrator (Backend, Postgres, Flutter-Web als Resource)  
  **Abhängigkeiten:** .NET Aspire SDK, Verweis auf Api & ServiceDefaults  
  **Anmerkungen:** Postgres als Container-Resource (`AddPostgres()`), Flutter-Web als Executable-Resource (Platzhalter)

- `src/Sheetstorm.AppHost/Program.cs`  
  **Zweck:** Aspire-Konfiguration — Ressourcen deklarieren, Service-Discovery  
  **Abhängigkeiten:** Sheetstorm.Api, PostgreSQL-Container-Image

- `src/Sheetstorm.AppHost/appsettings.json`  
  **Zweck:** Aspire-spezifische Konfiguration (Postgres-Credentials, Ressourcen-Ports)  
  **Abhängigkeiten:** Keine

- `src/Sheetstorm.ServiceDefaults/Sheetstorm.ServiceDefaults.csproj`  
  **Zweck:** Shared defaults für alle .NET-Projekte (OpenTelemetry, Health-Checks, Resilience)  
  **Abhängigkeiten:** Aspire.Hosting, Polly, OpenTelemetry-Packages

- `src/Sheetstorm.ServiceDefaults/Extensions.cs`  
  **Zweck:** IHostApplicationBuilder-Extension für ServiceDefaults  
  **Abhängigkeiten:** Microsoft.Extensions.DependencyInjection

**Api-Schicht:**

- `src/Sheetstorm.Api/Sheetstorm.Api.csproj`  
  **Zweck:** ASP.NET Core Web API (Controller, Middleware, OpenAPI)  
  **Abhängigkeiten:** Sheetstorm.Domain, Sheetstorm.Infrastructure, Sheetstorm.ServiceDefaults, Npgsql.EntityFrameworkCore.PostgreSQL, Swashbuckle.AspNetCore

- `src/Sheetstorm.Api/Program.cs`  
  **Zweck:** Entry Point, DI-Setup, Middleware-Pipeline, ServiceDefaults  
  **Abhängigkeiten:** Domain, Infrastructure, ServiceDefaults

- `src/Sheetstorm.Api/appsettings.json`  
  **Zweck:** App-Konfiguration (Logging, DB-Connection-String-Placeholder)  
  **Abhängigkeiten:** Keine

- `src/Sheetstorm.Api/appsettings.Development.json`  
  **Zweck:** Dev-Override (Hot-Reload, detailliertes Logging)  
  **Abhängigkeiten:** Keine

- `src/Sheetstorm.Api/Controllers/PingController.cs`  
  **Zweck:** Minimal-Controller für /ping-Endpoint (Smoke-Test)  
  **Abhängigkeiten:** Keine (kein Domain-Code, nur `{"message": "Hallo Blaskapelle"}`)

- `src/Sheetstorm.Api/Controllers/ApiControllerBase.cs`  
  **Zweck:** Basis-Klasse für alle Controller (gemeinsame Attribute, Route-Präfix `/api/v1`)  
  **Abhängigkeiten:** Keine

**Domain-Schicht:**

- `src/Sheetstorm.Domain/Sheetstorm.Domain.csproj`  
  **Zweck:** Core Business Logic, Entities, Interfaces (keine Infrastruktur-Abhängigkeiten)  
  **Abhängigkeiten:** Keine (außer Standard-Libraries)

- `src/Sheetstorm.Domain/Common/Entity.cs`  
  **Zweck:** Basis-Klasse für Entities (Id, CreatedAt, UpdatedAt)  
  **Abhängigkeiten:** Keine

- `src/Sheetstorm.Domain/Common/IRepository.cs`  
  **Zweck:** Generisches Repository-Interface  
  **Abhängigkeiten:** Keine

**Infrastructure-Schicht:**

- `src/Sheetstorm.Infrastructure/Sheetstorm.Infrastructure.csproj`  
  **Zweck:** EF Core, Repositories, externe Services  
  **Abhängigkeiten:** Sheetstorm.Domain, EF Core, Npgsql.EntityFrameworkCore.PostgreSQL

- `src/Sheetstorm.Infrastructure/Data/ApplicationDbContext.cs`  
  **Zweck:** EF Core DbContext (leer im Skeleton, Basis für künftige Entities)  
  **Abhängigkeiten:** Domain.Common.Entity

- `src/Sheetstorm.Infrastructure/Data/Configurations/.gitkeep`  
  **Zweck:** Platzhalter für künftige Entity-Konfigurationen  
  **Abhängigkeiten:** Keine

- `src/Sheetstorm.Infrastructure/Repositories/Repository.cs`  
  **Zweck:** Generische Repository-Implementierung (IRepository<T>)  
  **Abhängigkeiten:** Domain.Common, ApplicationDbContext

#### MODIFY

Keine — alle Backend-Dateien sind neu.

#### DELETE

Keine.

---

### 2.2 Backend Tests

#### CREATE

**Unit-Tests:**

- `tests/Sheetstorm.Domain.Tests/Sheetstorm.Domain.Tests.csproj`  
  **Zweck:** Unit-Tests für Domain-Logik  
  **Abhängigkeiten:** xUnit, FluentAssertions, Sheetstorm.Domain

- `tests/Sheetstorm.Domain.Tests/Common/EntityTests.cs`  
  **Zweck:** Test für Entity-Basisklasse (Smoke-Test)  
  **Abhängigkeiten:** Keine

**Integration-Tests:**

- `tests/Sheetstorm.Api.Tests/Sheetstorm.Api.Tests.csproj`  
  **Zweck:** Integration-Tests für Api-Layer (WebApplicationFactory, Testcontainers)  
  **Abhängigkeiten:** xUnit, FluentAssertions, Testcontainers.PostgreSql, Microsoft.AspNetCore.Mvc.Testing, Sheetstorm.Api

- `tests/Sheetstorm.Api.Tests/PingControllerTests.cs`  
  **Zweck:** Integration-Test für /ping-Endpoint  
  **Abhängigkeiten:** Testcontainers, WebApplicationFactory

- `tests/Sheetstorm.Api.Tests/TestWebApplicationFactory.cs`  
  **Zweck:** Custom WebApplicationFactory mit Testcontainers-Postgres  
  **Abhängigkeiten:** Testcontainers.PostgreSql

- `tests/Sheetstorm.Api.Tests/appsettings.Testing.json`  
  **Zweck:** Test-Konfiguration (In-Memory-Overrides)  
  **Abhängigkeiten:** Keine

#### MODIFY

Keine.

#### DELETE

Keine.

---

### 2.3 Flutter App

#### CREATE

**Projekt-Scaffold:**

- `sheetstorm_app/pubspec.yaml`  
  **Zweck:** Flutter-Dependencies (Riverpod, GoRouter, Drift, Intl, FlutterLocalizations)  
  **Abhängigkeiten:** `flutter create` Basis, dann Dependencies ergänzen

- `sheetstorm_app/lib/main.dart`  
  **Zweck:** Entry Point mit ProviderScope, Localization, GoRouter  
  **Abhängigkeiten:** Riverpod, GoRouter, i18n

- `sheetstorm_app/lib/core/router/app_router.dart`  
  **Zweck:** GoRouter-Konfiguration (Root-Route `/` → HomeScreen)  
  **Abhängigkeiten:** GoRouter, home screen

- `sheetstorm_app/lib/core/theme/app_theme.dart`  
  **Zweck:** Material 3 Theme (Light + Dark Mode)  
  **Abhängigkeiten:** Material 3

- `sheetstorm_app/lib/core/i18n/l10n.dart`  
  **Zweck:** Localization-Setup (generiert aus ARB)  
  **Abhängigkeiten:** flutter_localizations, intl

- `sheetstorm_app/lib/l10n/app_de.arb`  
  **Zweck:** Deutsch (de-DE) Strings (Primärsprache)  
  **Abhängigkeiten:** Keine

- `sheetstorm_app/lib/l10n/app_en.arb`  
  **Zweck:** Englisch (en) Strings (Platzhalter)  
  **Abhängigkeiten:** Keine

**Home Feature (Minimal):**

- `sheetstorm_app/lib/features/home/presentation/screens/home_screen.dart`  
  **Zweck:** Home-Screen mit i18n-String + /ping-Anzeige  
  **Abhängigkeiten:** Riverpod, i18n, ping_provider

- `sheetstorm_app/lib/features/home/presentation/providers/ping_provider.dart`  
  **Zweck:** Riverpod Provider für /ping-Aufruf  
  **Abhängigkeiten:** Riverpod, http

**Shared/Core:**

- `sheetstorm_app/lib/shared/services/api_client.dart`  
  **Zweck:** HTTP-Client-Wrapper (Basis für API-Calls)  
  **Abhängigkeiten:** http, flutter_dotenv (für BASE_URL)

- `sheetstorm_app/lib/shared/widgets/responsive_layout.dart`  
  **Zweck:** Responsive Layout Builder (Phone/Tablet/Desktop Breakpoints)  
  **Abhängigkeiten:** Material, LayoutBuilder

**Konfiguration:**

- `sheetstorm_app/.env.example`  
  **Zweck:** Environment-Variablen-Template (API_BASE_URL)  
  **Abhängigkeiten:** Keine

- `sheetstorm_app/analysis_options.yaml`  
  **Zweck:** Linter-Regeln (strict mode)  
  **Abhängigkeiten:** Keine

- `sheetstorm_app/l10n.yaml`  
  **Zweck:** Flutter-Localization-Konfiguration  
  **Abhängigkeiten:** Keine

#### MODIFY

Keine — flutter create erzeugt Basis, wir überschreiben relevante Dateien.

#### DELETE

- `sheetstorm_app/lib/main.dart` (original von flutter create)
- `sheetstorm_app/test/widget_test.dart` (Platzhalter)

---

### 2.4 Flutter Tests

#### CREATE

- `sheetstorm_app/test/features/home/presentation/screens/home_screen_test.dart`  
  **Zweck:** Widget-Test für HomeScreen (i18n + Semantics-Check)  
  **Abhängigkeiten:** flutter_test, home_screen

- `sheetstorm_app/test/shared/widgets/responsive_layout_test.dart`  
  **Zweck:** Widget-Test für ResponsiveLayout (Breakpoint-Logic)  
  **Abhängigkeiten:** flutter_test, responsive_layout

#### MODIFY

Keine.

#### DELETE

- `sheetstorm_app/test/widget_test.dart` (flutter create Platzhalter)

---

### 2.5 E2E Tests (Playwright)

#### CREATE

- `sheetstorm_app/playwright.config.ts`  
  **Zweck:** Playwright-Konfiguration (Base URL, Browser, Timeouts)  
  **Abhängigkeiten:** @playwright/test

- `sheetstorm_app/package.json`  
  **Zweck:** npm-Scripts für Playwright (test:e2e, test:e2e:ui)  
  **Abhängigkeiten:** @playwright/test

- `sheetstorm_app/e2e/ping.spec.ts`  
  **Zweck:** E2E-Test: Flutter-Web lädt, /ping-Antwort wird angezeigt  
  **Abhängigkeiten:** playwright.config.ts, laufender Aspire-Stack

- `sheetstorm_app/e2e/README.md`  
  **Zweck:** E2E-Doku (Setup, Ausführung, Voraussetzungen)  
  **Abhängigkeiten:** Keine

#### MODIFY

Keine.

#### DELETE

Keine.

---

### 2.6 CI/CD (GitHub Actions)

#### CREATE

- `.github/workflows/backend.yml`  
  **Zweck:** Backend CI (dotnet restore, build, test auf Ubuntu + Windows)  
  **Abhängigkeiten:** .NET SDK, Testcontainers (Linux)

- `.github/workflows/flutter.yml`  
  **Zweck:** Flutter CI (analyze, test auf Ubuntu)  
  **Abhängigkeiten:** Flutter SDK

- `.github/workflows/e2e.yml`  
  **Zweck:** E2E CI (Aspire + Flutter Web + Playwright, Ubuntu)  
  **Abhängigkeiten:** .NET SDK, Flutter SDK, Node.js, Playwright

- `.github/workflows/multi-model-review.yml`  
  **Zweck:** Stub für Multi-Model-Review (Opus/Sonnet/GPT) — TODO: Implementation  
  **Abhängigkeiten:** Keine (Stub mit Kommentar)

#### MODIFY

Keine.

#### DELETE

Keine.

---

### 2.7 Dokumentation

#### CREATE

- `README.md` (Root)  
  **Zweck:** Projekt-Übersicht, Quick-Start, Plattformen, Lizenz  
  **Abhängigkeiten:** Keine

- `sheetstorm_app/README.md`  
  **Zweck:** Flutter-App-Doku (Setup, DevLoop, Tests)  
  **Abhängigkeiten:** Keine

- `docs/operations/devloop.md`  
  **Zweck:** DevLoop-Anleitung (aspire run, Hot-Reload, Tests lokal)  
  **Abhängigkeiten:** Aspire, Flutter

- `docs/operations/testing.md`  
  **Zweck:** Testing-Guide (Unit, Integration, E2E, TDD-Workflow)  
  **Abhängigkeiten:** Framework-Spec §5

#### MODIFY

Keine.

#### DELETE

Keine.

---

### 2.8 Verschiedenes

#### CREATE

- `src/Directory.Build.props`  
  **Zweck:** Gemeinsame .csproj-Properties für alle Backend-Projekte (C# 13, Nullable, TreatWarningsAsErrors)  
  **Abhängigkeiten:** Keine

- `src/Directory.Packages.props`  
  **Zweck:** Central Package Management (alle NuGet-Versionen zentral)  
  **Abhängigkeiten:** Keine

- `.editorconfig` (erweitert)  
  **Zweck:** C#- und Dart-Linting-Regeln  
  **Abhängigkeiten:** Keine

- `.gitignore` (erweitert)  
  **Zweck:** Build-Artefakte, Flutter-Build-Outputs, node_modules  
  **Abhängigkeiten:** Keine

#### MODIFY

- `.editorconfig` (falls vorhanden — Regeln für C# und Dart ergänzen)
- `.gitignore` (falls vorhanden — Flutter- und Aspire-Artefakte ergänzen)

#### DELETE

Keine.

---

## 3. Dependency-Reihenfolge (für Implementation-Agents)

Die Implementierung **MUSS** in folgender Reihenfolge erfolgen, da Dependencies bestehen:

### Phase 1: Backend-Grundlagen

1. `src/Directory.Build.props`, `src/Directory.Packages.props` (definieren Package-Versionen)
2. `src/Sheetstorm.Domain/` (keine Abhängigkeiten)
3. `src/Sheetstorm.Infrastructure/` (abhängig von Domain)
4. `src/Sheetstorm.Api/` (abhängig von Domain, Infrastructure)
5. `src/Sheetstorm.ServiceDefaults/` (unabhängig)
6. `src/Sheetstorm.AppHost/` (abhängig von Api, ServiceDefaults)

### Phase 2: Backend-Tests

7. `tests/Sheetstorm.Domain.Tests/` (abhängig von Domain)
8. `tests/Sheetstorm.Api.Tests/` (abhängig von Api, Testcontainers)

### Phase 3: Flutter-App

9. `flutter create sheetstorm_app` (Basis-Scaffold)
10. `sheetstorm_app/pubspec.yaml` (Dependencies definieren)
11. `sheetstorm_app/lib/core/` (Theme, Router, i18n)
12. `sheetstorm_app/lib/l10n/` (ARB-Dateien)
13. `sheetstorm_app/lib/shared/` (API-Client, Widgets)
14. `sheetstorm_app/lib/features/home/` (abhängig von shared)

### Phase 4: Flutter-Tests

15. `sheetstorm_app/test/` (abhängig von lib/)

### Phase 5: E2E

16. `sheetstorm_app/package.json`, `playwright.config.ts` (npm-Setup)
17. `sheetstorm_app/e2e/` (abhängig von playwright.config)

### Phase 6: CI

18. `.github/workflows/` (alle 4 Workflows parallel möglich)

### Phase 7: Docs

19. `README.md`, `sheetstorm_app/README.md`, `docs/operations/` (parallel möglich)

---

## 4. Offene Entscheidungen (zu klären vor Implementation)

### 4.1 Postgres-Version

- **Frage:** Welche Postgres-Image-Version für Aspire-Container?  
- **Optionen:** `postgres:16-alpine` (neueste LTS), `postgres:15-alpine` (konservativ)  
- **Empfehlung:** `postgres:16-alpine` (laut Framework-Spec §3.2: "PostgreSQL")  
- **Entscheidung:** Agent Rogers (Backend) entscheidet in ADR oder schlägt vor.

### 4.2 Flutter-SDK-Pfad für Aspire

- **Frage:** Wie integriert Aspire die Flutter-Web-Ausführung?  
- **Optionen:**  
  - `AddExecutable()` mit manuellem Pfad zu `flutter`  
  - Separater Container mit Flutter-Web-Build  
  - Platzhalter-Kommentar in Phase 1, Implementierung später  
- **Empfehlung:** Platzhalter-Kommentar in `AppHost/Program.cs` — Runtime-Integration ist nicht Teil der Foundation-Akzeptanzkriterien (nur Build muss grün sein).  
- **Entscheidung:** Agent Rogers kann als TODO-Kommentar lassen.

### 4.3 Drift-Schema

- **Frage:** Soll bereits ein Drift-Schema-File (z.B. `database.drift`) als Platzhalter existieren?  
- **Optionen:** Ja (leere Datei), Nein (erst bei erstem Feature)  
- **Empfehlung:** **Nein** — Drift kommt erst mit echten Offline-Daten (Feature-Scope).  
- **Entscheidung:** Kein Drift-Code in Foundation, nur pubspec.yaml-Dependency.

### 4.4 OpenAPI-Export

- **Frage:** Soll die CI bereits OpenAPI-JSON exportieren und committen?  
- **Optionen:** Ja (vollautomatisch), Nein (erst bei erstem Feature)  
- **Empfehlung:** **Nein** — OpenAPI-Export ist Teil der CI-Infrastruktur, aber kein Akzeptanzkriterium für Foundation.  
- **Entscheidung:** Stub in CI-Workflow als Kommentar, keine Implementation.

---

## 5. Hinweise für Implementation-Agents

### Für Rogers (Backend)

- **Aspire:** Achte darauf, dass `aspire run` lokal funktioniert — Postgres muss starten, Api muss sich verbinden.
- **EF Migrations:** Erstelle **keine** Migrations in Foundation — ApplicationDbContext ist leer (außer Setup-Code).
- **Testcontainers:** `Testcontainers.PostgreSql` braucht Docker lokal — CI muss Ubuntu nutzen (Windows-Runner haben kein Docker).
- **PingController:** Return `{"message": "Hallo Blaskapelle"}` — kein Domain-Code.
- **TDD:** Der Integration-Test für /ping **MUSS** vor dem Controller geschrieben werden.

### Für Parker (Flutter)

- **flutter create:** Führe aus, lösche dann `lib/main.dart` und `test/widget_test.dart`.
- **i18n:** `flutter gen-l10n` generiert Code aus ARB — rufe nach ARB-Änderungen auf.
- **Responsive:** `ResponsiveLayout` nutzt Breakpoints: Phone < 600 dp, Tablet 600–1200 dp, Desktop ≥ 1200 dp.
- **Semantics:** **Jeder** Widget-Test braucht mind. einen `matchesSemantics()`-Check (Framework-Spec §4.2).
- **API-Call:** PingProvider ruft `/api/v1/ping` auf — BASE_URL aus `.env` (via flutter_dotenv).
- **TDD:** Widget-Test für HomeScreen **vor** HomeScreen-Code.

### Für Romanoff (E2E)

- **Playwright:** `npm install` in `sheetstorm_app/` vor `npx playwright install`.
- **Voraussetzungen:** Aspire + Flutter Web müssen laufen — dokumentiere in `e2e/README.md`.
- **CanvasKit:** Flutter-Web rendert mit CanvasKit — Text-Matching via `getByText()` funktioniert **nicht** direkt. Nutze `getByRole()` oder Screenshots.
- **Test-Scope:** Nur **ein** Test: "Flutter lädt, Ping-Antwort ist sichtbar" — kein weiterer E2E-Code.

### Für Alle

- **Keine Features:** Keine Band-Verwaltung, keine Noten-Logik, keine Auth-Flows — nur Skelett.
- **TDD:** RED → VERIFY RED → GREEN → VERIFY GREEN → REFACTOR.
- **Commits:** Conventional Commits (`feat:`, `test:`, `chore:`) + Issue-Ref (`#126`).
- **Verifikation:** `dotnet build`, `dotnet test`, `flutter analyze`, `flutter test` **MÜSSEN** grün sein am Ende.

---

## 6. Akzeptanzkriterien (für Stark's Abschluss-Verifikation)

Am Ende der Foundation-Session **MÜSSEN** folgende Befehle grün sein:

```powershell
# Backend
cd C:\Privat\Sheetstorm-worktrees\feat-app-scaffold
dotnet build src/Sheetstorm.sln        # 0 Errors, 0 Warnings
dotnet test src/Sheetstorm.sln         # All tests pass

# Flutter
cd sheetstorm_app
flutter analyze                        # No issues found
flutter test                           # All tests pass (inkl. Semantics)

# Aspire (Build-Check, kein Run)
cd C:\Privat\Sheetstorm-worktrees\feat-app-scaffold\src\Sheetstorm.AppHost
dotnet build                           # 0 Errors

# E2E (Config-Check, kein Run)
cd C:\Privat\Sheetstorm-worktrees\feat-app-scaffold\sheetstorm_app
npx playwright test --list            # Zeigt ping.spec.ts

# CI (Syntax-Check)
cd C:\Privat\Sheetstorm-worktrees\feat-app-scaffold
# GitHub Actions YAML-Syntax-Check via actionlint oder gh CLI
```

Zusätzlich:

- **Manual-Check:** `/ping` liefert `{"message": "Hallo Blaskapelle"}` (Browser oder curl)
- **Manual-Check:** Flutter-Home zeigt i18n-String + Ping-Antwort (DevTools oder Screenshot)

---

## 7. Risiken & Mitigations

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| Testcontainers scheitert in CI | Mittel | Hoch | Ubuntu-Runner, Docker vorinstalliert |
| Flutter gen-l10n Encoding-Fehler | Niedrig | Mittel | UTF-8 BOM in ARB vermeiden |
| Aspire-Run schlägt lokal fehl | Mittel | Mittel | Nur Build-Check, kein Run-Test als Akzeptanzkriterium |
| Playwright auf CanvasKit findet Text nicht | Hoch | Niedrig | getByRole() statt getByText() |
| .NET 10 SDK-Version mismatch | Niedrig | Hoch | global.json mit SDK-Version festlegen |

---

## 8. Referenzen

- **Framework-Spec:** `git show docs/framework-and-process-spec:docs/specs/00-framework-and-process.md`
- **Copilot-Instructions:** `.github/copilot-instructions.md` (TDD, 3-Schichten, E2E)
- **Issue:** [#126](https://github.com/caol-ila/Sheetstorm/issues/126)
- **Worktree:** `C:\Privat\Sheetstorm-worktrees\feat-app-scaffold`
- **Branch:** `feat/app-scaffold` (off `main`)

---

**Nächste Schritte:**

1. Rogers (Backend) liest diesen Plan und implementiert Phase 1+2 (#126)
2. Parker (Flutter) implementiert Phase 3+4 (#126)
3. Romanoff (E2E) implementiert Phase 5 (#126)
4. Stark führt Abschluss-Verifikation durch, erstellt PR
