// Multi-PDF Plausibility-Verifikation: läuft die Pipeline gegen eine konfigurierbare
// Liste echter PDFs und gibt die Plausibility-Statistik je PDF in einer Tabelle aus.
//
// Aufruf:
//   $env:OMR_PDF_DIR='C:\Users\tmahlberg\OneDrive\Noten\Anja\Labeled'; `
//   $env:OMR_PDF_LIST='BAVARIA.pdf,ANGELS.pdf,Anita.pdf,Mendocino.pdf'; `
//   cargo test -p omr-pipeline --test multi_pdf_verify -- --ignored --nocapture
//
// Ohne env-Vars wird BAVARIA.pdf aus dem Default-Pfad benutzt.

use std::path::PathBuf;

#[test]
#[ignore]
fn multi_pdf_plausibility() {
    let dir = std::env::var("OMR_PDF_DIR")
        .unwrap_or_else(|_| "C:\\Users\\tmahlberg\\OneDrive\\Noten\\Anja\\Labeled".into());
    let list = std::env::var("OMR_PDF_LIST")
        .unwrap_or_else(|_| "BAVARIA.pdf,ANGELS.pdf,Anita.pdf,Auf der Vogelwiese.pdf,Mendocino.pdf,Ein Prost.pdf,Zum Geburtstag.pdf".into());

    let dir = PathBuf::from(&dir);
    if !dir.exists() {
        println!("PDF dir not found: {}", dir.display());
        return;
    }

    println!("\n{:<35} {:>5} {:>6} {:>9} {:>7} {:>7}", "PDF", "Meas", "Exact", "Repaired", "Broken", "Plaus%");
    println!("{}", "-".repeat(80));

    let mut total_meas = 0usize;
    let mut total_exact = 0usize;
    let mut total_repaired = 0usize;
    let mut total_broken = 0usize;

    for name in list.split(',').map(|s| s.trim()).filter(|s| !s.is_empty()) {
        let path = dir.join(name);
        if !path.exists() {
            println!("{:<35} MISSING", name);
            continue;
        }
        let result = match omr_pipeline::process_pdf(&path, &omr_core::PipelineOptions::default()) {
            Ok(r) => r,
            Err(e) => {
                println!("{:<35} ERROR: {e}", name);
                continue;
            }
        };
        let stats = &result.stats;
        let plaus = if stats.n_measures > 0 {
            100.0 * (stats.n_measures_exact + stats.n_measures_repaired) as f32 / stats.n_measures as f32
        } else { 0.0 };
        let display_name = if name.len() > 33 { &name[..33] } else { name };
        println!("{:<35} {:>5} {:>6} {:>9} {:>7} {:>6.1}%",
            display_name, stats.n_measures, stats.n_measures_exact,
            stats.n_measures_repaired, stats.n_measures_broken, plaus);
        total_meas += stats.n_measures;
        total_exact += stats.n_measures_exact;
        total_repaired += stats.n_measures_repaired;
        total_broken += stats.n_measures_broken;
    }

    let total_plaus = if total_meas > 0 {
        100.0 * (total_exact + total_repaired) as f32 / total_meas as f32
    } else { 0.0 };
    println!("{}", "-".repeat(80));
    println!("{:<35} {:>5} {:>6} {:>9} {:>7} {:>6.1}%",
        "TOTAL", total_meas, total_exact, total_repaired, total_broken, total_plaus);
}
