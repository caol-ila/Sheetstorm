namespace Sheetstorm.Domain.Music;

/// <summary>
/// Korrektur-Annotation einer einzelnen Detection (Notenkopf, Pause, ...) durch
/// einen Notenverwalter. Die Annotation referenziert die Position im
/// Pipeline-Render-Pixel-System (page_index + bbox), nicht die OmrDetection-Id —
/// damit überlebt sie eine Re-Run der Pipeline (deterministische
/// Position-basierte Zuordnung).
///
/// Anwendungsfälle:
/// - Notenverwalter klickt auf einen erkannten NH und wählt:
///   "Falscher Pitch" → CorrectionJson = { "midi": 64, "step": "E", ... }
///   "Falsche Dauer" → CorrectionJson = { "duration": 4 }
///   "Falsche Klassifikation" → CorrectionJson = { "kind": "Open" }
///   "Keine Note (False-Positive)" → CorrectionJson = null
/// - Notenverwalter klickt auf eine leere Stelle → MissedNote
///   CorrectionJson = { "midi": 60, "duration": 4, "kind": "Filled" }
/// - Free-Form-Kommentar (Comment) — z.B. "unklare Stelle"
///
/// Diese Daten dienen sowohl als Trainings-Korpus für die OMR-Pipeline als
/// auch für eine korrigierte Anzeige in der App.
/// </summary>
public sealed class PartAnnotation
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid PartId { get; private set; }
    public Guid CreatedByUserId { get; private set; }

    /// 0-basierter Page-Index im Pipeline-Render.
    public int PageIndex { get; private set; }

    // Bbox im Pipeline-Render-Pixel-System (entspricht DetectionPage.width/height).
    public int BboxX { get; private set; }
    public int BboxY { get; private set; }
    public int BboxW { get; private set; }
    public int BboxH { get; private set; }

    public PartAnnotationKind Kind { get; private set; }

    /// JSON mit Korrekturdaten (siehe Klassen-Doku). Nullable.
    public string? CorrectionJson { get; private set; }

    /// Optionaler Freitext-Kommentar.
    public string? Comment { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; private set; } = DateTimeOffset.UtcNow;

    private PartAnnotation() { }

    public static PartAnnotation Create(
        Guid partId,
        Guid userId,
        int pageIndex,
        int x, int y, int w, int h,
        PartAnnotationKind kind,
        string? correctionJson = null,
        string? comment = null)
    {
        if (pageIndex < 0) throw new ArgumentOutOfRangeException(nameof(pageIndex));
        if (w <= 0 || h <= 0) throw new ArgumentException("Bbox-Dimensionen müssen > 0 sein");
        return new PartAnnotation
        {
            PartId = partId,
            CreatedByUserId = userId,
            PageIndex = pageIndex,
            BboxX = x,
            BboxY = y,
            BboxW = w,
            BboxH = h,
            Kind = kind,
            CorrectionJson = correctionJson,
            Comment = comment,
        };
    }

    public void Update(PartAnnotationKind kind, string? correctionJson, string? comment)
    {
        Kind = kind;
        CorrectionJson = correctionJson;
        Comment = comment;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}

/// <summary>
/// Art der Korrektur an einer Detection.
/// </summary>
public enum PartAnnotationKind
{
    /// Erkannter NH ist gar keine Note (False-Positive). Wird beim Training
    /// als "Negativ-Beispiel" verwendet.
    NotANote = 0,
    /// NH erkannt, aber Pitch ist falsch. CorrectionJson enthält den korrekten
    /// Pitch (midi/step/alter/octave).
    WrongPitch = 1,
    /// NH erkannt, aber Notenwert (Duration) ist falsch. CorrectionJson enthält
    /// die korrekte Duration (in Pipeline-Tick-Einheit, divisions=4 → 4=Viertel).
    WrongDuration = 2,
    /// NH erkannt, aber falsche Klassifikation (Filled vs Open vs Whole).
    /// CorrectionJson enthält den korrekten Kind.
    WrongKind = 3,
    /// User markiert eine Stelle wo ein NH fehlt (False-Negative).
    /// CorrectionJson enthält den vollständigen Pitch+Duration+Kind.
    MissedNote = 4,
    /// Freitext-Kommentar zu einer Stelle (keine konkrete Korrektur).
    Comment = 5,
    /// Notenverwalter bestätigt, dass DIESE Detection korrekt erkannt wurde
    /// (Pitch + Duration + Kind alles richtig). Wird beim Training als
    /// "Positiv-Beispiel" verwendet.
    Confirmed = 6,
    /// Notenverwalter bestätigt einen rechteckigen Bereich als komplett korrekt:
    /// alle Detections deren Center in diesem Bbox liegen gelten als "richtig".
    /// Reduziert Klick-Aufwand bei sauberen Stellen — der Verwalter kann eine
    /// ganze Zeile / einen Takt mit einem Drag bestätigen.
    /// CorrectionJson optional leer; Bbox = der bestätigte Bereich.
    RegionConfirmed = 7,
}

