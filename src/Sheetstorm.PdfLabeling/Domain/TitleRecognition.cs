namespace Sheetstorm.PdfLabeling.Domain;

public sealed record TitleRecognition(string Title, double Confidence, string? Reasoning = null);
