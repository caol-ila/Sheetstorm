// PDF-Render → Grayscale-Bild via pdfium-render.

use image::GrayImage;
use omr_core::{OmrError, Result};
use std::path::Path;

/// Rendere alle Seiten eines PDF mit gegebener DPI.
pub fn render_pages(path: &Path, dpi: u32) -> Result<Vec<GrayImage>> {
    use pdfium_render::prelude::*;

    // Lade pdfium-Bibliothek aus Standard-Pfaden.
    let bindings = Pdfium::bind_to_system_library()
        .or_else(|_| Pdfium::bind_to_library(Pdfium::pdfium_platform_library_name_at_path("./")))
        .map_err(|e| OmrError::PdfRender(format!("pdfium-Library nicht ladbar: {}", e)))?;
    let pdfium = Pdfium::new(bindings);

    let document = pdfium
        .load_pdf_from_file(path, None)
        .map_err(|e| OmrError::PdfRender(format!("PDF-Load fehlgeschlagen: {}", e)))?;

    let cfg = PdfRenderConfig::new()
        .scale_page_by_factor(dpi as f32 / 72.0);

    let mut images = Vec::new();
    for (idx, page) in document.pages().iter().enumerate() {
        let bitmap = page.render_with_config(&cfg)
            .map_err(|e| OmrError::PdfRender(format!("Seite {}: {}", idx + 1, e)))?;
        let dynamic = bitmap.as_image();
        let gray = dynamic.to_luma8();
        images.push(gray);
    }
    Ok(images)
}
