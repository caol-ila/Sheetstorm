// Symbol-Detection-Pipeline:
//   1. Connected Components → SymbolCandidate
//   2. Aspect-/Größen-Filter: Standard-Noteheads (rundlich) + Notehead+Stem-Kombinationen
//      (tall-narrow CCs, häufig nach Staff-Removal).
//   3. Bei tall-narrow-CCs: finde die "klobige" Y-Region innerhalb des CC
//      über horizontale Pixel-Density → das ist der eigentliche Notehead.
//   4. Notehead-Klassifikation: Filled vs. Open vs. Whole anhand
//      Fläche/Aspect-Ratio + Innen-Pixel-Verhältnis.

use omr_core::{Binary, Notehead, NoteheadKind, Point, Rect, ScoreNote, StaffSystem, Stem};
use tracing::debug;

pub mod bars;
pub mod beams;
pub mod cc;
pub mod meta;
pub mod pitch;
pub mod plausibility;
pub mod stems;
pub mod template;
pub use bars::{detect_measure_bars, MeasureBar};
pub use beams::{detect_beams, beams_per_stem, Beam};
pub use cc::{connected_components, ConnectedComponent};
pub use meta::{detect_clef, detect_key_signature};
pub use plausibility::{check_measure, repair_measure, validate_and_repair_part, MeasureCheck, MeasurePlausibility};
pub use template::{detect_noteheads_template_v2, rerank_with_template};

/// Hauptfunktion: detektiere Noteheads in einem staff-line-removed Binary.
/// `bin_original` wird genutzt um den Schlüssel/Vorzeichen-Bereich zu finden,
/// in dem keine Noteheads zugelassen werden.
pub fn detect_noteheads(staff_removed: &Binary, systems: &[StaffSystem]) -> Vec<Notehead> {
    detect_noteheads_with_skip(staff_removed, systems, &[])
}

/// Wie [`detect_noteheads`], aber mit explicit "verbotenen" X-Range pro System
/// (z.B. der Schlüssel/Key/Time-Bereich).
pub fn detect_noteheads_with_skip(
    staff_removed: &Binary,
    systems: &[StaffSystem],
    skip_x_per_system: &[std::ops::Range<u32>],
) -> Vec<Notehead> {
    if systems.is_empty() {
        return vec![];
    }
    let spacing = systems[0].line_spacing;
    if spacing < 4.0 {
        return vec![];
    }

    let expected_w = (spacing * 1.2).round() as u32;
    let expected_h = spacing.round() as u32;
    let min_w = (expected_w as f32 * 0.4).round() as u32;
    let max_w = (expected_w as f32 * 2.5).round() as u32;
    let min_h_simple = (expected_h as f32 * 0.4).round() as u32;
    let max_h_simple = (expected_h as f32 * 2.0).round() as u32;
    let max_h_tall = (spacing * 5.0).round() as u32;

    let ccs = connected_components(staff_removed);
    debug!(n = ccs.len(), "connected components");

    let mut noteheads = Vec::new();
    for cc in &ccs {
        let bb = cc.bbox;
        if bb.w < min_w || bb.w > max_w { continue; }
        if bb.h < min_h_simple || bb.h > max_h_tall { continue; }
        let aspect = bb.aspect();

        if bb.h <= max_h_simple && (0.5..=3.0).contains(&aspect) {
            if let Some(nh) = classify_simple_notehead(staff_removed, &bb, spacing, systems) {
                if is_in_skip_region(&nh, skip_x_per_system) { continue; }
                noteheads.push(nh);
            }
            continue;
        }

        // Schritt 3: Tall/wide CC kann mehrere Noteheads enthalten (Beam-Gruppen!).
        // Wir scannen pro X-Spalte das CC und finden überall wo die NH-Region
        // liegt mehrere Maxima.
        let extracted = extract_noteheads_from_complex(staff_removed, &bb, spacing, systems);
        for nh in extracted {
            if is_in_skip_region(&nh, skip_x_per_system) { continue; }
            noteheads.push(nh);
        }
    }
    debug!(kept = noteheads.len(), "noteheads after filter");
    noteheads
}

