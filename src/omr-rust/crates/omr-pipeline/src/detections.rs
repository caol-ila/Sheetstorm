// Detection-Output für das Annotation-/Trainings-Tool.
//
// Sammelt alle Pipeline-Detections (Noteheads, Stems, Beams, Bars, Measures,
// StaffSystems) inklusive zugewiesener Pitch/Duration in einem JSON-tauglichen
// Format. Wird vom omr-server `/detections`-Endpoint zurückgegeben.
//
// Koordinaten-System: Pixel des PDF-Renderings bei der Pipeline-internen DPI
// (200dpi). Die UI muss anhand `width/height` auf das eigene Page-Image-DPI
// skalieren.

use omr_core::{Measure, Notehead, NoteheadKind, ScoreNote, StaffSystem, Stem};
use omr_symbols::{Beam, MeasureBar};
use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
pub struct DetectionsResult {
    pub schema_version: u32,
    pub pages: Vec<DetectionPage>,
}

#[derive(Debug, Clone, Serialize)]
pub struct DetectionPage {
    pub page_index: u32,
    pub width: u32,
    pub height: u32,
    pub line_spacing: f32,
    pub line_thickness: f32,
    pub deskew_angle_deg: f32,
    pub staff_systems: Vec<StaffSystemEntry>,
    pub noteheads: Vec<NoteheadEntry>,
    pub stems: Vec<StemEntry>,
    pub beams: Vec<BeamEntry>,
    pub bars: Vec<BarEntry>,
    pub measures: Vec<MeasureEntry>,
}

#[derive(Debug, Clone, Serialize)]
pub struct StaffSystemEntry {
    pub system_idx: u32,
    /// Top-Y der obersten Linie (gemittelt).
    pub top_y: f32,
    /// Bot-Y der untersten Linie (gemittelt).
    pub bot_y: f32,
    pub line_spacing: f32,
}

#[derive(Debug, Clone, Serialize)]
pub struct NoteheadEntry {
    pub id: u32,
    pub bbox: [u32; 4],
    pub center: [f32; 2],
    pub kind: &'static str,
    pub system_idx: u32,
    pub confidence: f32,
    /// MIDI Note Number (z.B. 60 = C4). None wenn keine Score-Note zugeordnet.
    pub midi: Option<u8>,
    pub step: Option<&'static str>,
    pub alter: Option<i8>,
    pub octave: Option<i8>,
    pub duration: Option<u32>,
    pub augmentation_dots: Option<u8>,
    pub measure_number: Option<u32>,
    pub in_chord: Option<bool>,
    pub is_rest: Option<bool>,
    pub stem_id: Option<u32>,
}

#[derive(Debug, Clone, Serialize)]
pub struct StemEntry {
    pub id: u32,
    pub x: u32,
    pub y_top: u32,
    pub y_bot: u32,
    pub notehead_id: Option<u32>,
}

#[derive(Debug, Clone, Serialize)]
pub struct BeamEntry {
    pub id: u32,
    pub bbox: [u32; 4],
}

#[derive(Debug, Clone, Serialize)]
pub struct BarEntry {
    pub id: u32,
    pub x: u32,
    pub y_top: u32,
    pub y_bot: u32,
    pub system_idx: u32,
}

#[derive(Debug, Clone, Serialize)]
pub struct MeasureEntry {
    pub number: u32,
    pub system_idx: Option<u32>,
    pub bbox: Option<[u32; 4]>,
    pub time_signature: Option<String>,
    pub note_count: u32,
    pub plausibility: &'static str,
}

fn kind_str(k: NoteheadKind) -> &'static str {
    match k {
        NoteheadKind::Filled => "Filled",
        NoteheadKind::Open => "Open",
        NoteheadKind::Whole => "Whole",
    }
}

fn step_str(s: omr_core::PitchStep) -> &'static str {
    match s {
        omr_core::PitchStep::C => "C",
        omr_core::PitchStep::D => "D",
        omr_core::PitchStep::E => "E",
        omr_core::PitchStep::F => "F",
        omr_core::PitchStep::G => "G",
        omr_core::PitchStep::A => "A",
        omr_core::PitchStep::B => "B",
    }
}

