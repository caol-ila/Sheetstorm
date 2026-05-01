// Beam-Detection für korrekte Achtel-/Sechzehntel-/32stel-Erkennung.
//
// Beams sind dicke horizontale Balken zwischen mehreren Stems. Sie geben
// uns die Notenwert-Information bei Achteln und kleiner.
//
// Algorithmus:
//   1. Scanne im staff-removed Bild horizontale Runs der Länge >= 1.5*spacing
//      und Höhe in [0.4, 1.0]*spacing (Beam-Dicke ist typisch 0.5*spacing).
//   2. Pro Run: notiere x0, x1, y, thickness.
//   3. Match: jeder Stem dessen X innerhalb [x0, x1] liegt UND dessen
//      Y-Range den Beam-Y überlappt → der Stem hat diesen Beam.
//   4. Anzahl Beams pro Stem → Duration:
//        1 Beam → Achtel (8th)
//        2 Beams → Sechzehntel (16th)
//        3+ Beams → 32th oder schneller

use omr_core::{Binary, Stem};

#[derive(Debug, Clone)]
pub struct Beam {
    pub x_start: u32,
    pub x_end: u32,
    pub y_top: u32,
    pub y_bot: u32,
}

/// Detektiert Beams im (staff-removed) Bild.
pub fn detect_beams(bin: &Binary, spacing: f32) -> Vec<Beam> {
    // Min-Width 1.2*spacing (vorher 1.5): kürzere Beams (Achtel-Paare am Takt-Ende)
    // wurden vorher zu oft verworfen.
    let min_w = (spacing * 1.2) as u32;
    let min_thick = (spacing * 0.3) as u32;
    let max_thick = (spacing * 1.0) as u32;

    let mut beams = Vec::new();
    for y in 0..bin.h {
        let mut x = 0u32;
        while x < bin.w {
            if bin.get(x, y) != 1 { x += 1; continue; }
            let start = x;
            while x + 1 < bin.w && bin.get(x + 1, y) == 1 { x += 1; }
            let end = x;
            x += 1;
            let len = end - start + 1;
            if len < min_w { continue; }
            let thickness = measure_thickness(bin, start, end, y);
            if thickness < min_thick || thickness > max_thick { continue; }
            // Dedupe: skip wenn bei y-1 schon ein ähnlicher Run war.
            if y > 0 && has_similar_run(bin, start, end, y - 1) { continue; }
            beams.push(Beam {
                x_start: start,
                x_end: end,
                y_top: y,
                y_bot: y + thickness - 1,
            });
        }
    }
    beams
}

fn measure_thickness(bin: &Binary, x0: u32, x1: u32, y0: u32) -> u32 {
    let mut thickness = 0u32;
    let mut yy = y0;
    while yy < bin.h {
        let mut filled = 0u32;
        for x in x0..=x1 {
            if bin.get(x, yy) == 1 { filled += 1; }
        }
        // Coverage 0.55 (vorher 0.7): Beams im realen Druck haben oft ausgefranste
        // Ränder oder durchschnittene Stems.
        let coverage = filled as f32 / (x1 - x0 + 1) as f32;
        if coverage < 0.55 { break; }
        thickness += 1;
        yy += 1;
    }
    thickness
}

fn has_similar_run(bin: &Binary, x0: u32, x1: u32, y: u32) -> bool {
    let mut filled = 0u32;
    for x in x0..=x1 {
        if bin.get(x, y) == 1 { filled += 1; }
    }
    let coverage = filled as f32 / (x1 - x0 + 1) as f32;
    coverage > 0.55
}

/// Filtert Noteheads, deren Center in einem Beam-Bbox liegt.
///
/// Bei dichten Sechzehntel-/Achtel-Gruppen werden Beam-Pixelblöcke gelegentlich
/// als zusätzliche Noteheads detektiert (Connected-Component-Splits). Da Beams
/// horizontale Balken zwischen mehreren Stems sind, kann ein echter Notehead
/// niemals MITTIG auf einem Beam liegen — Stems berühren Beams am Stem-Ende
/// gegenüber dem NH.
///
/// Tolerance: y_top und y_bot werden um `tol` (in Pixeln) erweitert, um auch
/// nahe-am-Beam liegende FPs zu fangen.
pub fn filter_noteheads_on_beams(
    noteheads: Vec<omr_core::Notehead>,
    beams: &[Beam],
    tol: u32,
) -> Vec<omr_core::Notehead> {
    noteheads
        .into_iter()
        .filter(|nh| {
            let cx = nh.center.x as i32;
            let cy = nh.center.y as i32;
            !beams.iter().any(|b| {
                let y0 = b.y_top.saturating_sub(tol) as i32;
                let y1 = (b.y_bot + tol) as i32;
                cx >= b.x_start as i32
                    && cx <= b.x_end as i32
                    && cy >= y0
                    && cy <= y1
            })
        })
        .collect()
}

/// Anzahl Beams die einen gegebenen Stem berühren.
pub fn beams_per_stem(stems: &[Stem], beams: &[Beam]) -> Vec<u32> {
    stems
        .iter()
        .map(|s| {
            beams
                .iter()
                .filter(|b| s.x >= b.x_start && s.x <= b.x_end
                    && !(b.y_bot < s.y_top || b.y_top > s.y_bot))
                .count() as u32
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_simple_beam() {
        let mut bin = Binary::new(100, 50);
        // Beam 30 px breit, 4 px dick (spacing=10 → 0.4*spacing).
        for y in 20..24 {
            for x in 30..60 {
                bin.set(x, y, 1);
            }
        }
        let beams = detect_beams(&bin, 10.0);
        assert!(!beams.is_empty(), "expected at least one beam");
        let b = &beams[0];
        assert!(b.x_end - b.x_start >= 25);
        assert!(b.y_bot - b.y_top >= 2);
    }

    #[test]
    fn matches_stem_to_beam() {
        let beams = vec![Beam { x_start: 30, x_end: 60, y_top: 20, y_bot: 24 }];
        let stems = vec![
            Stem { x: 35, y_top: 22, y_bot: 50, notehead_idx: Some(0) }, // crosses beam
            Stem { x: 80, y_top: 22, y_bot: 50, notehead_idx: Some(1) }, // doesn't cross
        ];
        let counts = beams_per_stem(&stems, &beams);
        assert_eq!(counts, vec![1, 0]);
    }
}
