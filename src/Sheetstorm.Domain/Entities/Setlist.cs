using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A setlist represents a collection of pieces for a concert, rehearsal, or template.
/// </summary>
public class Setlist : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public SetlistType Type { get; set; }
    
    public Guid? EventId { get; set; }
    public DateOnly? Date { get; set; }
    public TimeOnly? StartTime { get; set; }

    public ICollection<SetlistEntry> Entries { get; set; } = [];
}
