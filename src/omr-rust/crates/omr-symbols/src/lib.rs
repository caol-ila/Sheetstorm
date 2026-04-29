// Symbol-Detection-Pipeline:
//   1. Connected Components → SymbolCandidate
//   2. Aspect-/Größen-Filter (entfernt Punkte, Mini-Restartefakte)
//   3. Notehead-Klassifikation: Filled vs. Open vs. Whole anhand
//      Fläche/Aspect-Ratio + Innen-Pixel-Verhältnis.
//   4. Zuordnung zu Staffsystem über Y-Range.

use omr_core::{
    Binary, Notehead, NoteheadKind, Point, Rect, ScoreNote, StaffSystem, Stem,
};
use tracing::debug;

pub mod cc;
pub mod pitch;
pub mod stems;
pub use cc::{connected_components, ConnectedComponent};

/// Hauptfunktion: detektiere Noteheads in einem staffline-removed Binary
/// (also Bild mit Symbolen aber ohne Linien).
pub fn detect_noteheads(staff_removed: &Binary, systems: &[StaffSystem]) -> Vec<Notehead> {
    if systems.is_empty() {
        return vec![];
    }
    let spacing = systems[0].line_spacing;
    if spacing < 4.0 {
        return vec![];
    }

    // Erwartete Notenkopf-Größe: ~1.2 * spacing breit, ~1.0 * spacing hoch.
    let expected_w = (spacing * 1.2).round() as u32;
    let expected_h = spacing.round() as u32;
    // Lockere Filter — wir filtern danach nochmal über Aspect/Fill.
    let min_w = (expected_w as f32 * 0.4) as u32;
    let max_w = (expected_w as f32 * 2.5) as u32;
    let min_h = (expected_h as f32 * 0.4) as u32;
    let max_h = (expected_h as f32 * 2.5) as u32;

    let ccs = connected_components(staff_removed);
    debug!(n = ccs.len(), "connected components");

    let mut noteheads = Vec::new();
    for cc in &ccs {
        let bb = cc.bbox;
        if bb.w < min_w || bb.w > max_w || bb.h < min_h || bb.h > max_h {
            continue;
        }
        let aspect = bb.aspect();
        if !(0.5..=3.0).contains(&aspect) {
            continue;
        }

        // Welcher StaffSystem passt?
        let staff_idx = match closest_staff(&bb, systems) {
            Some(s) => s,
            None => continue,
        };

        // Fülle ermitteln: Anteil schwarz innerhalb des CC-BBox.
        let fill_ratio = cc.pixel_count as f32 / bb.area().max(1) as f32;

        let kind = if fill_ratio > 0.65 {
            NoteheadKind::Filled
        } else if bb.w as f32 > spacing * 1.6 {
            NoteheadKind::Whole
        } else {
            NoteheadKind::Open
        };

        // Sub-pixel center: gewichteter Schwerpunkt.
        let (cx, cy) = subpixel_center(staff_removed, &bb);

        noteheads.push(Notehead {
            bbox: bb,
            center: Point { x: cx, y: cy },
            confidence: confidence_score(fill_ratio, aspect, kind),
            kind,
            staff_idx,
        });
    }
    debug!(kept = noteheads.len(), "noteheads after filter");
    noteheads
}

fn closest_staff(bb: &Rect, systems: &[StaffSystem]) -> Option<usize> {
    let cy = bb.cy();
    systems
        .iter()
        .enumerate()
        .map(|(i, s)| (i, (s.middle_y() - cy).abs()))
        .filter(|&(_, d)| d < 4.0 * systems[0].line_spacing)
        .min_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal))
        .map(|(i, _)| i)
}

/// Sub-Pixel-genauer Schwerpunkt eines CC-BBox-Bereichs.
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
    // Filled: erwartet Aspect ~1.3, Fill ~0.85.
    // Open:   erwartet Aspect ~1.2, Fill ~0.4.
    let (target_a, target_f) = match kind {
        NoteheadKind::Filled => (1.3, 0.85),
        NoteheadKind::Open => (1.2, 0.40),
        NoteheadKind::Whole => (1.6, 0.45),
    };
    let aspect_score = (1.0 - (aspect - target_a).abs() / 0.5).max(0.0);
    let fill_score = (1.0 - (fill_ratio - target_f).abs() / 0.3).max(0.0);
    (aspect_score * fill_score).clamp(0.0, 1.0)
}

/// Konvertiere Noteheads zu ScoreNotes (Pitch + Default-Duration).
pub fn noteheads_to_notes(
    noteheads: &[Notehead],
    systems: &[StaffSystem],
    stems: &[Stem],
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
        // Duration aus Notenkopf-Typ + Stem
        let has_stem = stems.iter().any(|s| s.notehead_idx == Some(idx));
        let duration = match (nh.kind, has_stem) {
            (NoteheadKind::Whole, _) => 16, // Ganze (4 quarters * 4 divisions = 16)
            (NoteheadKind::Open, true) => 8, // Halbe
            (NoteheadKind::Open, false) => 16, // ohne Stem als Whole behandeln
            (NoteheadKind::Filled, true) => 4, // Viertel
            (NoteheadKind::Filled, false) => 4, // ohne Stem trotzdem Viertel
        };
        notes.push(ScoreNote {
            midi: pitch.midi,
            step: pitch.step,
            alter: pitch.alter,
            octave: pitch.octave,
            duration,
            onset: 0, // wird im pipeline-layer korrigiert
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
        // Dummy Notenkopf 14×12 px gefüllt — passt zu spacing=12 (expected_w ≈ 14).
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
}