/// Aus komplexem CC (Notehead+Stem oder Notehead+Beam-Group) alle enthaltenen
/// Notenköpfe extrahieren via Sliding-Window auf Spalten-Densität.
fn extract_noteheads_from_complex(
    bin: &Binary,
    bb: &Rect,
    spacing: f32,
    systems: &[StaffSystem],
) -> Vec<Notehead> {
    // Wenn das CC schmaler als 2*spacing ist, ist es definitiv NUR ein Notehead+Stem.
    let nh_w = (spacing * 1.3).round() as u32;
    if bb.w < (spacing * 2.0) as u32 {
        if let Some(nh) = extract_single_notehead_from_tall(bin, bb, spacing, systems) {
            return vec![nh];
        }
        return vec![];
    }

    // Wide CC = Beam-Gruppe. Scanne X-Spalten in Schritten von spacing*0.6
    // und extrahiere an jeder X-Position eine potentielle Notehead-Region.
    let mut noteheads = Vec::new();
    let step = (spacing * 0.6).max(2.0) as u32;
    let mut x = bb.x;
    let nh_h = spacing.round() as u32;
    while x + nh_w <= bb.x + bb.w {
        // Pro X-Range: finde die Y-Region mit max Density.
        let sub_bb = Rect { x, y: bb.y, w: nh_w, h: bb.h };
        let row_density = local_row_density(bin, &sub_bb);
        if row_density.is_empty() { x += step; continue; }
        let win = (nh_h as usize).min(row_density.len());
        if win == 0 { x += step; continue; }

        let mut window_sum: u32 = row_density[..win].iter().sum();
        let mut best_sum = window_sum;
        let mut best_start: usize = 0;
        for i in win..row_density.len() {
            window_sum += row_density[i];
            window_sum -= row_density[i - win];
            if window_sum > best_sum {
                best_sum = window_sum;
                best_start = i + 1 - win;
            }
        }

        // Mindest-Densität: 0.55 * Notehead-Volumen.
        let avg_density = best_sum as f32 / win as f32;
        if avg_density < spacing * 0.55 {
            x += step;
            continue;
        }

        // Beam-Region (sehr dicht über die ganze Region) ausschließen:
        // Notenköpfe haben Density-Variation, Beams haben gleichmäßige Density.
        let beam_threshold = spacing * 0.85;
        let beamlike = row_density.iter().filter(|&&d| (d as f32) > beam_threshold).count();
        if beamlike > 4 && (avg_density / spacing) > 0.85 {
            // Wahrscheinlich nur Beam, kein Notenkopf.
            x += step;
            continue;
        }

        let nh_y = bb.y + best_start as u32;
        let nh_bbox = Rect { x, y: nh_y, w: nh_w, h: nh_h };
        let staff_idx = match closest_staff(&nh_bbox, systems) {
            Some(s) => s,
            None => { x += step; continue; }
        };
        let pixel_count = count_pixels_in_rect(bin, &nh_bbox);
        let fill_ratio = pixel_count as f32 / nh_bbox.area().max(1) as f32;
        let kind = if fill_ratio > 0.55 {
            NoteheadKind::Filled
        } else if nh_bbox.w as f32 > spacing * 1.6 {
            NoteheadKind::Whole
        } else {
            NoteheadKind::Open
        };
        let (cx, cy) = subpixel_center(bin, &nh_bbox);
        // Dedup: nicht zu nah am vorherigen.
        let too_close = noteheads.iter().any(|prev: &Notehead| {
            (prev.center.x - cx).abs() < spacing * 0.8
                && (prev.center.y - cy).abs() < spacing * 0.5
        });
        if !too_close {
            noteheads.push(Notehead {
                bbox: nh_bbox,
                center: Point { x: cx, y: cy },
                confidence: confidence_score(fill_ratio, nh_bbox.aspect(), kind) * 0.85,
                kind,
                staff_idx,
            });
        }
        x += step;
    }
    noteheads
}

fn extract_single_notehead_from_tall(
    bin: &Binary,
    bb: &Rect,
    spacing: f32,
    systems: &[StaffSystem],
) -> Option<Notehead> {
    extract_notehead_from_tall(bin, bb, spacing, systems)
}

