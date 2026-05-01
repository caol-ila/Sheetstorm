// Sheetstorm OMR — Kern-Datentypen.
//
// Diese Crate definiert die wichtigsten Datenstrukturen, die zwischen
// allen Pipeline-Stufen ausgetauscht werden. Bewusst kompakt gehalten.

use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use thiserror::Error;

pub mod image_buf;
pub use image_buf::{Binary, Gray, Rgba};

#[derive(Debug, Error)]
pub enum OmrError {
    #[error("I/O-Fehler: {0}")]
    Io(#[from] std::io::Error),
    #[error("Bildformat nicht unterstützt: {0}")]
    UnsupportedFormat(String),
    #[error("Fehler beim Bildladen: {0}")]
    ImageLoad(#[from] image::ImageError),
    #[error("Pipeline-Stufe '{stage}' fehlgeschlagen: {message}")]
    Stage { stage: &'static str, message: String },
    #[error("PDF-Render-Fehler: {0}")]
    PdfRender(String),
    #[error("MusicXML-Export-Fehler: {0}")]
    MusicXml(String),
}

pub type Result<T> = std::result::Result<T, OmrError>;

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Point<T> { pub x: T, pub y: T }

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Rect {
    pub x: u32,
    pub y: u32,
    pub w: u32,
    pub h: u32,
}

impl Rect {
    pub fn area(&self) -> u32 { self.w * self.h }
    pub fn aspect(&self) -> f32 { self.w as f32 / self.h.max(1) as f32 }
    pub fn cx(&self) -> f32 { self.x as f32 + self.w as f32 * 0.5 }
    pub fn cy(&self) -> f32 { self.y as f32 + self.h as f32 * 0.5 }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StaffLine {
    /// Y-Koordinate je X-Position. Length == image width.
    pub y_per_x: Vec<u32>,
}

impl StaffLine {
    pub fn mean_y(&self) -> f32 {
        if self.y_per_x.is_empty() { return 0.0; }
        self.y_per_x.iter().map(|&y| y as f64).sum::<f64>() as f32 / self.y_per_x.len() as f32
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StaffSystem {
    /// Genau 5 Linien, von oben nach unten.
    pub lines: Vec<StaffLine>,
    pub line_spacing: f32,
    pub line_thickness: f32,
}

impl StaffSystem {
    pub fn line_y_at(&self, line_idx: usize, x: u32) -> Option<f32> {
        let line = self.lines.get(line_idx)?;
        let y = *line.y_per_x.get(x as usize)?;
        Some(y as f32)
    }

    pub fn middle_y(&self) -> f32 {
        let top = self.lines.first().map(|l| l.mean_y()).unwrap_or(0.0);
        let bot = self.lines.last().map(|l| l.mean_y()).unwrap_or(0.0);
        (top + bot) * 0.5
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Notehead {
    pub bbox: Rect,
    pub center: Point<f32>,
    pub confidence: f32,
    pub kind: NoteheadKind,
    pub staff_idx: usize,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum NoteheadKind {
    Filled,
    Open,
    Whole,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Stem {
    pub x: u32,
    pub y_top: u32,
    pub y_bot: u32,
    pub notehead_idx: Option<usize>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScoreNote {
    pub midi: u8,
    pub step: PitchStep,
    pub alter: i8,
    pub octave: i8,
    pub duration: u32,
    pub onset: u32,
    pub voice: u8,
    pub kind: NoteheadKind,
    pub center: Point<f32>,
    /// Anzahl Punktierungen (0 = keine, 1 = einfach punktiert ×1.5,
    /// 2 = doppelt punktiert ×1.75). Default 0.
    #[serde(default)]
    pub augmentation_dots: u8,
    /// True wenn diese Note Teil eines Akkords ist und NICHT die "lead"-Note —
    /// d.h. mehrere NHs liegen am gleichen Onset und sollen in der MusicXML als
    /// `<chord/>` markiert werden. Plausibility-Σ ignoriert solche Notes.
    #[serde(default, skip_serializing_if = "std::ops::Not::not")]
    pub in_chord: bool,
    /// True wenn dieses Element eine Pause statt einer Note ist. MusicXML
    /// schreibt dann `<rest/>` statt `<pitch>`. Pitch-Felder werden ignoriert.
    #[serde(default, skip_serializing_if = "std::ops::Not::not")]
    pub is_rest: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PitchStep { C, D, E, F, G, A, B }

impl PitchStep {
    pub fn as_str(&self) -> &'static str {
        match self {
            PitchStep::C => "C",
            PitchStep::D => "D",
            PitchStep::E => "E",
            PitchStep::F => "F",
            PitchStep::G => "G",
            PitchStep::A => "A",
            PitchStep::B => "B",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Measure {
    pub number: u32,
    pub divisions: u32,
    pub notes: Vec<ScoreNote>,
    pub time_signature: Option<TimeSignature>,
    pub key_signature: Option<KeySignature>,
    pub clef: Option<Clef>,
    /// Bbox des Takts im Original-Bild (ungerotated, post-deskew).
    /// Optional weil ältere Pipeline-Pfade (z.B. Audiveris-Sidecar) das
    /// nicht liefern.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub bbox_orig: Option<Rect>,
    /// Index des StaffSystems (Zeile), in dem der Takt liegt.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub system_idx: Option<u32>,
    /// Sprungmarken innerhalb dieses Taktes.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub jump_marks: Vec<JumpMark>,
}

/// Sprungmarken, die das Performance-Verhalten eines Taktes beeinflussen.
/// Spec 22 (Layered OMR + Cross-Instrument-Sync) basiert auf zuverlässiger
/// Detection dieser Marken — selbst wenn die einzelnen Noten unvollständig
/// erkannt sind.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum JumpMark {
    /// Volta-Klammer ("1.", "2.", "3.") — wiederholungs-spezifischer Pfad.
    Volta { number: u8 },
    /// Da Capo (von vorne wiederholen).
    DaCapo,
    /// D.C. al Fine (von vorne bis Fine).
    DcAlFine,
    /// D.S. al Coda (zum Segno und weiter zur Coda).
    DsAlCoda,
    /// D.S. al Fine (zum Segno und weiter bis Fine).
    DsAlFine,
    /// Coda-Marker — Sprungziel.
    Coda,
    /// Segno-Marker — Sprungquelle.
    Segno,
    /// Fine — Endpunkt nach D.C./D.S. al Fine.
    Fine,
    /// Wiederholungs-Anfang ||:
    RepeatStart,
    /// Wiederholungs-Ende :||
    RepeatEnd,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct TimeSignature {
    pub beats: u8,
    pub beat_type: u8,
}
impl Default for TimeSignature {
    fn default() -> Self { Self { beats: 4, beat_type: 4 } }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct KeySignature {
    pub fifths: i8,
}
impl Default for KeySignature {
    fn default() -> Self { Self { fifths: 0 } }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Clef {
    Treble, Bass, Alto, Tenor,
}
impl Default for Clef {
    fn default() -> Self { Clef::Treble }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Part {
    pub id: String,
    pub name: String,
    pub measures: Vec<Measure>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Score {
    pub work_title: String,
    pub composer: String,
    pub parts: Vec<Part>,
}

/// Performance-Timeline: linearisiert die Spielreihenfolge eines Stücks
/// unter Beachtung aller Sprungmarken (Volta, D.C., D.S., Coda, Repeat).
///
/// Der `linear_index` ist instrumenten-unabhängig — d.h. Klar1 und Trompete
/// liefern dieselbe Timeline, auch wenn ihre measures unterschiedlich
/// umgebrochen sind. Damit kann man zwischen Stimmen sync-en (Spec 22).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct PerformanceTimeline {
    /// Linearisierte Reihenfolge der `measure.number`-Werte in Spielreihenfolge.
    /// Bei Wiederholungen erscheint dieselbe Nummer mehrfach.
    pub linear_order: Vec<u32>,
}

impl PerformanceTimeline {
    /// Berechnet die Timeline aus einem Part — folgt allen Sprungmarken.
    ///
    /// Implementierung: linearer Walk durch die Measures mit Tracking des
    /// "Jump-State" (Repeat-Start, taken-Repeats, taken-Backjumps).
    /// Pro Repeat/Volta-/D.C.-/D.S.-Marke wird der Sprung MAX. EINMAL ausgeführt
    /// (sonst Endlos-Schleife).
    pub fn from_part(part: &Part) -> Self {
        let mut order = Vec::with_capacity(part.measures.len() * 2);
        let mut i = 0usize;
        let mut repeat_start: Option<usize> = None;
        let mut in_repeat_pass = false; // Sind wir gerade in der zweiten (oder n-ten) Repeat-Iteration?
        let mut taken_repeat_at = std::collections::HashSet::new();
        let mut jumped_back = std::collections::HashSet::new();
        // Schutz vor Endlos-Schleife: maximal 4× #measures Schritte
        let max_steps = part.measures.len() * 4 + 10;
        let mut steps = 0usize;

        while i < part.measures.len() {
            steps += 1;
            if steps > max_steps {
                break;
            }
            let m = &part.measures[i];

            let is_volta1 = m.jump_marks.iter().any(|j| matches!(j, JumpMark::Volta { number: 1 }));
            let is_volta2 = m.jump_marks.iter().any(|j| matches!(j, JumpMark::Volta { number: 2 }));

            // Volta-1 wird beim WIEDERHOLUNGS-Durchlauf übersprungen
            if is_volta1 && in_repeat_pass {
                // Springe vorwärts bis zum nächsten Volta-2-Marker (oder Ende)
                let mut j = i;
                while j < part.measures.len() {
                    let mm = &part.measures[j];
                    if mm.jump_marks.iter().any(|jm| matches!(jm, JumpMark::Volta { number: 2 })) {
                        break;
                    }
                    j += 1;
                }
                if j == i { j += 1; } // Sicherheit: mindestens 1 Schritt
                i = j;
                continue;
            }

            order.push(m.number);

            // Repeat-Start merken (vor Repeat-End-Behandlung damit selbe Marke beides kann)
            if m.jump_marks.contains(&JumpMark::RepeatStart) {
                repeat_start = Some(i);
            }
            // Repeat-Ende: zurück zum Start (nur einmal pro Repeat-Pair)
            if m.jump_marks.contains(&JumpMark::RepeatEnd) {
                let start = repeat_start.unwrap_or(0);
                if !taken_repeat_at.contains(&i) {
                    taken_repeat_at.insert(i);
                    in_repeat_pass = true;
                    i = start;
                    continue;
                } else {
                    // Repeat schon genommen → weiter, NICHT zurück
                    in_repeat_pass = false;
                    repeat_start = None;
                }
            }
            // D.C. / D.S.: Sprung zurück (max. einmal pro Quell-Index)
            if !jumped_back.contains(&i) {
                if m.jump_marks.contains(&JumpMark::DaCapo)
                    || m.jump_marks.contains(&JumpMark::DcAlFine)
                {
                    jumped_back.insert(i);
                    i = 0;
                    in_repeat_pass = true; // nach DC: wir sind im "Wiederhol"-Modus
                    continue;
                }
                if let Some(segno_idx) = part.measures.iter().position(|mm|
                    mm.jump_marks.contains(&JumpMark::Segno))
                {
                    if m.jump_marks.contains(&JumpMark::DsAlCoda)
                        || m.jump_marks.contains(&JumpMark::DsAlFine)
                    {
                        jumped_back.insert(i);
                        i = segno_idx;
                        in_repeat_pass = true;
                        continue;
                    }
                }
            }
            // Fine nach D.C./D.S. al Fine: Stop
            if m.jump_marks.contains(&JumpMark::Fine)
                && jumped_back.iter().any(|&idx| {
                    let mm = &part.measures[idx];
                    mm.jump_marks.contains(&JumpMark::DcAlFine)
                        || mm.jump_marks.contains(&JumpMark::DsAlFine)
                })
            {
                break;
            }
            i += 1;
        }
        Self { linear_order: order }
    }

    /// Anzahl Takte in der linearisierten Performance.
    pub fn len(&self) -> usize {
        self.linear_order.len()
    }

    pub fn is_empty(&self) -> bool {
        self.linear_order.is_empty()
    }
}

#[cfg(test)]
mod timeline_tests {
    use super::*;

    fn measure(number: u32, marks: &[JumpMark]) -> Measure {
        Measure {
            number,
            divisions: 4,
            jump_marks: marks.to_vec(),
            ..Default::default()
        }
    }

    #[test]
    fn timeline_no_marks_is_linear() {
        let part = Part {
            id: "P1".into(),
            name: "T".into(),
            measures: vec![measure(1, &[]), measure(2, &[]), measure(3, &[])],
        };
        let t = PerformanceTimeline::from_part(&part);
        assert_eq!(t.linear_order, vec![1, 2, 3]);
    }

    #[test]
    fn timeline_simple_repeat() {
        // |: 1 2 3 :|  → 1,2,3,1,2,3
        let part = Part {
            id: "P1".into(),
            name: "T".into(),
            measures: vec![
                measure(1, &[JumpMark::RepeatStart]),
                measure(2, &[]),
                measure(3, &[JumpMark::RepeatEnd]),
            ],
        };
        let t = PerformanceTimeline::from_part(&part);
        assert_eq!(t.linear_order, vec![1, 2, 3, 1, 2, 3]);
    }

    #[test]
    fn timeline_volta_skips_volta1_on_repeat() {
        // |: 1 2 [Volta1: 3] [Volta2: 4] :|  → 1,2,3,1,2,4
        // Hier: Volta-1 = m3 (mit RepeatEnd), Volta-2 = m4
        let part = Part {
            id: "P1".into(),
            name: "T".into(),
            measures: vec![
                measure(1, &[JumpMark::RepeatStart]),
                measure(2, &[]),
                measure(3, &[JumpMark::Volta { number: 1 }, JumpMark::RepeatEnd]),
                measure(4, &[JumpMark::Volta { number: 2 }]),
            ],
        };
        let t = PerformanceTimeline::from_part(&part);
        // Erste Iteration: 1,2,3 (mit Volta-1 + RepeatEnd → zurück zu 1)
        // Zweite Iteration: 1,2 (Volta-1 überspringen) → 4
        assert_eq!(t.linear_order, vec![1, 2, 3, 1, 2, 4]);
    }

    #[test]
    fn timeline_da_capo_returns_to_start() {
        // 1 2 3 [D.C.] → 1,2,3,1,2,3
        let part = Part {
            id: "P1".into(),
            name: "T".into(),
            measures: vec![
                measure(1, &[]),
                measure(2, &[]),
                measure(3, &[JumpMark::DaCapo]),
            ],
        };
        let t = PerformanceTimeline::from_part(&part);
        assert_eq!(t.linear_order, vec![1, 2, 3, 1, 2, 3]);
    }
}

#[derive(Debug, Clone, Default)]
pub struct PipelineOptions {
    pub debug_dir: Option<PathBuf>,
    pub trace_only: bool,
    /// Optionaler Pfad zu einem ONNX-U-Net-Modell für Staff-Removal.
    /// Wird nur verwendet, wenn `omr-staff` mit `--features unet` gebaut
    /// wurde UND die Datei ladbar ist; ansonsten greift der RLE-Fallback.
    pub unet_model_path: Option<PathBuf>,
    /// Wenn true, sammelt die Pipeline alle Detection-Bboxes (NHs, Stems,
    /// Beams, Bars) und gibt sie im `PipelineResult.detections` zurück.
    /// Nötig für das Annotation-/Training-Tool. Default: false.
    pub collect_detections: bool,
}
