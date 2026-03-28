namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A poll for gathering opinions from band members.
/// </summary>
public class Poll : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public Guid CreatedByMusicianId { get; set; }
    public Musician CreatedByMusician { get; set; } = null!;

    public string Question { get; set; } = string.Empty;
    public bool IsAnonymous { get; set; }
    public bool IsMultipleChoice { get; set; }
    
    public DateTime? ExpiresAt { get; set; }
    public bool IsClosed { get; set; }

    public ICollection<PollOption> Options { get; set; } = [];
}
