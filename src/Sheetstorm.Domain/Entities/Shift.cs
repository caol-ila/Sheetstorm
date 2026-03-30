namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A single shift within a shift plan (e.g. "Bar duty 14:00–18:00").
/// </summary>
public class Shift : BaseEntity
{
    public Guid ShiftPlanId { get; set; }
    public ShiftPlan ShiftPlan { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public int RequiredCount { get; set; }

    public Guid? VoiceId { get; set; }
    public Voice? Voice { get; set; }

    public ICollection<ShiftAssignment> Assignments { get; set; } = [];
}
