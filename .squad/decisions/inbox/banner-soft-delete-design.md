# Design Decision: Post Soft-Delete Strategy (#110)

**Author:** Banner  
**Date:** 2026-03-30  
**Status:** Implemented

## Problem

Posts used hard-delete (`db.Remove(post)`) while PostComments used soft-delete (`IsDeleted` flag). This inconsistency could orphan comment records or break comment thread references when a post with comments was deleted.

## Decision

**Conditional delete strategy based on presence of child comments:**

- **Posts WITH active comments → Soft-delete:**  
  Set `IsDeleted = true`, `DeletedAt = DateTime.UtcNow`, clear `Title` and `Content` to `"[Gelöscht]"`, unpin. The post shell is preserved so existing comment threads remain intact and navigable.

- **Posts WITHOUT active comments → Hard-delete:**  
  Remove the record entirely. No orphan risk, no wasted storage.

- **Already soft-deleted posts → throw `NOT_FOUND` (404):**  
  Prevents double-delete confusion. Idempotent from the caller's perspective.

## Implementation

### New fields on `Post` entity
```csharp
public bool IsDeleted { get; set; }      // default false
public DateTime? DeletedAt { get; set; } // set on soft-delete
```

### `PostService.DeleteAsync` branching logic
```csharp
var hasActiveComments = post.Comments.Any(c => !c.IsDeleted);
if (hasActiveComments)
{
    post.IsDeleted = true;
    post.DeletedAt = DateTime.UtcNow;
    post.Title = "[Gelöscht]";
    post.Content = "[Gelöscht]";
    post.IsPinned = false;
}
else
{
    db.Set<Post>().Remove(post);
}
```

### Query changes
- `GetAllAsync`: filters `!p.IsDeleted` — deleted posts do not appear in listings
- `GetByIdAsync`: **no filter** — soft-deleted posts are still fetchable so their comment thread can be read
- `UpdateAsync`, `PinAsync`, `UnpinAsync`, `AddCommentAsync`, `AddReactionAsync`: all add `&& !p.IsDeleted` to prevent mutations on deleted posts

### Migration
`20260330215615_PostSoftDelete` — adds `IsDeleted` (bool, default false) and `DeletedAt` (nullable DateTime) to the Posts table.

## Alternatives Considered

1. **Always hard-delete + cascade comments:** Would destroy comment history. Rejected.
2. **Always soft-delete:** Would leave clutter for posts with no comments. Rejected as unnecessary complexity.
3. **Separate archive table:** Over-engineering for this use case. Rejected.

## Trade-offs

- `GetByIdAsync` returns soft-deleted posts (with cleared content). The client can render a "[Gelöscht]" placeholder and still show the comment thread. This is the intended UX.
- Comment counts in listings (`PostDto.CommentCount`) only count non-deleted comments. Soft-deleted post shells are never included in `GetAllAsync`.
