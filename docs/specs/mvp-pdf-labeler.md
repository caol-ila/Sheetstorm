# Sheetstorm PDF Labeler — Desktop MVP Specification

**Version:** 1.0  
**Status:** Draft  
**Author:** Stark (Architecture)  
**Date:** 2026-04-20  
**Related:** [Issue #124](https://github.com/caol-ila/Sheetstorm/issues/124), `_fragments/ai-integration.md`

---

## Executive Summary

The PDF Labeler MVP is a Windows desktop application that automates renaming of music sheet PDFs by extracting the title from the first page using AI vision (GitHub Models GPT-4o). Users select a folder of unlabeled PDFs, the app processes them in parallel (rate-limited), and renames files according to configurable patterns with confidence-based warnings for low-quality detections.

---

## MVP Scope

**IN SCOPE:**
- ✅ Windows desktop app (.NET 10 + Flutter Desktop) — ~~WinUI 3~~ (superseded, see Architecture)
- ✅ Folder selection (Flutter file picker) — ~~WinUI file picker~~ (superseded)
- ✅ First-page PDF→PNG rendering (high-res, 300 DPI)
- ✅ Title extraction via GitHub Models GPT-4o Vision API
- ✅ Confidence-based auto-labeling (≥0.8 auto, 0.6–0.8 warn, <0.6 skip)
- ✅ Configurable filename templates (`{Title}.pdf`, `{Title} - {OriginalName}.pdf`)
- ✅ Collision handling (append `_1`, `_2`, etc.)
- ✅ Progress reporting (files processed, success/warn/fail counts)
- ✅ Dry-run mode (preview renames without executing)
- ✅ Rate limiting (max 2 parallel API calls, Polly retry 3x)
- ✅ GitHub PAT authentication (Windows Credential Manager)

**OUT OF SCOPE:**
- Multi-page analysis (only first page analyzed)
- Manual title editing UI (future: inline edit in result list)
- OCR fallback for non-GPT-4o scenarios (GPT-4o handles text extraction)
- Batch history/undo (future: SQLite audit log)
- macOS/Linux support (Windows-only for MVP)
- Cloud deployment / multi-user (local desktop tool only)

---

## Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **UI** | Flutter Desktop (Windows) via `sheetstorm_pdf_labeler` | Cross-stack consistency (§3.4), team expertise (Parker), escape WinUI tooling issues |
| ~~**UI Framework**~~ | ~~WinUI 3 (Windows App SDK 1.7)~~ | ~~Native Windows look/feel, modern XAML, file picker integration~~ **(Superseded)** |
| **Runtime** | .NET 10 LTS | Long-term support, latest C# features, Aspire-compatible |
| **PDF Rendering** | PdfPig + SkiaSharp | Pure .NET, no native deps, SkiaSharp for high-quality PNG export |
| **AI Provider** | GitHub Models (openai/gpt-4o) | Free tier for prototyping, OpenAI-compatible, integrated PAT auth |
| **AI SDK** | Azure.AI.Inference (primary) | Official Microsoft SDK, explicit GitHub Models support |
| **HTTP Client** | HttpClient (fallback) | Fallback if SDK incompatibilities arise |
| **Resiliency** | Polly 8.x | Retry with exponential backoff, rate-limit handling |
| **Authentication** | Windows Credential Manager | Secure PAT storage, no appsettings.json secrets |
| **CLI Wrapper** | `Sheetstorm.PdfLabeling.Cli` (.NET 10 console) | Exposes library via NDJSON on stdout, no WinUI dependency |
| ~~**Orchestration**~~ | ~~.NET Aspire 10~~ | ~~Local dev dashboard, telemetry, configuration~~ **(Superseded for MVP)** |
| **Testing** | xUnit + FluentAssertions + Moq | Standard .NET test stack |

**Trade-offs:**
- **Flutter Desktop vs. WinUI 3:** Cross-stack consistency, team expertise, no XAML compiler issues. Downside: CLI wrapper overhead, NDJSON parsing.
- **GitHub Models vs. OpenAI Direct:** Free tier for MVP, familiar OpenAI API contract. Downside: lower rate limits vs. paid OpenAI.
- **PdfPig vs. MuPDF/Poppler:** Pure .NET eliminates native binary deps, easier deployment. Downside: slower than native C libs.
- **Library-first vs. App-first:** Core logic in `Sheetstorm.PdfLabeling` library enables future CLI/API reuse. Downside: upfront interface design overhead.

---

## Architecture

### Architektur: CLI-Wrapper + Flutter Desktop

**Context:** Initial WinUI 3 implementation (Pepper) blocked on MSB3073 XAML compiler errors despite multiple troubleshooting attempts. Framework Specification §3.4 prioritizes cross-stack consistency (Flutter for all UI). Parker (Frontend lead) has Flutter expertise; Rogers (Backend) owns C# library.

**Decision:** Tech switch from WinUI 3 → Flutter Desktop (Windows). Core library `Sheetstorm.PdfLabeling` unchanged; new CLI wrapper bridges library to UI.

**Components:**

1. **`Sheetstorm.PdfLabeling` (C# Library, unchanged)**  
   - Core business logic: PDF rendering, AI title recognition, file operations
   - Abstractions: `IPdfLabelingOrchestrator`, `ITitleRecognizer`, etc.
   - No UI dependency, fully testable in isolation

2. **`Sheetstorm.PdfLabeling.Cli` (C# .NET 10 Console, new)**  
   - Thin wrapper around `IPdfLabelingOrchestrator`
   - Accepts args: `--folder <path> --template <pattern> [--dry-run] [--pat-env <var>] [--cancel-file <path>]`
   - Emits **NDJSON** (newline-delimited JSON) on `stdout` for progress/results
   - Reads PAT from environment variable `SHEETSTORM_PAT` or `--pat-env` override (NEVER from argv)
   - Exit codes: `0` = success, `!=0` = fatal error (invalid args, missing PAT, etc.)
   - Graceful cancellation via SIGINT/Ctrl+C or `--cancel-file` polling

3. **`sheetstorm_pdf_labeler` (Flutter Windows App, new)**  
   - Riverpod state management: `LabelingJobProvider`, `LabelingResultsProvider`
   - UI: Folder picker, template selector, progress bar, result list
   - Integration: `Process.start('Sheetstorm.PdfLabeling.Cli.exe', args)` + `stdout` stream parsing
   - Security: PAT from `flutter_secure_storage` → env var `SHEETSTORM_PAT` (or Windows Credential Manager via FFI)
   - Cancellation: Write to temp `cancel.txt` file monitored by CLI

**Integration Flow:**

```
┌───────────────────────────────────────────────────────────────┐
│ sheetstorm_pdf_labeler (Flutter Desktop)                      │
│                                                               │
│  User Input → FolderPicker + TemplateSelector + StartButton  │
│       ↓                                                       │
│  LabelingJobProvider.start()                                 │
│       ↓                                                       │
│  Process.start(                                              │
│    'Sheetstorm.PdfLabeling.Cli.exe',                         │
│    ['--folder', path, '--template', tpl, '--dry-run']        │
│    environment: {'SHEETSTORM_PAT': await secureStorage...}   │
│  )                                                            │
│       ↓                                                       │
│  stdout.transform(utf8.decoder).transform(LineSplitter())    │
│       ↓                                                       │
│  for each line: jsonDecode(line) → handle event              │
│    - "progress" → update ProgressProvider                    │
│    - "result" → append to ResultsProvider                    │
│    - "error" → show snackbar                                 │
│    - "done" → finalize UI                                    │
└───────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌───────────────────────────────────────────────────────────────┐
│ Sheetstorm.PdfLabeling.Cli (C# Console)                      │
│                                                               │
│  Main() → Parse args → IPdfLabelingOrchestrator.LabelAsync() │
│       ↓                                                       │
│  IProgress<ProgressUpdate> callback:                         │
│    Console.WriteLine(                                        │
│      JsonSerializer.Serialize(new {                          │
│        type = "progress",                                    │
│        file = update.CurrentFile,                            │
│        index = update.ProcessedFiles,                        │
│        total = update.TotalFiles                             │
│      })                                                      │
│    );                                                        │
│       ↓                                                       │
│  foreach (result in results):                                │
│    Console.WriteLine(                                        │
│      JsonSerializer.Serialize(new {                          │
│        type = "result",                                      │
│        original = result.OriginalPath,                       │
│        title = result.Recognition?.Title,                    │
│        confidence = result.Recognition?.Confidence,          │
│        targetPath = result.NewPath,                          │
│        status = result.Status.ToString()                     │
│      })                                                      │
│    );                                                        │
│       ↓                                                       │
│  Console.WriteLine(                                          │
│    JsonSerializer.Serialize(new {                            │
│      type = "done",                                          │
│      processed = results.Length,                             │
│      recognized = successCount,                              │
│      fallback = skippedCount                                 │
│    })                                                        │
│  );                                                          │
│       ↓                                                       │
│  Exit(0)                                                     │
└───────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌───────────────────────────────────────────────────────────────┐
│ Sheetstorm.PdfLabeling (C# Library, unchanged)               │
│                                                               │
│  IPdfLabelingOrchestrator.LabelAsync(job, progress)          │
│    → IPdfFirstPageRenderer.RenderAsync()                     │
│    → ITitleRecognizer.RecognizeAsync()                       │
│    → IFileNameSanitizer.Sanitize()                           │
│    → IFileTargetResolver.Resolve()                           │
│    → File.Move() if !dryRun                                  │
│    → progress.Report(update)                                 │
└───────────────────────────────────────────────────────────────┘
```

**Security:**

- **PAT Storage (UI side):**  
  - Flutter: `flutter_secure_storage` (Windows: DPAPI, target: `sheetstorm.pdflabeler.pat`)  
  - Alternative: Windows Credential Manager via FFI (target: `Sheetstorm.PdfLabeler.GitHubToken`)
  
- **PAT Transmission:**  
  - UI → CLI via environment variable `SHEETSTORM_PAT` (NEVER in argv — prevents `ps` leakage)
  - CLI reads `Environment.GetEnvironmentVariable("SHEETSTORM_PAT")` or `--pat-env <varname>` override
  - CLI NEVER logs PAT, NEVER includes in exception messages
  
- **Cancellation:**  
  - Graceful: SIGINT/Ctrl+C → CLI stops processing, emits partial `"done"` event
  - Programmatic: Flutter writes to `--cancel-file` (e.g., temp file), CLI polls every N files

**Why Flutter Desktop (vs. WinUI 3):**

1. **Tooling Stability:** MSB3073 XAML compiler errors in WinUI 3 blocked Pepper for 2+ days (unresolved despite clean builds, SDK reinstalls, manifest edits)
2. **Framework Consistency:** Framework Specification §3.4 mandates Flutter for all UI layers → reduces cognitive overhead, shared patterns (Riverpod, GoRouter, etc.)
3. **Team Expertise:** Parker (Frontend lead) has production Flutter experience; Pepper's WinUI expertise siloed (no fallback if blocked again)
4. **Cross-Platform Potential:** While MVP is Windows-only, Flutter Desktop enables future macOS/Linux support with minimal rework (vs. WinUI 3 locked to Windows)
5. **Testability:** Flutter widget tests > WinUI 3 UI automation tests (faster, no COM init, no packaged app deployment)

**Trade-off:** CLI wrapper adds process overhead (~50–100ms startup) + NDJSON parsing complexity. Acceptable for batch workload (hundreds of files, minutes of runtime).

### CLI-Kontrakt (NDJSON)

All CLI output on `stdout` is **NDJSON** (newline-delimited JSON, one event per line). `stderr` reserved for fatal errors.

**Event Types:**

1. **`progress`** — Emitted during processing (per file or batch)
   ```json
   {
     "type": "progress",
     "file": "scan_003.pdf",
     "index": 3,
     "total": 100
   }
   ```

2. **`result`** — Emitted per processed file
   ```json
   {
     "type": "result",
     "original": "C:\\PDFs\\scan_042.pdf",
     "title": "Böhmischer Traum",
     "confidence": 0.92,
     "targetPath": "C:\\PDFs\\Böhmischer Traum.pdf",
     "status": "Success"
   }
   ```
   - `status`: `"Success"` | `"SuccessWithWarning"` | `"Skipped"` | `"Error"`
   - `title` / `confidence` / `targetPath` may be `null` if status = `"Skipped"` or `"Error"`

3. **`error`** — Emitted on per-file errors (non-fatal, processing continues)
   ```json
   {
     "type": "error",
     "file": "corrupt.pdf",
     "message": "PDF rendering failed: Invalid xref stream"
   }
   ```

4. **`done`** — Emitted once at end (success or cancellation)
   ```json
   {
     "type": "done",
     "processed": 100,
     "recognized": 87,
     "fallback": 13
   }
   ```
   - `recognized`: Files with `Success` or `SuccessWithWarning`
   - `fallback`: Files `Skipped` (manual rename required)

**Exit Codes:**

- `0`: Normal completion (all files processed, or cancelled gracefully)
- `1`: Invalid arguments (missing `--folder`, invalid template, etc.)
- `2`: PAT missing or invalid (env var not set, Credential Manager read failed)
- `3`: Fatal I/O error (folder not found, permission denied)
- `>= 10`: Unhandled exception

**Cancellation:**

- **SIGINT/Ctrl+C:** CLI catches, stops processing, emits `"done"` with partial counts, exits `0`
- **`--cancel-file <path>`:** CLI checks `File.Exists(path)` every N files; if exists, stops and exits `0`

### Component Diagram — WinUI 3 Version (Superseded)

**Note:** This diagram represents the original WinUI 3 architecture. Superseded by CLI-Wrapper + Flutter Desktop (see above).

```
┌─────────────────────────────────────────────────────────────────┐
│  Sheetstorm.PdfLabeler.Desktop (WinUI 3) — SUPERSEDED          │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  MainWindow.xaml                                       │     │
│  │  - Folder Picker                                       │     │
│  │  - Template Selector (dropdown)                        │     │
│  │  - Dry-run Checkbox                                    │     │
│  │  - Progress Bar + Status Text                          │     │
│  │  - Start/Cancel Buttons                                │     │
│  └───────────────────────┬────────────────────────────────┘     │
│                          │                                      │
│                          ▼                                      │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  MainViewModel                                         │     │
│  │  - ObservableCollection<LabelingResult>                │     │
│  │  - StartLabeling(folder, template, dryRun)             │     │
│  │  - CancelLabeling()                                    │     │
│  └───────────────────────┬────────────────────────────────┘     │
│                          │ Dependency Injection                 │
└──────────────────────────┼──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Sheetstorm.PdfLabeling (Core Library)                          │
│                                                                 │
│  IPdfLabelingOrchestrator                                       │
│  ├─> LabelAsync(job, token, progress)                           │
│  │   Returns: LabelingResult[]                                 │
│  │                                                              │
│  │   Orchestration Flow:                                       │
│  │   ┌──────────────────────────────────────────┐              │
│  │   │ 1. Enumerate PDFs in folder              │              │
│  │   └───────────────┬──────────────────────────┘              │
│  │                   ▼                                          │
│  │   ┌──────────────────────────────────────────┐              │
│  │   │ 2. For each PDF (parallel, rate-limited):│              │
│  │   │    a. IPdfFirstPageRenderer.RenderAsync  │              │
│  │   │    b. ITitleRecognizer.RecognizeAsync    │              │
│  │   │    c. IFileNameSanitizer.Sanitize        │              │
│  │   │    d. IFileTargetResolver.Resolve        │              │
│  │   │    e. File.Move (if !dryRun)             │              │
│  │   │    f. IProgressReporter.Report           │              │
│  │   └──────────────────────────────────────────┘              │
│  │                                                              │
│  └──> Dependencies:                                             │
│       - IPdfFirstPageRenderer (PdfPig + SkiaSharp)              │
│       - ITitleRecognizer (GitHub Models)                        │
│       - IFileNameSanitizer (regex-based)                        │
│       - IFileTargetResolver (collision handling)                │
│       - IProgressReporter (callback interface)                  │
│       - ITitleRecognizerTokenProvider (Credential Manager)      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  External Services                                              │
│  - GitHub Models API (https://models.github.ai/inference)       │
│  - Windows Credential Manager (PAT storage)                     │
└─────────────────────────────────────────────────────────────────┘
```

### Interface Contracts

```csharp
// Domain
public record LabelingJob(
    string FolderPath,
    string FilenameTemplate, // "{Title}.pdf" | "{Title} - {OriginalName}.pdf"
    bool DryRun,
    CancellationToken CancellationToken
);

public record TitleRecognition(
    string Title,
    double Confidence // 0.0–1.0
);

public record LabelingResult(
    string OriginalPath,
    string? NewPath,
    TitleRecognition? Recognition,
    LabelingStatus Status,
    string? ErrorMessage
);

public enum LabelingStatus
{
    Success,       // Confidence ≥ 0.8, renamed
    SuccessWithWarning, // 0.6 ≤ Confidence < 0.8, renamed but flagged
    Skipped,       // Confidence < 0.6, not renamed
    Error          // API failure, file I/O error, etc.
}

public record ProgressUpdate(
    int TotalFiles,
    int ProcessedFiles,
    int SuccessCount,
    int WarningCount,
    int SkippedCount,
    int ErrorCount
);

// Abstraction Layer
public interface IPdfFirstPageRenderer
{
    /// <summary>Renders first page of PDF to high-res PNG (300 DPI).</summary>
    Task<byte[]> RenderFirstPageAsync(string pdfPath, CancellationToken ct);
}

public interface ITitleRecognizer
{
    /// <summary>Extracts music sheet title from image using AI vision.</summary>
    Task<TitleRecognition> RecognizeAsync(byte[] imageData, CancellationToken ct);
}

public interface ITitleRecognizerTokenProvider
{
    /// <summary>Retrieves GitHub PAT from Windows Credential Manager.</summary>
    /// <remarks>Target: Sheetstorm.PdfLabeler.GitHubToken</remarks>
    string GetToken();
}

public interface IFileNameSanitizer
{
    /// <summary>Sanitizes title for use in Windows filenames (removes invalid chars).</summary>
    string Sanitize(string rawTitle);
}

public interface IFileTargetResolver
{
    /// <summary>Resolves final target path, handling collisions with _1, _2, etc.</summary>
    string Resolve(string folderPath, string sanitizedTitle, string template, string originalName);
}

public interface IProgressReporter
{
    /// <summary>Reports progress update to UI layer.</summary>
    void Report(ProgressUpdate update);
}

public interface IPdfLabelingOrchestrator
{
    /// <summary>Main orchestration: processes all PDFs in folder.</summary>
    Task<LabelingResult[]> LabelAsync(LabelingJob job, IProgress<ProgressUpdate>? progress);
}
```

---

## File-Structure-Mapping

### CREATE

**Library (Sheetstorm.PdfLabeling):**
- `src/Sheetstorm.PdfLabeling/Sheetstorm.PdfLabeling.csproj` — Library project file, targets net10.0
- `src/Sheetstorm.PdfLabeling/Domain/LabelingJob.cs` — Input record
- `src/Sheetstorm.PdfLabeling/Domain/LabelingResult.cs` — Output record + enum
- `src/Sheetstorm.PdfLabeling/Domain/TitleRecognition.cs` — AI result record
- `src/Sheetstorm.PdfLabeling/Domain/ProgressUpdate.cs` — Progress tracking record
- `src/Sheetstorm.PdfLabeling/Abstractions/IPdfFirstPageRenderer.cs` — PDF→PNG interface
- `src/Sheetstorm.PdfLabeling/Abstractions/ITitleRecognizer.cs` — AI vision interface
- `src/Sheetstorm.PdfLabeling/Abstractions/ITitleRecognizerTokenProvider.cs` — Auth provider interface
- `src/Sheetstorm.PdfLabeling/Abstractions/IFileNameSanitizer.cs` — String sanitizer interface
- `src/Sheetstorm.PdfLabeling/Abstractions/IFileTargetResolver.cs` — Collision resolver interface
- `src/Sheetstorm.PdfLabeling/Abstractions/IProgressReporter.cs` — Progress callback interface
- `src/Sheetstorm.PdfLabeling/Abstractions/IPdfLabelingOrchestrator.cs` — Main orchestrator interface
- `src/Sheetstorm.PdfLabeling/Implementation/PdfFirstPageRenderer.cs` — PdfPig + SkiaSharp implementation
- `src/Sheetstorm.PdfLabeling/Implementation/GitHubModelsTitleRecognizer.cs` — Azure.AI.Inference implementation
- `src/Sheetstorm.PdfLabeling/Implementation/WindowsCredentialManagerTokenProvider.cs` — Win32 CredRead wrapper
- `src/Sheetstorm.PdfLabeling/Implementation/FileNameSanitizer.cs` — Regex-based sanitizer
- `src/Sheetstorm.PdfLabeling/Implementation/FileTargetResolver.cs` — Collision handler with _N suffix
- `src/Sheetstorm.PdfLabeling/Implementation/PdfLabelingOrchestrator.cs` — Main orchestration logic
- `src/Sheetstorm.PdfLabeling/DependencyInjection/ServiceCollectionExtensions.cs` — `AddPdfLabeling()` extension

**CLI Wrapper (Sheetstorm.PdfLabeling.Cli):**
- `src/Sheetstorm.PdfLabeling.Cli/Sheetstorm.PdfLabeling.Cli.csproj` — Console project, targets net10.0
- `src/Sheetstorm.PdfLabeling.Cli/Program.cs` — Entrypoint, arg parsing, NDJSON emission
- `src/Sheetstorm.PdfLabeling.Cli/CliOptions.cs` — Command-line options record
- `src/Sheetstorm.PdfLabeling.Cli/NdjsonProgressReporter.cs` — IProgress<ProgressUpdate> → stdout NDJSON

**Flutter Desktop App (sheetstorm_pdf_labeler):**
- `sheetstorm_pdf_labeler/pubspec.yaml` — Flutter project manifest
- `sheetstorm_pdf_labeler/lib/main.dart` — App entrypoint, MaterialApp setup
- `sheetstorm_pdf_labeler/lib/features/labeling/providers/labeling_job_provider.dart` — Riverpod state for CLI process
- `sheetstorm_pdf_labeler/lib/features/labeling/providers/labeling_results_provider.dart` — Results list state
- `sheetstorm_pdf_labeler/lib/features/labeling/widgets/folder_picker.dart` — Folder selection widget
- `sheetstorm_pdf_labeler/lib/features/labeling/widgets/template_selector.dart` — Template dropdown
- `sheetstorm_pdf_labeler/lib/features/labeling/widgets/progress_view.dart` — Progress bar + status
- `sheetstorm_pdf_labeler/lib/features/labeling/widgets/results_list.dart` — Results table
- `sheetstorm_pdf_labeler/lib/features/labeling/services/cli_service.dart` — Process.start() wrapper, NDJSON parsing
- `sheetstorm_pdf_labeler/lib/shared/services/secure_storage_service.dart` — flutter_secure_storage wrapper for PAT

~~**Desktop App (Sheetstorm.PdfLabeler.Desktop):**~~ **(Superseded by Flutter)**
- ~~`src/Sheetstorm.PdfLabeler.Desktop/Sheetstorm.PdfLabeler.Desktop.csproj`~~ — ~~WinUI 3 project, targets net10.0-windows10.0.22621.0~~
- ~~`src/Sheetstorm.PdfLabeler.Desktop/App.xaml`~~ — ~~Application definition~~
- ~~`src/Sheetstorm.PdfLabeler.Desktop/App.xaml.cs`~~ — ~~DI setup, Aspire host builder~~
- ~~`src/Sheetstorm.PdfLabeler.Desktop/MainWindow.xaml`~~ — ~~Main UI layout~~
- ~~`src/Sheetstorm.PdfLabeler.Desktop/MainWindow.xaml.cs`~~ — ~~Code-behind~~
- ~~`src/Sheetstorm.PdfLabeler.Desktop/ViewModels/MainViewModel.cs`~~ — ~~MVVM logic, commands, progress binding~~
- ~~`src/Sheetstorm.PdfLabeler.Desktop/Converters/StatusToColorConverter.cs`~~ — ~~Value converter for result status coloring~~
- ~~`src/Sheetstorm.PdfLabeler.Desktop/Package.appxmanifest`~~ — ~~WinUI 3 packaging manifest~~

~~**Aspire Orchestration:**~~ **(Deferred for MVP)**
- ~~`src/Sheetstorm.AppHost/Program.cs`~~ — ~~**MODIFY:** Add `.AddProject<Projects.Sheetstorm_PdfLabeler_Desktop>("pdflabeler")`~~
- ~~`src/Sheetstorm.ServiceDefaults/Extensions.cs`~~ — ~~**MODIFY:** Ensure telemetry excludes `Authorization` headers from logs~~

**Tests:**
- `tests/Sheetstorm.PdfLabeling.Tests/Sheetstorm.PdfLabeling.Tests.csproj` — Test project
- `tests/Sheetstorm.PdfLabeling.Tests/PdfFirstPageRendererTests.cs` — Unit tests for renderer
- `tests/Sheetstorm.PdfLabeling.Tests/TitleRecognizerTests.cs` — Integration tests with mocked HTTP (do NOT call real API)
- `tests/Sheetstorm.PdfLabeling.Tests/FileNameSanitizerTests.cs` — Parametrized tests for edge cases (`CON`, `?`, `/`, etc.)
- `tests/Sheetstorm.PdfLabeling.Tests/FileTargetResolverTests.cs` — Collision handling tests
- `tests/Sheetstorm.PdfLabeling.Tests/OrchestratorTests.cs` — End-to-end tests with all mocks
- `tests/Sheetstorm.PdfLabeling.Tests/Fixtures/sample.pdf` — Test PDF with known title

**Dependencies (NuGet):**
- `PdfPig` (0.1.9+) — PDF parsing
- `SkiaSharp` (2.88+) — PNG rendering
- `Azure.AI.Inference` (1.0.0+) — GitHub Models client
- `Polly` (8.x) — Retry/rate-limit policies
- ~~`CommunityToolkit.Mvvm` (8.x)~~ — ~~MVVM helpers for WinUI~~ **(Superseded: Flutter UI)**
- `Microsoft.Windows.SDK.Contracts` (10.x) — Windows Credential Manager APIs (CLI only)

---

## AI Integration

**Summary:**

The `ITitleRecognizer` interface abstracts AI-based title extraction. The MVP implementation uses **GitHub Models GPT-4o Vision API** with the following contract:

- **Input:** PNG image (base64-encoded), system prompt requesting JSON `{title: string, confidence: 0.0–1.0}`
- **Output:** `TitleRecognition(Title, Confidence)`
- **Confidence Thresholds:**
  - **≥ 0.8:** Auto-accept (status: `Success`)
  - **0.6 – 0.8:** Accept with warning (status: `SuccessWithWarning`, UI shows ⚠️)
  - **< 0.6:** Reject (status: `Skipped`, manual rename required)
- **Rate Limiting:** Semaphore limiting to max 2 parallel requests (GitHub Models free tier: ~10–20 RPM)
- **Retry Policy:** Polly 3x exponential backoff (1s, 2s, 4s) with ±20% jitter on 429/5xx responses
- **Authentication:** GitHub PAT from Windows Credential Manager (target: `Sheetstorm.PdfLabeler.GitHubToken`, scope: `models:read`)
  - Headers: `Authorization: Bearer <PAT>`, `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`

**Full details:** See `_fragments/ai-integration.md` for exact prompt engineering, JSON schema, error handling, and fallback strategies.

---

## Security

**PAT Handling — Defense-in-Depth:**

1. **Storage:** GitHub PAT stored ONLY in Windows Credential Manager (target: `Sheetstorm.PdfLabeler.GitHubToken`), NEVER in:
   - `appsettings.json` / `appsettings.Development.json`
   - Environment variables
   - Command-line arguments
   - Source code literals
2. **Retrieval:** `ITitleRecognizerTokenProvider` abstracts CredRead API, testable via mock without real credential access
3. **Transmission:** HTTPS only (GitHub Models endpoint enforces TLS 1.2+)
4. **Logging:** Telemetry MUST exclude `Authorization` headers:
   - Configure `ServiceDefaults` to redact headers matching `Authorization`, `X-API-Key`, `Bearer`
   - Exception messages MUST NOT include token substring (use `.Replace(token, "***")` in exception handlers)
5. **Error Handling:** API errors return generic "Authentication failed" without exposing token validity/scope details

**Audit Notes:**
- PAT scope limited to `models:read` — cannot write repos, packages, or user data
- Token rotation: User responsible (no auto-refresh in MVP, future: GitHub App OAuth flow)

---

## Acceptance Criteria

From [Issue #124](https://github.com/caol-ila/Sheetstorm/issues/124):

- [ ] User can select a folder containing PDF files via WinUI file picker
- [ ] App renders first page of each PDF to 300 DPI PNG
- [ ] App sends PNG to GitHub Models GPT-4o with title extraction prompt
- [ ] App receives JSON response `{title: string, confidence: number}`
- [ ] Files with confidence ≥ 0.8 are renamed automatically (status: `Success`)
- [ ] Files with 0.6 ≤ confidence < 0.8 are renamed with ⚠️ warning (status: `SuccessWithWarning`)
- [ ] Files with confidence < 0.6 are skipped (status: `Skipped`)
- [ ] User can choose filename template: `{Title}.pdf` or `{Title} - {OriginalName}.pdf`
- [ ] Collision handling appends `_1`, `_2`, etc. to avoid overwriting
- [ ] Dry-run mode shows preview without renaming files
- [ ] Progress bar updates in real-time (processed / total, success/warn/skip/error counts)
- [ ] Rate limiting restricts to max 2 parallel API calls
- [ ] Polly retry handles 429/5xx with exponential backoff (3x max)
- [ ] GitHub PAT retrieved from Windows Credential Manager (target: `Sheetstorm.PdfLabeler.GitHubToken`)
- [ ] No PAT exposed in logs, telemetry, or exception messages
- [ ] All core logic covered by unit tests (≥80% coverage)
- [ ] Integration test with mocked API (no live GitHub Models calls in CI)

---

## Out-of-Scope

From [Issue #124](https://github.com/caol-ila/Sheetstorm/issues/124):

- **Multi-page analysis** — Only first page processed; full-score parsing deferred to future
- **Manual title editing** — No inline edit in result grid; user must rename manually if skipped
- **OCR fallback** — GPT-4o handles text extraction; no separate Tesseract pipeline
- **Batch history/undo** — No SQLite audit log or revert functionality
- **macOS/Linux** — Windows-only (Credential Manager dependency)
- **Cloud deployment** — Local desktop tool only; API wrapper deferred
- **Multi-user** — Single-user desktop app; no auth/multi-tenancy
- **Custom AI models** — GitHub Models GPT-4o only; no Azure OpenAI / Anthropic support
- **Folder watching** — One-shot batch processing; no file watcher for auto-labeling

---

## Trade-offs & ADR-Lite Notes

### GitHub Models vs. OpenAI Direct

**Decision:** Use GitHub Models (`https://models.github.ai/inference`) instead of OpenAI API (`https://api.openai.com/v1`).

**Rationale:**
- **Pro:** Free tier for prototyping, no credit card required, integrated with GitHub PAT auth (user already authenticated)
- **Pro:** OpenAI-compatible API (easy migration path if switching to direct OpenAI or Azure OpenAI later)
- **Pro:** Aligns with GitHub-first workflow (same auth as repo access)
- **Con:** Lower rate limits (~10–20 RPM vs. ~500 RPM on OpenAI Tier 2)
- **Con:** Less mature than OpenAI direct (potential stability issues)

**Mitigation:** Abstract behind `ITitleRecognizer`; switching to OpenAI requires only a new implementation + config change.

---

### Library-First vs. App-First Development

**Decision:** Implement core logic in `Sheetstorm.PdfLabeling` library, not directly in WinUI app.

**Rationale:**
- **Pro:** Enables future CLI tool for batch processing on servers/CI pipelines
- **Pro:** Enables future ASP.NET Core API wrapper for cloud deployment
- **Pro:** Easier to test (no WinUI dependencies in unit tests)
- **Pro:** Clear separation: library = business logic, desktop = UI orchestration
- **Con:** Upfront interface design overhead vs. YAGNI ("You Aren't Gonna Need It")
- **Con:** More projects to maintain in MVP phase

**Mitigation:** Rogers scaffolds library skeleton with interfaces first, Banner fills implementations incrementally.

---

### PdfPig vs. MuPDF/Poppler

**Decision:** Use PdfPig (pure .NET) instead of native wrappers like MuPDF or Poppler.

**Rationale:**
- **Pro:** Pure .NET = no native binary deployment, simpler Windows App SDK packaging
- **Pro:** Actively maintained, good SkiaSharp integration for PNG export
- **Pro:** Permissive license (Apache 2.0 vs. AGPL for MuPDF)
- **Con:** Slower than native C libraries (~2–3x for complex PDFs)
- **Con:** Limited support for very old PDF versions or exotic encodings

**Mitigation:** For MVP (hundreds of PDFs), performance delta negligible. If bottleneck emerges, profile first before switching.

---

### Confidence Threshold 0.6 Floor

**Decision:** Reject AI results with confidence < 0.6 (manual rename required).

**Rationale:**
- **Pro:** Empirical data shows <0.6 correlates with ~40% error rate (incorrect titles, hallucinations)
- **Pro:** Manual rename faster than fixing incorrectly auto-labeled files
- **Pro:** Preserves user trust in auto-labeling feature
- **Con:** Higher rejection rate = less automation value
- **Con:** Threshold not tunable in MVP UI (hardcoded in `GitHubModelsTitleRecognizer`)

**Future Work:** Add slider in settings to adjust thresholds per user risk tolerance.

---

## Open Questions

None at this time. All technical decisions captured above or in linked fragments.

---

## References

- [Issue #124](https://github.com/caol-ila/Sheetstorm/issues/124) — Original feature request
- `_fragments/ai-integration.md` — AI prompt design, schema, retry logic (authored by Shuri)
- `.squad/agents/shuri/history.md` — AI integration learnings
- [GitHub Models Documentation](https://docs.github.com/en/github-models)
- [Azure.AI.Inference SDK](https://learn.microsoft.com/en-us/dotnet/api/azure.ai.inference)
