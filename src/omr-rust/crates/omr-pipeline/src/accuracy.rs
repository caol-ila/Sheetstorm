// Accuracy-Metriken: vergleicht OMR-Output gegen Ground-Truth.
//
// Pro Pipeline-Stufe Precision/Recall:
//  - Notehead-Detection: position-tolerant (innerhalb 0.5*spacing)
//  - Stem-Matching: pro Stem mit zugeordneter NH
//  - Beam-Detection: Beam-Y-Position innerhalb 0.5*spacing
//  - Bar-Detection: X-Position innerhalb 0.5*spacing
//  - Pitch-Accuracy: korrekt klassifizierte Pitches (von gematchten NHs)
//  - Duration-Accuracy: korrekt klassifizierte Durations
//
// Format-Hinweis: Wir matchen via Hungarian/Greedy. Greedy reicht hier
// weil typisch Distanzen klein und Konflikte selten.

use crate::synthetic::{GroundTruth, NoteKind};
use omr_core::{Notehead, Stem};
use omr_symbols::{beams::Beam, bars::MeasureBar};

#[derive(Debug, Clone, Copy, Default)]
pub struct PrecisionRecall {
    pub tp: u32,
    pub fp: u32,
    pub fn_: u32,
}

impl PrecisionRecall {
    pub fn precision(&self) -> f32 {
        if self.tp + self.fp == 0 { return 0.0; }
        self.tp as f32 / (self.tp + self.fp) as f32
    }
    pub fn recall(&self) -> f32 {
        if self.tp + self.fn_ == 0 { return 0.0; }
        self.tp as f32 / (self.tp + self.fn_) as f32
    }
    pub fn f1(&self) -> f32 {
        let p = self.precision();
        let r = self.recall();
        if p + r == 0.0 { return 0.0; }
        2.0 * p * r / (p + r)
    }
}

#[derive(Debug, Clone, Default)]
pub struct StageMetrics {
    pub noteheads: PrecisionRecall,
    pub stems: PrecisionRecall,
    pub beams: PrecisionRecall,
    pub bars: PrecisionRecall,
    /// Pitch-Genauigkeit: von den Matched-NHs, wie viele haben den richtigen Pitch?
    pub pitch_correct: u32,
    pub pitch_total: u32,
    /// Notehead-Kind: Filled/Open/Whole korrekt?
    pub kind_correct: u32,
    pub kind_total: u32,
}

impl StageMetrics {
    pub fn pitch_accuracy(&self) -> f32 {
        if self.pitch_total == 0 { return 0.0; }
        self.pitch_correct as f32 / self.pitch_total as f32
    }
    pub fn kind_accuracy(&self) -> f32 {
        if self.kind_total == 0 { return 0.0; }
        self.kind_correct as f32 / self.kind_total as f32
    }
}

/// Greedy-Match: für jedes GT-Element das nächste Pred mit Distanz < tol.
/// Returns (tp, fp, fn) und die Indices der gematchten Pred-Elemente.
fn match_points<G, P>(
    gt: &[G],
    pred: &[P],
    tol: f32,
    gt_pos: impl Fn(&G) -> (f32, f32),
    pred_pos: impl Fn(&P) -> (f32, f32),
) -> (PrecisionRecall, Vec<Option<usize>>) {
    let mut matched_pred = vec![false; pred.len()];
    let mut gt_match: Vec<Option<usize>> = vec![None; gt.len()];

    for (gi, g) in gt.iter().enumerate() {
        let (gx, gy) = gt_pos(g);
        let mut best: Option<(usize, f32)> = None;
        for (pi, p) in pred.iter().enumerate() {
            if matched_pred[pi] { continue; }
            let (px, py) = pred_pos(p);
            let d = ((gx - px).powi(2) + (gy - py).powi(2)).sqrt();
            if d < tol {
                if best.map(|(_, bd)| d < bd).unwrap_or(true) {
                    best = Some((pi, d));
                }
            }
        }
        if let Some((pi, _)) = best {
            matched_pred[pi] = true;
            gt_match[gi] = Some(pi);
        }
    }

    let tp = gt_match.iter().filter(|m| m.is_some()).count() as u32;
    let fp = matched_pred.iter().filter(|m| !**m).count() as u32;
    let fn_ = gt_match.iter().filter(|m| m.is_none()).count() as u32;
    (PrecisionRecall { tp, fp, fn_ }, gt_match)
}

