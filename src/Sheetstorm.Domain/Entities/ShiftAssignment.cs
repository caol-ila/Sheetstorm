using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Assignment of a musician to a specific shift.
/// </summary>
public class ShiftAssignment : BaseEntity
{
    public Guid ShiftId { get; set; }
    public Shift Shift { get; set; } = null!;

    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public Guid? AssignedByMusicianId { get; set; }
    public Musician? AssignedByMusician { get; set; }

    public ShiftAssignmentStatus Status { get; set; } = ShiftAssignmentStatus.Assigned;
    public string? Notes { get; set; }
}
