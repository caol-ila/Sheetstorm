namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Per-Band default voice selection for a specific instrument.
/// Maps: which Voice does this Musician play for this instrument in this Band?
/// </summary>
public class VoicePreselection : BaseEntity
{
    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public Guid UserInstrumentID { get; set; }
    public UserInstrument UserInstrument { get; set; } = null!;

    /// <summary>The preferred Voice label (e.g. "2. Klarinette").</summary>
    public string VoiceLabel { get; set; } = string.Empty;
}
