// Sprungmarken-Detection (Volta, Repeat, D.C., D.S., Coda, Segno, Fine).
//
// Strategie:
// - Repeat-Bars (||: und :||): doppelte Vertikallinien mit 2 Punkten
//   (links/rechts). Erkennung anhand der bestehenden Bar-Detection +
//   doppelte-Linie-Heuristik.
// - Volta: horizontale Klammer ÜBER der Stafflinie mit Ziffer ("1.", "2.").
// - Coda/Segno: charakteristische Glyphen — werden via HoG+SVM-Klassifikator
//   erkannt (siehe classifier.rs). Hier nur Position-Annotation.
// - D.C./D.S./al Coda/al Fine/Fine: Text-Annotationen über/unter den
//   Stafflinien — werden via OCR oder Layout-Heuristik erkannt.
//   Aktuell: Text-Erkennung ist Phase 4, hier liefern wir Hooks.
//
// Phase A liefert die Bar-Marken (||: :||) zuverlässig + Volta-Detection
// als horizontale Klammer mit Ziffer am linken Anfang. Das reicht für die
// meisten Vereinsstücke.

use omr_core::{Binary, JumpMark, Notehead, Rect, StaffSystem};
use crate::bars::MeasureBar;

/// Erkennt Repeat-Marker basierend auf den schon detektierten Taktstrichen.
/// Repeat-Bars sind vertikale Doppellinien (oft mit Punkten daneben).
///
/// Heuristik: prüfe ob in 0.4*spacing-Distanz LINKS oder RECHTS eines Bar-X
/// eine zweite vertikale Linie steht. Ja → Repeat-Bar.
/// Wenn auf der LINKEN Seite Punkte (Doppel-Punkt-Pattern) → RepeatStart (||:).
/// Wenn auf der RECHTEN Seite Punkte → RepeatEnd (:||).
pub fn detect_repeat_marks(
    bin: &Binary,
    bars: &[MeasureBar],
    systems: &[StaffSystem],
) -> Vec<(usize, JumpMark)> {
    let mut out = Vec::new();
    for (bar_idx, bar) in bars.iter().enumerate() {
        let sys = match systems.get(bar.system_idx) {
            Some(s) => s,
            None => continue,
        };
        let spacing = sys.line_spacing;
        let bar_x = bar.x;

        // Hat der Bar einen "Partner" 0.2..0.5 spacing daneben?
        let partner_dist_min = (spacing * 0.2) as u32;
        let partner_dist_max = (spacing * 0.5).max(3.0) as u32;
        let mut has_left_partner = false;
        let mut has_right_partner = false;
        for d in partner_dist_min..=partner_dist_max {
            if bar_x >= d && is_vertical_line_at(bin, bar_x - d, sys) {
                has_left_partner = true;
            }
            if bar_x + d < bin.w && is_vertical_line_at(bin, bar_x + d, sys) {
                has_right_partner = true;
            }
        }
        // Punkte links / rechts der Doppellinie?
        let staff_top_y = sys.lines.first()
            .and_then(|l| l.y_per_x.iter().min().copied())
            .unwrap_or(0);
        let staff_bot_y = sys.lines.last()
            .and_then(|l| l.y_per_x.iter().max().copied())
            .unwrap_or(staff_top_y);
        let has_dots_left = has_repeat_dots(bin, bar_x, -1, spacing, staff_top_y, staff_bot_y);
        let has_dots_right = has_repeat_dots(bin, bar_x, 1, spacing, staff_top_y, staff_bot_y);

        // Klassifikation
        if has_dots_left && (has_left_partner || has_right_partner) {
            // Punkte links → RepeatEnd :||
            out.push((bar_idx, JumpMark::RepeatEnd));
        } else if has_dots_right && (has_left_partner || has_right_partner) {
            // Punkte rechts → RepeatStart ||:
            out.push((bar_idx, JumpMark::RepeatStart));
        }
    }
    out
}

/// Prüft ob bei x eine vertikale Linie quer durch das Staff-System geht.
fn is_vertical_line_at(bin: &Binary, x: u32, sys: &StaffSystem) -> bool {
    if x >= bin.w { return false; }
    let top_line = match sys.lines.first() { Some(l) => l, None => return false };
    let bot_line = match sys.lines.last() { Some(l) => l, None => return false };
    let top_y = *top_line.y_per_x.get(x as usize).unwrap_or(&0);
    let bot_y = *bot_line.y_per_x.get(x as usize).unwrap_or(&bin.h);
    if top_y >= bot_y { return false; }
    let h = bot_y - top_y + 1;
    let mut black = 0u32;
    for y in top_y..=bot_y.min(bin.h - 1) {
        if bin.get(x, y) == 1 { black += 1; }
    }
    let coverage = black as f32 / h.max(1) as f32;
    coverage >= 0.7
}

