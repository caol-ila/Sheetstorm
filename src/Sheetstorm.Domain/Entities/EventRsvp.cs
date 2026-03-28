using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// RSVP response from a musician for an event.
/// </summary>
public class EventRsvp : BaseEntity
{
    public Guid EventId { get; set; }
    public Event Event { get; set; } = null!;

    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public RsvpStatus Status { get; set; } = RsvpStatus.Pending;
    public string? Comment { get; set; }
    public DateTime? RespondedAt { get; set; }
}
