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

/// Kompakte SIG-Statistik für eine DetectionPage.
///
/// Wird von `sig_integration::enrich_with_sig` befüllt und im JSON-Output
/// des `/detections`-Endpoints unter dem Feld `sig` serialisiert.
#[derive(Debug, Clone, Serialize)]
pub struct SigSummary {
    /// Gesamtzahl der Inters im SIG.
    pub n_inters: u32,
    /// Anzahl Noteheads.
    pub n_heads: u32,
    /// Anzahl Stems.
    pub n_stems: u32,
    /// Anzahl Beams.
    pub n_beams: u32,
    /// Anzahl Taktstriche.
    pub n_bars: u32,
    /// Anzahl Tonart-Vorzeichen.
    pub n_keysigs: u32,
    /// Anzahl Taktart-Angaben.
    pub n_timesigs: u32,
    /// Gesamtzahl der Relations (Edges).
    pub n_relations: u32,
    /// Anzahl KeyConsistency-Support-Edges (diatonische Noteheads).
    pub n_keyconsistency_supports: u32,
    /// Anzahl KeyConsistency-Exclusion-Edges (nicht-diatonische Noteheads).
    pub n_keyconsistency_conflicts: u32,
    /// Anzahl HeadStem-Support-Edges.
    pub n_headstem_links: u32,
    /// Anzahl BeamStem-Support-Edges.
    pub n_beamstem_links: u32,
    /// Anzahl MeasureBudget-Edges.
    pub n_measurebudget_edges: u32,
}

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
    /// Erkannte Notenschlüssel pro System (typischerweise einer pro Zeile am Anfang).
    pub clefs: Vec<ClefEntry>,
    /// Erkannte Tonart-Vorzeichen pro System.
    pub key_signatures: Vec<KeySignatureEntry>,
    /// Erkannte Taktarten (typisch nur einmal am Anfang).
    pub time_signatures: Vec<TimeSignatureEntry>,
    /// Sprungmarken: Repeat, Volta, Coda, Segno, D.C., D.S., Fine.
    pub jump_marks: Vec<JumpMarkEntry>,
    /// Erkannte Pausen.
    pub rests: Vec<RestEntry>,
    /// Erkannte Slurs/Bögen über NH-Gruppen.
    pub slurs: Vec<SlurEntry>,
    /// Layered Reader Phase A: sequenzielle Lese-Streams + Anomalien pro System.
    /// Wird über `read_page_sequentially` produziert.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reading_stream: Option<omr_symbols::PageReadingStream>,
    /// Optionale SIG-Zusammenfassung — wird von `sig_integration::enrich_with_sig`
    /// befüllt wenn `include_sig=true` beim Endpoint gesetzt ist.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sig: Option<SigSummary>,
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
    /// HOG-Embedding des Patches (optional, für Active-Learning-Integration).
    #[serde(skip)]
    pub hog_embedding: Option<Vec<f32>>,
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

#[derive(Debug, Clone, Serialize)]
pub struct ClefEntry {
    pub system_idx: u32,
    pub kind: &'static str, // "Treble", "Bass", "Alto", "Tenor", "Percussion"
    /// Approximative Bbox am Zeilenanfang.
    pub bbox: [u32; 4],
}

#[derive(Debug, Clone, Serialize)]
pub struct KeySignatureEntry {
    pub system_idx: u32,
    /// -7 bis +7 (negativ = Bs, positiv = Kreuze).
    pub fifths: i8,
    pub bbox: [u32; 4],
}

#[derive(Debug, Clone, Serialize)]
pub struct TimeSignatureEntry {
    pub system_idx: u32,
    pub beats: u32,
    pub beat_type: u32,
    pub bbox: [u32; 4],
}

#[derive(Debug, Clone, Serialize)]
pub struct JumpMarkEntry {
    pub kind: &'static str, // "RepeatStart", "RepeatEnd", "Volta1", "Volta2", "Coda", "Segno", "DC", "DS", "Fine"
    pub bbox: [u32; 4],
    pub system_idx: Option<u32>,
}

#[derive(Debug, Clone, Serialize)]
pub struct RestEntry {
    pub kind: &'static str, // "Whole", "Half", "Quarter", "Eighth", "Sixteenth"
    pub bbox: [u32; 4],
    pub system_idx: Option<u32>,
}

