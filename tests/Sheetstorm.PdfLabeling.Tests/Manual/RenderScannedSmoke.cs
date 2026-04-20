using System.Diagnostics;
using System.Globalization;
using System.Text;
using FluentAssertions;
using Sheetstorm.PdfLabeling.Abstractions;
using Sheetstorm.PdfLabeling.Services;
using SkiaSharp;
using Xunit;

namespace Sheetstorm.PdfLabeling.Tests.Manual;

/// <summary>
/// Manual smoke test harness for verifying PdfFirstPageRenderer against real-world scanned PDFs.
/// NOT part of the automated test suite — run explicitly with SHEETSTORM_RUN_MANUAL=1.
/// </summary>
/// <remarks>
/// Purpose: Integration reality-check for AI-facing features with actual sheet music scans.
/// Orchestrates: PDF→PNG rendering, optional title recognition, CSV results export.
/// 
/// Usage:
///   $env:SHEETSTORM_RUN_MANUAL=1
///   $env:SHEETSTORM_SMOKE_PDF_FOLDER="C:\Temp\Noten-Smoke"
///   $env:SHEETSTORM_SMOKE_OUTPUT_FOLDER="C:\Temp\Noten-Smoke-Output"
///   $env:GITHUB_TOKEN="ghp_..." (optional, for recognition)
///   dotnet test --filter "Category=Manual"
/// 
/// Output:
///   - {filename}.png for each PDF (300 DPI)
///   - recognition-results.csv with columns: filename,png_bytes,width,height,recognized_title,confidence,duration_ms,error
/// 
/// Behavior:
///   - Skips cleanly if SHEETSTORM_RUN_MANUAL != "1"
///   - Skips cleanly if folder missing/empty
///   - Processes all PDFs, catches errors per file (doesn't fail entire test on single file)
///   - Asserts: at least 1 file processed AND success rate > 0 (ensures harness not broken)
/// </remarks>
[Trait("Category", "Manual")]
public sealed class RenderScannedSmoke : IDisposable
{
    private readonly IPdfFirstPageRenderer _renderer;
    private readonly string? _inputFolder;
    private readonly string? _outputFolder;
    private readonly string? _githubToken;
    private readonly bool _shouldRun;

    public RenderScannedSmoke()
    {
        _renderer = new PdfFirstPageRenderer();
        
        // Check if manual tests should run
        _shouldRun = Environment.GetEnvironmentVariable("SHEETSTORM_RUN_MANUAL") == "1";
        
        _inputFolder = Environment.GetEnvironmentVariable("SHEETSTORM_SMOKE_PDF_FOLDER") 
                       ?? @"C:\Temp\Noten-Smoke";
        
        _outputFolder = Environment.GetEnvironmentVariable("SHEETSTORM_SMOKE_OUTPUT_FOLDER") 
                        ?? @"C:\Temp\Noten-Smoke-Output";
        
        _githubToken = Environment.GetEnvironmentVariable("GITHUB_TOKEN");
    }

    public void Dispose()
    {
        // No cleanup needed — output folder intentionally persists for manual inspection
    }

    [Fact]
    public async Task SmokeTest_RenderAndOptionallyRecognize_ProducesValidOutputs()
    {
        // ARRANGE: Guard clauses for skip conditions
        if (!_shouldRun)
        {
            // Clean skip — not enabled
            return;
        }

        if (!Directory.Exists(_inputFolder))
        {
            // Clean skip — no input folder (expected in CI/sandbox)
            return;
        }

        var pdfFiles = Directory.GetFiles(_inputFolder!, "*.pdf", SearchOption.TopDirectoryOnly);
        if (pdfFiles.Length == 0)
        {
            // Clean skip — no PDFs to process
            return;
        }

        // If we reach here, user explicitly wants to run smoke test with provided files
        Directory.CreateDirectory(_outputFolder!);

        var results = new List<SmokeResult>();
        var csvPath = Path.Combine(_outputFolder!, "recognition-results.csv");

        // Optional: Setup title recognizer if token available
        ITitleRecognizer? recognizer = null;
        if (!string.IsNullOrWhiteSpace(_githubToken))
        {
            var httpClient = new HttpClient
            {
                BaseAddress = new Uri("https://models.inference.ai.azure.com"),
                Timeout = TimeSpan.FromSeconds(60)
            };
            
            var tokenProvider = new StaticTokenProvider(_githubToken!);
            recognizer = new GitHubModelsTitleRecognizer(
                httpClient, 
                tokenProvider,
                logger: null, // No logger in smoke test
                retryDelays: new[] { TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(2) } // Shorter retries for manual run
            );
        }

        // ACT: Process each PDF
        foreach (var pdfPath in pdfFiles)
        {
            var result = await ProcessPdfAsync(pdfPath, recognizer);
            results.Add(result);
        }

        // ASSERT: At least one file processed and success rate > 0
        results.Should().NotBeEmpty("Expected at least one PDF to process");
        
        var successCount = results.Count(r => r.Error == null);
        successCount.Should().BeGreaterThan(0, 
            "Expected at least one successful render (0 successes indicates harness is broken)");

        // Export results to CSV
        await ExportResultsToCsvAsync(csvPath, results);
        
        // Log summary to test output
        var summary = $"""
            
            ===== SMOKE TEST SUMMARY =====
            Total PDFs: {results.Count}
            Successful: {successCount}
            Failed: {results.Count - successCount}
            Output: {_outputFolder}
            CSV: {csvPath}
            Recognition: {(recognizer != null ? "Enabled" : "Disabled (no GITHUB_TOKEN)")}
            ==============================
            """;
        
        Console.WriteLine(summary);
    }

