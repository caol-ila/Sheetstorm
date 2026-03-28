namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Immutable audit log entry for configuration changes.
/// Tracks who changed what, when, and the before/after values.
/// </summary>
public class ConfigAudit
{
    public Guid Id { get; init; } = Guid.NewGuid();

    public Guid? BandId { get; set; }
    public Guid? MusicianId { get; set; }

    public string Level { get; set; } = string.Empty; // "Band", "user", "policy"
    public string Key { get; set; } = string.Empty;

    public string? OldValue { get; set; } // JSON string
    public string? NewValue { get; set; } // JSON string

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
