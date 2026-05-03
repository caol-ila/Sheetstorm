//! Pipeline-Hülle für das Labeling-Tool.
//!
//! Sammelt PDFs aus einem Filestore, rendert sie (best effort, fällt
//! still zurück, wenn pdfium nicht verfügbar ist), erkennt Staff-Systeme
//! und extrahiert pro System einfache Element-Patches (Connected
//! Components nach Staff-Removal). HoG-Embeddings werden für jedes
//! Element berechnet.

use anyhow::Result;
use image::{DynamicImage, GrayImage, ImageBuffer, Luma};
use omr_core::{Binary, Rect, StaffSystem};
use omr_embed::{Encoder, HogEncoder};
use std::path::{Path, PathBuf};

pub type SystemId = String;
pub type ElementId = String;

#[derive(Debug, Clone)]
pub struct RectifiedSystem {
    pub id: SystemId,
    pub image: GrayImage,
    pub page: usize,
    pub system_idx: usize,
    pub bbox_top: u32,
    pub bbox_bottom: u32,
}

#[derive(Debug, Clone)]
pub struct DetectedElement {
    pub id: ElementId,
    pub system_id: SystemId,
    pub bbox: Rect,
    pub patch: GrayImage,
    pub suggested_class: Option<String>,
    pub hog_embedding: Vec<f32>,
}

#[derive(Default)]
pub struct PipelineState {
    pub pdf_paths: Vec<PathBuf>,
    pub systems: Vec<RectifiedSystem>,
    pub elements: Vec<DetectedElement>,
}

impl PipelineState {
    pub fn new() -> Self {
        Self::default()
    }

    /// Rekursiver Walk durch `dir`; sammelt alle `*.pdf`-Dateien.
    pub fn scan_filestore(dir: &Path) -> Vec<PathBuf> {
        let mut out = Vec::new();
        if !dir.exists() {
            return out;
        }
        let mut stack = vec![dir.to_path_buf()];
        while let Some(d) = stack.pop() {
            let entries = match std::fs::read_dir(&d) {
                Ok(e) => e,
                Err(_) => continue,
            };
            for entry in entries.flatten() {
                let p = entry.path();
                if p.is_dir() {
                    stack.push(p);
                } else if let Some(ext) = p.extension().and_then(|s| s.to_str()) {
                    if ext.eq_ignore_ascii_case("pdf") {
                        out.push(p);
                    }
                }
            }
        }
        out.sort();
        out
    }

    /// Pre-Process eine PDF-Datei. Liefert die Anzahl der hinzugefügten
    /// Systeme. Falls pdfium nicht verfügbar ist, wird eine Warnung
    /// geloggt und die Methode mit 0 zurückgegeben (kein Panic).
    pub fn pre_process_pdf(&mut self, pdf: &Path) -> Result<usize> {
        let pages = match render_pages_safe(pdf, 200) {
            Ok(p) => p,
            Err(err) => {
                tracing::warn!(
                    "pdfium nicht verfügbar oder PDF nicht lesbar — überspringe {}: {}",
                    pdf.display(),
                    err
                );
                return Ok(0);
            }
        };

        let encoder = HogEncoder::new();
        let mut added_systems = 0usize;

        for (page_idx, gray) in pages.into_iter().enumerate() {
            let bin = Binary::threshold_global(&gray, 128);
            let systems = omr_staff::detect_systems(&bin);
            if systems.is_empty() {
                continue;
            }
            let staff_removed = omr_staff::remove_staff(&bin, &systems);
            for (sys_idx, system) in systems.iter().enumerate() {
                let (top, bottom) = system_bbox(&gray, system);
                let crop_h = bottom.saturating_sub(top).max(1);
                let cropped = sub_image(&gray, 0, top, gray.width(), crop_h);
                let rectified = rectify_system(&cropped, system, top);
                let id: SystemId =
                    format!("{}#p{}s{}", short_id(pdf), page_idx, sys_idx);

                let cropped_removed = sub_image(
                    &binary_to_gray(&staff_removed),
                    0,
                    top,
                    gray.width(),
                    crop_h,
                );
                let rects = detect_elements(&cropped_removed, system, top);

                for (elt_idx, r) in rects.iter().enumerate() {
                    let patch = extract_patch(&cropped, r, 64);
                    let emb = encoder
                        .embed(&patch)
                        .map(|e| e.vec)
                        .unwrap_or_default();
                    let elt_id = format!("{}#e{}", id, elt_idx);
                    self.elements.push(DetectedElement {
                        id: elt_id,
                        system_id: id.clone(),
                        bbox: *r,
                        patch,
                        suggested_class: None,
                        hog_embedding: emb,
                    });
                }

                self.systems.push(RectifiedSystem {
                    id,
                    image: rectified,
                    page: page_idx,
                    system_idx: sys_idx,
                    bbox_top: top,
                    bbox_bottom: bottom,
                });
                added_systems += 1;
            }
        }
        Ok(added_systems)
    }
}

