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

pub mod beams;
pub mod cc;
pub mod meta;
pub mod pitch;
pub mod stems;
pub use beams::{detect_beams, beams_per_stem, Beam};
pub use cc::{connected_components, ConnectedComponent};
pub use meta::{detect_clef, detect_key_signature};

/// Hauptfunktion: detektiere Noteheads in einem staff-line-removed Binary.
pub fn detect_noteheads(staff_removed: &Binary, systems: &[StaffSystem]) -> Vec<Notehead> {
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
    // Notehead+Stem zusammen kann bis 5x spacing hoch sein.
    let max_h_tall = (spacing * 5.0).round() as u32;

    let ccs = connected_components(staff_removed);
    debug!(n = ccs.len(), "connected components");

    let mut noteheads = Vec::new();
    for cc in &ccs {
        let bb = cc.bbox;
        // Schritt 1: Filter — entferne Mini- und absurd große CCs.
        if bb.w < min_w || bb.w > max_w { continue; }
        if bb.h < min_h_simple || bb.h > max_h_tall { continue; }
        let aspect = bb.aspect();

        // Schritt 2: Wenn das CC "klein und rund" ist (klassischer Notehead),
        // direkt klassifizieren.
        if bb.h <= max_h_simple && (0.5..=3.0).contains(&aspect) {
            if let Some(nh) = classify_simple_notehead(staff_removed, &bb, spacing, systems) {
                noteheads.push(nh);
            }
            continue;
        }

        // Schritt 3: Tall-narrow CC = Notehead + Stem zusammen.
        // Finde die Y-Region mit max horizontaler Density innerhalb des CC.
        if let Some(nh) = extract_notehead_from_tall(staff_removed, &bb, spacing, systems) {
            noteheads.push(nh);
        }
    }
    debug!(kept = noteheads.len(), "noteheads after filter");
    noteheads
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
    systems
        .iter()
        .enumerate()
        .map(|(i, s)| (i, (s.middle_y() - cy).abs()))
        .filter(|&(_, d)| d < 5.0 * systems[0].line_spacing)
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
        let pitch = pitch::pitch_from_y(nh.center.y, staff, clef, key);
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
