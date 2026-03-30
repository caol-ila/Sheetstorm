namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A comment on a post.
/// </summary>
public class PostComment : BaseEntity
{
    public Guid PostId { get; set; }
    public Post Post { get; set; } = null!;

    public Guid AuthorMusicianId { get; set; }
    public Musician AuthorMusician { get; set; } = null!;

    public string Content { get; set; } = string.Empty;
    
    public Guid? ParentCommentId { get; set; }
    public PostComment? ParentComment { get; set; }

    public bool IsDeleted { get; set; }
}
