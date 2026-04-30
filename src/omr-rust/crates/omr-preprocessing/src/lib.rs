// Bildvorverarbeitung — Sauvola-Binarisierung, Deskewing, Median-Filter.
//
// Quelle Sauvola: Sauvola/Pietikäinen 2000, "Adaptive document image
// binarization", Pattern Recognition 33(2). Parameter window=25, k=0.34
// sind aus 16-omr-algorithm-research.md.

use image::{GrayImage, ImageBuffer, Luma};
use omr_core::{Binary, Gray, OmrError, Result};
use rayon::prelude::*;
use tracing::debug;

pub mod deskew;
pub use deskew::deskew;

/// Sauvola-Binarisierung mit Integral-Image für O(N) statt O(N·w²).
///
/// Threshold pro Pixel:
///   T(x,y) = mean(W) * [ 1 + k * (std(W) / R - 1) ]
/// mit R = 128 (dynamic range constant) und window-size W = `window` × `window`.
///
/// Parameter:
/// * `window` — Fenstergröße in Pixeln (default 25 — passt zu 300dpi-Notenbildern).
/// * `k` — Sauvola-Konstante, default 0.34 (siehe Forschungs-Doku).
pub fn sauvola(gray: &Gray, window: u32, k: f64) -> Binary {
    let (w, h) = (gray.width(), gray.height());
    let half = (window / 2).max(1);

    // 1) Integral-Image und Integral-Quadrat-Image (1-indexiert für summed-area-trick).
    let mut s = vec![0i64; ((w + 1) * (h + 1)) as usize];
    let mut s2 = vec![0i64; ((w + 1) * (h + 1)) as usize];
    let stride = (w + 1) as usize;
    for y in 0..h {
        let mut row_sum = 0i64;
        let mut row_sum2 = 0i64;
        for x in 0..w {
            let v = gray.get_pixel(x, y)[0] as i64;
            row_sum += v;
            row_sum2 += v * v;
            let idx = (y as usize + 1) * stride + (x as usize + 1);
            s[idx] = s[idx - stride] + row_sum;
            s2[idx] = s2[idx - stride] + row_sum2;
        }
    }

    let r_const = 128.0_f64;
    let mut out = Binary::new(w, h);

    // 2) Pro Pixel: lokales Fenster mit summed-area-table-Lookup.
    out.data.par_chunks_mut(w as usize).enumerate().for_each(|(yu, row_out)| {
        let y = yu as u32;
        let y0 = y.saturating_sub(half) as usize;
        let y1 = (y + half).min(h - 1) as usize + 1;
        for x in 0..w {
            let x0 = x.saturating_sub(half) as usize;
            let x1 = (x + half).min(w - 1) as usize + 1;
            let area = ((x1 - x0) * (y1 - y0)) as f64;
            let sum = (s[y1 * stride + x1] - s[y0 * stride + x1]
                    - s[y1 * stride + x0] + s[y0 * stride + x0]) as f64;
            let sum_sq = (s2[y1 * stride + x1] - s2[y0 * stride + x1]
                    - s2[y1 * stride + x0] + s2[y0 * stride + x0]) as f64;
            let mean = sum / area;
            let var = (sum_sq / area - mean * mean).max(0.0);
            let std = var.sqrt();
            let threshold = mean * (1.0 + k * (std / r_const - 1.0));
            let v = gray.get_pixel(x, y)[0] as f64;
            row_out[x as usize] = if v < threshold { 1 } else { 0 };
        }
    });
    debug!(window, k, count = out.count(), "sauvola binarization done");
    out
}

/// Otsu-Binarisierung als Fallback / schneller Default.
pub fn otsu(gray: &Gray) -> Binary {
    let (w, h) = (gray.width(), gray.height());
    let mut hist = [0u32; 256];
    for p in gray.pixels() { hist[p[0] as usize] += 1; }
    let total = (w * h) as f64;

    let mut sum_total = 0.0;
    for (i, &c) in hist.iter().enumerate() { sum_total += i as f64 * c as f64; }

    let mut sum_b = 0.0;
    let mut w_b = 0.0;
    let mut max_var = 0.0;
    let mut threshold = 128u8;
    for (i, &c) in hist.iter().enumerate() {
        w_b += c as f64;
        if w_b == 0.0 { continue; }
        let w_f = total - w_b;
        if w_f == 0.0 { break; }
        sum_b += i as f64 * c as f64;
        let m_b = sum_b / w_b;
        let m_f = (sum_total - sum_b) / w_f;
        let between = w_b * w_f * (m_b - m_f).powi(2);
        if between > max_var {
            max_var = between;
            threshold = i as u8;
        }
    }
    debug!(threshold, "otsu binarization");
    Binary::threshold_global(gray, threshold.saturating_add(1))
}

/// Median-Filter (3×3) — entfernt Salt-and-Pepper-Rauschen.
pub fn median3x3(gray: &Gray) -> Gray {
    imageproc::filter::median_filter(gray, 1, 1)
}

/// Hilfsfunktion: Lade ein Bild von Pfad und konvertiere zu Grayscale.
pub fn load_grayscale(path: &std::path::Path) -> Result<Gray> {
    let img = image::open(path)?;
    Ok(img.to_luma8())
}

/// Bilineare Skalierung — falls DPI < 300 (zu klein für Standard-Parameter).
pub fn ensure_target_height(gray: &Gray, target_h: u32) -> Gray {
    let (w, h) = (gray.width(), gray.height());
    if h >= target_h { return gray.clone(); }
    let ratio = target_h as f32 / h as f32;
    let new_w = (w as f32 * ratio) as u32;
    image::imageops::resize(gray, new_w, target_h, image::imageops::FilterType::Triangle)
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{GrayImage, Luma};

    fn make_test_image() -> GrayImage {
        let mut img = ImageBuffer::from_pixel(100, 100, Luma([220u8]));
        // Schwarze 5x5 Box in der Mitte
        for y in 47..53 {
            for x in 47..53 {
                img.put_pixel(x, y, Luma([20]));
            }
        }
        img
    }

    #[test]
    fn sauvola_finds_dark_box() {
        let gray = make_test_image();
        let bin = sauvola(&gray, 25, 0.34);
        assert!(bin.get(50, 50) == 1, "Mitte muss schwarz sein");
        assert!(bin.get(0, 0) == 0, "Ecke muss weiß sein");
    }

    #[test]
    fn otsu_works() {
        let gray = make_test_image();
        let bin = otsu(&gray);
        assert!(bin.get(50, 50) == 1);
        assert!(bin.get(0, 0) == 0);
    }
}
