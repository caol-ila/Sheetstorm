using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Import;

// ── DTOs ──────────────────────────────────────────────────────────────────────

/// <summary>Metadata extracted by AI from an uploaded file.</summary>
public record StueckMetadataDto(
    string? Titel,
    string? Komponist,
    string? Tonart,
    string? Taktart,
    int? Tempo
);

/// <summary>Response DTO for a Stück.</summary>
public record StueckDto(
    Guid Id,
    string Titel,
    string? Komponist,
    string? Arrangeur,
    int? VeroeffentlichungsJahr,
    string? Tonart,
    string? Taktart,
    int? Tempo,
    string? Beschreibung,
    Guid? KapelleId,
    Guid? MusikerId,
    string? OriginalDateiname,
    ImportStatus ImportStatus,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

/// <summary>Request DTO for creating a Stück manually (without import).</summary>
public record StueckCreateDto(
    [Required][StringLength(200, MinimumLength = 1)] string Titel,
    [StringLength(200)] string? Komponist,
    [StringLength(200)] string? Arrangeur,
    int? VeroeffentlichungsJahr,
    [StringLength(50)] string? Tonart,
    [StringLength(50)] string? Taktart,
    int? Tempo,
    [StringLength(2000)] string? Beschreibung
);

/// <summary>Request DTO for updating a Stück.</summary>
public record StueckUpdateDto(
    [Required][StringLength(200, MinimumLength = 1)] string Titel,
    [StringLength(200)] string? Komponist,
    [StringLength(200)] string? Arrangeur,
    int? VeroeffentlichungsJahr,
    [StringLength(50)] string? Tonart,
    [StringLength(50)] string? Taktart,
    int? Tempo,
    [StringLength(2000)] string? Beschreibung
);

/// <summary>Response DTO for import result.</summary>
public record ImportResultDto(
    Guid StueckId,
    string Titel,
    ImportStatus ImportStatus,
    StueckMetadataDto? ExtractedMetadata
);
