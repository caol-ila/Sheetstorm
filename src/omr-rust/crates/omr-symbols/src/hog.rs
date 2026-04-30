//! Histogram of Oriented Gradients (HoG) Feature-Extraktor.
//!
//! Implementiert eine kompakte HoG-Variante für 32×32-Patches, die als
//! Eingang für den Symbol-Klassifikator (`svm_model.rs`) dient.
//!
//! ## Wahl der Variante
//!
//! Wir verwenden **klassisches HoG** (Variante A aus dem Task-Brief), nicht
//! Pixel-Density. Begründung:
//!
//! * HoG ist weitgehend invariant gegen Helligkeit und schwache geometrische
//!   Verzerrung — wichtig nach Staff-Removal, wo NH-Patches teilweise
//!   "zerschnitten" werden.
//! * Coda/Segno haben charakteristische Kanten-Orientierungen (Diagonalen,
//!   geschlossene Kurven), die sich in Orientierungs-Histogrammen sehr klar
//!   von der "isolierten Ellipse"-Signatur eines Noteheads unterscheiden.
//! * 324 Features × f32 = 1296 Bytes pro Sample — passt locker in den
//!   Performance-Budget (< 1 ms pro Patch).
//!
//! ## Pipeline
//!
//! 1. Patch wird (falls nötig) auf 32×32 resampled (Nearest-Neighbor reicht
//!    für binär-stämmige Patches).
//! 2. Sobel-ähnliche Gradienten Gx, Gy mit Kernel `[-1, 0, 1]`.
//! 3. Magnitude = √(Gx² + Gy²), Orientation = atan2(Gy, Gx) auf `[0, π)`
//!    (unsigned — Vorzeichen ist für Symbol-Erkennung irrelevant).
//! 4. Cells 8×8 → 4×4 = 16 Cells.
//! 5. 9 Bins pro Cell, Soft-Voting (lineare Interpolation auf zwei
//!    Nachbar-Bins).
//! 6. Blöcke 2×2 Cells, Stride 1 → 3×3 = 9 Blöcke, je 36 Features.
//! 7. L2-Hys-Normalisierung pro Block (clip auf 0.2, dann re-normalisieren).
//! 8. Konkatenation → **324 Features**.
//!
//! Der Output ist deterministisch und reproduzierbar.

use image::GrayImage;
#[cfg(test)]
use image::Luma;

/// Cell-Größe in Pixeln.
pub const CELL_SIZE: u32 = 8;
/// Block-Größe in Cells.
pub const BLOCK_SIZE: u32 = 2;
/// Anzahl Orientierungs-Bins.
pub const N_BINS: usize = 9;
/// Erwartete Patch-Größe in Pixeln (quadratisch).
pub const PATCH_SIZE: u32 = 32;
/// Anzahl Cells pro Achse.
pub const CELLS_PER_AXIS: u32 = PATCH_SIZE / CELL_SIZE; // 4
/// Anzahl Blöcke pro Achse.
pub const BLOCKS_PER_AXIS: u32 = CELLS_PER_AXIS - BLOCK_SIZE + 1; // 3
/// Länge des resultierenden Feature-Vektors.
pub const FEATURE_LEN: usize = (BLOCKS_PER_AXIS as usize)
    * (BLOCKS_PER_AXIS as usize)
    * (BLOCK_SIZE as usize)
    * (BLOCK_SIZE as usize)
    * N_BINS; // 3*3*2*2*9 = 324

/// Extrahiert den HoG-Feature-Vektor aus einem Grayscale-Patch.
///
/// Falls das Eingabebild nicht 32×32 ist, wird es per Nearest-Neighbor
/// resampled. Das ist für binäre/quasi-binäre OMR-Patches ausreichend
/// und schneller als bilinear/bicubic.
///
/// Returns einen Vektor der Länge [`FEATURE_LEN`] (324).
pub fn extract_hog(patch: &GrayImage) -> Vec<f32> {
    let resized = if patch.width() == PATCH_SIZE && patch.height() == PATCH_SIZE {
        patch.clone()
    } else {
        resize_nn(patch, PATCH_SIZE, PATCH_SIZE)
    };

    // Schritt 1+2: Gradienten via [-1, 0, 1]-Kernel.
    let (mag, ori) = compute_gradients(&resized);

    // Schritt 3: Cell-Histogramme.
    let cells = compute_cell_histograms(&mag, &ori);

    // Schritt 4: Block-Normalisierung.
    block_normalize(&cells)
}

