using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A task assigned within a band context, tracked from Open → InProgress → Done.
/// </summary>
public class BandTask : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }

    public BandTaskStatus Status { get; set; } = BandTaskStatus.Open;
    public TaskPriority Priority { get; set; } = TaskPriority.Medium;

    public DateTime? DueDate { get; set; }

    public Guid? EventId { get; set; }
    public Event? Event { get; set; }

    public Guid CreatedByMusicianId { get; set; }
    public Musician CreatedByMusician { get; set; } = null!;

    public ICollection<BandTaskAssignment> Assignments { get; set; } = [];
}
