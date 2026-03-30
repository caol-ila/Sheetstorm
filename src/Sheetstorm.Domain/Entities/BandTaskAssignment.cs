namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Assignment of a band member to a BandTask (N:M relationship).
/// </summary>
public class BandTaskAssignment : BaseEntity
{
    public Guid BandTaskId { get; set; }
    public BandTask BandTask { get; set; } = null!;

    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;
}
