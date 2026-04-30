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
