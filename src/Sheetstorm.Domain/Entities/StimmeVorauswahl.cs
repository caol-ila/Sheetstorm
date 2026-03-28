namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Per-Kapelle default voice selection for a specific instrument.
/// Maps: which Stimme does this Musiker play for this instrument in this Kapelle?
/// </summary>
public class StimmeVorauswahl : BaseEntity
{
    public Guid MusikerID { get; set; }
    public Musiker Musiker { get; set; } = null!;

    public Guid KapelleID { get; set; }
    public Kapelle Kapelle { get; set; } = null!;

    public Guid NutzerInstrumentID { get; set; }
    public NutzerInstrument NutzerInstrument { get; set; } = null!;

    /// <summary>The preferred Stimme label (e.g. "2. Klarinette").</summary>
    public string StimmeBezeichnung { get; set; } = string.Empty;
}
