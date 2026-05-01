//! Ledger-Line-Detection für hohe/tiefe Noten außerhalb der 5 Stafflinien.
//!
//! Hilfslinien (Ledger-Lines) sind kurze horizontale Linien, die für Noten
//! ÜBER oder UNTER der 5-Linien-Staff gezeichnet werden. Beispiel:
//! - C5 (Tenor-Schluessel): unter dem Notensystem auf einer Hilfslinie
//! - Hohe G5+: Hilfslinien über dem System
//!
//! Die Pipeline berechnet Pitch derzeit via Y-Distance-Extrapolation. Bei
//! schiefem Papier oder verzerrter Y-Achse kann das aber fehlerhaft sein.
//! Wenn wir die echten Ledger-Lines detektieren, bekommen wir eine
//! kalibrierte Y-Position für die NH und damit korrekteren Pitch.
//!
//! Algorithmus:
//! 1. Pro NH außerhalb der 5 Staff-Linien (NH.center.y < top_line - 0.7*spacing
//!    oder > bot_line + 0.7*spacing):
//!    a. Suche horizontale Linie in der Y-Position der NH (±0.4*spacing)
//!    b. Linien-Länge muss >= 1.5 * spacing breit sein (durch die NH gehend)
//!    c. Darf NICHT Stem oder Beam sein (zu lang oder zu schmal)
//! 2. Wenn Ledger-Line gefunden: notiere die echte Y-Position dieser Linie
//!    als kalibrierte Pitch-Anchor.

use omr_core::{Binary, Notehead, StaffSystem};

/// Ergebnis pro NH: bekommt eine "kalibrierte" Y-Position basierend auf der
/// gefundenen Ledger-Line, oder None falls keine ledger-line gefunden / unnötig.
#[derive(Debug, Clone, Copy)]
pub struct LedgerInfo {
    pub note_idx: usize,
    /// Y-Position der gefundenen Ledger-Line (gemessen, statt extrapoliert)
    pub ledger_y: u32,
    /// Anzahl Ledger-Lines zwischen Staff und dieser Note (1 = 1 Hilfslinie,
    /// 2 = 2 Hilfslinien, etc). Hilft bei Pitch-Disambiguierung.
    pub ledger_count: u8,
}

pub fn detect_ledger_lines(
    bin: &Binary,
    noteheads: &[Notehead],
    systems: &[StaffSystem],
) -> Vec<LedgerInfo> {
    let mut results = Vec::new();
    for (i, nh) in noteheads.iter().enumerate() {
        let staff = match systems.get(nh.staff_idx) { Some(s) => s, None => continue };
        let spacing = staff.line_spacing;
        let cx = nh.center.x as u32;
        let cy = nh.center.y as i32;

        let top_y = staff.lines.first()
            .and_then(|l| l.y_per_x.get(cx as usize).copied())
            .unwrap_or_else(|| staff.lines[0].mean_y() as u32) as i32;
        let bot_y = staff.lines.last()
            .and_then(|l| l.y_per_x.get(cx as usize).copied())
            .unwrap_or_else(|| staff.lines[4].mean_y() as u32) as i32;

        // Nur NHs außerhalb der Staff brauchen Ledger-Lines
        let above_staff = cy < top_y - (spacing * 0.7) as i32;
        let below_staff = cy > bot_y + (spacing * 0.7) as i32;
        if !above_staff && !below_staff { continue; }

        // Suche horizontale Linien in einem schmalen Y-Range um die NH
        // (±0.5 spacing). Eine Ledger-Line ist 1-2*spacing breit (durch NH gehend).
        let search_y_range = (spacing * 0.5) as i32;
        let line_min_w = (spacing * 1.0) as u32;
        let line_max_w = (spacing * 3.0) as u32;
        let search_x_half = (spacing * 1.5) as u32;
        let x0 = cx.saturating_sub(search_x_half);
        let x1 = (cx + search_x_half).min(bin.w);

        let mut best_y: Option<u32> = None;
        let mut best_score: u32 = 0;

        for dy in -search_y_range..=search_y_range {
            let y = (cy + dy).max(0) as u32;
            if y >= bin.h { continue; }
            // Zähle horizontale schwarze Pixel in dieser Reihe (continuous run)
            let mut max_run = 0u32;
            let mut current_run = 0u32;
            for x in x0..x1 {
                if bin.get(x, y) != 0 {
                    current_run += 1;
                    if current_run > max_run { max_run = current_run; }
                } else {
                    current_run = 0;
                }
            }
            if max_run >= line_min_w && max_run <= line_max_w {
                if max_run > best_score {
                    best_score = max_run;
                    best_y = Some(y);
                }
            }
        }

        if let Some(y) = best_y {
            // Anzahl der Hilfslinien: distance / spacing
            let dist = if above_staff {
                (top_y - y as i32).max(0) as f32 / spacing
            } else {
                (y as i32 - bot_y).max(0) as f32 / spacing
            };
            let ledger_count = (dist.round() as u32).max(1) as u8;
            results.push(LedgerInfo { note_idx: i, ledger_y: y, ledger_count });
        }
    }
    results
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
    fn detect_ledger_above_staff() {
        // Staff bei y=100..172 (5 lines, spacing 18). NH bei y=80 (über Staff).
        // Ledger-Line bei y=80, ~30px breit (durch NH gehend)
        let mut bin = mk_bin(400, 300);
        for x in 90..120 { put_pixel(&mut bin, x, 80); }
        let system = mk_system(100, 18);
        let nhs = vec![mk_nh(105.0, 80.0)];
        let res = detect_ledger_lines(&bin, &nhs, &[system]);
        assert_eq!(res.len(), 1, "expected 1 ledger-line detection");
        assert_eq!(res[0].ledger_y, 80);
    }

    #[test]
    fn no_ledger_for_inside_staff() {
        let mut bin = mk_bin(400, 300);
        for x in 90..120 { put_pixel(&mut bin, x, 130); } // innerhalb staff
        let system = mk_system(100, 18);
        let nhs = vec![mk_nh(105.0, 130.0)];
        let res = detect_ledger_lines(&bin, &nhs, &[system]);
        // NH innerhalb staff → keine ledger-line erwartet
        assert_eq!(res.len(), 0);
    }
}
