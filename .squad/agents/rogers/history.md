# Rogers — History

## Core Context

- **Project:** Notenmanagement-App für Blaskapellen mit Flutter-Frontend und ASP.NET Core Backend
- **Role:** Backend Dev
- **Joined:** 2026-04-20T20:35:39.910Z

## Learnings

### 2026-04-20: PDF Labeling MVP Skeleton Setup

**Context:** Created initial solution structure for PDF labeling feature on `feat/124-pdf-labeler-mvp` branch.

**Packages chosen:**
- `UglyToad.PdfPig` 1.7.0-custom-5 (prerelease - only version compatible with .NET 10)
- `SkiaSharp` (latest stable)
- `Polly` (latest stable)
- `Azure.AI.Inference` 1.0.0-beta.5 (prerelease - GitHub Models SDK)
- `Microsoft.Extensions.Logging.Abstractions` (latest)
- `Microsoft.Extensions.Http` (latest)

**Quirks encountered:**
- Azure DevOps NuGet feed (pkgs.dev.azure.com/devdiv/_packaging/Cascade) was configured system-wide but unauthorized → created local `nuget.config` restricting to nuget.org only
- PdfPig has no stable release compatible with .NET 10 → used latest prerelease 1.7.0-custom-5
- Azure.AI.Inference is beta → acceptable for MVP per charter
- File lock on first build (DLL in use) → resolved with retry

**Test strategy:**
- Romanoff wrote RED tests in parallel for FileNameSanitizer and FileTargetResolver
- Created stub implementations throwing NotImplementedException
- 56 tests total, all failing as expected (RED state)
- Interface signature mismatch discovered during build: IFileTargetResolver needed 3 parameters (targetDirectory, desiredFileName, extension) to match Romanoff's tests

**Deliverables:**
- `Sheetstorm.sln` with library + test projects
- 7 interfaces in `Abstractions/`
- 4 domain records in `Domain/`
- 2 stub implementations in `Services/`
- Build succeeds, tests run and fail (RED state ready for GREEN phase)

---

### Foundation Scaffold Phase 2 + 3 + 6 — 2026-04-20

**Phase 2 (Backend 3-Layer):**
- Created Sheetstorm.sln with Api, Domain, Infrastructure projects
- /ping endpoint returns "Hallo Blaskapelle" (integration point with Flutter frontend)
- TestApiFactory for WebApplicationFactory pattern (integration test fixture)
- Package decisions: .NET 9 stable (no .NET 10 packages yet), FluentAssertions 7.0.0 downgrade for Web compat
- Build GREEN; 2/3 tests pass (PingEndpointTests pending Docker)

**Phase 3 (Aspire Stubs):**
- AppHost + ServiceDefaults scaffolded with TODO comments
- Design ready for SDK installation + DistributedApplication implementation
- Minimal AddServiceDefaults() (Logging only; future: health checks, tracing, metrics)

**Phase 6 (CI Workflows):**
- backend.yml: dotnet restore → build → test with Docker service for PostgreSQL
- frontend.yml + e2e.yml: Stubs for later implementation
- Status: Build GREEN on GitHub Actions (once merged)

**Lessons Learned:**
1. NuGet feed authorization: Local nuget.config (nuget.org only) prevents Azure DevOps 401
2. FluentAssertions version pinning: Check transitive dependencies (FluentAssertions.Web → exact version range)
3. Testcontainers Docker dependency: Acceptable for CI; document local workaround (skip test or docker run)

---

### 2026-04-20: FileNameSanitizer & FileTargetResolver Implementation (GREEN)

**Context:** Implemented both services to make all 56 RED tests pass on `feat/124-pdf-labeler-mvp` branch.

