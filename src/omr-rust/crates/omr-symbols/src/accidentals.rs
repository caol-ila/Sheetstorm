//! Lokale Accidentals (♯, ♭, ♮) direkt links von Noteheads.
//!
//! Strategie: Pro NH suchen wir Connected-Components in einem schmalen
//! Bereich LINKS vom NH (Range: 0.3-1.5 spacing in X, ±1.2 spacing in Y).
//!
//! Klassifikation via Shape:
//!   - Sharp (#): symmetrisch, ~0.7-1.0 spacing breit, ~1.5-2.0 spacing hoch,
//!     Pixel-Verteilung gleichmäßig in Y (zwei horizontale Kreuzungen)
//!   - Flat (b): asymmetrisch, ~0.4-0.7 spacing breit, ~1.5-2.0 spacing hoch,
//!     Pixel-Verteilung schwerpunktmäßig UNTEN (Bauchform)
//!   - Natural (♮): symmetrisch, ähnlich Sharp aber schmaler, weniger Pixel
//!
//! Output: pro NH der zusätzliche `alter` (-1 = flat, 0 = none, +1 = sharp).
//! Der Score-Builder kombiniert das mit der Key-Signature: lokale Accidentals
//! ÜBERSCHREIBEN die Key-Signature (für genau diese eine Note).

use omr_core::{Binary, Notehead, StaffSystem};

use crate::cc::connected_components;