/// Nearest-Neighbor-Resize auf gegebene Zielgröße.
fn resize_nn(src: &GrayImage, w: u32, h: u32) -> GrayImage {
    let sw = src.width() as f32;
    let sh = src.height() as f32;
    let mut dst = GrayImage::new(w, h);
    for y in 0..h {
        for x in 0..w {
            let sx = ((x as f32 + 0.5) * sw / w as f32).floor() as u32;
            let sy = ((y as f32 + 0.5) * sh / h as f32).floor() as u32;
            let sx = sx.min(src.width() - 1);
            let sy = sy.min(src.height() - 1);
            dst.put_pixel(x, y, *src.get_pixel(sx, sy));
        }
    }
    dst
}

/// Berechnet Gradienten-Magnitude und unsigned Orientation `[0, π)`
/// für jedes Pixel (mit Zero-Padding am Rand).
fn compute_gradients(img: &GrayImage) -> (Vec<f32>, Vec<f32>) {
    let w = img.width() as i32;
    let h = img.height() as i32;
    let n = (w * h) as usize;
    let mut mag = vec![0.0_f32; n];
    let mut ori = vec![0.0_f32; n];
    let pi = std::f32::consts::PI;

    let get = |x: i32, y: i32| -> f32 {
        if x < 0 || y < 0 || x >= w || y >= h {
            0.0
        } else {
            img.get_pixel(x as u32, y as u32)[0] as f32
        }
    };

    for y in 0..h {
        for x in 0..w {
            let gx = get(x + 1, y) - get(x - 1, y);
            let gy = get(x, y + 1) - get(x, y - 1);
            let m = (gx * gx + gy * gy).sqrt();
            // Unsigned Orientation: atan2 → [-π, π], mod π → [0, π).
            let mut a = gy.atan2(gx);
            if a < 0.0 {
                a += pi;
            }
            // Sicherheit: Werte minimal über π werden auf < π geclamped.
            if a >= pi {
                a -= pi;
            }
            let idx = (y * w + x) as usize;
            mag[idx] = m;
            ori[idx] = a;
        }
    }
    (mag, ori)
}

/// Berechnet Histogramme (9 Bins) pro Cell mit Soft-Binning.
/// Output-Layout: row-major über Cells, je Cell N_BINS Werte.
fn compute_cell_histograms(mag: &[f32], ori: &[f32]) -> Vec<f32> {
    let cells_per_axis = CELLS_PER_AXIS as usize;
    let mut cells = vec![0.0_f32; cells_per_axis * cells_per_axis * N_BINS];
    let bin_width = std::f32::consts::PI / N_BINS as f32;
    let img_w = PATCH_SIZE as usize;

    for cy in 0..cells_per_axis {
        for cx in 0..cells_per_axis {
            let cell_idx = (cy * cells_per_axis + cx) * N_BINS;
            for py in 0..CELL_SIZE as usize {
                for px in 0..CELL_SIZE as usize {
                    let x = cx * CELL_SIZE as usize + px;
                    let y = cy * CELL_SIZE as usize + py;
                    let pix = y * img_w + x;
                    let m = mag[pix];
                    if m == 0.0 {
                        continue;
                    }
                    let a = ori[pix];
                    // Bilineares Voting auf zwei Nachbar-Bins.
                    let bin_pos = a / bin_width - 0.5;
                    let lower = bin_pos.floor() as i32;
                    let frac = bin_pos - lower as f32;
                    let lo = ((lower).rem_euclid(N_BINS as i32)) as usize;
                    let hi = ((lower + 1).rem_euclid(N_BINS as i32)) as usize;
                    cells[cell_idx + lo] += m * (1.0 - frac);
                    cells[cell_idx + hi] += m * frac;
                }
            }
        }
    }
    cells
}

