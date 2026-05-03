//! Pipeline-Hülle für das Labeling-Tool.
//!
//! Sammelt PDFs aus einem Filestore, rendert sie (best effort, fällt
//! still zurück, wenn pdfium nicht verfügbar ist), erkennt Staff-Systeme
//! und extrahiert pro System einfache Element-Patches (Connected
//! Components nach Staff-Removal). HoG-Embeddings werden für jedes
//! Element berechnet.

use anyhow::Result;
use image::{DynamicImage, GrayImage, ImageBuffer, Luma};
use omr_core::{Binary, Rect, StaffLine, StaffSystem};
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
    /// Vollständiges Page-Bild (ungeschnitten), gleiche Page-Index.
    /// Wird für Kontext-View benötigt (oben/unten drumrum).
    pub page_image: GrayImage,
    /// Y-Offset des Systems im Page-Bild (top in page-Koordinaten).
    pub page_top: u32,
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
    ///
    /// Filtert automatisch:
    /// - Test-/Junk-Files mit Pattern "conduct" oder "test" im Filename
    /// - Bekannte Multi-Staff-Stuecke (Klavier-Begleitung), die kein Blasmusik-
    ///   Material sind (Dichterliebe, Schumann, Klavier).
    /// - Files unter 1 KB (offensichtlich kaputt)
    ///
    /// Damit landen nur realistische Single-Staff-Blasmusik-Stimmen im Tool.
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
                    if !ext.eq_ignore_ascii_case("pdf") {
                        continue;
                    }
                    if !is_realistic_blasmusik_pdf(&p) {
                        tracing::debug!("Filter: ueberspringe {} (kein Blasmusik-Material)", p.display());
                        continue;
                    }
                    out.push(p);
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
            // Filter: ueberspringe Multi-Staff-Seiten (Klavier-Grand-Staff,
            // Chor-Partitur o.ae.). Blasmusik-Stimmen sind immer Single-Staff
            // pro Zeile. Heuristik: wenn zwei aufeinanderfolgende Systeme
            // weniger als 3.5 * line_spacing voneinander entfernt sind,
            // gehoeren sie wahrscheinlich zu einem Grand-Staff/Bracket.
            if is_multi_staff_page(&systems) {
                tracing::info!(
                    "{}#p{}: multi-staff page detected — skipping (kein Blasmusik-Material)",
                    short_id(pdf),
                    page_idx
                );
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
                let rects_raw = detect_elements(&cropped_removed, system, top);

                // Logical-Groups + Slurs: das sind die *primaeren* Elemente.
                // Atome die zu einer Gruppe gehoeren werden NICHT einzeln gelabelt.
                let noteheads = omr_symbols::detect_noteheads(&staff_removed, std::slice::from_ref(system));
                let stems = omr_symbols::stems::detect_stems(&staff_removed, &noteheads, system.line_spacing);
                let beams = omr_symbols::detect_beams(&staff_removed, system.line_spacing);
                let adjusted_system = adjust_system_to_crop(system, top);
                let logical_groups = omr_symbols::detect_logical_groups(
                    &noteheads,
                    &stems,
                    &beams,
                    adjusted_system.line_spacing,
                );
                let slurs = omr_symbols::slurs::detect_slurs(
                    &staff_removed,
                    &noteheads,
                    std::slice::from_ref(system),
                );

                // Sammle "primary elements":
                // 1. Logical Groups (BeamedGroup, ChordCluster, ...) — bbox + class_id
                // 2. Slurs/Ties — werden mit ueberlapenden Logical Groups
                //    zu einem grossen Element zusammengezogen
                // 3. Standalone CC-Rects die NICHT von einer Group abgedeckt
                //    sind (Clefs, KeySigs, TimeSigs, isolierte Symbole)
                //    — gemerged via merge_close_rects (4/4-Taktangabe!)
                let mut primary_elements: Vec<(Rect, Option<String>)> = Vec::new();

                // Step A: Logical groups, mit Slur-Erweiterung wenn vorhanden
                let mut logical_used = vec![false; logical_groups.len()];
                let mut slur_used = vec![false; slurs.len()];

                for (gi, g) in logical_groups.iter().enumerate() {
                    if logical_used[gi] {
                        continue;
                    }
                    logical_used[gi] = true;
                    // crop-koordinaten — Logical groups sind in page-koordinaten,
                    // slur bbox ebenfalls. Beide in crop-rel transformieren.
                    let mut bbox = rect_to_crop(&g.bbox, top);
                    let mut class_id = Some(g.class_id.clone());

                    // Pruefe Slurs die mit dieser Group ueberlappen
                    for (si, s) in slurs.iter().enumerate() {
                        if slur_used[si] {
                            continue;
                        }
                        if rects_overlap_or_touch(&g.bbox, &s.bbox, system.line_spacing) {
                            // Bbox erweitern, klasse auf 'slurred' setzen wenn klein,
                            // sonst class behalten + Slur hinzufuegen.
                            slur_used[si] = true;
                            let s_crop = rect_to_crop(&s.bbox, top);
                            bbox = union_rect(bbox, s_crop);
                            if class_id.as_deref() == Some("group/single_note")
                                || class_id.as_deref() == Some("group/single_note_quarter")
                            {
                                class_id = Some(if s.is_tie {
                                    "group/tied_pair".to_string()
                                } else {
                                    "group/slurred_phrase".to_string()
                                });
                            }
                            // Auch andere Logical Groups die unter dem Slur liegen mergen
                            for (gj, g2) in logical_groups.iter().enumerate() {
                                if logical_used[gj] {
                                    continue;
                                }
                                if rects_overlap_or_touch(&g2.bbox, &s.bbox, system.line_spacing) {
                                    logical_used[gj] = true;
                                    let g2_crop = rect_to_crop(&g2.bbox, top);
                                    bbox = union_rect(bbox, g2_crop);
                                    if !s.is_tie {
                                        class_id = Some("group/slurred_phrase".to_string());
                                    }
                                }
                            }
                        }
                    }
                    primary_elements.push((bbox, class_id));
                }

                // Step B: Slurs ohne uebersnappende Logical Groups
                for (si, s) in slurs.iter().enumerate() {
                    if slur_used[si] {
                        continue;
                    }
                    let bbox = rect_to_crop(&s.bbox, top);
                    let class_id = if s.is_tie {
                        "group/tied_pair".to_string()
                    } else {
                        "group/slurred_phrase".to_string()
                    };
                    primary_elements.push((bbox, Some(class_id)));
                }

                // Step C: CC-Rects die NICHT in einem Logical-Group/Slur liegen
                // werden gemerged + als standalone-Elements aufgenommen.
                let standalone_rects: Vec<Rect> = rects_raw
                    .iter()
                    .filter(|r| {
                        !primary_elements.iter().any(|(pb, _)| rect_iou_or_inside(r, pb) > 0.4)
                    })
                    .copied()
                    .collect();
                let standalone_merged = merge_close_rects(&standalone_rects, system.line_spacing);
                for r in standalone_merged {
                    primary_elements.push((r, None));
                }

                // X-sortieren fuer stabiles Labeling-Ordering.
                primary_elements.sort_by_key(|(r, _)| (r.x, r.y));

                for (elt_idx, (r, class_id)) in primary_elements.iter().enumerate() {
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
                        suggested_class: class_id.clone(),
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
                    page_image: gray.clone(),
                    page_top: top,
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

/// Filter: ist eine PDF realistisches Blasmusik-Material?
///
/// Skip-Liste basiert auf User-Vorgabe: "fast alle unsere Noten sind nur eine
/// Stimme oder maximal 2 stimmen aber in der gleichen Zeile. Wir haben keine
/// noten mit mehreren Systemen."
///
/// - Skip Files unter 1 KB (Junk-Uploads, leere Test-Files)
/// - Skip Filenames mit "conduct" / "test" / "demo" / "sample" (Test-Daten)
/// - Skip Multi-Staff-Stuecke nach Filename: "Dichterliebe", "Schumann",
///   "Klavier", "piano-trio", etc.
fn is_realistic_blasmusik_pdf(path: &Path) -> bool {
    let meta = match std::fs::metadata(path) {
        Ok(m) => m,
        Err(_) => return false,
    };
    if meta.len() < 1024 {
        return false;
    }
    let name = match path.file_name().and_then(|s| s.to_str()) {
        Some(s) => s.to_ascii_lowercase(),
        None => return true,
    };
    // Skip Junk/Test-Uploads
    for skip in [
        "conduct",
        "sheetstorm-test",
        "sheetstorm-demo",
        "sheetstorm-sample",
    ] {
        if name.contains(skip) {
            return false;
        }
    }
    // Skip Multi-Staff-Stuecke (Klavier-Begleitung, Lieder, Klavier-Trios)
    for skip in [
        "dichterliebe",
        "schumann",
        "klaviertrio",
        "piano-trio",
        "klaviersonate",
        "piano-sonata",
        "lied-",
        "_lied_",
    ] {
        if name.contains(skip) {
            return false;
        }
    }
    true
}

/// Erkennt ob eine Page Multi-Staff-Material enthaelt (Klavier-Grand-Staff,
/// Chor-Partitur, Orchestral-Score). Solche Seiten sind kein realistisches
/// Blasmusik-Material und werden im Labeler ausgeblendet.
///
/// Heuristik: zwei Systeme die weniger als 3.5 × line_spacing voneinander
/// entfernt liegen gehoeren wahrscheinlich zu einem Grand-Staff oder Bracket.
/// Bei Blasmusik-Stimmen sind aufeinanderfolgende Zeilen ueblicherweise
/// 4-8 × line_spacing voneinander entfernt.
fn is_multi_staff_page(systems: &[StaffSystem]) -> bool {
    if systems.len() < 2 {
        return false;
    }
    let mut sorted: Vec<(f32, f32)> = systems
        .iter()
        .map(|s| {
            let top_y = s.lines.first().map(|l| l.mean_y()).unwrap_or(0.0);
            let bot_y = s.lines.last().map(|l| l.mean_y()).unwrap_or(0.0);
            (top_y, bot_y)
        })
        .collect();
    sorted.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap_or(std::cmp::Ordering::Equal));
    for w in sorted.windows(2) {
        let gap = w[1].0 - w[0].1;
        let line_spacing = systems[0].line_spacing.max(1.0);
        if gap < line_spacing * 3.5 {
            return true;
        }
    }
    false
}

/// Konvertiert eine Page-Rect in eine Crop-Rect (top wird abgezogen).
fn rect_to_crop(r: &Rect, top: u32) -> Rect {
    Rect {
        x: r.x,
        y: r.y.saturating_sub(top),
        w: r.w,
        h: r.h,
    }
}

/// Vereinigt zwei Rects.
fn union_rect(a: Rect, b: Rect) -> Rect {
    let x0 = a.x.min(b.x);
    let y0 = a.y.min(b.y);
    let x1 = (a.x + a.w).max(b.x + b.w);
    let y1 = (a.y + a.h).max(b.y + b.h);
    Rect {
        x: x0,
        y: y0,
        w: x1.saturating_sub(x0),
        h: y1.saturating_sub(y0),
    }
}

/// Pruefe ob zwei Rects ueberlappen ODER nahe genug sind (Lücke <= tol).
fn rects_overlap_or_touch(a: &Rect, b: &Rect, line_spacing: f32) -> bool {
    let tol = (line_spacing * 0.6).max(3.0) as i32;
    let ax0 = a.x as i32;
    let ax1 = (a.x + a.w) as i32;
    let bx0 = b.x as i32;
    let bx1 = (b.x + b.w) as i32;
    let dx = if ax1 < bx0 {
        bx0 - ax1
    } else if bx1 < ax0 {
        ax0 - bx1
    } else {
        0
    };
    let ay0 = a.y as i32;
    let ay1 = (a.y + a.h) as i32;
    let by0 = b.y as i32;
    let by1 = (b.y + b.h) as i32;
    let dy = if ay1 < by0 {
        by0 - ay1
    } else if by1 < ay0 {
        ay0 - by1
    } else {
        0
    };
    dx <= tol && dy <= tol
}

/// Wie viel Prozent von rect r sind innerhalb von rect target (oder
/// touchen). Returns 1.0 wenn r komplett in target liegt.
/// (Note: r und target koennen in unterschiedlichen Koordinatensystemen
/// sein. Diese Funktion vergleicht direkt; Aufrufer muss dafuer sorgen
/// dass sie kompatibel sind.)
fn rect_iou_or_inside(r: &Rect, target: &Rect) -> f32 {
    let rx0 = r.x;
    let ry0 = r.y;
    let rx1 = r.x + r.w;
    let ry1 = r.y + r.h;
    let tx0 = target.x;
    let ty0 = target.y;
    let tx1 = target.x + target.w;
    let ty1 = target.y + target.h;
    let ix0 = rx0.max(tx0);
    let iy0 = ry0.max(ty0);
    let ix1 = rx1.min(tx1);
    let iy1 = ry1.min(ty1);
    if ix0 >= ix1 || iy0 >= iy1 {
        return 0.0;
    }
    let inter = ((ix1 - ix0) as f32) * ((iy1 - iy0) as f32);
    let r_area = (r.w as f32) * (r.h as f32);
    if r_area <= 0.0 {
        return 0.0;
    }
    inter / r_area
}

/// Merget eng beieinander liegende Bboxes zu Element-Gruppen.
///
/// Zwei Bboxes werden gemerged wenn:
/// - vertikal überlappend ODER fast überlappend (Lücke ≤ 0.5 × line_spacing)
/// - horizontal nahe (Lücke ≤ 0.6 × line_spacing)
///
/// Das löst u.a. das 4/4-Taktangabe-Problem: die zwei Ziffern sind getrennte
/// Pixelinseln aber gehören als ein Element zusammen. Auch Akkorde werden
/// dadurch zu einer Element-Bbox.
///
/// Iteration: Union-Find — repeat bis stabiler Zustand.
fn merge_close_rects(rects: &[Rect], line_spacing: f32) -> Vec<Rect> {
    if rects.is_empty() {
        return Vec::new();
    }
    let n = rects.len();
    // Union-Find
    let mut parent: Vec<usize> = (0..n).collect();
    fn find(p: &mut Vec<usize>, x: usize) -> usize {
        if p[x] != x {
            let r = find(p, p[x]);
            p[x] = r;
        }
        p[x]
    }
    fn union(p: &mut Vec<usize>, a: usize, b: usize) {
        let ra = find(p, a);
        let rb = find(p, b);
        if ra != rb {
            p[ra] = rb;
        }
    }

    let gap_x = (line_spacing * 0.6).max(3.0) as i32;
    let gap_y = (line_spacing * 0.5).max(3.0) as i32;
    for i in 0..n {
        for j in (i + 1)..n {
            let a = &rects[i];
            let b = &rects[j];
            // X-Lücke: 0 wenn überlappen, sonst Distanz
            let ax0 = a.x as i32;
            let ax1 = (a.x + a.w) as i32;
            let bx0 = b.x as i32;
            let bx1 = (b.x + b.w) as i32;
            let dx = if ax1 < bx0 {
                bx0 - ax1
            } else if bx1 < ax0 {
                ax0 - bx1
            } else {
                0
            };
            let ay0 = a.y as i32;
            let ay1 = (a.y + a.h) as i32;
            let by0 = b.y as i32;
            let by1 = (b.y + b.h) as i32;
            let dy = if ay1 < by0 {
                by0 - ay1
            } else if by1 < ay0 {
                ay0 - by1
            } else {
                0
            };
            if dx <= gap_x && dy <= gap_y {
                union(&mut parent, i, j);
            }
        }
    }
    // Group by root
    let mut groups: std::collections::BTreeMap<usize, Vec<usize>> = std::collections::BTreeMap::new();
    for i in 0..n {
        let r = find(&mut parent, i);
        groups.entry(r).or_default().push(i);
    }
    // Compute union-bbox per group
    let mut out = Vec::new();
    for (_root, members) in groups {
        let mut min_x = u32::MAX;
        let mut min_y = u32::MAX;
        let mut max_x = 0u32;
        let mut max_y = 0u32;
        for &i in &members {
            let r = &rects[i];
            min_x = min_x.min(r.x);
            min_y = min_y.min(r.y);
            max_x = max_x.max(r.x + r.w);
            max_y = max_y.max(r.y + r.h);
        }
        if min_x < max_x && min_y < max_y {
            out.push(Rect {
                x: min_x,
                y: min_y,
                w: max_x - min_x,
                h: max_y - min_y,
            });
        }
    }
    // Sort by x for stable ordering
    out.sort_by_key(|r| (r.x, r.y));
    out
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

/// Hilfsfunktion: kodiert ein RGB-Bild (image::RgbImage) als PNG-Bytes.
pub fn encode_png_rgb(img: &image::RgbImage) -> Result<Vec<u8>> {
    let mut buf: Vec<u8> = Vec::new();
    let dyn_img = DynamicImage::ImageRgb8(img.clone());
    dyn_img.write_to(
        &mut std::io::Cursor::new(&mut buf),
        image::ImageFormat::Png,
    )?;
    Ok(buf)
}

/// Passt ein StaffSystem an einen Y-Crop an: verschiebt alle y_per_x-Werte
/// um `top_offset` nach oben (crop-relativ).
fn adjust_system_to_crop(system: &StaffSystem, top_offset: u32) -> StaffSystem {
    StaffSystem {
        lines: system
            .lines
            .iter()
            .map(|l| StaffLine {
                y_per_x: l
                    .y_per_x
                    .iter()
                    .map(|&y| y.saturating_sub(top_offset))
                    .collect(),
            })
            .collect(),
        line_spacing: system.line_spacing,
        line_thickness: system.line_thickness,
    }
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
