//! Bravura-basierter Symbol-Template-Generator.
//!
//! Dieses Modul rendert SMuFL-Glyphen (Bravura.otf) zu 32×32 Grayscale-Patches und
//! erzeugt augmentierte Varianten als Trainings-Korpus für einen Patch-Klassifikator.
//!
//! ## Lizenz-Hinweis
//! Die Datei `assets/Bravura.otf` ist unter der SIL Open Font License (OFL) lizenziert.
//! Siehe `assets/BRAVURA-LICENSE.txt`. Das Font-Rendering selbst nutzt
//! `fontdue` (Apache-2.0 / MIT) und `rand` (Apache-2.0 / MIT).
//!
//! ## Workflow
//! ```ignore
//! use omr_symbols::templates::{generate_training_corpus, SymbolClass};
//!
//! let corpus = generate_training_corpus(32, 30, 42);
//! // -> Vec<(GrayImage, SymbolClass)>, ca. 7 Klassen × 30 Varianten × Augmentation
//! ```
//!
//! Pre-rendern auf Disk:
//! ```ignore
//! omr_symbols::templates::write_corpus_to_disk(
//!     "src/omr-rust/training-data/symbol-patches",
//!     32, 30, 42,
//! ).unwrap();
//! ```

use image::{GrayImage, Luma};
use rand::{Rng, SeedableRng};
use rand_chacha::ChaCha8Rng;
use serde::{Deserialize, Serialize};
use std::path::Path;

/// Eingebettete Bravura.otf-Datei. Wird beim Build aus `assets/` geladen.
pub const BRAVURA_OTF: &[u8] =
    include_bytes!("../assets/Bravura.otf");

/// Symbol-Klasse für den Patch-Klassifikator.
///
/// SMuFL-Codepoints siehe: <https://w3c.github.io/smufl/latest/tables/index.html>
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum SymbolClass {
    /// Geschlossener Notenkopf (Quarter, 8th, 16th) – U+E0A4 `noteheadBlack`.
    NoteheadFilled,
    /// Halber Notenkopf (offen) – U+E0A3 `noteheadHalf`.
    NoteheadOpen,
    /// Ganze Note – U+E0A2 `noteheadWhole`.
    NoteheadWhole,
    /// Coda-Symbol – U+E048 `coda`.
    Coda,
    /// Segno-Symbol – U+E047 `segno`.
    Segno,
    /// Dynamik `p` (piano) – U+E520.
    DynamicPiano,
    /// Dynamik `mp` (mezzo-piano) – U+E521.
    DynamicMezzopiano,
    /// Dynamik `mf` (mezzo-forte) – U+E522.
    DynamicMezzoforte,
    /// Dynamik `f` (forte) – U+E523.
    DynamicForte,
    /// Negative Klasse: zufälliges Pixel-Rauschen / leere Patches.
    Noise,
}

impl SymbolClass {
    /// Alle Klassen in stabiler Reihenfolge.
    pub const ALL: &'static [SymbolClass] = &[
        SymbolClass::NoteheadFilled,
        SymbolClass::NoteheadOpen,
        SymbolClass::NoteheadWhole,
        SymbolClass::Coda,
        SymbolClass::Segno,
        SymbolClass::DynamicPiano,
        SymbolClass::DynamicMezzopiano,
        SymbolClass::DynamicMezzoforte,
        SymbolClass::DynamicForte,
        SymbolClass::Noise,
    ];

    /// SMuFL-Codepoint der Klasse, oder `None` für synthetische Klassen.
    pub fn smufl_codepoint(self) -> Option<u32> {
        Some(match self {
            SymbolClass::NoteheadFilled => 0xE0A4,
            SymbolClass::NoteheadOpen => 0xE0A3,
            SymbolClass::NoteheadWhole => 0xE0A2,
            SymbolClass::Coda => 0xE048,
            SymbolClass::Segno => 0xE047,
            SymbolClass::DynamicPiano => 0xE520,
            SymbolClass::DynamicMezzopiano => 0xE521,
            SymbolClass::DynamicMezzoforte => 0xE522,
            SymbolClass::DynamicForte => 0xE523,
            SymbolClass::Noise => return None,
        })
    }

    /// Verzeichnis-/Label-Name für Training-Output.
    pub fn label(self) -> &'static str {
        match self {
            SymbolClass::NoteheadFilled => "notehead_filled",
            SymbolClass::NoteheadOpen => "notehead_open",
            SymbolClass::NoteheadWhole => "notehead_whole",
            SymbolClass::Coda => "coda",
            SymbolClass::Segno => "segno",
            SymbolClass::DynamicPiano => "dynamic_p",
            SymbolClass::DynamicMezzopiano => "dynamic_mp",
            SymbolClass::DynamicMezzoforte => "dynamic_mf",
            SymbolClass::DynamicForte => "dynamic_f",
            SymbolClass::Noise => "noise",
        }
    }
}

