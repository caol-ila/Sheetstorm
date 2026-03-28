using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.MediaLinks;

// ── Requests ──────────────────────────────────────────────────
public record CreateMediaLinkRequest(
    [Required][Url][StringLength(2048, MinimumLength = 1)] string Url,
    [StringLength(200)] string? Title,
    [StringLength(500)] string? Description
);

public record UpdateMediaLinkRequest(
    [StringLength(200)] string? Title,
    [StringLength(500)] string? Description
);

// ── Responses ──────────────────────────────────────────────────
public record MediaLinkDto(
    Guid Id,
    string Url,
    MediaLinkType Type,
    string? Title,
    string? Description,
    string? ThumbnailUrl,
    int? DurationSeconds,
    Guid AddedByMusicianId,
    string AddedByMusicianName,
    DateTime CreatedAt
);
