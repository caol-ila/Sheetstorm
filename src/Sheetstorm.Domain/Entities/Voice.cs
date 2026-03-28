namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A specific instrumental part (Voice) for a piece.
/// </summary>
public class Voice : BaseEntity
{
    public Guid PieceId { get; set; }
    public Piece Piece { get; set; } = null!;

    public string Label { get; set; } = string.Empty;
    public string? Instrument { get; set; }

    /// <summary>Normalized instrument type key for fallback matching (e.g. "klarinette").</summary>
    public string? InstrumentType { get; set; }

    /// <summary>Instrument family for fallback step 4 (e.g. "holzblaeser").</summary>
    public string? InstrumentFamily { get; set; }

    /// <summary>Voice number for sorting/fallback (e.g. 2 for "2. Klarinette"). Null = no number.</summary>
    public int? VoiceNumber { get; set; }

    public ICollection<SheetMusic> SheetMusicFiles { get; set; } = [];
}
