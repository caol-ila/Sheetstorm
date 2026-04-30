// Deskewing über horizontale Projektion + Auto-Rotation-Detection.
//
// Strategie:
//   1) Auto-Rotation: prüfe ob Stafflinien horizontal oder vertikal sind.
//      Wenn vertikal (höhere column-density-Varianz als row-density), rotiere um 90°.
//   2) Feine Rotation in [-5°, +5°] über Density-Variance-Maximierung.

use image::GrayImage;
use omr_core::Binary;

/// Rotiere `gray` so dass Stafflinien horizontal sind und korrigiere kleine Schräglage.
/// Gibt das Output-Bild + den korrigierten Winkel in Grad (incl. 90°-Schritte).
pub fn deskew(gray: &GrayImage) -> (GrayImage, f32) {
    // Schritt 1: Coarse-Rotation (0/90/180/270)
    let coarse_angle = detect_coarse_rotation(gray);
    let pre = if coarse_angle != 0 {
        rotate_90_steps(gray, coarse_angle)
    } else {
        gray.clone()
    };

    // Schritt 2: Feine Drehung
    let (best_angle, _) = find_best_angle(&pre, -5.0, 5.0, 0.5);
    let refined = if best_angle.abs() > 0.1 {
        let (a, _) = find_best_angle(&pre, best_angle - 0.5, best_angle + 0.5, 0.1);
        a
    } else { best_angle };
    if refined.abs() < 0.05 {
        return (pre, coarse_angle as f32);
    }
    let rotated = imageproc::geometric_transformations::rotate_about_center(
        &pre,
        refined.to_radians(),
        imageproc::geometric_transformations::Interpolation::Bilinear,
        image::Luma([255u8]),
    );
    (rotated, coarse_angle as f32 + refined)
}

/// Detektiert ob das Bild um 90/180/270 Grad gedreht ist.
/// Strategie: vergleiche Row-Density-Varianz mit Column-Density-Varianz.
/// Bei korrekter Orientierung sind Stafflinien horizontal → row-Varianz hoch.
/// Bei 90°-Rotation sind Linien vertikal → column-Varianz hoch.
fn detect_coarse_rotation(gray: &GrayImage) -> i32 {
    let row_var = density_variance(gray);
    let col_var = column_density_variance(gray);
    if col_var > row_var * 2.0 {
        // Vertikale Stafflinien → 90° rotieren.
        // Wir wählen 90° gegen den Uhrzeigersinn (rotates clockwise contents
        // into landscape→portrait). Wenn die Erkennung nach -90 schlechter
        // ist, hilft eine zweite Pass im Pipeline-Code.
        return 90;
    }
    0
}

/// Rotiere ein Bild in 90°-Schritten. Steps positiv = im Uhrzeigersinn.
pub fn rotate_90_steps(gray: &GrayImage, degrees: i32) -> GrayImage {
    let normalized = ((degrees % 360) + 360) % 360;
    match normalized {
        0 => gray.clone(),
        90 => {
            let (w, h) = (gray.width(), gray.height());
            let mut out = image::ImageBuffer::new(h, w);
            for y in 0..h {
                for x in 0..w {
                    let p = gray.get_pixel(x, y);
                    // x_new = h - 1 - y, y_new = x  (CW rotation)
                    out.put_pixel(h - 1 - y, x, *p);
                }
            }
            out
        }
        180 => {
            let (w, h) = (gray.width(), gray.height());
            let mut out = image::ImageBuffer::new(w, h);
            for y in 0..h {
                for x in 0..w {
                    let p = gray.get_pixel(x, y);
                    out.put_pixel(w - 1 - x, h - 1 - y, *p);
                }
            }
            out
        }
        270 => {
            let (w, h) = (gray.width(), gray.height());
            let mut out = image::ImageBuffer::new(h, w);
            for y in 0..h {
                for x in 0..w {
                    let p = gray.get_pixel(x, y);
                    // x_new = y, y_new = w - 1 - x (CCW rotation)
                    out.put_pixel(y, w - 1 - x, *p);
                }
            }
            out
        }
        _ => gray.clone(),
    }
}

