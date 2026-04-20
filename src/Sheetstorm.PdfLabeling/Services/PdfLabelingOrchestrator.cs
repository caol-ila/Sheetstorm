using System.Diagnostics;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;
using Sheetstorm.PdfLabeling.Abstractions;
using Sheetstorm.PdfLabeling.Domain;

namespace Sheetstorm.PdfLabeling.Services;

public sealed partial class PdfLabelingOrchestrator : IPdfLabelingOrchestrator
{
    private const double ConfidenceThreshold = 0.6;
    private const string UnrecognizedDirectoryName = "_unerkannt";

    private readonly IPdfFirstPageRenderer _renderer;
    private readonly ITitleRecognizer _recognizer;
    private readonly IFileNameSanitizer _sanitizer;
    private readonly IFileTargetResolver _resolver;
    private readonly ILogger<PdfLabelingOrchestrator>? _logger;

    public PdfLabelingOrchestrator(
        IPdfFirstPageRenderer renderer,
        ITitleRecognizer recognizer,
        IFileNameSanitizer sanitizer,
        IFileTargetResolver resolver,
        ILogger<PdfLabelingOrchestrator>? logger = null)
    {
        _renderer = renderer ?? throw new ArgumentNullException(nameof(renderer));
        _recognizer = recognizer ?? throw new ArgumentNullException(nameof(recognizer));
        _sanitizer = sanitizer ?? throw new ArgumentNullException(nameof(sanitizer));
        _resolver = resolver ?? throw new ArgumentNullException(nameof(resolver));
        _logger = logger;
    }

    public async Task<IReadOnlyList<LabelingResult>> LabelBatchAsync(
        LabelingJob job,
        IProgress<ProgressUpdate>? progress = null,
        CancellationToken ct = default)
    {
        if (job == null) throw new ArgumentNullException(nameof(job));

        var stopwatch = Stopwatch.StartNew();

        if (!Directory.Exists(job.SourceDirectory))
        {
            throw new DirectoryNotFoundException($"Source directory not found: {job.SourceDirectory}");
        }

        if (!Directory.Exists(job.TargetDirectory))
        {
            Directory.CreateDirectory(job.TargetDirectory);
        }

        var pdfFiles = Directory.GetFiles(job.SourceDirectory, "*.pdf", SearchOption.TopDirectoryOnly)
            .OrderBy(f => f, StringComparer.OrdinalIgnoreCase)
            .ToList();

        var totalCount = pdfFiles.Count;
        var results = new List<LabelingResult>(totalCount);

        if (totalCount == 0)
        {
            ReportProgress(progress, 0, 0, string.Empty, stopwatch.Elapsed, null);
            return results;
        }

        for (int i = 0; i < pdfFiles.Count; i++)
        {
            var pdfPath = pdfFiles[i];
            var fileName = Path.GetFileName(pdfPath);

            ReportProgress(progress, i, totalCount, fileName, stopwatch.Elapsed, 
                CalculateEstimatedRemaining(i, totalCount, stopwatch.Elapsed));

            if (ct.IsCancellationRequested)
            {
                for (int j = i; j < pdfFiles.Count; j++)
                {
                    results.Add(CreateCancelledResult(pdfFiles[j]));
                }
                break;
            }

            try
            {
                var result = await ProcessFileAsync(pdfPath, job.TargetDirectory, ct);
                results.Add(result);
            }
            catch (OperationCanceledException)
            {
                results.Add(CreateCancelledResult(pdfPath));
                
                for (int j = i + 1; j < pdfFiles.Count; j++)
                {
                    results.Add(CreateCancelledResult(pdfFiles[j]));
                }
                break;
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Failed to process file {FilePath}", pdfPath);
                results.Add(CreateFailedResult(pdfPath, ex));
            }
        }

        ReportProgress(progress, results.Count, totalCount, string.Empty, stopwatch.Elapsed, TimeSpan.Zero);

        return results;
    }

