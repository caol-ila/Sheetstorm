// Synthetic-Score-Generator für deterministische Pitch- und Detection-Tests.
//
// Erzeugt programmatisch ein Bild eines kleinen Notenbeispiels mit bekannten
// Pitches/Durations. Dadurch können wir die OMR-Pipeline gegen Ground-Truth
// validieren — komplett offline, ohne externe PDF-Dependencies.

use image::{GrayImage, ImageBuffer, Luma};

#[derive(Debug, Clone, Copy)]
pub enum SyntheticNote {
    /// (step_offset_from_top_line_in_half_steps, kind)
    /// Bei Treble: top_line ist F5; offset 0 = F5, +1 = E5 (höher Y), -1 = G5 (niedriger Y).
    /// → wir verwenden die Konvention: `offset = halftones_below_top_line` (positives Y nach unten).
    NoteAt { offset: i32, kind: NoteKind },
}

#[derive(Debug, Clone, Copy)]
pub enum NoteKind {
    Filled,
    Open,
    Whole,
}

pub struct SyntheticScore {
    /// Gewünschtes Bild
    pub image: GrayImage,
    /// Erwartete Notenpositionen, in Reading-Order:
    /// (step, alter, octave) für Vergleich mit OMR-Output.
    pub expected_pitches: Vec<(char, i8, i8)>,
}

/// Generiere eine C-Dur-Tonleiter (C4..C5) als Bild im Treble-Schlüssel.
pub fn c_major_scale_treble() -> SyntheticScore {
    // Bild-Layout:
    //   Höhe = 200, Breite = 600
    //   Stafflinien: y = 60, 75, 90, 105, 120 (spacing=15)
    //   8 Notenköpfe: x = 80, 130, 180, 230, 280, 330, 380, 430
    //   Pitches: C4, D4, E4, F4, G4, A4, B4, C5
    //
    // Treble: top line F5 → spacing=15 → wir berechnen die Y-Position
    // jedes Notenkopfs aus seiner halftones-below-top-line.
    //
    // C4 = 8 halftones (= 4 spaces) below top_line F5 → y = 60 + 8*7.5 = 120 (bottom line)
    // Genauer: F5 ist top_line (y=60). E5=1, D5=2, C5=3, B4=4, A4=5, G4=6, F4=7, E4=8, D4=9, C4=10
    // halftones below.
    let w: u32 = 600;
    let h: u32 = 200;
    let top_y = 60u32;
    let spacing = 15.0_f32;
    let mut img = ImageBuffer::from_pixel(w, h, Luma([255u8]));

    // Stafflinien (5 Linien, 2px dick)
    for i in 0..5u32 {
        let y = top_y + (i as f32 * spacing) as u32;
        for x in 30..(w - 30) {
            for ty in 0..2u32 {
                if y + ty < h { img.put_pixel(x, y + ty, Luma([0])); }
            }
        }
    }

    // Treble-Schlüssel (Pseudo: 4 Vertical-Strokes + Hook)
    draw_treble_clef(&mut img, 35, top_y, spacing as u32);

    let pitches = [
        ('C', 4, 10), // C4: 10 halftones below F5
        ('D', 4, 9),
        ('E', 4, 8),
        ('F', 4, 7),
        ('G', 4, 6),
        ('A', 4, 5),
        ('B', 4, 4),
        ('C', 5, 3),
    ];

    let mut expected = Vec::new();
    let nh_w = (spacing * 1.3) as u32;
    let nh_h = (spacing * 0.95) as u32;
    for (i, &(step, octave, halftones_below)) in pitches.iter().enumerate() {
        let center_x = 80 + i as u32 * 50;
        let center_y = top_y as f32 + halftones_below as f32 * (spacing * 0.5);
        let nh_x = center_x.saturating_sub(nh_w / 2);
        let nh_y = (center_y as u32).saturating_sub(nh_h / 2);
        // Gefüllter Notenkopf (Filled-Ellipse)
        draw_filled_ellipse(&mut img, nh_x, nh_y, nh_w, nh_h);
        // Stem nach oben (für Pitches unter Linie B4 ist Stem-up Standard)
        let stem_x = nh_x + nh_w - 1;
        let stem_top = nh_y.saturating_sub((spacing * 2.5) as u32);
        for y in stem_top..nh_y {
            for tx in 0..2u32 {
                if stem_x + tx < w {
                    img.put_pixel(stem_x + tx, y, Luma([0]));
                }
            }
        }
        expected.push((step, 0i8, octave as i8));
    }
    let _ = expected.clone();

    SyntheticScore {
        image: img,
        expected_pitches: pitches.iter().map(|&(s, o, _)| (s, 0i8, o as i8)).collect(),
    }
}

