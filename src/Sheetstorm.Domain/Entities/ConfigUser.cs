namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A key-value config entry at the Nutzer (personal) level.
/// Synchronized bidirectionally with version-per-field conflict resolution.
/// </summary>
public class ConfigUser : BaseEntity
{
    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty; // JSON string

    public long Version { get; set; } = 1;
}
