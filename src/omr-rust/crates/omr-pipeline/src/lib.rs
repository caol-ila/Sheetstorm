// OMR-Pipeline-Orchestrator. Verbindet alle Stufen in der richtigen
// Reihenfolge und produziert einen Score (oder MusicXML).

use image::GrayImage;
use omr_core::{
    Clef, KeySignature, Measure, OmrError, Part, PipelineOptions, Result, Score, TimeSignature,
};
use std::path::Path;
use std::sync::OnceLock;
use tracing::{info, info_span, warn};

pub mod accuracy;
pub mod debug_viz;
pub mod muscima;
pub mod pdf_render;
pub mod synthetic;

/// Eingebettetes vortrainiertes Klassifikator-Modell.
///
/// Wird beim ersten Aufruf von [`hog_svm_classifier`] aus dem Asset-Pfad des
/// `omr-symbols`-Crates geladen. Ist die Datei nicht vorhanden oder
/// inkompatibel, fällt die Pipeline auf den Template-NCC-Filter zurück.
static HOG_SVM_CLASSIFIER: OnceLock<Option<omr_symbols::svm_model::HogSvmClassifier>> =
    OnceLock::new();

/// Versucht den Symbol-Klassifikator zu laden (genau einmal pro Prozess).
/// Liefert `None`, wenn die Modell-Datei fehlt oder fehlerhaft ist.
fn hog_svm_classifier() -> Option<&'static omr_symbols::svm_model::HogSvmClassifier> {
    HOG_SVM_CLASSIFIER
        .get_or_init(|| {
            // Pfade in Reihenfolge der Priorität:
            //  1) ENV-Override `OMR_SYMBOL_CLASSIFIER`
            //  2) Asset im Crate
            let candidates: Vec<std::path::PathBuf> = {
                let mut v = Vec::new();
                if let Ok(p) = std::env::var("OMR_SYMBOL_CLASSIFIER") {
                    v.push(std::path::PathBuf::from(p));
                }
                // Workspace-relativ vom Pipeline-Crate aus.
                let pipe_dir = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"));
                if let Some(workspace) = pipe_dir.parent().and_then(|p| p.parent()) {
                    v.push(
                        workspace
                            .join("crates")
                            .join("omr-symbols")
                            .join("assets")
                            .join("symbol-classifier.bin"),
                    );
                }
                v
            };
            for path in candidates {
                if !path.exists() {
                    continue;
                }
                match omr_symbols::svm_model::HogSvmClassifier::load(&path) {
                    Ok(m) => {
                        info!(model_path = %path.display(), "loaded HoG+SVM classifier");
                        return Some(m);
                    }
                    Err(e) => {
                        warn!(model_path = %path.display(), error = %e,
                              "failed to load HoG+SVM classifier, will fall back");
                    }
                }
            }
            None
        })
        .as_ref()
}

/// Ergebnis eines vollständigen Durchlaufs für ein Bild oder PDF.
#[derive(Debug, Clone)]
pub struct PipelineResult {
    pub score: Score,
    /// MusicXML als String.
    pub musicxml: String,
    /// Stage-Timings in Millisekunden.
    pub timings: Timings,
    /// Diagnose-Statistiken.
    pub stats: Stats,
}

#[derive(Debug, Clone, Default)]
pub struct Timings {
    pub preprocessing_ms: u128,
    pub staff_detection_ms: u128,
    pub staff_removal_ms: u128,
    pub symbol_detection_ms: u128,
    pub musicxml_ms: u128,
    pub total_ms: u128,
}

#[derive(Debug, Clone, Default)]
pub struct Stats {
    pub n_systems: usize,
    pub line_thickness: f32,
    pub line_spacing: f32,
    pub n_noteheads: usize,
    pub n_stems: usize,
    pub n_beams: usize,
    pub n_bars: usize,
    pub n_rests: usize,
    pub n_measures: usize,
    pub n_measures_exact: usize,
    pub n_measures_repaired: usize,
    pub n_measures_broken: usize,
    pub n_jump_marks: usize,
    pub timeline_len: usize,
    pub deskew_angle_deg: f32,
    /// Document-Typ-Diagnose
    pub doc_type: Option<&'static str>,
    pub doc_confidence: f32,
    pub doc_line_straightness: f32,
    pub doc_line_thickness_stddev: f32,
    pub doc_gray_variance: f32,
    /// NH-Größen-Variabilität (Stddev/Mean Ratio) — printed: niedrig, handwritten: hoch.
    pub doc_nh_size_cv: f32,
}

