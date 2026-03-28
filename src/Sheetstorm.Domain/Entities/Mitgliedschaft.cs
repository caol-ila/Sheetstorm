namespace Sheetstorm.Domain.Entities;

/// <summary>
/// N:M relationship between Musiker and Kapelle with role assignment.
/// </summary>
public class Mitgliedschaft : BaseEntity
{
    public Guid MusikerID { get; set; }
    public Musiker Musiker { get; set; } = null!;

    public Guid KapelleID { get; set; }
    public Kapelle Kapelle { get; set; } = null!;

    public MitgliedRolle Rolle { get; set; } = MitgliedRolle.Musiker;
    public bool IstAktiv { get; set; } = true;

    /// <summary>
    /// Personal Stimmen override for this member in this Kapelle.
    /// When set, takes precedence over the Kapelle default Stimmen mapping.
    /// </summary>
    public string? StimmenOverride { get; set; }
}

public enum MitgliedRolle
{
    Musiker,
    Registerführer,
    Dirigent,
    Notenwart,
    Administrator
}
