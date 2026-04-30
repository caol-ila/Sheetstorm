// OMR-Pipeline-Orchestrator. Verbindet alle Stufen in der richtigen
// Reihenfolge und produziert einen Score (oder MusicXML).

use image::GrayImage;
use omr_core::{
    Clef, KeySignature, Measure, OmrError, Part, PipelineOptions, Result, Score, TimeSignature,
};
use std::path::Path;
use tracing::{info, info_span, warn};

pub mod accuracy;
pub mod debug_viz;
pub mod muscima;
pub mod pdf_render;
pub mod synthetic;

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
    pub n_measures: usize,
    pub n_measures_exact: usize,
    pub n_measures_repaired: usize,
    pub n_measures_broken: usize,
    pub deskew_angle_deg: f32,
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

    // 3) Staff-Removal.
    let sr_t = std::time::Instant::now();
    let removed = omr_staff::remove_staff(&bin, &systems);
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
    let stems = omr_symbols::stems::detect_stems(&removed, &noteheads, line_spacing);
    let beams = omr_symbols::detect_beams(&removed, line_spacing);
    let beam_counts = omr_symbols::beams_per_stem(&stems, &beams);
    let bars = omr_symbols::detect_measure_bars(&bin, &systems, &noteheads);
    let symbol_detection_ms = sym_t.elapsed().as_millis();
    drop(_span);
    info!(
        n_raw = raw_noteheads.len(),
        n_reranked = noteheads.len(),
        n_stems = stems.len(),
        n_beams = beams.len(),
        n_bars = bars.len(),
        "symbols detected"
    );

    // Debug-Visualisierung (wenn aktiviert) — zeichne alle Detections
    // farbig auf das Original-Grayscale.
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

            split_into_measures(all_notes, &bar_xs)
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

    let part = Part {
        id: "P1".into(),
        name: "Stimme".into(),
        measures,
    };

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
            n_measures: measure_checks.len(),
            n_measures_exact,
            n_measures_repaired,
            n_measures_broken,
            deskew_angle_deg: deskew_angle,
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
        let mut onset = 0u32;
        for n in all.iter_mut() {
            n.onset = onset;
            onset += n.duration;
        }
        return vec![Measure {
            number: 1,
            divisions: 4,
            notes: all,
            time_signature: None,
            key_signature: None,
            clef: None,
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
        let mut onset = 0u32;
        for n in measure_notes.iter_mut() {
            n.onset = onset;
            onset += n.duration;
        }
        // Skippe leere Measures bevor der erste Notenkopf kommt (Schlüssel/Vorzeichen-Bereich).
        if !measure_notes.is_empty() || !measures.is_empty() {
            measures.push(Measure {
                number: 0, // wird vom caller numerated
                divisions: 4,
                notes: measure_notes,
                time_signature: None,
                key_signature: None,
                clef: None,
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
        }];
    }
    measures
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
        merged_stats.n_measures += r.stats.n_measures;
        merged_stats.n_measures_exact += r.stats.n_measures_exact;
        merged_stats.n_measures_repaired += r.stats.n_measures_repaired;
        merged_stats.n_measures_broken += r.stats.n_measures_broken;
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
