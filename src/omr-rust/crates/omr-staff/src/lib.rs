// Staff-Line Detection mit Stable Paths (Cardoso et al. 2009)
//      "Staff Detection with Stable Paths", IEEE TPAMI 31(6).
//
// Algorithmus (eigenständige Implementation, keine Code-Übernahme):
//
//   1. RLE-Statistik: ermittle die häufigste schwarze Run-Länge (= Linien-
//      stärke `staff_line_thickness`) und die häufigste weiße Run-Länge
//      (= Notenliniensystem-Spacing `staff_line_spacing`).
//
//   2. Trace pro Bildzeile y: starte bei (0, y) und gehe pro X-Schritt zu
//      der Y-Position in {y-1, y, y+1} mit niedrigsten Kosten. Schwarze
//      Pixel kosten 0, weiße Pixel kosten 5, Y-Sprünge kosten 1.
//
//   3. Verbundene Linien gruppieren: Linien die genau `staff_spacing` ±tol
//      auseinander liegen → zu einem StaffSystem (5 Linien).

use omr_core::{Binary, StaffLine, StaffSystem};
use rayon::prelude::*;
use tracing::{debug, info};

pub mod removal;
pub use removal::remove_staff;

/// Detect staff systems in a binary image.
pub fn detect_systems(bin: &Binary) -> Vec<StaffSystem> {
    let stats = analyze_runs(bin);
    info!(
        line_thickness = stats.line_thickness,
        line_spacing = stats.line_spacing,
        "RLE statistics"
    );

    if stats.line_thickness == 0 || stats.line_spacing == 0 {
        return vec![];
    }

    let candidates = find_line_candidates(bin, &stats);
    debug!(n = candidates.len(), "candidate line rows");

    let lines: Vec<StaffLine> = candidates
        .par_iter()
        .map(|&y0| trace_stable_path(bin, y0, stats.line_thickness))
        .collect();

    group_into_systems(lines, stats.line_spacing as f32, stats.line_thickness as f32)
}

#[derive(Debug, Clone, Copy)]
pub(crate) struct RunStats {
    pub line_thickness: u32,
    pub line_spacing: u32,
}

fn analyze_runs(bin: &Binary) -> RunStats {
    let mut black_hist = vec![0u32; 32];
    let mut white_hist = vec![0u32; 256];

    let step = (bin.w / 200).max(1);
    for x in (0..bin.w).step_by(step as usize) {
        let mut run_val = bin.get(x, 0);
        let mut run_len = 1u32;
        for y in 1..bin.h {
            let v = bin.get(x, y);
            if v == run_val {
                run_len += 1;
            } else {
                if run_val == 1 && (run_len as usize) < black_hist.len() {
                    black_hist[run_len as usize] += 1;
                } else if run_val == 0 && (run_len as usize) < white_hist.len() {
                    white_hist[run_len as usize] += 1;
                }
                run_val = v;
                run_len = 1;
            }
        }
    }

    let line_thickness = black_hist
        .iter()
        .enumerate()
        .skip(1)
        .max_by_key(|&(_, c)| *c)
        .map(|(i, _)| i as u32)
        .unwrap_or(2);

    let lo = (line_thickness * 2).max(4) as usize;
    let hi = 60.min(white_hist.len() - 1);
    let line_spacing = white_hist[lo..=hi]
        .iter()
        .enumerate()
        .max_by_key(|&(_, c)| *c)
        .map(|(i, _)| (i + lo) as u32)
        .unwrap_or(12);

    let line_spacing = line_spacing + line_thickness;
    RunStats { line_thickness, line_spacing }
}

fn find_line_candidates(bin: &Binary, stats: &RunStats) -> Vec<u32> {
    let dens = bin.row_density();
    let threshold = (bin.w as f32 * 0.4) as u32;
    let mut peaks = Vec::new();
    let mut last = 0u32;
    for (y, &d) in dens.iter().enumerate() {
        let y = y as u32;
        if d >= threshold {
            if y as i32 - last as i32 >= stats.line_thickness as i32 {
                peaks.push(y);
                last = y;
            }
        }
    }
    peaks
}

fn trace_stable_path(bin: &Binary, y0: u32, _thickness: u32) -> StaffLine {
    let w = bin.w;
    let h = bin.h;
    let mut y_per_x = Vec::with_capacity(w as usize);
    let mut y = y0 as i32;
    y_per_x.push(y as u32);
    for x in 1..w {
        let candidates = [y, y - 1, y + 1];
        let mut best_y = y;
        let mut best_cost = u32::MAX;
        for &cy in &candidates {
            if cy < 0 || cy as u32 >= h { continue; }
            let pixel_cost = if bin.get(x, cy as u32) == 1 { 0u32 } else { 5u32 };
            let jump_penalty = if cy != y { 1u32 } else { 0u32 };
            let cost = pixel_cost + jump_penalty;
            if cost < best_cost {
                best_cost = cost;
                best_y = cy;
            }
        }
        y = best_y;
        y_per_x.push(y as u32);
    }
    StaffLine { y_per_x }
}

fn group_into_systems(lines: Vec<StaffLine>, expected_spacing: f32, thickness: f32) -> Vec<StaffSystem> {
    if lines.is_empty() { return vec![]; }

    let mut sorted: Vec<StaffLine> = lines;
    sorted.sort_by(|a, b| a.mean_y().partial_cmp(&b.mean_y()).unwrap_or(std::cmp::Ordering::Equal));

    let mut systems: Vec<StaffSystem> = Vec::new();
    let mut current: Vec<StaffLine> = Vec::new();
    let tol = expected_spacing * 0.5;

    for line in sorted {
        if current.is_empty() {
            current.push(line);
            continue;
        }
        let last_y = current.last().unwrap().mean_y();
        let dy = line.mean_y() - last_y;
        if dy.abs() < expected_spacing * 0.2 {
            continue;
        }
        if (dy - expected_spacing).abs() < tol {
            current.push(line);
            if current.len() == 5 {
                systems.push(StaffSystem {
                    lines: std::mem::take(&mut current),
                    line_spacing: expected_spacing,
                    line_thickness: thickness,
                });
            }
        } else {
            current.clear();
            current.push(line);
        }
    }

    debug!(n = systems.len(), "grouped into staff systems");
    systems
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_synthetic_staff(w: u32, h: u32, n_systems: u32, spacing: u32, line_t: u32) -> Binary {
        let mut bin = Binary::new(w, h);
        for s in 0..n_systems {
            let base_y = (s + 1) * 80 + 60;
            for line in 0..5u32 {
                let y0 = base_y + line * spacing;
                for t in 0..line_t {
                    for x in 5..w - 5 {
                        bin.set(x, y0 + t, 1);
                    }
                }
            }
        }
        bin
    }

    #[test]
    fn finds_stafflines_in_synthetic_image() {
        let bin = make_synthetic_staff(800, 1000, 2, 14, 2);
        let systems = detect_systems(&bin);
        assert_eq!(systems.len(), 2, "expected 2 staff systems");
        for s in &systems {
            assert_eq!(s.lines.len(), 5);
        }
    }

    #[test]
    fn removes_stafflines() {
        let bin = make_synthetic_staff(800, 1000, 1, 14, 2);
        let systems = detect_systems(&bin);
        let removed = remove_staff(&bin, &systems);
        // Vorher ~5 Linien * 790 px * 2 = 7900 schwarze Pixel
        assert!(bin.count() > 5000);
        // Nachher fast weiß
        assert!(removed.count() < 500, "expected most to be removed: {}", removed.count());
    }
}
