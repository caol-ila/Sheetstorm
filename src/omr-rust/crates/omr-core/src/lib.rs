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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Measure {
    pub number: u32,
    pub divisions: u32,
    pub notes: Vec<ScoreNote>,
    pub time_signature: Option<TimeSignature>,
    pub key_signature: Option<KeySignature>,
    pub clef: Option<Clef>,
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

#[derive(Debug, Clone, Default)]
pub struct PipelineOptions {
    pub debug_dir: Option<PathBuf>,
    pub trace_only: bool,
}
