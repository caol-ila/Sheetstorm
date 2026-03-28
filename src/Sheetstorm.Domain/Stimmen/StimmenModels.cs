using System.ComponentModel.DataAnnotations;

namespace Sheetstorm.Domain.Stimmen;

// ── Fallback result ─────────────────────────────────────────────────────────

/// <summary>
/// Result of the 6-step Stimmen fallback algorithm.
/// </summary>
public record StimmenFallbackResult(
    Guid? StimmeId,
    string? Bezeichnung,
    int? FallbackSchritt,
    string? FallbackGrund
);

// ── Stimmen list response ───────────────────────────────────────────────────

public record StimmeDto(
    Guid Id,
    string Bezeichnung,
    string? InstrumentTyp,
    string? InstrumentFamilie,
    int? StimmenNummer,
    int SeitenAnzahl
);

public record StimmenListeResponse(
    Guid StueckId,
    IReadOnlyList<StimmeDto> Stimmen,
    StimmenFallbackResult Vorausgewaehlt
);

// ── Resolved Stimme response ────────────────────────────────────────────────

public record ResolvedStimmeResponse(
    Guid StueckId,
    StimmenFallbackResult Ergebnis
);

// ── Nutzer instrument profile ───────────────────────────────────────────────

public record NutzerInstrumentDto(
    Guid Id,
    string InstrumentTyp,
    string InstrumentBezeichnung,
    int Sortierung,
    IReadOnlyList<StimmeVorauswahlDto> StandardStimmen
);

public record StimmeVorauswahlDto(
    Guid KapelleId,
    string KapelleName,
    string StimmeBezeichnung
);

public record StimmenProfilResponse(
    Guid NutzerId,
    IReadOnlyList<NutzerInstrumentDto> Instrumente
);

// ── Nutzer instrument profile requests ──────────────────────────────────────

public record InstrumentEintrag(
    [Required][StringLength(50, MinimumLength = 1)] string InstrumentTyp,
    [Required][StringLength(100, MinimumLength = 1)] string InstrumentBezeichnung,
    IReadOnlyList<StimmeVorauswahlEintrag>? StandardStimmen
);

public record StimmeVorauswahlEintrag(
    [Required] Guid KapelleId,
    [Required][StringLength(100, MinimumLength = 1)] string StimmeBezeichnung
);

public record StimmenProfilSetzenRequest(
    [Required] IReadOnlyList<InstrumentEintrag> Instrumente
);