pub fn evaluate(
    gt: &GroundTruth,
    noteheads: &[Notehead],
    stems: &[Stem],
    beams: &[Beam],
    bars: &[MeasureBar],
) -> StageMetrics {
    let mut m = StageMetrics::default();

    // 1. Noteheads: position-tolerant match (0.5 * spacing)
    let nh_tol = gt.spacing * 0.5;
    let (nh_pr, nh_match) = match_points(
        &gt.noteheads,
        noteheads,
        nh_tol,
        |g| (g.center_x, g.center_y),
        |p| (p.center.x, p.center.y),
    );
    m.noteheads = nh_pr;

    // 2. Pitch / Kind-Genauigkeit auf gematchten NHs
    for (gi, &maybe_pi) in nh_match.iter().enumerate() {
        if let Some(pi) = maybe_pi {
            let g = &gt.noteheads[gi];
            let p = &noteheads[pi];
            m.kind_total += 1;
            let kind_match = match (g.kind, p.kind) {
                (NoteKind::Filled, omr_core::NoteheadKind::Filled) => true,
                (NoteKind::Open, omr_core::NoteheadKind::Open) => true,
                (NoteKind::Whole, omr_core::NoteheadKind::Whole) => true,
                _ => false,
            };
            if kind_match { m.kind_correct += 1; }
            // Pitch wird über noteheads_to_notes geprüft — hier nur step+octave
            // anhand position (das macht der eigentliche pipeline.score-Test).
            m.pitch_total += 1;
            // (Pitch ist nicht direkt im Notehead, das käme aus dem Score.
            //  Hier zählen wir es als richtig wenn die Y-Position passt.)
            let dy = (g.center_y - p.center.y).abs();
            if dy < gt.spacing * 0.3 {
                m.pitch_correct += 1;
            }
        }
    }

    // 3. Stems: tolerant match auf x-Position UND y-Range-Overlap
    let stem_tol = gt.spacing * 0.6;
    let (stem_pr, _) = match_points(
        &gt.stems,
        stems,
        stem_tol,
        |g| (g.x, (g.y_top + g.y_bot) / 2.0),
        |p| (p.x as f32, ((p.y_top + p.y_bot) / 2) as f32),
    );
    m.stems = stem_pr;

    // 4. Beams
    let beam_tol = gt.spacing * 0.6;
    let (beam_pr, _) = match_points(
        &gt.beams,
        beams,
        beam_tol,
        |g| ((g.x_start + g.x_end) / 2.0, g.y),
        |p| ((p.x_start + p.x_end) as f32 / 2.0, (p.y_top + p.y_bot) as f32 / 2.0),
    );
    m.beams = beam_pr;

    // 5. Bars: nur x-Position (y irrelevant)
    let bar_tol = gt.spacing * 0.5;
    let (bar_pr, _) = match_points(
        &gt.bars,
        bars,
        bar_tol,
        |g| (g.x, 0.0),
        |p| (p.x as f32, 0.0),
    );
    m.bars = bar_pr;

    m
}

/// Komplette Pipeline laufen lassen und Metriken berechnen.
pub fn benchmark_pipeline(
    image: &image::GrayImage,
    gt: &GroundTruth,
) -> (StageMetrics, std::time::Duration) {
    use std::time::Instant;
    let started = Instant::now();
    let (gray, _angle) = omr_preprocessing::deskew(image);
    let noise = omr_preprocessing::estimate_noise_level(&gray);
    let gray = if noise > 0.04 {
        omr_preprocessing::despeckle_strong(&gray)
    } else {
        omr_preprocessing::median3x3(&gray)
    };
    let bin = omr_preprocessing::sauvola(&gray, 25, 0.34);
    let systems = omr_staff::detect_systems(&bin);
    let removed = omr_staff::remove_staff(&bin, &systems);
    let noteheads = omr_symbols::detect_noteheads(&removed, &systems);
    let line_spacing = systems.first().map(|s| s.line_spacing).unwrap_or(gt.spacing);
    let stems = omr_symbols::stems::detect_stems(&removed, &noteheads, line_spacing);
    let beams = omr_symbols::detect_beams(&removed, line_spacing);
    let bars = omr_symbols::detect_measure_bars(&bin, &systems, &noteheads);
    let elapsed = started.elapsed();

    let metrics = evaluate(gt, &noteheads, &stems, &beams, &bars);
    (metrics, elapsed)
}

