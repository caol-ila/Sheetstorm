using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Container grouping annotation elements per page and visibility level.
/// One Annotation per (PiecePageId, Level, VoiceId?) combination.
/// </summary>
public class Annotation : BaseEntity
{
    public Guid PiecePageId { get; set; }
    public PiecePage PiecePage { get; set; } = null!;

    public AnnotationLevel Level { get; set; }

    /// <summary>Only set when Level = Voice.</summary>
    public Guid? VoiceId { get; set; }
    public Voice? Voice { get; set; }

    /// <summary>Only set when Level = Voice or Orchestra.</summary>
    public Guid? BandId { get; set; }
    public Band? Band { get; set; }

    public Guid CreatedByMusicianId { get; set; }
    public Musician CreatedByMusician { get; set; } = null!;

    public long Version { get; set; } = 1;

    public ICollection<AnnotationElement> Elements { get; set; } = [];
}
