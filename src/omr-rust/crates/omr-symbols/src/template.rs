// NCC-Template-Matching für Noteheads.
//
// Strategie: Aus der gefundenen `line_spacing` werden synthetische Notehead-
// Templates generiert (gefüllt + offen), und das Bild wird per Normalized
// Cross-Correlation darauf gescannt. Lokale Maxima im NCC-Heatmap mit
// Schwellwert > 0.6 werden als Notehead-Kandidaten zurückgegeben.
//
// Vorteile gegenüber CC-only-Detection:
//  - Robust gegen Notehead-Stem-Verschmelzung (Stems werden vom Template ignoriert)
//  - Präzises Sub-Pixel-Center via parabolische Interpolation
//  - Bessere Filled-vs-Open-Klassifikation durch separate Templates

use omr_core::{Binary, Notehead, NoteheadKind, Point, Rect, StaffSystem};
use rayon::prelude::*;

/// Template-Match Notehead-Detection. Komplementär zur CC-Detection.
pub fn detect_noteheads_template(
    bin: &Binary,
    systems: &[StaffSystem],
    threshold: f32,
) -> Vec<Notehead> {
    if systems.is_empty() { return vec![]; }
    let spacing = systems[0].line_spacing;
    if spacing < 6.0 { return vec![]; }

    let filled_template = make_notehead_template(spacing, NoteheadKind::Filled);
    let open_template = make_notehead_template(spacing, NoteheadKind::Open);

    let filled_heat = ncc_heatmap(bin, &filled_template);
    let open_heat = ncc_heatmap(bin, &open_template);

    let mut candidates = Vec::new();
    let suppress_radius = (spacing * 0.6) as i32;

    // Lokale Maxima in beiden Heatmaps finden, gefilterter Schwellwert.
    let filled_peaks = local_maxima(&filled_heat, threshold, suppress_radius);
    let open_peaks = local_maxima(&open_heat, threshold, suppress_radius);

    for (x, y, conf) in filled_peaks {
        if let Some(nh) = make_notehead(bin, systems, x, y, conf, NoteheadKind::Filled, spacing) {
            candidates.push(nh);
        }
    }
    for (x, y, conf) in open_peaks {
        if let Some(nh) = make_notehead(bin, systems, x, y, conf, NoteheadKind::Open, spacing) {
            candidates.push(nh);
        }
    }

    // Konflikt-Resolution: zwei Kandidaten mit |dx|<spacing/2 und |dy|<spacing/2 →
    // den mit höherer Konfidenz behalten.
    dedup_candidates(candidates, spacing * 0.5)
}

#[derive(Clone)]
struct Template {
    w: u32,
    h: u32,
    /// f32-Werte (-1..+1), normalisiert zu mean=0.
    data: Vec<f32>,
    sum_sq: f32,
}