/// Verarbeite ein bereits geladenes Grayscale-Bild.
pub fn process_gray(gray: GrayImage, opts: &PipelineOptions) -> Result<PipelineResult> {
    let total_t = std::time::Instant::now();

    // 1) Preprocessing: deskew + adaptive despeckle + binarize.
    let _span = info_span!("preprocessing").entered();
    let pre_t = std::time::Instant::now();
    let (gray, deskew_angle) = omr_preprocessing::deskew(&gray);
    // Adaptiv: Bei wenig Rauschen reicht 1× Median, bei viel Rauschen 2×.
    let noise = omr_preprocessing::estimate_noise_level(&gray);
    let gray = if noise > 0.04 {
        omr_preprocessing::despeckle_strong(&gray)
    } else {
        omr_preprocessing::median3x3(&gray)
    };
    let bin = omr_preprocessing::sauvola(&gray, 25, 0.34);
    let preprocessing_ms = pre_t.elapsed().as_millis();
    drop(_span);
    info!(deskew_angle, noise, count = bin.count(), "preprocessing done");

    if let Some(ref dir) = opts.debug_dir {
        let _ = bin.to_gray().save(dir.join("01_binary.png"));
    }

    // 2) Staff-Detection.
    let _span = info_span!("staff_detection").entered();
    let sd_t = std::time::Instant::now();
    let systems = omr_staff::detect_systems(&bin);
    let staff_detection_ms = sd_t.elapsed().as_millis();
    drop(_span);
    info!(n = systems.len(), "staff systems detected");

    if systems.is_empty() {
        warn!("no staff systems found — returning empty score");
        return Ok(PipelineResult {
            score: Score::default(),
            musicxml: omr_musicxml::export(&Score::default())?,
            timings: Timings { preprocessing_ms, staff_detection_ms, total_ms: total_t.elapsed().as_millis(), ..Default::default() },
            stats: Stats { deskew_angle_deg: deskew_angle, ..Default::default() },
        });
    }

    let line_spacing = systems[0].line_spacing;
    let line_thickness = systems[0].line_thickness;

    // 2b) Document-Type-Detection: gedruckt vs handschrift.
    // Beeinflusst Pipeline-Tuning für Bars/Stems/Plausibility.
    let doc_class = omr_preprocessing::classify_document(&gray, &bin, &systems);
    info!(
        doc_type = ?doc_class.doc_type,
        confidence = doc_class.confidence,
        line_straightness = doc_class.line_straightness,
        line_thickness_stddev = doc_class.line_thickness_stddev,
        gray_variance = doc_class.gray_variance,
        "document classified"
    );

    // 3) Staff-Removal. U-Net (wenn Modell gegeben + Feature aktiv +
    //    Datei ladbar), sonst klassisches RLE-Removal.
    let sr_t = std::time::Instant::now();
    let removed = match opts.unet_model_path.as_deref() {
        Some(model_path) => match omr_staff::try_remove_staff_unet(&bin, model_path) {
            Some(unet_bin) => {
                info!(model = %model_path.display(), "staff removal via U-Net");
                unet_bin
            }
            None => omr_staff::remove_staff(&bin, &systems),
        },
        None => omr_staff::remove_staff(&bin, &systems),
    };
    let staff_removal_ms = sr_t.elapsed().as_millis();
    if let Some(ref dir) = opts.debug_dir {
        let _ = removed.to_gray().save(dir.join("02_staff_removed.png"));
    }

    // 4) Symbol-Detection: Noteheads + Stems + Beams + Bars.
    let _span = info_span!("symbol_detection").entered();
    let sym_t = std::time::Instant::now();

    // Skip-Region pro System: ersten ~14*spacing (Schlüssel + Key + Time)
    // wo keine Noteheads erlaubt sind.
    let skip_regions: Vec<std::ops::Range<u32>> = systems.iter().map(|s| {
        let spacing = s.line_spacing;
        // Finde X wo Stafflinie beginnt
        let first_line = s.lines.first();
        let line_start_x = first_line
            .and_then(|l| l.y_per_x.iter().position(|&y| y > 0))
            .unwrap_or(0) as u32;
        // 6 spacings reichen für Schlüssel + Vorzeichen + Taktart
        line_start_x..(line_start_x + (spacing * 6.0) as u32)
    }).collect();

    let raw_noteheads = omr_symbols::detect_noteheads_with_skip(&removed, &systems, &skip_regions);
    let noteheads = omr_symbols::rerank_with_template(&removed, &raw_noteheads, line_spacing);
    // Symbol-Klassifikator: filtert Coda/Segno/D.S./Dynamik/Noise.
    // Bevorzugt HoG+SVM (gelernt auf Bravura-Synth-Korpus). Fallback auf
    // Template-NCC, wenn das Modell nicht ladebar ist.
    let n_before_classifier = noteheads.len();
    let noteheads = if let Some(clf) = hog_svm_classifier() {
        // Klassifikator auf ORIGINAL-Binary (nicht staff-removed) — Coda/Segno-Glyphen
        // bleiben dort intakter und matchen besser zu den Bravura-Templates.
        omr_symbols::classifier::filter_via_hog_svm(&bin, noteheads, line_spacing, clf)
    } else {
        omr_symbols::classifier::filter_via_templates(&removed, noteheads, line_spacing)
    };
    let n_after_classifier = noteheads.len();
    let stems = omr_symbols::stems::detect_stems(&removed, &noteheads, line_spacing);
    let beams = omr_symbols::detect_beams(&removed, line_spacing);
    let beam_counts = omr_symbols::beams_per_stem(&stems, &beams);
    let bars = omr_symbols::detect_measure_bars(&bin, &systems, &noteheads);
    // Pausen-Detection (Whole-Rest, Half-Rest) — füllt leere Measures mit
    // expliziten Pause-Notes statt Tacet zu lassen.
    let rests = omr_symbols::detect_rests(&bin, &systems);
    // Sprungmarken erkennen (Repeat-Bars + Volta) — Phase A für Layered-OMR (Spec 22)
    let mut jump_detections = Vec::new();
    jump_detections.extend(omr_symbols::jump_marks::detect_repeat_marks(&bin, &bars, &systems));
    jump_detections.extend(omr_symbols::jump_marks::detect_voltas(&bin, &bars, &noteheads, &systems));
    let symbol_detection_ms = sym_t.elapsed().as_millis();
    drop(_span);
    info!(
        n_raw = raw_noteheads.len(),
        n_reranked = n_before_classifier,
        n_classifier_filtered = n_after_classifier,
        n_stems = stems.len(),
        n_beams = beams.len(),
        n_bars = bars.len(),
        n_rests = rests.len(),
        n_jump_marks = jump_detections.len(),
        "symbols detected"
    );

    // Debug-Visualisierung (wenn aktiviert) — zeichne alle Detections
    // farbig auf das Original-Grayscale. Wird hier OHNE Measures aufgerufen
    // weil die Score-Konstruktion noch kommt — ein zweiter Debug-Render mit
    // Measures (für Bbox+Sprungmarken-Highlighting) erfolgt am Ende.
    if let Some(ref dir) = opts.debug_dir {
        let staff_systems_lines: Vec<Vec<Vec<u32>>> = systems.iter()
            .map(|s| s.lines.iter().map(|l| l.y_per_x.clone()).collect())
            .collect();
        let overlays = debug_viz::Overlays {
            noteheads: &noteheads,
            stems: &stems,
            beams: &beams,
            bars: &bars,
            staff_systems_lines,
            measures: None,
        };
        let dbg = debug_viz::render_debug_image(&gray, &overlays);
        let _ = dbg.save(dir.join("03_detections.png"));
    }

    // 5) Score-Konstruktion: ein Measure pro StaffSystem, Noten in Reading-Order (X).
    // Clef + Key Signature pro System auf Original-Binary detektieren.
    let clefs: Vec<Clef> = systems.iter().map(|s| omr_symbols::detect_clef(&bin, s)).collect();
    let keys: Vec<omr_core::KeySignature> = systems.iter().map(|s| omr_symbols::detect_key_signature(&bin, s)).collect();
    let detected_time = systems.first().and_then(|s| omr_symbols::meta::detect_time_signature(&bin, s))
        .unwrap_or(TimeSignature { beats: 4, beat_type: 4 });

    // Augmentation-Dot-Detection (Punktierungen) auf staff-removed Bild
    let dots_per_nh = omr_symbols::detect_augmentation_dots(&removed, &noteheads, line_spacing);

    let all_measures_per_system: Vec<Vec<Measure>> = (0..systems.len())
        .map(|sys_i| {
            // Globale Indices der NH dieses Systems sammeln
            let global_indices: Vec<usize> = noteheads.iter().enumerate()
                .filter(|(_, nh)| nh.staff_idx == sys_i)
                .map(|(i, _)| i)
                .collect();
            let mut sorted_global: Vec<usize> = global_indices.clone();
            sorted_global.sort_by(|&a, &b| {
                noteheads[a].center.x.partial_cmp(&noteheads[b].center.x).unwrap_or(std::cmp::Ordering::Equal)
            });
            let nh_local: Vec<omr_core::Notehead> = sorted_global.iter().map(|&i| noteheads[i].clone()).collect();
            let dots_local: Vec<u8> = sorted_global.iter().map(|&i| dots_per_nh.get(i).copied().unwrap_or(0)).collect();
            let stems_local: Vec<omr_core::Stem> = stems
                .iter()
                .filter(|s| {
                    if let Some(idx) = s.notehead_idx {
                        noteheads.get(idx).map(|n| n.staff_idx == sys_i).unwrap_or(false)
                    } else { false }
                })
                .cloned()
                .collect();
            let beam_counts_local: Vec<u32> = omr_symbols::beams_per_stem(&stems_local, &beams);
            let clef_for_sys = clefs.get(sys_i).copied().unwrap_or(Clef::Treble);
            let key_for_sys = keys.get(sys_i).copied().unwrap_or(KeySignature::default());
            let mut all_notes = omr_symbols::noteheads_to_notes_with_dots(
                &nh_local, &systems, &stems_local, &beam_counts_local, clef_for_sys, key_for_sys,
                &dots_local,
            );
            all_notes.sort_by(|a, b| a.center.x.partial_cmp(&b.center.x).unwrap_or(std::cmp::Ordering::Equal));

            let mut bar_xs: Vec<f32> = bars.iter()
                .filter(|b| b.system_idx == sys_i)
                .map(|b| b.x as f32)
                .collect();
            bar_xs.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));

            // Bboxes pro Takt aus den Bar-Positionen + Staff-System-Y-Range berechnen.
            // Wird in den Measures als bbox_orig gespeichert für Phase-A
            // (Live-Position-Highlighting + Cross-Instrument-Sync, Spec 22).
            let staff = &systems[sys_i];
            let line_spacing_local = staff.line_spacing;
            let staff_top_y = staff.lines.first().and_then(|l| l.y_per_x.iter().min().copied()).unwrap_or(0);
            let staff_bot_y = staff.lines.last().and_then(|l| l.y_per_x.iter().max().copied()).unwrap_or(staff_top_y);
            let pad = (line_spacing_local * 1.5) as u32;
            let bbox_top = staff_top_y.saturating_sub(pad);
            let bbox_bot = staff_bot_y.saturating_add(pad);
            // x-Bereich: vom Anfang des Systems (oder Bar-Start) bis zum nächsten Bar
            let staff_x_start = staff.lines.first()
                .and_then(|l| l.y_per_x.iter().position(|&y| y > 0))
                .map(|p| p as u32)
                .unwrap_or(0);

            let mut split = split_into_measures(all_notes, &bar_xs);
            // Berechne Bbox pro Takt aus bar_xs
            let mut bar_xs_full = vec![staff_x_start as f32];
            bar_xs_full.extend(bar_xs.iter().copied());
            // Letzter Bar: Bild-Ende
            bar_xs_full.push(removed.w as f32);
            for (mi, m) in split.iter_mut().enumerate() {
                if mi + 1 < bar_xs_full.len() {
                    let x0 = bar_xs_full[mi].max(0.0) as u32;
                    let x1 = bar_xs_full[mi + 1].min(removed.w as f32) as u32;
                    if x1 > x0 {
                        m.bbox_orig = Some(omr_core::Rect {
                            x: x0,
                            y: bbox_top,
                            w: x1 - x0,
                            h: bbox_bot.saturating_sub(bbox_top),
                        });
                    }
                }
                m.system_idx = Some(sys_i as u32);
            }
            split
        })
        .collect();

    let mut measures: Vec<Measure> = Vec::new();
    let mut measure_num = 1u32;
    for (sys_i, mut sys_measures) in all_measures_per_system.into_iter().enumerate() {
        for (mi, m) in sys_measures.iter_mut().enumerate() {
            m.number = measure_num;
            measure_num += 1;
            if mi == 0 {
                m.clef = clefs.get(sys_i).copied();
                m.key_signature = keys.get(sys_i).copied();
                if sys_i == 0 {
                    m.time_signature = Some(detected_time);
                }
            }
        }
        measures.extend(sys_measures);
    }

    // 5a) Akkord-Detection + Onset-Berechnung. Mehrere NHs auf gleicher
    //     X-Position werden zu einem Akkord gruppiert: erste Note ist Lead,
    //     alle weiteren bekommen in_chord=true und werden in der Plausibility-Σ
    //     ignoriert (sie tragen nicht zur Taktdauer bei).
    mark_chords_and_onsets(&mut measures, line_spacing);

    // 5a-bis) Pausen-Insertion: für jedes leere Measure prüfen ob ein Rest
    // im x-Bereich des Measures detektiert wurde. Wenn ja: einfügen.
    // Wenn das Measure leer ist UND keine Rest gefunden wurde: implicit
    // Whole-Rest hinzufügen (Tacet-Annahme). Dadurch wird der MusicXML-Output
    // gültig und vollständig. Rest-Detection ist konservativ → nur leere
    // Measures werden modifiziert, korrekte Takte bleiben unverändert.
    insert_rests_into_empty_measures(&mut measures, &rests, detected_time);

    // 5b) Plausibilisierung der Takte gegen die erkannte Taktart.
    //     Repariert Takte deren Σ duration nicht passt.
    let measure_checks = omr_symbols::validate_and_repair_part(&mut measures, detected_time);
    let n_measures_exact = measure_checks.iter()
        .filter(|c| matches!(c.plausibility, omr_symbols::MeasurePlausibility::Exact | omr_symbols::MeasurePlausibility::Anacrusis))
        .count();
    let n_measures_broken = measure_checks.iter()
        .filter(|c| matches!(c.plausibility, omr_symbols::MeasurePlausibility::Broken))
        .count();
    let n_measures_repaired = measure_checks.len().saturating_sub(n_measures_exact + n_measures_broken);
    info!(
        n_measures = measure_checks.len(),
        exact = n_measures_exact,
        repaired = n_measures_repaired,
        broken = n_measures_broken,
        "measure plausibility"
    );

    // bar_to_measure-Mapping: jeder Bar wird dem Measure RECHTS davon zugeordnet
    // (oder dem dem Bar selbst - bei RepeatEnd). Wir suchen für jeden Bar das
    // erste Measure dessen Bbox-Center.x > bar.x ist.
    let bar_to_measure: Vec<Option<usize>> = bars.iter().map(|b| {
        let bar_x = b.x as f32;
        measures.iter().position(|m| {
            m.bbox_orig
                .map(|bb| bb.x as f32 + bb.w as f32 * 0.5 >= bar_x)
                .unwrap_or(false)
        })
    }).collect();
    omr_symbols::jump_marks::apply_jump_marks(&mut measures, &bar_to_measure, &jump_detections);

    let part = Part {
        id: "P1".into(),
        name: "Stimme".into(),
        measures,
    };

    let timeline = omr_core::PerformanceTimeline::from_part(&part);
    info!(
        n_jump_detections = jump_detections.len(),
        timeline_len = timeline.len(),
        "performance timeline"
    );

    // Zweiter Debug-Render mit Bbox-/Sprungmarken-Highlighting (Phase A)
    if let Some(ref dir) = opts.debug_dir {
        let staff_systems_lines: Vec<Vec<Vec<u32>>> = systems.iter()
            .map(|s| s.lines.iter().map(|l| l.y_per_x.clone()).collect())
            .collect();
        let overlays = debug_viz::Overlays {
            noteheads: &noteheads,
            stems: &stems,
            beams: &beams,
            bars: &bars,
            staff_systems_lines,
            measures: Some(&part.measures),
        };
        let dbg = debug_viz::render_debug_image(&gray, &overlays);
        let _ = dbg.save(dir.join("04_measures_and_jumps.png"));
    }

    let score = Score {
        work_title: String::new(),
        composer: String::new(),
        parts: vec![part],
    };

    // 6) MusicXML Export.
    let mx_t = std::time::Instant::now();
    let musicxml = omr_musicxml::export(&score)?;
    let musicxml_ms = mx_t.elapsed().as_millis();

    let total_ms = total_t.elapsed().as_millis();
    Ok(PipelineResult {
        score,
        musicxml,
        timings: Timings {
            preprocessing_ms,
            staff_detection_ms,
            staff_removal_ms,
            symbol_detection_ms,
            musicxml_ms,
            total_ms,
        },
        stats: Stats {
            n_systems: systems.len(),
            line_thickness,
            line_spacing,
            n_noteheads: noteheads.len(),
            n_stems: stems.len(),
            n_beams: beams.len(),
            n_bars: bars.len(),
            n_rests: rests.len(),
            n_measures: measure_checks.len(),
            n_measures_exact,
            n_measures_repaired,
            n_measures_broken,
            n_jump_marks: jump_detections.len(),
            timeline_len: timeline.len(),
            deskew_angle_deg: deskew_angle,
            doc_type: Some(match doc_class.doc_type {
                omr_preprocessing::DocumentType::Printed => "printed",
                omr_preprocessing::DocumentType::Handwritten => "handwritten",
                omr_preprocessing::DocumentType::Unknown => "unknown",
            }),
            doc_confidence: doc_class.confidence,
            doc_line_straightness: doc_class.line_straightness,
            doc_line_thickness_stddev: doc_class.line_thickness_stddev,
            doc_gray_variance: doc_class.gray_variance,
            doc_nh_size_cv: nh_size_cv(&noteheads),
        },
    })
}