/// Rendert einen einzelnen Codepoint aus einem Font in ein zentriertes
/// `size_px × size_px` Grayscale-Patch (0 = weiß/Hintergrund, 255 = schwarz/Glyph).
///
/// Die Glyphhöhe wird auf ca. 70 % der Patch-Höhe skaliert, damit nach
/// Rotation/Skalierung noch Rand bleibt.
pub fn render_glyph(font_data: &[u8], codepoint: u32, size_px: u32) -> GrayImage {
    let target_glyph_px = (size_px as f32 * 0.70).max(8.0);
    render_glyph_at(font_data, codepoint, size_px, target_glyph_px)
}

/// Wie [`render_glyph`], aber mit konfigurierbarer Glyph-Höhe in Pixel.
pub fn render_glyph_at(
    font_data: &[u8],
    codepoint: u32,
    size_px: u32,
    glyph_px: f32,
) -> GrayImage {
    let canvas = GrayImage::from_pixel(size_px, size_px, Luma([0u8]));
    let ch = match char::from_u32(codepoint) {
        Some(c) => c,
        None => return canvas,
    };

    let font = match fontdue::Font::from_bytes(font_data, fontdue::FontSettings::default()) {
        Ok(f) => f,
        Err(_) => return canvas,
    };

    // fontdue rasterisiert mit "px"-Höhe (em-Einheiten). Wir renderen einmal,
    // messen die Bounding-Box und passen ggf. an, falls die SMuFL-Glyphen
    // sehr unterschiedlich groß sind.
    let (metrics, bitmap) = font.rasterize(ch, glyph_px);
    if metrics.width == 0 || metrics.height == 0 {
        return canvas;
    }

    // Skaliere auf Ziel-Höhe, falls Glyph größer als Canvas geworden ist
    // (Bravura-Glyphen können breiter als hoch sein).
    let max_dim = metrics.width.max(metrics.height) as f32;
    let allowed = (size_px as f32 * 0.95).max(8.0);
    if max_dim > allowed {
        let factor = allowed / max_dim;
        let new_px = (glyph_px * factor).max(6.0);
        let (m2, bm2) = font.rasterize(ch, new_px);
        return blit_centered(canvas, &bm2, m2.width, m2.height);
    }

    blit_centered(canvas, &bitmap, metrics.width, metrics.height)
}

/// Kopiert eine fontdue-Bitmap (8-bit Coverage) zentriert in ein Canvas.
fn blit_centered(
    mut canvas: GrayImage,
    bitmap: &[u8],
    w: usize,
    h: usize,
) -> GrayImage {
    let cw = canvas.width() as i32;
    let ch = canvas.height() as i32;
    let off_x = (cw - w as i32) / 2;
    let off_y = (ch - h as i32) / 2;
    for y in 0..h {
        for x in 0..w {
            let v = bitmap[y * w + x];
            if v == 0 {
                continue;
            }
            let cx = off_x + x as i32;
            let cy = off_y + y as i32;
            if cx < 0 || cy < 0 || cx >= cw || cy >= ch {
                continue;
            }
            canvas.put_pixel(cx as u32, cy as u32, Luma([v]));
        }
    }
    canvas
}

