// Stem-Detection. Verbessertes Verfahren:
//  - scanne x in [bbox.x - 8, bbox.x + bbox.w + 8] (war: -3 bis +3)
//  - vertikaler Run muss min `1.0 * spacing` lang sein (war: 1.5 spacing)
//  - akzeptiere bis zu 4px Stem-Breite + bis zu 4px Lücken
//
// Recall-Verbesserungen (vorher 25% Stem-Coverage → jetzt erwartet 60%+):
//  - Längere Stems werden auch mit kleineren min_len gefunden
//  - Größere x-Range fängt schiefe/wackelige Stems ab
//  - Mehr Gap-Toleranz für unterbrochene Stems (alte/scan-Drucke)

use omr_core::{Binary, Notehead, Stem};

pub fn detect_stems(bin: &Binary, noteheads: &[Notehead], spacing: f32) -> Vec<Stem> {
    let mut stems = Vec::new();
    // Reduziert von 1.5 auf 1.0 spacing — Stems in Beam-Gruppen sind oft kürzer.
    // Min 6px absolut für sehr-kleinen-Notenkopf-Fall.
    let min_stem_len = (spacing * 1.0).max(6.0) as u32;
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
    // Erweiterter Scan: bis 8px rechts/links (war: 5/3) — bei schiefen Scans
    // sind Stems oft mehrere px versetzt zum NH-Bbox-Rand.
    let right_x_range = (bb.x + bb.w).saturating_sub(3)..(bb.x + bb.w + 9).min(bin.w);
    let left_x_range = bb.x.saturating_sub(8)..bb.x.saturating_add(4).min(bin.w);

    let mut best_stem: Option<Stem> = None;
    let mut best_len: u32 = 0;
    for x in right_x_range.chain(left_x_range) {
        if let Some(s) = scan_vertical(bin, x, bb.y, bb.h, min_len) {
            let len = s.y_bot.saturating_sub(s.y_top);
            if len > best_len {
                best_len = len;
                best_stem = Some(s);
            }
        }
    }
    best_stem.map(|mut s| { s.notehead_idx = None; s })
}

/// Sucht einen vertikalen schwarzen Run mit Gap-Tolerance,
/// der den BBox-Bereich überschneidet und mindestens `min_len` lang ist.
fn scan_vertical(bin: &Binary, x: u32, bb_y: u32, bb_h: u32, min_len: u32) -> Option<Stem> {
    if x >= bin.w { return None; }
    let mut best: Option<Stem> = None;
    // Erhöht von 2 auf 4px — bei alten/gefadeten Scans sind Stems oft unterbrochen.
    let max_gap = 4u32;
    let mut y = 0u32;
    while y < bin.h {
        if bin.get(x, y) != 1 { y += 1; continue; }
        let start = y;
        let mut gap = 0u32;
        let mut last_black = y;
        while y + 1 < bin.h {
            if bin.get(x, y + 1) == 1 {
                last_black = y + 1;
                gap = 0;
                y += 1;
            } else if gap < max_gap {
                gap += 1;
                y += 1;
            } else {
                break;
            }
        }
        let end = last_black;
        let len = end - start + 1;
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