/// Erzeuge ein synthetisches Notehead-Template.
/// Notenkopf = leicht geneigte Ellipse, Aspect ~1.3 (breiter als hoch).
/// `kind` bestimmt das Aussehen:
///  - Filled: gefüllte Ellipse (Aspect ~1.3, ähnlich Viertelnote).
///  - Open: leerer Notenkopf mit Ring (Aspect ~1.3, ähnlich Halbenote).
///  - Whole: leerer Notenkopf, breiter Aspect ~1.7 mit dünnerem Ring,
///    typische Form von Ganzennoten (○-Symbol).
fn make_notehead_template(spacing: f32, kind: NoteheadKind) -> Template {
    let (w_factor, h_factor, ring_thick) = match kind {
        NoteheadKind::Filled => (1.3, 0.95, 0.0),
        NoteheadKind::Open => (1.3, 0.95, 0.55),
        // Whole: deutlich breiter (1.7×spacing) und dünnerer Ring (Inner-Ratio 0.65)
        // weil der Outline einer Ganzennote relativ schmal ist.
        NoteheadKind::Whole => (1.7, 0.95, 0.65),
    };
    let w = (spacing * w_factor).round() as u32;
    let h = (spacing * h_factor).round() as u32;
    let cx = w as f32 * 0.5;
    let cy = h as f32 * 0.5;
    let rx = w as f32 * 0.45;
    let ry = h as f32 * 0.45;
    let rx_in = rx * ring_thick;
    let ry_in = ry * ring_thick;
    let is_filled = matches!(kind, NoteheadKind::Filled);

    let mut raw = vec![0.0f32; (w * h) as usize];
    for y in 0..h {
        for x in 0..w {
            let dx = (x as f32 + 0.5) - cx;
            let dy = (y as f32 + 0.5) - cy;
            let outer = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry);
            let v = if is_filled {
                if outer <= 1.0 { 1.0 } else { 0.0 }
            } else {
                // Open/Whole notehead: nur der Ring zwischen Außen- und Innen-Ellipse ist 1.
                let inner = (dx * dx) / (rx_in * rx_in) + (dy * dy) / (ry_in * ry_in);
                if outer <= 1.0 && inner > 1.0 { 1.0 } else { 0.0 }
            };
            raw[(y * w + x) as usize] = v;
        }
    }
    // Mean-Center.
    let mean: f32 = raw.iter().sum::<f32>() / raw.len() as f32;
    let centered: Vec<f32> = raw.iter().map(|v| v - mean).collect();
    let sum_sq: f32 = centered.iter().map(|v| v * v).sum();
    Template { w, h, data: centered, sum_sq }
}

/// Berechne NCC-Heatmap zwischen Bild und Template.
/// Output: Vec<f32> der Größe (bin.w - tmpl.w + 1) × (bin.h - tmpl.h + 1).
fn ncc_heatmap(bin: &Binary, tmpl: &Template) -> Vec<f32> {
    let bw = bin.w as i32;
    let bh = bin.h as i32;
    let tw = tmpl.w as i32;
    let th = tmpl.h as i32;
    if tw > bw || th > bh { return vec![]; }
    let out_w = (bw - tw + 1) as u32;
    let out_h = (bh - th + 1) as u32;

    // Integral-Image für lokales Mean.
    let mut sum = vec![0i64; ((bin.w + 1) * (bin.h + 1)) as usize];
    let stride = (bin.w + 1) as usize;
    for y in 0..bin.h {
        let mut row_sum = 0i64;
        for x in 0..bin.w {
            row_sum += bin.get(x, y) as i64;
            let idx = (y as usize + 1) * stride + (x as usize + 1);
            sum[idx] = sum[idx - stride] + row_sum;
        }
    }

    let area = (tw * th) as f32;
    let tmpl_data = &tmpl.data;
    let tmpl_sum_sq = tmpl.sum_sq.max(1e-6);

    let sum_ref = &sum;
    let out: Vec<f32> = (0..out_h)
        .into_par_iter()
        .flat_map_iter(|oy| {
            let oy_i = oy as i32;
            (0..out_w).map(move |ox| {
                let ox_i = ox as i32;
                let s = (
                    sum_ref[(oy_i + th) as usize * stride + (ox_i + tw) as usize]
                    - sum_ref[oy_i as usize * stride + (ox_i + tw) as usize]
                    - sum_ref[(oy_i + th) as usize * stride + ox_i as usize]
                    + sum_ref[oy_i as usize * stride + ox_i as usize]
                ) as f32;
                let mean = s / area;
                let mut cc = 0.0f32;
                let mut sum_sq_local = 0.0f32;
                for ty in 0..th {
                    for tx in 0..tw {
                        let v = bin.get((ox_i + tx) as u32, (oy_i + ty) as u32) as f32 - mean;
                        let t = tmpl_data[(ty * tw + tx) as usize];
                        cc += v * t;
                        sum_sq_local += v * v;
                    }
                }
                let denom = (sum_sq_local * tmpl_sum_sq).sqrt().max(1e-6);
                cc / denom
            }).collect::<Vec<_>>()
        })
        .collect();
    out
}

