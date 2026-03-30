using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A media link to external resources (YouTube, Spotify, etc.) for a piece.
/// </summary>
public class MediaLink : BaseEntity
{
    public Guid PieceId { get; set; }
    public Piece Piece { get; set; } = null!;

    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public string Url { get; set; } = string.Empty;
    public MediaLinkType Type { get; set; }
    
    public string? Title { get; set; }
    public string? Description { get; set; }
    public string? ThumbnailUrl { get; set; }
    public int? DurationSeconds { get; set; }

    public Guid AddedByMusicianId { get; set; }
    public Musician AddedByMusician { get; set; } = null!;
}
