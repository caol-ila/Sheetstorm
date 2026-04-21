namespace Sheetstorm.PdfLabeling.Domain;

public sealed record ProgressUpdate(
    int ProcessedCount,
    int TotalCount,
    string CurrentFileName,
    TimeSpan Elapsed,
    TimeSpan? EstimatedRemaining
);
