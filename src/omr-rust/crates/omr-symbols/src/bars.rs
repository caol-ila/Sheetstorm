// Measure-Bar (Taktstrich) Detection.
//
// Strategie (verbessert nach Visual-Debug):
//   1. Suche vertikale Pixel-Spalten die das Staff-System komplett durchqueren
//   2. STRIKT: Spalte direkt links UND rechts vom Bar-Run muss WEISS sein
//      (= isolierte Vertikallinie, nicht Stem-mit-Notehead-dran)
//   3. Bar-Run muss UNTERHALB top_line beginnen UND ÜBERHALB bot_line enden
//      (Stems ragen meist über die Linien hinaus)
//   4. Min-Distance zwischen Bars: 4*spacing
//   5. Bars dürfen sich NICHT mit Notehead-X-Positionen überlappen

use omr_core::{Binary, Notehead, StaffSystem};

#[derive(Debug, Clone)]
pub struct MeasureBar {
    pub x: u32,
    pub system_idx: usize,
}

pub fn detect_measure_bars(
    bin: &Binary,
    systems: &[StaffSystem],
    noteheads: &[Notehead],
) -> Vec<MeasureBar> {
    let mut bars = detect_bars_with_params(bin, systems, noteheads, BarParams::strict());

    // Adaptiv: Wenn ein System sehr wenige Bars hat (< 2 für Systeme mit
    // signifikant Notenkopf-Inhalt), versuche eine zweite Pass mit
    // toleranteren Parametern. Häufiger Fall: handgeschriebene Notenblätter
    // mit wackeligen Bar-Linien.
    for (idx, sys) in systems.iter().enumerate() {
        let bars_in_system = bars.iter().filter(|b| b.system_idx == idx).count();
        let nhs_in_system = noteheads.iter().filter(|n| n.staff_idx == idx).count();
        if bars_in_system < 2 && nhs_in_system >= 6 {
            // Fallback: lockere Parameter, NUR für dieses System
            let extra = detect_bars_in_one_system(bin, sys, idx, noteheads, BarParams::loose());
            // Dedup gegen existierende
            for new_bar in extra {
                let already = bars.iter().any(|b| {
                    b.system_idx == idx
                        && (b.x as i32 - new_bar.x as i32).abs() < (sys.line_spacing * 2.0) as i32
                });
                if !already {
                    bars.push(new_bar);
                }
            }
        }
    }
    // Sort by system, then x
    bars.sort_by_key(|b| (b.system_idx, b.x));
    bars
}

#[derive(Clone, Copy)]
struct BarParams {
    coverage_min: f32,
    white_max: u32,
    flank_white_required: u32,
}

impl BarParams {
    fn strict() -> Self {
        Self { coverage_min: 0.78, white_max: 3, flank_white_required: 6 }
    }
    fn loose() -> Self {
        // Für handgeschriebene Bars: weniger volle Spalten, mehr Lücken erlaubt,
        // weniger weiße Flanken (Pen-Strich kann diagonal sein).
        Self { coverage_min: 0.60, white_max: 6, flank_white_required: 4 }
    }
}

fn detect_bars_with_params(
    bin: &Binary,
    systems: &[StaffSystem],
    noteheads: &[Notehead],
    params: BarParams,
) -> Vec<MeasureBar> {
    let mut bars = Vec::new();
    for (idx, sys) in systems.iter().enumerate() {
        let mut sys_bars = detect_bars_in_one_system(bin, sys, idx, noteheads, params);
        bars.append(&mut sys_bars);
    }
    bars
}

fn detect_bars_in_one_system(
    bin: &Binary,
    sys: &StaffSystem,
    idx: usize,
    noteheads: &[Notehead],
    params: BarParams,
) -> Vec<MeasureBar> {
    let mut bars = Vec::new();
    if sys.lines.len() < 2 { return bars; }
    let top_line = sys.lines.first().unwrap();
    let bot_line = sys.lines.last().unwrap();
    let spacing = sys.line_spacing;
    let max_thickness = (spacing * 0.4).max(2.0) as u32;
    let margin = (spacing * 0.4) as u32;
    let min_dist = (spacing * 4.0) as i64;

    let nh_xs: Vec<f32> = noteheads.iter()
        .filter(|n| n.staff_idx == idx)
        .map(|n| n.center.x)
        .collect();
    let nh_proximity = spacing * 0.7;

    let mut x = 0u32;
    let mut last_bar_x: i64 = -((min_dist as i64) + 1);
    while x < bin.w {
        let top_y = *top_line.y_per_x.get(x as usize).unwrap_or(&0);
        let bot_y = *bot_line.y_per_x.get(x as usize).unwrap_or(&bin.h);

        if !column_is_full_between(bin, x, top_y, bot_y, params.coverage_min, params.white_max) {
            x += 1;
            continue;
        }

        let mut x_end = x;
        while x_end + 1 < bin.w {
            let ty = *top_line.y_per_x.get((x_end + 1) as usize).unwrap_or(&0);
            let by = *bot_line.y_per_x.get((x_end + 1) as usize).unwrap_or(&bin.h);
            if !column_is_full_between(bin, x_end + 1, ty, by, params.coverage_min, params.white_max) { break; }
            x_end += 1;
        }
        let bar_width = x_end - x + 1;

        if bar_width > max_thickness {
            x = x_end + 1;
            continue;
        }

        let bar_x = (x + x_end) / 2;
        let (run_top, run_bot) = run_extent(bin, bar_x, top_y);
        let extends_above = top_y.saturating_sub(run_top) > margin;
        let extends_below = run_bot.saturating_sub(bot_y) > margin;
        if extends_above || extends_below {
            x = x_end + 1;
            continue;
        }

        let too_close_to_nh = nh_xs.iter().any(|&nx| (nx - bar_x as f32).abs() < nh_proximity);
        if too_close_to_nh {
            x = x_end + 1;
            continue;
        }

        if (bar_x as i64) - last_bar_x < min_dist {
            x = x_end + 1;
            continue;
        }

        if !flanks_are_white(bin, x, x_end, top_y, bot_y, params.flank_white_required) {
            x = x_end + 1;
            continue;
        }

        bars.push(MeasureBar { x: bar_x, system_idx: idx });
        last_bar_x = bar_x as i64;
        x = x_end + 1;
    }
    bars
}