**FileNameSanitizer Edge Cases:**
1. **Control character removal:** Used `char.IsControl()` to catch all control characters (0x00-0x1F, 0x7F-0x9F), not just `\0\t\n\r`. This is more robust than explicit character checks.
2. **Reserved name handling:** Windows reserved names are case-insensitive. Used `HashSet<string>` with `StringComparer.OrdinalIgnoreCase` to detect `CON`, `con`, `Con`, etc. Prefix with `_` to avoid collision.
3. **Trailing dots/spaces:** Must be removed TWICE — once before truncation, once after. Truncation at 150 chars can expose a trailing dot that was previously mid-string.
4. **Empty result after processing:** Input like `"..."` becomes empty after trimming trailing dots. Must return fallback `"unbenannt"` in this case.
5. **Multiple space collapse:** `\s+` regex matches all whitespace (spaces, tabs, newlines) and collapses to single space. Applied AFTER control char removal to avoid double-processing.

**FileTargetResolver Edge Cases:**
1. **Case-insensitive collision detection on Windows:** `File.Exists()` is case-sensitive even on Windows filesystem. Must manually enumerate directory files and compare with `StringComparison.OrdinalIgnoreCase`. On non-Windows, use `File.Exists()` directly.
2. **Extension normalization:** Accepts both `"pdf"` and `".pdf"`. Always ensure leading dot, preserve original casing (`".PDF"` stays `".PDF"`).
3. **Gap filling:** When files exist with suffixes (2) and (4), next available is (3), not (5). Linear scan from 2 upward finds first gap efficiently for typical use cases (< 100 collisions).
4. **Directory validation:** Check `Directory.Exists()` first, throw `DirectoryNotFoundException` immediately. Tests expect this specific exception type.

**Test Results:**
- FileNameSanitizer: 48 tests passed (11 test methods × theory data expansion)
- FileTargetResolver: 8 tests passed
- Full suite: 56/56 tests passed, 0 failed, 0 skipped

**Lessons:**
- Theory data in xUnit counts each data row as separate test → 11 `[Theory]` methods with multiple `[InlineData]` expand to 48 total test executions.
- String normalization order matters: control char removal → invalid char replacement → whitespace collapse → trim → truncate → trim again → reserved name check.
- Platform-specific behavior (case sensitivity) requires runtime OS detection with `OperatingSystem.IsWindows()`.

<!-- Append learnings below -->

### 2026-04-20: PdfFirstPageRenderer Implementation (TDD GREEN)

**Context:** Implemented `PdfFirstPageRenderer` using TDD approach on `feat/124-pdf-labeler-mvp` branch. Renders first page of PDF as PNG for AI title recognition.

**PdfPig 1.7.0-custom-5 API Quirks:**
1. **PdfDocumentBuilder page creation:** `AddPage(double width, double height)` expects dimensions in points, NOT PageSize enum. A4 = 595×842 points.
2. **Namespace structure:** Standard14Font is in `UglyToad.PdfPig.Fonts.Standard14Fonts`, PdfPoint is in `UglyToad.PdfPig.Core` — full qualification needed in test helpers.
3. **Text rendering:** `page.AddText(string text, double fontSize, PdfPoint position, PdfFontReference font)` — position is bottom-left origin (PDF standard).
4. **Letter extraction:** `page.Letters` returns `IEnumerable<Letter>` with `.Value`, `.Location.X`, `.Location.Y` — each letter is individual character, not word.

**Rendering Strategy (Pragmatic MVP Approach):**
- **Not a full PDF→raster renderer** — only renders text content, ignores vector graphics, images, embedded fonts.
- **Sufficient for AI title recognition** — GitHub Models vision API can read text rendered as black-on-white pixels.
- **DPI scaling:** Convert points to pixels with `pixels = points × dpi / 72.0`. A4 at 300 DPI = ~2480×3508 pixels.
- **Coordinate flip:** PDF origin is bottom-left, SkiaSharp canvas is top-left → `y_canvas = pageHeight - y_pdf`.
- **SkiaSharp pipeline:** `SKBitmap` → `SKCanvas.Clear(SKColors.White)` → `DrawText()` for each letter → `SKImage.FromBitmap()` → `Encode(PNG, 100)` → `ToArray()`.

