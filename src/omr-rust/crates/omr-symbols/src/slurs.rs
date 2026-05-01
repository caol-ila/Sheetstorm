//! Slur-/Tie-Detection.
//!
//! Strategie:
//!   1. Suche im Binary (vor Staff-Removal — Slurs überlappen Stafflinien)
//!      Connected-Components mit "Bogen-Profil":
//!        - Breit: w > 1.5 × spacing
//!        - Kurz:  h < 0.6 × spacing
//!        - Y-Profil hat Maximum/Minimum in der Mitte (gewölbt)
//!   2. Klassifiziere als Slur-above (Konvex nach oben über Notes) oder
//!      Slur-below (Konvex nach unten unter Notes).
//!   3. Matching: Endpunkte mit nächst-gelegenen NHs auf der gleichen Staff
//!      verbinden (links + rechts).
//!
//! Output: `Slur { start_nh_idx, end_nh_idx, above, bbox }`
//!
//! Tie vs Slur:
//!   - Tie verbindet zwei NHs der gleichen Tonhöhe (gleicher MIDI)
//!   - Slur verbindet beliebige NHs
//!   - Wir emittieren bei gleichem MIDI als Tie, sonst Slur
//!
//! Phase 1 fokussiert auf reine Bbox-Detection ohne strikte Curve-Analyse.

use crate::cc::connected_components;
use omr_core::{Binary, Notehead, Rect, StaffSystem};
use serde::Serialize;

/// Erkannter Slur oder Tie.
#[derive(Debug, Clone, Serialize)]
pub struct Slur {
    pub bbox: Rect,
    /// Index in NH-Array von `noteheads` (oder None falls kein Match).
    pub start_nh_idx: Option<usize>,
    pub end_nh_idx: Option<usize>,
    /// True wenn Bogen ÜBER der Notenreihe sitzt (= Slur unter NH-Seite ist
    /// nach unten konvex). Über = "unten" mit Stem-Ende, "oben" mit NH-Top.
    pub above: bool,
    /// True wenn vermutlich Tie (gleicher MIDI an Endpunkten).
    pub is_tie: bool,
    pub system_idx: usize,
}

/// Detektiert Slurs/Ties in einem Binary.
///
/// Args:
///   - `bin`: Original-Binary VOR Staff-Removal (Slurs überqueren Stafflinien).
///   - `noteheads`: Detektierte NHs für Endpoint-Matching.
///   - `systems`: StaffSystems für Spacing + Y-Bereiche.
pub fn detect_slurs(bin: &Binary, noteheads: &[Notehead], systems: &[StaffSystem]) -> Vec<Slur> {
    if systems.is_empty() {
        return Vec::new();
    }
    let spacing = systems[0].line_spacing;

    // Slur-Bbox-Constraints
    let min_w = (spacing * 1.5) as u32;
    let max_w = (spacing * 25.0) as u32;
    let min_h = (spacing * 0.05).max(2.0) as u32;
    let max_h = (spacing * 0.8) as u32;

    let ccs = connected_components(bin);
    let mut slurs: Vec<Slur> = Vec::new();

    for cc in &ccs {
        let bb = cc.bbox;
        if bb.w < min_w || bb.w > max_w { continue; }
        if bb.h < min_h || bb.h > max_h { continue; }
        let aspect = bb.aspect();
        if aspect < 3.0 { continue; } // Slurs sind sehr-wide
        if aspect > 30.0 { continue; } // zu lange Striche → Beam oder Stem-row

        // Curve-Test: Y-Profil sollte ein klares Min/Max in der Mitte haben.
        // Wir nehmen die obere Y-Kante über der Bbox: für jeden X innerhalb
        // der Bbox, ist der höchste schwarze Pixel an Position y_top(x).
        // Bei einer konvex-nach-oben Slur (above=true) ist y_top minimum in
        // der Mitte.
        if !is_arc_shaped(bin, &bb) { continue; }

        // Welches System?
        let cy = bb.y as f32 + bb.h as f32 * 0.5;
        let mut best_sys = 0usize;
        let mut best_dist = f32::INFINITY;
        for (i, s) in systems.iter().enumerate() {
            let mid = s.middle_y();
            let d = (mid - cy).abs();
            if d < best_dist { best_dist = d; best_sys = i; }
        }

        // Above-System (above=true) wenn cy < system.middle_y - spacing.
        // Below-System (above=false) wenn cy > system.middle_y + spacing.
        let staff = &systems[best_sys];
        let above = cy < staff.middle_y() - spacing * 0.5;

        // Endpunkt-Matching: links und rechts in same-system NHs suchen
        let left_x = bb.x as f32;
        let right_x = (bb.x + bb.w) as f32;
        let start_idx = nearest_nh(noteheads, best_sys, left_x, spacing);
        let end_idx = nearest_nh(noteheads, best_sys, right_x, spacing);

        // Wenn beide Endpunkte einen Notehead haben → echter Slur
        if start_idx.is_none() && end_idx.is_none() { continue; }

        // Tie-Detection: gleicher MIDI nicht möglich auf Notehead-Ebene
        // (NH hat keine MIDI-Info). Wir setzen is_tie=false und überlassen
        // die Tie-Tagging dem Score-Builder.
        let is_tie = false;

        slurs.push(Slur {
            bbox: bb,
            start_nh_idx: start_idx,
            end_nh_idx: end_idx,
            above,
            is_tie,
            system_idx: best_sys,
        });
    }

    slurs
}