/// Rendert eine SMuFL-Klasse: liefert das Basis-Template plus deterministisch
/// augmentierte Varianten (Anzahl `variants`, inkl. Basis).
///
/// Für [`SymbolClass::Noise`] werden synthetische Rausch-Patches erzeugt.
pub fn render_smufl_class(class: SymbolClass, size_px: u32) -> Vec<GrayImage> {
    render_smufl_class_with(class, size_px, 30, 0)
}

/// Wie [`render_smufl_class`], aber mit konfigurierbarer Variantenanzahl und Seed.
pub fn render_smufl_class_with(
    class: SymbolClass,
    size_px: u32,
    variants: usize,
    seed: u64,
) -> Vec<GrayImage> {
    let mut out = Vec::with_capacity(variants);
    let mut rng = ChaCha8Rng::seed_from_u64(mix_seed(seed, class));

    if matches!(class, SymbolClass::Noise) {
        for _ in 0..variants {
            out.push(render_noise(size_px, &mut rng));
        }
        return out;
    }

    let cp = match class.smufl_codepoint() {
        Some(c) => c,
        None => return out,
    };

    let base = render_glyph(BRAVURA_OTF, cp, size_px);
    out.push(base.clone());

    for _ in 1..variants {
        out.push(augment(&base, &mut rng));
    }
    out
}

/// Mischt einen User-Seed mit dem Klassen-Diskriminator.
fn mix_seed(seed: u64, class: SymbolClass) -> u64 {
    let class_id = SymbolClass::ALL
        .iter()
        .position(|c| *c == class)
        .unwrap_or(0) as u64;
    seed.wrapping_mul(0x9E37_79B9_7F4A_7C15)
        .wrapping_add(class_id.wrapping_mul(0xBF58_476D_1CE4_E5B9))
}

/// Erzeugt ein synthetisches Noise-Patch.
///
/// Wichtig: Noise-Patches dürfen NICHT NH-shaped sein, sonst lernt der
/// Klassifikator NH ↔ Noise nicht zu trennen. Daher:
/// - leere Patches
/// - reine Streupixel
/// - horizontale Striche (Stafflinien-Reste)
/// - vertikale dünne Striche (Stem-Reste)
/// - diagonale Patterns (Kompressions-Artefakte)
///
/// KEINE NH-ähnlichen Halbmonde / Ellipsen / runden Formen!
fn render_noise(size_px: u32, rng: &mut ChaCha8Rng) -> GrayImage {
    let mut img = GrayImage::from_pixel(size_px, size_px, Luma([0u8]));
    let kind: u32 = rng.gen_range(0..5);
    match kind {
        0 => {} // ~1/5 leer
        1 => {
            // Streupixel
            let n = (size_px as f32 * size_px as f32 * 0.05) as u32;
            for _ in 0..n {
                let x = rng.gen_range(0..size_px);
                let y = rng.gen_range(0..size_px);
                img.put_pixel(x, y, Luma([255]));
            }
        }
        2 => {
            // Horizontale Striche (Stafflinien-Reste)
            let n_lines = rng.gen_range(1..=3);
            for _ in 0..n_lines {
                let y = rng.gen_range(2..size_px - 2);
                let x_start = rng.gen_range(0..size_px / 2);
                let x_end = rng.gen_range(size_px / 2..size_px);
                for x in x_start..x_end {
                    img.put_pixel(x, y, Luma([255]));
                }
            }
        }
        3 => {
            // Vertikaler dünner Strich (Stem/Bar-Fragmente)
            let x = rng.gen_range(2..size_px - 2);
            let thick = rng.gen_range(1..=3);
            for y in 0..size_px {
                for tx in 0..thick {
                    if x + tx < size_px {
                        img.put_pixel(x + tx, y, Luma([255]));
                    }
                }
            }
        }
        _ => {
            // Diagonal-Pattern
            for i in 0..size_px {
                let x = i;
                let y = (i as f32 * rng.gen_range(0.5..2.0)) as u32 % size_px;
                img.put_pixel(x, y, Luma([255]));
            }
        }
    }
    img
}

