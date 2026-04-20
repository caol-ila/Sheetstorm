# Sheetstorm — Projekt-Setup Spezifikation

> **Issue:** [#6 — Projekt-Setup: Projektstruktur & CI/CD spezifizieren](https://github.com/caol-ila/Sheetstorm/issues/6)  
> **Autor:** Stark (Lead / Architect)  
> **Datum:** 2026-03-28  
> **Status:** In Review  
> **Stack:** Flutter 3.41.5 (Dart 3.11.0) · ASP.NET Core 10 (.NET 10 LTS) · PostgreSQL 18.3 · GitHub Actions

---

## 1. Projektstruktur — Mono-Repo Layout

Das Sheetstorm-Repository ist als Mono-Repo organisiert. Alle Teilprojekte liegen im gleichen Repository; CI-Workflows können gezielt pro Verzeichnis ausgeführt werden.

```
Sheetstorm/
├── backend/                        # ASP.NET Core 10 Backend
│   ├── Sheetstorm.slnx             # .NET 10 XML Solution File
│   ├── src/
│   │   ├── Sheetstorm.Api/         # HTTP-Layer: Controller, Middleware, DI-Bootstrapping
│   │   ├── Sheetstorm.Domain/      # Domänenmodell: Entities, Value Objects, Interfaces
│   │   └── Sheetstorm.Infrastructure/ # EF Core, PostgreSQL, Blob Storage, SignalR Hubs
│   └── tests/
│       ├── Sheetstorm.UnitTests/   # xUnit-Unit-Tests (Domain + Application-Logic)
│       ├── Sheetstorm.IntegrationTests/ # Integration-Tests (EF Core + PostgreSQL, Testcontainers)
│       └── Sheetstorm.ApiTests/    # HTTP-Level API-Tests (WebApplicationFactory)
│
├── frontend/                       # Flutter App
│   ├── lib/
│   │   ├── core/                   # Shared Utilities, Extensions, Constants, i18n
│   │   ├── data/                   # Repositories, API-Clients, Drift-Schemas
│   │   ├── domain/                 # Entitäten, Use Cases, Riverpod Providers
│   │   └── ui/                     # Screens, Widgets, Themes
│   ├── test/                       # flutter_test Unit- & Widget-Tests
│   ├── integration_test/           # Flutter Integration-Tests (echtes Gerät / Emulator)
│   └── pubspec.yaml
│
├── docs/                           # Alle Projektdokumentationen
│   ├── feature-specs/              # Feature-Spezifikationen (diese Datei + weitere)
│   ├── spezifikation.md
│   ├── meilensteine.md
│   ├── technologie-entscheidung.md
│   ├── konfigurationskonzept.md
│   └── ...
│
├── .squad/                         # Squad-Dokumentation und Agent-Definitionen
│   ├── agents/                     # Agent-Charter + Histories
│   ├── decisions/                  # Inbox für neue Entscheidungen
│   ├── decisions.md                # Konsolidierte Team-Entscheidungen
│   └── log/                        # Session-Logs
│
├── scripts/                        # Hilfs-Skripte (Start, DB-Migrations, etc.)
├── .github/
│   └── workflows/                  # GitHub Actions Workflow-Definitionen
├── .editorconfig                   # Einheitliche Code-Formatierung (C# + Dart)
├── .gitignore
└── README.md
```

### Verzeichnis-Konventionen

| Verzeichnis | Zweck | Owner |
|------------|-------|-------|
| `backend/src/Sheetstorm.Api` | HTTP-Schicht, Controller, Middleware, DI | Banner |
| `backend/src/Sheetstorm.Domain` | Reine Domänenlogik, keine Infrastruktur-Abhängigkeiten | Banner / Stark |
| `backend/src/Sheetstorm.Infrastructure` | EF Core Migrations, DbContext, externe Services | Banner |
| `backend/tests/` | Alle .NET Tests — Unit, Integration, API | Parker |
| `frontend/lib/` | Flutter App — nach Feature-Slices organisiert | Romanoff |
| `frontend/test/` | Unit + Widget Tests | Parker |
| `frontend/integration_test/` | End-to-End Tests auf echtem Gerät | Parker |
| `docs/feature-specs/` | Pro-Issue Feature-Spezifikationen | Stark |

---

## 2. CI/CD Pipeline — GitHub Actions

### 2.1 Workflow-Übersicht

| Workflow-Datei | Trigger | Zweck |
|----------------|---------|-------|
| `ci-backend.yml` | PR + push to `main` | Build, Test, Coverage (.NET) |
| `ci-frontend.yml` | PR + push to `main` | Build, Test, Coverage (Flutter) |
| `lint.yml` | PR | Lint-Checks (Dart Analyze, dotnet format) |
| `deploy-dev.yml` | push to `main` | Deploy zu Dev-Environment (Azure) |

### 2.2 Backend CI — `.github/workflows/ci-backend.yml`

```yaml
name: Backend CI

on:
  pull_request:
    paths:
      - 'backend/**'
      - '.github/workflows/ci-backend.yml'
  push:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:18
        env:
          POSTGRES_DB: sheetstorm_test
          POSTGRES_USER: sheetstorm
          POSTGRES_PASSWORD: sheetstorm_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET 10
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'

      - name: Restore dependencies
        run: dotnet restore backend/Sheetstorm.slnx

      - name: Build
        run: dotnet build backend/Sheetstorm.slnx --no-restore --configuration Release

      - name: Run Unit Tests
        run: >
          dotnet test backend/tests/Sheetstorm.UnitTests
          --no-build --configuration Release
          --collect:"XPlat Code Coverage"
          --results-directory ./coverage

      - name: Run Integration Tests
        run: >
          dotnet test backend/tests/Sheetstorm.IntegrationTests
          --no-build --configuration Release
          --collect:"XPlat Code Coverage"
          --results-directory ./coverage
        env:
          ConnectionStrings__DefaultConnection: >
            Host=localhost;Database=sheetstorm_test;Username=sheetstorm;Password=sheetstorm_test

      - name: Check Coverage Threshold
        run: >
          dotnet tool install --global dotnet-coverage &&
          dotnet-coverage merge ./coverage/**/*.xml --output merged.xml --output-format xml &&
          dotnet tool install --global dotnet-reportgenerator-globaltool &&
          reportgenerator -reports:merged.xml -targetdir:coverage-report -reporttypes:TextSummary &&
          cat coverage-report/Summary.txt

      - name: Upload Coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./merged.xml
          flags: backend
```

### 2.3 Frontend CI — `.github/workflows/ci-frontend.yml`

```yaml
name: Frontend CI

on:
  pull_request:
    paths:
      - 'frontend/**'
      - '.github/workflows/ci-frontend.yml'
  push:
    branches: [main]
    paths:
      - 'frontend/**'

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter 3.41.5
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'
          channel: 'stable'
          cache: true

      - name: Get dependencies
        run: flutter pub get
        working-directory: frontend

      - name: Run Unit & Widget Tests
        run: >
          flutter test
          --coverage
          --reporter json
          > test-results.json
        working-directory: frontend

      - name: Check Coverage Threshold
        run: |
          COVERAGE=$(lcov --summary frontend/coverage/lcov.info 2>&1 | grep "lines......" | awk '{print $2}' | tr -d '%')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 70" | bc -l) )); then
            echo "❌ Coverage $COVERAGE% is below threshold of 70%"
            exit 1
          fi

      - name: Upload Coverage
        uses: codecov/codecov-action@v4
        with:
          files: frontend/coverage/lcov.info
          flags: frontend

      - name: Build Web (Smoke Test)
        run: flutter build web --release
        working-directory: frontend
```

### 2.4 Lint — `.github/workflows/lint.yml`

```yaml
name: Lint

on:
  pull_request:

jobs:
  dart-analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'
          channel: 'stable'
          cache: true
      - run: flutter pub get
        working-directory: frontend
      - name: Dart Analyze
        run: flutter analyze --fatal-infos
        working-directory: frontend
      - name: Dart Format Check
        run: dart format --output none --set-exit-if-changed lib/ test/
        working-directory: frontend

  dotnet-format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'
      - name: Restore
        run: dotnet restore backend/Sheetstorm.slnx
      - name: dotnet format (verify-no-changes)
        run: >
          dotnet format backend/Sheetstorm.slnx
          --verify-no-changes
          --report dotnet-format-report.json
      - name: Upload Format Report
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: dotnet-format-report
          path: dotnet-format-report.json
```

### 2.5 Coverage-Schwellenwerte

| Projekt | Typ | Mindest-Coverage | Ziel |
|---------|-----|-----------------|------|
| `Sheetstorm.Domain` | Unit | **80%** | 90% |
| `Sheetstorm.Api` | Unit + Integration | **70%** | 80% |
| `Sheetstorm.Infrastructure` | Integration | **60%** | 75% |
| Flutter `lib/domain/` | Unit | **80%** | 90% |
| Flutter `lib/data/` | Unit | **70%** | 80% |
| Flutter `lib/ui/` | Widget | **60%** | 70% |

Coverage-Checks schlagen den PR-Build fehl. Ausnahmen nur via PR-Kommentar des Lead (Stark) dokumentiert.

---

## 3. Code Conventions

### 3.1 Dart / Flutter

**Linter:** `flutter_lints` + `effective_dart` Regeln via `analysis_options.yaml`:

```yaml
# frontend/analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Naming
    - camel_case_types            # Klassen: PascalCase
    - camel_case_extensions       # Extensions: PascalCase
    - file_names                  # Dateinamen: snake_case.dart
    - non_constant_identifier_names # Variablen/Methoden: camelCase
    - constant_identifier_names   # Konstanten: lowerCamelCase (NICHT SCREAMING_CAPS)

    # Code Quality
    - avoid_print               # Kein print() in Produktion (→ logger)
    - avoid_empty_else
    - avoid_relative_lib_imports  # Absolute Package-Imports
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_single_quotes
    - unnecessary_const
    - unnecessary_new

    # Sicherheit
    - avoid_dynamic_calls
    - always_declare_return_types

analyzer:
  errors:
    missing_required_param: error
    missing_return: error
    invalid_assignment: error
```

**Benennungskonventionen Dart:**

| Element | Convention | Beispiel |
|---------|------------|---------|
| Klassen, Enums, Typaliase | `PascalCase` | `NoteRepository`, `MitgliedRolle` |
| Methoden, Variablen | `camelCase` | `fetchStimmen()`, `aktiverMusiker` |
| Konstanten | `lowerCamelCase` | `defaultTimeout`, `maxRetries` |
| Dateinamen | `snake_case.dart` | `note_repository.dart` |
| Riverpod Providers | `camelCase` + Suffix | `noteRepositoryProvider`, `musikerNotifier` |
| Widgets | `PascalCase` | `Spielmodus-Screen → SpielmodusScreen` |
| Test-Dateien | `*_test.dart` | `note_repository_test.dart` |

### 3.2 C# / .NET

**Linter:** `dotnet format` + `.editorconfig`:

```ini
# .editorconfig (Root)
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space

[*.{cs,csx}]
indent_size = 4

# Naming Conventions (C# specifics)
dotnet_naming_rule.private_fields_should_be_camel_case.severity = warning
dotnet_naming_rule.private_fields_should_be_camel_case.symbols = private_fields
dotnet_naming_rule.private_fields_should_be_camel_case.style = camel_case_with_underscore

dotnet_naming_symbols.private_fields.applicable_kinds = field
dotnet_naming_symbols.private_fields.applicable_accessibilities = private

dotnet_naming_style.camel_case_with_underscore.required_prefix = _
dotnet_naming_style.camel_case_with_underscore.capitalization = camel_case

# Code Style
csharp_style_var_for_built_in_types = false:suggestion
csharp_style_var_when_type_is_apparent = true:suggestion
csharp_prefer_braces = true:warning
csharp_style_expression_bodied_methods = when_on_single_line:suggestion
csharp_style_expression_bodied_properties = true:suggestion
csharp_style_throw_expression = true:suggestion
csharp_style_null_check_on_left = true:suggestion
dotnet_style_prefer_is_null_check_over_reference_equality_method = true:warning
dotnet_style_qualification_for_field = false:warning
dotnet_style_qualification_for_property = false:warning
dotnet_style_require_accessibility_modifiers = always:warning

[*.{yaml,yml,json}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

**Benennungskonventionen C#:**

| Element | Convention | Beispiel |
|---------|------------|---------|
| Klassen, Interfaces | `PascalCase` | `NoteRepository`, `INoteRepository` |
| Interfaces | `I` + `PascalCase` | `IMusikRepository` |
| Methoden, Properties | `PascalCase` | `GetStimmenAsync()`, `AktiveSeit` |
| Private Felder | `_camelCase` | `_dbContext`, `_logger` |
| Lokale Variablen | `camelCase` | `aktiverMusiker` |
| Konstanten | `PascalCase` | `MaxRetryCount` |
| Async-Methoden | Suffix `Async` | `GetByIdAsync()`, `SaveChangesAsync()` |
| DTOs | Suffix `Dto` | `MusikerDto`, `StimmeCreateDto` |
| Enums | `PascalCase`, Werte `PascalCase` | `MitgliedRolle.Dirigent` |

### 3.3 Git — Conventional Commits

Format: `<type>(<scope>): <beschreibung>`

**Commit-Typen:**

| Typ | Verwendung |
|-----|------------|
| `feat` | Neues Feature |
| `fix` | Bugfix |
| `docs` | Nur Dokumentation |
| `refactor` | Code-Umstrukturierung ohne Verhaltensänderung |
| `test` | Tests hinzufügen oder korrigieren |
| `chore` | Build, CI, Dependencies, Tools |
| `perf` | Performance-Verbesserung |
| `style` | Formatierung, Linting (kein Logik-Change) |
| `revert` | Reverts a prior commit |

**Scopes:** `backend`, `frontend`, `ci`, `docs`, `squad`, `auth`, `noten`, `spielmodus`, `config`, `migrations`

**Beispiele:**
```
feat(backend): add JWT refresh token endpoint
fix(frontend): correct half-page-turn scroll offset
docs(stark): add projekt-setup-spec for issue #6
chore(ci): increase Flutter coverage threshold to 70%
test(backend): add integration tests for MusikerRepository
refactor(frontend): extract NoteViewer into reusable widget
```

**Branch-Naming:** `squad/{issue-nummer}-{kurz-slug}`

```
squad/6-projekt-setup-spec
squad/7-backend-scaffolding
squad/12-auth-jwt
squad/18-spielmodus-prototype
```

### 3.4 Pull Request Policy

**PR-Titel:** Conventional Commit Format: `feat(scope): beschreibung (#issue)`

**PR-Body muss enthalten:**
1. Verknüpfter Issue: `Closes #N`
2. Was wurde geändert (Kurzfassung)
3. Wie wurde getestet
4. Screenshots (bei UI-Änderungen)

**Review-Policy (3-Reviewer):**

Jeder PR muss von **3 verschiedenen Reviewern** reviewed und approved werden:

| Reviewer | Modell | Fokus |
|----------|--------|-------|
| Reviewer 1 | Claude Sonnet 4.6 | Code-Qualität, Architektur-Konformität |
| Reviewer 2 | Claude Opus 4.6 | Tiefe Analyse, Edge Cases, Sicherheit |
| Reviewer 3 | GPT 5.4 | Alternativer Blickwinkel, Best Practices |

Der Lead (Stark) überprüft die Review-Ergebnisse und entscheidet, welche Vorschläge umgesetzt, zurückgestellt oder verworfen werden.

**UX-Review:** Pflicht bei allen Änderungen die Nutzer-Interaktion betreffen (→ Wanda).

**Merge-Strategie:** Squash Merge auf `main`. Branch nach Merge löschen.

---

## 4. Development Environment

### 4.1 Pflicht-Tools

| Tool | Version | Installation | Zweck |
|------|---------|-------------|-------|
| **Flutter SDK** | 3.41.5 (stable) | [flutter.dev](https://flutter.dev/docs/get-started/install) | Frontend-Entwicklung |
| **Dart SDK** | 3.11.0 (via Flutter) | Inklusive in Flutter SDK | Dart-Toolchain |
| **.NET 10 SDK** | 10.0 LTS | [dotnet.microsoft.com](https://dotnet.microsoft.com/download/dotnet/10.0) | Backend-Entwicklung |
| **PostgreSQL** | 18.x | [postgresql.org](https://www.postgresql.org/download/) oder Docker | Server-Datenbank |
| **Git** | 2.40+ | [git-scm.com](https://git-scm.com/) | Versionskontrolle |
| **GitHub CLI** | 2.x | [cli.github.com](https://cli.github.com/) | PR/Issue-Management |

**Optional (empfohlen):**

| Tool | Zweck |
|------|-------|
| **Docker Desktop** | PostgreSQL lokal via Container (kein manuelles Install) |
| **Azure CLI** | Deployment zu Azure Dev-Environment |
| **Postman / Bruno** | API-Testen |

### 4.2 VS Code Extensions

`.vscode/extensions.json` im Repository:

```json
{
  "recommendations": [
    // Flutter / Dart
    "Dart-Code.dart-code",
    "Dart-Code.flutter",
    
    // C# / .NET
    "ms-dotnettools.csharp",
    "ms-dotnettools.csdevkit",
    "ms-dotnettools.vscode-dotnet-runtime",
    
    // Code Quality
    "editorconfig.editorconfig",
    "streetsidesoftware.code-spell-checker",
    "streetsidesoftware.code-spell-checker-german",
    
    // Git
    "eamodio.gitlens",
    "mhutchie.git-graph",
    
    // Allgemein
    "ms-azuretools.vscode-docker",
    "humao.rest-client",
    "yzhang.markdown-all-in-one"
  ]
}
```

### 4.3 VS Code Workspace Settings

`.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit"
  },
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.formatOnSave": true,
    "editor.rulers": [80]
  },
  "[csharp]": {
    "editor.defaultFormatter": "ms-dotnettools.csharp",
    "editor.formatOnSave": true
  },
  "dart.flutterSdkPath": null,
  "dart.lineLength": 80,
  "files.exclude": {
    "**/bin": true,
    "**/obj": true,
    "**/.dart_tool": true
  }
}
```

### 4.4 Lokale Entwicklung Setup

```bash
# 1. Repository klonen
git clone https://github.com/caol-ila/Sheetstorm.git
cd Sheetstorm

# 2. Flutter-Abhängigkeiten installieren
cd frontend && flutter pub get && cd ..

# 3. .NET-Abhängigkeiten wiederherstellen
cd backend && dotnet restore Sheetstorm.slnx && cd ..

# 4a. PostgreSQL via Docker starten (empfohlen)
docker run -d \
  --name sheetstorm-postgres \
  -e POSTGRES_DB=sheetstorm_dev \
  -e POSTGRES_USER=sheetstorm \
  -e POSTGRES_PASSWORD=sheetstorm_dev \
  -p 5432:5432 \
  postgres:18

# 4b. Oder: PostgreSQL nativ, Datenbank anlegen:
# createdb sheetstorm_dev

# 5. User Secrets für lokale Konfiguration (Backend)
cd backend/src/Sheetstorm.Api
dotnet user-secrets set "ConnectionStrings:DefaultConnection" \
  "Host=localhost;Database=sheetstorm_dev;Username=sheetstorm;Password=sheetstorm_dev"
dotnet user-secrets set "Jwt:Key" "your-local-dev-secret-min-32-chars"
dotnet user-secrets set "Jwt:Issuer" "sheetstorm-dev"

# 6. Datenbankmigrationen ausführen
dotnet ef database update --project src/Sheetstorm.Infrastructure \
  --startup-project src/Sheetstorm.Api

# 7. Backend starten
dotnet run --project src/Sheetstorm.Api

# 8. Frontend starten (neues Terminal)
cd frontend && flutter run -d chrome  # oder: flutter run -d windows
```

---

## 5. Testing-Strategie

### 5.1 Übersicht der Test-Ebenen

```
┌─────────────────────────────────────────────────────────┐
│  End-to-End Tests (selten, langsam, hohes Vertrauen)    │
│  Flutter Integration Tests · WebApplicationFactory API  │
├─────────────────────────────────────────────────────────┤
│  Integration Tests (mittel, gegen echte Datenbank)      │
│  Testcontainers + PostgreSQL · EF Core Migrations test  │
├─────────────────────────────────────────────────────────┤
│  Widget Tests (Flutter-spezifisch)                      │
│  UI-Komponenten isoliert · ohne echte Daten             │
├─────────────────────────────────────────────────────────┤
│  Unit Tests (viele, schnell, isoliert)                  │
│  Domain-Logik · Repositories (Mock-DB) · Use Cases     │
└─────────────────────────────────────────────────────────┘
```

### 5.2 .NET Tests (xUnit)

**Framework:** xUnit 2.x + Moq + FluentAssertions + Testcontainers (Integration)

**Unit Tests — `Sheetstorm.UnitTests`:**

```csharp
// Konvention: {Klasse}Tests.cs, Methode: {Methode}_WhenCondition_Should/Returns
public class StimmeServiceTests
{
    [Fact]
    public async Task GetStimmeForMusiker_WhenPrimaryExists_ReturnsPrimary()
    { ... }

    [Theory]
    [InlineData("2. Klarinette", "1. Klarinette")]
    [InlineData("1. Klarinette", "Klarinette")]
    public async Task GetStimmeForMusiker_WhenFallbackNeeded_ReturnsNextBest(
        string requested, string expected)
    { ... }
}
```

**Integration Tests — `Sheetstorm.IntegrationTests`:**

```csharp
// Testcontainers: startet echtes PostgreSQL in Docker für jeden Test-Run
public class MusikerRepositoryIntegrationTests : IAsyncLifetime
{
    private PostgreSqlContainer _postgres = new PostgreSqlBuilder()
        .WithImage("postgres:18")
        .Build();

    public async Task InitializeAsync() => await _postgres.StartAsync();
    public async Task DisposeAsync() => await _postgres.DisposeAsync();
}
```

**API Tests — `Sheetstorm.ApiTests`:**

```csharp
// WebApplicationFactory für HTTP-Level Tests ohne Deploy
public class MusikerApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task GetMusiker_WithValidToken_Returns200()
    { ... }
}
```

### 5.3 Flutter Tests (flutter_test)

**Unit Tests — `frontend/test/`:**

```dart
// Konvention: test/{domain}/{klasse}_test.dart
// Gruppierung: group('StimmeRepository', () { ... })
void main() {
  group('StimmenFallbackLogik', () {
    test('gibt primäre Stimme zurück wenn vorhanden', () async {
      // Arrange
      final repo = MockStimmeRepository();
      when(() => repo.findStimme('2. Klarinette'))
          .thenAnswer((_) async => Some(stimme));
      // Act + Assert
      expect(await service.getStimme(musiker), equals(stimme));
    });

    test('fällt auf nächste Stimme zurück', () async { ... });
  });
}
```

**Widget Tests:**

```dart
void main() {
  testWidgets('SpielmodusScreen zeigt Vollbild an', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteProvider.overrideWith((_) => mockNote)],
        child: const MaterialApp(home: SpielmodusScreen()),
      ),
    );
    expect(find.byType(NoteViewer), findsOneWidget);
    expect(find.byType(AppBar), findsNothing); // Vollbild = keine AppBar
  });
}
```

**Integration Tests — `frontend/integration_test/`:**

```dart
// Laufen auf echtem Gerät / Emulator via flutter test integration_test/
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Halbe-Seite-Umblättern funktioniert', (tester) async {
    // Startet die echte App, testet reale Gesten
    app.main();
    await tester.pumpAndSettle();
    // ...
  });
}
```

### 5.4 Coverage-Richtlinien

- **Neue Features:** Kein Merge ohne Tests für Happy Path + mindestens 1 Edge Case
- **Bugfixes:** Regression-Test ist Pflicht — kein Fix ohne Test der den Bug reproduziert
- **Coverage-Gates** (aus Abschnitt 2.5) werden im CI erzwungen
- **Ausnahmen:** Reine DTO-Klassen, Auto-Generated Code (EF Migrations), Entry Points

### 5.5 Test-Naming Konventionen

| Sprache | Konvention | Beispiel |
|---------|------------|---------|
| C# (xUnit) | `Methode_Bedingung_Erwartung` | `GetMusiker_WhenNotFound_Returns404` |
| Dart (flutter_test) | Beschreibender String | `'gibt Stimme zurück wenn verfügbar'` |
| Integration | Szenario-basiert | `'Musiker kann sich mit gültigem Token einloggen'` |

---

## 6. Deployment-Strategie (MS1)

### 6.1 Environment-Übersicht

| Environment | Branch | Zweck | Hosting |
|-------------|--------|-------|---------|
| **local** | jeder | Entwicklung | Lokal (Docker + dotnet run + flutter run) |
| **dev** | `main` | Integration, Stakeholder-Demo | Azure App Service (Free/Basic Tier) |
| *(staging)* | *(release/*)* | *(Pre-Production — ab MS2)* | *(Azure App Service Standard)* |
| *(prod)* | *(tags)* | *(Production — nach MS1 Review)* | *(Azure App Service Premium)* |

Für **MS1** werden nur `local` und `dev` betrieben. Staging und Production kommen mit MS2.

### 6.2 Dev-Environment Deploy — `.github/workflows/deploy-dev.yml`

```yaml
name: Deploy to Dev

on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    needs: [build-and-test]  # Nur nach erfolgreichem CI
    environment: dev

    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET 10
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'

      - name: Publish Backend
        run: >
          dotnet publish backend/src/Sheetstorm.Api/Sheetstorm.Api.csproj
          --configuration Release
          --output ./publish

      - name: Deploy to Azure App Service
        uses: azure/webapps-deploy@v3
        with:
          app-name: sheetstorm-api-dev
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE_DEV }}
          package: ./publish

  deploy-frontend:
    runs-on: ubuntu-latest
    needs: [build-and-test]

    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'
          channel: 'stable'
      - name: Build Flutter Web
        run: flutter build web --release --dart-define=API_URL=${{ vars.DEV_API_URL }}
        working-directory: frontend
      - name: Deploy to Azure Static Web Apps
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_DEV }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          app_location: frontend/build/web
          skip_app_build: true
```

### 6.3 Datenbank-Migrations-Workflow

**Konvention:** Migrationen sind versioniert, idempotent und rückwärtskompatibel.

**Lokale Migration erstellen:**

```bash
# Im backend-Verzeichnis
dotnet ef migrations add <MigrationName> \
  --project src/Sheetstorm.Infrastructure \
  --startup-project src/Sheetstorm.Api \
  --output-dir Migrations

# Beispiel:
dotnet ef migrations add InitialCreate
dotnet ef migrations add AddMusikerAvatarUrl
dotnet ef migrations add AddStimmeMetadata
```

**Migrations-Naming-Konvention:**

| Pattern | Beispiel |
|---------|---------|
| Initiale Migration | `InitialCreate` |
| Tabelle hinzufügen | `Add{Entität}Table` → `AddKapelleTable` |
| Spalte hinzufügen | `Add{Spalte}To{Tabelle}` → `AddAvatarUrlToMusiker` |
| Index hinzufügen | `Add{Index}IndexOn{Tabelle}` → `AddEmailIndexOnMusiker` |
| Spalte umbenennen | `Rename{AltNeu}In{Tabelle}` → `RenameNameToTitelInStueck` |
| Tabelle löschen | `Remove{Entität}Table` → `RemoveLegacyImportTable` |

**Migrations in CI/CD:**

```yaml
# Teil von deploy-dev.yml (nach publish, vor start)
- name: Run Database Migrations
  run: >
    dotnet ef database update
    --project backend/src/Sheetstorm.Infrastructure
    --startup-project backend/src/Sheetstorm.Api
  env:
    ConnectionStrings__DefaultConnection: ${{ secrets.DEV_DB_CONNECTION_STRING }}
```

**Migrations-Regeln:**

1. **Nie eine existierende Migration editieren** — immer neue Migration erstellen
2. **Keine destruktiven Migrationen ohne Datensicherung** — Spalten erst umbenennen, dann löschen (2 Migrations)
3. **Seed-Daten** in separaten Migrations oder `HasData()` in `OnModelCreating`
4. **Down-Methode** muss immer implementiert sein (ermöglicht Rollback)

### 6.4 Environment-Konfiguration

**Konfigurationsprinzip:** Kein Secret im Code. Alle Secrets via GitHub Secrets / Azure App Configuration.

| Konfigurationsebene | Methode | Umgebung |
|--------------------|---------|----------|
| Lokale Entwicklung | `dotnet user-secrets` | local |
| CI/CD-Pipelines | GitHub Secrets | CI |
| Dev/Staging/Prod | Azure App Configuration + Key Vault | dev / staging / prod |

**Pflicht-Konfigurationen (Backend):**

```json
// appsettings.json (Defaults, keine Secrets)
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Jwt": {
    "Issuer": "",
    "Audience": "sheetstorm-app",
    "ExpiresInMinutes": 60,
    "RefreshExpiresInDays": 30
  }
}
```

Secrets (Key, ConnectionString, AzureAI-Keys) **ausschließlich** über User Secrets (lokal) oder Azure Key Vault (Cloud).

---

## 7. Abhängigkeiten zu anderen Issues

| Issue | Abhängigkeit |
|-------|-------------|
| #7 Backend Scaffolding | Nutzt Projektstruktur aus §1, Konventionen aus §3 |
| #8 Frontend Scaffolding | Nutzt Projektstruktur aus §1, analysis_options aus §3 |
| #9 Auth | Backend-Tests nach §5.2, Deployment nach §6 |
| Alle PRs | 3-Reviewer Policy aus §3.4 |

---

*Spezifikation by Stark (Lead / Architect) · Closes #6*
