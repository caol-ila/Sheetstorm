//! Konkrete `Inter`-Typen für die Sheetstorm-OMR-Pipeline.
//!
//! Jeder Detektor erzeugt typed Inters (HeadInter, StemInter, BeamInter, ...)
//! die das `Inter`-Trait implementieren und die existierenden omr-core-
//! Datenstrukturen umschließen.
//!
//! Diese Typen sind die "Bridge" zwischen den bestehenden Detektor-Outputs
//! und der SIG-Architektur — bestehender Code muss minimal verändert werden,
//! aber das Resultat wird Inter-basiert.

use omr_core::{NoteheadKind, Point, Rect};
use serde::{Deserialize, Serialize};

use crate::grade::Grade;
use crate::inter::{Inter, InterId, InterKind, InterMeta};

/// Macro um Inter-Boilerplate zu reduzieren — implementiert `Inter` Trait.
macro_rules! impl_inter {
    ($t:ty) => {
        impl Inter for $t {
            fn meta(&self) -> &InterMeta {
                &self.meta
            }
            fn meta_mut(&mut self) -> &mut InterMeta {
                &mut self.meta
            }
            fn as_any(&self) -> &dyn std::any::Any {
                self
            }
            fn as_any_mut(&mut self) -> &mut dyn std::any::Any {
                self
            }
        }
    };
}

// ============================================================================
// Notehead
// ============================================================================

/// Inter für einen Notenkopf.
///
/// Wraps die typische `omr_core::Notehead`-Struktur und ergaenzt sie um
/// Inter-Metadaten + Pitch (wird vom Detektor gesetzt sobald StaffLine-Y
/// bekannt ist).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeadInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// Bbox-Center in Pixel-Koordinaten.
    pub center: Point<f32>,
    /// Filled / Open / Whole.
    pub notehead_kind: NoteheadKind,
    /// MIDI-Pitch (0-127); 0 wenn noch nicht berechnet.
    pub midi: u8,
    /// Pitch-Step (C, D, E, F, G, A, B); 0=C wenn noch nicht berechnet.
    pub step: omr_core::PitchStep,
    /// Octave-Nummer (4 = mittlere Oktave).
    pub octave: i8,
    /// Vorzeichen (-2 = double-flat, -1 = flat, 0 = natural, 1 = sharp, 2 = double-sharp).
    pub alter: i8,
    /// Punktierung (0/1/2).
    pub augmentation_dots: u8,
    /// Duration in Ticks (0=unbekannt, 1=16th, 2=8th, 4=quarter, 8=half, 16=whole).
    pub duration: u32,
}
impl_inter!(HeadInter);

impl HeadInter {
    /// Erstellt einen neuen HeadInter aus einer omr-core Notehead.
    pub fn from_notehead(id: InterId, nh: &omr_core::Notehead) -> Self {
        let meta = InterMeta::new(id, InterKind::Head, nh.bbox, Grade::new(nh.confidence as f64));
        Self {
            meta,
            center: nh.center,
            notehead_kind: nh.kind,
            midi: 0,
            step: omr_core::PitchStep::C,
            octave: 4,
            alter: 0,
            augmentation_dots: 0,
            duration: match nh.kind {
                NoteheadKind::Filled => 4, // default to quarter
                NoteheadKind::Open => 8,   // half
                NoteheadKind::Whole => 16, // whole
            },
        }
    }
}

// ============================================================================
// Stem
// ============================================================================

/// Inter für einen Stem (Notenhals).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StemInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// X-Pixel des Stems.
    pub x: u32,
    /// Top-Y (kleinerer Y-Wert = oben im Bild).
    pub y_top: u32,
    /// Bottom-Y.
    pub y_bot: u32,
    /// True = Stem zeigt nach oben (Notehead unten); False = nach unten.
    pub stem_up: bool,
}
impl_inter!(StemInter);

impl StemInter {
    /// Erstellt einen neuen StemInter aus einer omr-core Stem.
    pub fn from_stem(id: InterId, stem: &omr_core::Stem, grade: Grade) -> Self {
        let bounds = Rect {
            x: stem.x.saturating_sub(1),
            y: stem.y_top,
            w: 2,
            h: stem.y_bot.saturating_sub(stem.y_top).max(1),
        };
        let meta = InterMeta::new(id, InterKind::Stem, bounds, grade);
        // stem_up: heuristisch — Notenkopf ist meist unten am Stem.
        // Detektor kann das später anpassen.
        Self {
            meta,
            x: stem.x,
            y_top: stem.y_top,
            y_bot: stem.y_bot,
            stem_up: true,
        }
    }

    /// Länge des Stems in Pixeln.
    pub fn length(&self) -> u32 {
        self.y_bot.saturating_sub(self.y_top)
    }
}

// ============================================================================
// Beam
// ============================================================================

/// Inter für einen Beam (Balken zwischen Stems).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BeamInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// X-Start-Position.
    pub x_start: u32,
    /// X-Ende-Position.
    pub x_end: u32,
    /// Y-Top des Beams.
    pub y_top: u32,
    /// Y-Bottom des Beams.
    pub y_bot: u32,
    /// Anzahl Beam-Levels (1 = Achtel, 2 = Sechzehntel, 3 = 32stel).
    pub level: u8,
}
impl_inter!(BeamInter);

impl BeamInter {
    /// Erstellt einen neuen BeamInter.
    pub fn new(
        id: InterId,
        x_start: u32,
        x_end: u32,
        y_top: u32,
        y_bot: u32,
        level: u8,
        grade: Grade,
    ) -> Self {
        let bounds = Rect {
            x: x_start,
            y: y_top,
            w: x_end.saturating_sub(x_start),
            h: y_bot.saturating_sub(y_top).max(1),
        };
        let meta = InterMeta::new(id, InterKind::Beam, bounds, grade);
        Self {
            meta,
            x_start,
            x_end,
            y_top,
            y_bot,
            level,
        }
    }
}

