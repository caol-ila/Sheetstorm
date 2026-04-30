// Quick debug: rendert die zwei Hälften eines doppelseitigen Scans und
// speichert sie als PNG. Hilft beim Tuning der Split-Logik.

#[test]
#[ignore]
fn dump_doublespread_halves() {
    let pdf_path = std::env::var("OMR_PDF").unwrap_or_else(|_| {
        "C:\\Users\\tmahlberg\\OneDrive\\Noten\\Anja\\Labeled\\Mack The Knife.pdf".into()
    });
    let p = std::path::PathBuf::from(&pdf_path);
    if !p.exists() {
        println!("PDF not found: {pdf_path}");
        return;
    }

    let images = omr_pipeline::pdf_render::render_pages(&p, 200).expect("pdf render");
    let img = images.into_iter().next().expect("no pages");
    let (w, h) = (img.width(), img.height());
    println!("Image: {w}x{h} aspect={:.2}", w as f32 / h as f32);

    // Suche split_x via density
    let search_x_start = (w as f32 * 0.35) as u32;
    let search_x_end = (w as f32 * 0.65) as u32;
    let mut col_density = vec![0u32; w as usize];
    for y in 0..h {
        for x in search_x_start..search_x_end {
            if img.get_pixel(x, y)[0] < 128 {
                col_density[x as usize] += 1;
            }
        }
    }
    let mut min_x = search_x_start;
    let mut min_v = u32::MAX;
    for x in search_x_start..search_x_end {
        let v = col_density[x as usize];
        if v < min_v {
            min_v = v;
            min_x = x;
        }
    }
    println!("Split candidate: x={min_x}, density={min_v} (threshold={})", h / 100);

    // Verschiedene split-Punkte testen
    for &split in &[(w / 2), min_x, min_x + 50, min_x.saturating_sub(50)] {
        let left = image::imageops::crop_imm(&img, 0, 0, split, h).to_image();
        let right = image::imageops::crop_imm(&img, split, 0, w - split, h).to_image();
        let opts = omr_core::PipelineOptions::default();
        let l = omr_pipeline::process_gray(left.clone(), &opts).expect("L");
        let r = omr_pipeline::process_gray(right.clone(), &opts).expect("R");
        println!("split={split:5} → L: n_systems={} n_measures={} | R: n_systems={} n_measures={}",
            l.stats.n_systems, l.stats.n_measures,
            r.stats.n_systems, r.stats.n_measures);

        // Save halves at the original min_x split
        if split == min_x {
            let _ = left.save("debug-out\\Mack-Right\\half_L.png");
            let _ = right.save("debug-out\\Mack-Right\\half_R.png");
        }
    }
}
