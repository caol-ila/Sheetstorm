# Stark — History

## Core Context

- **Project:** Notenmanagement-App für Blaskapellen mit Flutter-Frontend und ASP.NET Core Backend
- **Role:** Lead
- **Joined:** 2026-04-20T20:35:39.900Z

## Learnings

### Foundation Scaffold Phase 1 + 7 — 2026-04-20

**Phase 1 (Decision Scope):**
- Documented branch strategy (feat/app-scaffold off main, not off feat/124)
- Monorepo rationale: sheetstorm_app/ subfolder aligns with Aspire orchestration
- 3-Schichten structure (src/, tests/, sheetstorm_app/) = clear separation
- Decided inbox files for operational decisions (not MADR ADRs)

**Phase 7 (README + DevLoop + PR):**
- Root README: Quick-start with `.\start.ps1 -Web` for full stack
- DevLoop guide: Local Aspire, Flutter, E2E orchestration
- PR #127 draft ready; awaits Thomas approval on 3 open design questions
- Lesson: Clear handoff documentation prevents onboarding friction

**Open Questions for Thomas:**
1. Monorepo long-term or split Flutter later?
2. Solution file in root (Rider/VS integration) or Directory.Build.props?
3. global.json SDK pin for .NET 10?

**Coordination Learnings:**
- 5 agents + 7 phases → natural parallelism (Phase 1 → Phases 2–6 parallel → Phase 7)
- Decision consolidation essential: 11 inbox files → 1 decisions.md
- Escalation grades prevent "is this done?" ambiguity

<!-- Append learnings below -->

### PDF Labeler MVP — 2026-04-20 23:15

**Interface Contracts Decided:**
- **Orchestration:** `IPdfLabelingOrchestrator` as main entry point, returns `LabelingResult[]` from `LabelingJob`
- **6 abstraction interfaces:** `IPdfFirstPageRenderer`, `ITitleRecognizer`, `IFileNameSanitizer`, `IFileTargetResolver`, `IProgressReporter`, `ITitleRecognizerTokenProvider`
- **Domain types:** All immutable records (`LabelingJob`, `LabelingResult`, `TitleRecognition`, `ProgressUpdate`)
- **Status enum:** `Success`, `SuccessWithWarning`, `Skipped`, `Error` — maps to confidence thresholds 0.8/0.6

**Key Trade-offs:**
1. **Library-first approach:** Core logic in `Sheetstorm.PdfLabeling` library enables future CLI/API reuse, at cost of upfront interface design overhead (justified for non-trivial business logic)
2. **GitHub Models vs OpenAI direct:** Free tier + PAT auth alignment vs lower rate limits → abstraction via `ITitleRecognizer` makes swap cheap
3. **Confidence threshold 0.6 floor:** Empirical 40% error rate below 0.6 → reject early, preserve trust in auto-labeling → hardcoded in MVP, future: user-tunable
4. **PdfPig vs native (MuPDF/Poppler):** Pure .NET deployment simplicity vs 2–3x perf delta → delta negligible for MVP scale (hundreds of files)

**Architecture Principles Applied:**
- **Dependency Inversion:** All external I/O (PDF, AI, filesystem, credentials) behind interfaces
- **Single Responsibility:** Each interface owns one concern (rendering ≠ recognition ≠ sanitization)
- **Fail-fast validation:** Confidence thresholds at recognition layer, not UI
- **Rate-limit at source:** Semaphore in orchestrator (max 2 parallel), not in recognizer (SRP)

**Security Design:**
- PAT stored in Windows Credential Manager only (target: `Sheetstorm.PdfLabeler.GitHubToken`)
- `ITitleRecognizerTokenProvider` abstracts CredRead API → testable without Win32 dependency
- Telemetry header redaction enforced in `ServiceDefaults` → no `Authorization` in logs/exceptions

### Triage & Status Comment Posted — 2026-04-21 00:05

**Issue:** #124 (PDF Labeler MVP)  
**Branch:** feat/124-pdf-labeler-mvp (7 commits, 83 tests ✅)

**Status Comment Scope:**
- TDD-complete library: 5 components, 83 test cases (all GREEN)
- GitHub Models AI integration confirmed (mocked in tests; real endpoint untested live)
- Deferred: Aspire AppHost, WinUI3 Desktop, WindowsCredentialTokenProvider, full integration tests