#[derive(Debug, Clone, Serialize)]
pub struct SlurEntry {
    pub bbox: [u32; 4],
    pub system_idx: u32,
    pub above: bool,
    pub start_nh_idx: Option<u32>,
    pub end_nh_idx: Option<u32>,
    pub is_tie: bool,
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
    clefs: &[omr_core::Clef],
    keys: &[omr_core::KeySignature],
    time_signature: Option<omr_core::TimeSignature>,
    jump_detections: &[(usize, omr_core::JumpMark)],
    rests: &[omr_symbols::Rest],
    slurs: &[omr_symbols::Slur],
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
                hog_embedding: None,
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

    // Clef/KeySig/TimeSig — eine "logische" Bbox pro System: Header-Bereich am
    // Anfang der Zeile, ca. 0..6*spacing breit. Wir liefern eine grobe Bbox.
    let clef_entries: Vec<ClefEntry> = clefs
        .iter()
        .enumerate()
        .filter_map(|(sys_i, c)| {
            let s = systems.get(sys_i)?;
            let line = s.lines.first()?;
            let line_start_x = line.y_per_x.iter().position(|&y| y > 0)? as u32;
            let top_y = line.mean_y() as u32;
            let bot_y = s.lines.last().map(|l| l.mean_y()).unwrap_or(0.0) as u32;
            let h = bot_y.saturating_sub(top_y);
            Some(ClefEntry {
                system_idx: sys_i as u32,
                kind: match c {
                    omr_core::Clef::Treble => "Treble",
                    omr_core::Clef::Bass => "Bass",
                    omr_core::Clef::Alto => "Alto",
                    omr_core::Clef::Tenor => "Tenor",
                },
                bbox: [line_start_x, top_y.saturating_sub(line_spacing as u32),
                       (line_spacing * 3.0) as u32, h + 2 * line_spacing as u32],
            })
        })
        .collect();

    let key_entries: Vec<KeySignatureEntry> = keys
        .iter()
        .enumerate()
        .filter_map(|(sys_i, k)| {
            if k.fifths == 0 { return None; }
            let s = systems.get(sys_i)?;
            let line = s.lines.first()?;
            let line_start_x = line.y_per_x.iter().position(|&y| y > 0)? as u32;
            let top_y = line.mean_y() as u32;
            let bot_y = s.lines.last().map(|l| l.mean_y()).unwrap_or(0.0) as u32;
            let h = bot_y.saturating_sub(top_y);
            // Nach Clef (~3*spacing): KeySig-Bereich
            let key_x = line_start_x + (line_spacing * 3.0) as u32;
            let key_w = (line_spacing * 0.7 * k.fifths.unsigned_abs() as f32) as u32;
            Some(KeySignatureEntry {
                system_idx: sys_i as u32,
                fifths: k.fifths,
                bbox: [key_x, top_y, key_w, h],
            })
        })
        .collect();

    let time_entries: Vec<TimeSignatureEntry> = time_signature
        .map(|t| {
            let mut v = Vec::new();
            if let Some(s) = systems.first() {
                if let Some(line) = s.lines.first() {
                    if let Some(line_start_x) = line.y_per_x.iter().position(|&y| y > 0) {
                        let top_y = line.mean_y() as u32;
                        let bot_y = s.lines.last().map(|l| l.mean_y()).unwrap_or(0.0) as u32;
                        let h = bot_y.saturating_sub(top_y);
                        // Nach Clef + KeySig
                        let n_acc = keys.first().map(|k| k.fifths.unsigned_abs()).unwrap_or(0) as f32;
                        let time_x = line_start_x as u32 + (line_spacing * (3.0 + 0.7 * n_acc)) as u32;
                        v.push(TimeSignatureEntry {
                            system_idx: 0,
                            beats: t.beats as u32,
                            beat_type: t.beat_type as u32,
                            bbox: [time_x, top_y, (line_spacing * 1.5) as u32, h],
                        });
                    }
                }
            }
            v
        })
        .unwrap_or_default();

