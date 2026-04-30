// Debug: Listet broken/repaired Measures eines realen PDFs auf und gibt
// Histogramme aus welche Σ-Durations die Pipeline produziert. Hilfreich zum
// Tuning der Plausibility-Heuristik und Stem/NH/Beam-Detection.

use std::path::PathBuf;

#[test]
#[ignore]
fn diagnose_broken_measures() {
    let pdf_path = std::env::var("OMR_PDF").unwrap_or_else(|_| {
        "C:\\Users\\tmahlberg\\OneDrive\\Noten\\Anja\\Labeled\\BAVARIA.pdf".into()
    });
    let p = PathBuf::from(&pdf_path);
    if !p.exists() {
        println!("PDF not found: {pdf_path}");
        return;
    }

    let dbg_dir = PathBuf::from("../../debug-out/BAVARIA-overlay");
    let _ = std::fs::create_dir_all(&dbg_dir);
    let result = omr_pipeline::process_pdf(&p, &omr_core::PipelineOptions {
        debug_dir: Some(dbg_dir.clone()),
        ..Default::default()
    })
        .expect("pipeline failed");

    println!("=== {} ===", p.file_name().unwrap().to_string_lossy());
    println!("Measures: {} (exact {}, repaired {}, broken {})",
        result.stats.n_measures,
        result.stats.n_measures_exact,
        result.stats.n_measures_repaired,
        result.stats.n_measures_broken);

    let mut diff_hist: std::collections::BTreeMap<i32, u32> = std::collections::BTreeMap::new();
    let mut nh_per_measure: Vec<usize> = Vec::new();
    let mut filled_per_measure: Vec<usize> = Vec::new();

    for part in &result.score.parts {
        for m in &part.measures {
            // Korrekte Formel: divisions=4 → 4 Ticks pro Viertel, 4/4 = 16 Ticks
            let expected: i32 = ((m.divisions as i32) * 4 * 4) / 4;
            // Lead-Σ: ohne Akkord-Member
            let actual: i32 = m.notes.iter().filter(|n| !n.in_chord).map(|n| n.duration as i32).sum();
            let diff = actual - expected;
            *diff_hist.entry(diff).or_insert(0) += 1;
            nh_per_measure.push(m.notes.len());
            filled_per_measure.push(m.notes.iter().filter(|n| n.kind == omr_core::NoteheadKind::Filled).count());
        }
    }

    println!("\nDuration-Diff Histogramm (lead_sum - expected, in divisions):");
    for (diff, cnt) in diff_hist.iter() {
        println!("  {diff:+3}: {cnt}");
    }

    println!("\nNHs per Measure: min={:?} max={:?} median={:?}",
        nh_per_measure.iter().min(),
        nh_per_measure.iter().max(),
        {
            let mut s = nh_per_measure.clone();
            s.sort();
            s.get(s.len()/2).copied()
        });

    // Detail: Measures mit auffällig vielen NHs (potentielle MMR-FPs) oder mit
    // großem Diff. Zeige Position für jeden NH zur visuellen Verifikation.
    let mut shown = 0;
    'outer: for part in &result.score.parts {
        for m in &part.measures {
            let expected: i32 = ((m.divisions as i32) * 4 * 4) / 4;
            let actual: i32 = m.notes.iter().filter(|n| !n.in_chord).map(|n| n.duration as i32).sum();
            let diff = (actual - expected).abs();
            let too_many = m.notes.len() > 5;
            if (diff > expected/2 || too_many) && !m.notes.is_empty() {
                shown += 1;
                println!("\nMeasure {} (sys {:?}): expected={} actual={} ({}NHs, {} chord-members)",
                    m.number, m.system_idx, expected, actual, m.notes.len(),
                    m.notes.iter().filter(|n| n.in_chord).count());
                for (i, n) in m.notes.iter().enumerate().take(15) {
                    let chord = if n.in_chord { " [CHORD]" } else { "" };
                    println!("    note[{}]: kind={:?} dur={} pitch=midi{} x={:.0} y={:.0}{}",
                        i, n.kind, n.duration, n.midi, n.center.x, n.center.y, chord);
                }
                if shown >= 12 { break 'outer; }
            }
        }
    }

    // Dump ALL notes within suspect MMR-bar Y-ranges (for visual debugging).
    // BAVARIA Lines 4-9 have MMR-bars at y in: 700-720, 858-870, 1010-1030, 1310-1320
    println!("\n=== ALL NHs (sorted by y) ===");
    // Trenne echte Notes (is_rest=false) von implicit-whole-rests (is_rest=true).
    let mut all_notes: Vec<(u32, &str, i32, f32, f32, bool)> = Vec::new();
    for part in &result.score.parts {
        for m in &part.measures {
            for n in &m.notes {
                let kind_str = match n.kind {
                    omr_core::NoteheadKind::Filled => "F",
                    omr_core::NoteheadKind::Open => "O",
                    omr_core::NoteheadKind::Whole => "W",
                };
                all_notes.push((m.number, kind_str, n.midi as i32, n.center.x, n.center.y, n.is_rest));
            }
        }
    }
    all_notes.sort_by(|a, b| a.4.partial_cmp(&b.4).unwrap_or(std::cmp::Ordering::Equal));
    let n_rests = all_notes.iter().filter(|n| n.5).count();
    let n_real = all_notes.len() - n_rests;
    let n_filled = all_notes.iter().filter(|n| !n.5 && n.1 == "F").count();
    let n_open = all_notes.iter().filter(|n| !n.5 && n.1 == "O").count();
    let n_whole = all_notes.iter().filter(|n| !n.5 && n.1 == "W").count();
    println!("Total entries: {} (real notes: {}, rests: {})", all_notes.len(), n_real, n_rests);
    println!("Real-NH distribution: F={} O={} W={}", n_filled, n_open, n_whole);
    for (num, k, midi, x, y, is_rest) in &all_notes {
        let tag = if *is_rest { "REST" } else { "NOTE" };
        println!("    M{:02} {} {} midi={} x={:.0} y={:.0}", num, k, tag, midi, x, y);
    }
}
