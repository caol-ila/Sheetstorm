// Smoke-Test: lese ein PDF + zeige Detection-Statistik.
//
// Aufruf: cargo run --release -p omr-pipeline --example detect_smoke -- "path/to.pdf"

fn main() {
    let pdf = std::env::args().nth(1).expect("usage: detect_smoke <pdf>");
    let opts = omr_core::PipelineOptions {
        collect_detections: true,
        ..Default::default()
    };
    let r = omr_pipeline::process_pdf(std::path::Path::new(&pdf), &opts).expect("pipeline ok");
    let det = r.detections.expect("detections present");
    println!("schema_version={} pages={}", det.schema_version, det.pages.len());
    for p in &det.pages {
        println!(
            "  page {}: {}x{} spacing={:.1} NHs={} stems={} bars={} measures={}",
            p.page_index,
            p.width,
            p.height,
            p.line_spacing,
            p.noteheads.len(),
            p.stems.len(),
            p.bars.len(),
            p.measures.len()
        );
        let with_pitch = p.noteheads.iter().filter(|n| n.midi.is_some()).count();
        println!("  -> {} of {} NHs have pitch", with_pitch, p.noteheads.len());
        for nh in p.noteheads.iter().take(3) {
            println!(
                "  NH#{}: bbox={:?} kind={} midi={:?} duration={:?} measure={:?}",
                nh.id, nh.bbox, nh.kind, nh.midi, nh.duration, nh.measure_number
            );
        }
    }
    let json = serde_json::to_string_pretty(&det).expect("serialize");
    println!("JSON size: {} bytes", json.len());
}