/// Sucht das typische "Doppel-Punkt-Pattern" (zwei Dots vertikal ausgerichtet
/// in den 2. und 3. Zwischenraum). `direction`: -1 = links, +1 = rechts vom Bar.
fn has_repeat_dots(
    bin: &Binary,
    bar_x: u32,
    direction: i32,
    spacing: f32,
    staff_top_y: u32,
    staff_bot_y: u32,
) -> bool {
    if staff_top_y >= staff_bot_y { return false; }
    // Horizontaler Offset: ~0.6..1.2 spacing weg vom Bar
    let dot_offset_min = (spacing * 0.5) as i32;
    let dot_offset_max = (spacing * 1.4) as i32;
    // Vertikale Position: 2. Linie + 0.5 Spacing (oberer Dot), 3. Linie + 0.5 Spacing (unterer Dot)
    // Genauer: zwischen Linie 2 und 3 (oberer Dot) und zwischen 3 und 4 (unterer Dot)
    let h = staff_bot_y - staff_top_y;
    // Zwischenräume bei 1.5/4 (~37%) und 2.5/4 (~62%) der Höhe
    let upper_dot_y = staff_top_y + h * 3 / 8;
    let lower_dot_y = staff_top_y + h * 5 / 8;
    let dot_radius = (spacing * 0.18).max(2.0) as i32;

    // Suche Pixel-Cluster im erwarteten Bereich
    for offset in dot_offset_min..=dot_offset_max {
        let x = bar_x as i32 + (direction * offset);
        if x < 0 || x as u32 >= bin.w { continue; }
        let xu = x as u32;
        // Hat dieser X-Bereich BEIDE Punkte (oben + unten)?
        if has_dot_near(bin, xu, upper_dot_y, dot_radius)
            && has_dot_near(bin, xu, lower_dot_y, dot_radius)
        {
            return true;
        }
    }
    false
}

fn has_dot_near(bin: &Binary, x: u32, y: u32, radius: i32) -> bool {
    if x >= bin.w || y >= bin.h { return false; }
    let r = radius.max(1);
    for dy in -r..=r {
        for dx in -r..=r {
            let xx = x as i32 + dx;
            let yy = y as i32 + dy;
            if xx < 0 || yy < 0 || xx as u32 >= bin.w || yy as u32 >= bin.h {
                continue;
            }
            if bin.get(xx as u32, yy as u32) == 1 {
                return true;
            }
        }
    }
    false
}

/// Erkennt Volta-Klammern oberhalb eines Stafflinien-Systems.
///
/// Volta-Klammer = horizontale Linie mit linkem Knick nach unten und ggf.
/// rechtem Knick nach unten + Ziffer-Pattern am linken Anfang.
///
/// Heuristik:
///   1. Suche eine durchgehende horizontale Linie 1.5-3 spacings über der
///      Top-Stafflinie, mindestens 4*spacing breit.
///   2. Wenn die Linie einen Knick nach unten am linken Ende hat: ist Volta.
///   3. Numerische Erkennung der Ziffer (1./2.) ist optional — wir markieren
///      jetzt einfach die ersten Volta = "1", zweite = "2", etc.
///
/// Returns: Vec<(bar_idx, JumpMark::Volta)>. bar_idx ist der Bar an dem die
/// Volta-Klammer beginnt.
pub fn detect_voltas(
    bin: &Binary,
    bars: &[MeasureBar],
    _noteheads: &[Notehead],
    systems: &[StaffSystem],
) -> Vec<(usize, JumpMark)> {
    let mut out = Vec::new();
    let mut volta_count = 0u8;

    for (sys_idx, sys) in systems.iter().enumerate() {
        let spacing = sys.line_spacing;
        let staff_top_y = sys.lines.first()
            .and_then(|l| l.y_per_x.iter().min().copied())
            .unwrap_or(0);
        if staff_top_y < (spacing * 3.0) as u32 { continue; }

        // Suche horizontale Linien im Y-Range [staff_top_y - 3*spacing, staff_top_y - 0.5*spacing]
        let y_min = staff_top_y.saturating_sub((spacing * 3.0) as u32);
        let y_max = staff_top_y.saturating_sub((spacing * 0.5) as u32);

        for y in y_min..=y_max {
            // Zähle die längste durchgehende horizontale Linie auf dieser Y-Position
            let (line_x_start, line_x_end) = longest_horizontal_run(bin, y);
            let line_len = line_x_end.saturating_sub(line_x_start);
            if line_len < (spacing * 4.0) as u32 { continue; }

            // Linker Knick nach unten? Prüfe ob bei line_x_start eine vertikale
            // Linie nach unten geht (2-3 Pixel).
            let has_left_corner = (0..(spacing * 0.6) as u32).any(|dy| {
                if y + dy >= bin.h { return false; }
                bin.get(line_x_start, y + dy) == 1
            });
            if !has_left_corner { continue; }

            // Volta detected — finde nähesten Bar
            let mid_x = (line_x_start + line_x_end) / 2;
            let nearest_bar = bars.iter().enumerate()
                .filter(|(_, b)| b.system_idx == sys_idx)
                .min_by_key(|(_, b)| (b.x as i64 - mid_x as i64).abs());
            if let Some((bar_idx, _)) = nearest_bar {
                volta_count = (volta_count % 2) + 1;
                out.push((bar_idx, JumpMark::Volta { number: volta_count }));
                break; // ein Volta pro System reicht
            }
        }
    }
    out
}

