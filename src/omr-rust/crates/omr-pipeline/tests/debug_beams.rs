// Debug-Test: Beam-Group-NH-Detection im Detail.
// Schreibt die binarisierten/staff-removed Bilder und tracet jeden
// CC-Schritt damit wir genau sehen warum nur 1/8 NHs erkannt werden.

use omr_pipeline::synthetic::{corpus_eighth_beams, corpus_mixed_durations};

#[test]
fn debug_eighth_beams_cc() {
    let (img, gt) = corpus_eighth_beams();
    let bin = omr_preprocessing::sauvola(&img, 25, 0.34);
    let systems = omr_staff::detect_systems(&bin);
    let removed = omr_staff::remove_staff(&bin, &systems);

    let dir = std::path::Path::new("../../debug-out");
    let _ = std::fs::create_dir_all(dir);
    let _ = bin.to_gray().save(dir.join("eighth_beams_bin.png"));
    let _ = removed.to_gray().save(dir.join("eighth_beams_removed.png"));
    let _ = img.save(dir.join("eighth_beams_orig.png"));

    let nhs = omr_symbols::detect_noteheads(&removed, &systems);
    println!("Eighth Beams: {} NHs, {} GT", nhs.len(), gt.noteheads.len());
}

#[test]
fn debug_mixed_durations() {
    let (img, gt) = corpus_mixed_durations();
    let bin = omr_preprocessing::sauvola(&img, 25, 0.34);
    let systems = omr_staff::detect_systems(&bin);
    let removed = omr_staff::remove_staff(&bin, &systems);

    let dir = std::path::Path::new("../../debug-out");
    let _ = std::fs::create_dir_all(dir);
    let _ = bin.to_gray().save(dir.join("mixed_bin.png"));
    let _ = removed.to_gray().save(dir.join("mixed_removed.png"));
    let _ = img.save(dir.join("mixed_orig.png"));

    println!("=== Mixed Durations ===");
    println!("GT NHs:");
    for (i, nh) in gt.noteheads.iter().enumerate() {
        println!("  GT #{}: ({:.0},{:.0}) kind={:?} {}{}",
            i, nh.center_x, nh.center_y, nh.kind, nh.step, nh.octave);
    }

    let nhs = omr_symbols::detect_noteheads(&removed, &systems);
    println!("Detected NHs:");
    for (i, nh) in nhs.iter().enumerate() {
        let pixel_count: u32 = (nh.bbox.y..nh.bbox.y+nh.bbox.h).map(|y|
            (nh.bbox.x..nh.bbox.x+nh.bbox.w).filter(|&x| removed.get(x, y) == 1).count() as u32
        ).sum();
        let fill = pixel_count as f32 / nh.bbox.area().max(1) as f32;
        println!("  NH #{}: center=({:.1},{:.1}) bbox={}x{} fill={:.2} kind={:?}",
            i, nh.center.x, nh.center.y, nh.bbox.w, nh.bbox.h, fill, nh.kind);
    }
}