/// Spalte zwischen [top_y, bot_y] muss zu mindestens `coverage_min` schwarz sein,
/// max. `white_max` aufeinanderfolgende weiße Pixel.
fn column_is_full_between(bin: &Binary, x: u32, top_y: u32, bot_y: u32, coverage_min: f32, white_max: u32) -> bool {
    if x >= bin.w { return false; }
    let bot = bot_y.min(bin.h.saturating_sub(1));
    if top_y >= bot { return false; }
    let h = bot - top_y + 1;
    let mut white = 0u32;
    let mut white_max_seen = 0u32;
    let mut black = 0u32;
    for y in top_y..=bot {
        if bin.get(x, y) == 1 {
            black += 1;
            white = 0;
        } else {
            white += 1;
            if white > white_max_seen { white_max_seen = white; }
        }
    }
    let coverage = black as f32 / h.max(1) as f32;
    coverage >= coverage_min && white_max_seen <= white_max
}

/// Findet den vertikalen schwarzen Run der Position (x, y_seed) enthält.
fn run_extent(bin: &Binary, x: u32, y_seed: u32) -> (u32, u32) {
    if x >= bin.w || y_seed >= bin.h || bin.get(x, y_seed) != 1 {
        return (y_seed, y_seed);
    }
    let mut top = y_seed;
    while top > 0 && bin.get(x, top - 1) == 1 { top -= 1; }
    let mut bot = y_seed;
    while bot + 1 < bin.h && bin.get(x, bot + 1) == 1 { bot += 1; }
    (top, bot)
}

/// Linke und rechte Nachbarspalten müssen weitgehend weiß sein.
fn flanks_are_white(bin: &Binary, bar_x_start: u32, bar_x_end: u32, top_y: u32, bot_y: u32, white_required: u32) -> bool {
    let bot = bot_y.min(bin.h.saturating_sub(1));
    if top_y >= bot { return false; }
    let h = bot - top_y;
    let spacing = h / 4;
    if spacing == 0 { return false; }
    let left_x = bar_x_start.saturating_sub(2);
    let right_x = (bar_x_end + 2).min(bin.w.saturating_sub(1));
    if left_x == bar_x_start || right_x == bar_x_end { return false; }
    let mut white_count = 0;
    for i in 0..4 {
        let y = top_y + spacing / 2 + i * spacing;
        if y >= bin.h { continue; }
        if bin.get(left_x, y) == 0 { white_count += 1; }
        if bin.get(right_x, y) == 0 { white_count += 1; }
    }
    // Mindestens 6/8 müssen weiß sein.
    white_count >= white_required as usize
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
    fn finds_isolated_bar_only() {
        let mut bin = Binary::new(200, 100);
        for line_y in [20u32, 30, 40, 50, 60] {
            for x in 5..195 { bin.set(x, line_y, 1); }
        }
        // Echter Taktstrich x=100 (von 20..=60)
        for y in 20..=60 { bin.set(100, y, 1); }
        // Stem x=150: 1px breit, ragt von 50 bis 80 (Notehead darunter)
        for y in 50..=80 { bin.set(150, y, 1); }
        for yy in 75..82 { for xx in 145..155 { bin.set(xx, yy, 1); } } // Notehead

        let bars = detect_measure_bars(&bin, &[make_staff()], &[]);
        assert_eq!(bars.len(), 1, "expected only 1 bar (the isolated one), found {}", bars.len());
        assert!((bars[0].x as i32 - 100).abs() <= 1);
    }

    #[test]
    fn rejects_notehead_proximity() {
        let mut bin = Binary::new(200, 100);
        for line_y in [20u32, 30, 40, 50, 60] {
            for x in 5..195 { bin.set(x, line_y, 1); }
        }
        for y in 20..=60 { bin.set(100, y, 1); }

        let nh = Notehead {
            bbox: omr_core::Rect { x: 95, y: 35, w: 10, h: 8 },
            center: omr_core::Point { x: 100.0, y: 39.0 },
            confidence: 1.0,
            kind: omr_core::NoteheadKind::Filled,
            staff_idx: 0,
        };
        let bars = detect_measure_bars(&bin, &[make_staff()], &[nh]);
        assert_eq!(bars.len(), 0, "Bar-Position mit Notehead daneben muss verworfen werden");
    }
}
