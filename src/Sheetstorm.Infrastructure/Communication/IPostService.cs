using Sheetstorm.Domain.Communication;

namespace Sheetstorm.Infrastructure.Communication;

public interface IPostService
{
    Task<IReadOnlyList<PostDto>> GetAllAsync(Guid bandId, Guid musicianId, CancellationToken ct);
    Task<PostDetailDto> GetByIdAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct);
    Task<PostDetailDto> CreateAsync(Guid bandId, CreatePostRequest request, Guid musicianId, CancellationToken ct);
    Task<PostDetailDto> UpdateAsync(Guid bandId, Guid postId, UpdatePostRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct);
    Task PinAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct);
    Task UnpinAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct);
    Task<PostCommentDto> AddCommentAsync(Guid bandId, Guid postId, CreatePostCommentRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteCommentAsync(Guid bandId, Guid postId, Guid commentId, Guid musicianId, CancellationToken ct);
    Task AddReactionAsync(Guid bandId, Guid postId, AddPostReactionRequest request, Guid musicianId, CancellationToken ct);
    Task RemoveReactionAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct);
}
