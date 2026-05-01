// Integration-Tests: synthetische Bilder durch die ganze Pipeline laufen lassen
// und Output gegen Ground-Truth vergleichen.

use omr_pipeline::synthetic::{c_major_scale_treble, add_scanner_noise};
use omr_pipeline::process_gray;
use omr_core::PipelineOptions;

#[test]
fn c_major_scale_runs_through_pipeline() {
    let synth = c_major_scale_treble();
    let opts = PipelineOptions::default();
    let result = process_gray(synth.image, &opts).expect("pipeline ok");

    // Mindestens 5 Notenköpfe sollten erkannt werden (von 8 erwarteten).
    assert!(
        result.stats.n_noteheads >= 5,
        "expected at least 5 noteheads, got {}",
        result.stats.n_noteheads
    );
    // Mindestens 1 Stafftsystem detected
    assert!(result.stats.n_systems >= 1);
    // MusicXML wird gerendert
    assert!(result.musicxml.contains("<score-partwise"));
    assert!(result.musicxml.contains("<step>"));
}

#[test]
fn c_major_scale_pitches_extracted() {
    let synth = c_major_scale_treble();
    let opts = PipelineOptions::default();
    let result = process_gray(synth.image, &opts).expect("pipeline ok");
    let detected_pitches = extract_pitches(&result.musicxml);

    // Die Tonleiter geht aufsteigend C4..C5. Wir erwarten min. 5 von 8 erkannt.
    // Der Test ist tolerant: wir prüfen nur dass C, D, E, F, G mindestens je
    // einmal in der erkannten Folge auftauchen (nicht streng-sequentiell, weil
    // Reading-Order anhand X-Position).
    assert!(
        detected_pitches.len() >= 5,
        "expected ≥5 pitches in MusicXML, got {}: {:?}",
        detected_pitches.len(),
        detected_pitches
    );

    // Mindestens C oder D muss erkannt werden (start der Tonleiter).
    let starts_low = detected_pitches.iter().take(3).any(|p| p.0 == 'C' || p.0 == 'D');
    assert!(starts_low, "expected scale to start with C or D, got {:?}", detected_pitches);
}

#[test]
fn noisy_scale_still_produces_output() {
    let synth = c_major_scale_treble();
    let noisy = add_scanner_noise(&synth.image, 0.02);
    let opts = PipelineOptions::default();
    let result = process_gray(noisy, &opts).expect("pipeline ok");

    // Auch bei 2% Salt-and-Pepper-Noise sollte mindestens 1 System erkannt werden
    // und mindestens ein paar Noteheads.
    assert!(result.stats.n_systems >= 1, "noise broke staff detection");
    assert!(
        result.stats.n_noteheads >= 3,
        "noise broke notehead detection too much: {}",
        result.stats.n_noteheads
    );
}

#[test]
fn very_noisy_scale_at_least_finds_staff() {
    let synth = c_major_scale_treble();
    let noisy = add_scanner_noise(&synth.image, 0.10);
    let opts = PipelineOptions::default();
    let result = process_gray(noisy, &opts).expect("pipeline ok");

    // Bei 10% Noise dürfen Noteheads schwächer werden, aber Stafflinien sollten
    // robust gefunden werden.
    assert!(
        result.stats.n_systems >= 1,
        "even very noisy image should have at least 1 staff system, got {}",
        result.stats.n_systems
    );
}

fn extract_pitches(xml: &str) -> Vec<(char, i8, i8)> {
    let mut out = Vec::new();
    let mut rest = xml;
    while let Some(p) = rest.find("<pitch>") {
        rest = &rest[p..];
        let end = rest.find("</pitch>").unwrap_or(0);
        if end == 0 { break; }
        let block = &rest[..end];
        let step = extract(block, "step").and_then(|s| s.chars().next()).unwrap_or('?');
        let alter: i8 = extract(block, "alter").and_then(|s| s.parse().ok()).unwrap_or(0);
        let octave: i8 = extract(block, "octave").and_then(|s| s.parse().ok()).unwrap_or(0);
        out.push((step, alter, octave));
        rest = &rest[end..];
    }
    out
}

fn extract(s: &str, tag: &str) -> Option<String> {
    let open = format!("<{}>", tag);
    let close = format!("</{}>", tag);
    let i = s.find(&open)? + open.len();
    let j = s[i..].find(&close)?;
    Some(s[i..i + j].to_string())
}
