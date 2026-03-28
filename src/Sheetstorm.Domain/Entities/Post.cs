namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A message post in the band communication board.
/// </summary>
public class Post : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public Guid AuthorMusicianId { get; set; }
    public Musician AuthorMusician { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    
    public bool IsPinned { get; set; }
    public DateTime? PinnedAt { get; set; }
    public string? Category { get; set; }

    public ICollection<PostComment> Comments { get; set; } = [];
    public ICollection<PostReaction> Reactions { get; set; } = [];
}
