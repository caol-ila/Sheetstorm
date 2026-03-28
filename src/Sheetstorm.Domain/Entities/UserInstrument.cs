namespace Sheetstorm.Domain.Entities;

/// <summary>
/// An instrument that a Musician plays (1:N from Musician).
/// Each Musician can have multiple instruments with a sort order.
/// </summary>
public class UserInstrument : BaseEntity
{
    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    /// <summary>Normalized instrument type key (e.g. "klarinette", "trompete").</summary>
    public string InstrumentType { get; set; } = string.Empty;

    /// <summary>Display name (e.g. "Klarinette", "Altsaxophon").</summary>
    public string InstrumentLabel { get; set; } = string.Empty;

    /// <summary>Sort order in the user's profile (0 = primary instrument).</summary>
    public int SortOrder { get; set; }

    public ICollection<VoicePreselection> Preselections { get; set; } = [];
}