/// Findet den längsten durchgehenden horizontalen schwarzen Run auf Y-Position y.
/// Returns (start_x, end_x).
fn longest_horizontal_run(bin: &Binary, y: u32) -> (u32, u32) {
    if y >= bin.h { return (0, 0); }
    let mut best_start = 0u32;
    let mut best_end = 0u32;
    let mut best_len = 0u32;
    let mut x = 0u32;
    while x < bin.w {
        if bin.get(x, y) != 1 {
            x += 1;
            continue;
        }
        let start = x;
        while x + 1 < bin.w && bin.get(x + 1, y) == 1 {
            x += 1;
        }
        let len = x - start + 1;
        if len > best_len {
            best_len = len;
            best_start = start;
            best_end = x;
        }
        x += 1;
    }
    (best_start, best_end)
}

/// Sortiert die Sprungmarken-Detections und applied sie auf die Measures.
/// `bar_to_measure` mapped Bar-Index → Measure-Index in der finalen
/// Score-Struktur.
pub fn apply_jump_marks(
    measures: &mut [omr_core::Measure],
    bar_to_measure: &[Option<usize>],
    detections: &[(usize, JumpMark)],
) {
    for (bar_idx, mark) in detections {
        if let Some(&Some(m_idx)) = bar_to_measure.get(*bar_idx) {
            if let Some(m) = measures.get_mut(m_idx) {
                if !m.jump_marks.contains(mark) {
                    m.jump_marks.push(*mark);
                }
            }
        }
    }
}

/// Helper: Berechnet das Bbox eines Volta-Klammer-Bereichs (für Visual-Debug).
#[allow(dead_code)]
pub fn volta_bbox(bin: &Binary, sys: &StaffSystem) -> Option<Rect> {
    let spacing = sys.line_spacing;
    let staff_top_y = sys.lines.first()
        .and_then(|l| l.y_per_x.iter().min().copied())
        .unwrap_or(0);
    if staff_top_y < (spacing * 3.0) as u32 { return None; }
    let y_min = staff_top_y.saturating_sub((spacing * 3.0) as u32);
    let y_max = staff_top_y.saturating_sub((spacing * 0.5) as u32);

    let mut best: Option<Rect> = None;
    for y in y_min..=y_max {
        let (s, e) = longest_horizontal_run(bin, y);
        let len = e.saturating_sub(s);
        if len > (spacing * 4.0) as u32 {
            best = Some(Rect { x: s, y: y_min, w: e - s, h: y - y_min + 1 });
            break;
        }
    }
    best
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::StaffLine;

    fn make_staff() -> StaffSystem {
        StaffSystem {
            lines: [20u32, 30, 40, 50, 60].iter().map(|&y| StaffLine {
                y_per_x: vec![y; 200],
            }).collect(),
            line_spacing: 10.0,
            line_thickness: 1.0,
        }
    }

    #[test]
    fn detects_repeat_end_with_dots_left() {
        let mut bin = Binary::new(200, 100);
        // Stafflinien
        for line_y in [20u32, 30, 40, 50, 60] {
            for x in 5..195 { bin.set(x, line_y, 1); }
        }
        // Doppel-Bar bei x=100, x=104
        for y in 20..=60 {
            bin.set(100, y, 1);
            bin.set(104, y, 1);
        }
        // Punkte LINKS bei x=92 (in den Zwischenräumen)
        // Oberer Dot: y ~ 36 (zwischen Linie 2+3); unterer: y ~ 46 (zwischen 3+4)
        for dy in -2..=2 {
            for dx in -2..=2 {
                let yu = (36 + dy).max(0) as u32;
                let yl = (46 + dy).max(0) as u32;
                let x = (92 + dx).max(0) as u32;
                bin.set(x, yu, 1);
                bin.set(x, yl, 1);
            }
        }

        let sys = make_staff();
        let bars = vec![MeasureBar { x: 100, system_idx: 0 }];
        let marks = detect_repeat_marks(&bin, &bars, &[sys]);
        assert!(!marks.is_empty(), "expected repeat detection");
        assert_eq!(marks[0].1, JumpMark::RepeatEnd);
    }

    #[test]
    fn no_repeat_without_dots() {
        let mut bin = Binary::new(200, 100);
        for line_y in [20u32, 30, 40, 50, 60] {
            for x in 5..195 { bin.set(x, line_y, 1); }
        }
        // Einzelne Bar, keine Punkte
        for y in 20..=60 { bin.set(100, y, 1); }

        let sys = make_staff();
        let bars = vec![MeasureBar { x: 100, system_idx: 0 }];
        let marks = detect_repeat_marks(&bin, &bars, &[sys]);
        assert!(marks.is_empty(), "no repeat without dots");
    }
}