/// Wrapper um `pdf_render::render_pages`, fängt Panics ab und liefert
/// einen ordentlichen Result.
fn render_pages_safe(pdf: &Path, dpi: u32) -> Result<Vec<GrayImage>> {
    let res = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        omr_pipeline::pdf_render::render_pages(pdf, dpi)
    }));
    match res {
        Ok(Ok(v)) => Ok(v),
        Ok(Err(e)) => Err(anyhow::anyhow!("{}", e)),
        Err(_) => Err(anyhow::anyhow!("pdfium-Panic abgefangen")),
    }
}

fn short_id(p: &Path) -> String {
    p.file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("unknown")
        .replace(' ', "_")
}

fn sub_image(img: &GrayImage, x: u32, y: u32, w: u32, h: u32) -> GrayImage {
    let w = w.min(img.width().saturating_sub(x));
    let h = h.min(img.height().saturating_sub(y));
    let mut out: GrayImage = ImageBuffer::new(w.max(1), h.max(1));
    for yy in 0..h {
        for xx in 0..w {
            out.put_pixel(xx, yy, *img.get_pixel(x + xx, y + yy));
        }
    }
    out
}

fn binary_to_gray(bin: &Binary) -> GrayImage {
    bin.to_gray()
}

/// Bbox-Approximation eines Systems: minY der obersten Linie, maxY der
/// untersten Linie, plus etwa eine Linienhöhe Polster.
fn system_bbox(_gray: &GrayImage, system: &StaffSystem) -> (u32, u32) {
    let top = system
        .lines
        .first()
        .map(|l| l.mean_y())
        .unwrap_or(0.0);
    let bot = system
        .lines
        .last()
        .map(|l| l.mean_y())
        .unwrap_or(top);
    let pad = (system.line_spacing * 4.0).max(8.0);
    let top = (top - pad).max(0.0) as u32;
    let bot = (bot + pad) as u32;
    (top, bot)
}

/// Vereinfachte Rectification: pro X-Spalte wird ein vertikaler Shift
/// angewandt, sodass die Mittellinie auf eine horizontale Linie
/// projiziert wird. Das ist eine Light-Variante eines affinen Warps und
/// ohne `imageproc`-Abhängigkeit umsetzbar.
fn rectify_system(crop: &GrayImage, system: &StaffSystem, top_offset: u32) -> GrayImage {
    let w = crop.width();
    let h = crop.height();
    if h == 0 || w == 0 || system.lines.is_empty() {
        return crop.clone();
    }
    let target_mid = (h as f32) * 0.5;
    let mut out: GrayImage = ImageBuffer::from_pixel(w, h, Luma([255u8]));
    for x in 0..w {
        // Mittlere Y-Position der mittleren Linie an dieser Spalte.
        let mid_idx = system.lines.len() / 2;
        let y_mid = system
            .line_y_at(mid_idx, x)
            .unwrap_or_else(|| system.middle_y());
        let local_mid = (y_mid - top_offset as f32).max(0.0);
        let shift = (target_mid - local_mid).round() as i32;
        for y in 0..h as i32 {
            let src_y = y - shift;
            if src_y < 0 || src_y >= h as i32 {
                continue;
            }
            let p = *crop.get_pixel(x, src_y as u32);
            out.put_pixel(x, y as u32, p);
        }
    }
    out
}

