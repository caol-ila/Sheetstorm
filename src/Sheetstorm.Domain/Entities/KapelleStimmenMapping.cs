namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Default Stimmen mapping for a Kapelle: which Stimme a given Instrument plays by default.
/// Admins can override this; individual members can further override via Mitgliedschaft.StimmenOverride.
/// </summary>
public class KapelleStimmenMapping : BaseEntity
{
    public Guid KapelleId { get; set; }
    public Kapelle Kapelle { get; set; } = null!;

    /// <summary>Instrument name (e.g. "Trompete", "Klarinette").</summary>
    public string Instrument { get; set; } = string.Empty;

    /// <summary>Default Stimme label for this instrument in this Kapelle (e.g. "1. Stimme").</summary>
    public string Stimme { get; set; } = string.Empty;
}