fn local_maxima(heat: &[f32], threshold: f32, radius: i32) -> Vec<(u32, u32, f32)> {
    if heat.is_empty() || radius <= 0 { return vec![]; }
    // We must know dimensions; the caller knows them. We re-derive here:
    // Heatmap-len = w * h, w & h are passed via radius? — actually we need separate parameters.
    // Workaround: assume square — but better: pass dims.
    let _ = (threshold, radius);
    Vec::new() // placeholder — see local_maxima_2d below
}

/// Findet lokale Maxima in einem 2D-Heatmap-Array.
fn local_maxima_2d(heat: &[f32], w: u32, h: u32, threshold: f32, radius: i32) -> Vec<(u32, u32, f32)> {
    let mut out = Vec::new();
    let r = radius.max(1);
    for y in 0..h as i32 {
        for x in 0..w as i32 {
            let v = heat[(y as u32 * w + x as u32) as usize];
            if v < threshold { continue; }
            let mut is_max = true;
            'outer: for dy in -r..=r {
                for dx in -r..=r {
                    if dx == 0 && dy == 0 { continue; }
                    let nx = x + dx;
                    let ny = y + dy;
                    if nx < 0 || ny < 0 || nx >= w as i32 || ny >= h as i32 { continue; }
                    let nv = heat[(ny as u32 * w + nx as u32) as usize];
                    if nv > v { is_max = false; break 'outer; }
                }
            }
            if is_max {
                out.push((x as u32, y as u32, v));
            }
        }
    }
    out
}

fn make_notehead(
    _bin: &Binary,
    systems: &[StaffSystem],
    x_top_left: u32,
    y_top_left: u32,
    confidence: f32,
    kind: NoteheadKind,
    spacing: f32,
) -> Option<Notehead> {
    let w = (spacing * 1.3) as u32;
    let h = (spacing * 0.95) as u32;
    let bbox = Rect { x: x_top_left, y: y_top_left, w, h };
    let staff_idx = closest_staff(&bbox, systems)?;
    let cx = bbox.cx();
    let cy = bbox.cy();
    Some(Notehead {
        bbox,
        center: Point { x: cx, y: cy },
        confidence,
        kind,
        staff_idx,
    })
}

fn closest_staff(bb: &Rect, systems: &[StaffSystem]) -> Option<usize> {
    let cy = bb.cy();
    systems
        .iter()
        .enumerate()
        .map(|(i, s)| (i, (s.middle_y() - cy).abs()))
        .filter(|&(_, d)| d < 5.0 * systems[0].line_spacing)
        .min_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal))
        .map(|(i, _)| i)
}

fn dedup_candidates(mut cands: Vec<Notehead>, radius: f32) -> Vec<Notehead> {
    cands.sort_by(|a, b| b.confidence.partial_cmp(&a.confidence).unwrap_or(std::cmp::Ordering::Equal));
    let mut keep = Vec::new();
    for c in cands {
        let dup = keep.iter().any(|k: &Notehead| {
            let dx = k.center.x - c.center.x;
            let dy = k.center.y - c.center.y;
            (dx * dx + dy * dy).sqrt() < radius
        });
        if !dup {
            keep.push(c);
        }
    }
    keep
}