/// Verarbeite eine Bilddatei (PNG/JPEG/TIFF/BMP).
pub fn process_image(path: &Path, opts: &PipelineOptions) -> Result<PipelineResult> {
    let gray = omr_preprocessing::load_grayscale(path)?;
    let gray = omr_preprocessing::ensure_target_height(&gray, 2000);
    process_gray(gray, opts)
}

/// Splittet Noten anhand der Taktstrich-X-Positionen in Measures.
/// Zwischen aufeinanderfolgenden Bars (oder zwischen Anfang/Ende) entsteht ein Measure.
fn split_into_measures(notes: Vec<omr_core::ScoreNote>, bar_xs: &[f32]) -> Vec<Measure> {
    if bar_xs.is_empty() {
        // Kein Bar → ein Measure
        let mut all = notes;
        all.sort_by(|a, b| a.center.x.partial_cmp(&b.center.x).unwrap_or(std::cmp::Ordering::Equal));
        return vec![Measure {
            number: 1,
            divisions: 4,
            notes: all,
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        }];
    }
    let mut measures = Vec::new();
    let mut prev_x = 0.0f32;
    let bar_iter = bar_xs.iter().copied().chain(std::iter::once(f32::INFINITY));
    for bar_x in bar_iter {
        let mut measure_notes: Vec<omr_core::ScoreNote> = notes
            .iter()
            .filter(|n| n.center.x >= prev_x && n.center.x < bar_x)
            .cloned()
            .collect();
        measure_notes.sort_by(|a, b| {
            a.center.x.partial_cmp(&b.center.x).unwrap_or(std::cmp::Ordering::Equal)
        });
        // Skippe leere Measures bevor der erste Notenkopf kommt (Schlüssel/Vorzeichen-Bereich).
        if !measure_notes.is_empty() || !measures.is_empty() {
            measures.push(Measure {
                number: 0, // wird vom caller numerated
                divisions: 4,
                notes: measure_notes,
                time_signature: None,
                key_signature: None,
                clef: None,
                ..Default::default()
            });
        }
        prev_x = bar_x;
    }
    if measures.is_empty() {
        // Fallback: alle Noten in 1 Measure
        return vec![Measure {
            number: 1,
            divisions: 4,
            notes,
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        }];
    }
    measures
}

