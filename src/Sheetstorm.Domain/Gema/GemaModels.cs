using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Gema;

// ── Requests ──────────────────────────────────────────────────────────────────

public record CreateGemaReportRequest(
    [Required][StringLength(200, MinimumLength = 1)] string Title,
    Guid? EventId,
    [Required] DateTime ReportDate,
    Guid? SetlistId = null,
    [StringLength(200)] string? EventLocation = null,
    [StringLength(50)] string? EventCategory = null,
    [StringLength(200)] string? Organizer = null
);

public record UpdateGemaReportRequest(
    [StringLength(200, MinimumLength = 1)] string? Title = null,
    [StringLength(200)] string? EventLocation = null,
    [StringLength(50)] string? EventCategory = null,
    [StringLength(200)] string? Organizer = null
);

public record AddGemaReportEntryRequest(
    [Required][StringLength(300, MinimumLength = 1)] string Title,
    [Required][StringLength(200, MinimumLength = 1)] string Composer,
    [StringLength(200)] string? Arranger = null,
    [StringLength(200)] string? Publisher = null,
    int? DurationSeconds = null,
    [StringLength(20)] string? WorkNumber = null,
    Guid? PieceId = null
);

public record UpdateGemaReportEntryRequest(
    [StringLength(300)] string? Title = null,
    [StringLength(200)] string? Composer = null,
    [StringLength(200)] string? Arranger = null,
    [StringLength(200)] string? Publisher = null,
    int? DurationSeconds = null,
    [StringLength(20)] string? WorkNumber = null
);

// ── Responses ─────────────────────────────────────────────────────────────────

public record GemaReportDto(
    Guid Id,
    Guid BandId,
    string Title,
    Guid? EventId,
    DateTime ReportDate,
    GemaReportStatus Status,
    Guid GeneratedByMusicianId,
    string GeneratedByName,
    string? ExportFormat,
    string? EventLocation,
    string? EventCategory,
    string? Organizer,
    Guid? SetlistId,
    DateTime? ExportedAt,
    IReadOnlyList<GemaReportEntryDto> Entries,
    DateTime CreatedAt
);

public record GemaReportSummaryDto(
    Guid Id,
    string Title,
    DateTime ReportDate,
    GemaReportStatus Status,
    string? EventLocation,
    string? EventCategory,
    int EntryCount,
    DateTime? ExportedAt,
    DateTime CreatedAt
);

public record GemaReportEntryDto(
    Guid Id,
    Guid? PieceId,
    string Composer,
    string Title,
    string? Arranger,
    string? Publisher,
    int? DurationSeconds,
    string? WorkNumber,
    int Position
);
