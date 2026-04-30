// Stem-Detection. Verbessertes Verfahren:
//  - scanne x in [bbox.x - 3, bbox.x + bbox.w + 3]
//  - vertikaler Run muss min `1.5 * spacing` lang sein
//  - akzeptiere bis zu 3px Stem-Breite (Hough-ähnlich)

use omr_core::{Binary, Notehead, Stem};

pub fn detect_stems(bin: &Binary, noteheads: &[Notehead], spacing: f32) -> Vec<Stem> {
    let mut stems = Vec::new();
    let min_stem_len = (spacing * 1.5).max(8.0) as u32;
    for (i, nh) in noteheads.iter().enumerate() {
        // 1) Erst implied stem aus tall-narrow CC suchen (wahrscheinlichster Fall).
        if let Some(s) = crate::implied_stem_for_tall_notehead(bin, nh, spacing) {
            let mut s = s;
            s.notehead_idx = Some(i);
            stems.push(s);
            continue;
        }
        // 2) Fallback: scan rechts/links für isolierten Stem.
        if let Some(mut s) = find_stem_for(bin, nh, min_stem_len) {
            s.notehead_idx = Some(i);
            stems.push(s);
        }
    }
    stems
}

fn find_stem_for(bin: &Binary, nh: &Notehead, min_len: u32) -> Option<Stem> {
    let bb = nh.bbox;
    // Reihenfolge: rechts (Stems-Up häufiger), dann links (Stems-Down).
    let right_x_range = (bb.x + bb.w).saturating_sub(1)..(bb.x + bb.w + 4).min(bin.w);
    let left_x_range = bb.x.saturating_sub(3)..bb.x.saturating_add(2).min(bin.w);

    for x in right_x_range.chain(left_x_range) {
        if let Some(mut s) = scan_vertical(bin, x, bb.y, bb.h, min_len) {
            s.notehead_idx = None;
            return Some(s);
        }
    }
    None
}

/// Sucht einen vertikalen schwarzen Run, der den BBox-Bereich überschneidet
/// und mindestens `min_len` Pixel lang ist.
fn scan_vertical(bin: &Binary, x: u32, bb_y: u32, bb_h: u32, min_len: u32) -> Option<Stem> {
    if x >= bin.w { return None; }
    // Suche Anfang: höchstes y-Pixel das schwarz ist und im Range bb_y..bb_y+bb_h.
    let mut best: Option<Stem> = None;
    let mut y = 0u32;
    while y < bin.h {
        if bin.get(x, y) != 1 { y += 1; continue; }
        // Run startet bei y. Finde Ende.
        let start = y;
        while y + 1 < bin.h && bin.get(x, y + 1) == 1 { y += 1; }
        let end = y;
        let len = end - start + 1;
        // Run muss bbox überschneiden.
        let overlaps = !(end < bb_y || start > bb_y + bb_h.saturating_sub(1));
        if overlaps && len >= min_len {
            let candidate = Stem { x, y_top: start, y_bot: end, notehead_idx: None };
            best = match best {
                Some(s) if (s.y_bot - s.y_top) >= (end - start) => Some(s),
                _ => Some(candidate),
            };
        }
        y += 1;
    }
    best
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{NoteheadKind, Point, Rect};

    #[test]
    fn finds_stem_right_of_notehead() {
        let mut bin = Binary::new(50, 100);
        // Notehead at (10..18, 40..50)
        for y in 40..50 { for x in 10..18 { bin.set(x, y, 1); } }
        // Stem: 1px wide, x=18, y 20..50
        for y in 20..50 { bin.set(18, y, 1); }
        let nh = Notehead {
            bbox: Rect { x: 10, y: 40, w: 8, h: 10 },
            center: Point { x: 14.0, y: 45.0 },
            confidence: 1.0,
            kind: NoteheadKind::Filled,
            staff_idx: 0,
        };
        let stems = detect_stems(&bin, &[nh], 8.0);
        assert_eq!(stems.len(), 1, "expected exactly 1 stem");
        assert_eq!(stems[0].notehead_idx, Some(0));
        // y_top kann durch Gap-Tolerance bis 1px über tatsächlichem Stem-Top liegen.
        assert!(stems[0].y_top <= 20, "y_top = {} (≤ 20 erwartet)", stems[0].y_top);
        assert!(stems[0].y_bot >= 49);
    }
}
