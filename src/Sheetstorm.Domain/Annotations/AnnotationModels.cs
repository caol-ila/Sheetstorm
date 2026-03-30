using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Annotations;

// ── DTOs ─────────────────────────────────────────────────────────────────────

public record AnnotationDto(
    Guid Id,
    Guid PiecePageId,
    AnnotationLevel Level,
    Guid? VoiceId,
    Guid? BandId,
    Guid CreatedByMusicianId,
    long Version,
    IReadOnlyList<AnnotationElementDto> Elements
);

public record AnnotationElementDto(
    Guid Id,
    Guid AnnotationId,
    AnnotationTool Tool,
    string? Points,
    double BboxX,
    double BboxY,
    double BboxWidth,
    double BboxHeight,
    string? Text,
    string? StampCategory,
    string? StampValue,
    double Opacity,
    double StrokeWidth,
    long Version,
    Guid CreatedByMusicianId,
    bool IsDeleted,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

// ── Requests ─────────────────────────────────────────────────────────────────

public record CreateAnnotationElementRequest(
    Guid PiecePageId,
    AnnotationLevel Level,
    Guid? VoiceId,
    AnnotationTool Tool,
    string? Points,
    double BboxX,
    double BboxY,
    double BboxWidth,
    double BboxHeight,
    string? Text,
    string? StampCategory,
    string? StampValue,
    double Opacity,
    double StrokeWidth
);

public record UpdateAnnotationElementRequest(
    long Version,
    double BboxX,
    double BboxY,
    double BboxWidth,
    double BboxHeight,
    string? Points,
    string? Text,
    string? StampCategory,
    string? StampValue,
    double Opacity,
    double StrokeWidth
);

// ── Sync Response ────────────────────────────────────────────────────────────

public record AnnotationSyncResponse(
    IReadOnlyList<AnnotationElementDto> Elements,
    long CurrentVersion
);

// ── SignalR Notification ─────────────────────────────────────────────────────

public record ElementChangeNotification(
    Guid AnnotationId,
    Guid ElementId,
    string ChangeType, // "added", "updated", "deleted"
    AnnotationElementDto? Element
);
