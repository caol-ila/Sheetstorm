namespace Sheetstorm.Domain.Entities;

/// <summary>
/// N:M relationship between Musician and Band with role assignment.
/// </summary>
public class Membership : BaseEntity
{
    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public MemberRole Role { get; set; } = MemberRole.Musician;
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Personal Voices override for this member in this Band.
    /// When set, takes precedence over the Band default Voices mapping.
    /// </summary>
    public string? VoiceOverride { get; set; }
}

public enum MemberRole
{
    Musician,
    SectionLeader,
    Conductor,
    SheetMusicManager,
    Administrator
}
