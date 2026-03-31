namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Change-log entry for delta-sync. Records each accepted field change per musician.
/// Used for pull responses: clients request all entries with Version > their last known version.
/// </summary>
public class SyncChangelog : BaseEntity
{
    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public string EntityType { get; set; } = string.Empty;  // "Piece", "SheetMusic", "PiecePage"
    public Guid EntityId { get; set; }
    public string Operation { get; set; } = string.Empty;  // "Create", "Update", "Delete"

    /// <summary>Set for Update operations. Null for Create/Delete.</summary>
    public string? FieldName { get; set; }

    /// <summary>The new value. For Create: serialized JSON of all fields. For Update: scalar value.</summary>
    public string? NewValue { get; set; }

    /// <summary>Client-provided timestamp of when the change occurred.</summary>
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Server-assigned monotonic version number.</summary>
    public long Version { get; set; }

    public Guid? DeviceId { get; set; }
}
