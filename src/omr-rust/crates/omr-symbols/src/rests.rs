// Pausen-Detection: Whole- und Half-Rest sind kleine schwarze Rechtecke,
// die je nach Y-Position auf der Stafflinie als Whole oder Half klassifiziert
// werden. Quarter-Rest, Eighth-Rest etc. sind komplexere Glyphen und werden
// in einer späteren Iteration unterstützt (Template-Matching auf Bravura).
//
// Whole-Rest hängt UNTER Linie 4 (zwischen Linie 4 und 5 von oben gezählt,
// d.h. zwischen 2. und 3. Linie von unten).
// Half-Rest sitzt OBEN auf Linie 3 (mittlere Linie).
//
// Beide Rests sind ähnliche Rechtecke (Breite ≈ 1 spacing, Höhe ≈ 0.4 spacing).

use omr_core::{Binary, Point, Rect, StaffSystem};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RestKind {
    Whole,
    Half,
    Quarter,
    Eighth,
    Sixteenth,
}

impl RestKind {
    /// Duration in MusicXML-Ticks (divisions=4 → Quarter=4 Ticks).
    pub fn duration(self) -> u32 {
        match self {
            RestKind::Whole => 16,
            RestKind::Half => 8,
            RestKind::Quarter => 4,
            RestKind::Eighth => 2,
            RestKind::Sixteenth => 1,
        }
    }
}

#[derive(Debug, Clone)]
pub struct Rest {
    pub center: Point<f32>,
    pub bbox: Rect,
    pub kind: RestKind,
    pub staff_idx: usize,
}

/// Detektiert Whole-/Half-Rests im Original-Binary (vor Staff-Removal).
///
/// Wichtig: Wir nutzen das Original-Binary statt removed, weil Whole-Rest
/// direkt UNTER Linie 4 sitzt und beim Staff-Removal teilweise abgeschnitten
/// wird (z.B. wenn das Rest-Rechteck Linie 4 berührt → entfernt).
///
/// Algorithmus:
/// 1. Pro Stafflinie-System: bestimme Y-Range der Stafflinien.
/// 2. Suche kleine CCs (0.6-1.6 spacing breit, 0.18-0.7 spacing hoch).
/// 3. Klassifiziere nach Y-Position relative zu Linie 3/4:
///    - bbox.bottom auf Linie 3 → Half-Rest
///    - bbox.top auf Linie 4 → Whole-Rest
/// 4. Filter: bbox.x muss in der Staff-X-Range liegen, und keine NH-Position überlappen.
pub fn detect_rests(bin: &Binary, systems: &[StaffSystem]) -> Vec<Rest> {
    let mut rests = Vec::new();
    if systems.is_empty() {
        return rests;
    }
    let spacing = systems[0].line_spacing;
    let min_w = ((spacing * 0.45) as u32).max(4);
    let max_w = ((spacing * 1.8) as u32).max(8);
    let min_h = ((spacing * 0.16) as u32).max(2);
    let max_h = ((spacing * 0.75) as u32).max(4);
    if min_w == 0 || min_h == 0 {
        return rests;
    }

    // Wir nehmen ein "Stafflinien-removed" Lokal-Bild zur CC-Findung,
    // damit die Stafflinien selbst nicht zu großen CCs verschmelzen,
    // aber das Rest-Rechteck NICHT entfernt wird.
    let bin_no_lines = remove_horizontal_runs_only(bin, systems, spacing);

    let visited = std::cell::RefCell::new(vec![false; (bin.w * bin.h) as usize]);

    for (sys_idx, sys) in systems.iter().enumerate() {
        if sys.lines.len() < 5 {
            continue;
        }
        let line3_y = mean_y(&sys.lines[2].y_per_x);
        let line4_y = mean_y(&sys.lines[3].y_per_x);
        let line5_y = mean_y(&sys.lines[4].y_per_x);

        // Whole-Rest hängt zwischen Linie 4 und Linie 5: bbox.top zwischen line4 und line4+spacing/3
        let whole_top_min = line4_y.saturating_sub((spacing * 0.10) as u32);
        let whole_top_max = line4_y + (spacing * 0.45) as u32;

        // Half-Rest sitzt zwischen Linie 3 und Linie 2: bbox.bot zwischen line3-spacing/3 und line3
        let half_bot_min = line3_y.saturating_sub((spacing * 0.10) as u32);
        let half_bot_max = line3_y + (spacing * 0.45) as u32;

        let staff_top = mean_y(&sys.lines[0].y_per_x).saturating_sub((spacing * 1.2) as u32);
        let staff_bot = line5_y + (spacing * 1.2) as u32;
        let staff_x_start = sys.lines[0].y_per_x.iter().position(|&y| y > 0).unwrap_or(0) as u32;
        let staff_x_end = sys.lines[0].y_per_x.iter().rposition(|&y| y > 0).unwrap_or(bin.w as usize - 1) as u32;

        for y in staff_top..staff_bot.min(bin.h) {
            for x in staff_x_start..staff_x_end.min(bin.w) {
                if bin_no_lines.get(x, y) != 1 {
                    continue;
                }
                let idx = (y * bin.w + x) as usize;
                if visited.borrow()[idx] {
                    continue;
                }
                let bbox = flood_fill_bbox(&bin_no_lines, x, y, &visited);
                if bbox.w < min_w || bbox.w > max_w || bbox.h < min_h || bbox.h > max_h {
                    continue;
                }
                if bbox.h >= bbox.w {
                    continue;
                }
                // Density-Check: Rest-Rechteck ist solide gefüllt (>50% Pixel)
                let density = count_pixels_in_bbox(&bin_no_lines, &bbox) as f32
                    / (bbox.w * bbox.h).max(1) as f32;
                if density < 0.45 {
                    continue;
                }

                let bbox_top = bbox.y;
                let bbox_bot = bbox.y + bbox.h;
                let kind = if bbox_bot >= half_bot_min && bbox_bot <= half_bot_max {
                    RestKind::Half
                } else if bbox_top >= whole_top_min && bbox_top <= whole_top_max {
                    RestKind::Whole
                } else {
                    continue;
                };

                let cx = bbox.x as f32 + bbox.w as f32 / 2.0;
                let cy = bbox.y as f32 + bbox.h as f32 / 2.0;
                rests.push(Rest {
                    center: Point { x: cx, y: cy },
                    bbox,
                    kind,
                    staff_idx: sys_idx,
                });
            }
        }
    }
    rests
}