fn is_in_skip_region(nh: &Notehead, skip_x_per_system: &[std::ops::Range<u32>]) -> bool {
    if let Some(range) = skip_x_per_system.get(nh.staff_idx) {
        let x = nh.center.x as u32;
        x >= range.start && x < range.end
    } else { false }
}

fn classify_simple_notehead(
    bin: &Binary,
    bb: &Rect,
    spacing: f32,
    systems: &[StaffSystem],
) -> Option<Notehead> {
    let staff_idx = closest_staff(bb, systems)?;
    let pixel_count = count_pixels_in_rect(bin, bb);
    let fill_ratio = pixel_count as f32 / bb.area().max(1) as f32;
    let kind = if fill_ratio > 0.65 {
        NoteheadKind::Filled
    } else if bb.w as f32 > spacing * 1.6 {
        NoteheadKind::Whole
    } else {
        NoteheadKind::Open
    };
    let (cx, cy) = subpixel_center(bin, bb);
    Some(Notehead {
        bbox: *bb,
        center: Point { x: cx, y: cy },
        confidence: confidence_score(fill_ratio, bb.aspect(), kind),
        kind,
        staff_idx,
    })
}

/// Aus einem tall-narrow-CC (Notehead+Stem oder Notehead+Stem+Beam) den
/// eigentlichen Notenkopf-Bereich extrahieren.
fn extract_notehead_from_tall(
    bin: &Binary,
    bb: &Rect,
    spacing: f32,
    systems: &[StaffSystem],
) -> Option<Notehead> {
    // Berechne horizontale Pixel-Density pro Zeile (innerhalb der bbox).
    let row_density = local_row_density(bin, bb);
    if row_density.is_empty() { return None; }

    // Notenkopf-Region = Sliding-Window von ca. spacing Zeilen mit max Σ row_density.
    let nh_h = spacing.round() as u32;
    let nh_h = nh_h.clamp(4, bb.h);
    let win = nh_h as usize;

    // Sliding-Window-Sum.
    let mut window_sum: u32 = row_density[..win.min(row_density.len())].iter().sum();
    let mut best_sum = window_sum;
    let mut best_start: usize = 0;
    for i in win..row_density.len() {
        window_sum += row_density[i];
        window_sum -= row_density[i - win];
        if window_sum > best_sum {
            best_sum = window_sum;
            best_start = i + 1 - win;
        }
    }

    // Mindest-Density um Stem-only-Region auszuschließen (Stem hat ~1-3 px/zeile,
    // Notehead-Zeile hat ~spacing px/zeile).
    let avg_density = best_sum as f32 / win as f32;
    if avg_density < spacing * 0.4 { return None; }

    let nh_y = bb.y + best_start as u32;
    let nh_bbox = Rect {
        x: bb.x,
        y: nh_y,
        w: bb.w,
        h: nh_h,
    };

    let staff_idx = closest_staff(&nh_bbox, systems)?;
    let pixel_count = count_pixels_in_rect(bin, &nh_bbox);
    let fill_ratio = pixel_count as f32 / nh_bbox.area().max(1) as f32;
    let kind = if fill_ratio > 0.55 {
        NoteheadKind::Filled
    } else if nh_bbox.w as f32 > spacing * 1.6 {
        NoteheadKind::Whole
    } else {
        NoteheadKind::Open
    };
    let (cx, cy) = subpixel_center(bin, &nh_bbox);
    Some(Notehead {
        bbox: nh_bbox,
        center: Point { x: cx, y: cy },
        confidence: confidence_score(fill_ratio, nh_bbox.aspect(), kind) * 0.9,
        kind,
        staff_idx,
    })
}

