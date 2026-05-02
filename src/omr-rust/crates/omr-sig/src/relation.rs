//! Relation — eine Kante zwischen zwei (oder mehr) `Inter`s im SIG.
//!
//! Inspiriert von Audiveris (~60 Relations), erweitert um Sheetstorm-Extensions:
//! - **Music-Theory** (Key/Voice-Leading/Phrase) — als deklarative Constraints
//! - **Scope** (Dynamik/Tempo/Pedal) — wer beeinflusst wen
//! - **Cross-Part / Cross-Document** — Multi-Stimmen-Konsistenz für Blasmusik
//! - **ML-derived** — Sequence-Model-Support, Detector-Ensemble
//!
//! Jede `Relation` ist entweder:
//! - **`Exclusion`**: die beiden Inters dürfen nicht gleichzeitig wahr sein
//! - **`Support`**: wenn beide wahr sind, verstärken sie den Contextual Grade

use crate::inter::InterId;
use crate::Provenance;
use serde::{Deserialize, Serialize};

/// Klassifikation einer `Relation` — was modelliert die Kante?
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum RelationKind {
    // ── Audiveris-äquivalent: geometrisch/strukturell ──
    /// Notenkopf hängt an Stem.
    HeadStem,
    /// Beam verbindet Heads (über Stems).
    BeamHead,
    /// Beam ist mit Stem verbunden.
    BeamStem,
    /// Flag hängt an Stem-Ende.
    FlagStem,
    /// Slur/Tie verbindet zwei Heads.
    SlurHead,
    /// Tie zwischen zwei gleichen Heads (degenerierter Slur).
    TieHead,
    /// Vorzeichen gehört zu einem Head.
    AlterHead,
    /// Punktierung verlängert einen Head/Rest.
    AugmentationDot,
    /// Tuplet-Marker über mehreren Notes.
    ChordTuplet,
    /// Articulation-Marker (Staccato, Accent) auf einem Head.
    ArticulationHead,
    /// Stems im gleichen Akkord müssen ausgerichtet sein.
    StemAlignment,
    /// Clef → KeySig → TimeSig: Header-Reihenfolge.
    ClefKey,
    /// KeySig besteht aus mehreren Alters.
    KeyAlters,
    /// Repeat-Bar mit den zwei Punkten verbunden.
    RepeatDotPair,
    /// Bar-Connection zwischen zwei Staves im gleichen System.
    BarConnection,
    /// Mirror-Relation: zwei Heads am gleichen Stem (oben + unten).
    Mirror,
    /// Hilfslinie unter/über einem Head.
    LedgerHead,

    // ── Voice & Time ──
    /// Zwei Notes sind in der gleichen Voice.
    SameVoice,
    /// Zwei Notes sind in verschiedenen Voices.
    SeparateVoice,
    /// Note B kommt direkt nach Note A in derselben Voice.
    NextInVoice,
    /// Beide Notes haben den gleichen Onset (Akkord-Mitglieder).
    SameTime,
    /// Notes sind explizit zu verschiedenen Onsets gehörend.
    SeparateTime,

    // ── Sheetstorm: Music-Theory ──
    /// Note ist konsistent mit aktiver Tonart (kein unerwartetes Akzidens).
    KeyConsistency,
    /// Note ist konsistent mit Voice-Leading-Regeln (Schritt vs Sprung).
    VoiceLeading,
    /// Note hat eine harmonische Funktion (Root, Third, Fifth, Passing, Neighbor).
    HarmonicFunction,
    /// Leitton resolviert zur Tonika.
    LeadingToneResolution,
    /// Note ist Akkord-Ton in aktiver Harmonie.
    ChordTone,
    /// Note ist Durchgangs-/Wechselnote.
    NonChordTone,

    // ── Sheetstorm: Rhythmus / Metrik ──
    /// Σ Durations im Takt = Time-Signature-Erwartung.
    MeasureBudget,
    /// Note auf Down-Beat (starker Schlag) oder Up-Beat.
    MetricStrength,
    /// Note ist Mitglied einer Beat-Gruppe (Beam-Group, Tuplet).
    BeatGroupMember,

    // ── Sheetstorm: Scope (Direktiven) ──
    /// Dynamik gilt von Note A bis Note B.
    DynamicScope,
    /// Tempo gilt von Note A bis Note B.
    TempoScope,
    /// Pedal-Markierung erstreckt sich von A bis B.
    PedalScope,
    /// Octava-Klammer (8va) verschiebt Pitches in Bereich.
    OctaveScope,
    /// Articulation propagiert über Slur (Legato-Group).
    SlurArticulationPropagation,

    // ── Sheetstorm: Struktur (Wiederholungen / Sprünge) ──
    /// RepeatStart...RepeatEnd Block-Struktur.
    RepeatBlock,
    /// Volta-1 / Volta-2 Alternativ-Endung.
    AlternateEnding,
    /// Erster Takt ist Anacrusis (Auftakt).
    Anacrusis,
    /// Da Capo / Dal Segno Sprungmarken-Zielung.
    DaCapo,
    /// Dal Segno-Sprung von "$" zu Segno.
    DalSegno,
    /// Coda-Sprung von "To Coda" zu "Coda".
    Coda,

    // ── Sheetstorm: Cross-Staff / Multi-Voice ──
    /// Klavier links/rechts Hand zur gleichen Zeit (Grand-Staff Alignment).
    CrossStaff,
    /// Stimme setzt sich über Takt-Grenzen fort.
    VoiceContinuity,

    // ── Sheetstorm: Cross-Part / Cross-Document ──
    /// Trumpet-1 und Trumpet-2 desselben Stücks: Takt-Anzahl, Tempo, Tonart konsistent.
    CrossPartAlignment,
    /// Mehrere Kopien des gleichen PDFs hochgeladen → Consensus.
    SamePieceConsensus,
    /// Bekanntes Motif aus Library wiedererkannt.
    MotifMatch,

    // ── Sheetstorm: ML ──
    /// Music-Language-Model bewertet Note im Kontext positiv.
    LanguageModelSupport,
    /// Mehrere Detektoren stimmen über Inter-Existenz überein.
    DetectorAgreement,
}

