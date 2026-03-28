using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Import;

// ── DTOs ──────────────────────────────────────────────────────────────────────

/// <summary>Metadata extracted by AI from an uploaded file.</summary>
public record PieceMetadataDto(
    string? Title,
    string? Composer,
    string? MusicalKey,
    string? TimeSignature,
    int? Tempo
);

/// <summary>Response DTO for a Stück.</summary>
public record PieceDto(
    Guid Id,
    string Title,
    string? Composer,
    string? Arranger,
    int? PublicationYear,
    string? MusicalKey,
    string? TimeSignature,
    int? Tempo,
    string? Description,
    Guid? BandId,
    Guid? MusicianId,
    string? OriginalFileName,
    ImportStatus ImportStatus,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

/// <summary>Request DTO for creating a Stück manually (without import).</summary>
public record PieceCreateDto(
    [Required][StringLength(200, MinimumLength = 1)] string Title,
    [StringLength(200)] string? Composer,
    [StringLength(200)] string? Arranger,
    int? PublicationYear,
    [StringLength(50)] string? MusicalKey,
    [StringLength(50)] string? TimeSignature,
    int? Tempo,
    [StringLength(2000)] string? Description
);

/// <summary>Request DTO for updating a Stück.</summary>
public record PieceUpdateDto(
    [Required][StringLength(200, MinimumLength = 1)] string Title,
    [StringLength(200)] string? Composer,
    [StringLength(200)] string? Arranger,
    int? PublicationYear,
    [StringLength(50)] string? MusicalKey,
    [StringLength(50)] string? TimeSignature,
    int? Tempo,
    [StringLength(2000)] string? Description
);

/// <summary>Response DTO for import result.</summary>
public record ImportResultDto(
    Guid PieceId,
    string Title,
    ImportStatus ImportStatus,
    PieceMetadataDto? ExtractedMetadata
);
