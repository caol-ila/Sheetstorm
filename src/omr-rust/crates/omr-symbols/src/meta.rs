// Clef- und Key-Signature-Detection.
//
// Strategie:
//   - Am Anfang jedes Systems (linke Bildränder, x ∈ [first_line_x, +5*spacing])
//     suche das größte CC mit Bounding-Box passend zu G-/F-/C-Schlüssel.
//   - Klassifiziere via Höhen- und Y-Position-Heuristik (G-Schlüssel ist
//     typisch 4*spacing hoch, F-Schlüssel kompakter).
//   - Key-Signature: zähle # / b nach dem Schlüssel im Bereich der nächsten
//     ~10*spacing.

use omr_core::{Binary, Clef, KeySignature, StaffSystem};

use crate::cc::connected_components;

/// Erkenne den Schlüssel am Anfang eines Systems.
pub fn detect_clef(bin: &Binary, system: &StaffSystem) -> Clef {
    if system.lines.is_empty() {
        return Clef::Treble;
    }
    let top_y = system.lines.first().unwrap().mean_y() as i32;
    let bot_y = system.lines.last().unwrap().mean_y() as i32;
    let spacing = system.line_spacing;
    let staff_h = (bot_y - top_y) as f32;

    // Schlüsselbereich: ersten 4*spacing nach dem Staff-Beginn.
    let x0 = first_x_with_pixel(bin, top_y, bot_y).unwrap_or(0);
    let x1 = (x0 + (spacing * 5.0) as u32).min(bin.w);
    let y0 = (top_y - (spacing * 2.0) as i32).max(0) as u32;
    let y1 = ((bot_y + (spacing * 2.0) as i32).max(0) as u32).min(bin.h);

    // CCs in diesem Region.
    let mut max_cc: Option<(i32, i32, i32, i32)> = None; // (x0, y0, x1, y1)
    let ccs = connected_components_region(bin, x0, y0, x1, y1);
    for (cx0, cy0, cx1, cy1) in ccs {
        let h = cy1 - cy0;
        if (h as f32) < staff_h * 0.6 { continue; }
        let prev_h = max_cc.map(|(_, sy0, _, sy1)| sy1 - sy0).unwrap_or(0);
        if h > prev_h {
            max_cc = Some((cx0, cy0, cx1, cy1));
        }
    }

    if let Some((_cx0, cy0, _cx1, cy1)) = max_cc {
        let cc_h = (cy1 - cy0) as f32;
        let cc_top = cy0 as f32;
        let cc_bot = cy1 as f32;

        // Heuristik:
        //  - G-Schlüssel: cc_h ≥ 1.4 * staff_h, ragt deutlich oben + unten raus
        //  - F-Schlüssel: cc_h ≈ 0.7-1.1 * staff_h, schwerpunkt im oberen Drittel
        //  - C-Schlüssel: cc_h ≈ staff_h, zentriert
        if cc_h >= staff_h * 1.4 {
            return Clef::Treble;
        }
        // Schwerpunkt-relative Position.
        let cc_mid = (cc_top + cc_bot) * 0.5;
        let staff_mid = (top_y + bot_y) as f32 * 0.5;
        if cc_mid < staff_mid - spacing * 0.5 {
            return Clef::Bass;
        }
        return Clef::Alto;
    }
    Clef::Treble
}