/// Bei `Exclusion` — warum schließen sich die zwei Inters aus?
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum ExclusionCause {
    /// Beide Inters belegen denselben Pixel-Bereich.
    BoundsOverlap,
    /// Inters sind alternative Hypothesen für dasselbe Symbol.
    AlternativeHypotheses,
    /// Beide würden gleiche Voice an gleicher Position belegen.
    VoiceConflict,
    /// Ein Inter würde Konsistenz-Regel verletzen.
    ConsistencyViolation,
    /// Inkompatible Klassifikation (Head vs Beam an gleicher Stelle).
    KindIncompatible,
}

/// Bei `Support` — welche Sub-Klasse von Unterstützung?
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum SupportKind {
    /// Geometrische Nachbarschaft (z.B. Stem berührt Head).
    Geometric,
    /// Strukturelle/Musikalische Konsistenz.
    Structural,
    /// Theoretische Konsistenz (Tonart, Voice-Leading).
    Theoretical,
    /// ML-derived Support (Sequence-Model, Ensemble).
    Machine,
    /// Cross-Document Support (Multi-Part-Konsistenz).
    Cross,
}

/// Multiplikative Beiträge zum Contextual Grade pro Richtung.
///
/// Audiveris-Konvention: jede Support-Edge liefert (`source_ratio`, `target_ratio`),
/// jeweils ≥ 1.0. Ratio > 1.0 = positive Verstärkung, = 1.0 = neutral.
///
/// `contribution_for(target) = source_grade · (target_ratio - 1.0)`
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct SupportImpacts {
    /// Multiplikator für `from`-Inter wenn `to` wahr ist.
    pub source_ratio: f64,
    /// Multiplikator für `to`-Inter wenn `from` wahr ist.
    pub target_ratio: f64,
    /// Sub-Klasse.
    pub kind: SupportKind,
}

impl SupportImpacts {
    /// Neutraler Support (wirkt nicht).
    pub fn neutral() -> Self {
        Self {
            source_ratio: 1.0,
            target_ratio: 1.0,
            kind: SupportKind::Structural,
        }
    }
    /// Symmetrischer Support: gleicher Multiplikator in beide Richtungen.
    pub fn symmetric(ratio: f64, kind: SupportKind) -> Self {
        Self {
            source_ratio: ratio,
            target_ratio: ratio,
            kind,
        }
    }
    /// Asymmetrischer Support.
    pub fn asymmetric(source_ratio: f64, target_ratio: f64, kind: SupportKind) -> Self {
        Self {
            source_ratio,
            target_ratio,
            kind,
        }
    }
}

