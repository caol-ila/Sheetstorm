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