/// Entfernt nur lange horizontale Runs (Stafflinien), behält aber alle anderen
/// Pixel — inkl. Whole-/Half-Rests die auf Stafflinien aufsitzen.
fn remove_horizontal_runs_only(bin: &Binary, systems: &[StaffSystem], spacing: f32) -> Binary {
    let mut result = Binary::new(bin.w, bin.h);
    result.data.copy_from_slice(&bin.data);
    let max_thickness = ((spacing * 0.30) as u32).max(2);
    for sys in systems {
        for line in &sys.lines {
            for (x, &y_center) in line.y_per_x.iter().enumerate() {
                if y_center == 0 || y_center >= bin.h {
                    continue;
                }
                let mut top = y_center;
                while top > 0 && bin.get(x as u32, top - 1) == 1 {
                    top -= 1;
                    if y_center.saturating_sub(top) > max_thickness {
                        break;
                    }
                }
                let mut bot = y_center;
                while bot + 1 < bin.h && bin.get(x as u32, bot + 1) == 1 {
                    bot += 1;
                    if bot.saturating_sub(y_center) > max_thickness {
                        break;
                    }
                }
                let thickness = bot - top + 1;
                if thickness <= max_thickness {
                    for y in top..=bot {
                        result.set(x as u32, y, 0);
                    }
                }
            }
        }
    }
    result
}

fn count_pixels_in_bbox(bin: &Binary, bbox: &Rect) -> u32 {
    let mut count = 0;
    for y in bbox.y..(bbox.y + bbox.h).min(bin.h) {
        for x in bbox.x..(bbox.x + bbox.w).min(bin.w) {
            if bin.get(x, y) == 1 {
                count += 1;
            }
        }
    }
    count
}

