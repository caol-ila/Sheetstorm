namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A key-value config entry at the Band (organization) level.
/// Stored as JSONB in PostgreSQL.
/// </summary>
public class ConfigBand : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty; // JSON string

    public Guid? UpdatedById { get; set; }
    public Musician? UpdatedBy { get; set; }
}