/// Markiert Akkorde: aufeinanderfolgende Notes deren X-Center innerhalb von
/// `chord_x_tolerance` liegen, gehören zu einem Akkord. Die erste Note bleibt
/// Lead (in_chord=false), alle weiteren werden auf in_chord=true gesetzt.
/// Setzt außerdem onset so, dass in_chord-Notes denselben onset wie der Lead
/// haben und die nächste Lead-Note onset = lead.onset + lead.duration bekommt.
fn mark_chords_and_onsets(measures: &mut [Measure], line_spacing: f32) {
    // Zwei NHs gehören zum gleichen Onset wenn sie horizontal näher sind als
    // ein NH-Halbradius. Wir nutzen line_spacing als Proxy für NH-Höhe (NH-Höhe
    // ≈ line_spacing). Tolerance = 0.4 × line_spacing ist robust gegenüber
    // NH-Y-Shift bei breiten Akkorden, ohne benachbarte Achtel zu verschmelzen.
    let tol = (line_spacing * 0.40).max(3.0);
    for m in measures.iter_mut() {
        if m.notes.is_empty() {
            continue;
        }
        let mut lead_onset: u32 = 0;
        let mut lead_x = m.notes[0].center.x;
        let mut lead_duration = m.notes[0].duration;
        for (i, n) in m.notes.iter_mut().enumerate() {
            if i == 0 {
                n.in_chord = false;
                n.onset = 0;
                lead_onset = 0;
                lead_x = n.center.x;
                lead_duration = n.duration;
                continue;
            }
            if (n.center.x - lead_x).abs() <= tol {
                // Akkord-Member
                n.in_chord = true;
                n.onset = lead_onset;
                // Behalte die Lead-Duration als die "longest" — falls verschiedene
                // Werte erkannt wurden, nehmen wir die Mehrheits-Lead aber lassen
                // hier die Member intakt (MusicXML braucht ihre Duration).
            } else {
                // Neue Lead-Note: onset = vorherige Lead + ihre Duration
                lead_onset = lead_onset.saturating_add(lead_duration);
                n.in_chord = false;
                n.onset = lead_onset;
                lead_x = n.center.x;
                lead_duration = n.duration;
            }
        }
    }
}

