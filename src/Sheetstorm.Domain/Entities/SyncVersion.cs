namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Tracks the current sync version counter for a musician's personal collection.
/// One record per musician. The version increments monotonically with each accepted push.
/// </summary>
public class SyncVersion
{
    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public long CurrentVersion { get; set; } = 0;
    public DateTime? LastSyncAt { get; set; }
}
