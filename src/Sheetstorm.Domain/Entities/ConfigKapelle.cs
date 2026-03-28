namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A key-value config entry at the Kapelle (organization) level.
/// Stored as JSONB in PostgreSQL.
/// </summary>
public class ConfigKapelle : BaseEntity
{
    public Guid KapelleId { get; set; }
    public Kapelle Kapelle { get; set; } = null!;

    public string Schluessel { get; set; } = string.Empty;
    public string Wert { get; set; } = string.Empty; // JSON string

    public Guid? AktualisiertVonId { get; set; }
    public Musiker? AktualisiertVon { get; set; }
}
