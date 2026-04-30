// Measure-Bar (Taktstrich) Detection.
//
// Strategie: Suche vertikale Pixel-Linien die das gesamte Staff-System
// von oben nach unten durchqueren — typischerweise 1-3 px breit.
//
// In den meisten Notensätzen sind Taktstriche dünner als Stems und
// erstrecken sich exakt von der ersten bis zur fünften Stafflinie
// (während Stems 0.5-3 spacings über/unter dem System hinausragen).

use omr_core::{Binary, StaffSystem};

#[derive(Debug, Clone)]
pub struct MeasureBar {
    pub x: u32,
    pub system_idx: usize,
}

/// Detektiert alle Taktstriche in einem ORIGINAL-Binary (mit Stafflinien).
pub fn detect_measure_bars(bin: &Binary, systems: &[StaffSystem]) -> Vec<MeasureBar> {
    let mut bars = Vec::new();
    for (idx, sys) in systems.iter().enumerate() {
        if sys.lines.len() < 2 { continue; }
        let top_line = sys.lines.first().unwrap();
        let bot_line = sys.lines.last().unwrap();
        let spacing = sys.line_spacing;
        let max_thickness = (spacing * 0.4).max(2.0) as u32;

        // Pro X-Spalte: ist der Bereich [top_line.y..bot_line.y] vollständig schwarz?
        let mut x = 0u32;
        let mut last_bar_x: i64 = -1;
        // Min-Distance zwischen Taktstrichen — Takte sind typischerweise
        // mind. 4*spacing breit.
        let min_dist = (spacing * 3.0) as i64;
        while x < bin.w {
            let top_y = *top_line.y_per_x.get(x as usize).unwrap_or(&0);
            let bot_y = *bot_line.y_per_x.get(x as usize).unwrap_or(&bin.h);
            if !is_full_vertical(bin, x, top_y, bot_y) {
                x += 1;
                continue;
            }
            // Run-Breite messen.
            let mut x_end = x;
            while x_end + 1 < bin.w {
                let ty = *top_line.y_per_x.get((x_end + 1) as usize).unwrap_or(&0);
                let by = *bot_line.y_per_x.get((x_end + 1) as usize).unwrap_or(&bin.h);
                if !is_full_vertical(bin, x_end + 1, ty, by) { break; }
                x_end += 1;
            }
            let bar_width = x_end - x + 1;
            // Filter: nicht zu dick (sonst ist es ein Symbol).
            if bar_width <= max_thickness {
                let bar_x = (x + x_end) / 2;
                if (bar_x as i64) - last_bar_x >= min_dist {
                    bars.push(MeasureBar { x: bar_x, system_idx: idx });
                    last_bar_x = bar_x as i64;
                }
            }
            x = x_end + 1;
        }
    }
    bars
}

/// Prüft ob die Spalte x zwischen [top_y, bot_y] (inclusive) vollständig
/// schwarze Pixel enthält. Toleriert kleine Lücken (max 2 weiße Pixel
/// hintereinander).
fn is_full_vertical(bin: &Binary, x: u32, top_y: u32, bot_y: u32) -> bool {
    if x >= bin.w { return false; }
    let h = bot_y.saturating_sub(top_y) + 1;
    let mut white = 0u32;
    let mut white_max = 0u32;
    let mut black = 0u32;
    for y in top_y..=bot_y.min(bin.h - 1) {
        if bin.get(x, y) == 1 {
            black += 1;
            white = 0;
        } else {
            white += 1;
            if white > white_max { white_max = white; }
        }
    }
    // Min 80% schwarz UND max 2 aufeinanderfolgende weiße Pixel.
    let coverage = black as f32 / h.max(1) as f32;
    coverage >= 0.8 && white_max <= 2
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::StaffLine;

    #[test]
    fn finds_one_measure_bar() {
        let mut bin = Binary::new(200, 100);
        // Stafflinien y=20, 30, 40, 50, 60.
        for line_y in [20u32, 30, 40, 50, 60] {
            for x in 5..195 { bin.set(x, line_y, 1); }
        }
        // Taktstrich x=100, von y=20 bis y=60.
        for y in 20..=60 { bin.set(100, y, 1); }
        // 2. Taktstrich x=150.
        for y in 20..=60 { bin.set(150, y, 1); }

        let sys = StaffSystem {
            lines: [20u32, 30, 40, 50, 60].iter().map(|&y| StaffLine {
                y_per_x: vec![y; 200],
            }).collect(),
            line_spacing: 10.0,
            line_thickness: 1.0,
        };
        let bars = detect_measure_bars(&bin, &[sys]);
        assert_eq!(bars.len(), 2);
        assert!((bars[0].x as i32 - 100).abs() <= 1);
        assert!((bars[1].x as i32 - 150).abs() <= 1);
    }
}
