namespace Sheetstorm.Domain.Entities;

/// <summary>
/// An instrument that a Musiker plays (1:N from Musiker).
/// Each Musiker can have multiple instruments with a sort order.
/// </summary>
public class NutzerInstrument : BaseEntity
{
    public Guid MusikerID { get; set; }
    public Musiker Musiker { get; set; } = null!;

    /// <summary>Normalized instrument type key (e.g. "klarinette", "trompete").</summary>
    public string InstrumentTyp { get; set; } = string.Empty;

    /// <summary>Display name (e.g. "Klarinette", "Altsaxophon").</summary>
    public string InstrumentBezeichnung { get; set; } = string.Empty;

    /// <summary>Sort order in the user's profile (0 = primary instrument).</summary>
    public int Sortierung { get; set; }

    public ICollection<StimmeVorauswahl> Vorauswahlen { get; set; } = [];
}