fn mean_y(y_per_x: &[u32]) -> u32 {
    let valid: Vec<u32> = y_per_x.iter().copied().filter(|&y| y > 0).collect();
    if valid.is_empty() {
        return 0;
    }
    (valid.iter().sum::<u32>() / valid.len() as u32) as u32
}

fn flood_fill_bbox(
    bin: &Binary,
    sx: u32,
    sy: u32,
    visited: &std::cell::RefCell<Vec<bool>>,
) -> Rect {
    let mut stack = vec![(sx, sy)];
    let mut x_min = sx;
    let mut x_max = sx;
    let mut y_min = sy;
    let mut y_max = sy;
    let mut count = 0u32;
    let cap = 500u32; // Sicherheits-Cap für übergroße CCs (skip rest if too big)

    while let Some((x, y)) = stack.pop() {
        let idx = (y * bin.w + x) as usize;
        {
            let mut v = visited.borrow_mut();
            if v[idx] {
                continue;
            }
            v[idx] = true;
        }
        if bin.get(x, y) != 1 {
            continue;
        }
        count += 1;
        if count > cap {
            return Rect {
                x: x_min,
                y: y_min,
                w: cap + 100,
                h: cap + 100,
            }; // dummy oversize → wird gefiltert
        }
        x_min = x_min.min(x);
        x_max = x_max.max(x);
        y_min = y_min.min(y);
        y_max = y_max.max(y);
        if x > 0 {
            stack.push((x - 1, y));
        }
        if x + 1 < bin.w {
            stack.push((x + 1, y));
        }
        if y > 0 {
            stack.push((x, y - 1));
        }
        if y + 1 < bin.h {
            stack.push((x, y + 1));
        }
    }

    Rect {
        x: x_min,
        y: y_min,
        w: x_max - x_min + 1,
        h: y_max - y_min + 1,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::StaffLine;

    fn make_staff(line_ys: &[u32], w: u32) -> StaffSystem {
        StaffSystem {
            lines: line_ys
                .iter()
                .map(|&y| StaffLine {
                    y_per_x: (0..w).map(|_| y).collect(),
                })
                .collect(),
            line_spacing: 12.0,
            line_thickness: 2.0,
        }
    }

    #[test]
    fn detect_whole_rest_below_line4() {
        let mut bin = Binary::new(200, 100);
        // Lines bei y=20,32,44,56,68 (spacing=12)
        // Whole-Rest hängt UNTER Linie 4 (y=56), zwischen 56 und 62
        // Position: x=100, ein 12px breites, 4px hohes Rechteck bei y=56
        for y in 56..=60 {
            for x in 100..=111 {
                bin.set(x, y, 1);
            }
        }
        let sys = make_staff(&[20, 32, 44, 56, 68], 200);
        let rests = detect_rests(&bin, &[sys]);
        assert!(!rests.is_empty(), "should detect at least 1 rest");
        assert_eq!(rests[0].kind, RestKind::Whole);
    }

    #[test]
    fn detect_half_rest_above_line3() {
        let mut bin = Binary::new(200, 100);
        // Half-Rest sitzt OBEN auf Linie 3 (y=44), zwischen 38 und 44
        for y in 39..=43 {
            for x in 100..=111 {
                bin.set(x, y, 1);
            }
        }
        let sys = make_staff(&[20, 32, 44, 56, 68], 200);
        let rests = detect_rests(&bin, &[sys]);
        assert!(!rests.is_empty(), "should detect at least 1 rest");
        assert_eq!(rests[0].kind, RestKind::Half);
    }

    #[test]
    fn ignores_too_small() {
        let mut bin = Binary::new(200, 100);
        // 2x2 px ist zu klein für rest
        for y in 56..=57 {
            for x in 100..=101 {
                bin.set(x, y, 1);
            }
        }
        let sys = make_staff(&[20, 32, 44, 56, 68], 200);
        let rests = detect_rests(&bin, &[sys]);
        assert!(rests.is_empty());
    }
}
