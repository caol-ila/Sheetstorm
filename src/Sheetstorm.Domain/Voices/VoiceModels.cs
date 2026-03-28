using System.ComponentModel.DataAnnotations;

namespace Sheetstorm.Domain.Voices;

// ── Fallback result ─────────────────────────────────────────────────────────

/// <summary>
/// Result of the 6-step Voices fallback algorithm.
/// </summary>
public record VoiceFallbackResult(
    Guid? VoiceId,
    string? Label,
    int? FallbackSchritt,
    string? FallbackGrund
);

// ── Voices list response ───────────────────────────────────────────────────

public record VoiceDto(
    Guid Id,
    string Label,
    string? InstrumentType,
    string? InstrumentFamily,
    int? VoiceNumber,
    int PageCount
);

public record VoiceListResponse(
    Guid PieceId,
    IReadOnlyList<VoiceDto> Voices,
    VoiceFallbackResult Preselected
);

// ── Resolved Voice response ────────────────────────────────────────────────

public record ResolvedVoiceResponse(
    Guid PieceId,
    VoiceFallbackResult Ergebnis
);

// ── Nutzer instrument profile ───────────────────────────────────────────────

public record UserInstrumentDto(
    Guid Id,
    string InstrumentType,
    string InstrumentLabel,
    int SortOrder,
    IReadOnlyList<VoicePreselectionDto> DefaultVoices
);

public record VoicePreselectionDto(
    Guid BandId,
    string BandName,
    string VoiceLabel
);

public record VoiceProfileResponse(
    Guid UserId,
    IReadOnlyList<UserInstrumentDto> Instruments
);

// ── Nutzer instrument profile requests ──────────────────────────────────────

public record InstrumentEntry(
    [Required][StringLength(50, MinimumLength = 1)] string InstrumentType,
    [Required][StringLength(100, MinimumLength = 1)] string InstrumentLabel,
    IReadOnlyList<VoicePreselectionEntry>? DefaultVoices
);

public record VoicePreselectionEntry(
    [Required] Guid BandId,
    [Required][StringLength(100, MinimumLength = 1)] string VoiceLabel
);

public record SetVoiceProfileRequest(
    [Required] IReadOnlyList<InstrumentEntry> Instruments
);
