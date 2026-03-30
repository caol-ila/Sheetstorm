using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Individual graphic element within an annotation container.
/// Supports pencil strokes, highlighter, text, and stamps.
/// Versioned for optimistic concurrency (LWW conflict resolution).
/// </summary>
public class AnnotationElement : BaseEntity
{
    public Guid AnnotationId { get; set; }
    public Annotation Annotation { get; set; } = null!;

    public AnnotationTool Tool { get; set; }

    /// <summary>JSON array of stroke points [{x, y, pressure}, ...]. Null for Text/Stamp.</summary>
    public string? Points { get; set; }

    public double BboxX { get; set; }
    public double BboxY { get; set; }
    public double BboxWidth { get; set; }
    public double BboxHeight { get; set; }

    /// <summary>Only for Tool = Text.</summary>
    public string? Text { get; set; }

    /// <summary>Only for Tool = Stamp.</summary>
    public string? StampCategory { get; set; }

    /// <summary>Only for Tool = Stamp.</summary>
    public string? StampValue { get; set; }

    public double Opacity { get; set; } = 1.0;
    public double StrokeWidth { get; set; } = 3.0;

    public long Version { get; set; } = 1;

    public Guid CreatedByMusicianId { get; set; }
    public Musician CreatedByMusician { get; set; } = null!;

    /// <summary>Soft-delete flag for sync consistency.</summary>
    public bool IsDeleted { get; set; }
}
