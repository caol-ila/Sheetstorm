namespace Sheetstorm.PdfLabeling.Cli;

public sealed record CliOptions(
    string SourceDirectory,
    string TargetDirectory,
    double Confidence = 0.6,
    string? TokenEnv = null,
    string? CancelFile = null
);