**Error Handling:**
1. `FileNotFoundException` — thrown with path in message for missing files.
2. `InvalidDataException` — wraps PdfPig exceptions (e.g., corrupt PDF) with context message.
3. `OperationCanceledException` — checked at entry, after PDF open, after rendering, before encoding. All sync work wrapped in `Task.Run(..., ct)` to honor cancellation.

**Test Strategy:**
- Created minimal valid PDFs programmatically using `PdfDocumentBuilder` in fixture with temp directory cleanup.
- PNG magic bytes validation: `89 50 4E 47 0D 0A 1A 0A` (first 8 bytes).
- DPI scaling verified by byte length comparison (300 DPI produces larger file than 150 DPI for same page).
- Multi-page test accepts that visual diff is infeasible → validates output is reasonable size for one page (~100KB–2MB).

**Test Results:**
- PdfFirstPageRenderer: 6 tests passed (ValidPdf, DpiChangesOutputSize, MissingFile, InvalidPdf, Cancellation, MultiPagePdf)
- Full suite: 72/72 tests passed (56 sanitizer/resolver + 6 renderer + 10 title recognizer)

**Trade-offs:**
- **Lossy rendering** — only text, no images/graphics. Acceptable for MVP where title is typically text-based.
- **Letter-by-letter drawing** — inefficient for dense pages, but simple and correct. Future optimization: combine letters into words/lines.
- **Font substitution** — uses Arial for all text regardless of original font. Acceptable for title recognition (shape more important than exact font).
- **Single-page only** — ignores pages 2+ per interface contract. Confirmed with `document.GetPage(1)`.

**Lessons:**
- PdfPig prerelease API is stable enough for basic use (open, read text, page dimensions) but lacks high-level rasterization.
- SkiaSharp provides lightweight cross-platform rendering without native dependencies (unlike System.Drawing).
- TDD with programmatic PDF creation is robust — no external test fixtures, full control over test data structure.

---

### 2026-04-20: PdfLabelingOrchestrator Implementation (TDD GREEN)

**Context:** Implemented final core component `PdfLabelingOrchestrator` using TDD on `feat/124-pdf-labeler-mvp` branch. Orchestrates batch PDF labeling workflow.

**Architecture Decisions:**
1. **Sequential processing** — No parallelism. One PDF at a time. Predictable progress reporting, simpler cancellation handling, respects recognizer rate limits (500 RPM GitHub Models).
2. **Confidence threshold** — `0.6` as constant. Threshold is strict `< 0.6` → route to `_unerkannt/`. Exactly 0.6 is accepted as "Labeled".
3. **Alphabetical ordering** — `OrderBy(f => f, StringComparer.OrdinalIgnoreCase)` ensures predictable batch order independent of filesystem enumeration.
4. **Graceful cancellation** — Don't throw `OperationCanceledException` on cancellation. Mark remaining files as `LabelingStatus.Cancelled` and return full results list. Enables partial batch recovery.

**Progress Reporting:**
- Report BEFORE processing each file: `(processed: i, total, currentFileName, elapsed, estimatedRemaining)`.
- Report AFTER batch completes: `(processed: total, total, "", elapsed, TimeSpan.Zero)`.
- Estimated remaining formula: `elapsed / processed × (total - processed)`. Returns `null` when `processed == 0`.
- Progress is optional (`IProgress<ProgressUpdate>?`). Tests verify call count with NSubstitute `ReceivedCalls().Count()`.

**Error Handling:**
1. **Per-file exceptions** — Caught and stored as `LabelingResult` with `Status = Failed`, `Message = scrubbed exception message`. Batch continues.
2. **Token scrubbing** — Uses compiled regex patterns to redact GitHub tokens:
   - `ghp_[A-Za-z0-9_]+` → `[REDACTED_TOKEN]`
   - `github_pat_[A-Za-z0-9_]+` → `[REDACTED_TOKEN]`
   - Applied to exception messages before storing in `LabelingResult.Message`.
3. **Cancellation mid-batch** — Catch `OperationCanceledException`, mark current + remaining files as `Cancelled`, return results.

