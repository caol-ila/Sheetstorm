using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Setlists;

// ── Requests ──────────────────────────────────────────────────
public record CreateSetlistRequest(
    [Required][StringLength(120, MinimumLength = 1)] string Name,
    [StringLength(500)] string? Description,
    [Required] SetlistType Type,
    DateOnly? Date,
    TimeOnly? StartTime,
    Guid? EventId
);

public record UpdateSetlistRequest(
    [Required][StringLength(120, MinimumLength = 1)] string Name,
    [StringLength(500)] string? Description,
    [Required] SetlistType Type,
    DateOnly? Date,
    TimeOnly? StartTime,
    Guid? EventId
);

public record AddSetlistEntryRequest(
    Guid? PieceId,
    bool IsPlaceholder,
    [StringLength(150)] string? PlaceholderTitle,
    [StringLength(100)] string? PlaceholderComposer,
    [StringLength(250)] string? Notes,
    int? DurationSeconds
);

public record UpdateSetlistEntryRequest(
    [StringLength(250)] string? Notes,
    int? DurationSeconds
);

public record ReorderEntriesRequest(
    [Required] IReadOnlyList<Guid> EntryIds
);

// ── Responses ──────────────────────────────────────────────────
public record SetlistDto(
    Guid Id,
    string Name,
    string? Description,
    SetlistType Type,
    DateOnly? Date,
    TimeOnly? StartTime,
    Guid? EventId,
    int EntryCount,
    int? TotalDurationSeconds,
    DateTime CreatedAt
);

public record SetlistDetailDto(
    Guid Id,
    string Name,
    string? Description,
    SetlistType Type,
    DateOnly? Date,
    TimeOnly? StartTime,
    Guid? EventId,
    IReadOnlyList<SetlistEntryDto> Entries,
    int? TotalDurationSeconds,
    DateTime CreatedAt
);

public record SetlistEntryDto(
    Guid Id,
    int Position,
    Guid? PieceId,
    string? PieceTitle,
    string? PieceComposer,
    bool IsPlaceholder,
    string? PlaceholderTitle,
    string? PlaceholderComposer,
    string? Notes,
    int? DurationSeconds
);
