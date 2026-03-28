namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A policy entry that can lock/force config settings at the Kapelle level.
/// When enforced, Nutzer and Gerät overrides for the affected key are blocked.
/// </summary>
public class ConfigPolicy : BaseEntity
{
    public Guid KapelleId { get; set; }
    public Kapelle Kapelle { get; set; } = null!;

    public string Schluessel { get; set; } = string.Empty;
    public string Wert { get; set; } = string.Empty; // JSON string

    public Guid? AktualisiertVonId { get; set; }
    public Musiker? AktualisiertVon { get; set; }
}
