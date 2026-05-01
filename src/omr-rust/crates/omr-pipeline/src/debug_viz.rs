// Debug-Visualizer: zeichne Pipeline-Zwischenergebnisse als farbige Overlays
// auf das Original-Bild zurück. Hilft beim Identifizieren wo die Pipeline
// schief geht.

use image::{Rgb, RgbImage};
use omr_core::{Gray, JumpMark, Measure, Notehead, NoteheadKind, Stem};
use omr_symbols::{Beam, MeasureBar};

const COLOR_NOTEHEAD_FILLED: Rgb<u8> = Rgb([255, 64, 64]);    // rot
const COLOR_NOTEHEAD_OPEN:   Rgb<u8> = Rgb([255, 180, 64]);   // orange
const COLOR_NOTEHEAD_WHOLE:  Rgb<u8> = Rgb([255, 240, 64]);   // gelb
const COLOR_STEM:            Rgb<u8> = Rgb([64, 255, 64]);    // grün
const COLOR_BEAM:            Rgb<u8> = Rgb([64, 200, 255]);   // hellblau
const COLOR_BAR:             Rgb<u8> = Rgb([200, 64, 255]);   // magenta
const COLOR_STAFF:           Rgb<u8> = Rgb([64, 200, 200]);   // cyan
const COLOR_MEASURE_BBOX:    Rgb<u8> = Rgb([100, 255, 100]);  // helles grün — Takt-Bbox
const COLOR_REPEAT:          Rgb<u8> = Rgb([255, 100, 200]);  // pink — Repeat
const COLOR_VOLTA:           Rgb<u8> = Rgb([255, 200, 0]);    // gold — Volta

pub struct Overlays<'a> {
    pub noteheads: &'a [Notehead],
    pub stems: &'a [Stem],
    pub beams: &'a [Beam],
    pub bars: &'a [MeasureBar],
    /// Per-System: Liste der 5 Linien (jede mit y_per_x).
    pub staff_systems_lines: Vec<Vec<Vec<u32>>>,
    /// Optional: Measures für Bbox-Highlight und Sprungmarken-Annotations.
    pub measures: Option<&'a [Measure]>,
}

/// Erzeugt ein RGB-Bild mit Original (in voller Helligkeit) + Overlays als
/// halb-transparente Marker. Originalnotation bleibt klar lesbar, erkannte
/// Symbole werden als farbige Punkte/Linien/Boxes oben drauf gezeichnet.
pub fn render_debug_image(gray: &Gray, ovr: &Overlays) -> RgbImage {
    let (w, h) = (gray.width(), gray.height());
    let mut rgb = RgbImage::new(w, h);

    // Original in voller Helligkeit. Pixels gehen direkt rüber.
    for (x, y, p) in gray.enumerate_pixels() {
        let v = p[0];
        rgb.put_pixel(x, y, Rgb([v, v, v]));
    }

    // Stafflinien hellcyan (alle Systeme)
    for sys_lines in &ovr.staff_systems_lines {
        for line in sys_lines {
            for (x, &y) in line.iter().enumerate() {
                if (x as u32) < w && y < h {
                    rgb.put_pixel(x as u32, y, COLOR_STAFF);
                }
            }
        }
    }

    // Beams (zuerst, damit Noteheads drüber liegen)
    for b in ovr.beams {
        draw_filled_rect(&mut rgb, b.x_start, b.y_top, b.x_end - b.x_start, b.y_bot - b.y_top, COLOR_BEAM, 0.4);
    }

    // Bars — nur über das eigene System!
    for bar in ovr.bars {
        let Some(sys_lines) = ovr.staff_systems_lines.get(bar.system_idx) else { continue; };
        let mut y_top = u32::MAX;
        let mut y_bot = 0u32;
        for line in sys_lines {
            if let Some(&y) = line.get(bar.x as usize) {
                if y > 0 && y < y_top { y_top = y; }
                if y > y_bot { y_bot = y; }
            }
        }
        if y_top == u32::MAX || y_bot <= y_top { continue; }
        for y in y_top.saturating_sub(2)..=(y_bot + 2).min(h - 1) {
            if bar.x < w {
                rgb.put_pixel(bar.x, y, COLOR_BAR);
            }
        }
    }

    // Stems
    for s in ovr.stems {
        draw_vertical_line_thick(&mut rgb, s.x, s.y_top, s.y_bot, COLOR_STEM);
    }

    // Noteheads
    for nh in ovr.noteheads {
        let color = match nh.kind {
            NoteheadKind::Filled => COLOR_NOTEHEAD_FILLED,
            NoteheadKind::Open => COLOR_NOTEHEAD_OPEN,
            NoteheadKind::Whole => COLOR_NOTEHEAD_WHOLE,
        };
        draw_rect_outline(&mut rgb, nh.bbox.x, nh.bbox.y, nh.bbox.w, nh.bbox.h, color);
        // Center-Cross
        let cx = nh.center.x as i32;
        let cy = nh.center.y as i32;
        for d in -3..=3i32 {
            let px = (cx + d).max(0) as u32;
            let py = (cy + d).max(0) as u32;
            if px < w && (cy as u32) < h { rgb.put_pixel(px, cy as u32, color); }
            if (cx as u32) < w && py < h { rgb.put_pixel(cx as u32, py, color); }
        }
    }

    // Measure-Bboxes (Phase A): dünner Rahmen pro Takt
    if let Some(measures) = ovr.measures {
        for m in measures {
            if let Some(bb) = m.bbox_orig {
                let color = if m.jump_marks.iter().any(|j| matches!(j,
                    JumpMark::RepeatStart | JumpMark::RepeatEnd
                )) {
                    COLOR_REPEAT
                } else if m.jump_marks.iter().any(|j| matches!(j,
                    JumpMark::Volta { .. }
                )) {
                    COLOR_VOLTA
                } else {
                    COLOR_MEASURE_BBOX
                };
                draw_rect_outline(&mut rgb, bb.x, bb.y, bb.w, bb.h, color);
            }
        }
    }

    rgb
}

