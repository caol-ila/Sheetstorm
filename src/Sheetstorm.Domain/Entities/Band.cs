namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A brass band or ensemble.
/// </summary>
public class Band : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }

    public string? Location { get; set; }
    public string? LogoUrl { get; set; }

    /// <summary>
    /// True for a user's personal "Meine Musik" band (auto-created at registration, one per user).
    /// Personal bands cannot be deleted, left, or shared with others.
    /// </summary>
    public bool IsPersonal { get; set; } = false;

    public ICollection<Membership> Members { get; set; } = [];
    public ICollection<Piece> Pieces { get; set; } = [];
    public ICollection<Invitation> Invitationen { get; set; } = [];
    public ICollection<BandVoiceMapping> VoiceMappings { get; set; } = [];
}