/// Fügt Pausen-Notes in leere Measures ein. Konservativ: nur Measures ohne
/// Notes werden modifiziert, korrekte Takte bleiben unverändert.
///
/// Strategie:
/// 1. Wenn ein Rest-Glyph in der x-Bbox des Measures liegt (gleiches System),
///    füge ihn als Pause ein.
/// 2. Sonst: füge einen impliziten Whole-Rest hinzu (Tacet-Annahme).
fn insert_rests_into_empty_measures(
    measures: &mut [Measure],
    rests: &[omr_symbols::Rest],
    time: omr_core::TimeSignature,
) {
    let expected = (time.beats as u32 * 4 * 4) / time.beat_type as u32;
    for m in measures.iter_mut() {
        if !m.notes.is_empty() {
            continue;
        }
        // Suche Rests in der x-Range dieses Measures (gleiches System)
        let mut measure_rests: Vec<&omr_symbols::Rest> = if let Some(bbox) = m.bbox_orig {
            rests.iter()
                .filter(|r| {
                    Some(r.staff_idx as u32) == m.system_idx
                        && r.center.x as u32 >= bbox.x
                        && (r.center.x as u32) < bbox.x + bbox.w
                })
                .collect()
        } else {
            Vec::new()
        };
        measure_rests.sort_by(|a, b| a.center.x.partial_cmp(&b.center.x).unwrap_or(std::cmp::Ordering::Equal));

        if measure_rests.is_empty() {
            // Implicit Whole-Rest für leere Measures (Tacet)
            m.notes.push(omr_core::ScoreNote {
                midi: 0,
                step: omr_core::PitchStep::C,
                alter: 0,
                octave: 4,
                duration: expected,
                onset: 0,
                voice: 1,
                kind: omr_core::NoteheadKind::Whole,
                center: omr_core::Point {
                    x: m.bbox_orig.map(|b| b.x as f32 + b.w as f32 / 2.0).unwrap_or(0.0),
                    y: m.bbox_orig.map(|b| b.y as f32 + b.h as f32 / 2.0).unwrap_or(0.0),
                },
                augmentation_dots: 0,
                in_chord: false,
                is_rest: true,
            });
        } else {
            let mut onset = 0u32;
            for r in measure_rests {
                m.notes.push(omr_core::ScoreNote {
                    midi: 0,
                    step: omr_core::PitchStep::C,
                    alter: 0,
                    octave: 4,
                    duration: r.kind.duration(),
                    onset,
                    voice: 1,
                    kind: omr_core::NoteheadKind::Filled,
                    center: r.center,
                    augmentation_dots: 0,
                    in_chord: false,
                    is_rest: true,
                });
                onset = onset.saturating_add(r.kind.duration());
            }
        }
    }
}