    private async Task<SmokeResult> ProcessPdfAsync(string pdfPath, ITitleRecognizer? recognizer)
    {
        var sw = Stopwatch.StartNew();
        var fileName = Path.GetFileNameWithoutExtension(pdfPath);
        var result = new SmokeResult { FileName = fileName };

        try
        {
            // Render PDF to PNG
            var pngBytes = await _renderer.RenderFirstPageAsPngAsync(pdfPath, dpi: 300);
            result.PngBytes = pngBytes.Length;

            // Extract dimensions from PNG
            using var image = SKBitmap.Decode(pngBytes);
            result.Width = image.Width;
            result.Height = image.Height;

            // Write PNG to output folder
            var outputPath = Path.Combine(_outputFolder!, $"{fileName}.png");
            await File.WriteAllBytesAsync(outputPath, pngBytes);

            // Optional: Run title recognition
            if (recognizer != null)
            {
                try
                {
                    var recognition = await recognizer.RecognizeTitleAsync(pngBytes);
                    result.RecognizedTitle = recognition.Title;
                    result.Confidence = recognition.Confidence;
                }
                catch (Exception ex)
                {
                    // Recognition failed, but rendering succeeded — log error, don't fail
                    result.RecognizedTitle = "";
                    result.Confidence = 0.0;
                    result.Error = $"Recognition failed: {ex.Message}";
                }
            }

            sw.Stop();
            result.DurationMs = (int)sw.ElapsedMilliseconds;
        }
        catch (Exception ex)
        {
            // Rendering failed — log error
            sw.Stop();
            result.DurationMs = (int)sw.ElapsedMilliseconds;
            result.Error = ex.Message;
        }

        return result;
    }

    private static async Task ExportResultsToCsvAsync(string csvPath, List<SmokeResult> results)
    {
        var csv = new StringBuilder();
        csv.AppendLine("filename,png_bytes,width,height,recognized_title,confidence,duration_ms,error");

        foreach (var r in results)
        {
            // CSV-escape title and error (handle commas/quotes)
            var title = EscapeCsv(r.RecognizedTitle ?? "");
            var error = EscapeCsv(r.Error ?? "");

            csv.AppendLine($"{r.FileName},{r.PngBytes},{r.Width},{r.Height},{title},{r.Confidence:F2},{r.DurationMs},{error}");
        }

        await File.WriteAllTextAsync(csvPath, csv.ToString(), Encoding.UTF8);
    }

    private static string EscapeCsv(string value)
    {
        if (value.Contains(',') || value.Contains('"') || value.Contains('\n'))
        {
            return $"\"{value.Replace("\"", "\"\"")}\"";
        }
        return value;
    }

    private sealed class SmokeResult
    {
        public required string FileName { get; init; }
        public int PngBytes { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public string? RecognizedTitle { get; set; }
        public double Confidence { get; set; }
        public int DurationMs { get; set; }
        public string? Error { get; set; }
    }

    /// <summary>
    /// Simple token provider for smoke tests (not for production — use WindowsCredentialManagerTokenProvider).
    /// </summary>
    private sealed class StaticTokenProvider : ITitleRecognizerTokenProvider
    {
        private readonly string _token;

        public StaticTokenProvider(string token)
        {
            _token = token;
        }

        public ValueTask<string> GetTokenAsync(CancellationToken ct = default)
        {
            return new ValueTask<string>(_token);
        }
    }
}