**Actions:**
- Posted triage comment via `gh issue comment 124 -F`: https://github.com/caol-ila/Sheetstorm/issues/124#issuecomment-4284426201
- Added labels: `squad:stark`, `implementation`

**Next:** Brady reviews; no PR merged until decision point.

### Tech Switch: WinUI 3 → Flutter Desktop — 2026-04-21 01:30

**Issue:** #124 (PDF Labeler MVP)  
**Branch:** feat/124-pdf-labeler-mvp  
**Commit:** bd6ad75

**Context:** Pepper's WinUI 3 implementation blocked on MSB3073 XAML compiler errors (2+ days, unresolved despite troubleshooting). Framework Spec §3.4 prioritizes Flutter for UI consistency.

**Decision:** Switch UI tech stack from WinUI 3 → Flutter Desktop (Windows).

**New Architecture:**
- **`Sheetstorm.PdfLabeling` (C# Library):** Unchanged, all 83 TDD tests remain green
- **`Sheetstorm.PdfLabeling.Cli` (C# Console):** New, Rogers-owned, exposes library via NDJSON on stdout
- **`sheetstorm_pdf_labeler` (Flutter Windows):** New, Parker-owned, Process.start() + stdout stream parsing

**Integration Pattern:**
1. Flutter UI calls `Process.start('Sheetstorm.PdfLabeling.Cli.exe', args)`
2. PAT passed via `SHEETSTORM_PAT` env var (NEVER in argv — prevents `ps` leakage)
3. CLI emits NDJSON on stdout: `{"type":"progress",...}`, `{"type":"result",...}`, `{"type":"done",...}`
4. Flutter parses stream via `stdout.transform(utf8.decoder).transform(LineSplitter())`
5. Riverpod providers (`LabelingJobProvider`, `LabelingResultsProvider`) update UI state

**CLI Contract (NDJSON):**
- **Events:** `progress` (per file), `result` (per processed file), `error` (non-fatal), `done` (final summary)
- **Exit Codes:** 0=success, 1=invalid args, 2=PAT missing, 3=I/O error, ≥10=unhandled exception
- **Cancellation:** SIGINT/Ctrl+C or `--cancel-file` polling

**Security Enhancements:**
- PAT in env var only (not argv) → prevents command-line history exposure
- Flutter reads PAT from `flutter_secure_storage` (Windows: DPAPI) or Credential Manager via FFI
- CLI never logs PAT, never includes in exception messages

**Trade-offs:**
- **Pro:** Cross-stack consistency (Flutter everywhere), team expertise (Parker), escape WinUI tooling hell
- **Pro:** Future macOS/Linux support trivial (vs. WinUI Windows-locked)
- **Con:** CLI wrapper overhead (~50–100ms startup) — acceptable for batch workload (hundreds of PDFs, minutes runtime)
- **Con:** NDJSON parsing complexity (vs. direct library integration in WinUI) — mitigated by Riverpod abstraction

**Spec Changes:**
- Updated `docs/specs/mvp-pdf-labeler.md`:
  - Tech stack table: UI → Flutter Desktop
  - Marked WinUI 3 mentions as "Superseded" (preserved for history, not deleted)
  - Added new section "Architektur: CLI-Wrapper + Flutter Desktop"
  - Added CLI-Kontrakt subsection with NDJSON event types
  - Updated File-Structure-Mapping with CLI + Flutter projects
  - Deferred Aspire orchestration for MVP

**Actions:**
- Committed spec update: `docs: update PDF Labeler spec for Flutter Desktop tech switch (#124)`
- Posted issue comment: https://github.com/caol-ila/Sheetstorm/issues/124#issuecomment-4284596300
- Rogers proceeds with CLI wrapper (System.CommandLine, NDJSON emission)
- Parker proceeds with Flutter UI (Riverpod, Process integration)
- Pepper's WinUI work paused/archived (not deleted, available if future need)

**Key Insight:** Library-first architecture paid off — core logic unchanged, only UI integration shifted. Abstraction boundaries (`IPdfLabelingOrchestrator`) enabled tech switch with zero domain logic rework.

**Risk:** CLI wrapper is new attack surface (malformed NDJSON, process spawn failures). Mitigation: comprehensive error handling in Flutter `CliService`, timeout guards on Process.start().

**Next:** Rogers delivers CLI wrapper, Parker delivers Flutter UI — parallel work, independent timelines.
