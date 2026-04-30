// Debug: scanne ein bereits binarisiertes PNG (von einem CLI-Run) und zeige
// NH-Patches an deren Position das Modell nicht-NH-Klassen vorschlägt.

use omr_symbols::svm_model::HogSvmClassifier;
use omr_symbols::templates::SymbolClass;

#[test]
#[ignore] // braucht echtes Binary-PNG — lokal aktivieren mit `cargo test -- --ignored`
fn debug_classifier_on_real_binary_png() {
    let bin_path = std::env::var("OMR_REAL_BIN_PNG").unwrap_or_else(|_| {
        "C:\\Users\\tmahlberg\\OneDrive\\Noten\\Anja\\Labeled\\sheetstorm-output\\ANGELS\\01_binary.png".into()
    });
    let bin_path = std::path::PathBuf::from(bin_path);
    if !bin_path.exists() {
        println!("Binary PNG not found at {:?}", bin_path);
        return;
    }

    let model_path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join("omr-symbols")
        .join("assets")
        .join("symbol-classifier.bin");
    let classifier = match HogSvmClassifier::load(&model_path) {
        Ok(c) => c,
        Err(e) => {
            println!("classifier not loaded: {e}");
            return;
        }
    };

    let gray = match image::open(&bin_path) {
        Ok(i) => i.to_luma8(),
        Err(e) => {
            println!("PNG load failed: {e}");
            return;
        }
    };
    // Re-konstruiere Binary aus dem PNG (schwarz=1, weiss=0)
    let (w, h) = (gray.width(), gray.height());
    let mut bin = omr_core::Binary::new(w, h);
    for y in 0..h {
        for x in 0..w {
            if gray.get_pixel(x, y)[0] < 128 {
                bin.set(x, y, 1);
            }
        }
    }
    let systems = omr_staff::detect_systems(&bin);
    let removed = omr_staff::remove_staff(&bin, &systems);
    let nhs = omr_symbols::detect_noteheads(&removed, &systems);
    let line_spacing = systems.first().map(|s| s.line_spacing).unwrap_or(16.0);

    println!("=== {} ===", bin_path.display());
    println!("Spacing={line_spacing}, NHs={}", nhs.len());

    let patch_size = ((line_spacing * 1.6).round() as u32).clamp(16, 64);
    let mut by_class: std::collections::HashMap<SymbolClass, u32> =
        std::collections::HashMap::new();
    let mut interesting = Vec::new();

    for nh in nhs.iter() {
        let cx = nh.center.x as i32;
        let cy = nh.center.y as i32;
        let half = patch_size as i32 / 2;
        let x0 = (cx - half).max(0) as u32;
        let y0 = (cy - half).max(0) as u32;
        if x0 + patch_size > bin.w || y0 + patch_size > bin.h {
            continue;
        }
        let mut img = image::GrayImage::new(patch_size, patch_size);
        for py in 0..patch_size {
            for px in 0..patch_size {
                let v = if bin.get(x0 + px, y0 + py) == 1 { 255 } else { 0 };
                img.put_pixel(px, py, image::Luma([v]));
            }
        }
        let (cls, conf) = classifier.predict(&img);
        *by_class.entry(cls).or_insert(0) += 1;
        let is_reject = matches!(
            cls,
            SymbolClass::Coda
                | SymbolClass::Segno
                | SymbolClass::DynamicPiano
                | SymbolClass::DynamicMezzopiano
                | SymbolClass::DynamicMezzoforte
                | SymbolClass::DynamicForte
        );
        if is_reject && conf > 0.30 {
            interesting.push((nh.center.x, nh.center.y, cls, conf));
        }
    }

    println!("\nClass-Histogramm (alle NHs):");
    let mut entries: Vec<_> = by_class.iter().collect();
    entries.sort_by_key(|(_, c)| std::cmp::Reverse(**c));
    for (cls, cnt) in entries {
        println!("  {:?}: {cnt}", cls);
    }

    println!("\nReject-Kandidaten (Coda/Segno/Dynamic, conf > 0.30):");
    for (x, y, cls, conf) in interesting.iter().take(30) {
        let stage = if *conf > 0.55 { "REJECT" } else { "borderline" };
        println!("  ({x:.0},{y:.0}) → {:?} conf={:.2} {}", cls, conf, stage);
    }
    println!("\nTotal Reject-Kandidaten: {}", interesting.len());
    let active_rejects = interesting.iter().filter(|(_, _, _, c)| *c > 0.55).count();
    println!("Aktive Rejects (conf > 0.55): {}", active_rejects);
}

