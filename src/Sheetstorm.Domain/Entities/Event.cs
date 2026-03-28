using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A scheduled event (concert, rehearsal, meeting, etc.) for a band.
/// </summary>
public class Event : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public EventType EventType { get; set; }
    public string? Location { get; set; }

    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsAllDay { get; set; }
    public string? RepeatRule { get; set; }

    public Guid? SetlistId { get; set; }
    public Setlist? Setlist { get; set; }

    public string? Notes { get; set; }
    public string? DressCode { get; set; }
    public string? MeetingPoint { get; set; }
    public DateTime? RsvpDeadline { get; set; }

    public Guid CreatedByMusicianId { get; set; }
    public Musician CreatedByMusician { get; set; } = null!;

    public ICollection<EventRsvp> Rsvps { get; set; } = [];
}
