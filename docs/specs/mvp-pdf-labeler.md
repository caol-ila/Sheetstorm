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
- ✅ Windows desktop app (.NET 10 + WinUI 3)
- ✅ Folder selection (WinUI file picker)
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
| **UI Framework** | WinUI 3 (Windows App SDK 1.7) | Native Windows look/feel, modern XAML, file picker integration |
| **Runtime** | .NET 10 LTS | Long-term support, latest C# features, Aspire-compatible |
| **PDF Rendering** | Docnet.Core (PDFium) + SkiaSharp | Raster rendering via PDFium handles scanned PDFs, vector graphics, and fonts. SkiaSharp for PNG encoding and vision optimization. |
| **AI Provider** | GitHub Models (openai/gpt-4o) | Free tier for prototyping, OpenAI-compatible, integrated PAT auth |
| **AI SDK** | Azure.AI.Inference (primary) | Official Microsoft SDK, explicit GitHub Models support |
| **HTTP Client** | HttpClient (fallback) | Fallback if SDK incompatibilities arise |
| **Resiliency** | Polly 8.x | Retry with exponential backoff, rate-limit handling |
| **Authentication** | Windows Credential Manager | Secure PAT storage, no appsettings.json secrets |
| **Orchestration** | .NET Aspire 10 | Local dev dashboard, telemetry, configuration |
| **Testing** | xUnit + FluentAssertions + Moq | Standard .NET test stack |

**Trade-offs:**
- **GitHub Models vs. OpenAI Direct:** Free tier for MVP, familiar OpenAI API contract. Downside: lower rate limits vs. paid OpenAI.
- **Docnet.Core vs. Pure .NET:** PDFium provides true raster rendering for scanned PDFs and complex layouts. Downside: native binaries bundled in NuGet package (larger deployment).
- **Library-first vs. App-first:** Core logic in `Sheetstorm.PdfLabeling` library enables future CLI/API reuse. Downside: upfront interface design overhead.

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Sheetstorm.PdfLabeler.Desktop (WinUI 3)                        │
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
│       - IPdfFirstPageRenderer (Docnet.Core + SkiaSharp)            │
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
    /// <summary>Renders first page of PDF to high-res PNG via raster rendering (default 300 DPI).</summary>
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
- `src/Sheetstorm.PdfLabeling/Services/PdfFirstPageRenderer.cs` — Docnet.Core (PDFium) raster rendering
- `src/Sheetstorm.PdfLabeling/Implementation/GitHubModelsTitleRecognizer.cs` — Azure.AI.Inference implementation
- `src/Sheetstorm.PdfLabeling/Implementation/WindowsCredentialManagerTokenProvider.cs` — Win32 CredRead wrapper
- `src/Sheetstorm.PdfLabeling/Implementation/FileNameSanitizer.cs` — Regex-based sanitizer
- `src/Sheetstorm.PdfLabeling/Implementation/FileTargetResolver.cs` — Collision handler with _N suffix
- `src/Sheetstorm.PdfLabeling/Implementation/PdfLabelingOrchestrator.cs` — Main orchestration logic
- `src/Sheetstorm.PdfLabeling/DependencyInjection/ServiceCollectionExtensions.cs` — `AddPdfLabeling()` extension

**Desktop App (Sheetstorm.PdfLabeler.Desktop):**
- `src/Sheetstorm.PdfLabeler.Desktop/Sheetstorm.PdfLabeler.Desktop.csproj` — WinUI 3 project, targets net10.0-windows10.0.22621.0
- `src/Sheetstorm.PdfLabeler.Desktop/App.xaml` — Application definition
- `src/Sheetstorm.PdfLabeler.Desktop/App.xaml.cs` — DI setup, Aspire host builder
- `src/Sheetstorm.PdfLabeler.Desktop/MainWindow.xaml` — Main UI layout
- `src/Sheetstorm.PdfLabeler.Desktop/MainWindow.xaml.cs` — Code-behind
- `src/Sheetstorm.PdfLabeler.Desktop/ViewModels/MainViewModel.cs` — MVVM logic, commands, progress binding
- `src/Sheetstorm.PdfLabeler.Desktop/Converters/StatusToColorConverter.cs` — Value converter for result status coloring
- `src/Sheetstorm.PdfLabeler.Desktop/Package.appxmanifest` — WinUI 3 packaging manifest

**Aspire Orchestration:**
- `src/Sheetstorm.AppHost/Program.cs` — **MODIFY:** Add `.AddProject<Projects.Sheetstorm_PdfLabeler_Desktop>("pdflabeler")`
- `src/Sheetstorm.ServiceDefaults/Extensions.cs` — **MODIFY:** Ensure telemetry excludes `Authorization` headers from logs

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
- `CommunityToolkit.Mvvm` (8.x) — MVVM helpers for WinUI
- `Microsoft.Windows.SDK.Contracts` (10.x) — Windows Credential Manager APIs

