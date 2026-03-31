using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Pagination;

namespace Sheetstorm.Infrastructure.Pagination;

/// <summary>
/// Helpers for cursor-based pagination on already-filtered and ordered queries.
/// The caller is responsible for applying cursor WHERE clauses and ordering.
/// This method handles: fetch N+1, determine HasMore, encode next cursor.
/// </summary>
public static class PaginationExtensions
{
    /// <summary>
    /// Executes a paginated query. The query must already be filtered (including cursor
    /// WHERE clause) and ordered. This method takes pageSize+1 items to detect HasMore,
    /// maps results, and encodes the next cursor from the last item.
    /// </summary>
    public static async Task<PagedResult<TResult>> ToPaginatedAsync<TSource, TResult>(
        this IQueryable<TSource> orderedFilteredQuery,
        int effectivePageSize,
        Func<TSource, TResult> mapper,
        Func<TSource, DateTime> createdAtSelector,
        Func<TSource, Guid> idSelector,
        CancellationToken ct = default)
    {
        var items = await orderedFilteredQuery
            .Take(effectivePageSize + 1)
            .ToListAsync(ct);

        var hasMore = items.Count > effectivePageSize;
        if (hasMore)
            items = items.Take(effectivePageSize).ToList();

        string? nextCursor = null;
        if (hasMore && items.Count > 0)
        {
            var last = items[^1];
            nextCursor = CursorHelper.Encode(createdAtSelector(last), idSelector(last));
        }

        var mapped = items.Select(mapper).ToList();
        return new PagedResult<TResult>(mapped, nextCursor, hasMore, effectivePageSize);
    }
}