pub fn print_report(name: &str, m: &StageMetrics, duration: std::time::Duration) {
    println!("=== {} ({:.0}ms) ===", name, duration.as_secs_f32() * 1000.0);
    println!("  NH:    P={:.2} R={:.2} F1={:.2}  ({} TP, {} FP, {} FN)",
        m.noteheads.precision(), m.noteheads.recall(), m.noteheads.f1(),
        m.noteheads.tp, m.noteheads.fp, m.noteheads.fn_);
    println!("  Stems: P={:.2} R={:.2} F1={:.2}  ({} TP, {} FP, {} FN)",
        m.stems.precision(), m.stems.recall(), m.stems.f1(),
        m.stems.tp, m.stems.fp, m.stems.fn_);
    println!("  Beams: P={:.2} R={:.2} F1={:.2}  ({} TP, {} FP, {} FN)",
        m.beams.precision(), m.beams.recall(), m.beams.f1(),
        m.beams.tp, m.beams.fp, m.beams.fn_);
    println!("  Bars:  P={:.2} R={:.2} F1={:.2}  ({} TP, {} FP, {} FN)",
        m.bars.precision(), m.bars.recall(), m.bars.f1(),
        m.bars.tp, m.bars.fp, m.bars.fn_);
    println!("  Pitch: {:.1}% ({}/{})", m.pitch_accuracy() * 100.0, m.pitch_correct, m.pitch_total);
    println!("  Kind:  {:.1}% ({}/{})", m.kind_accuracy() * 100.0, m.kind_correct, m.kind_total);
}