/// L2-Hys-Block-Normalisierung mit Clip-Threshold 0.2.
fn block_normalize(cells: &[f32]) -> Vec<f32> {
    let cells_per_axis = CELLS_PER_AXIS as usize;
    let block_size = BLOCK_SIZE as usize;
    let blocks_per_axis = BLOCKS_PER_AXIS as usize;
    let mut feats = Vec::with_capacity(FEATURE_LEN);

    for by in 0..blocks_per_axis {
        for bx in 0..blocks_per_axis {
            let mut block: Vec<f32> = Vec::with_capacity(block_size * block_size * N_BINS);
            for dy in 0..block_size {
                for dx in 0..block_size {
                    let cy = by + dy;
                    let cx = bx + dx;
                    let cell_idx = (cy * cells_per_axis + cx) * N_BINS;
                    block.extend_from_slice(&cells[cell_idx..cell_idx + N_BINS]);
                }
            }
            // L2-Norm
            let norm = block.iter().map(|v| v * v).sum::<f32>().sqrt();
            if norm > 1e-6 {
                for v in block.iter_mut() {
                    *v /= norm;
                    if *v > 0.2 {
                        *v = 0.2;
                    }
                }
                // Re-Normalisierung nach Clip.
                let norm2 = block.iter().map(|v| v * v).sum::<f32>().sqrt();
                if norm2 > 1e-6 {
                    for v in block.iter_mut() {
                        *v /= norm2;
                    }
                }
            }
            feats.extend(block);
        }
    }
    debug_assert_eq!(feats.len(), FEATURE_LEN);
    feats
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn feature_len_matches_constant() {
        let img = GrayImage::from_pixel(PATCH_SIZE, PATCH_SIZE, Luma([0]));
        let f = extract_hog(&img);
        assert_eq!(f.len(), FEATURE_LEN);
        assert_eq!(FEATURE_LEN, 324);
    }

    #[test]
    fn empty_patch_produces_zero_vector() {
        let img = GrayImage::from_pixel(PATCH_SIZE, PATCH_SIZE, Luma([0]));
        let f = extract_hog(&img);
        // Ohne Gradient ist das gesamte Histogramm 0.
        assert!(f.iter().all(|&v| v == 0.0));
    }

    #[test]
    fn uniform_patch_produces_only_boundary_response() {
        // Konstante Helligkeit erzeugt nur am Rand Gradienten (durch
        // Zero-Padding). Die Summe aller Features bleibt klein verglichen
        // mit einer echten Kante mitten im Bild.
        let img = GrayImage::from_pixel(PATCH_SIZE, PATCH_SIZE, Luma([128]));
        let f = extract_hog(&img);
        // Nach L2-Hys-Norm sind die Werte beschränkt; der Test prüft nur,
        // dass kein Wert außerhalb [0, 0.21] liegt (= Norm bound + Slack).
        for v in &f {
            assert!(*v >= 0.0 && *v <= 0.21, "feature out of range: {v}");
        }
    }

    #[test]
    fn vertical_edge_concentrates_in_horizontal_orientation() {
        // Bildhälfte schwarz / weiß → vertikale Kante → Gradient in x-Richtung
        // → unsigned Orientation ≈ 0 → Energy in Bin 0.
        let mut img = GrayImage::new(PATCH_SIZE, PATCH_SIZE);
        for y in 0..PATCH_SIZE {
            for x in 0..PATCH_SIZE {
                let v = if x < PATCH_SIZE / 2 { 0 } else { 255 };
                img.put_pixel(x, y, Luma([v]));
            }
        }
        let f = extract_hog(&img);
        // Bin 0 (oder Bin 8 wegen Wrap) sollte die meiste Energie haben.
        let mut bin_sums = vec![0.0_f32; N_BINS];
        for (i, v) in f.iter().enumerate() {
            bin_sums[i % N_BINS] += v;
        }
        let dominant = bin_sums
            .iter()
            .enumerate()
            .max_by(|a, b| a.1.partial_cmp(b.1).unwrap())
            .unwrap()
            .0;
        assert!(
            dominant == 0 || dominant == N_BINS - 1,
            "expected dominant bin around 0, got {dominant}: {bin_sums:?}"
        );
    }

    #[test]
    fn resizing_handles_non_square_input() {
        // Auch nicht-32-Patches sollen ohne Panic einen 324-Vektor produzieren.
        let img = GrayImage::from_pixel(48, 48, Luma([0]));
        let f = extract_hog(&img);
        assert_eq!(f.len(), FEATURE_LEN);
    }
}