/// Baut eine DetectionPage aus den internen Pipeline-Daten.
///
/// Mapping von ScoreNote → Notehead via center.x/y (NHs sind in der
/// gleichen Reihenfolge im NH-Array wie in den Score-Notes nicht garantiert,
/// daher matchen wir per Distanz).
pub fn build_detection_page(
    page_index: u32,
    width: u32,
    height: u32,
    deskew_angle_deg: f32,
    systems: &[StaffSystem],
    noteheads: &[Notehead],
    stems: &[Stem],
    beams: &[Beam],
    bars: &[MeasureBar],
    measures: &[Measure],
    plausibility: &[omr_symbols::MeasureCheck],
) -> DetectionPage {
    let line_spacing = systems.first().map(|s| s.line_spacing).unwrap_or(0.0);
    let line_thickness = systems.first().map(|s| s.line_thickness).unwrap_or(0.0);

    let staff_systems: Vec<StaffSystemEntry> = systems
        .iter()
        .enumerate()
        .map(|(i, s)| StaffSystemEntry {
            system_idx: i as u32,
            top_y: s.lines.first().map(|l| l.mean_y()).unwrap_or(0.0),
            bot_y: s.lines.last().map(|l| l.mean_y()).unwrap_or(0.0),
            line_spacing: s.line_spacing,
        })
        .collect();

    // Build notehead_id → stem_id map (notehead_idx in stems is the ARRAY-INDEX
    // into the noteheads-Array used by detect_stems).
    let mut nh_to_stem: Vec<Option<u32>> = vec![None; noteheads.len()];
    let stem_entries: Vec<StemEntry> = stems
        .iter()
        .enumerate()
        .map(|(i, s)| {
            let stem_id = i as u32;
            if let Some(nh_idx) = s.notehead_idx {
                if nh_idx < nh_to_stem.len() {
                    nh_to_stem[nh_idx] = Some(stem_id);
                }
            }
            StemEntry {
                id: stem_id,
                x: s.x,
                y_top: s.y_top,
                y_bot: s.y_bot,
                notehead_id: s.notehead_idx.map(|i| i as u32),
            }
        })
        .collect();

    // Score-Notes flat extrahieren mit Measure-Nummer
    struct FlatNote<'a> {
        note: &'a ScoreNote,
        measure_number: u32,
    }
    let flat_notes: Vec<FlatNote> = measures
        .iter()
        .flat_map(|m| {
            m.notes.iter().map(move |n| FlatNote {
                note: n,
                measure_number: m.number,
            })
        })
        .collect();

    let nh_entries: Vec<NoteheadEntry> = noteheads
        .iter()
        .enumerate()
        .map(|(i, nh)| {
            // Nearest-Match: ScoreNote mit dem geringsten Abstand zum NH-Center
            let mut best: Option<(f32, &FlatNote)> = None;
            for fn_ in &flat_notes {
                let dx = fn_.note.center.x - nh.center.x;
                let dy = fn_.note.center.y - nh.center.y;
                let d2 = dx * dx + dy * dy;
                if best.map(|(b, _)| d2 < b).unwrap_or(true) {
                    best = Some((d2, fn_));
                }
            }
            // Nur matchen wenn Abstand < 1*spacing (Score-Notes können
            // in der Repair-Phase verschoben werden)
            let max_d2 = (line_spacing * 1.0).powi(2);
            let matched = best.filter(|(d2, _)| *d2 <= max_d2).map(|(_, n)| n);

            NoteheadEntry {
                id: i as u32,
                bbox: [nh.bbox.x, nh.bbox.y, nh.bbox.w, nh.bbox.h],
                center: [nh.center.x, nh.center.y],
                kind: kind_str(nh.kind),
                system_idx: nh.staff_idx as u32,
                confidence: nh.confidence,
                midi: matched.map(|n| n.note.midi),
                step: matched.map(|n| step_str(n.note.step)),
                alter: matched.map(|n| n.note.alter),
                octave: matched.map(|n| n.note.octave),
                duration: matched.map(|n| n.note.duration),
                augmentation_dots: matched.map(|n| n.note.augmentation_dots),
                measure_number: matched.map(|n| n.measure_number),
                in_chord: matched.map(|n| n.note.in_chord),
                is_rest: matched.map(|n| n.note.is_rest),
                stem_id: nh_to_stem.get(i).copied().flatten(),
            }
        })
        .collect();

    let beam_entries: Vec<BeamEntry> = beams
        .iter()
        .enumerate()
        .map(|(i, b)| BeamEntry {
            id: i as u32,
            bbox: [
                b.x_start,
                b.y_top,
                b.x_end.saturating_sub(b.x_start) + 1,
                b.y_bot.saturating_sub(b.y_top) + 1,
            ],
        })
        .collect();

    let bar_entries: Vec<BarEntry> = bars
        .iter()
        .enumerate()
        .map(|(i, b)| {
            // MeasureBar hat nur x + system_idx; y_top/y_bot über Staff-System ableiten
            let (y_top, y_bot) = systems
                .get(b.system_idx)
                .map(|s| {
                    let top = s.lines.first().map(|l| l.mean_y()).unwrap_or(0.0) as u32;
                    let bot = s.lines.last().map(|l| l.mean_y()).unwrap_or(0.0) as u32;
                    (top, bot)
                })
                .unwrap_or((0, 0));
            BarEntry {
                id: i as u32,
                x: b.x,
                y_top,
                y_bot,
                system_idx: b.system_idx as u32,
            }
        })
        .collect();

    let measure_entries: Vec<MeasureEntry> = measures
        .iter()
        .map(|m| {
            let plaus = plausibility
                .iter()
                .find(|c| c.measure_idx == m.number as usize)
                .map(|c| match c.plausibility {
                    omr_symbols::MeasurePlausibility::Exact => "exact",
                    omr_symbols::MeasurePlausibility::Anacrusis => "anacrusis",
                    omr_symbols::MeasurePlausibility::Repairable => "repaired",
                    omr_symbols::MeasurePlausibility::Broken => "broken",
                })
                .unwrap_or("unknown");
            MeasureEntry {
                number: m.number,
                system_idx: m.system_idx,
                bbox: m.bbox_orig.map(|r| [r.x, r.y, r.w, r.h]),
                time_signature: m
                    .time_signature
                    .map(|t| format!("{}/{}", t.beats, t.beat_type)),
                note_count: m.notes.iter().filter(|n| !n.in_chord).count() as u32,
                plausibility: plaus,
            }
        })
        .collect();

    DetectionPage {
        page_index,
        width,
        height,
        line_spacing,
        line_thickness,
        deskew_angle_deg,
        staff_systems,
        noteheads: nh_entries,
        stems: stem_entries,
        beams: beam_entries,
        bars: bar_entries,
        measures: measure_entries,
    }
}
