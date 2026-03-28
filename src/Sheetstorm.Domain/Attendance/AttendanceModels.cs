using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Attendance;

// ── Requests ──────────────────────────────────────────────────
public record CreateAttendanceRecordRequest(
    [Required] Guid MusicianId,
    [Required] DateOnly Date,
    [Required] AttendanceStatus Status,
    Guid? EventId,
    [StringLength(500)] string? Notes
);

public record UpdateAttendanceRecordRequest(
    [Required] AttendanceStatus Status,
    [StringLength(500)] string? Notes
);

public record AttendanceStatsQueryRequest(
    DateOnly? StartDate,
    DateOnly? EndDate,
    Guid? MusicianId
);

// ── Responses ──────────────────────────────────────────────────
public record AttendanceRecordDto(
    Guid Id,
    Guid MusicianId,
    string MusicianName,
    DateOnly Date,
    AttendanceStatus Status,
    Guid? EventId,
    string? Notes,
    Guid RecordedByMusicianId,
    string RecordedByMusicianName,
    DateTime CreatedAt
);

public record AttendanceStatsDto(
    Guid MusicianId,
    string MusicianName,
    int TotalEvents,
    int PresentCount,
    int AbsentCount,
    int ExcusedCount,
    int LateCount,
    double AttendanceRate
);

public record BandAttendanceStatsDto(
    DateOnly StartDate,
    DateOnly EndDate,
    int TotalEvents,
    double AverageAttendanceRate,
    IReadOnlyList<AttendanceStatsDto> MusicianStats
);