fn draw_filled_ellipse(img: &mut GrayImage, x: u32, y: u32, w: u32, h: u32) {
    let cx = x as f32 + w as f32 / 2.0;
    let cy = y as f32 + h as f32 / 2.0;
    let rx = w as f32 / 2.0;
    let ry = h as f32 / 2.0;
    for dy in 0..h {
        for dx in 0..w {
            let xx = x + dx;
            let yy = y + dy;
            if xx >= img.width() || yy >= img.height() { continue; }
            let nx = (xx as f32 + 0.5 - cx) / rx;
            let ny = (yy as f32 + 0.5 - cy) / ry;
            if nx * nx + ny * ny <= 1.0 {
                img.put_pixel(xx, yy, Luma([0]));
            }
        }
    }
}

fn draw_treble_clef(img: &mut GrayImage, x_start: u32, top_y: u32, spacing: u32) {
    // Vereinfachter Treble-Schlüssel: ein "G"-Symbol das von oben weit über das
    // System hinausragt + unten hinab. Hauptbeitrag: vertikale Linie.
    let h = spacing * 8;
    let cx = x_start;
    let top = top_y.saturating_sub(spacing);
    let bot = top + h;

    // Vertikale Mittellinie, 2-3 px breit
    for y in top..=bot.min(img.height() - 1) {
        for tx in 0..3u32 {
            if cx + tx < img.width() {
                img.put_pixel(cx + tx, y, Luma([0]));
            }
        }
    }

    // Schleife oben (Halbkreis von cx..cx+spacing*1.5)
    let loop_y = top + spacing;
    let loop_r = spacing as i32;
    let center_x = cx as i32 + loop_r;
    let center_y = loop_y as i32 + loop_r / 2;
    for angle_deg in 0..360 {
        let rad = (angle_deg as f32).to_radians();
        let px = (center_x as f32 + (loop_r as f32) * rad.cos()) as i32;
        let py = (center_y as f32 + (loop_r as f32 * 0.6) * rad.sin()) as i32;
        if px >= 0 && py >= 0 && (px as u32) < img.width() && (py as u32) < img.height() {
            img.put_pixel(px as u32, py as u32, Luma([0]));
        }
    }
}

/// Erzeuge einen verrauschten Score (mit Salt-and-Pepper-Noise + Gauss-Blur).
pub fn add_scanner_noise(img: &GrayImage, noise_level: f32) -> GrayImage {
    let (w, h) = (img.width(), img.height());
    let mut out = img.clone();

    // Salt-and-Pepper-Noise
    let mut state = 12345u64;
    for y in 0..h {
        for x in 0..w {
            state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            let r = (state >> 32) as u32 & 0xFFFF;
            let f = r as f32 / 65535.0;
            if f < noise_level {
                let val = if (state & 1) == 0 { 0u8 } else { 255u8 };
                out.put_pixel(x, y, Luma([val]));
            }
        }
    }
    // Light Gauss-Blur (3x3) für JPEG-/Scanner-Smearing
    imageproc::filter::gaussian_blur_f32(&out, 0.8)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn synthetic_scale_has_8_notes() {
        let s = c_major_scale_treble();
        assert_eq!(s.expected_pitches.len(), 8);
        assert_eq!(s.expected_pitches[0].0, 'C');
        assert_eq!(s.expected_pitches[7].0, 'C');
    }

    #[test]
    fn synthetic_image_has_dark_pixels() {
        let s = c_major_scale_treble();
        let dark_count = s.image.pixels().filter(|p| p[0] < 100).count();
        assert!(dark_count > 100, "expected lots of dark pixels for noteheads + lines");
    }
}
