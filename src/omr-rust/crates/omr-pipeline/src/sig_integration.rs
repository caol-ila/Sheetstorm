//! SIG-Integration für die Sheetstorm-OMR-Pipeline.
//!
//! Übersetzt eine `DetectionPage` (Output der bestehenden Pipeline) in einen
//! `omr_sig::Sig` mit Inter-Knoten und Support-/Exclusion-Edges.
//!
//! Das ist die Schnittstelle, die spätere Iterationen erweitern werden um:
//! - Music-Theory-Edges (Key-Consistency, Voice-Leading, MeasureBudget)
//! - User-Edits aus dem Op-Log
//! - ML-derived Edges (Music-Language-Model, Detector-Ensemble)
//!
//! Aktuell: minimaler "1:1"-Build der bestehenden Detections in einen SIG.

use omr_core::{Notehead, NoteheadKind, Stem};
use omr_sig::{Sig, SigBuilder};

use crate::detections::DetectionPage;

fn parse_kind(s: &str) -> NoteheadKind {
    match s {
        "Open" => NoteheadKind::Open,
        "Whole" => NoteheadKind::Whole,
        _ => NoteheadKind::Filled,
    }
}

/// Minimaler Detection-Page → Sig Adapter.
///
/// Erzeugt einen frischen `Sig` mit:
/// - Allen Noteheads als `HeadInter`
/// - Allen Stems als `StemInter`
/// - Allen Beams als `BeamInter`
/// - Allen Bars als `BarInter`
/// - HeadStem-Support-Edges (Audiveris-Heuristik: stem.x ≈ head.cx, y-overlap)
/// - BeamStem-Support-Edges (stem-y enthält beam-y)
///
/// Anschließend wird `contextualize()` aufgerufen.
pub fn build_sig_from_page(page: &DetectionPage) -> Sig {
    let mut sig = Sig::new();

    // Convert DetectionPage entries zurück in omr-core Strukturen.
    let noteheads: Vec<Notehead> = page
        .noteheads
        .iter()
        .map(|nh| Notehead {
            bbox: omr_core::Rect {
                x: nh.bbox[0],
                y: nh.bbox[1],
                w: nh.bbox[2],
                h: nh.bbox[3],
            },
            center: omr_core::Point {
                x: nh.center[0],
                y: nh.center[1],
            },
            confidence: nh.confidence,
            kind: parse_kind(nh.kind),
            staff_idx: nh.system_idx as usize,
        })
        .collect();

    let stems: Vec<Stem> = page
        .stems
        .iter()
        .map(|s| Stem {
            x: s.x,
            y_top: s.y_top,
            y_bot: s.y_bot,
            notehead_idx: s.notehead_id.map(|i| i as usize),
        })
        .collect();

    // Beams: bbox = [x, y, w, h]. Convert to (x_start, x_end, y_top, y_bot, level).
    // Default-Level ist 1 (Achtel) — exakter Level kommt später aus stems.beam_count.
    let beams: Vec<(u32, u32, u32, u32, u8)> = page
        .beams
        .iter()
        .map(|b| {
            let x_start = b.bbox[0];
            let y_top = b.bbox[1];
            let x_end = x_start + b.bbox[2];
            let y_bot = y_top + b.bbox[3];
            (x_start, x_end, y_top, y_bot, 1u8)
        })
        .collect();

    let bars: Vec<(u32, u32)> = page
        .bars
        .iter()
        .map(|b| (b.x, b.system_idx))
        .collect();

    let _ = SigBuilder::new(page.line_spacing)
        .add_noteheads(&mut sig, &noteheads)
        .add_stems(&mut sig, &stems)
        .add_beams(&mut sig, &beams)
        .add_bars(&mut sig, &bars)
        .link_head_stem(&mut sig)
        .link_beam_stem(&mut sig);

    sig.contextualize();
    sig
}

/// Schaut sich die Sig-Statistik an und produziert einen kompakten Summary-
/// String für Debug-Output.
pub fn sig_summary(sig: &Sig) -> String {
    use omr_sig::InterKind;
    let total = sig.inter_count();
    let n_heads = sig.inters_of_kind(InterKind::Head).count();
    let n_stems = sig.inters_of_kind(InterKind::Stem).count();
    let n_beams = sig.inters_of_kind(InterKind::Beam).count();
    let n_bars = sig.inters_of_kind(InterKind::Bar).count();
    let n_relations = sig.relation_count();
    format!(
        "Sig({} inters: {}H + {}S + {}Beam + {}Bar | {} relations)",
        total, n_heads, n_stems, n_beams, n_bars, n_relations
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::detections::{
        BarEntry, BeamEntry, DetectionPage, NoteheadEntry, StemEntry,
    };

    fn empty_page() -> DetectionPage {
        DetectionPage {
            page_index: 0,
            width: 1000,
            height: 1000,
            line_spacing: 10.0,
            line_thickness: 1.0,
            deskew_angle_deg: 0.0,
            staff_systems: vec![],
            noteheads: vec![],
            stems: vec![],
            beams: vec![],
            bars: vec![],
            measures: vec![],
            clefs: vec![],
            key_signatures: vec![],
            time_signatures: vec![],
            jump_marks: vec![],
            rests: vec![],
            slurs: vec![],
            reading_stream: None,
        }
    }

    #[test]
    fn empty_page_produces_empty_sig() {
        let page = empty_page();
        let sig = build_sig_from_page(&page);
        assert_eq!(sig.inter_count(), 0);
        assert_eq!(sig.relation_count(), 0);
    }

    #[test]
    fn page_with_head_and_stem_links_them() {
        let mut page = empty_page();
        page.noteheads.push(NoteheadEntry {
            id: 0,
            bbox: [100, 200, 8, 6],
            center: [104.0, 203.0],
            kind: "Filled",
            system_idx: 0,
            confidence: 0.9,
            midi: None,
            step: None,
            alter: None,
            octave: None,
            duration: None,
            augmentation_dots: None,
            measure_number: None,
            in_chord: None,
            is_rest: None,
            stem_id: None,
        });
        page.stems.push(StemEntry {
            id: 0,
            x: 104,
            y_top: 180,
            y_bot: 230,
            notehead_id: Some(0),
        });
        let sig = build_sig_from_page(&page);
        // 1 Head + 1 Stem = 2 Inters
        assert_eq!(sig.inter_count(), 2);
        // 1 HeadStem-Relation
        assert_eq!(sig.relation_count(), 1);
        // Contextual grades sollen erhöht sein
        for inter in sig.inters() {
            assert!(inter.effective_grade().value() >= inter.grade().value());
        }
    }
}
