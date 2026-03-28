namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A shift plan for organizing tasks during events (festivals, etc.).
/// </summary>
public class ShiftPlan : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public Guid? EventId { get; set; }
    public Event? Event { get; set; }

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }

    public Guid CreatedByMusicianId { get; set; }
    public Musician CreatedByMusician { get; set; } = null!;

    public ICollection<Shift> Shifts { get; set; } = [];
}
