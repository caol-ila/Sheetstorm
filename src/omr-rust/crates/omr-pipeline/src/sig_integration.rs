//! SIG-Integration für die Sheetstorm-OMR-Pipeline.
//!
//! Übersetzt eine `DetectionPage` (Output der bestehenden Pipeline) in einen
//! `omr_sig::Sig` mit Inter-Knoten und Support-/Exclusion-Edges.
//!
//! Das ist die Schnittstelle, die spätere Iterationen erweitern werden um:
//! - Music-Theory-Edges (Key-Consistency, Voice-Leading, MeasureBudget)
//! - User-Edits aus dem Op-Log
//! - ML-derived Edges (Music-Language-Model, Detector-Ensemble)

use omr_core::{Notehead, NoteheadKind, PitchStep, Rect, Stem};
use omr_sig::{
    add_key_consistency_edges, add_measure_budget_edges, Grade, HeadInter, InterKind, InterMeta,
    KeySignatureInter, Provenance, Sig, SigBuilder, TimeSignatureInter,
};

use crate::detections::DetectionPage;

fn parse_kind(s: &str) -> NoteheadKind {
    match s {
        "Open" => NoteheadKind::Open,
        "Whole" => NoteheadKind::Whole,
        _ => NoteheadKind::Filled,
    }
}

fn parse_step(s: Option<&'static str>) -> PitchStep {
    match s {
        Some("C") => PitchStep::C,
        Some("D") => PitchStep::D,
        Some("E") => PitchStep::E,
        Some("F") => PitchStep::F,
        Some("G") => PitchStep::G,
        Some("A") => PitchStep::A,
        Some("B") => PitchStep::B,
        _ => PitchStep::C,
    }
}