// ============================================================================
// Bar
// ============================================================================

/// Inter für einen Taktstrich.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BarInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// X-Pixel des Strichs.
    pub x: u32,
    /// Optional: Top-Y.
    pub y_top: Option<u32>,
    /// Optional: Bottom-Y.
    pub y_bot: Option<u32>,
    /// True = Doppelstrich, False = Einfachstrich.
    pub double: bool,
}
impl_inter!(BarInter);

impl BarInter {
    /// Erstellt einen neuen BarInter.
    pub fn new(id: InterId, x: u32, system_idx: u32, grade: Grade) -> Self {
        let bounds = Rect { x: x.saturating_sub(1), y: 0, w: 2, h: 0 };
        let mut meta = InterMeta::new(id, InterKind::Bar, bounds, grade);
        meta.system_idx = Some(system_idx);
        Self {
            meta,
            x,
            y_top: None,
            y_bot: None,
            double: false,
        }
    }
}

// ============================================================================
// Slur / Tie
// ============================================================================

/// Inter für einen Slur oder Tie.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SlurInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// Start-Punkt der Bezier-Kurve.
    pub start: Point<f32>,
    /// End-Punkt.
    pub end: Point<f32>,
    /// Kontroll-Punkt (Höhe der Kurve).
    pub control: Point<f32>,
    /// True = Tie zwischen gleichen Notes; False = Slur über Phrase.
    pub is_tie: bool,
}
impl_inter!(SlurInter);

// ============================================================================
// Rest
// ============================================================================

/// Inter für eine Pause.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RestInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// Duration in Ticks (16th=1, 8th=2, quarter=4, half=8, whole=16).
    pub duration: u32,
}
impl_inter!(RestInter);

// ============================================================================
// Clef / KeySig / TimeSig
// ============================================================================

/// Inter für einen Notenschlüssel.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClefInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// Welcher Clef? (Treble, Bass, Alto, Tenor, ...).
    pub clef_type: ClefType,
    /// Welche Stafflinie ist Anchor (0=oberste, 4=unterste, default je Clef).
    pub line: u8,
}
impl_inter!(ClefInter);

/// Typ eines Notenschlüssels.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ClefType {
    /// Violinschlüssel (G-Schlüssel auf 2. Linie).
    Treble,
    /// Bassschlüssel (F-Schlüssel auf 4. Linie).
    Bass,
    /// Altschlüssel (C-Schlüssel auf 3. Linie).
    Alto,
    /// Tenorschlüssel (C-Schlüssel auf 4. Linie).
    Tenor,
    /// Sopranschlüssel (C-Schlüssel auf 1. Linie).
    Soprano,
    /// Schlagzeug-/Percussion-Schlüssel.
    Percussion,
    /// Gitarren-Tab-Schlüssel.
    Tab,
}

/// Inter für eine Tonart-Signatur.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KeySignatureInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// Anzahl Vorzeichen (positiv = Sharps, negativ = Flats, 0 = C-Dur/A-Moll).
    pub fifths: i8,
}
impl_inter!(KeySignatureInter);

/// Inter für eine Taktangabe.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimeSignatureInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// Zähler (z.B. 4 in 4/4).
    pub beats: u8,
    /// Nenner (z.B. 4 in 4/4).
    pub beat_type: u8,
}
impl_inter!(TimeSignatureInter);

// ============================================================================
// Alter (Akzidens)
// ============================================================================

/// Inter für ein Vorzeichen (Sharp, Flat, Natural, Double-Sharp/Flat).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlterInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// -2..2 entsprechend Double-Flat ... Double-Sharp.
    pub alter: i8,
}
impl_inter!(AlterInter);

// ============================================================================
// Ledger
// ============================================================================

/// Inter für eine Hilfslinie.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LedgerInter {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// X-Start.
    pub x_start: u32,
    /// X-Ende.
    pub x_end: u32,
    /// Y-Position der Linie.
    pub y: u32,
    /// Position relativ zum Staff: 1 = direkt darüber, 2 = noch eins darüber, -1 = direkt darunter, ...
    pub position: i8,
}
impl_inter!(LedgerInter);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn head_inter_from_notehead_preserves_data() {
        let nh = omr_core::Notehead {
            bbox: Rect { x: 10, y: 20, w: 8, h: 8 },
            center: Point { x: 14.0, y: 24.0 },
            confidence: 0.85,
            kind: NoteheadKind::Filled,
            staff_idx: 0,
        };
        let h = HeadInter::from_notehead(InterId(1), &nh);
        assert_eq!(h.kind(), InterKind::Head);
        assert!((h.grade().value() - 0.85).abs() < 1e-6);
        assert_eq!(h.notehead_kind, NoteheadKind::Filled);
        assert_eq!(h.duration, 4); // quarter (filled default)
    }

    #[test]
    fn stem_inter_calculates_length() {
        let stem = omr_core::Stem { x: 50, y_top: 100, y_bot: 150, notehead_idx: None };
        let si = StemInter::from_stem(InterId(1), &stem, Grade::new(0.7));
        assert_eq!(si.length(), 50);
        assert_eq!(si.kind(), InterKind::Stem);
    }

    #[test]
    fn beam_inter_kind_is_beam() {
        let b = BeamInter::new(InterId(1), 100, 200, 50, 55, 1, Grade::new(0.8));
        assert_eq!(b.kind(), InterKind::Beam);
        assert_eq!(b.level, 1);
    }
}