/// Implied-Stem-Detection für eine Notehead die aus einem tall-narrow-CC kommt.
/// Returns den Stem WENN das CC oberhalb oder unterhalb der NH-Region noch
/// ein langes schmales Run-Gebiet hat (d.h. Notehead+Stem zusammen waren
/// ein einziges CC).
///
/// Algorithmus: Für jede X-Spalte im NH-Bbox + 2px-Margin, miss wie weit
/// der vertikale schwarze Run nach oben/unten reicht (auch über Lücken bis
/// 1px tolerant). Wähle die Spalte mit der LÄNGSTEN Extension; wenn das ≥
/// 1.3*spacing ist (Stem-Mindestlänge), gilt es als Stem.
pub fn implied_stem_for_tall_notehead(
    bin: &Binary,
    nh: &Notehead,
    spacing: f32,
) -> Option<Stem> {
    let bb = nh.bbox;
    // Für reale Scans: nicht nur direkt-angrenzend prüfen, sondern bis 4px
    // Lücke tolerieren (verschmierter Druck/JPEG-Artefakt bricht Stem).
    let bx0 = bb.x.saturating_sub(3);
    let bx1 = (bb.x + bb.w + 3).min(bin.w);
    let min_stem = (spacing * 1.3) as i32;
    let mut best: Option<Stem> = None;

    for x in bx0..bx1 {
        // Walk UP from bb.y mit Lücken-Toleranz
        let mut top = bb.y;
        let mut gap = 0u32;
        while top > 0 {
            if bin.get(x, top - 1) == 1 {
                top -= 1;
                gap = 0;
            } else if gap < 1 {
                top = top.saturating_sub(1);
                gap += 1;
            } else {
                break;
            }
        }
        let above = bb.y as i32 - top as i32;

        // Walk DOWN from bb.y+bb.h-1 mit Lücken-Toleranz
        let bottom_start = bb.y + bb.h.saturating_sub(1);
        let mut bot = bottom_start;
        gap = 0;
        while bot + 1 < bin.h {
            if bin.get(x, bot + 1) == 1 {
                bot += 1;
                gap = 0;
            } else if gap < 1 {
                bot += 1;
                gap += 1;
            } else {
                break;
            }
        }
        let below = bot as i32 - bottom_start as i32;

        if above >= min_stem || below >= min_stem {
            let candidate = Stem {
                x,
                y_top: top,
                y_bot: bot,
                notehead_idx: None,
            };
            best = match best {
                Some(s) if (s.y_bot - s.y_top) >= (bot - top) => Some(s),
                _ => Some(candidate),
            };
        }
    }
    best
}

fn local_row_density(bin: &Binary, bb: &Rect) -> Vec<u32> {
    let mut out = Vec::with_capacity(bb.h as usize);
    for y in bb.y..(bb.y + bb.h) {
        let mut s = 0u32;
        for x in bb.x..(bb.x + bb.w) {
            s += bin.get(x, y) as u32;
        }
        out.push(s);
    }
    out
}

fn count_pixels_in_rect(bin: &Binary, bb: &Rect) -> u32 {
    let mut s = 0u32;
    for y in bb.y..(bb.y + bb.h) {
        for x in bb.x..(bb.x + bb.w) {
            s += bin.get(x, y) as u32;
        }
    }
    s
}

fn closest_staff(bb: &Rect, systems: &[StaffSystem]) -> Option<usize> {
    let cy = bb.cy();
    // 3.5*spacing ≈ Stafflinien-Höhe (2 spacings) + 2 Hilfslinien-Spacings + Margin.
    // Damit werden Title/Copyright-Text die typisch 5+ spacings über der Stafflinie
    // liegen herausgefiltert.
    systems
        .iter()
        .enumerate()
        .map(|(i, s)| (i, (s.middle_y() - cy).abs()))
        .filter(|&(_, d)| d < 3.5 * systems[0].line_spacing)
        .min_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal))
        .map(|(i, _)| i)
}

fn subpixel_center(bin: &Binary, bb: &Rect) -> (f32, f32) {
    let mut sx = 0.0f64;
    let mut sy = 0.0f64;
    let mut n = 0u64;
    for y in bb.y..(bb.y + bb.h) {
        for x in bb.x..(bb.x + bb.w) {
            if bin.get(x, y) == 1 {
                sx += x as f64;
                sy += y as f64;
                n += 1;
            }
        }
    }
    if n == 0 {
        (bb.cx(), bb.cy())
    } else {
        (sx as f32 / n as f32 + 0.5, sy as f32 / n as f32 + 0.5)
    }
}

