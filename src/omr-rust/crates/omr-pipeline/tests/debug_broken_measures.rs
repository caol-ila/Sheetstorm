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

    let result = omr_pipeline::process_pdf(&p, &omr_core::PipelineOptions::default())
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
            let expected: i32 = ((m.divisions as i32 * 4) / 4).max(1);
            let actual: i32 = m.notes.iter().map(|n| n.duration as i32).sum();
            let diff = actual - expected;
            *diff_hist.entry(diff).or_insert(0) += 1;
            nh_per_measure.push(m.notes.len());
            filled_per_measure.push(m.notes.iter().filter(|n| n.kind == omr_core::NoteheadKind::Filled).count());
        }
    }

    println!("\nDuration-Diff Histogramm (actual - expected, in divisions):");
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

    // Detail: erste 10 broken Measures mit Sample-Notes
    let mut shown = 0;
    'outer: for part in &result.score.parts {
        for m in &part.measures {
            let expected: i32 = ((m.divisions as i32 * 4) / 4).max(1);
            let actual: i32 = m.notes.iter().map(|n| n.duration as i32).sum();
            let diff = (actual - expected).abs();
            if diff > expected/2 {
                shown += 1;
                println!("\nMeasure {} (sys {:?}): expected={} actual={} ({}NHs)",
                    m.number, m.system_idx, expected, actual, m.notes.len());
                for (i, n) in m.notes.iter().enumerate().take(8) {
                    println!("    note[{}]: kind={:?} dur={} pitch=midi{} dot={}",
                        i, n.kind, n.duration, n.midi, n.augmentation_dots);
                }
                if shown >= 8 { break 'outer; }
            }
        }
    }
}
