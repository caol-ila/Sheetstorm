using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Communication;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Pagination;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Pagination;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Communication;

public class PostService(AppDbContext db, IBandAuthorizationService bandAuth) : IPostService
{
    public async Task<IReadOnlyList<PostDto>> GetAllAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var posts = await db.Set<Post>()
            .Include(p => p.AuthorMusician)
            .Include(p => p.Comments.Where(c => !c.IsDeleted))
            .Include(p => p.Reactions)
            .Where(p => p.BandId == bandId && !p.IsDeleted)
            .OrderByDescending(p => p.IsPinned)
            .ThenByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

        return posts.Select(p => MapToDto(p, musicianId)).ToList();
    }

    public async Task<PagedResult<PostDto>> GetAllPaginatedAsync(
        Guid bandId, Guid musicianId, PaginationRequest pagination, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var pageSize = pagination.EffectivePageSize;

        var query = db.Set<Post>()
            .Include(p => p.AuthorMusician)
            .Include(p => p.Comments.Where(c => !c.IsDeleted))
            .Include(p => p.Reactions)
            .Where(p => p.BandId == bandId && !p.IsDeleted);

        if (pagination.Cursor is not null)
        {
            var (cursorDate, cursorId) = CursorHelper.Decode(pagination.Cursor);
            query = query.Where(p =>
                p.CreatedAt < cursorDate ||
                (p.CreatedAt == cursorDate && p.Id.CompareTo(cursorId) < 0));
        }

        return await query
            .OrderByDescending(p => p.CreatedAt)
            .ThenByDescending(p => p.Id)
            .ToPaginatedAsync(
                pageSize,
                p => MapToDto(p, musicianId),
                p => p.CreatedAt,
                p => p.Id,
                ct);
    }

    public async Task<PostDetailDto> GetByIdAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var post = await db.Set<Post>()
            .Include(p => p.AuthorMusician)
            .Include(p => p.Comments.Where(c => !c.IsDeleted))
            .ThenInclude(c => c.AuthorMusician)
            .Include(p => p.Reactions)
            .ThenInclude(r => r.Musician)
            .FirstOrDefaultAsync(p => p.Id == postId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Post not found.", 404);

        var comments = post.Comments
            .Where(c => !c.IsDeleted)
            .OrderBy(c => c.CreatedAt)
            .Select(c => new PostCommentDto(
                c.Id,
                c.Content,
                c.AuthorMusicianId,
                c.AuthorMusician.Name,
                c.ParentCommentId,
                c.IsDeleted,
                c.CreatedAt
            ))
            .ToList();

        var reactions = GetReactionSummaries(post.Reactions, musicianId);

        return new PostDetailDto(
            post.Id,
            post.Title,
            post.Content,
            post.Category,
            post.AuthorMusicianId,
            post.AuthorMusician.Name,
            post.IsPinned,
            post.PinnedAt,
            comments,
            reactions,
            post.CreatedAt,
            post.UpdatedAt
        );
    }

    public async Task<PostDetailDto> CreateAsync(Guid bandId, CreatePostRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && 
            membership.Role != MemberRole.Conductor && 
            membership.Role != MemberRole.SectionLeader)
            throw new DomainException("FORBIDDEN", "Only admins, conductors, and section leaders can create posts.", 403);

        var post = new Post
        {
            BandId = bandId,
            AuthorMusicianId = musicianId,
            Title = request.Title.Trim(),
            Content = request.Content.Trim(),
            Category = request.Category?.Trim()
        };

        db.Set<Post>().Add(post);
        await db.SaveChangesAsync(ct);

        var musician = await db.Set<Musician>().FindAsync(new object[] { musicianId }, ct);

        return new PostDetailDto(
            post.Id,
            post.Title,
            post.Content,
            post.Category,
            musicianId,
            musician!.Name,
            false,
            null,
            Array.Empty<PostCommentDto>(),
            Array.Empty<ReactionSummaryDto>(),
            post.CreatedAt,
            post.UpdatedAt
        );
    }

    public async Task<PostDetailDto> UpdateAsync(Guid bandId, Guid postId, UpdatePostRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var post = await db.Set<Post>()
            .Include(p => p.AuthorMusician)
            .Include(p => p.Comments.Where(c => !c.IsDeleted))
            .ThenInclude(c => c.AuthorMusician)
            .Include(p => p.Reactions)
            .FirstOrDefaultAsync(p => p.Id == postId && p.BandId == bandId && !p.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Post not found.", 404);

        if (post.AuthorMusicianId != musicianId)
            throw new DomainException("FORBIDDEN", "You can only edit your own posts.", 403);

        post.Title = request.Title.Trim();
        post.Content = request.Content.Trim();
        post.Category = request.Category?.Trim();

        await db.SaveChangesAsync(ct);

        var comments = post.Comments
            .Where(c => !c.IsDeleted)
            .OrderBy(c => c.CreatedAt)
            .Select(c => new PostCommentDto(
                c.Id,
                c.Content,
                c.AuthorMusicianId,
                c.AuthorMusician.Name,
                c.ParentCommentId,
                c.IsDeleted,
                c.CreatedAt
            ))
            .ToList();

        var reactions = GetReactionSummaries(post.Reactions, musicianId);

        return new PostDetailDto(
            post.Id,
            post.Title,
            post.Content,
            post.Category,
            post.AuthorMusicianId,
            post.AuthorMusician.Name,
            post.IsPinned,
            post.PinnedAt,
            comments,
            reactions,
            post.CreatedAt,
            post.UpdatedAt
        );
    }

    public async Task DeleteAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct)
    {
        var membership = await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var post = await db.Set<Post>()
            .Include(p => p.Comments)
            .FirstOrDefaultAsync(p => p.Id == postId && p.BandId == bandId && !p.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Post not found.", 404);

        if (post.AuthorMusicianId != musicianId && membership.Role != MemberRole.Administrator)
            throw new DomainException("FORBIDDEN", "You can only delete your own posts or be an admin.", 403);

        var hasActiveComments = post.Comments.Any(c => !c.IsDeleted);
        if (hasActiveComments)
        {
            post.IsDeleted = true;
            post.DeletedAt = DateTime.UtcNow;
            post.Title = "[Gelöscht]";
            post.Content = "[Gelöscht]";
            post.IsPinned = false;
            post.PinnedAt = null;
        }
        else
        {
            db.Set<Post>().Remove(post);
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task PinAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct)
    {
        var membership = await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can pin posts.", 403);

        var post = await db.Set<Post>()
            .FirstOrDefaultAsync(p => p.Id == postId && p.BandId == bandId && !p.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Post not found.", 404);

        if (post.IsPinned)
            return;

        var pinnedCount = await db.Set<Post>()
            .CountAsync(p => p.BandId == bandId && p.IsPinned && !p.IsDeleted, ct);

        if (pinnedCount >= 3)
            throw new DomainException("CONFLICT", "Maximum of 3 posts can be pinned at once.", 409);

        post.IsPinned = true;
        post.PinnedAt = DateTime.UtcNow;

        await db.SaveChangesAsync(ct);
    }

    public async Task UnpinAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct)
    {
        var membership = await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can unpin posts.", 403);

        var post = await db.Set<Post>()
            .FirstOrDefaultAsync(p => p.Id == postId && p.BandId == bandId && !p.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Post not found.", 404);

        post.IsPinned = false;
        post.PinnedAt = null;

        await db.SaveChangesAsync(ct);
    }

    public async Task<PostCommentDto> AddCommentAsync(Guid bandId, Guid postId, CreatePostCommentRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var post = await db.Set<Post>()
            .FirstOrDefaultAsync(p => p.Id == postId && p.BandId == bandId && !p.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Post not found.", 404);

        if (request.ParentCommentId.HasValue)
        {
            var parent = await db.Set<PostComment>()
                .FirstOrDefaultAsync(c => c.Id == request.ParentCommentId.Value && !c.IsDeleted, ct)
                ?? throw new DomainException("NOT_FOUND", "Parent comment not found.", 404);

            if (parent.PostId != postId)
                throw new DomainException("VALIDATION_ERROR", "Parent comment does not belong to this post.", 400);
        }

        var comment = new PostComment
        {
            PostId = postId,
            AuthorMusicianId = musicianId,
            Content = request.Content.Trim(),
            ParentCommentId = request.ParentCommentId
        };

        db.Set<PostComment>().Add(comment);
        await db.SaveChangesAsync(ct);

        var musician = await db.Set<Musician>().FindAsync(new object[] { musicianId }, ct);

        return new PostCommentDto(
            comment.Id,
            comment.Content,
            musicianId,
            musician!.Name,
            comment.ParentCommentId,
            false,
            comment.CreatedAt
        );
    }

    public async Task<PagedResult<PostCommentDto>> GetCommentsPaginatedAsync(
        Guid bandId, Guid postId, Guid musicianId, PaginationRequest pagination, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var postExists = await db.Set<Post>()
            .AnyAsync(p => p.Id == postId && p.BandId == bandId && !p.IsDeleted, ct);
        if (!postExists)
            throw new DomainException("NOT_FOUND", "Post not found.", 404);

        var pageSize = pagination.EffectivePageSize;

        var query = db.Set<PostComment>()
            .Include(c => c.AuthorMusician)
            .Where(c => c.PostId == postId && !c.IsDeleted);

        if (pagination.Cursor is not null)
        {
            var (cursorDate, cursorId) = CursorHelper.Decode(pagination.Cursor);
            query = query.Where(c =>
                c.CreatedAt > cursorDate ||
                (c.CreatedAt == cursorDate && c.Id.CompareTo(cursorId) > 0));
        }

        // Comments ordered oldest first (ascending) for chronological reading
        return await query
            .OrderBy(c => c.CreatedAt)
            .ThenBy(c => c.Id)
            .ToPaginatedAsync(
                pageSize,
                c => new PostCommentDto(
                    c.Id,
                    c.Content,
                    c.AuthorMusicianId,
                    c.AuthorMusician.Name,
                    c.ParentCommentId,
                    c.IsDeleted,
                    c.CreatedAt),
                c => c.CreatedAt,
                c => c.Id,
                ct);
    }

    public async Task DeleteCommentAsync(Guid bandId, Guid postId, Guid commentId, Guid musicianId, CancellationToken ct)
    {
        var membership = await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var comment = await db.Set<PostComment>()
            .Include(c => c.Post)
            .FirstOrDefaultAsync(c => c.Id == commentId && c.PostId == postId && c.Post.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Comment not found.", 404);

        if (comment.AuthorMusicianId != musicianId && membership.Role != MemberRole.Administrator)
            throw new DomainException("FORBIDDEN", "You can only delete your own comments or be an admin.", 403);

        comment.IsDeleted = true;
        comment.Content = "[Deleted]";

        await db.SaveChangesAsync(ct);
    }

    public async Task AddReactionAsync(Guid bandId, Guid postId, AddPostReactionRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var post = await db.Set<Post>()
            .FirstOrDefaultAsync(p => p.Id == postId && p.BandId == bandId && !p.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Post not found.", 404);

        var existingReaction = await db.Set<PostReaction>()
            .FirstOrDefaultAsync(r => r.PostId == postId && r.MusicianId == musicianId, ct);

        if (existingReaction != null)
        {
            existingReaction.ReactionType = request.ReactionType.Trim();
        }
        else
        {
            var reaction = new PostReaction
            {
                PostId = postId,
                MusicianId = musicianId,
                ReactionType = request.ReactionType.Trim()
            };
            db.Set<PostReaction>().Add(reaction);
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task RemoveReactionAsync(Guid bandId, Guid postId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var reaction = await db.Set<PostReaction>()
            .Include(r => r.Post)
            .FirstOrDefaultAsync(r => r.PostId == postId && r.MusicianId == musicianId && r.Post.BandId == bandId, ct);

        if (reaction != null)
        {
            db.Set<PostReaction>().Remove(reaction);
            await db.SaveChangesAsync(ct);
        }
    }

    private static PostDto MapToDto(Post post, Guid currentMusicianId)
    {
        var reactions = GetReactionSummaries(post.Reactions, currentMusicianId);
        var commentCount = post.Comments.Count(c => !c.IsDeleted);

        return new PostDto(
            post.Id,
            post.Title,
            post.Content,
            post.Category,
            post.AuthorMusicianId,
            post.AuthorMusician.Name,
            post.IsPinned,
            post.PinnedAt,
            commentCount,
            reactions,
            post.CreatedAt,
            post.UpdatedAt
        );
    }

    private static IReadOnlyList<ReactionSummaryDto> GetReactionSummaries(ICollection<PostReaction> reactions, Guid currentMusicianId)
    {
        return reactions
            .GroupBy(r => r.ReactionType)
            .Select(g => new ReactionSummaryDto(
                g.Key,
                g.Count(),
                g.Any(r => r.MusicianId == currentMusicianId)
            ))
            .ToList();
    }
}
