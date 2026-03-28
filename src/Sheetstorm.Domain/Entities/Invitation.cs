namespace Sheetstorm.Domain.Entities;

/// <summary>
/// An invitation code granting a Musician access to a Band with a predefined role.
/// </summary>
public class Invitation : BaseEntity
{
    public string Code { get; set; } = string.Empty;

    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public MemberRole IntendedRole { get; set; } = MemberRole.Musician;

    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }

    public Guid CreatedByMusicianId { get; set; }
    public Musician CreatedBy { get; set; } = null!;

    public Guid? RedeemedByMusicianId { get; set; }
    public Musician? RedeemedBy { get; set; }
}
