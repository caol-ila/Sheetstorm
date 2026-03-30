using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A record of a musician's attendance at an event or rehearsal.
/// </summary>
public class AttendanceRecord : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public Guid? EventId { get; set; }
    
    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public DateOnly Date { get; set; }
    public AttendanceStatus Status { get; set; }
    
    public string? Notes { get; set; }
    
    public Guid RecordedByMusicianId { get; set; }
    public Musician RecordedByMusician { get; set; } = null!;
}
