namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A key-value config entry at the Nutzer (personal) level.
/// Synchronized bidirectionally with version-per-field conflict resolution.
/// </summary>
public class ConfigNutzer : BaseEntity
{
    public Guid MusikerId { get; set; }
    public Musiker Musiker { get; set; } = null!;

    public string Schluessel { get; set; } = string.Empty;
    public string Wert { get; set; } = string.Empty; // JSON string

    public long Version { get; set; } = 1;
}
