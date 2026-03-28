namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A brass band or ensemble.
/// </summary>
public class Kapelle : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Beschreibung { get; set; }

    public ICollection<Mitgliedschaft> Mitglieder { get; set; } = [];
    public ICollection<Stueck> Stuecke { get; set; } = [];
}
