namespace Sheetstorm.PdfLabeling.Domain;

public enum LabelingStatus
{
    Labeled,
    Unrecognized,
    DuplicateResolved,
    Failed,
    Cancelled
}

public sealed record LabelingResult(
    string SourcePath,
    string? TargetPath,
    string? RecognizedTitle,
    double Confidence,
    LabelingStatus Status,
    string? Message
);