/// Detektiert lokale Accidentals für jeden Notehead.
///
/// Returns: pro NH einen Override-`alter`-Wert oder None.
/// None = kein lokales Accidental → Score-Builder nutzt Key-Sig.
pub fn detect_local_accidentals(
    bin: &Binary,
    noteheads: &[Notehead],
    systems: &[StaffSystem],
) -> Vec<Option<i8>> {
    let mut alters = vec![None; noteheads.len()];
    if systems.is_empty() {
        return alters;
    }
    let spacing = systems[0].line_spacing;

    for (i, nh) in noteheads.iter().enumerate() {
        let cx = nh.center.x as i32;
        let cy = nh.center.y as i32;
        // Search-Region: LINKS vom NH-Linksrand, 0.3-1.7 spacing
        let nh_left = nh.bbox.x as i32;
        let x0 = (nh_left - (spacing * 1.7) as i32).max(0) as u32;
        let x1 = (nh_left - (spacing * 0.2) as i32).max(0) as u32;
        let y0 = (cy - (spacing * 1.3) as i32).max(0) as u32;
        let y1 = ((cy + (spacing * 1.3) as i32).max(0) as u32).min(bin.h);
        if x0 >= x1 || y0 >= y1 { continue; }

        let _ = cx; // unused but useful for context

        // Sub-Binary cropping
        let w = (x1 - x0).max(1);
        let h = (y1 - y0).max(1);
        let mut sub = Binary::new(w, h);
        for yy in 0..h {
            for xx in 0..w {
                sub.set(xx, yy, bin.get(x0 + xx, y0 + yy));
            }
        }
        let ccs = connected_components(&sub);

        // Suche das CC das am rechtmäßigsten ist und Accidental-Shape hat.
        // (Accidental sitzt direkt links neben dem NH.)
        let mut best: Option<(u32, char)> = None; // (right-edge, kind)
        for cc in &ccs {
            let bb = cc.bbox;
            let cc_h = bb.h as f32;
            let cc_w = bb.w as f32;
            // Größe-Filter: Accidentals sind schmaler-als-hoch
            if !(cc_h > spacing * 1.0 && cc_h < spacing * 2.5) { continue; }
            if !(cc_w > spacing * 0.25 && cc_w < spacing * 1.0) { continue; }
            let aspect = cc_w / cc_h.max(1.0);
            if aspect > 0.75 { continue; } // muss höher als breit sein

            // Klassifikation Sharp vs Flat:
            // Sharp: pixel-density ist symmetrisch um Y-Mitte (zwei horizontale Querbalken)
            // Flat:  pixel-density ist UNTERE-Hälfte schwerer (Bauch)
            let mid_y = bb.y + bb.h / 2;
            let mut top_px = 0u32;
            let mut bot_px = 0u32;
            for yy in bb.y..(bb.y + bb.h) {
                for xx in bb.x..(bb.x + bb.w) {
                    if sub.get(xx, yy) != 0 {
                        if yy < mid_y { top_px += 1; } else { bot_px += 1; }
                    }
                }
            }
            let total_px = top_px + bot_px;
            if total_px < 10 { continue; } // zu wenige Pixel

            // Sharp: top/bot innerhalb 30% Differenz
            // Flat: bot >= 1.4× top
            let kind = if bot_px >= (top_px * 14 / 10) {
                'b'
            } else if (top_px as i32 - bot_px as i32).abs() < (total_px as i32 * 30 / 100) {
                '#'
            } else {
                continue; // unentschieden
            };

            let cc_right = bb.x + bb.w;
            // Wir bevorzugen das CC am rechtmäßigsten (am nächsten am NH)
            if best.is_none() || cc_right > best.as_ref().unwrap().0 {
                best = Some((cc_right, kind));
            }
        }

        if let Some((_, kind)) = best {
            alters[i] = Some(if kind == '#' { 1 } else { -1 });
        }
    }

    alters
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{NoteheadKind, Point, Rect, StaffLine};

    fn mk_bin(w: u32, h: u32) -> Binary {
        Binary { w, h, data: vec![0u8; (w * h) as usize] }
    }

    fn put_pixel(bin: &mut Binary, x: u32, y: u32) {
        if x < bin.w && y < bin.h {
            let idx = (y * bin.w + x) as usize;
            bin.data[idx] = 1;
        }
    }

    fn mk_system(top_y: u32, spacing: u32) -> StaffSystem {
        let mut lines = Vec::new();
        for i in 0..5 {
            let y = top_y + i * spacing;
            let mut y_per_x = vec![0u32; 1000];
            for x in 50..950 { y_per_x[x] = y; }
            lines.push(StaffLine { y_per_x });
        }
        StaffSystem { lines, line_spacing: spacing as f32, line_thickness: 2.0 }
    }

    fn mk_nh(x: f32, y: f32) -> Notehead {
        Notehead {
            bbox: Rect { x: (x as u32).saturating_sub(8), y: (y as u32).saturating_sub(8), w: 16, h: 16 },
            center: Point { x, y },
            confidence: 0.9, kind: NoteheadKind::Filled, staff_idx: 0,
        }
    }

    #[test]
    fn detect_sharp_left_of_notehead() {
        let mut bin = mk_bin(400, 300);
        let system = mk_system(100, 18);
        // Sharp # bei x=70, y=140 (links von NH bei x=100)
        // Sharp: 2 vertikale Linien + 2 horizontale Querbalken, ~10x30
        for y in 130..158 { put_pixel(&mut bin, 70, y); put_pixel(&mut bin, 78, y); } // verticals
        for x in 67..82 { put_pixel(&mut bin, x, 138); put_pixel(&mut bin, x, 148); } // horizontals
        let nhs = vec![mk_nh(100.0, 140.0)];
        let alters = detect_local_accidentals(&bin, &nhs, &[system]);
        assert_eq!(alters.len(), 1);
        assert_eq!(alters[0], Some(1), "expected sharp (+1) but got {:?}", alters[0]);
    }

    #[test]
    fn detect_flat_left_of_notehead() {
        let mut bin = mk_bin(400, 300);
        let system = mk_system(100, 18);
        // Flat b bei x=70: vertikale Linie + Bauch unten
        for y in 120..160 { put_pixel(&mut bin, 70, y); }
        // Bauch unten (Halbkreis) - mehr Pixel im unteren Bereich
        for y in 145..158 {
            for x in 70..80 { put_pixel(&mut bin, x, y); }
        }
        let nhs = vec![mk_nh(100.0, 140.0)];
        let alters = detect_local_accidentals(&bin, &nhs, &[system]);
        assert_eq!(alters[0], Some(-1), "expected flat (-1) but got {:?}", alters[0]);
    }

    #[test]
    fn no_accidental_for_isolated_notehead() {
        let bin = mk_bin(400, 300);
        let system = mk_system(100, 18);
        let nhs = vec![mk_nh(100.0, 140.0)];
        let alters = detect_local_accidentals(&bin, &nhs, &[system]);
        assert_eq!(alters[0], None);
    }
}