/// Wendet eine zufällige Augmentation-Pipeline auf ein Basis-Template an.
///
/// Pipeline für realistische Pipeline-Patches:
/// 1. Skalierung (0.85-1.15)
/// 2. Rotation (±4°)
/// 3. Translation (±4px)
/// 4. Gauss-Blur (0-0.8 sigma)
/// 5. Salt-Pepper (0-2%)
/// 6. Staff-Removal-Artefakte (30%): horizontale Striche am RAND
fn augment(base: &GrayImage, rng: &mut ChaCha8Rng) -> GrayImage {
    let size = base.width();
    let scale = rng.gen_range(0.85..=1.15_f32);
    let angle_deg = rng.gen_range(-4.0..=4.0_f32);
    let tx = rng.gen_range(-4..=4_i32);
    let ty = rng.gen_range(-4..=4_i32);
    let blur_sigma = rng.gen_range(0.0..=0.8_f32);
    let sp_ratio = rng.gen_range(0.0..=0.02_f32);

    let scaled = scale_centered(base, scale);
    let rotated = rotate_image(&scaled, angle_deg.to_radians());
    let translated = translate_xy(&rotated, tx, ty);
    let blurred = if blur_sigma > 0.05 {
        imageproc::filter::gaussian_blur_f32(&translated, blur_sigma)
    } else {
        translated
    };
    let mut current = salt_pepper(&blurred, sp_ratio, rng);

    // Staff-Removal-Artefakte: nur am Patch-Rand (oben/unten 1/4),
    // nicht im Zentrum wo das Symbol liegt.
    if rng.gen_bool(0.3) {
        current = add_edge_staff_artifacts(&current, rng);
    }

    debug_assert_eq!(current.width(), size);
    current
}

/// Fügt horizontale Striche NUR am oberen oder unteren Rand hinzu.
/// Das simuliert Stafflinien-Reste angrenzend an einen Notenkopf.
fn add_edge_staff_artifacts(src: &GrayImage, rng: &mut ChaCha8Rng) -> GrayImage {
    let mut dst = src.clone();
    let h = dst.height();
    let w = dst.width();
    let edge_zone = h / 4;
    // 1 Strich am oberen oder unteren Rand
    let y = if rng.gen_bool(0.5) {
        rng.gen_range(0..edge_zone)
    } else {
        rng.gen_range(h - edge_zone..h)
    };
    let length = rng.gen_range(w / 2..w);
    let x_start = rng.gen_range(0..w - length + 1);
    for x in x_start..x_start + length {
        dst.put_pixel(x, y, Luma([255]));
    }
    dst
}

/// Translation in beide Richtungen.
fn translate_xy(src: &GrayImage, tx: i32, ty: i32) -> GrayImage {
    if tx == 0 && ty == 0 {
        return src.clone();
    }
    let w = src.width();
    let h = src.height();
    let mut dst = GrayImage::from_pixel(w, h, Luma([0u8]));
    for y in 0..h {
        for x in 0..w {
            let sx = x as i32 - tx;
            let sy = y as i32 - ty;
            if sx >= 0 && sy >= 0 && (sx as u32) < w && (sy as u32) < h {
                dst.put_pixel(x, y, *src.get_pixel(sx as u32, sy as u32));
            }
        }
    }
    dst
}

