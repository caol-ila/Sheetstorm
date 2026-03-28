using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Domain.Kapellenverwaltung;

// ── Requests ──────────────────────────────────────────────────────────────────

public record KapelleErstellenRequest(
    [Required][StringLength(80, MinimumLength = 1)] string Name,
    [StringLength(500)] string? Beschreibung,
    [StringLength(100)] string? Ort
);

public record KapelleBearbeitenRequest(
    [Required][StringLength(80, MinimumLength = 1)] string Name,
    [StringLength(500)] string? Beschreibung,
    [StringLength(100)] string? Ort
);

public record EinladungErstellenRequest(
    MitgliedRolle Rolle = MitgliedRolle.Musiker,
    [Range(1, 30)] int GueltigkeitTage = 7
);

public record BeitretenRequest(
    [Required][StringLength(20, MinimumLength = 6)] string Code
);

public record RolleAendernRequest(
    [Required] MitgliedRolle Rolle
);

// ── Responses ─────────────────────────────────────────────────────────────────

public record KapelleDto(
    Guid Id,
    string Name,
    string? Beschreibung,
    string? Ort,
    int MitgliederAnzahl,
    MitgliedRolle MeineRolle,
    DateTime CreatedAt
);

public record KapelleDetailDto(
    Guid Id,
    string Name,
    string? Beschreibung,
    string? Ort,
    IReadOnlyList<MitgliedDto> Mitglieder,
    DateTime CreatedAt
);

public record MitgliedDto(
    Guid UserId,
    string Name,
    string Email,
    string? Instrument,
    MitgliedRolle Rolle,
    DateTime BeigetretenAm
);

public record EinladungDto(
    string Code,
    MitgliedRolle Rolle,
    DateTime ExpiresAt
);
