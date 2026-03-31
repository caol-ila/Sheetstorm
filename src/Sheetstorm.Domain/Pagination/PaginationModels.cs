namespace Sheetstorm.Domain.Pagination;

/// <summary>
/// Cursor-based pagination request. Cursor is opaque to clients.
/// </summary>
public record PaginationRequest(
    string? Cursor = null,
    int PageSize = 20
)
{
    public const int MaxPageSize = 100;
    public const int DefaultPageSize = 20;

    /// <summary>
    /// Returns an effective page size clamped between 1 and MaxPageSize.
    /// </summary>
    public int EffectivePageSize => Math.Clamp(PageSize, 1, MaxPageSize);
}

/// <summary>
/// Cursor-based pagination response wrapper.
/// </summary>
public record PagedResult<T>(
    IReadOnlyList<T> Items,
    string? Cursor,
    bool HasMore,
    int PageSize
);