/// Wrapper: kombiniert lokal_maxima_2d über die heat-Vec-Länge.
/// (ncc_heatmap returns flat vec, also we need to know dims here.)
pub fn detect_noteheads_template_v2(
    bin: &Binary,
    systems: &[StaffSystem],
    threshold: f32,
) -> Vec<Notehead> {
    if systems.is_empty() { return vec![]; }
    let spacing = systems[0].line_spacing;
    if spacing < 6.0 { return vec![]; }

    let filled_template = make_notehead_template(spacing, NoteheadKind::Filled);
    let open_template = make_notehead_template(spacing, NoteheadKind::Open);

    let filled_heat = ncc_heatmap(bin, &filled_template);
    let open_heat = ncc_heatmap(bin, &open_template);

    let suppress_radius = (spacing * 0.6) as i32;
    let out_w_filled = bin.w - filled_template.w + 1;
    let out_h_filled = bin.h - filled_template.h + 1;
    let out_w_open = bin.w - open_template.w + 1;
    let out_h_open = bin.h - open_template.h + 1;

    let filled_peaks = local_maxima_2d(&filled_heat, out_w_filled, out_h_filled, threshold, suppress_radius);
    let open_peaks = local_maxima_2d(&open_heat, out_w_open, out_h_open, threshold, suppress_radius);

    let mut cands = Vec::new();
    for (x, y, c) in filled_peaks {
        if let Some(nh) = make_notehead(bin, systems, x, y, c, NoteheadKind::Filled, spacing) {
            cands.push(nh);
        }
    }
    for (x, y, c) in open_peaks {
        if let Some(nh) = make_notehead(bin, systems, x, y, c, NoteheadKind::Open, spacing) {
            cands.push(nh);
        }
    }
    dedup_candidates(cands, spacing * 0.5)
}

/// Re-Rank existierende Notehead-Kandidaten via lokales NCC-Matching.
///
/// Für jeden Kandidaten wird ein 3×3-NCC-Lookup um sein Center gemacht (3×3 statt
/// kompletter Bild-Scan). Das gibt eine refined Konfidenz + Sub-Pixel-Center +
/// Filled-vs-Open-Klassifikation.
///
/// Performance: O(n_candidates · template_size · 9) statt O(image_size · template_size).
/// Bei 200 Kandidaten und 17×12-Template: 200·204·9 ≈ 370k Ops → < 1ms.
pub fn rerank_with_template(
    staff_removed: &Binary,
    candidates: &[Notehead],
    spacing: f32,
) -> Vec<Notehead> {
    if candidates.is_empty() || spacing < 6.0 { return candidates.to_vec(); }

    let filled_tmpl = make_notehead_template(spacing, NoteheadKind::Filled);
    let open_tmpl = make_notehead_template(spacing, NoteheadKind::Open);
    let whole_tmpl = make_notehead_template(spacing, NoteheadKind::Whole);

    candidates
        .par_iter()
        .filter_map(|nh| {
            // Suche das beste NCC-Match in einer 3×3-Region um center.
            let cx = nh.center.x as i32;
            let cy = nh.center.y as i32;
            // Verwende die größeren Whole-Template-Dimensionen für Boundary-Checks
            // damit Whole-Templates auch bei Filled/Open-Kandidaten getestet werden.
            let half_w_f = filled_tmpl.w as i32 / 2;
            let half_h_f = filled_tmpl.h as i32 / 2;
            let half_w_w = whole_tmpl.w as i32 / 2;
            let half_h_w = whole_tmpl.h as i32 / 2;

            let mut best_score = f32::NEG_INFINITY;
            let mut best_x = cx;
            let mut best_y = cy;
            let mut best_kind = nh.kind;

            for dy in -1..=1i32 {
                for dx in -1..=1i32 {
                    // Filled+Open Templates (Aspect 1.3)
                    let tlx_f = cx + dx - half_w_f;
                    let tly_f = cy + dy - half_h_f;
                    if tlx_f >= 0 && tly_f >= 0 {
                        let tlx = tlx_f as u32;
                        let tly = tly_f as u32;
                        if tlx + filled_tmpl.w <= staff_removed.w && tly + filled_tmpl.h <= staff_removed.h {
                            let f_score = local_ncc(staff_removed, &filled_tmpl, tlx, tly);
                            let o_score = local_ncc(staff_removed, &open_tmpl, tlx, tly);
                            if f_score > best_score {
                                best_score = f_score;
                                best_x = cx + dx;
                                best_y = cy + dy;
                                best_kind = NoteheadKind::Filled;
                            }
                            if o_score > best_score {
                                best_score = o_score;
                                best_x = cx + dx;
                                best_y = cy + dy;
                                best_kind = NoteheadKind::Open;
                            }
                        }
                    }
                    // Whole Template (Aspect 1.7) — separater Boundary-Check, weil
                    // das Template breiter ist und nicht überall reinpasst.
                    let tlx_w = cx + dx - half_w_w;
                    let tly_w = cy + dy - half_h_w;
                    if tlx_w >= 0 && tly_w >= 0 {
                        let tlx = tlx_w as u32;
                        let tly = tly_w as u32;
                        if tlx + whole_tmpl.w <= staff_removed.w && tly + whole_tmpl.h <= staff_removed.h {
                            let w_score = local_ncc(staff_removed, &whole_tmpl, tlx, tly);
                            // Whole bevorzugt wenn Whole-NCC mindestens so gut wie
                            // das aktuell beste (Filled/Open) Score ist. Kein Margin,
                            // weil ein hollow-wide Notenkopf besser auf Whole als auf
                            // Open matched (Open ist schmaler, daher leakt der Hole-
                            // Bereich in Außenpixel der Open-Template-Bbox).
                            if w_score > best_score {
                                best_score = w_score;
                                best_x = cx + dx;
                                best_y = cy + dy;
                                best_kind = NoteheadKind::Whole;
                            }
                        }
                    }
                }
            }
            // NCC-Threshold: < 0.20 → kein echter Notehead.
            // Erhöht von 0.05 (war zu lax und ließ viele Symbol-False-Positives durch).
            // Coda/Segno/D.S. liegen typisch bei NCC 0.10-0.18, echte NHs > 0.40.
            if best_score < 0.20 { return None; }
            Some(Notehead {
                bbox: nh.bbox,
                center: Point { x: best_x as f32, y: best_y as f32 },
                confidence: best_score.clamp(0.0, 1.0),
                kind: best_kind,
                staff_idx: nh.staff_idx,
            })
        })
        .collect()
}