/// Eine Kante zwischen zwei (oder mehr) `Inter`s.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Relation {
    /// Klassifikation.
    pub kind: RelationKind,
    /// Quell-Inter.
    pub from: InterId,
    /// Ziel-Inter.
    pub to: InterId,
    /// Zusätzliche Inters für n-äre Relations (z.B. Tuplet 3+ Notes).
    pub extra: Vec<InterId>,
    /// Variant: Exclusion ODER Support — entscheidet die Reduce-Logik.
    pub variant: RelationVariant,
    /// Wer hat diese Edge erzeugt?
    pub provenance: Provenance,
    /// Wenn `true`: User hat bestätigt (z.B. „diese 2 Heads gehören zu diesem Stem"),
    /// überlebt jede Reduktion.
    pub frozen: bool,
}

/// Diskriminator zwischen Exclusion und Support.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub enum RelationVariant {
    /// Mutual Exclusion — beide Inters dürfen nicht koexistieren.
    Exclusion(ExclusionCause),
    /// Gegenseitige Verstärkung mit gegebenen Multiplikatoren.
    Support(SupportImpacts),
}

impl Relation {
    /// Erstellt eine Exclusion-Kante.
    pub fn exclusion(
        kind: RelationKind,
        from: InterId,
        to: InterId,
        cause: ExclusionCause,
    ) -> Self {
        Self {
            kind,
            from,
            to,
            extra: Vec::new(),
            variant: RelationVariant::Exclusion(cause),
            provenance: Provenance::Detector,
            frozen: false,
        }
    }
    /// Erstellt eine Support-Kante.
    pub fn support(
        kind: RelationKind,
        from: InterId,
        to: InterId,
        impacts: SupportImpacts,
    ) -> Self {
        Self {
            kind,
            from,
            to,
            extra: Vec::new(),
            variant: RelationVariant::Support(impacts),
            provenance: Provenance::Detector,
            frozen: false,
        }
    }

    /// Erweitert die `extra`-Liste um zusätzliche Inters (für n-äre Relations).
    pub fn with_extra(mut self, extra: Vec<InterId>) -> Self {
        self.extra = extra;
        self
    }
    /// Markiert als User-bestätigt.
    pub fn freeze(mut self) -> Self {
        self.frozen = true;
        self.provenance = Provenance::User;
        self
    }

    /// Ist diese Kante ein Mutual-Exclusion-Constraint?
    pub fn is_exclusion(&self) -> bool {
        matches!(self.variant, RelationVariant::Exclusion(_))
    }
    /// Ist diese Kante eine Support-Verstärkung?
    pub fn is_support(&self) -> bool {
        matches!(self.variant, RelationVariant::Support(_))
    }
    /// Wenn Support: liefere die Impacts.
    pub fn support_impacts(&self) -> Option<&SupportImpacts> {
        match &self.variant {
            RelationVariant::Support(s) => Some(s),
            _ => None,
        }
    }
    /// Wenn Exclusion: liefere die Cause.
    pub fn exclusion_cause(&self) -> Option<ExclusionCause> {
        match &self.variant {
            RelationVariant::Exclusion(c) => Some(*c),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::inter::InterId;

    #[test]
    fn exclusion_constructor_works() {
        let r = Relation::exclusion(
            RelationKind::HeadStem,
            InterId(1),
            InterId(2),
            ExclusionCause::BoundsOverlap,
        );
        assert!(r.is_exclusion());
        assert!(!r.is_support());
        assert_eq!(r.exclusion_cause(), Some(ExclusionCause::BoundsOverlap));
    }

    #[test]
    fn support_neutral_does_nothing() {
        let s = SupportImpacts::neutral();
        assert_eq!(s.source_ratio, 1.0);
        assert_eq!(s.target_ratio, 1.0);
    }

    #[test]
    fn support_with_impacts_is_support() {
        let r = Relation::support(
            RelationKind::HeadStem,
            InterId(1),
            InterId(2),
            SupportImpacts::symmetric(1.5, SupportKind::Geometric),
        );
        assert!(r.is_support());
        let s = r.support_impacts().unwrap();
        assert_eq!(s.source_ratio, 1.5);
        assert_eq!(s.target_ratio, 1.5);
    }

    #[test]
    fn freeze_changes_provenance() {
        let r = Relation::exclusion(
            RelationKind::HeadStem,
            InterId(1),
            InterId(2),
            ExclusionCause::BoundsOverlap,
        )
        .freeze();
        assert!(r.frozen);
        assert_eq!(r.provenance, Provenance::User);
    }
}