    private async Task<LabelingResult> ProcessFileAsync(
        string sourcePath,
        string targetDirectory,
        CancellationToken ct)
    {
        var pngBytes = await _renderer.RenderFirstPageAsPngAsync(sourcePath, dpi: 300, ct);
        var recognition = await _recognizer.RecognizeTitleAsync(pngBytes, ct);

        if (recognition.Confidence < ConfidenceThreshold)
        {
            return await RouteToUnrecognizedAsync(sourcePath, targetDirectory, recognition, ct);
        }

        var sanitizedTitle = _sanitizer.Sanitize(recognition.Title);
        var targetPath = _resolver.Resolve(targetDirectory, sanitizedTitle, "pdf");
        
        File.Copy(sourcePath, targetPath, overwrite: false);

        var status = DetermineStatus(targetPath, targetDirectory, sanitizedTitle);

        return new LabelingResult(
            SourcePath: sourcePath,
            TargetPath: targetPath,
            RecognizedTitle: recognition.Title,
            Confidence: recognition.Confidence,
            Status: status,
            Message: null
        );
    }

    private async Task<LabelingResult> RouteToUnrecognizedAsync(
        string sourcePath,
        string targetDirectory,
        TitleRecognition recognition,
        CancellationToken ct)
    {
        var unerkanntDir = Path.Combine(targetDirectory, UnrecognizedDirectoryName);
        
        if (!Directory.Exists(unerkanntDir))
        {
            Directory.CreateDirectory(unerkanntDir);
        }

        var fileName = Path.GetFileName(sourcePath);
        var targetPath = Path.Combine(unerkanntDir, fileName);

        await Task.Run(() => File.Copy(sourcePath, targetPath, overwrite: false), ct);

        return new LabelingResult(
            SourcePath: sourcePath,
            TargetPath: targetPath,
            RecognizedTitle: recognition.Title,
            Confidence: recognition.Confidence,
            Status: LabelingStatus.Unrecognized,
            Message: null
        );
    }

    private static LabelingStatus DetermineStatus(string targetPath, string targetDirectory, string sanitizedTitle)
    {
        var basePath = Path.Combine(targetDirectory, sanitizedTitle + ".pdf");
        
        return string.Equals(targetPath, basePath, StringComparison.OrdinalIgnoreCase)
            ? LabelingStatus.Labeled
            : LabelingStatus.DuplicateResolved;
    }

    private static LabelingResult CreateCancelledResult(string sourcePath)
    {
        return new LabelingResult(
            SourcePath: sourcePath,
            TargetPath: null,
            RecognizedTitle: null,
            Confidence: 0,
            Status: LabelingStatus.Cancelled,
            Message: null
        );
    }

    private static LabelingResult CreateFailedResult(string sourcePath, Exception ex)
    {
        var scrubbedMessage = ScrubSensitiveTokens(ex.Message);
        
        return new LabelingResult(
            SourcePath: sourcePath,
            TargetPath: null,
            RecognizedTitle: null,
            Confidence: 0,
            Status: LabelingStatus.Failed,
            Message: scrubbedMessage
        );
    }

    private static string ScrubSensitiveTokens(string message)
    {
        var scrubbed = GitHubTokenRegex().Replace(message, "[REDACTED_TOKEN]");
        scrubbed = GitHubPatTokenRegex().Replace(scrubbed, "[REDACTED_TOKEN]");
        return scrubbed;
    }

    private static void ReportProgress(
        IProgress<ProgressUpdate>? progress,
        int processed,
        int total,
        string currentFileName,
        TimeSpan elapsed,
        TimeSpan? estimatedRemaining)
    {
        progress?.Report(new ProgressUpdate(
            ProcessedCount: processed,
            TotalCount: total,
            CurrentFileName: currentFileName,
            Elapsed: elapsed,
            EstimatedRemaining: estimatedRemaining
        ));
    }

    private static TimeSpan? CalculateEstimatedRemaining(int processed, int total, TimeSpan elapsed)
    {
        if (processed == 0)
        {
            return null;
        }

        var remaining = total - processed;
        var averageTimePerFile = elapsed.TotalSeconds / processed;
        return TimeSpan.FromSeconds(averageTimePerFile * remaining);
    }

    [GeneratedRegex(@"ghp_[A-Za-z0-9_]+", RegexOptions.Compiled)]
    private static partial Regex GitHubTokenRegex();

    [GeneratedRegex(@"github_pat_[A-Za-z0-9_]+", RegexOptions.Compiled)]
    private static partial Regex GitHubPatTokenRegex();
}