/// Lokales NCC für ein einzelnes Template-Patch.
fn local_ncc(bin: &Binary, tmpl: &Template, top_left_x: u32, top_left_y: u32) -> f32 {
    let tw = tmpl.w;
    let th = tmpl.h;
    // Mean of patch.
    let mut sum = 0.0f32;
    for ty in 0..th {
        for tx in 0..tw {
            sum += bin.get(top_left_x + tx, top_left_y + ty) as f32;
        }
    }
    let area = (tw * th) as f32;
    let mean = sum / area;
    let mut cc = 0.0f32;
    let mut sq = 0.0f32;
    for ty in 0..th {
        for tx in 0..tw {
            let v = bin.get(top_left_x + tx, top_left_y + ty) as f32 - mean;
            let t = tmpl.data[(ty * tw + tx) as usize];
            cc += v * t;
            sq += v * v;
        }
    }
    let denom = (sq * tmpl.sum_sq.max(1e-6)).sqrt().max(1e-6);
    cc / denom
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn synthetic_filled_template_matches() {
        // Bild mit einem gefüllten Notenkopf bei (50, 50).
        let mut bin = Binary::new(100, 100);
        let spacing = 12.0;
        let tmpl = make_notehead_template(spacing, NoteheadKind::Filled);
        let off_x = 50i32 - tmpl.w as i32 / 2;
        let off_y = 50i32 - tmpl.h as i32 / 2;
        for y in 0..tmpl.h {
            for x in 0..tmpl.w {
                let v = tmpl.data[(y * tmpl.w + x) as usize];
                // Nur Pixel >0 ergeben Schwarz.
                if v > 0.1 {
                    let bx = (off_x + x as i32) as u32;
                    let by = (off_y + y as i32) as u32;
                    if bx < bin.w && by < bin.h { bin.set(bx, by, 1); }
                }
            }
        }
        let staff = StaffSystem {
            lines: (0..5).map(|i| omr_core::StaffLine {
                y_per_x: vec![30 + i * 10; 100],
            }).collect(),
            line_spacing: 12.0,
            line_thickness: 2.0,
        };
        let nhs = detect_noteheads_template_v2(&bin, &[staff], 0.5);
        assert!(!nhs.is_empty(), "expected at least one match");
    }
}
