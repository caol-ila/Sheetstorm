// OMR-Pipeline-Orchestrator. Verbindet alle Stufen in der richtigen
// Reihenfolge und produziert einen Score (oder MusicXML).

use image::GrayImage;
use omr_core::{
    Clef, KeySignature, Measure, OmrError, Part, PipelineOptions, Result, Score, TimeSignature,
};
use std::path::Path;
use tracing::{info, info_span, warn};

pub mod pdf_render;

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
    pub deskew_angle_deg: f32,
}

/// Verarbeite ein bereits geladenes Grayscale-Bild.
pub fn process_gray(gray: GrayImage, opts: &PipelineOptions) -> Result<PipelineResult> {
    let total_t = std::time::Instant::now();

    // 1) Preprocessing: deskew + binarize.
    let _span = info_span!("preprocessing").entered();
    let pre_t = std::time::Instant::now();
    let (gray, deskew_angle) = omr_preprocessing::deskew(&gray);
    let bin = omr_preprocessing::sauvola(&gray, 25, 0.34);
    let preprocessing_ms = pre_t.elapsed().as_millis();
    drop(_span);
    info!(deskew_angle, count = bin.count(), "preprocessing done");

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

    // 4) Symbol-Detection: Noteheads + Stems + Beams.
    let _span = info_span!("symbol_detection").entered();
    let sym_t = std::time::Instant::now();
    let noteheads = omr_symbols::detect_noteheads(&removed, &systems);
    let stems = omr_symbols::stems::detect_stems(&removed, &noteheads, line_spacing);
    let beams = omr_symbols::detect_beams(&removed, line_spacing);
    let beam_counts = omr_symbols::beams_per_stem(&stems, &beams);
    let symbol_detection_ms = sym_t.elapsed().as_millis();
    drop(_span);
    info!(n_noteheads = noteheads.len(), n_stems = stems.len(), n_beams = beams.len(), "symbols detected");

    // 5) Score-Konstruktion: ein Measure pro StaffSystem, Noten in Reading-Order (X).
    // Clef + Key Signature pro System auf Original-Binary detektieren.
    let clefs: Vec<Clef> = systems.iter().map(|s| omr_symbols::detect_clef(&bin, s)).collect();
    let keys: Vec<omr_core::KeySignature> = systems.iter().map(|s| omr_symbols::detect_key_signature(&bin, s)).collect();

    let all_notes_per_system: Vec<Vec<omr_core::ScoreNote>> = (0..systems.len())
        .map(|sys_i| {
            let mut filtered: Vec<&omr_core::Notehead> =
                noteheads.iter().filter(|nh| nh.staff_idx == sys_i).collect();
            filtered.sort_by(|a, b| a.center.x.partial_cmp(&b.center.x).unwrap_or(std::cmp::Ordering::Equal));
            let nh_local: Vec<omr_core::Notehead> = filtered.into_iter().cloned().collect();
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
            let mut notes = omr_symbols::noteheads_to_notes(&nh_local, &systems, &stems_local, &beam_counts_local, clef_for_sys, key_for_sys);
            notes.sort_by(|a, b| a.center.x.partial_cmp(&b.center.x).unwrap_or(std::cmp::Ordering::Equal));
            let mut onset = 0u32;
            for n in notes.iter_mut() {
                n.onset = onset;
                onset += n.duration;
            }
            notes
        })
        .collect();

    let measures: Vec<Measure> = all_notes_per_system
        .into_iter()
        .enumerate()
        .map(|(i, notes)| Measure {
            number: (i + 1) as u32,
            divisions: 4,
            notes,
            time_signature: if i == 0 { Some(TimeSignature { beats: 4, beat_type: 4 }) } else { None },
            key_signature: keys.get(i).copied(),
            clef: clefs.get(i).copied(),
        })
        .collect();

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
