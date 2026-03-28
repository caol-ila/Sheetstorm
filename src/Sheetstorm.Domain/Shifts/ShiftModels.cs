using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Shifts;

// ── Requests ──────────────────────────────────────────────────────────────────

public record CreateShiftPlanRequest(
    [Required][StringLength(100, MinimumLength = 1)] string Title,
    [StringLength(500)] string? Description = null,
    Guid? EventId = null
);

public record UpdateShiftPlanRequest(
    [Required][StringLength(100, MinimumLength = 1)] string Title,
    [StringLength(500)] string? Description = null,
    Guid? EventId = null
);

public record CreateShiftRequest(
    [Required][StringLength(80, MinimumLength = 1)] string Name,
    [StringLength(200)] string? Description = null,
    [Required] TimeOnly StartTime = default,
    [Required] TimeOnly EndTime = default,
    [Range(1, 99)] int RequiredCount = 1,
    Guid? VoiceId = null
);

public record UpdateShiftRequest(
    [Required][StringLength(80, MinimumLength = 1)] string Name,
    [StringLength(200)] string? Description = null,
    [Required] TimeOnly StartTime = default,
    [Required] TimeOnly EndTime = default,
    [Range(1, 99)] int RequiredCount = 1,
    Guid? VoiceId = null
);

public record CreateShiftAssignmentRequest(
    Guid? MusicianId = null
);

public record UpdateShiftAssignmentStatusRequest(
    [Required] ShiftAssignmentStatus Status,
    [StringLength(200)] string? Notes = null
);

// ── Responses ─────────────────────────────────────────────────────────────────

public record ShiftPlanDto(
    Guid Id,
    Guid BandId,
    Guid? EventId,
    string Title,
    string? Description,
    Guid CreatedByMusicianId,
    string CreatedByName,
    int ShiftCount,
    int TotalAssignments,
    int TotalOpenSlots,
    DateTime CreatedAt
);

public record ShiftDto(
    Guid Id,
    Guid ShiftPlanId,
    string Name,
    string? Description,
    TimeOnly StartTime,
    TimeOnly EndTime,
    int RequiredCount,
    Guid? VoiceId,
    int AssignmentCount,
    int OpenSlots,
    IReadOnlyList<ShiftAssignmentDto> Assignments,
    DateTime CreatedAt
);

public record ShiftSummaryDto(
    Guid Id,
    Guid ShiftPlanId,
    string Name,
    TimeOnly StartTime,
    TimeOnly EndTime,
    int RequiredCount,
    int AssignmentCount,
    int OpenSlots
);

public record ShiftAssignmentDto(
    Guid Id,
    Guid ShiftId,
    Guid MusicianId,
    string MusicianName,
    Guid? AssignedByMusicianId,
    string? AssignedByName,
    ShiftAssignmentStatus Status,
    string? Notes,
    DateTime CreatedAt
);

public record MyShiftDto(
    Guid ShiftPlanId,
    string ShiftPlanTitle,
    Guid ShiftId,
    string ShiftName,
    TimeOnly StartTime,
    TimeOnly EndTime,
    ShiftAssignmentStatus Status,
    DateTime AssignedAt
);