/// Detection-Page → Sig Adapter.
///
/// Erzeugt einen frischen `Sig` mit:
/// - Noteheads als `HeadInter` mit pitch (midi/step/octave) wo verfügbar
/// - Stems als `StemInter`
/// - Beams als `BeamInter`
/// - Bars als `BarInter`
/// - KeySignatures + TimeSignatures pro System
/// - HeadStem + BeamStem Support-Edges (Geometric-Heuristics)
/// - KeyConsistency-Edges (Diatonic = Support, Non-Diatonic = Exclusion)
/// - MeasureBudget-Annotation-Edges
///
/// Anschließend wird `contextualize()` aufgerufen.
pub fn build_sig_from_page(page: &DetectionPage) -> Sig {
    let mut sig = Sig::new();

    let noteheads: Vec<Notehead> = page
        .noteheads
        .iter()
        .map(|nh| Notehead {
            bbox: Rect {
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

    // Pitch-Daten aus der DetectionPage in HeadInters durchreichen.
    populate_head_pitches(&mut sig, page);

    // KeySignatures + TimeSignatures als Inters anlegen.
    add_keysig_inters(&mut sig, page);
    add_timesig_inters(&mut sig, page);

    // Music-Theory-Edges berechnen.
    let _ = add_key_consistency_edges(&mut sig);
    let _ = add_measure_budget_edges(&mut sig);

    sig.contextualize();
    sig
}

/// Aktualisiert die HeadInters im Sig mit Pitch-Daten aus der DetectionPage.
/// Mappt per Position (head_index in der NoteheadEntry-Liste).
fn populate_head_pitches(sig: &mut Sig, page: &DetectionPage) {
    // Sammle (id, pos) Paare basierend auf Reihenfolge in der Sig.
    let head_ids: Vec<_> = sig
        .typed_inters::<HeadInter>()
        .map(|h| h.meta.id)
        .collect();
    if head_ids.len() != page.noteheads.len() {
        // Anzahl stimmt nicht; nicht safe zu mappen — bail out.
        return;
    }
    for (idx, head_id) in head_ids.iter().enumerate() {
        let entry = &page.noteheads[idx];
        if let Some(head) = sig.get_mut(*head_id) {
            if let Some(h) = head.as_any_mut().downcast_mut::<HeadInter>() {
                if let Some(midi) = entry.midi {
                    h.midi = midi;
                }
                if let Some(step) = entry.step {
                    h.step = parse_step(Some(step));
                }
                if let Some(alter) = entry.alter {
                    h.alter = alter;
                }
                if let Some(octave) = entry.octave {
                    h.octave = octave;
                }
                if let Some(duration) = entry.duration {
                    h.duration = duration;
                }
                if let Some(dots) = entry.augmentation_dots {
                    h.augmentation_dots = dots;
                }
                if let Some(measure) = entry.measure_number {
                    h.meta.measure_number = Some(measure);
                }
            }
        }
    }
}

fn add_keysig_inters(sig: &mut Sig, page: &DetectionPage) {
    for ks in &page.key_signatures {
        let id = sig.next_inter_id();
        let bb = Rect { x: ks.bbox[0], y: ks.bbox[1], w: ks.bbox[2], h: ks.bbox[3] };
        let mut meta = InterMeta::new(id, InterKind::KeySignature, bb, Grade::new(0.85));
        meta.system_idx = Some(ks.system_idx);
        meta.provenance = Provenance::Detector;
        let inter = KeySignatureInter {
            meta,
            fifths: ks.fifths,
        };
        sig.add_inter(Box::new(inter));
    }
}

fn add_timesig_inters(sig: &mut Sig, page: &DetectionPage) {
    for ts in &page.time_signatures {
        let id = sig.next_inter_id();
        let bb = Rect { x: ts.bbox[0], y: ts.bbox[1], w: ts.bbox[2], h: ts.bbox[3] };
        let mut meta = InterMeta::new(id, InterKind::TimeSignature, bb, Grade::new(0.90));
        meta.system_idx = Some(ts.system_idx);
        meta.provenance = Provenance::Detector;
        let inter = TimeSignatureInter {
            meta,
            beats: ts.beats as u8,
            beat_type: ts.beat_type as u8,
        };
        sig.add_inter(Box::new(inter));
    }
}

/// Schaut sich die Sig-Statistik an und produziert einen kompakten Summary-
/// String für Debug-Output.
pub fn sig_summary(sig: &Sig) -> String {
    let total = sig.inter_count();
    let n_heads = sig.inters_of_kind(InterKind::Head).count();
    let n_stems = sig.inters_of_kind(InterKind::Stem).count();
    let n_beams = sig.inters_of_kind(InterKind::Beam).count();
    let n_bars = sig.inters_of_kind(InterKind::Bar).count();
    let n_keys = sig.inters_of_kind(InterKind::KeySignature).count();
    let n_times = sig.inters_of_kind(InterKind::TimeSignature).count();
    let n_relations = sig.relation_count();
    format!(
        "Sig({} inters: {}H + {}S + {}Beam + {}Bar + {}Key + {}Time | {} relations)",
        total, n_heads, n_stems, n_beams, n_bars, n_keys, n_times, n_relations
    )
}

/// Helper: validiert mehrere Sigs als Cross-Part-Vergleich.
///
/// # Argumente
/// - `parts_with_names`: Slice aus `(part_name, sig_ref, transposition_semitones)`.
///
/// # Rückgabe
/// `CrossPartReport` mit allen gefundenen Inkonsistenzen.
pub fn validate_parts<'a>(
    parts_with_names: &[(String, &'a omr_sig::Sig, i8)],
) -> omr_sig::cross_part::CrossPartReport {
    let parts: Vec<_> = parts_with_names
        .iter()
        .map(|(name, sig, transp)| omr_sig::cross_part::Part {
            name: name.clone(),
            sig,
            transposition_semitones: *transp,
        })
        .collect();
    omr_sig::cross_part::validate_cross_parts(&parts)
}

/// Reichert Noteheads einer `DetectionPage` mit Informationen aus dem
/// User-Labels-Corpus an (Active-Learning-Integration).
///
/// Liest den Embedding-Corpus aus dem Pfad `OMR_USER_LABELS_DIR/corpus.db`.
/// Für jeden Notehead mit einem gespeicherten `hog_embedding` wird eine
/// k-NN-Suche durchgeführt. Das Top-1-Ergebnis bestimmt den `kind`-Wert
/// ("Filled" / "Open" / "Whole"), wenn die Konfidenz ≥ `min_confidence`.
///
/// Ist `OMR_USER_LABELS_DIR` nicht gesetzt oder der Corpus leer, bleibt die
/// Seite unverändert.
///
/// # Hinweise
/// - Ist eine Best-Effort-Operation: Fehler werden geloggt, nie propagiert.
/// - Benötigt `hog_embedding` im `NoteheadEntry`, sonst wird der Eintrag
///   übersprungen.
pub fn enrich_noteheads_from_user_labels(page: &mut crate::detections::DetectionPage) {
    let labels_dir = match std::env::var("OMR_USER_LABELS_DIR") {
        Ok(d) => std::path::PathBuf::from(d),
        Err(_) => return,
    };

    let corpus_path = labels_dir.join("corpus.db");
    if !corpus_path.exists() {
        tracing::debug!(
            "OMR_USER_LABELS_DIR gesetzt, aber corpus.db fehlt ({}). Überspringe.",
            corpus_path.display()
        );
        return;
    }

    let corpus = match omr_embed::Corpus::open(&corpus_path) {
        Ok(c) => c,
        Err(e) => {
            tracing::warn!("Corpus öffnen fehlgeschlagen ({}): {}", corpus_path.display(), e);
            return;
        }
    };

    let mut index = match corpus.into_index("hog-v1") {
        Ok(idx) => idx,
        Err(e) => {
            tracing::warn!("Index-Aufbau fehlgeschlagen: {}", e);
            return;
        }
    };

    if index.corpus_size() == 0 {
        tracing::debug!("Corpus-Index leer — überspringe Notehead-Anreicherung.");
        return;
    }

    let encoder_version = "hog-v1";
    let encoder_dim = omr_embed::encoder::FEATURE_LEN;
    let min_confidence = 0.6_f32;

    let mut enriched = 0usize;

    for nh in page.noteheads.iter_mut() {
        let emb_vec = match &nh.hog_embedding {
            Some(v) if v.len() == encoder_dim => v.clone(),
            _ => continue,
        };

        let query = omr_embed::Embedding {
            vec: emb_vec,
            version: encoder_version.to_string(),
        };

        let matches = match index.knn(&query, 1) {
            Ok(m) => m,
            Err(_) => continue,
        };

        if let Some(top1) = matches.into_iter().next() {
            let confidence = 1.0_f32 - top1.distance;
            if confidence >= min_confidence {
                nh.kind = match top1.label.to_ascii_lowercase().as_str() {
                    s if s.contains("open") => "Open",
                    s if s.contains("whole") => "Whole",
                    _ => "Filled",
                };
                enriched += 1;
            }
        }
    }

    if enriched > 0 {
        tracing::info!(
            "Notehead-Anreicherung via User-Labels: {} von {} Noteheads aktualisiert.",
            enriched,
            page.noteheads.len()
        );
    }
}

/// Befüllt die `sig`-Summary eines `DetectionPage` durch Aufbau des SIG.
///
/// Baut den SIG aus der DetectionPage auf, zählt alle Inters und Relations
/// nach Kind und schreibt das Ergebnis in `page.sig`.
/// Idempotent — mehrfaches Aufrufen überschreibt den vorherigen Wert.
pub fn enrich_with_sig(page: &mut crate::detections::DetectionPage) {
    use crate::detections::SigSummary;
    use omr_sig::{InterKind, RelationKind};

    let sig = build_sig_from_page(page);

    let summary = SigSummary {
        n_inters: sig.inter_count() as u32,
        n_heads: sig.inters_of_kind(InterKind::Head).count() as u32,
        n_stems: sig.inters_of_kind(InterKind::Stem).count() as u32,
        n_beams: sig.inters_of_kind(InterKind::Beam).count() as u32,
        n_bars: sig.inters_of_kind(InterKind::Bar).count() as u32,
        n_keysigs: sig.inters_of_kind(InterKind::KeySignature).count() as u32,
        n_timesigs: sig.inters_of_kind(InterKind::TimeSignature).count() as u32,
        n_relations: sig.relation_count() as u32,
        n_keyconsistency_supports: sig
            .relations()
            .filter(|r| r.kind == RelationKind::KeyConsistency && r.is_support())
            .count() as u32,
        n_keyconsistency_conflicts: sig
            .relations()
            .filter(|r| r.kind == RelationKind::KeyConsistency && r.is_exclusion())
            .count() as u32,
        n_headstem_links: sig
            .relations()
            .filter(|r| r.kind == RelationKind::HeadStem && r.is_support())
            .count() as u32,
        n_beamstem_links: sig
            .relations()
            .filter(|r| r.kind == RelationKind::BeamStem && r.is_support())
            .count() as u32,
        n_measurebudget_edges: sig
            .relations()
            .filter(|r| r.kind == RelationKind::MeasureBudget)
            .count() as u32,
    };
    page.sig = Some(summary);
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::detections::{
        DetectionPage, KeySignatureEntry, NoteheadEntry, StemEntry, TimeSignatureEntry,
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
            sig: None,
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
            hog_embedding: None,
        });
        page.stems.push(StemEntry {
            id: 0,
            x: 104,
            y_top: 180,
            y_bot: 230,
            notehead_id: Some(0),
        });
        let sig = build_sig_from_page(&page);
        assert_eq!(sig.inter_count(), 2);
        assert_eq!(sig.relation_count(), 1);
    }

    #[test]
    fn key_signature_creates_diatonic_consistency() {
        let mut page = empty_page();
        // KeySig G-Dur (1 Sharp) im System 0
        page.key_signatures.push(KeySignatureEntry {
            system_idx: 0,
            fifths: 1,
            bbox: [50, 100, 30, 40],
        });
        // TimeSig 4/4 im System 0
        page.time_signatures.push(TimeSignatureEntry {
            system_idx: 0,
            beats: 4,
            beat_type: 4,
            bbox: [80, 100, 20, 40],
        });
        // Head F#4 (MIDI 66) — diatonic in G major
        page.noteheads.push(NoteheadEntry {
            id: 0,
            bbox: [100, 200, 8, 6],
            center: [104.0, 203.0],
            kind: "Filled",
            system_idx: 0,
            confidence: 0.9,
            midi: Some(66),
            step: Some("F"),
            alter: Some(1),
            octave: Some(4),
            duration: Some(4),
            augmentation_dots: Some(0),
            measure_number: Some(1),
            in_chord: None,
            is_rest: None,
            stem_id: None,
            hog_embedding: None,
        });

        let sig = build_sig_from_page(&page);
        // 1 Head + 1 KeySig + 1 TimeSig = 3 Inters
        assert_eq!(sig.inter_count(), 3);
        // Head has its midi=66 set
        let head = sig
            .typed_inters::<HeadInter>()
            .next()
            .expect("HeadInter present");
        assert_eq!(head.midi, 66);
        // Edges: 1 KeyConsistency (Support, diatonic) + 1 MeasureBudget = 2 relations
        assert_eq!(sig.relation_count(), 2);
        // KeyConsistency-Edge soll Support sein (F# IS diatonic in G major)
        let kc_edge = sig
            .relations()
            .find(|r| r.kind == omr_sig::RelationKind::KeyConsistency)
            .expect("KeyConsistency edge present");
        assert!(kc_edge.is_support(), "F# in G major should be Support not Exclusion");
    }

    #[test]
    fn non_diatonic_pitch_produces_exclusion() {
        let mut page = empty_page();
        page.key_signatures.push(KeySignatureEntry {
            system_idx: 0,
            fifths: 1, // G-Dur
            bbox: [50, 100, 30, 40],
        });
        // F natural (MIDI 65) — NOT diatonic in G major
        page.noteheads.push(NoteheadEntry {
            id: 0,
            bbox: [100, 200, 8, 6],
            center: [104.0, 203.0],
            kind: "Filled",
            system_idx: 0,
            confidence: 0.9,
            midi: Some(65),
            step: Some("F"),
            alter: Some(0),
            octave: Some(4),
            duration: Some(4),
            augmentation_dots: Some(0),
            measure_number: Some(1),
            in_chord: None,
            is_rest: None,
            stem_id: None,
            hog_embedding: None,
        });
        let sig = build_sig_from_page(&page);
        let kc_edge = sig
            .relations()
            .find(|r| r.kind == omr_sig::RelationKind::KeyConsistency)
            .expect("KeyConsistency edge present");
        assert!(kc_edge.is_exclusion(), "F natural in G major should be Exclusion");
    }

    #[test]
    fn enrich_with_sig_populates_summary() {
        let mut page = empty_page();
        // G-Dur Tonart
        page.key_signatures.push(KeySignatureEntry {
            system_idx: 0,
            fifths: 1,
            bbox: [50, 100, 30, 40],
        });
        // Diatonischer Head F#4 (MIDI 66)
        page.noteheads.push(NoteheadEntry {
            id: 0,
            bbox: [100, 200, 8, 6],
            center: [104.0, 203.0],
            kind: "Filled",
            system_idx: 0,
            confidence: 0.9,
            midi: Some(66),
            step: Some("F"),
            alter: Some(1),
            octave: Some(4),
            duration: Some(4),
            augmentation_dots: Some(0),
            measure_number: Some(1),
            in_chord: None,
            is_rest: None,
            stem_id: None,
            hog_embedding: None,
        });
        // Nicht-diatonischer Head F natural (MIDI 65)
        page.noteheads.push(NoteheadEntry {
            id: 1,
            bbox: [200, 200, 8, 6],
            center: [204.0, 203.0],
            kind: "Filled",
            system_idx: 0,
            confidence: 0.85,
            midi: Some(65),
            step: Some("F"),
            alter: Some(0),
            octave: Some(4),
            duration: Some(4),
            augmentation_dots: Some(0),
            measure_number: Some(1),
            in_chord: None,
            is_rest: None,
            stem_id: None,
            hog_embedding: None,
        });

        assert!(page.sig.is_none());
        super::enrich_with_sig(&mut page);

        let sig = page.sig.expect("sig populated after enrich_with_sig");
        assert_eq!(sig.n_heads, 2);
        assert_eq!(sig.n_keysigs, 1);
        // 1 diatonic Head → 1 Support
        assert_eq!(sig.n_keyconsistency_supports, 1);
        // 1 non-diatonic Head → 1 Exclusion/Conflict
        assert_eq!(sig.n_keyconsistency_conflicts, 1);
        // Inters: 2 Heads + 1 KeySig = 3
        assert_eq!(sig.n_inters, 3);
    }
}