    let jump_entries: Vec<JumpMarkEntry> = jump_detections
        .iter()
        .map(|(_idx, jm)| {
            // JumpMark hat keine Bbox direkt — wir nehmen den nächsten Bar als Position
            let kind: &'static str = match jm {
                omr_core::JumpMark::RepeatStart => "RepeatStart",
                omr_core::JumpMark::RepeatEnd => "RepeatEnd",
                omr_core::JumpMark::Volta { number: 1 } => "Volta1",
                omr_core::JumpMark::Volta { number: 2 } => "Volta2",
                omr_core::JumpMark::Volta { .. } => "VoltaOther",
                omr_core::JumpMark::Coda => "Coda",
                omr_core::JumpMark::Segno => "Segno",
                omr_core::JumpMark::DaCapo => "DC",
                omr_core::JumpMark::DcAlFine => "DCalFine",
                omr_core::JumpMark::DsAlCoda => "DSalCoda",
                omr_core::JumpMark::DsAlFine => "DSalFine",
                omr_core::JumpMark::Fine => "Fine",
            };
            JumpMarkEntry {
                kind,
                bbox: [0, 0, 0, 0],
                system_idx: None,
            }
        })
        .collect();

    let rest_entries: Vec<RestEntry> = rests
        .iter()
        .map(|r| RestEntry {
            kind: match r.kind {
                omr_symbols::RestKind::Whole => "Whole",
                omr_symbols::RestKind::Half => "Half",
                omr_symbols::RestKind::Quarter => "Quarter",
                omr_symbols::RestKind::Eighth => "Eighth",
                omr_symbols::RestKind::Sixteenth => "Sixteenth",
            },
            bbox: [r.bbox.x, r.bbox.y, r.bbox.w, r.bbox.h],
            system_idx: Some(r.staff_idx as u32),
        })
        .collect();

    let slur_entries: Vec<SlurEntry> = slurs
        .iter()
        .map(|s| SlurEntry {
            bbox: [s.bbox.x, s.bbox.y, s.bbox.w, s.bbox.h],
            system_idx: s.system_idx as u32,
            above: s.above,
            start_nh_idx: s.start_nh_idx.map(|i| i as u32),
            end_nh_idx: s.end_nh_idx.map(|i| i as u32),
            is_tie: s.is_tie,
        })
        .collect();

    // Layered Reader Phase A: sequenzielles Lesen pro System
    let measures_for_reader: Vec<omr_core::Measure> = measures.to_vec();
    let reading_stream = Some(omr_symbols::read_page_sequentially(
        systems,
        clefs,
        keys,
        time_signature,
        &measures_for_reader,
        noteheads,
        rests,
        bars,
        jump_detections,
    ));

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
        clefs: clef_entries,
        key_signatures: key_entries,
        time_signatures: time_entries,
        jump_marks: jump_entries,
        rests: rest_entries,
        slurs: slur_entries,
        reading_stream,
        sig: None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sig_summary_fields_default_zero() {
        let summary = SigSummary {
            n_inters: 0,
            n_heads: 0,
            n_stems: 0,
            n_beams: 0,
            n_bars: 0,
            n_keysigs: 0,
            n_timesigs: 0,
            n_relations: 0,
            n_keyconsistency_supports: 0,
            n_keyconsistency_conflicts: 0,
            n_headstem_links: 0,
            n_beamstem_links: 0,
            n_measurebudget_edges: 0,
        };
        assert_eq!(summary.n_inters, 0);
        assert_eq!(summary.n_heads, 0);
        assert_eq!(summary.n_relations, 0);
    }

    #[test]
    fn sig_summary_serializes_with_all_fields() {
        let summary = SigSummary {
            n_inters: 10,
            n_heads: 5,
            n_stems: 3,
            n_beams: 1,
            n_bars: 2,
            n_keysigs: 1,
            n_timesigs: 1,
            n_relations: 8,
            n_keyconsistency_supports: 4,
            n_keyconsistency_conflicts: 1,
            n_headstem_links: 3,
            n_beamstem_links: 1,
            n_measurebudget_edges: 5,
        };
        let json = serde_json::to_string(&summary).expect("serialize ok");
        assert!(json.contains("n_inters"));
        assert!(json.contains("n_keyconsistency_conflicts"));
        assert!(json.contains("n_measurebudget_edges"));
    }
}
