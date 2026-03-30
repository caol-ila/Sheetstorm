using System.ComponentModel.DataAnnotations;

namespace Sheetstorm.Domain.Substitutes;

// ── Requests ──────────────────────────────────────────────────────────────────

public record CreateSubstituteAccessRequest(
    [Required][StringLength(100, MinimumLength = 1)] string Name,
    [EmailAddress] string? Email = null,
    Guid? VoiceId = null,
    Guid? EventId = null,
    DateTime? ExpiresAt = null,
    [StringLength(100)] string? Instrument = null,
    [StringLength(200)] string? Note = null
);

public record ExtendSubstituteAccessRequest(
    [Required] DateTime ExpiresAt
);

// ── Responses ─────────────────────────────────────────────────────────────────

public record SubstituteAccessDto(
    Guid Id,
    Guid BandId,
    string Name,
    string? Email,
    Guid? VoiceId,
    string? VoiceName,
    Guid? EventId,
    string? EventTitle,
    Guid GrantedByMusicianId,
    string GrantedByName,
    DateTime ExpiresAt,
    DateTime? RevokedAt,
    bool IsActive,
    DateTime? LastAccessedAt,
    string? Instrument,
    string? Note,
    DateTime CreatedAt
);

public record SubstituteAccessCreatedDto(
    Guid Id,
    Guid BandId,
    string Name,
    string? Email,
    Guid? VoiceId,
    Guid? EventId,
    string Token,
    string Link,
    string QrCodeData,
    DateTime ExpiresAt,
    bool IsActive,
    string? Instrument,
    string? Note,
    DateTime CreatedAt
);

public record SubstituteValidationDto(
    Guid Id,
    string Name,
    string? Instrument,
    Guid BandId,
    string BandName,
    Guid? VoiceId,
    string? VoiceName,
    Guid? EventId,
    string? EventTitle,
    DateTime? EventDate,
    string? Note,
    DateTime ExpiresAt
);
