using System.ComponentModel.DataAnnotations;

namespace Sheetstorm.Domain.Communication;

// ── Requests ──────────────────────────────────────────────────
public record CreatePostRequest(
    [Required][StringLength(120, MinimumLength = 1)] string Title,
    [Required][StringLength(5000, MinimumLength = 1)] string Content,
    [StringLength(50)] string? Category
);

public record UpdatePostRequest(
    [Required][StringLength(120, MinimumLength = 1)] string Title,
    [Required][StringLength(5000, MinimumLength = 1)] string Content,
    [StringLength(50)] string? Category
);

public record CreatePostCommentRequest(
    [Required][StringLength(1000, MinimumLength = 1)] string Content,
    Guid? ParentCommentId
);

public record AddPostReactionRequest(
    [Required][StringLength(20, MinimumLength = 1)] string ReactionType
);

// ── Responses ──────────────────────────────────────────────────
public record PostDto(
    Guid Id,
    string Title,
    string Content,
    string? Category,
    Guid AuthorMusicianId,
    string AuthorMusicianName,
    bool IsPinned,
    DateTime? PinnedAt,
    int CommentCount,
    IReadOnlyList<ReactionSummaryDto> Reactions,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

public record PostDetailDto(
    Guid Id,
    string Title,
    string Content,
    string? Category,
    Guid AuthorMusicianId,
    string AuthorMusicianName,
    bool IsPinned,
    DateTime? PinnedAt,
    IReadOnlyList<PostCommentDto> Comments,
    IReadOnlyList<ReactionSummaryDto> Reactions,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

public record PostCommentDto(
    Guid Id,
    string Content,
    Guid AuthorMusicianId,
    string AuthorMusicianName,
    Guid? ParentCommentId,
    bool IsDeleted,
    DateTime CreatedAt
);

public record ReactionSummaryDto(
    string ReactionType,
    int Count,
    bool UserReacted
);