/// Skaliert ein quadratisches Patch um den Mittelpunkt mit Nearest-Neighbor.
fn scale_centered(src: &GrayImage, scale: f32) -> GrayImage {
    let w = src.width();
    let h = src.height();
    if (scale - 1.0).abs() < 1e-3 {
        return src.clone();
    }
    let cx = w as f32 / 2.0;
    let cy = h as f32 / 2.0;
    let mut dst = GrayImage::from_pixel(w, h, Luma([0u8]));
    for y in 0..h {
        for x in 0..w {
            let sx = ((x as f32 - cx) / scale + cx).round() as i32;
            let sy = ((y as f32 - cy) / scale + cy).round() as i32;
            if sx >= 0 && sy >= 0 && (sx as u32) < w && (sy as u32) < h {
                let p = src.get_pixel(sx as u32, sy as u32);
                dst.put_pixel(x, y, *p);
            }
        }
    }
    dst
}

/// Rotation um den Bildmittelpunkt mit Bilinear-Interpolation.
fn rotate_image(src: &GrayImage, angle_rad: f32) -> GrayImage {
    if angle_rad.abs() < 1e-4 {
        return src.clone();
    }
    imageproc::geometric_transformations::rotate_about_center(
        src,
        angle_rad,
        imageproc::geometric_transformations::Interpolation::Bilinear,
        Luma([0u8]),
    )
}

/// Salt-Pepper-Rauschen mit gegebenem Anteil.
fn salt_pepper(src: &GrayImage, ratio: f32, rng: &mut ChaCha8Rng) -> GrayImage {
    if ratio <= 0.0 {
        return src.clone();
    }
    let w = src.width();
    let h = src.height();
    let mut dst = src.clone();
    let n = ((w * h) as f32 * ratio) as u32;
    for _ in 0..n {
        let x = rng.gen_range(0..w);
        let y = rng.gen_range(0..h);
        let v: u8 = if rng.gen_bool(0.5) { 0 } else { 255 };
        dst.put_pixel(x, y, Luma([v]));
    }
    dst
}

/// Erzeugt das vollständige Trainings-Korpus über alle Klassen.
///
/// `variants_per_class` ist die Zielanzahl Templates pro Klasse (inkl. Basis).
/// Der Aufruf ist deterministisch in `seed`.
pub fn generate_training_corpus(
    size_px: u32,
    variants_per_class: usize,
    seed: u64,
) -> Vec<(GrayImage, SymbolClass)> {
    let mut out = Vec::with_capacity(SymbolClass::ALL.len() * variants_per_class);
    for class in SymbolClass::ALL {
        let imgs = render_smufl_class_with(*class, size_px, variants_per_class, seed);
        for img in imgs {
            out.push((img, *class));
        }
    }
    out
}

/// Schreibt das Trainings-Korpus als PNG-Dateien nach `out_dir/<label>/<id>.png`.
pub fn write_corpus_to_disk(
    out_dir: impl AsRef<Path>,
    size_px: u32,
    variants_per_class: usize,
    seed: u64,
) -> std::io::Result<usize> {
    let out_dir = out_dir.as_ref();
    let mut written = 0usize;
    for class in SymbolClass::ALL {
        let class_dir = out_dir.join(class.label());
        std::fs::create_dir_all(&class_dir)?;
        let imgs = render_smufl_class_with(*class, size_px, variants_per_class, seed);
        for (i, img) in imgs.iter().enumerate() {
            let path = class_dir.join(format!("{:04}.png", i));
            img.save(&path).map_err(|e| {
                std::io::Error::new(std::io::ErrorKind::Other, format!("png save: {e}"))
            })?;
            written += 1;
        }
    }
    Ok(written)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn font_loads() {
        assert!(BRAVURA_OTF.len() > 100_000, "Bravura.otf scheint zu klein");
        let font = fontdue::Font::from_bytes(BRAVURA_OTF, fontdue::FontSettings::default());
        assert!(font.is_ok());
    }

    #[test]
    fn determinism() {
        let a = render_smufl_class_with(SymbolClass::NoteheadFilled, 32, 5, 42);
        let b = render_smufl_class_with(SymbolClass::NoteheadFilled, 32, 5, 42);
        assert_eq!(a.len(), b.len());
        for (x, y) in a.iter().zip(b.iter()) {
            assert_eq!(x.as_raw(), y.as_raw());
        }
    }
}
