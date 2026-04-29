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

    // 4) Symbol-Detection: Noteheads + Stems.
    let _span = info_span!("symbol_detection").entered();
    let sym_t = std::time::Instant::now();
    let noteheads = omr_symbols::detect_noteheads(&removed, &systems);
    let stems = omr_symbols::stems::detect_stems(&removed, &noteheads, line_spacing);
    let symbol_detection_ms = sym_t.elapsed().as_millis();
    drop(_span);
    info!(n_noteheads = noteheads.len(), n_stems = stems.len(), "symbols detected");

    // 5) Score-Konstruktion: ein Measure pro StaffSystem, Noten in Reading-Order (X).
    let clef = Clef::Treble;
    let key = KeySignature::default();

    let all_notes_per_system: Vec<Vec<omr_core::ScoreNote>> = (0..systems.len())
        .map(|sys_i| {
            let mut filtered: Vec<&omr_core::Notehead> =
                noteheads.iter().filter(|nh| nh.staff_idx == sys_i).collect();
            filtered.sort_by(|a, b| a.center.x.partial_cmp(&b.center.x).unwrap_or(std::cmp::Ordering::Equal));
            // notehead_indices in original-Reihenfolge — filter map zur stems lookup
            let nh_local: Vec<omr_core::Notehead> = filtered.into_iter().cloned().collect();
            // stems neu mappen — wir müssen für die filter ent-indexen, vereinfacht: Match per Index in nh_local fehlt,
            // wir matchen Stems über räumliche Nähe.
            let stems_local: Vec<omr_core::Stem> = stems
                .iter()
                .filter(|s| {
                    if let Some(idx) = s.notehead_idx {
                        noteheads.get(idx).map(|n| n.staff_idx == sys_i).unwrap_or(false)
                    } else { false }
                })
                .cloned()
                .collect();
            let mut notes = omr_symbols::noteheads_to_notes(&nh_local, &systems, &stems_local, clef, key);
            notes.sort_by(|a, b| a.center.x.partial_cmp(&b.center.x).unwrap_or(std::cmp::Ordering::Equal));
            // Onset = sequenzielle Position * 1 (vereinfacht)
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
            key_signature: if i == 0 { Some(key) } else { None },
            clef: if i == 0 { Some(clef) } else { None },
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

/// Verarbeite eine PDF-Datei (rendert die erste Seite).
/// Wenn `pdfium` nicht initialisiert werden kann, wird ein deutlicher
/// Fehler zurückgegeben.
pub fn process_pdf(path: &Path, opts: &PipelineOptions) -> Result<PipelineResult> {
    let images = pdf_render::render_pages(path, 200)?;
    let first = images.into_iter().next().ok_or_else(|| OmrError::PdfRender("PDF enthält keine Seiten".into()))?;
    process_gray(first, opts)
}

/// Verarbeite eine PDF-Datei mit allen Seiten und liefert PipelineResult pro Seite.
pub fn process_pdf_all_pages(path: &Path, opts: &PipelineOptions) -> Result<Vec<PipelineResult>> {
    let images = pdf_render::render_pages(path, 200)?;
    images.into_iter().map(|img| process_gray(img, opts)).collect()
}
