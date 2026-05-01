namespace Sheetstorm.Web;

public sealed record PushSubscriptionDto(string Endpoint, string P256dh, string Auth);
public sealed record ConductorKeyDto(string PublicKeyBase64);
public sealed record AnnotationSaveDto(string LayerJson);

/// <summary>
/// Korrektur-Annotation an einer Detection (Annotation-Tool).
/// Bbox-Koordinaten in Pipeline-Render-Pixel-System (Detections.width/height).
/// </summary>
public sealed record PartAnnotationDto(
    int PageIndex,
    int X,
    int Y,
    int W,
    int H,
    int Kind,
    string? CorrectionJson,
    string? Comment);
