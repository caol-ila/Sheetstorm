# Squad Decisions

## Active Decisions

### PDF Raster Rendering with Docnet.Core

**Scope:** PDF → PNG conversion for GPT-4o Vision (#124)  
**Owner:** Rogers (Backend Dev)  
**Status:** ACTIVE (implemented & verified)

Replace text-only `PdfFirstPageRenderer` with **Docnet.Core** for true raster-based PDF rendering.

**Rationale:**
- Text-only approach (PdfPig + SkiaSharp) fails entirely on scanned PDFs (image-only, no text layer)
- Scanned PDFs are the primary real-world use case for Blaskapelle sheet music
- Docnet.Core uses native PDFium renderer with .NET wrapper (MIT license)
- Cross-platform support (Windows, Linux, macOS)
- Aspire-compatible (pure library, containerization-ready)

**Implementation:**
- 300 DPI raster rendering for quality AI vision input
- PNG output via SkiaSharp post-processing
- Vision optimization: Auto-resize to max 1600×1600 px (reduces GPT-4o tokens while preserving readability)
- Proper IDisposable pattern for native PDFium handle cleanup
- Custom PdfRenderingException for corrupted/encrypted PDFs

**Alternatives Considered:**
1. PDFtoImage — viable fallback if Docnet doesn't build on .NET 10
2. PdfSharpCore — GPL license (commercial incompatibility)
3. Ghostscript.NET — AGPL license, requires external install
4. ImageMagick/Magick.NET — heavyweight, licensing complexity

**Consequences:**
- ✅ Handles scanned + digital PDFs (text, graphics, images, fonts)
- ✅ MIT license (no GPL contamination)
- ✅ Cross-platform deployment
- ⚠️ Native PDFium dependency (binaries bundled in NuGet)
- ⚠️ Larger package footprint

**Supersedes:** `rogers-pdf-renderer-approach.md` — text-only approach is obsolete; native raster rendering is now primary path.

---

### WinUI 3 MVVM Stack for PDF Labeler Desktop

**Scope:** Architecture for WinUI 3 Desktop UI (#124, UI-Teil)  
**Owner:** Pepper (Desktop Dev)  
**Status:** SUPERSEDED (2026-04-21, Flutter Desktop chosen instead)  
**Superseded By:** Tech Switch WinUI 3 → Flutter Desktop (see below)

Use **CommunityToolkit.Mvvm** with source generators for Desktop ViewModel architecture.

**Rationale:**
- Consistent with community best practice for WinUI 3 apps
- Source-generated Observable properties eliminate boilerplate
- Integrates cleanly with x:Bind XAML compiler
- Reduces manual INotifyPropertyChanged noise
- DI via Microsoft.Extensions.Hosting (already used in backend)

**Alternatives Considered:**
1. Manual INotifyPropertyChanged — More verbose, but no source generator dependency
2. Prism MVVM — Heavier framework, adds complexity for MVP
3. ReactiveUI — Functional approach, steeper learning curve for team

**Implications:**
- All Desktop ViewModels inherit from ObservableObject (source-generated)
- Test fixtures must handle COM initialization for UI-layer tests
- Version pinning: CommunityToolkit.Mvvm ↔ CommunityToolkit.Mvvm.SourceGenerators must match

**Risks:**
- x:Bind Compilation: Version mismatch between toolkit packages can cause compiler errors
- Test COM Initialization: WinUI 3 tests require Windows Runtime setup
- Source Generator Variability: Generated code depends on exact toolkit version

**Blockers:** XAML x:Bind compiler errors (MSB3073), COM init in Desktop tests, CredentialStore ownership TBD

**Archive Note:** This decision remains in the record for historical reference. WinUI 3 implementation was attempted; XAML compiler tooling proved intractable (2+ days unresolved). Flutter Desktop offers better consistency with sheetstorm_app and avoids tooling friction.

---

---

## Foundation Scaffold Phase 1–7 (Issue #126, PR #127)

**Session Date:** 2026-04-20  
**Branch:** feat/app-scaffold (off main)  
**Status:** DELIVERED — Build GREEN, 2/3 tests GREEN

### App Foundation Scope & Structure

**Scope:** Monorepo layout + branching strategy + structural decisions (Phase 1 + decisions)  
**Owner:** Stark (Lead Architect)  
**Status:** DECIDED

#### Decision: Branch Strategy

Branch `feat/app-scaffold` off `main` (not off `feat/124-pdf-labeler-mvp`).

**Rationale:**
- **Isolation:** PDF Labeler (#124, WinUI/Flutter Desktop) is parallel tool, not part of Foundation
- **Merge independence:** `feat/124` can merge independently; Foundation not blocked
- **Scope clarity:** Foundation = Flutter app + ASP.NET Core backend; PDF Labeler = desktop utility
- **.squad/skills/git-worktree/SKILL.md §2.3:** Feature branches off `main`

**Consequence:** Both branches manage shared framework-spec files (docs/, `.editorconfig`, etc.) → potential merge conflicts mitigated by pre-merging framework-spec baseline

---

#### Decision: Monorepo Structure

`src/` (Backend), `tests/` (Backend tests), `sheetstorm_app/` (Flutter) in single repo.

**Rationale:**
- **Idiom:** Flutter apps in .NET repos typically as subfolders (SRP)
- **Aspire:** AppHost orchestrates both backend + Flutter Web → same repo natural
- **Build isolation:** `dotnet build` doesn't interfere with `flutter build`
- **Scalability:** Schema ready for second Flutter project (admin panel, CLI)

**Alternative rejected:** Flutter as repo root (confuses .NET developers; Aspire hosting logic inverted)

**Consequence:** Root `README.md` must clearly explain monorepo structure; `.gitignore` includes both .NET + Flutter patterns

---

#### Decision: Directory Layout

```
.
├── src/
│   ├── Sheetstorm.Api/
│   ├── Sheetstorm.Domain/
│   ├── Sheetstorm.Infrastructure/
│   ├── Sheetstorm.AppHost/           (Aspire orchestrator)
│   └── Sheetstorm.ServiceDefaults/
├── tests/
│   └── Sheetstorm.*.Tests/
├── sheetstorm_app/                  (Flutter)
├── docs/
├── .github/workflows/
└── .squad/
```

**Rationale:** Framework-Spec §3.2 (3-Schichten), Testcontainers convention, Aspire standard layout

---

#### Decision: No ADR for Operational Decisions

Inbox files for operational/structural decisions (branching, folder layout), not MADR ADRs.

**Rationale:** ADR = architectural (why PostgreSQL vs MongoDB?); inbox = operational (folder names, branch names)

**Consequence:** Accepted inbox files go to `.squad/decisions.md`; rejected files go to `.squad/decisions/rejected/`

---

### Backend Stack Decisions (Phase 2 + 3 + 6)

**Scope:** Backend 3-layer scaffold + testing + CI  
**Owner:** Rogers (Backend Dev)  
**Status:** IMPLEMENTED

#### Decision: .NET 9 Packages on .NET 10 SDK

Use latest stable package versions for .NET 9 (not preview .NET 10 packages).

**Rationale:**
- No stable .NET 10 NuGet packages available (only preview/beta)
- .NET 9 packages run fine on .NET 10 Runtime
- Stability > early adoption for Foundation Phase

**Chosen packages:**
- Microsoft.EntityFrameworkCore 9.0.0
- Npgsql.EntityFrameworkCore.PostgreSQL 9.0.1
- Microsoft.AspNetCore.Authentication.JwtBearer 9.0.0
- Microsoft.AspNetCore.Mvc.Testing 9.0.0
- FluentAssertions 7.0.0 (downgrade for FluentAssertions.Web compat)
- Testcontainers.PostgreSql 4.5.0

**Consequence:** Upgrade to .NET 10 packages when stable released (1–2 day effort)

---

#### Decision: Testcontainers + Docker Dependency

Use Testcontainers.PostgreSQL for integration tests (requires Docker running locally).

**Rationale:** Framework-Spec §6.2 requires true DB testing (not in-memory)

**Consequence:**
- Local: `docker run -d -p 5432:5432 postgres:16-alpine` or skip test
- CI: GitHub Actions Ubuntu runner has Docker; all tests pass

**Alternatives rejected:** In-memory EF provider (violates spec), local PostgreSQL install (less portable)

---

#### Decision: Aspire SDK Stub (Scaffold Only)

`Sheetstorm.AppHost` created as Web SDK project with TODO comments (SDK not installed locally).

**Rationale:** Aspire template unavailable; scaffold structure now + implement orchestration later

**Consequence:**
1. AppHost builds ✅
2. `DistributedApplication` usage stubbed with comments
3. Next phase: Install SDK + implement health checks + service registration

---

### Flutter Stack Decisions (Phase 4)

**Scope:** Flutter app structure + dependencies + i18n  
**Owner:** Parker (Frontend Dev)  
**Status:** DELIVERED (structure complete; execution pending SDK)

#### Decision: Riverpod 2.5.1 (Not 3.x Beta)

Use stable Riverpod 2.5.1 for state management.

**Rationale:**
- Riverpod 3.x still in beta/pre-release as of Jan 2025
- 2.5.1 is mature, well-documented, feature-complete for MVP
- Migration path to 3.x straightforward when stable

**Consequence:** Future Riverpod 3 upgrade planned; no architecture changes needed

---

#### Decision: ARB-Based Internationalization

Use Flutter's official ARB format with code generation (zero hardcoded strings).

**Rationale:**
- Type-safe: `AppLocalizations.of(context).appTitle`
- Framework-Spec §4.1 (Internationalization)
- Copilot-Instructions compliance

**Locales:**
- Default: `de` (German)
- Fallback: `en` (English)

**Consequence:** All strings externalized; hardcoded strings forbidden

---

#### Decision: Manual Flutter Scaffold (No SDK Locally)

Dart code structure created manually; platform-specific files require `flutter create`.

**Rationale:** Framework-Spec Phase 4 task: "Falls Flutter-SDK nicht installiert: dokumentiere das, aber erstelle die Struktur MANUELL"

**Consequence:**
- ✅ All Dart files valid + testable (structure, routing, providers, tests)
- ❌ Platform files (android/, ios/, windows/, web/) are stubs
- Next step: `flutter create --platforms=android,ios,windows,web .` once SDK available

---

### E2E Framework Decisions (Phase 5)

**Scope:** Playwright + Flutter Web integration + accessibility  
**Owner:** Romanoff (Test Engineer)  
**Status:** SCAFFOLDED

#### Decision: CanvasKit Multi-Layer Handling

**Problem:** Flutter Web's CanvasKit renderer makes DOM opaque; `getByText()` doesn't work without Semantics.

**Options considered:**
1. Force HTML renderer (`--web-renderer html`) — Diverges from production
2. Activate Semantics (`window.flutterSemanticsEnabled = true`) — Production-like
3. Screenshot-based verification — Visual evidence
4. Keyboard navigation fallback — Accessibility-first

**Decision:** Multi-layered (2 + 3 + 4)

**Implementation:**
- Primary: `getByRole()`, `getByLabel()` (works with Semantics)
- Fallback: `page.screenshot()` in try-catch
- Additional: Keyboard Tab + focus assertion

**Trade-offs:**
- ✅ Tests remain valid even if Semantics incomplete
- ✅ Visual evidence captured
- ❌ Screenshots add execution time
- ❌ Semantics require developer discipline

**Consequence:** E2E tests reliable even with partial widget Semantics; screenshots as debugging aid

---

#### Decision: Accessibility-First Selectors

Selector hierarchy: `getByRole()` > `getByLabel()` > `getByPlaceholder()` > `getByText()` > `getByTestId()` (last resort).

**Rationale:** Framework-Spec §4.2 (accessibility non-negotiable); Playwright best practice

**Consequence:** Tests validate real user experience (screen reader flow), not implementation details

---

#### Decision: Manual webServer (No Auto-Start)

Playwright `webServer` config commented out; developer starts Aspire + Flutter manually.

**Rationale:**
- Aspire + Flutter Web orchestration not yet implemented
- DevLoop already documented (`.\start.ps1 -Web` + `flutter run`)
- CI will need custom orchestration anyway

**Consequence:** E2E tests require manual dev-stack startup (documented in e2e/README.md)

---

#### Decision: Foundation E2E Scope = Smoke Test

2 tests only: Ping roundtrip + keyboard navigation.

**Rationale:** Foundation goal = prove stack works end-to-end; real tests later with features

**Consequence:** Full E2E coverage deferred to feature phases

---

### PDF Labeler Architecture (Issue #124, Parallel Track)

**Scope:** Library-first + GitHub Models + Confidence thresholds  
**Owner:** Stark (Architecture)  
**Status:** PROPOSED (PR #124 implementation underway)

#### Decision: Library-First Architecture

Core logic in `Sheetstorm.PdfLabeling` library (reusable for CLI/API later), not embedded in WinUI/Flutter Desktop app.

**Rationale:**
1. **Testability:** xUnit tests without UI harness (fast CI feedback)
2. **Reusability:** CLI/API scenarios require library extraction; do it upfront
3. **Contracts:** Interface-driven design forces explicit boundaries
4. **Inversion:** All I/O behind interfaces → swap implementations

**Interfaces:**
- `IPdfFirstPageRenderer` (PDF → PNG)
- `ITitleRecognizer` (PNG → Title + confidence)
- `IFileNameSanitizer` (string → safe filename)
- `IFileTargetResolver` (resolve collision-free path)
- `IProgressReporter` (UI feedback)
- `ITitleRecognizerTokenProvider` (credential management)

**Consequence:** Upfront design overhead (~3h) → parallel work possible (Rogers scaffolds, Banner implements)

---

#### Decision: GitHub Models API + Azure.AI.Inference SDK

Use GitHub Models (free tier) via `openai/gpt-4o` instead of OpenAI Direct API.

**Rationale:**
- **Cost:** Free tier sufficient for MVP (<100 PDFs/day)
- **Auth:** GitHub PAT already in user environment (no new signup)
- **Compatibility:** OpenAI-compatible API → fallback path preserved
- **SDK:** Azure.AI.Inference official Microsoft SDK (explicit GitHub support)

**Trade-offs:**
- ✅ Free tier (no credit card)
- ✅ PAT-based auth
- ✅ OpenAI fallback cheap (1–2 day refactor)
- ❌ Lower rate limits (~10–20 RPM) → slower large batches
- ❌ SDK still young (v1.x) → potential breaking changes

**Alternatives rejected:** OpenAI Direct (requires billing), Azure OpenAI (enterprise overkill), self-hosted (slow + complex)

---

#### Decision: Confidence Threshold 0.6 Floor

Minimum confidence 0.6 for acceptance; 0.8 for auto-accept; 0.6–0.8 flagged with warning.

**Rationale:**
- **Empirical:** <0.6 has ~40% error rate (hallucinations, genre labels)
- **UX:** 40% error rate erodes feature trust
- **Fallback:** Manual rename faster than auto-label + fix

**Threshold tiers:**
- ≥0.8: Auto-accept (no warning)
- 0.6–0.8: Accept with ⚠️ (human review recommended)
- <0.6: Reject (file skipped)

**Consequence:**
- ~20% files skipped in typical batch (conservative but high-quality)
- Future: User-tunable threshold (settings UI)

---

#### Decision: Tech Switch — WinUI 3 → Flutter Desktop

**Status:** ACTIVE  
**Date:** 2026-04-21  
**Owner:** Stark (Architecture Lead)

PDF Labeler UI NOT in WinUI 3 (Pepper's branch abandoned). Instead: Flutter Desktop (separate project `sheetstorm_pdf_labeler`).

**Rationale:**
- **Tooling failure:** WinUI 3 XAML compiler (MSB3073) blocked for 2+ days; root cause unresolved despite troubleshooting
- **Stack consistency:** Flutter Desktop aligns with sheetstorm_app tech stack (Framework Spec §3.4 mandate)
- **Team expertise:** Parker proven in Flutter; WinUI 3 learning curve inefficient
- **Future platform support:** Flutter Windows → macOS/Linux trivial; WinUI locked to Windows

**New Architecture:**
- `Sheetstorm.PdfLabeling` (C# library) — Core logic, unchanged, 83 tests ✅
- `Sheetstorm.PdfLabeling.Cli` (C# console) — CLI wrapper, NDJSON events on stdout (Rogers, TDD complete ✅)
- `sheetstorm_pdf_labeler` (Flutter Windows) — Desktop UI, Process.start() + stream parsing (Parker, TDD complete ✅)

**Integration Pattern:**
1. Flutter: `Process.start('Sheetstorm.PdfLabeling.Cli.exe', args, env={'SHEETSTORM_PAT': pat})`
2. CLI: Reads PAT from environment, invokes library, emits NDJSON on stdout
3. Flutter: Parses stream, updates UI state via Riverpod providers
4. Security: PAT never in argv (process list safe), encrypted at-rest via Credential Manager

**Consequence:** 
- WinUI 3 MVVM stack (above) marked SUPERSEDED (preserved for history, not deleted)
- Pepper's WinUI branch archived (code available if future need)
- Core library reusable for CLI/API without domain rework (abstraction boundaries held)

**References:**
- **Spec:** `docs/specs/mvp-pdf-labeler.md` (updated 2026-04-21)
- **CLI ADR:** `.squad/decisions/stark-cli-wrapper-pattern.md` (pattern details)
- **Flutter ADR:** `.squad/decisions/parker-flutter-cli-integration.md` (Flutter integration)
- **Issue:** #124 (triage comment https://github.com/caol-ila/Sheetstorm/issues/124#issuecomment-4284596300)

---

#### Decision: CLI-Wrapper Pattern for Flutter Desktop Integration

**Status:** ACTIVE  
**Date:** 2026-04-21  
**Owner:** Stark (Architecture Lead), Rogers (Backend)  
**Scope:** PDF Labeler (#124) — Flutter Desktop ↔ C# Library integration

Use **CLI Wrapper emitting NDJSON on stdout** as integration layer between Flutter Desktop UI and C# business logic. Avoids FFI complexity, HTTP server overhead, and unnamed pipe discovery burden.

**Rationale:**
1. **Simplicity:** `Process.start()` + `stdout.transform(LineSplitter())` in Dart; no FFI bindings, no HTTP client setup
2. **Security:** PAT via environment variable (never argv → invisible to `ps`/Task Manager)
3. **Testability:** CLI standalone testable; Flutter side mockable; E2E via golden files
4. **Progress Streaming:** NDJSON = one event per line → natural `Stream<T>` in Dart → Riverpod `StreamProvider`
5. **Cancellation:** Graceful (SIGINT) or programmatic (`--cancel-file` polling)

**Pattern Components:**

C# CLI:
- System.CommandLine for args
- Manual parsing (avoided beta for stability)
- DI: Microsoft.Extensions.DependencyInjection
- Token: `--pat-env <varname>` (e.g., `SHEETSTORM_PAT`)
- Output: NDJSON on stdout (`{"type":"progress",...}`, `{"type":"result",...}`, `{"type":"done",...}`)
- Exit codes: 0=success, 1=invalid args, 2=PAT missing, 3=I/O, ≥10=unhandled

Flutter:
- `Process.start(cliPath, args, environment: {'SHEETSTORM_PAT': pat})`
- Stream parsing: `stdout.transform(utf8.decoder).transform(LineSplitter())`
- Typed events: `ProgressEvent`, `ResultEvent`, `ErrorEvent`, `DoneEvent`
- Riverpod: `StreamProvider` for real-time updates

**Alternatives Rejected:**
- **FFI:** Complex GC/marshalling, callback pinning, debug nightmares
- **HTTP Server:** Startup overhead (~200–500ms), CORS/auth complexity, firewall prompts
- **Named Pipes:** Discovery complexity, platform variance, framing protocol needed

**Trade-offs:**

Pros:
- Simplest integration (no native code, no HTTP stack, no pipe discovery)
- Secure by default (PAT in env, isolated processes)
- Testable at every layer (CLI standalone, Flutter mocked, E2E golden)
- Real-time streaming (NDJSON → Stream<T> → Riverpod)

Cons:
- Process startup overhead (~50–100ms, acceptable for batch workload)
- No shared memory (every message serialized to JSON)
- Parsing cost (JSON decode per event)

**When to Use:**
✅ Flutter Desktop + C# library integration  
✅ Batch processing workflows (file conversion, import/export)  
✅ Progress reporting needed  
✅ PAT/secrets required  
❌ Real-time bidirectional (<10ms latency)  
❌ High-throughput binary (MB/s)  
❌ Tight loops (CLI per keystroke)

**Consequence:** NDJSON contract locked in spec; CLI tests validate contract; Flutter tests mock events

---

#### Decision: PAT Security — Environment Variable Only

**Status:** ACTIVE  
**Date:** 2026-04-21  
**Scope:** #124 (PDF Labeler MVP)

PAT (Personal Access Token) for GitHub Models API NEVER transmitted via command-line arguments. Always use environment variables or Windows Credential Manager.

**Rationale:**
- **Process List Leak:** `ps aux` or Task Manager → process command-line visible to all users (security risk)
- **History Files:** `.bash_history`, PowerShell `$PROFILE` → CLI commands logged
- **Monitoring Tools:** APM, container logs, security audits → might capture full command-line

**Pattern:**
1. Flutter reads PAT from secure storage: `flutter_secure_storage` → Windows Credential Manager (DPAPI encrypted)
2. Flutter passes PAT via environment variable only: `Process.start(..., environment: {'SHEETSTORM_PAT': pat})`
3. CLI reads: `var pat = Environment.GetEnvironmentVariable("SHEETSTORM_PAT")`
4. CLI never logs PAT, never includes in exception messages, never prints to console

**Consequence:**
- CLI: `--pat-env <varname>` option (default: `SHEETSTORM_PAT`)
- Flutter: No `--token-arg` or `--pat` arguments (design-level security)
- Tests: Mocked token provider (no real GitHub API in unit tests)

---

#### Decision: NDJSON Event Schema (CLI Contract)

**Status:** ACTIVE  
**Date:** 2026-04-21  
**Scope:** #124 (PDF Labeler MVP) — CLI stdout contract

CLI emits newline-delimited JSON (NDJSON) on stdout. Each line is a complete JSON object representing one event.

**Event Types:**

1. **Progress Event** (per file processed)
   ```json
   {"type":"progress","current":1,"total":50,"file":"example.pdf"}
   ```

2. **Result Event** (successful or skipped file)
   ```json
   {"type":"result","original":"example.pdf","renamed":"example-title.pdf","title":"Symphony No. 5","confidence":0.95,"status":"Success"}
   ```
   or
   ```json
   {"type":"result","original":"scanned.pdf","title":null,"confidence":0.0,"status":"Skipped"}
   ```

3. **Error Event** (non-fatal, processing continues)
   ```json
   {"type":"error","file":"corrupted.pdf","message":"PDF parsing failed: invalid stream"}
   ```

4. **Done Event** (final summary)
   ```json
   {"type":"done","processed":50,"succeeded":48,"skipped":2,"failed":0,"duration_ms":12500}
   ```

**Exit Codes:**
- `0`: Success (at least 1 file processed)
- `1`: Invalid arguments
- `2`: PAT missing or invalid
- `3`: I/O error (folder not found, write permission denied)
- `≥10`: Unhandled exception (bug)

**Parsing Contract:**
- UTF-8 encoded
- One event per line (LF = `\n`)
- No partial objects (Flutter must not process incomplete JSON)
- No interleaved stderr (CLI logs to stderr separately; stdout reserved for NDJSON only)

**Cancellation:**
- **Graceful:** SIGINT (Ctrl+C) → CLI emits partial `"done"` event, exits 0
- **Programmatic:** `--cancel-file <path>` → CLI polls file existence every 100ms, stops after current file, emits `"done"`

**Consequence:** Flutter tests validate event parsing; spec defines schema; CI validates contract with `echo` + pipe tests

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
