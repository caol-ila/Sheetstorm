namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A reaction (emoji) to a post.
/// </summary>
public class PostReaction : BaseEntity
{
    public Guid PostId { get; set; }
    public Post Post { get; set; } = null!;

    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public string ReactionType { get; set; } = string.Empty;
}
