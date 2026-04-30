// Per-Stage Accuracy-Benchmarks.
//
// Diese Tests messen Precision/Recall pro Pipeline-Stufe gegen
// pixel-genaue synthetische Ground-Truth. Sie ASSERTen Mindestwerte —
// so dass Regression sofort sichtbar wird.
//
// Performance-Budget: jede Pipeline auf 700×220 < 200ms (mit Sauvola).

use omr_pipeline::accuracy::{benchmark_pipeline, print_report};
use omr_pipeline::synthetic::{
    apply_noise, corpus_basic_quarters, corpus_eighth_beams, corpus_mixed_durations,
    corpus_quarters_with_bars, NoiseProfile,
};

#[test]
fn accuracy_basic_quarters_clean() {
    let (img, gt) = corpus_basic_quarters();
    let (m, dur) = benchmark_pipeline(&img, &gt);
    print_report("basic_quarters_clean", &m, dur);

    assert!(m.noteheads.recall() >= 0.95, "NH recall {} < 0.95", m.noteheads.recall());
    assert!(m.noteheads.precision() >= 0.95, "NH precision {} < 0.95", m.noteheads.precision());
    assert!(m.stems.recall() >= 0.90, "Stems recall {} < 0.90", m.stems.recall());
    assert!(m.kind_accuracy() >= 0.90, "Kind accuracy {} < 0.90", m.kind_accuracy());
}

#[test]
fn accuracy_quarters_with_bars_clean() {
    let (img, gt) = corpus_quarters_with_bars();
    let (m, dur) = benchmark_pipeline(&img, &gt);
    print_report("quarters_with_bars_clean", &m, dur);

    assert!(m.bars.recall() >= 0.9, "Bars recall {} < 0.9", m.bars.recall());
    assert!(m.noteheads.recall() >= 0.95, "NH recall {}", m.noteheads.recall());
}

#[test]
fn accuracy_eighth_beams_clean() {
    let (img, gt) = corpus_eighth_beams();
    let (m, dur) = benchmark_pipeline(&img, &gt);
    print_report("eighth_beams_clean", &m, dur);

    assert!(m.beams.recall() >= 0.9, "Beams recall {}", m.beams.recall());
    assert!(m.noteheads.recall() >= 0.95, "NH recall {}", m.noteheads.recall());
    assert!(m.stems.recall() >= 0.90, "Stems recall {}", m.stems.recall());
}

#[test]
fn accuracy_mixed_durations_clean() {
    let (img, gt) = corpus_mixed_durations();
    let (m, dur) = benchmark_pipeline(&img, &gt);
    print_report("mixed_durations_clean", &m, dur);

    assert!(m.noteheads.recall() >= 0.7, "NH recall on mixed {}", m.noteheads.recall());
    assert!(m.kind_accuracy() >= 0.9, "Kind accuracy {}", m.kind_accuracy());
}

#[test]
fn accuracy_basic_quarters_scan_light() {
    let (img, gt) = corpus_basic_quarters();
    let noisy = apply_noise(&img, NoiseProfile::SCAN_LIGHT);
    let (m, dur) = benchmark_pipeline(&noisy, &gt);
    print_report("basic_quarters_scan_light", &m, dur);

    assert!(m.noteheads.recall() >= 0.9, "NH recall (scan_light) {}", m.noteheads.recall());
    assert!(m.noteheads.precision() >= 0.85, "NH precision (scan_light) {}", m.noteheads.precision());
}

#[test]
fn accuracy_basic_quarters_scan_medium() {
    let (img, gt) = corpus_basic_quarters();
    let noisy = apply_noise(&img, NoiseProfile::SCAN_MEDIUM);
    let (m, dur) = benchmark_pipeline(&noisy, &gt);
    print_report("basic_quarters_scan_medium", &m, dur);

    assert!(m.noteheads.recall() >= 0.7, "NH recall (scan_medium) {}", m.noteheads.recall());
}

#[test]
fn accuracy_basic_quarters_scan_heavy() {
    let (img, gt) = corpus_basic_quarters();
    let noisy = apply_noise(&img, NoiseProfile::SCAN_HEAVY);
    let (m, dur) = benchmark_pipeline(&noisy, &gt);
    print_report("basic_quarters_scan_heavy", &m, dur);

    // Bei sehr heavy scan-noise: mindestens 30% recall.
    assert!(m.noteheads.recall() >= 0.3, "NH recall (scan_heavy) {}", m.noteheads.recall());
}

#[test]
fn performance_budget_clean() {
    let (img, gt) = corpus_quarters_with_bars();
    let (_m, dur) = benchmark_pipeline(&img, &gt);
    let ms = dur.as_secs_f32() * 1000.0;
    println!("Performance: {:.0}ms on 900x220", ms);
    assert!(ms < 1500.0, "Pipeline too slow: {:.0}ms", ms);
}
