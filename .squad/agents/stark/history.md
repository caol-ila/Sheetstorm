# Stark — History

## Core Context

- **Project:** Notenmanagement-App für Blaskapellen mit Flutter-Frontend und ASP.NET Core Backend
- **Role:** Lead
- **Joined:** 2026-04-20T20:35:39.900Z

## Learnings

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
