namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Immutable audit log entry for configuration changes.
/// Tracks who changed what, when, and the before/after values.
/// </summary>
public class ConfigAudit
{
    public Guid Id { get; init; } = Guid.NewGuid();

    public Guid? KapelleId { get; set; }
    public Guid? MusikerId { get; set; }

    public string Ebene { get; set; } = string.Empty; // "kapelle", "nutzer", "policy"
    public string Schluessel { get; set; } = string.Empty;

    public string? AlterWert { get; set; } // JSON string
    public string? NeuerWert { get; set; } // JSON string

    public DateTime Zeitstempel { get; set; } = DateTime.UtcNow;
}
