namespace Sheetstorm.Domain.Entities;

/// <summary>
/// An option in a poll.
/// </summary>
public class PollOption : BaseEntity
{
    public Guid PollId { get; set; }
    public Poll Poll { get; set; } = null!;

    public string Text { get; set; } = string.Empty;
    public int Position { get; set; }

    public ICollection<PollVote> Votes { get; set; } = [];
}
