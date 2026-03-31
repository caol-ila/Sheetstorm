using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Events;

// ── Requests ──────────────────────────────────────────────────────────────────

public record CreateEventRequest(
    [Required][StringLength(100, MinimumLength = 1)] string Title,
    [StringLength(1000)] string? Description,
    [Required] EventType EventType,
    [StringLength(200)] string? Location,
    [Required] DateTime StartDate,
    DateTime? EndDate,
    bool IsAllDay = false,
    [StringLength(100)] string? RepeatRule = null,
    Guid? SetlistId = null,
    [StringLength(500)] string? Notes = null,
    [StringLength(100)] string? DressCode = null,
    [StringLength(200)] string? MeetingPoint = null,
    DateTime? RsvpDeadline = null
);

public record UpdateEventRequest(
    [Required][StringLength(100, MinimumLength = 1)] string Title,
    [StringLength(1000)] string? Description,
    [Required] EventType EventType,
    [StringLength(200)] string? Location,
    [Required] DateTime StartDate,
    DateTime? EndDate,
    bool IsAllDay = false,
    [StringLength(100)] string? RepeatRule = null,
    Guid? SetlistId = null,
    [StringLength(500)] string? Notes = null,
    [StringLength(100)] string? DressCode = null,
    [StringLength(200)] string? MeetingPoint = null,
    DateTime? RsvpDeadline = null
);

public record SetRsvpRequest(
    [Required] RsvpStatus Status,
    [StringLength(200)] string? Comment = null
);

// ── Responses ─────────────────────────────────────────────────────────────────

public record EventDto(
    Guid Id,
    Guid BandId,
    string Title,
    string? Description,
    EventType EventType,
    string? Location,
    DateTime StartDate,
    DateTime? EndDate,
    bool IsAllDay,
    string? RepeatRule,
    Guid? SetlistId,
    string? Notes,
    string? DressCode,
    string? MeetingPoint,
    DateTime? RsvpDeadline,
    Guid CreatedByMusicianId,
    string CreatedByName,
    RsvpStatsDto Stats,
    DateTime CreatedAt
);

public record RsvpStatsDto(
    int Accepted,
    int Declined,
    int Tentative,
    int Pending
);

public record EventRsvpDto(
    Guid Id,
    Guid EventId,
    Guid MusicianId,
    string MusicianName,
    string? Instrument,
    RsvpStatus Status,
    string? Comment,
    DateTime? RespondedAt
);

public record SubstituteSuggestionDto(
    Guid MusicianId,
    string Name,
    string? Instrument,
    RsvpStatus CurrentStatus,
    int MatchScore,
    string MatchReason
);

public record CalendarEventDto(
    Guid Id,
    string Title,
    EventType EventType,
    DateTime StartDate,
    DateTime? EndDate,
    string? Location,
    RsvpStatus MyStatus,
    Guid BandId,
    string BandName,
    Guid? SetlistId
);
