// Stem-Detection: vertikale Run-Length-Erkennung neben Noteheads.

use omr_core::{Binary, Notehead, Stem};

/// Suche Stems an den Seiten der Noteheads.
/// Heuristik: 1-2px breite vertikale Runs der Länge >= 2*spacing.
pub fn detect_stems(bin: &Binary, noteheads: &[Notehead], spacing: f32) -> Vec<Stem> {
    let mut stems = Vec::new();
    let min_stem_len = (spacing * 2.0) as u32;
    for (i, nh) in noteheads.iter().enumerate() {
        if let Some(stem) = find_stem_for(bin, nh, min_stem_len) {
            let mut s = stem;
            s.notehead_idx = Some(i);
            stems.push(s);
        }
    }
    stems
}

fn find_stem_for(bin: &Binary, nh: &Notehead, min_len: u32) -> Option<Stem> {
    let bb = nh.bbox;
    // Rechte Seite (häufiger, "stems up")
    if let Some(s) = scan_vertical_at(bin, bb.x + bb.w, bb.y, bb.h, min_len, true) {
        return Some(s);
    }
    // Linke Seite (stems down)
    if let Some(s) = scan_vertical_at(bin, bb.x.saturating_sub(1), bb.y, bb.h, min_len, false) {
        return Some(s);
    }
    None
}

fn scan_vertical_at(
    bin: &Binary,
    x: u32,
    notehead_y: u32,
    notehead_h: u32,
    min_len: u32,
    upwards: bool,
) -> Option<Stem> {
    if x >= bin.w { return None; }
    // Suche schwarzen Pixel in 2-Pixel-Umkreis.
    for dx in 0..3 {
        let xc = x.saturating_add(dx);
        if xc >= bin.w { break; }
        if bin.get(xc, notehead_y) != 1 { continue; }
        let mut top = notehead_y;
        while top > 0 && bin.get(xc, top - 1) == 1 { top -= 1; }
        let mut bot = notehead_y + notehead_h.saturating_sub(1);
        while bot + 1 < bin.h && bin.get(xc, bot + 1) == 1 { bot += 1; }
        let len = bot - top + 1;
        if len >= min_len {
            let _ = upwards;
            return Some(Stem { x: xc, y_top: top, y_bot: bot, notehead_idx: None });
        }
    }
    None
}