/// Evaluiert die Pipeline gegen eine MUSCIMA++-Annotation.
///
/// Im Gegensatz zu `evaluate` (synthetisch, mit bekanntem Spacing) müssen
/// wir hier:
///  * das Staff-Spacing vom Detektor übernehmen (Fallback: aus
///    NH-Bounding-Box-Höhen geschätzt)
///  * Match-Toleranzen relativ zur typischen NH-Höhe wählen, weil
///    handgeschriebene Symbole stark variieren
///  * NoteheadKind nicht 1:1 vergleichen (MuNG kennt nur full/half/whole,
///    ohne Kontext, ob ein "noteheadFull mit stem+beam" eine 8tel ist).
///
/// Tolerance-Heuristik: 0.7 * line_spacing (großzügiger als bei synthetisch
/// rein generierten Bildern, wegen Handschrift-Streuung).
pub fn evaluate_against_muscima(
    ann: &crate::muscima::MuscimaAnnotation,
    detector_spacing: f32,
    noteheads: &[Notehead],
    stems: &[Stem],
    beams: &[Beam],
    bars: &[MeasureBar],
) -> StageMetrics {
    let mut m = StageMetrics::default();

    // Spacing-Fallback: median height of full noteheads als Proxy.
    let spacing = if detector_spacing > 1.0 {
        detector_spacing
    } else {
        let mut hs: Vec<f32> = ann
            .noteheads_full
            .iter()
            .map(|s| s.bbox.h as f32)
            .collect();
        hs.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
        hs.get(hs.len() / 2).copied().unwrap_or(20.0)
    };

    let nh_tol = spacing * 0.7;

    // GT-Noteheads: alle full+half+whole.
    let gt_nh: Vec<(f32, f32)> = ann.all_noteheads().map(|s| s.center()).collect();
    let pred_nh: Vec<(f32, f32)> = noteheads
        .iter()
        .map(|p| (p.center.x, p.center.y))
        .collect();
    let (nh_pr, nh_match) = match_points(&gt_nh, &pred_nh, nh_tol, |g| *g, |p| *p);
    m.noteheads = nh_pr;

    // Pitch-Accuracy: Y-Position innerhalb 0.4*spacing als grobe Pitch-Korrektheit.
    let gt_nh_vec: Vec<&crate::muscima::MuscimaSymbol> = ann.all_noteheads().collect();
    for (gi, &maybe_pi) in nh_match.iter().enumerate() {
        if let Some(pi) = maybe_pi {
            m.pitch_total += 1;
            let dy = (gt_nh_vec[gi].center().1 - noteheads[pi].center.y).abs();
            if dy < spacing * 0.4 {
                m.pitch_correct += 1;
            }
            // Kind-Match: full→Filled, half→Open, whole→Whole.
            m.kind_total += 1;
            let gt_kind = match gt_nh_vec[gi].class_name.as_str() {
                "noteheadFull" | "noteheadFullSmall" => Some(omr_core::NoteheadKind::Filled),
                "noteheadHalf" | "noteheadHalfSmall" | "noteheadEmpty" => {
                    Some(omr_core::NoteheadKind::Open)
                }
                "noteheadWhole" => Some(omr_core::NoteheadKind::Whole),
                _ => None,
            };
            if gt_kind == Some(noteheads[pi].kind) {
                m.kind_correct += 1;
            }
        }
    }

    // Stems: x + y-Mitte vergleichen.
    let gt_stems: Vec<(f32, f32)> = ann.stems.iter().map(|s| s.center()).collect();
    let pred_stems: Vec<(f32, f32)> = stems
        .iter()
        .map(|p| (p.x as f32, ((p.y_top + p.y_bot) / 2) as f32))
        .collect();
    let (stem_pr, _) = match_points(&gt_stems, &pred_stems, spacing * 0.8, |g| *g, |p| *p);
    m.stems = stem_pr;

    // Beams: Mittelpunkt vs. Mittelpunkt.
    let gt_beams: Vec<(f32, f32)> = ann.beams.iter().map(|s| s.center()).collect();
    let pred_beams: Vec<(f32, f32)> = beams
        .iter()
        .map(|p| {
            (
                (p.x_start + p.x_end) as f32 / 2.0,
                (p.y_top + p.y_bot) as f32 / 2.0,
            )
        })
        .collect();
    let (beam_pr, _) = match_points(&gt_beams, &pred_beams, spacing * 0.8, |g| *g, |p| *p);
    m.beams = beam_pr;

    // Bars: nur x-Position.
    let gt_bars: Vec<(f32, f32)> = ann.bars.iter().map(|s| (s.center().0, 0.0)).collect();
    let pred_bars: Vec<(f32, f32)> = bars.iter().map(|p| (p.x as f32, 0.0)).collect();
    let (bar_pr, _) = match_points(&gt_bars, &pred_bars, spacing * 0.7, |g| *g, |p| *p);
    m.bars = bar_pr;

    m
}

/// Pipeline gegen ein reales (MUSCIMA++) Bild laufen lassen und Metriken berechnen.
///
/// Im Gegensatz zu `benchmark_pipeline` wird hier mit handgeschriebenen
/// Scans gearbeitet — weniger Annahmen über Bildgröße, gröbere Toleranzen.
pub fn benchmark_pipeline_real(
    image: &image::GrayImage,
    ann: &crate::muscima::MuscimaAnnotation,
) -> (StageMetrics, std::time::Duration) {
    use std::time::Instant;
    let started = Instant::now();
    let (gray, _angle) = omr_preprocessing::deskew(image);
    let noise = omr_preprocessing::estimate_noise_level(&gray);
    let gray = if noise > 0.04 {
        omr_preprocessing::despeckle_strong(&gray)
    } else {
        omr_preprocessing::median3x3(&gray)
    };
    let bin = omr_preprocessing::sauvola(&gray, 25, 0.34);
    let systems = omr_staff::detect_systems(&bin);
    let removed = omr_staff::remove_staff(&bin, &systems);
    let noteheads = omr_symbols::detect_noteheads(&removed, &systems);
    let line_spacing = systems.first().map(|s| s.line_spacing).unwrap_or(0.0);
    let stems = omr_symbols::stems::detect_stems(&removed, &noteheads, line_spacing.max(1.0));
    let beams = omr_symbols::detect_beams(&removed, line_spacing.max(1.0));
    let bars = omr_symbols::detect_measure_bars(&bin, &systems, &noteheads);
    let elapsed = started.elapsed();

    let metrics = evaluate_against_muscima(ann, line_spacing, &noteheads, &stems, &beams, &bars);
    (metrics, elapsed)
}
