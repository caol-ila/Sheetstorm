namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Default Voices mapping for a Band: which Voice a given Instrument plays by default.
/// Admins can override this; individual members can further override via Membership.VoiceOverride.
/// </summary>
public class BandVoiceMapping : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    /// <summary>Instrument name (e.g. "Trompete", "Klarinette").</summary>
    public string Instrument { get; set; } = string.Empty;

    /// <summary>Default Voice label for this instrument in this Band (e.g. "1. Voice").</summary>
    public string Voice { get; set; } = string.Empty;
}