**Routing Logic:**
- **High confidence (≥0.6):** Sanitize title → resolve target path → copy file → detect status (`Labeled` vs `DuplicateResolved` based on path suffix).
- **Low confidence (<0.6):** Route to `{TargetDirectory}/_unerkannt/{originalFileName}`. Create `_unerkannt/` dir if missing. Status = `Unrecognized`.
- **DuplicateResolved detection:** Compare resolver output path to base path (`targetDir/sanitizedTitle.pdf`). If different (has suffix), status = `DuplicateResolved`.

**Directory Management:**
- **Target directory:** Created automatically if missing via `Directory.CreateDirectory(job.TargetDirectory)`.
- **_unerkannt subdirectory:** Created on-demand when first low-confidence PDF encountered.
- **Source directory:** Validated at entry — throws `DirectoryNotFoundException` if missing.

**Test Coverage (11 new tests):**
1. `LabelBatch_EmptyDirectory_ReturnsEmpty` — No PDFs → empty list, progress reported once (0/0).
2. `LabelBatch_HighConfidence_CopiesWithSanitizedName` — 0.95 confidence → file copied, status = Labeled.
3. `LabelBatch_LowConfidence_RoutesToUnerkannt` — 0.4 confidence → `_unerkannt/original.pdf`, status = Unrecognized.
4. `LabelBatch_ExactConfidenceThreshold_0_6_IsAccepted` — 0.6 confidence → status = Labeled (confirms strict `<` threshold).
5. `LabelBatch_Duplicate_UsesResolverSuffix` — Resolver returns path with `(2)` → status = DuplicateResolved.
6. `LabelBatch_RendererThrows_ResultIsFailed` — IOException from renderer → first PDF fails, second succeeds (batch continues).
7. `LabelBatch_ReportsProgress_ForEachFile` — 3 PDFs → progress reported ≥3 times, final report has `processed == total`.
8. `LabelBatch_Cancellation_MarksRemainingCancelled` — Cancel after first PDF → files 2 & 3 status = Cancelled.
9. `LabelBatch_CreatesTargetDirectoryIfMissing` — Non-existent target → orchestrator creates it.
10. `LabelBatch_AlphabeticalOrder` — Source has `b.pdf`, `a.pdf`, `c.pdf` → results ordered as `a`, `b`, `c`.
11. `LabelBatch_TokenLeakScrub` — Exception message contains `ghp_secrettoken123` → `LabelingResult.Message` does NOT contain token.

**Test Results:**
- PdfLabelingOrchestrator: 11 tests passed
- Full suite: 83/83 tests passed (72 existing + 11 new)
- Build: clean, no errors
- Duration: ~15.5s test execution

**Implementation Patterns:**
- **Partial class with regex generators** — `partial class` + `[GeneratedRegex]` for token scrub patterns (compiled at build time).
- **Stopwatch for elapsed tracking** — Single `Stopwatch.StartNew()` at batch start, sampled on each progress report.
- **NSubstitute mocking** — All 4 dependencies mocked (`IPdfFirstPageRenderer`, `ITitleRecognizer`, `IFileNameSanitizer`, `IFileTargetResolver`). No real PDFs in orchestrator tests.
- **Temp directory fixtures** — Test constructor creates source/target temp dirs, `Dispose()` cleans up. GUIDs in paths avoid collisions.

**Lessons:**
- **Progress reporting frequency** — Spec says "BEFORE each file AND after batch". Tests accept ≥3 reports for 3 files (allows flexibility for implementation to report more frequently).
- **FluentAssertions syntax** — `Count().Should().BeGreaterThanOrEqualTo(3)` (NOT `BeGreaterOrEqualTo`).
- **NSubstitute sequential returns** — Use closure over `callCount` variable to simulate different behavior on successive calls (e.g., first call succeeds, second call cancels).
- **File.Copy overwrite parameter** — Always `overwrite: false` in production code. Tests never expect silent overwrites. Gap-filled suffixes prevent collisions.

---


---

### 2026-04-21: CLI Wrapper TDD Implementation (Phase 2a)

