using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A musical piece in the library. Belongs to a Band (or personal collection when BandId is null).
/// </summary>
public class Piece : BaseEntity
{
    public Guid? BandId { get; set; }
    public Band? Band { get; set; }

    /// <summary>Owner for personal pieces (BandId = null).</summary>
    public Guid? MusicianId { get; set; }
    public Musician? Musician { get; set; }

    public string Title { get; set; } = string.Empty;
    public string? Composer { get; set; }
    public string? Arranger { get; set; }
    public int? PublicationYear { get; set; }

    // Import-specific fields
    public string? MusicalKey { get; set; }
    public string? TimeSignature { get; set; }
    public int? Tempo { get; set; }
    public string? Description { get; set; }
    public string? OriginalFileName { get; set; }
    public string? StorageKey { get; set; }
    public ImportStatus ImportStatus { get; set; } = ImportStatus.Completed;

    public ICollection<Voice> Voices { get; set; } = [];
    public ICollection<PiecePage> Pages { get; set; } = [];
}