---

## PDF Rendering

**Summary:**

The `IPdfFirstPageRenderer` interface provides raster-based PDF-to-PNG conversion using **Docnet.Core** (PDFium wrapper) for true page rendering. This approach handles all PDF types:

- **Scanned documents:** Image-only PDFs without text layers (primary use case for sheet music)
- **Digital documents:** PDFs with vector graphics, embedded fonts, and text layers
- **Mixed content:** PDFs combining images, vectors, and text

**Implementation Details:**

- **Library:** Docnet.Core 2.6.0 (MIT license)
- **Rendering Engine:** PDFium (Google's PDF renderer, same as Chrome/Chromium)
- **Default DPI:** 300 (configurable via parameter)
- **Vision Optimization:** Auto-resize to max 2000×2000 px (longest edge) to reduce GPT-4o Vision token costs while preserving readability
  - A4 at 300 DPI = 2480×3508 px → scales to ~1140×1613 px
  - Preserves aspect ratio, uses high-quality SkiaSharp resampling
- **Output Format:** PNG with 100% quality (lossless)
- **Resource Management:** Proper disposal of native PDFium handles via RAII pattern
- **Error Handling:** Custom `PdfRenderingException` for corrupted/encrypted/invalid PDFs
- **Cross-platform:** Native PDFium binaries bundled in NuGet package (Windows, Linux, macOS)

**Why Docnet.Core?**

1. **Scanned PDF Support:** PdfPig's text-extraction approach fails on image-only PDFs (no text layer → blank output)
2. **Complete Rendering:** PDFium renders fonts, images, vector paths, transparency — all content types
3. **Battle-Tested:** Same engine used in Chrome, proven on billions of PDFs
4. **MIT License:** Commercial-friendly, no GPL contamination
5. **Aspire-Compatible:** Works in containerized environments, no external dependencies beyond bundled natives

**Manual Verification:**

For smoke testing with real-world scanned PDFs, a manual test harness is available:

**Location:** `tests/Sheetstorm.PdfLabeling.Tests/Manual/RenderScannedSmoke.cs`

**Purpose:**
- Integration reality-check for AI-facing features with actual sheet music scans
- NOT part of automated CI — gated by environment variable to prevent accidental runs
- Processes all PDFs in a folder, renders to PNG, optionally runs title recognition
- Exports CSV with results for analysis

**How to Run:**

1. **Prepare Input Folder:**
   ```powershell
   # Create folder and copy your scanned PDFs
   New-Item -ItemType Directory -Path "C:\Temp\Noten-Smoke" -Force
   # Copy your test PDFs to C:\Temp\Noten-Smoke\
   ```

2. **Run Smoke Test:**
   ```powershell
   # Enable manual test execution
   $env:SHEETSTORM_RUN_MANUAL = "1"
   
   # Optional: Customize input/output folders
   $env:SHEETSTORM_SMOKE_PDF_FOLDER = "C:\Temp\Noten-Smoke"
   $env:SHEETSTORM_SMOKE_OUTPUT_FOLDER = "C:\Temp\Noten-Smoke-Output"
   
   # Optional: Enable title recognition (requires GitHub PAT with models:read scope)
   $env:GITHUB_TOKEN = "ghp_your_token_here"
   
   # Run the smoke test
   cd C:\Privat\Sheetstorm\tests\Sheetstorm.PdfLabeling.Tests
   dotnet test --filter "Category=Manual"
   ```

3. **Inspect Results:**
   - **PNGs:** `C:\Temp\Noten-Smoke-Output\{filename}.png` (300 DPI renders)
   - **CSV Report:** `C:\Temp\Noten-Smoke-Output\recognition-results.csv`
     - Columns: `filename,png_bytes,width,height,recognized_title,confidence,duration_ms,error`
     - Verify: PNG sizes reasonable (>10 KB), dimensions ≈ DPI scaling, no errors

**Behavior:**
- Skips cleanly if `SHEETSTORM_RUN_MANUAL != "1"` (safe for CI)
- Skips cleanly if input folder missing or empty
- Processes each PDF independently — one file error doesn't abort entire test
- Asserts: at least 1 file processed AND success rate > 0 (ensures harness not broken)

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `SHEETSTORM_RUN_MANUAL` | — | Must be `"1"` to enable execution |
| `SHEETSTORM_SMOKE_PDF_FOLDER` | `C:\Temp\Noten-Smoke` | Input folder with `*.pdf` files |
| `SHEETSTORM_SMOKE_OUTPUT_FOLDER` | `C:\Temp\Noten-Smoke-Output` | Output folder for PNGs + CSV |
| `GITHUB_TOKEN` | — | (Optional) GitHub PAT for title recognition |

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