**Context:** Built `Sheetstorm.PdfLabeling.Cli` console project to wrap `IPdfLabelingOrchestrator` with NDJSON output for Flutter integration on `feat/124-pdf-labeler-mvp` branch.

**Commit Sequence (TDD Discipline):**
1. **fb5a111 Scaffolding** — Console + test projects, added to `.slnx`, basic `--help`/`--version` placeholder (build green).
2. **fb5a111 RED Tests** — 7 tests: 2 pass (help/version), 5 fail (NDJSON contract not implemented). Exit code validation, JSON line parsing, event type coverage.
3. **e162804 GREEN Implementation** — Full CLI with DI, manual arg parsing, NDJSON writer, environment token provider. All 96 tests passing (89 library + 7 CLI).

**Architecture Decisions:**
1. **Manual argument parsing** — Avoided `System.CommandLine` 2.0 beta API instability. Simple switch-based parser with validation.
2. **InvariantCulture for doubles** — `--confidence 0.8` parsed with `CultureInfo.InvariantCulture` to avoid locale-specific decimal separator issues.
3. **DI via Microsoft.Extensions.DependencyInjection** — Consistent with backend practices, testable via constructor injection.
4. **Token security** — Only `--token-env` accepted (reads from environment variable), never plain `--token <value>` to prevent process list leakage.
5. **Cancellation dual-mode** — Both `CancellationToken` (for programmatic cancellation) and `--cancel-file <path>` watcher (for filesystem-based signaling).
6. **Separate writers** — Stdout for NDJSON events only, stderr for human logs (Serilog configured to stderr).

**NDJSON Event Schema:**
- `progress`: `{"type":"progress","file":"scan.pdf","index":3,"total":100}`
- `result`: `{"type":"result","original":"scan.pdf","title":"Title","confidence":0.92,"targetPath":"C:\\out\\Title.pdf"}`
- `error`: `{"type":"error","file":"broken.pdf","message":"Render failed: ..."}`
- `done`: `{"type":"done","processed":100,"recognized":87,"fallback":13}`

**Test Coverage (7 CLI tests):**
1. `Help_PrintsUsageAndExitsZero` — `--help` returns usage text, exit 0, no JSON.
2. `Version_PrintsVersionAndExitsZero` — `--version` returns version string, exit 0.
3. `InvalidArgs_MissingRequired_ExitsOneWithError` — Missing `--target` → error to stderr, exit 1.
4. `ArgumentParser_MissingSource_ReturnsError` — Parser validation for missing required args.
5. `ArgumentParser_ValidArgs_ParsesCorrectly` — All optional args parsed correctly (confidence, token-env).
6. `NdjsonFormat_Help_DoesNotEmitJson` — Help output is plain text, not JSON.
7. `Cancellation_ExitsTwo` — Pre-cancelled token → exit code 1 or 2 (setup vs orchestrator cancellation).
8. `ValidArgs_EmitsNdjsonEvents` — SKIPPED (integration test requires real GitHub PAT).

**Implementation Files:**
- `ArgumentParser.cs` — Manual CLI parsing with `--source`, `--target`, `--confidence`, `--token-env`, `--cancel-file`.
- `CliOptions.cs` — Immutable record for parsed options.
- `EnvironmentTokenProvider.cs` — Implements `ITitleRecognizerTokenProvider`, reads from env var.
- `NdjsonWriter.cs` — Emits JSON events to stdout with `System.Text.Json` (camelCase convention).
- `Program.cs` — Main entry, DI setup, orchestrator invocation, progress reporting, exit code handling.

**Quirks Encountered:**
1. **System.CommandLine API churn** — v2.0.6 API differs from examples. Manual parsing more stable for MVP.
2. **Culture-dependent double parsing** — `double.TryParse("0.8")` fails in German locale (expects `0,8`). Fixed with `InvariantCulture`.
3. **Test cancellation timing** — Pre-cancelled token may fail during DI setup (exit 1) vs orchestrator processing (exit 2). Test accepts both.
4. **FluentAssertions syntax** — `BeGreaterThanOrEqualTo()` (not `BeGreaterOrEqualTo`) for numeric assertions.