fn is_arc_shaped(bin: &Binary, bb: &Rect) -> bool {
    // Sample ~10 X-Positionen über die Breite und finde y_top für jede.
    let w = bb.w;
    if w < 10 { return false; }
    let n_samples = 10u32;
    let step = (w / n_samples).max(1);

    let mut tops: Vec<i32> = Vec::with_capacity(n_samples as usize);
    for k in 0..n_samples {
        let x = bb.x + k * step;
        if x >= bin.w { break; }
        let mut y_top: Option<u32> = None;
        for y in bb.y..(bb.y + bb.h).min(bin.h) {
            if bin.get(x, y) != 0 {
                y_top = Some(y);
                break;
            }
        }
        if let Some(yt) = y_top {
            tops.push(yt as i32);
        }
    }
    if tops.len() < 5 { return false; }

    // Curve-Test: Mitte ist signifikant höher (= y kleiner) ODER niedriger
    // (= y größer) als beide Enden.
    let n = tops.len();
    let left_avg = (tops[0] + tops[1]) as f32 * 0.5;
    let right_avg = (tops[n - 1] + tops[n - 2]) as f32 * 0.5;
    let mid = tops[n / 2] as f32;
    // Slur-above: y_top in Mitte < links und rechts (= Bogen schwingt nach oben)
    // Slur-below: y_top in Mitte > links und rechts (= Bogen schwingt nach unten)
    let curve_amp = (left_avg + right_avg) * 0.5 - mid; // Positiv = above, Negativ = below
    curve_amp.abs() > (bb.h as f32 * 0.3)
}

fn nearest_nh(noteheads: &[Notehead], system_idx: usize, x_target: f32, spacing: f32) -> Option<usize> {
    let max_dx = spacing * 1.5;
    let mut best: Option<usize> = None;
    let mut best_dx = max_dx;
    for (i, nh) in noteheads.iter().enumerate() {
        if nh.staff_idx != system_idx { continue; }
        let dx = (nh.center.x - x_target).abs();
        if dx < best_dx {
            best_dx = dx;
            best = Some(i);
        }
    }
    best
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{NoteheadKind, Point, StaffLine};

    fn mk_bin(w: u32, h: u32) -> Binary {
        Binary { w, h, data: vec![0u8; (w * h) as usize] }
    }

    fn put_pixel(bin: &mut Binary, x: u32, y: u32) {
        if x < bin.w && y < bin.h {
            let idx = (y * bin.w + x) as usize;
            bin.data[idx] = 1;
        }
    }

    fn mk_arc_above(bin: &mut Binary, x0: u32, y_apex: u32, w: u32, depth: u32) {
        // Parabolic arc from (x0, y_apex+depth) → apex at (x0+w/2, y_apex) → (x0+w, y_apex+depth).
        for k in 0..w {
            let t = (k as f32 - w as f32 * 0.5) / (w as f32 * 0.5);
            // y = y_apex + depth * t^2
            let dy = depth as f32 * t * t;
            let y = y_apex + dy as u32;
            put_pixel(bin, x0 + k, y);
            put_pixel(bin, x0 + k, y.saturating_sub(1));
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

    fn mk_nh(staff_idx: usize, x: f32, y: f32) -> Notehead {
        Notehead {
            bbox: Rect { x: (x as u32).saturating_sub(8), y: (y as u32).saturating_sub(8), w: 16, h: 16 },
            center: Point { x, y },
            confidence: 0.9, kind: NoteheadKind::Filled, staff_idx,
        }
    }

    #[test]
    fn detect_simple_arc_above_two_nhs() {
        let mut bin = mk_bin(400, 300);
        // Stafflinien bei y=100..172 (5 lines, spacing 18)
        let system = mk_system(100, 18);
        // Zwei NHs auf Linie 0 (y=100), getrennt durch 80px in X
        let nhs = vec![
            mk_nh(0, 100.0, 100.0),
            mk_nh(0, 180.0, 100.0),
        ];
        // Slur ÜBER den NHs: Apex bei y=80 (über Linie 0), Bogen-Endpunkte bei 100/180
        mk_arc_above(&mut bin, 100, 80, 80, 12);
        let slurs = detect_slurs(&bin, &nhs, &[system]);
        assert!(!slurs.is_empty(), "expected at least 1 slur to be detected");
        // Endpoints sollten beide gematcht sein
        let s = &slurs[0];
        assert!(s.start_nh_idx.is_some() && s.end_nh_idx.is_some(),
                "expected both endpoints matched, got start={:?} end={:?}",
                s.start_nh_idx, s.end_nh_idx);
        assert!(s.above, "expected slur above");
    }

    #[test]
    fn reject_horizontal_line_as_slur() {
        let mut bin = mk_bin(400, 300);
        let system = mk_system(100, 18);
        // Reine horizontale Linie (kein Bogen)
        for x in 100..180 {
            put_pixel(&mut bin, x, 80);
            put_pixel(&mut bin, x, 81);
        }
        let nhs = vec![mk_nh(0, 100.0, 100.0), mk_nh(0, 180.0, 100.0)];
        let slurs = detect_slurs(&bin, &nhs, &[system]);
        assert!(slurs.is_empty(), "horizontal line should not be detected as slur, got {:?}", slurs);
    }
}