/// Zähle Vorzeichen (# oder b) nach dem Schlüssel.
/// Gibt KeySignature mit fifths zwischen -7..+7.
pub fn detect_key_signature(bin: &Binary, system: &StaffSystem) -> KeySignature {
    if system.lines.is_empty() {
        return KeySignature::default();
    }
    let top_y = system.lines.first().unwrap().mean_y() as i32;
    let bot_y = system.lines.last().unwrap().mean_y() as i32;
    let spacing = system.line_spacing;
    let staff_h = (bot_y - top_y) as f32;

    // Suche Vorzeichen im Bereich x ∈ [4*spacing, 14*spacing] nach Staff-Anfang.
    let x_left = first_x_with_pixel(bin, top_y, bot_y).unwrap_or(0);
    let x0 = x_left + (spacing * 4.0) as u32;
    let x1 = (x_left + (spacing * 14.0) as u32).min(bin.w);
    let y0 = (top_y - (spacing * 2.0) as i32).max(0) as u32;
    let y1 = ((bot_y + (spacing * 2.0) as i32).max(0) as u32).min(bin.h);
    if x0 >= x1 || y0 >= y1 { return KeySignature::default(); }

    let ccs = connected_components_region(bin, x0, y0, x1, y1);

    // # = vertikales Kreuz, ~1.7*spacing hoch, ~0.8*spacing breit
    // b = unten gerundet, ~1.7*spacing hoch, ~0.6*spacing breit
    let mut sharps = 0i8;
    let mut flats = 0i8;
    for (cx0, cy0, cx1, cy1) in &ccs {
        let h = (cy1 - cy0) as f32;
        let w = (cx1 - cx0) as f32;
        if !(h > spacing * 1.2 && h < spacing * 2.5) { continue; }
        if !(w > spacing * 0.3 && w < spacing * 1.3) { continue; }
        // # hat aspekt ~0.5 (höher als breit), b ähnlich
        // Unterscheidung: bei # gibt es zwei "Parallel-Linien" → CC hat 2 vertikale
        // dichte Spalten. Bei b ist eine Y-Region am unteren Ende sehr dicht.
        // Pragmatisch: nutze Aspect ≤ 0.55 für # (schmaler), > 0.55 für b.
        // Das ist ungenau aber für v0.1 OK.
        let region_w = (cx1 - cx0) as u32;
        let region_h = (cy1 - cy0) as u32;
        let _ = (region_w, region_h);
        let aspect = w / h.max(1.0);
        if aspect < 0.55 {
            sharps += 1;
        } else {
            flats += 1;
        }
    }
    let _ = staff_h;
    let fifths = if sharps > flats { sharps.min(7) } else { -(flats.min(7)) };
    KeySignature { fifths }
}

/// Erste X-Position mit schwarzem Pixel innerhalb der Y-Range (Staff-Anfang).
fn first_x_with_pixel(bin: &Binary, top_y: i32, bot_y: i32) -> Option<u32> {
    let y0 = top_y.max(0) as u32;
    let y1 = ((bot_y as u32) + 1).min(bin.h);
    for x in 0..bin.w {
        for y in y0..y1 {
            if bin.get(x, y) == 1 {
                return Some(x);
            }
        }
    }
    None
}

/// Lokale Connected-Components in einer Region. Returns (x0, y0, x1, y1)-Tupel.
fn connected_components_region(bin: &Binary, x0: u32, y0: u32, x1: u32, y1: u32) -> Vec<(i32, i32, i32, i32)> {
    // Crop in eine sub-Binary (overhead gering im typischen Schlüsselbereich).
    let w = (x1 - x0).max(1);
    let h = (y1 - y0).max(1);
    let mut sub = Binary::new(w, h);
    for yy in 0..h {
        for xx in 0..w {
            sub.set(xx, yy, bin.get(x0 + xx, y0 + yy));
        }
    }
    let ccs = connected_components(&sub);
    ccs.into_iter()
        .map(|cc| (
            (cc.bbox.x + x0) as i32,
            (cc.bbox.y + y0) as i32,
            (cc.bbox.x + cc.bbox.w + x0) as i32,
            (cc.bbox.y + cc.bbox.h + y0) as i32,
        ))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::StaffLine;

    fn dummy_staff(top_y: u32, spacing: u32) -> StaffSystem {
        StaffSystem {
            lines: (0..5)
                .map(|i| StaffLine {
                    y_per_x: vec![top_y + i * spacing; 200],
                })
                .collect(),
            line_spacing: spacing as f32,
            line_thickness: 1.0,
        }
    }

    #[test]
    fn no_clef_defaults_to_treble() {
        let bin = Binary::new(200, 200);
        let sys = dummy_staff(50, 10);
        let clef = detect_clef(&bin, &sys);
        assert!(matches!(clef, Clef::Treble));
    }

    #[test]
    fn no_signs_zero_fifths() {
        let bin = Binary::new(200, 200);
        let sys = dummy_staff(50, 10);
        let key = detect_key_signature(&bin, &sys);
        assert_eq!(key.fifths, 0);
    }
}
