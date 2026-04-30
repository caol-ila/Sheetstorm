// Integrationstests für das U-Net-Staff-Removal.
//
// Diese Tests werden nur ausgeführt, wenn die Umgebungsvariable
// `SHEETSTORM_UNET_MODEL` auf eine gültige ONNX-Datei zeigt — sonst
// `#[ignore]`. So bleibt `cargo test --workspace` grün, auch wenn kein
// Modell in der Entwicklungsumgebung vorhanden ist.
//
// Workflow zum Ausführen lokal:
//   $env:SHEETSTORM_UNET_MODEL = "C:\path\to\staff-removal-unet.onnx"
//   cargo test -p omr-staff --features unet -- --ignored

use omr_core::Binary;

/// Rendert ein synthetisches Bild mit 5 sauberen Stafflinien und einer
/// einzelnen offenen Notenkopf-Ellipse, die zwei Linien kreuzt.
/// Erwartung U-Net: Linien weg, Open-Note-Ellipse intakt.
/// Erwartung RLE  : Open-Note in Halbmonde zerschnitten.
fn make_staff_with_open_note() -> Binary {
    let (w, h) = (400u32, 200u32);
    let mut bin = Binary::new(w, h);
    let spacing = 14u32;
    let line_t = 2u32;
    let base_y = 60u32;
    for line in 0..5u32 {
        let y0 = base_y + line * spacing;
        for t in 0..line_t {
            for x in 5..w - 5 {
                bin.set(x, y0 + t, 1);
            }
        }
    }
    // Offene Notenkopf-Ellipse: zentriert auf Linie 2, kreuzt Linie 1+2+3.
    let cx = 200i32;
    let cy = (base_y + 2 * spacing) as i32;
    let rx = 9i32;
    let ry = 7i32;
    let stroke = 2i32;
    for dy in -ry - stroke..=ry + stroke {
        for dx in -rx - stroke..=rx + stroke {
            let inside_outer =
                (dx * dx) as f32 / ((rx + stroke) * (rx + stroke)) as f32
                    + (dy * dy) as f32 / ((ry + stroke) * (ry + stroke)) as f32
                    <= 1.0;
            let inside_inner =
                (dx * dx) as f32 / (rx * rx) as f32 + (dy * dy) as f32 / (ry * ry) as f32 <= 1.0;
            if inside_outer && !inside_inner {
                let x = cx + dx;
                let y = cy + dy;
                if x >= 0 && y >= 0 && (x as u32) < bin.w && (y as u32) < bin.h {
                    bin.set(x as u32, y as u32, 1);
                }
            }
        }
    }
    bin
}

fn model_path_from_env() -> Option<std::path::PathBuf> {
    std::env::var_os("SHEETSTORM_UNET_MODEL").map(std::path::PathBuf::from)
}

#[test]
#[ignore = "requires SHEETSTORM_UNET_MODEL pointing to an ONNX U-Net (run with --ignored)"]
#[cfg(feature = "unet")]
fn unet_removes_stafflines_keeps_open_note() {
    let path = model_path_from_env().expect(
        "SHEETSTORM_UNET_MODEL not set — required for U-Net integration test",
    );
    let bin = make_staff_with_open_note();

    let removed =
        omr_staff::try_remove_staff_unet(&bin, &path).expect("U-Net inference must succeed");

    // Der Großteil der Stafflinien-Pixel muss weg sein.
    assert!(
        removed.count() < bin.count() / 2,
        "expected staff lines mostly removed, before={} after={}",
        bin.count(),
        removed.count()
    );

    // Die offene Note sollte als zusammenhängender CC ihrer Größe
    // erhalten bleiben — wir prüfen pragmatisch via Pixelzählung in der
    // Notenkopf-Bounding-Box.
    let nh_pixels = count_in_box(&removed, 200 - 12, 200 + 12, 88 - 10, 88 + 10);
    assert!(
        nh_pixels > 30,
        "open note pixels in bbox should be largely intact, got {}",
        nh_pixels
    );
}

#[test]
#[cfg(not(feature = "unet"))]
fn try_remove_staff_unet_returns_none_without_feature() {
    let bin = make_staff_with_open_note();
    let r = omr_staff::try_remove_staff_unet(&bin, std::path::Path::new("nonexistent.onnx"));
    assert!(r.is_none(), "without `unet` feature, U-Net path must always fall through");
}

#[test]
#[cfg(feature = "unet")]
fn try_remove_staff_unet_returns_none_for_missing_model() {
    let bin = make_staff_with_open_note();
    let r = omr_staff::try_remove_staff_unet(
        &bin,
        std::path::Path::new("definitely-missing-file.onnx"),
    );
    assert!(r.is_none(), "missing model path must return None, not panic");
}

fn count_in_box(bin: &Binary, x0: i32, x1: i32, y0: i32, y1: i32) -> u32 {
    let mut n = 0u32;
    for y in y0.max(0)..(y1.min(bin.h as i32)) {
        for x in x0.max(0)..(x1.min(bin.w as i32)) {
            if bin.get(x as u32, y as u32) == 1 {
                n += 1;
            }
        }
    }
    n
}