fn draw_rect_outline(img: &mut RgbImage, x: u32, y: u32, w: u32, h: u32, color: Rgb<u8>) {
    let (iw, ih) = (img.width(), img.height());
    for dx in 0..w {
        let xx = x + dx;
        if xx < iw {
            if y < ih { img.put_pixel(xx, y, color); }
            let by = y + h.saturating_sub(1);
            if by < ih { img.put_pixel(xx, by, color); }
        }
    }
    for dy in 0..h {
        let yy = y + dy;
        if yy < ih {
            if x < iw { img.put_pixel(x, yy, color); }
            let rx = x + w.saturating_sub(1);
            if rx < iw { img.put_pixel(rx, yy, color); }
        }
    }
}

fn draw_filled_rect(img: &mut RgbImage, x: u32, y: u32, w: u32, h: u32, color: Rgb<u8>, alpha: f32) {
    let (iw, ih) = (img.width(), img.height());
    for dy in 0..h {
        for dx in 0..w {
            let xx = x + dx;
            let yy = y + dy;
            if xx >= iw || yy >= ih { continue; }
            let p = img.get_pixel(xx, yy);
            let nr = (p[0] as f32 * (1.0 - alpha) + color[0] as f32 * alpha) as u8;
            let ng = (p[1] as f32 * (1.0 - alpha) + color[1] as f32 * alpha) as u8;
            let nb = (p[2] as f32 * (1.0 - alpha) + color[2] as f32 * alpha) as u8;
            img.put_pixel(xx, yy, Rgb([nr, ng, nb]));
        }
    }
}

fn draw_vertical_line(img: &mut RgbImage, x: u32, color: Rgb<u8>) {
    if x >= img.width() { return; }
    for y in 0..img.height() {
        img.put_pixel(x, y, color);
    }
}

fn draw_vertical_line_thick(img: &mut RgbImage, x: u32, y_top: u32, y_bot: u32, color: Rgb<u8>) {
    let (iw, ih) = (img.width(), img.height());
    for y in y_top..=y_bot.min(ih.saturating_sub(1)) {
        for dx in -1..=1i32 {
            let xx = (x as i32 + dx).max(0) as u32;
            if xx < iw { img.put_pixel(xx, y, color); }
        }
    }
}
