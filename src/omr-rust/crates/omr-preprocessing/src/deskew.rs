// Deskewing über horizontale Projektion.
//
// Strategie: rotiere das Bild um Winkel α ∈ [-5°, +5°] in 0.2°-Schritten,
// berechne pro Winkel die Varianz des Row-Density-Profils. Bei korrekter
// Ausrichtung sind Stafflines exakt waagrecht, wodurch die Row-Density
// in den Linien-Zeilen extrem hoch und dazwischen extrem niedrig ist
// → max Varianz.
//
// Komplexität: 50 Rotationen * O(N), für 2000x3000-Bild ca. 0.5 s.

use image::GrayImage;
use omr_core::Binary;

/// Rotiere `gray` um den Winkel der Notenlinien.
///
/// Gibt das deskewte Grayscale-Bild zurück + den korrigierten Winkel in Grad.
pub fn deskew(gray: &GrayImage) -> (GrayImage, f32) {
    let (best_angle, _best_var) = find_best_angle(gray, -5.0, 5.0, 0.5);
    let refined = if best_angle.abs() > 0.1 {
        let (a, _) = find_best_angle(gray, best_angle - 0.5, best_angle + 0.5, 0.1);
        a
    } else { best_angle };
    if refined.abs() < 0.05 {
        return (gray.clone(), 0.0);
    }
    let rotated = imageproc::geometric_transformations::rotate_about_center(
        gray,
        refined.to_radians(),
        imageproc::geometric_transformations::Interpolation::Bilinear,
        image::Luma([255u8]),
    );
    (rotated, refined)
}

/// Finde den Winkel mit max Row-Density-Varianz.
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

/// Varianz der Row-Density nach Rotation.
fn density_variance_at_angle(gray: &GrayImage, angle_deg: f32) -> f64 {
    if angle_deg.abs() < 0.05 {
        // Kein Rotationsaufwand bei Mini-Winkel
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

#[allow(dead_code)]
fn binary_density_variance(bin: &Binary) -> f64 {
    let dens = bin.row_density();
    let mean = dens.iter().map(|&v| v as f64).sum::<f64>() / dens.len() as f64;
    dens.iter().map(|&v| { let d = v as f64 - mean; d * d }).sum::<f64>() / dens.len() as f64
}