/// Verarbeite eine PDF-Datei (rendert ALLE Seiten und merged sie zu einem Score).
pub fn process_pdf(path: &Path, opts: &PipelineOptions) -> Result<PipelineResult> {
    let images = pdf_render::render_pages(path, 200)?;
    if images.is_empty() {
        return Err(OmrError::PdfRender("PDF enthält keine Seiten".into()));
    }
    if images.len() == 1 {
        return process_gray(images.into_iter().next().unwrap(), opts);
    }
    // Multi-Page: jede Seite separat verarbeiten, Measures konkatenieren.
    let total_t = std::time::Instant::now();
    let mut merged_score = Score::default();
    let mut merged_part = Part {
        id: "P1".into(),
        name: "Stimme".into(),
        measures: Vec::new(),
    };
    let mut merged_timings = Timings::default();
    let mut merged_stats = Stats::default();
    let mut next_measure = 1u32;

    for (idx, img) in images.into_iter().enumerate() {
        info!(page = idx + 1, "processing page");
        let r = process_gray(img, opts)?;
        merged_timings.preprocessing_ms += r.timings.preprocessing_ms;
        merged_timings.staff_detection_ms += r.timings.staff_detection_ms;
        merged_timings.staff_removal_ms += r.timings.staff_removal_ms;
        merged_timings.symbol_detection_ms += r.timings.symbol_detection_ms;
        merged_timings.musicxml_ms += r.timings.musicxml_ms;
        merged_stats.n_systems += r.stats.n_systems;
        merged_stats.n_noteheads += r.stats.n_noteheads;
        merged_stats.n_stems += r.stats.n_stems;
        merged_stats.n_beams += r.stats.n_beams;
        merged_stats.n_bars += r.stats.n_bars;
        merged_stats.n_rests += r.stats.n_rests;
        merged_stats.n_measures += r.stats.n_measures;
        merged_stats.n_measures_exact += r.stats.n_measures_exact;
        merged_stats.n_measures_repaired += r.stats.n_measures_repaired;
        merged_stats.n_measures_broken += r.stats.n_measures_broken;
        merged_stats.n_jump_marks += r.stats.n_jump_marks;
        merged_stats.timeline_len += r.stats.timeline_len;
        merged_stats.line_thickness = r.stats.line_thickness;
        merged_stats.line_spacing = r.stats.line_spacing;
        merged_stats.deskew_angle_deg = r.stats.deskew_angle_deg;

        if let Some(p) = r.score.parts.into_iter().next() {
            for mut m in p.measures.into_iter() {
                m.number = next_measure;
                next_measure += 1;
                merged_part.measures.push(m);
            }
        }
    }
    merged_score.parts.push(merged_part);
    merged_timings.total_ms = total_t.elapsed().as_millis();
    let musicxml = omr_musicxml::export(&merged_score)?;
    Ok(PipelineResult {
        score: merged_score,
        musicxml,
        timings: merged_timings,
        stats: merged_stats,
    })
}

/// Verarbeite eine PDF-Datei mit allen Seiten und liefert ein PipelineResult pro Seite (Detail-Output).
pub fn process_pdf_pages_separately(path: &Path, opts: &PipelineOptions) -> Result<Vec<PipelineResult>> {
    let images = pdf_render::render_pages(path, 200)?;
    images.into_iter().map(|img| process_gray(img, opts)).collect()
}

/// Coefficient of Variation (Stddev/Mean) der NH-Bbox-Diagonalen.
/// Bei printed: typisch <0.18, bei handwritten: oft >0.30.
fn nh_size_cv(noteheads: &[omr_core::Notehead]) -> f32 {
    if noteheads.len() < 4 {
        return 0.0;
    }
    let sizes: Vec<f32> = noteheads
        .iter()
        .map(|nh| {
            let dx = nh.bbox.w as f32;
            let dy = nh.bbox.h as f32;
            (dx * dx + dy * dy).sqrt()
        })
        .collect();
    let mean = sizes.iter().sum::<f32>() / sizes.len() as f32;
    if mean < 1.0 {
        return 0.0;
    }
    let var = sizes.iter().map(|s| (s - mean).powi(2)).sum::<f32>() / sizes.len() as f32;
    var.sqrt() / mean
}