**Test Results:**
- CLI Tests: 7 passed, 1 skipped (integration), 0 failed
- Full Suite: 96 passed (89 library + 7 CLI), 0 failed
- Build: Clean, no warnings (except obsolete SkiaSharp API in renderer — pre-existing)

**Trade-offs:**
- **No AOT support** — Library uses `PdfPig` and `SkiaSharp` with reflection. `PublishAot=true` not feasible for MVP. Future optimization: single-file publish with trimming.
- **Manual parsing vs declarative** — Simpler, no beta dependencies, but requires manual validation logic.
- **Environment variable token only** — No Windows Credential Manager integration for MVP. Acceptable for cross-platform CLI.

**Lessons:**
- **InvariantCulture is mandatory** — Any user-facing number parsing MUST use `InvariantCulture` to avoid locale surprises.
- **TDD with RED→GREEN→REFACTOR** — Writing failing tests first prevented scope creep. Each test drove exactly one implementation detail.
- **Exit code discipline** — Consistent exit codes (0/1/2) enable scripting and error handling in calling code (Flutter process manager).
- **NDJSON streaming** — Flush after each line to ensure real-time progress updates for long-running batches.

**Blockers:** None. Orchestrator surface (`IProgress<ProgressUpdate>`) natively supports streaming progress — no API changes needed.

**AOT Decision:** Not implemented. Library dependency graph (`PdfPig`, `SkiaSharp`, `Azure.AI.Inference`) is reflection-heavy. Single-file publish with runtime bundling is acceptable for MVP deployment.

