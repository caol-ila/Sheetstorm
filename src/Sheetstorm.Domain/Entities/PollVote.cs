namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A vote on a poll option.
/// </summary>
public class PollVote : BaseEntity
{
    public Guid PollOptionId { get; set; }
    public PollOption PollOption { get; set; } = null!;

    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;
}