/// Extrahiert Connected-Components-Bboxes aus dem (staff-removed)
/// System-Crop. Bewusst sehr einfach: 4-Connectivity, BFS, Filter auf
/// Mindestgröße.
fn detect_elements(crop: &GrayImage, system: &StaffSystem, _top_offset: u32) -> Vec<Rect> {
    let w = crop.width() as i32;
    let h = crop.height() as i32;
    if w == 0 || h == 0 {
        return Vec::new();
    }
    let n = (w * h) as usize;
    let mut seen = vec![false; n];
    let min_dim = ((system.line_spacing * 0.5).max(3.0)) as i32;
    let max_dim = ((system.line_spacing * 10.0).max(64.0)) as i32;

    let is_fg = |x: i32, y: i32| -> bool {
        if x < 0 || y < 0 || x >= w || y >= h {
            return false;
        }
        crop.get_pixel(x as u32, y as u32)[0] < 128
    };

    let mut rects = Vec::new();
    let mut queue: std::collections::VecDeque<(i32, i32)> = std::collections::VecDeque::new();

    for sy in 0..h {
        for sx in 0..w {
            let idx = (sy * w + sx) as usize;
            if seen[idx] || !is_fg(sx, sy) {
                continue;
            }
            queue.clear();
            queue.push_back((sx, sy));
            seen[idx] = true;
            let mut min_x = sx;
            let mut min_y = sy;
            let mut max_x = sx;
            let mut max_y = sy;
            let mut size = 0u32;
            while let Some((x, y)) = queue.pop_front() {
                size += 1;
                min_x = min_x.min(x);
                min_y = min_y.min(y);
                max_x = max_x.max(x);
                max_y = max_y.max(y);
                for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                    let nx = x + dx;
                    let ny = y + dy;
                    if nx < 0 || ny < 0 || nx >= w || ny >= h {
                        continue;
                    }
                    let nidx = (ny * w + nx) as usize;
                    if seen[nidx] || !is_fg(nx, ny) {
                        continue;
                    }
                    seen[nidx] = true;
                    queue.push_back((nx, ny));
                }
            }
            let bw = max_x - min_x + 1;
            let bh = max_y - min_y + 1;
            if bw < min_dim || bh < min_dim {
                continue;
            }
            if bw > max_dim * 4 || bh > max_dim {
                continue;
            }
            if size < 8 {
                continue;
            }
            rects.push(Rect {
                x: min_x as u32,
                y: min_y as u32,
                w: bw as u32,
                h: bh as u32,
            });
        }
    }
    rects
}

/// Schneidet einen Patch aus einem System-Crop und resampled ihn auf
/// `target × target` mittels Nearest-Neighbor.
pub fn extract_patch(crop: &GrayImage, r: &Rect, target: u32) -> GrayImage {
    let sub = sub_image(crop, r.x, r.y, r.w, r.h);
    let resized = resize_nn(&sub, target, target);
    resized
}

fn resize_nn(src: &GrayImage, w: u32, h: u32) -> GrayImage {
    let mut dst = GrayImage::new(w.max(1), h.max(1));
    let sw = src.width().max(1) as f32;
    let sh = src.height().max(1) as f32;
    for y in 0..dst.height() {
        for x in 0..dst.width() {
            let sx = ((x as f32 + 0.5) * sw / dst.width() as f32).floor() as u32;
            let sy = ((y as f32 + 0.5) * sh / dst.height() as f32).floor() as u32;
            let sx = sx.min(src.width().saturating_sub(1));
            let sy = sy.min(src.height().saturating_sub(1));
            dst.put_pixel(x, y, *src.get_pixel(sx, sy));
        }
    }
    dst
}

/// Hilfsfunktion: kodiert ein GrayImage als PNG-Bytes.
pub fn encode_png(img: &GrayImage) -> Result<Vec<u8>> {
    let mut buf: Vec<u8> = Vec::new();
    let dyn_img = DynamicImage::ImageLuma8(img.clone());
    dyn_img.write_to(
        &mut std::io::Cursor::new(&mut buf),
        image::ImageFormat::Png,
    )?;
    Ok(buf)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::File;
    use std::io::Write;

    fn make_test_dir(suffix: &str) -> std::path::PathBuf {
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or(0);
        let dir = std::env::temp_dir().join(format!("omr-labeler-test-{}-{}", suffix, nanos));
        std::fs::create_dir_all(&dir).unwrap();
        dir
    }

    #[test]
    fn scan_filestore_finds_pdfs() {
        let dir = make_test_dir("scan");
        let p1 = dir.join("a.pdf");
        let p2 = dir.join("sub").join("b.pdf");
        let p3 = dir.join("c.txt");
        std::fs::create_dir_all(dir.join("sub")).unwrap();
        File::create(&p1).unwrap().write_all(b"x").unwrap();
        File::create(&p2).unwrap().write_all(b"x").unwrap();
        File::create(&p3).unwrap().write_all(b"x").unwrap();

        let found = PipelineState::scan_filestore(&dir);
        assert_eq!(found.len(), 2);
        assert!(found.iter().any(|p| p.ends_with("a.pdf")));
        assert!(found.iter().any(|p| p.ends_with("b.pdf")));

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn scan_filestore_handles_missing_dir() {
        let v = PipelineState::scan_filestore(Path::new("Z:/does-not-exist-12345"));
        assert!(v.is_empty());
    }
}
