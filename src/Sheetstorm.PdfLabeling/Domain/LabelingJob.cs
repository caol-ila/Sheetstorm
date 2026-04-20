namespace Sheetstorm.PdfLabeling.Domain;

public sealed record LabelingJob(string SourceDirectory, string TargetDirectory, bool IncludeUnrecognized = true);
