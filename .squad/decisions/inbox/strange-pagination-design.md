# Decision: Cursor-Based Pagination Design

**By:** Strange (Principal Backend Engineer)  
**Date:** 2026-04-16  
**Status:** Implemented (CR#7)

## Context

All list endpoints returned unbounded results. For a Blaskapelle with growing data (posts, events, comments), this becomes a performance and UX issue.

## Decision

**Cursor-based pagination** (not offset-based) for all list endpoints.

### Why Cursor Over Offset

- **No page drift:** New items added between page requests don't cause duplicates or gaps
- **Consistent performance:** Cursor filter uses indexed columns (CreatedAt + Id), no `OFFSET` scan
- **Better for real-time feeds:** Posts/events are frequently added; cursor stays stable

### Cursor Format

Base64-encoded JSON: `{"CreatedAt":"2025-06-15T10:30:00Z","Id":"guid"}`

- **Opaque to clients** — clients pass cursor as-is, no need to understand structure
- **Stable ordering** — CreatedAt + Id guarantees uniqueness (Id breaks ties for same-millisecond inserts)
- **Invalid cursors** return HTTP 400 with `INVALID_CURSOR` error code

### Defaults & Limits

- Default page size: **20**
- Maximum page size: **100** (capped silently via `Math.Clamp`)
- No cursor + no pageSize = first page with 20 items (backward compatible)

### Response Shape

```json
{
  "items": [...],
  "cursor": "base64-encoded-string-or-null",
  "hasMore": true,
  "pageSize": 20
}
```

### Endpoints Applied

| Endpoint | Order | Rationale |
|----------|-------|-----------|
| `GET /api/bands/{bandId}/posts` | CreatedAt DESC | Newest posts first (news feed) |
| `GET /api/bands/{bandId}/events` | CreatedAt DESC | Recently created events first |
| `GET /api/bands/{bandId}/posts/{postId}/comments` | CreatedAt ASC | Chronological reading |

### Extension Points

Other list endpoints (polls, setlists, members, etc.) can adopt pagination by:
1. Adding `PaginationRequest` parameter to service method
2. Applying cursor WHERE clause on the entity's CreatedAt/Id
3. Calling `.ToPaginatedAsync()` on the ordered query

### Files

- **Domain:** `src/Sheetstorm.Domain/Pagination/PaginationModels.cs`
- **Infrastructure:** `src/Sheetstorm.Infrastructure/Pagination/CursorHelper.cs`, `PaginationExtensions.cs`
- **Services:** PostService, EventService (new paginated methods added alongside existing unpaginated ones)
- **Controllers:** PostController, EventController (GetAll/GetEvents now return `PagedResult<T>`)
- **Tests:** `tests/Sheetstorm.Tests/Pagination/` (26 tests)

## Alternatives Considered

1. **Offset-based pagination** — Rejected: page drift with real-time data, O(n) skip cost at scale
2. **Keyset pagination on StartDate (events)** — Rejected for consistency: all endpoints use CreatedAt + Id as cursor base. Events sorted by StartDate for the unpaginated calendar view remain unchanged.

## Impact

- **Flutter:** Clients must handle the new `PagedResult<T>` response shape. Existing calls without `cursor`/`pageSize` params still work (first page returned).
- **Performance:** Bounded result sets prevent full-table scans.
