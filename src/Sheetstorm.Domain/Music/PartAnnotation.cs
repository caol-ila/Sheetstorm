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
    /// Erkanntes Element ist eigentlich etwas anderes (z.B. "ist Notenschlüssel,
    /// kein Notenkopf"). CorrectionJson hat das Feld "symbol" mit dem korrekten
    /// SymbolType (siehe <see cref="SymbolType"/>) plus optionale Detail-Felder.
    WrongSymbol = 8,
    /// Bereich enthält ein Symbol das die Pipeline nicht erkannt hat
    /// (z.B. fehlende Volta-Klammer, fehlender Crescendo-Hairpin).
    /// CorrectionJson hat das Feld "symbol" mit dem SymbolType.
    MissedSymbol = 9,
}

/// <summary>
/// Taxonomie aller Symboltypen die in einer Notenseite vorkommen können.
/// Wird in <see cref="PartAnnotation.CorrectionJson"/> als <c>{"symbol": "..."}</c>
/// gespeichert. Die Pipeline-Detections nutzen aktuell nur Note/Rest, alle anderen
/// werden über User-Annotations ergänzt (oder später auch automatisch erkannt).
/// </summary>
public enum SymbolType
{
    // Hauptkategorien
    /// <summary>Ton mit Pitch + Duration. CorrectionJson zusätzliche Felder:
    /// midi (0-127), step (C/D/E/F/G/A/B), alter (-2..2), octave (0-9), duration (1=16th, 2=8th, 4=quarter, 8=half, 16=whole).</summary>
    Note = 0,
    /// <summary>Pause mit Duration. CorrectionJson Feld: duration.</summary>
    Rest = 1,

    // Notenschlüssel
    ClefTreble = 100,
    ClefBass = 101,
    ClefAlto = 102,
    ClefTenor = 103,
    ClefPercussion = 104,
    ClefOther = 109,

    // Taktangabe
    /// <summary>z.B. 4/4. CorrectionJson Felder: beats, beatType.</summary>
    TimeSignature = 200,
    /// <summary>Common Time C-Symbol (= 4/4).</summary>
    TimeSignatureCommon = 201,
    /// <summary>Cut Time (alla breve, = 2/2).</summary>
    TimeSignatureCut = 202,

    // Tonart-Vorzeichen
    /// <summary>Vorzeichen-Block am Zeilenanfang. CorrectionJson Feld: fifths (-7..+7, negativ = Bs, positiv = Kreuze).</summary>
    KeySignature = 300,

    // Taktstriche & Wiederholungen
    Barline = 400,
    BarlineDouble = 401,
    BarlineFinal = 402,
    RepeatStart = 410,
    RepeatEnd = 411,
    Volta1 = 420,
    Volta2 = 421,
    VoltaOther = 422,

    // Sprungmarken
    Coda = 500,
    Segno = 501,
    DalCapo = 502,
    DalSegno = 503,
    Fine = 504,
    DalCapoAlFine = 505,
    DalSegnoAlFine = 506,
    DalSegnoAlCoda = 507,

    // Dynamik (statisch)
    DynamicPianissimo = 600,    // pp
    DynamicPiano = 601,          // p
    DynamicMezzopiano = 602,     // mp
    DynamicMezzoforte = 603,     // mf
    DynamicForte = 604,          // f
    DynamicFortissimo = 605,     // ff
    DynamicSfz = 606,            // sfz
    DynamicFp = 607,             // fp

    // Dynamik (Verlauf - Hairpins)
    HairpinCrescendo = 620,      // <
    HairpinDecrescendo = 621,    // >
    DynamicTextCrescendo = 630,  // "cresc."
    DynamicTextDecrescendo = 631, // "decresc.", "dim."

    // Tempo
    /// <summary>Tempo-Markierung in BPM (z.B. ♩ = 120). CorrectionJson Feld: bpm.</summary>
    TempoBpm = 700,
    TempoText = 701,             // z.B. "Allegro", "Andante"
    Ritardando = 710,            // rit.
    Accelerando = 711,           // accel.
    AtempoMarking = 712,         // a tempo
    Fermata = 720,

    // Artikulation (Akzent etc.)
    AccentMark = 800,            // >
    Staccato = 801,              // .
    StaccatissimoMark = 802,     // '
    Tenuto = 803,                // -
    Marcato = 804,               // ^
    BowUp = 810,                 // V
    BowDown = 811,               // ⊓

    // Bögen
    Slur = 900,                  // Bindebogen
    Tie = 901,                   // Haltebogen
    Trill = 902,                 // tr
    Mordent = 903,
    Turn = 904,                  // ~

    // Tuplet
    Triplet = 1000,              // 3 über drei Noten
    Quintuplet = 1001,           // 5
    Sextuplet = 1002,            // 6

    // Sonstiges
    /// <summary>Freitext-Annotation, CorrectionJson Feld: text.</summary>
    Text = 9000,
    /// <summary>Symbol das User nicht zuordnen kann.</summary>
    Other = 9999,
}