fn find_best_angle(gray: &GrayImage, lo: f32, hi: f32, step: f32) -> (f32, f64) {
    let mut best = (0.0_f32, 0.0_f64);
    let mut a = lo;
    while a <= hi + 0.001 {
        let var = density_variance_at_angle(gray, a);
        if var > best.1 {
            best = (a, var);
        }
        a += step;
    }
    best
}

fn density_variance_at_angle(gray: &GrayImage, angle_deg: f32) -> f64 {
    if angle_deg.abs() < 0.05 {
        return density_variance(gray);
    }
    let rotated = imageproc::geometric_transformations::rotate_about_center(
        gray,
        angle_deg.to_radians(),
        imageproc::geometric_transformations::Interpolation::Nearest,
        image::Luma([255u8]),
    );
    density_variance(&rotated)
}

fn density_variance(gray: &GrayImage) -> f64 {
    let (w, h) = (gray.width(), gray.height());
    let mut row_dens = vec![0u32; h as usize];
    for y in 0..h {
        let mut sum = 0u32;
        for x in 0..w {
            if gray.get_pixel(x, y)[0] < 128 { sum += 1; }
        }
        row_dens[y as usize] = sum;
    }
    let mean = row_dens.iter().map(|&v| v as f64).sum::<f64>() / row_dens.len() as f64;
    row_dens.iter().map(|&v| {
        let d = v as f64 - mean;
        d * d
    }).sum::<f64>() / row_dens.len() as f64
}

fn column_density_variance(gray: &GrayImage) -> f64 {
    let (w, h) = (gray.width(), gray.height());
    let mut col_dens = vec![0u32; w as usize];
    for y in 0..h {
        for x in 0..w {
            if gray.get_pixel(x, y)[0] < 128 { col_dens[x as usize] += 1; }
        }
    }
    let mean = col_dens.iter().map(|&v| v as f64).sum::<f64>() / col_dens.len() as f64;
    col_dens.iter().map(|&v| {
        let d = v as f64 - mean;
        d * d
    }).sum::<f64>() / col_dens.len() as f64
}

#[allow(dead_code)]
fn binary_density_variance(bin: &Binary) -> f64 {
    let dens = bin.row_density();
    let mean = dens.iter().map(|&v| v as f64).sum::<f64>() / dens.len() as f64;
    dens.iter().map(|&v| { let d = v as f64 - mean; d * d }).sum::<f64>() / dens.len() as f64
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{GrayImage, Luma};

    fn make_horizontal_stafflines(w: u32, h: u32) -> GrayImage {
        let mut img = image::ImageBuffer::from_pixel(w, h, Luma([255u8]));
        for line_y in [40u32, 50, 60, 70, 80] {
            for x in 5..w - 5 {
                if line_y < h { img.put_pixel(x, line_y, Luma([0])); }
            }
        }
        img
    }

    #[test]
    fn rotate_90_makes_horizontal_lines_vertical() {
        let img = make_horizontal_stafflines(200, 100);
        let rot = rotate_90_steps(&img, 90);
        assert_eq!(rot.width(), 100);
        assert_eq!(rot.height(), 200);
    }

    #[test]
    fn detect_coarse_does_not_rotate_horizontal_image() {
        let img = make_horizontal_stafflines(200, 100);
        assert_eq!(detect_coarse_rotation(&img), 0);
    }

    #[test]
    fn detect_coarse_rotates_vertical_image_to_horizontal() {
        let img = make_horizontal_stafflines(200, 100);
        let rotated = rotate_90_steps(&img, 90);
        assert_eq!(detect_coarse_rotation(&rotated), 90);
    }

    #[test]
    fn deskew_recovers_horizontal_from_90_rotated() {
        let img = make_horizontal_stafflines(200, 120);
        let rotated = rotate_90_steps(&img, 90);
        let (recovered, applied) = deskew(&rotated);
        // Nach Recover: horizontal stafflines → row-variance hoch wieder
        assert_eq!(applied as i32 % 360, 90);
        assert!(density_variance(&recovered) > column_density_variance(&recovered));
    }
}
