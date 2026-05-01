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
    assert!(ms < 2500.0, "Pipeline too slow: {:.0}ms", ms);
}

// ============================================================================
// MUSCIMA++ — handschriftliche Notation.
// ============================================================================
//
// Diese Tests laufen gegen das MUSCIMA++-Korpus (CC-BY-NC-SA 4.0,
// nicht im Repo — siehe `tests/fixtures/muscima_plus/README.md`).
// Sie sind alle `#[ignore]`, damit `cargo test --workspace` ohne
// vorhandene Fixtures grün bleibt.
//
// Aktivieren mit:
//   cd src/omr-rust
//   cargo test -p omr-pipeline --test accuracy_bench -- --ignored \
//       --nocapture muscima
//
// Schwellen sind bewusst niedrig (60–80% Recall): handgeschriebene
// Notation ist für eine ML-freie Pipeline hart. Die Tests dienen als
// Regressions-Wächter, nicht als Ziel-SLA.

use omr_pipeline::accuracy::benchmark_pipeline_real;
use omr_pipeline::muscima::load_muscima_xml;
use std::path::PathBuf;

fn fixtures_dir() -> PathBuf {
    // Workspace-Root: src/omr-rust → 2× hoch zu Repo-Root.
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join("..")
        .join("..")
        .join("..")
        .join("tests")
        .join("fixtures")
        .join("muscima_plus")
}

fn run_muscima_case(stem: &str) -> Option<(omr_pipeline::accuracy::StageMetrics, std::time::Duration)>
{
    let xml = fixtures_dir().join(format!("{stem}.xml"));
    let png = fixtures_dir().join(format!("{stem}.png"));
    if !xml.exists() || !png.exists() {
        eprintln!(
            "MUSCIMA fixture fehlt: {} oder {} — siehe tests/fixtures/muscima_plus/README.md",
            xml.display(),
            png.display()
        );
        return None;
    }
    let ann = load_muscima_xml(&xml).expect("MuNG-XML parse failed");
    let img = image::open(&png)
        .expect("PNG laden failed")
        .to_luma8();
    let (m, dur) = benchmark_pipeline_real(&img, &ann);
    print_report(&format!("muscima::{stem}"), &m, dur);
    Some((m, dur))
}

#[test]
#[ignore = "Benötigt MUSCIMA++-Daten in tests/fixtures/muscima_plus/ (CC-BY-NC-SA, nicht im Repo)"]
fn accuracy_muscima_easy_scale() {
    let Some((m, _)) = run_muscima_case("easy_01_scale") else { return };
    assert!(
        m.noteheads.recall() >= 0.6,
        "MUSCIMA easy NH recall {} < 0.6",
        m.noteheads.recall()
    );
}

#[test]
#[ignore = "Benötigt MUSCIMA++-Daten in tests/fixtures/muscima_plus/"]
fn accuracy_muscima_beam_groups() {
    let Some((m, _)) = run_muscima_case("medium_02_beams") else { return };
    assert!(
        m.noteheads.recall() >= 0.55,
        "MUSCIMA beams NH recall {} < 0.55",
        m.noteheads.recall()
    );
    assert!(
        m.beams.recall() >= 0.4,
        "MUSCIMA beams Beam recall {} < 0.4",
        m.beams.recall()
    );
}

#[test]
#[ignore = "Benötigt MUSCIMA++-Daten in tests/fixtures/muscima_plus/"]
fn accuracy_muscima_voltas() {
    let Some((m, _)) = run_muscima_case("medium_03_voltas") else { return };
    assert!(
        m.noteheads.recall() >= 0.55,
        "MUSCIMA voltas NH recall {} < 0.55",
        m.noteheads.recall()
    );
}

#[test]
#[ignore = "Benötigt MUSCIMA++-Daten in tests/fixtures/muscima_plus/"]
fn accuracy_muscima_polyphony() {
    let Some((m, _)) = run_muscima_case("hard_04_polyphony") else { return };
    assert!(
        m.noteheads.recall() >= 0.45,
        "MUSCIMA polyphony NH recall {} < 0.45",
        m.noteheads.recall()
    );
}

#[test]
#[ignore = "Benötigt MUSCIMA++-Daten in tests/fixtures/muscima_plus/"]
fn accuracy_muscima_slurs() {
    let Some((m, _)) = run_muscima_case("medium_05_slurs") else { return };
    assert!(
        m.noteheads.recall() >= 0.55,
        "MUSCIMA slurs NH recall {} < 0.55",
        m.noteheads.recall()
    );
}

#[test]
#[ignore = "Benötigt MUSCIMA++-Daten in tests/fixtures/muscima_plus/"]
fn accuracy_muscima_typical_band_piece() {
    let Some((m, _)) = run_muscima_case("medium_06_band") else { return };
    assert!(
        m.noteheads.recall() >= 0.55,
        "MUSCIMA band NH recall {} < 0.55",
        m.noteheads.recall()
    );
    assert!(
        m.bars.recall() >= 0.4,
        "MUSCIMA band Bars recall {} < 0.4",
        m.bars.recall()
    );
}
