using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Domain.BandManagement;

// ── Requests ──────────────────────────────────────────────────────────────────

public record CreateBandRequest(
    [Required][StringLength(80, MinimumLength = 1)] string Name,
    [StringLength(500)] string? Description,
    [StringLength(100)] string? Location
);

public record UpdateBandRequest(
    [Required][StringLength(80, MinimumLength = 1)] string Name,
    [StringLength(500)] string? Description,
    [StringLength(100)] string? Location
);

public record CreateInvitationRequest(
    MemberRole Role = MemberRole.Musician,
    [Range(1, 30)] int ValidityDays = 7
);

public record JoinRequest(
    [Required][StringLength(20, MinimumLength = 6)] string Code
);

public record ChangeRoleRequest(
    [Required] MemberRole Role
);

// ── Voices-Mapping ───────────────────────────────────────────────────────────

public record VoiceMappingEntry(
    [Required][StringLength(100, MinimumLength = 1)] string Instrument,
    [Required][StringLength(100, MinimumLength = 1)] string Voice
);

public record SetVoiceMappingRequest(
    [Required] IReadOnlyList<VoiceMappingEntry> Entries
);

public record VoiceMappingResponse(
    IReadOnlyList<VoiceMappingEntry> Entries
);

public record UserVoicesRequest(
    [StringLength(100)] string? VoiceOverride
);

// ── Responses ─────────────────────────────────────────────────────────────────

public record BandDto(
    Guid Id,
    string Name,
    string? Description,
    string? Location,
    int MemberCount,
    MemberRole MyRole,
    DateTime CreatedAt
);

public record BandDetailDto(
    Guid Id,
    string Name,
    string? Description,
    string? Location,
    IReadOnlyList<MemberDto> Members,
    DateTime CreatedAt
);

public record MemberDto(
    Guid UserId,
    string Name,
    string Email,
    string? Instrument,
    MemberRole Role,
    string? VoiceOverride,
    DateTime JoinedAt
);

public record InvitationDto(
    string Code,
    MemberRole Role,
    DateTime ExpiresAt
);
