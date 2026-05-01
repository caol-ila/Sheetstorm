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
    detect_clef_with_extent(bin, system).0
}

/// Wie [`detect_clef`], aber liefert zusätzlich die rightmost-X der detektierten
/// Clef-Glyph-Bbox. Erlaubt eine genauere Skip-Region (Pipeline-Pre-Filter).
pub fn detect_clef_with_extent(bin: &Binary, system: &StaffSystem) -> (Clef, u32) {
    if system.lines.is_empty() {
        return (Clef::Treble, 0);
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

    let mut max_cc: Option<(i32, i32, i32, i32)> = None;
    let ccs = connected_components_region(bin, x0, y0, x1, y1);
    for (cx0, cy0, cx1, cy1) in ccs {
        let h = cy1 - cy0;
        if (h as f32) < staff_h * 0.6 { continue; }
        let prev_h = max_cc.map(|(_, sy0, _, sy1)| sy1 - sy0).unwrap_or(0);
        if h > prev_h {
            max_cc = Some((cx0, cy0, cx1, cy1));
        }
    }

    if let Some((_cx0, cy0, cx1, cy1)) = max_cc {
        let cc_h = (cy1 - cy0) as f32;
        let cc_top = cy0 as f32;
        let cc_bot = cy1 as f32;
        let rightmost_x = cx1 as u32;

        let clef = if cc_h >= staff_h * 1.4 {
            Clef::Treble
        } else {
            let cc_mid = (cc_top + cc_bot) * 0.5;
            let staff_mid = (top_y + bot_y) as f32 * 0.5;
            if cc_mid < staff_mid - spacing * 0.5 { Clef::Bass } else { Clef::Alto }
        };
        return (clef, rightmost_x);
    }
    (Clef::Treble, 0)
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

/// Wie [`detect_key_signature`], aber zusätzlich der rightmost-X aller
/// detektierten Vorzeichen-CCs. Erlaubt eine tightere Header-Skip-Region:
/// statt 0.7×fifths-Heuristik nutzen wir die echte Position des letzten
/// Vorzeichens.
///
/// Returns: `(KeySignature, rightmost_x)` — `rightmost_x` ist 0 wenn keine
/// Vorzeichen erkannt wurden.
pub fn detect_key_signature_with_extent(bin: &Binary, system: &StaffSystem) -> (KeySignature, u32) {
    if system.lines.is_empty() {
        return (KeySignature::default(), 0);
    }
    let top_y = system.lines.first().unwrap().mean_y() as i32;
    let bot_y = system.lines.last().unwrap().mean_y() as i32;
    let spacing = system.line_spacing;

    let x_left = first_x_with_pixel(bin, top_y, bot_y).unwrap_or(0);
    let x0 = x_left + (spacing * 4.0) as u32;
    let x1 = (x_left + (spacing * 14.0) as u32).min(bin.w);
    let y0 = (top_y - (spacing * 2.0) as i32).max(0) as u32;
    let y1 = ((bot_y + (spacing * 2.0) as i32).max(0) as u32).min(bin.h);
    if x0 >= x1 || y0 >= y1 {
        return (KeySignature::default(), 0);
    }

    let ccs = connected_components_region(bin, x0, y0, x1, y1);

    let mut sharps = 0i8;
    let mut flats = 0i8;
    let mut rightmost_x = 0u32;
    for (cx0, cy0, cx1, cy1) in &ccs {
        let h = (cy1 - cy0) as f32;
        let w = (cx1 - cx0) as f32;
        if !(h > spacing * 1.2 && h < spacing * 2.5) { continue; }
        if !(w > spacing * 0.3 && w < spacing * 1.3) { continue; }
        let aspect = w / h.max(1.0);
        if aspect < 0.55 { sharps += 1; } else { flats += 1; }
        rightmost_x = rightmost_x.max((*cx1).max(0) as u32);
    }
    let fifths = if sharps > flats { sharps.min(7) } else { -(flats.min(7)) };
    (KeySignature { fifths }, rightmost_x)
}

/// Erkenne die Taktart (z.B. 4/4, 3/4, 6/8) am Anfang eines Systems.
/// Strategie: Suche nach 2 vertikal übereinander stehenden Zahlen-CCs
/// hinter dem Schlüssel + Vorzeichen, im Bereich x ∈ [4..15]*spacing.
/// Klassifikation der Zahlen via Aspect-Heuristik:
///   - "4" / "3" / "2" / "6" sind ähnlich groß (~spacing × 1.6 spacing).
///   - Wir nehmen die häufigsten Werte an: numerator ≥ denominator,
///     aber für v0.1 reicht ein "best guess" auf Basis der Höhen.
pub fn detect_time_signature(bin: &Binary, system: &StaffSystem) -> Option<omr_core::TimeSignature> {
    if system.lines.is_empty() { return None; }
    let top_y = system.lines.first().unwrap().mean_y() as i32;
    let bot_y = system.lines.last().unwrap().mean_y() as i32;
    let spacing = system.line_spacing;

    let x_left = first_x_with_pixel(bin, top_y, bot_y).unwrap_or(0);
    let x0 = x_left + (spacing * 4.0) as u32;
    let x1 = (x_left + (spacing * 16.0) as u32).min(bin.w);
    let y0 = top_y.max(0) as u32;
    let y1 = (bot_y as u32 + 1).min(bin.h);
    if x0 >= x1 || y0 >= y1 { return None; }

    let ccs = connected_components_region(bin, x0, y0, x1, y1);
    // Suche zwei ungefähr gleichgroße CCs die vertikal übereinander stehen.
    // Höhe ~2*spacing, Breite ~spacing.
    let target_h = (spacing * 2.0) as u32;
    let target_w = (spacing * 1.2) as u32;

    let mut numerals: Vec<(i32, i32, i32, i32)> = ccs.iter()
        .filter(|(cx0, cy0, cx1, cy1)| {
            let h = (cy1 - cy0) as u32;
            let w = (cx1 - cx0) as u32;
            h >= target_h.saturating_sub(spacing as u32 / 2)
                && h <= target_h + (spacing as u32)
                && w >= target_w.saturating_sub(spacing as u32 / 2)
                && w <= target_w + (spacing as u32)
        })
        .copied()
        .collect();

    if numerals.len() < 2 { return None; }
    // Sortiere nach X-Mitte → die ersten 2 sind die Taktart.
    numerals.sort_by_key(|(cx0, _, cx1, _)| (cx0 + cx1) / 2);

    // Nehme das CC-Paar das vertikal am meisten überlappt.
    let mut best_pair: Option<((i32, i32, i32, i32), (i32, i32, i32, i32))> = None;
    let mut best_score = i32::MAX;
    for i in 0..numerals.len() {
        for j in i + 1..numerals.len() {
            let a = numerals[i];
            let b = numerals[j];
            let cx_a = (a.0 + a.2) / 2;
            let cx_b = (b.0 + b.2) / 2;
            if (cx_a - cx_b).abs() > spacing as i32 * 2 { continue; }
            // a oberhalb von b
            let (top, bot) = if (a.1 + a.3) < (b.1 + b.3) { (a, b) } else { (b, a) };
            if top.3 > bot.1 + 4 { continue; } // dürfen sich nicht überlappen
            let dist_to_staff_mid = ((top.1 + bot.3) / 2 - (top_y + bot_y) / 2).abs();
            if dist_to_staff_mid < best_score {
                best_score = dist_to_staff_mid;
                best_pair = Some((top, bot));
            }
        }
    }

    if let Some((top, bot)) = best_pair {
        let beats = classify_time_numeral(bin, top);
        let beat_type = classify_time_numeral(bin, bot);
        if let (Some(b), Some(bt)) = (beats, beat_type) {
            return Some(omr_core::TimeSignature { beats: b, beat_type: bt });
        }
    }
    None
}

/// Klassifiziere eine Ziffern-Bbox in eine Zahl 2..16. Sehr simple Heuristik
/// auf Basis von Bounding-Box-Aspect + interner Pixel-Verteilung.
fn classify_time_numeral(bin: &Binary, bb: (i32, i32, i32, i32)) -> Option<u8> {
    let (x0, y0, x1, y1) = bb;
    let w = (x1 - x0).max(1) as u32;
    let h = (y1 - y0).max(1) as u32;
    let bx0 = x0.max(0) as u32;
    let by0 = y0.max(0) as u32;
    let bx1 = (x1.max(0) as u32).min(bin.w - 1);
    let by1 = (y1.max(0) as u32).min(bin.h - 1);

    // Density in 4 vertikalen Streifen (top, mid-upper, mid-lower, bottom).
    let strip_h = (h / 4).max(1);
    let mut strips = [0f32; 4];
    for k in 0..4u32 {
        let ys = by0 + k * strip_h;
        let ye = (ys + strip_h).min(by1);
        let mut filled = 0u32;
        let mut total = 0u32;
        for yy in ys..=ye {
            for xx in bx0..=bx1 {
                total += 1;
                if bin.get(xx, yy) == 1 { filled += 1; }
            }
        }
        strips[k as usize] = filled as f32 / total.max(1) as f32;
    }
    let _ = (w, h);

    // Heuristik:
    //   "4": top dünn, mitte dicht (Querstrich), unten dünn. Density im 2. Streifen ist max.
    //   "2": oben rund, unten flach mit Strich.
    //   "3": Density relativ konstant, leicht oben+unten höher.
    //   "8": gleichmäßig dicht.
    //   "6": Density unten höher (Schleife unten).
    //   "16": breitere bbox (zwei Ziffern).

    let max_idx = strips
        .iter()
        .enumerate()
        .max_by(|a, b| a.1.partial_cmp(b.1).unwrap_or(std::cmp::Ordering::Equal))
        .map(|(i, _)| i)
        .unwrap_or(0);
    let bottom_density = strips[3];
    let top_density = strips[0];

    // Default 4 (häufigste Taktart in Blasmusik).
    if max_idx == 1 || max_idx == 2 {
        // Mittlerer Streifen dominiert → 4 (Querstrich) oder 8 (Mitte voll)
        if strips.iter().all(|&s| s > 0.4) {
            return Some(8);
        }
        return Some(4);
    }
    if bottom_density > top_density + 0.15 {
        return Some(6);
    }
    if top_density > bottom_density + 0.15 {
        return Some(2);
    }
    Some(4)
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
