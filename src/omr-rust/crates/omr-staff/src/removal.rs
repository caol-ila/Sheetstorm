// Staff-Line Removal — Run-Length-basiert (klassisch).
//
// Strategie: für jede Linie y_per_x, betrachte vertikale Runs der Länge
// `<= line_thickness + 2`, die das y-Pixel kreuzen. Solche Runs gehören
// zur Linie und werden gelöscht. Längere Runs (z.B. Stems) bleiben.

use omr_core::{Binary, StaffSystem};

pub fn remove_staff(bin: &Binary, systems: &[StaffSystem]) -> Binary {
    let mut out = Binary {
        w: bin.w,
        h: bin.h,
        data: bin.data.clone(),
    };
    if systems.is_empty() { return out; }

    let max_thick = systems
        .iter()
        .map(|s| s.line_thickness as u32)
        .max()
        .unwrap_or(2)
        .max(1);
    // Toleranz: Linien dürfen bis 2x Stärke breit sein bevor wir sie als
    // potenziellen Stem stehen lassen. Stems sind in der Regel viel länger
    // (≥ 0.5 * Spacing).

    for sys in systems {
        let max_remove_len = max_thick + 4;
        for line in &sys.lines {
            for (x, &y) in line.y_per_x.iter().enumerate() {
                let x = x as u32;
                if y >= bin.h { continue; }
                // Vertikalen Run um (x, y) ermitteln.
                let mut top = y;
                while top > 0 && out.get(x, top - 1) == 1 { top -= 1; }
                let mut bot = y;
                while bot + 1 < bin.h && out.get(x, bot + 1) == 1 { bot += 1; }
                let run_len = bot - top + 1;
                if run_len <= max_remove_len {
                    for yy in top..=bot {
                        out.set(x, yy, 0);
                    }
                }
            }
        }
    }
    out
}