fn confidence_score(fill_ratio: f32, aspect: f32, kind: NoteheadKind) -> f32 {
    let (target_a, target_f) = match kind {
        NoteheadKind::Filled => (1.3, 0.85),
        NoteheadKind::Open => (1.2, 0.40),
        NoteheadKind::Whole => (1.6, 0.45),
    };
    let aspect_score = (1.0 - (aspect - target_a).abs() / 0.5).max(0.0);
    let fill_score = (1.0 - (fill_ratio - target_f).abs() / 0.3).max(0.0);
    (aspect_score * fill_score).clamp(0.0, 1.0)
}

/// Konvertiere Noteheads + Stems + Beams → ScoreNotes mit Pitch + Duration.
pub fn noteheads_to_notes(
    noteheads: &[Notehead],
    systems: &[StaffSystem],
    stems: &[Stem],
    beam_counts: &[u32],
    clef: omr_core::Clef,
    key: omr_core::KeySignature,
) -> Vec<ScoreNote> {
    let mut notes = Vec::with_capacity(noteheads.len());
    for (idx, nh) in noteheads.iter().enumerate() {
        let staff = match systems.get(nh.staff_idx) {
            Some(s) => s,
            None => continue,
        };
        let pitch = pitch::pitch_from_xy(nh.center.x, nh.center.y, staff, clef, key);
        // Stem für diesen Notehead?
        let stem_idx = stems.iter().position(|s| s.notehead_idx == Some(idx));
        let has_stem = stem_idx.is_some();
        let n_beams = stem_idx.and_then(|i| beam_counts.get(i)).copied().unwrap_or(0);

        // Duration in divisions (divisions=4 → quarter = 4).
        let duration = match (nh.kind, has_stem, n_beams) {
            (NoteheadKind::Whole, _, _) => 16,                  // ganze
            (NoteheadKind::Open, true, _) => 8,                 // halbe
            (NoteheadKind::Open, false, _) => 16,
            (NoteheadKind::Filled, true, 0) => 4,               // viertel
            (NoteheadKind::Filled, true, 1) => 2,               // achtel
            (NoteheadKind::Filled, true, 2) => 1,               // 16th
            (NoteheadKind::Filled, true, _) => 1,               // 32nd → cap auf 16th
            (NoteheadKind::Filled, false, _) => 4,
        };
        notes.push(ScoreNote {
            midi: pitch.midi,
            step: pitch.step,
            alter: pitch.alter,
            octave: pitch.octave,
            duration,
            onset: 0,
            voice: 1,
            kind: nh.kind,
            center: nh.center,
        });
    }
    notes
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_filled_notehead() {
        let mut bin = Binary::new(160, 160);
        for y in 60..72 {
            for x in 60..74 {
                bin.set(x, y, 1);
            }
        }
        let staff = StaffSystem {
            lines: (0..5).map(|i| omr_core::StaffLine {
                y_per_x: vec![40 + i * 12; 160],
            }).collect(),
            line_spacing: 12.0,
            line_thickness: 2.0,
        };
        let nhs = detect_noteheads(&bin, &[staff]);
        assert!(!nhs.is_empty(), "expected at least one notehead");
        assert!(matches!(nhs[0].kind, NoteheadKind::Filled));
    }

    #[test]
    fn detects_notehead_with_stem() {
        // Notehead 14×12 unten + Stem 2×40 nach oben verbunden = ein langes CC.
        let mut bin = Binary::new(80, 200);
        for y in 80..92 {
            for x in 30..44 {
                bin.set(x, y, 1);
            }
        }
        // Stem 2px breit nach oben
        for y in 40..80 {
            for x in 36..38 {
                bin.set(x, y, 1);
            }
        }
        let staff = StaffSystem {
            lines: (0..5).map(|i| omr_core::StaffLine {
                y_per_x: vec![60 + i * 12; 80],
            }).collect(),
            line_spacing: 12.0,
            line_thickness: 2.0,
        };
        let nhs = detect_noteheads(&bin, &[staff]);
        assert!(!nhs.is_empty(), "expected notehead extracted from tall CC");
        // Notehead-bbox sollte um y≈85 zentriert sein (Bottom of CC).
        let center_y = nhs[0].center.y;
        assert!((center_y - 86.0).abs() < 4.0, "center.y expected ~86, got {}", center_y);
    }
}
