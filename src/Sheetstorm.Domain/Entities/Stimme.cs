namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A specific instrumental part (Stimme) for a piece.
/// </summary>
public class Stimme : BaseEntity
{
    public Guid StueckID { get; set; }
    public Stueck Stueck { get; set; } = null!;

    public string Bezeichnung { get; set; } = string.Empty;
    public string? Instrument { get; set; }

    /// <summary>Normalized instrument type key for fallback matching (e.g. "klarinette").</summary>
    public string? InstrumentTyp { get; set; }

    /// <summary>Instrument family for fallback step 4 (e.g. "holzblaeser").</summary>
    public string? InstrumentFamilie { get; set; }

    /// <summary>Stimme number for sorting/fallback (e.g. 2 for "2. Klarinette"). Null = no number.</summary>
    public int? StimmenNummer { get; set; }

    public ICollection<Notenblatt> Notenblaetter { get; set; } = [];
}
