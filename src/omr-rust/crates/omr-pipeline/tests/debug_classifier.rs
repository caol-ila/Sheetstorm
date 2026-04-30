// Debug: prüfe was der HoG+SVM-Klassifikator pro NH sagt.

use omr_pipeline::synthetic::corpus_eighth_beams;
use omr_symbols::svm_model::HogSvmClassifier;
use omr_symbols::templates::SymbolClass;

#[test]
fn debug_classifier_predictions_on_synthetic() {
    // Modell laden
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

    let (img, _gt) = corpus_eighth_beams();
    let bin = omr_preprocessing::sauvola(&img, 25, 0.34);
    let systems = omr_staff::detect_systems(&bin);
    let removed = omr_staff::remove_staff(&bin, &systems);
    let nhs = omr_symbols::detect_noteheads(&removed, &systems);
    let spacing = systems[0].line_spacing;
    let patch_size = ((spacing * 1.6).round() as u32).clamp(16, 64);

    println!("Spacing={spacing}, patch_size={patch_size}, NHs={}", nhs.len());

    let mut by_class: std::collections::HashMap<SymbolClass, (u32, f32)> = std::collections::HashMap::new();
    for (i, nh) in nhs.iter().enumerate() {
        let cx = nh.center.x as i32;
        let cy = nh.center.y as i32;
        let half = patch_size as i32 / 2;
        let x0 = (cx - half).max(0) as u32;
        let y0 = (cy - half).max(0) as u32;
        if x0 + patch_size > removed.w || y0 + patch_size > removed.h { continue; }
        let mut img = image::GrayImage::new(patch_size, patch_size);
        for py in 0..patch_size {
            for px in 0..patch_size {
                let v = if removed.get(x0 + px, y0 + py) == 1 { 255 } else { 0 };
                img.put_pixel(px, py, image::Luma([v]));
            }
        }
        let (cls, conf) = classifier.predict(&img);
        if i < 8 {
            println!("NH#{i} center=({:.0},{:.0}) → {:?} conf={:.2}",
                nh.center.x, nh.center.y, cls, conf);
        }
        let entry = by_class.entry(cls).or_insert((0, 0.0));
        entry.0 += 1;
        entry.1 += conf;
    }
    println!("\nClass-Histogramm:");
    for (cls, (cnt, sum_conf)) in &by_class {
        println!("  {:?}: {cnt}× (avg conf {:.2})", cls, sum_conf / *cnt as f32);
    }
}