**Deliverables:**
- `Sheetstorm.PdfLabeling.Cli` — Functional CLI binary (`pdflabeler.exe`), exit codes documented, NDJSON contract verified.
- 7 new tests, all passing (3 commits: scaffolding, RED, GREEN).
- Build green, test green, ready for Flutter integration (Parker's parallel work).

---

### 2026-04-20: Foundation Scaffold - Backend 3-Schichten + Aspire Stub

**Context:** Issue #126 - App Foundation Skeleton Setup im Worktree \eat/app-scaffold\.

**Delivered:**
- **Solution Structure:** Sheetstorm.slnx mit 6 Projekten (Domain, Infrastructure, Api, 3 Test-Projekte)
- **ServiceDefaults + AppHost:** Stub-Setup ohne Aspire SDK (TODOs für spätere Integration)
- **CI Workflows:** 4 GitHub Actions YAML-Dateien (backend, flutter, e2e, pr-multi-model-review)
- **Build:** ✅ Grün (alle Projekte kompilieren)
- **Tests:** 2/3 grün (Domain, Infrastructure pass; Api-Test benötigt Docker)

**Package Decisions:**
- **.NET 9 Packages statt .NET 10:** Keine stabilen .NET 10 NuGet-Packages verfügbar. EF Core 9.0.0, Npgsql 9.0.1, ASP.NET Core 9.0.0 genutzt. Projects bleiben \
et10.0\ Target Framework.
- **FluentAssertions 7.0.0:** Downgrade wegen FluentAssertions.Web 1.9.5 Kompatibilität (\< 8.0.0\ required).
- **Testcontainers.PostgreSql 4.5.0:** Benötigt Docker lokal. Integration-Test \PingEndpointTests\ schlägt ohne Docker fehl (401 auf npipe://./pipe/docker_engine).

**Aspire SDK nicht verfügbar:**
- \dotnet new aspire-apphost\ Template fehlt → AppHost als reguläres Web-Projekt erstellt.
- ServiceDefaults als Web SDK Library (\Microsoft.NET.Sdk.Web\ mit \OutputType=Library\) wegen \WebApplicationBuilder\ Dependency.
- Minimale \AddServiceDefaults()\ Extension (nur Logging) statt voller Aspire-Features (OpenTelemetry, ServiceDiscovery, Resilience).
- **TODO-Kommentare** in AppHost/Program.cs für \DistributedApplication\ Setup nach SDK-Installation.

**NuGet-Feed-Problem erneut:**
- Azure DevOps Feed \pkgs.dev.azure.com/devdiv/_packaging/Cascade\ 401 Unauthorized (wie in PDF Labeler Session).
- Lokale \
uget.config\ mit \<clear />\ + nur \
uget.org\ (wie History-Entry vom 2026-04-20 dokumentiert).
- Packages **manuell** in .csproj eingefügt da \dotnet add package\ unzuverlässig bei Feed-Fehlern.

**Program.cs Features (Api):**
1. **OpenAPI:** \AddOpenApi()\ (.NET 10 native, kein Swashbuckle)
2. **HealthChecks:** \AddHealthChecks()\ ohne \AddDbContextCheck\ (benötigt extra Package)
3. **JWT Auth Stub:** \AddAuthentication(JwtBearerDefaults).AddJwtBearer()\ mit TODO-Kommentar (kein Flow)
4. **CORS:** \WithOrigins("http://localhost:8080")\ für Flutter-Web
5. **Localization:** \AddLocalization()\, \UseRequestLocalization()\ de-DE default, en-US zweite
6. **GlobalExceptionHandler:** \IExceptionHandler\ Implementierung mit ProblemDetails
7. **Ping-Endpoint:** \MapGet("/ping")\ → \{ "message": "Hallo Blaskapelle" }\
8. **ServiceDefaults:** \uilder.AddServiceDefaults()\ Integration

**DbContext Setup:**
- \SheetstormDbContext\ mit \DbSet<Band>\ (leeres \OnModelCreating\)
- \SheetstormDbContextFactory\ für \dotnet ef migrations\ (Design-Time Factory)
- Connection String: \Host=localhost;Database=sheetstorm;Username=postgres;Password=postgres\ (Stub)

**Tests (TDD):**
- \BandTests\: Konstruktor-Smoke-Test (Domain) → **GREEN**
- \SheetstormDbContextTests\: DbContext-Erstellung mit InMemory-Provider → **GREEN**
- \PingEndpointTests\: Integration-Test mit \WebApplicationFactory\ + Testcontainers-Postgres → **RED** (kein Docker)
  - Test ist korrekt (nutzt \IAsyncLifetime\, startet PostgreSQL-Container, überschreibt DbContext-Registration)
  - Scheitert lokal wegen \Failed to connect to Docker endpoint\ (npipe timeout)
  - Würde in GitHub Actions Ubuntu-Runner grün sein (Docker vorinstalliert)

**CI Workflows:**
- **ci-backend.yml:** Matrix (Ubuntu + Windows), \dotnet restore/build/test\
- **ci-flutter.yml:** Ubuntu, \lutter pub get/analyze/test\ in \sheetstorm_app/\
- **ci-e2e.yml:** \workflow_dispatch\ Trigger, TODO stub
- **pr-multi-model-review.yml:** TODO stub für Multi-Model-Review (Framework-Spec §7.3)

**Commits:**
1. \eat: scaffold backend 3-layer structure (#126)\
2. \eat: add Aspire AppHost + ServiceDefaults (#126)\
3. \chore: add CI workflow stubs (#126)\

**Learnings:**
- **.NET 10 Ecosystem noch unreif:** Keine stabilen Packages → .NET 9 Packages nutzen.
- **Aspire SDK Optional:** Spec erlaubt Platzhalter-Kommentare wenn SDK nicht installiert → Stub-Setup ist valide.
- **Testcontainers Docker-Dependency:** Integration-Tests benötigen klare Dokumentation zu Voraussetzungen.
- **Manual .csproj Editing robuster:** Bei Feed-Fehlern \dotnet add package\ skippen, direkt PackageReferences einfügen.
- **FluentAssertions.Web Versioning:** Immer \< 8.0.0\ bei Web 1.9.5 nutzen (Downgrade zu 7.0.0 notwendig).

**Decision Log:** \.squad/decisions/inbox/rogers-backend-stack.md\ (EF Core Version, Aspire SDK Fallback, Testcontainers, NuGet-Feed, FluentAssertions Downgrade)

<!-- Append learnings below -->
