namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A brass band or ensemble.
/// </summary>
public class Kapelle : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Beschreibung { get; set; }

    public string? Ort { get; set; }
    public string? LogoUrl { get; set; }

    public ICollection<Mitgliedschaft> Mitglieder { get; set; } = [];
    public ICollection<Stueck> Stuecke { get; set; } = [];
    public ICollection<Einladung> Einladungen { get; set; } = [];
    public ICollection<KapelleStimmenMapping> StimmenMappings { get; set; } = [];
}
