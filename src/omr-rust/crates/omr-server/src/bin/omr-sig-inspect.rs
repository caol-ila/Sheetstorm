// omr-sig-inspect — CLI zum Inspizieren von DetectionsResult-JSON-Dateien.
//
// Liest eine vom `/detections`-Endpoint erzeugte JSON-Datei und gibt eine
// formatierte SIG-Zusammenfassung pro Seite im Terminal aus.
//
// Aufruf:
//   cargo run --bin omr-sig-inspect -- detections.json
//   cargo run --bin omr-sig-inspect -- detections.json --verbose

use clap::Parser;
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(
    name = "omr-sig-inspect",
    about = "Sheetstorm SIG Inspector — zeigt SIG-Statistiken aus einer DetectionsResult-JSON-Datei"
)]
struct Args {
    /// Pfad zur DetectionsResult-JSON-Datei.
    file: PathBuf,

    /// Zeigt auch Noteheads ohne Pitch und weitere Detail-Informationen.
    #[arg(short, long)]
    verbose: bool,
}

fn main() {
    let args = Args::parse();

    let content = match std::fs::read_to_string(&args.file) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Fehler beim Lesen von {}: {}", args.file.display(), e);
            std::process::exit(1);
        }
    };

    let data: serde_json::Value = match serde_json::from_str(&content) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Ungültiges JSON: {}", e);
            std::process::exit(1);
        }
    };

    let pages = match data["pages"].as_array() {
        Some(p) => p,
        None => {
            eprintln!("JSON enthält kein 'pages'-Array — ist das eine gültige DetectionsResult-Datei?");
            std::process::exit(1);
        }
    };

    println!("=== Sheetstorm SIG Inspector ===");
    println!("File: {}", args.file.display());
    println!("Pages: {}\n", pages.len());

    for (page_idx, page) in pages.iter().enumerate() {
        print_page(page_idx, page, args.verbose);
    }
}

fn print_page(page_idx: usize, page: &serde_json::Value, verbose: bool) {
    let n_systems = page["staff_systems"].as_array().map(|a| a.len()).unwrap_or(0);
    let noteheads = page["noteheads"].as_array();
    let n_heads = noteheads.map(|a| a.len()).unwrap_or(0);
    let n_stems = page["stems"].as_array().map(|a| a.len()).unwrap_or(0);
    let n_beams = page["beams"].as_array().map(|a| a.len()).unwrap_or(0);
    let n_bars = page["bars"].as_array().map(|a| a.len()).unwrap_or(0);

    println!("Page {}:", page_idx + 1);
    println!(
        "  {} Systems, {} Noteheads, {} Stems, {} Beams, {} Bars",
        n_systems, n_heads, n_stems, n_beams, n_bars
    );

    // Durchschnitts-Konfidenz der Noteheads berechnen.
    let avg_conf_heads = noteheads
        .map(|nhs| {
            let sum: f64 = nhs.iter().filter_map(|n| n["confidence"].as_f64()).sum();
            let count = nhs.len();
            if count > 0 { sum / count as f64 } else { 0.0 }
        })
        .unwrap_or(0.0);
    let avg_conf_stems = page["stems"]
        .as_array()
        .map(|stems| {
            let sum: f64 = stems.iter().filter_map(|s| s["confidence"].as_f64()).sum();
            let count = stems.len();
            if count > 0 { sum / count as f64 } else { 0.0 }
        })
        .unwrap_or(0.0);

    println!("  ┌─ SIG ─────────────────────────────");

    // SIG-Summary aus dem JSON lesen (wenn vorhanden).
    if let Some(sig) = page["sig"].as_object() {
        let n_inters = sig.get("n_inters").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_sig_heads = sig.get("n_heads").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_sig_stems = sig.get("n_stems").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_sig_beams = sig.get("n_beams").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_sig_bars = sig.get("n_bars").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_keysigs = sig.get("n_keysigs").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_timesigs = sig.get("n_timesigs").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_relations = sig.get("n_relations").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_kc_supports = sig.get("n_keyconsistency_supports").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_kc_conflicts = sig.get("n_keyconsistency_conflicts").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_headstem = sig.get("n_headstem_links").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_beamstem = sig.get("n_beamstem_links").and_then(|v| v.as_u64()).unwrap_or(0);
        let n_budget = sig.get("n_measurebudget_edges").and_then(|v| v.as_u64()).unwrap_or(0);

        println!("  │ {} Inters total", n_inters);
        println!("  │   Heads:     {:>5}  (avg conf {:.2})", n_sig_heads, avg_conf_heads);
        println!("  │   Stems:     {:>5}  (avg conf {:.2})", n_sig_stems, avg_conf_stems);
        println!("  │   Beams:     {:>5}", n_sig_beams);
        println!("  │   Bars:      {:>5}", n_sig_bars);

        // KeySig-Details aus den raw key_signatures
        if let Some(keys) = page["key_signatures"].as_array() {
            for k in keys {
                let fifths = k["fifths"].as_i64().unwrap_or(0);
                let key_name = key_name(fifths as i8);
                println!("  │   KeySigs:  {:>5}  fifths={} ({})", n_keysigs, fifths, key_name);
            }
            if keys.is_empty() {
                println!("  │   KeySigs:  {:>5}", n_keysigs);
            }
        }

        // TimeSig-Details aus den raw time_signatures
        if let Some(times) = page["time_signatures"].as_array() {
            for t in times {
                let beats = t["beats"].as_u64().unwrap_or(0);
                let beat_type = t["beat_type"].as_u64().unwrap_or(4);
                println!("  │   TimeSigs: {:>5}  {}/{}", n_timesigs, beats, beat_type);
            }
            if times.is_empty() {
                println!("  │   TimeSigs: {:>5}", n_timesigs);
            }
        }

        println!("  │ {} Relations total", n_relations);
        println!("  │   HeadStem:        {} (Support)", n_headstem);
        println!("  │   BeamStem:        {} (Support)", n_beamstem);
        println!(
            "  │   KeyConsistency: {} Support / {} Exclusion",
            n_kc_supports, n_kc_conflicts
        );
        println!("  │   MeasureBudget:  {}", n_budget);

        // Konflikte anzeigen
        if n_kc_conflicts > 0 {
            println!("  │");
            println!("  │ ⚠ Conflicts: {} nicht-diatonische Pitches", n_kc_conflicts);
            print_conflict_details(page, verbose);
        }
    } else {
        // Kein vorberechnetes SIG — Basis-Info aus JSON
        println!("  │ [kein SIG-Summary im JSON — erstelle mit aktuellem /detections-Endpoint]");
        println!("  │ {} Noteheads  (avg conf {:.2})", n_heads, avg_conf_heads);
        println!("  │ {} Stems", n_stems);
        println!("  │ {} Beams", n_beams);
        println!("  │ {} Bars", n_bars);

        // Trotzdem Konflikte erkennen wenn KeySig und Noteheads vorhanden
        let conflicts = find_conflicts_from_json(page);
        if !conflicts.is_empty() {
            println!("  │");
            println!("  │ ⚠ Konflikte (geschätzt): {} nicht-diatonische Pitches", conflicts.len());
            for c in conflicts.iter().take(5) {
                println!("  │   - {}", c);
            }
            if conflicts.len() > 5 {
                println!("  │   ... und {} weitere", conflicts.len() - 5);
            }
        }
    }

    println!("  └─────────────────────────────────────");
    println!();
}

/// Gibt Konflikt-Details aus den Noteheads des JSON aus.
fn print_conflict_details(page: &serde_json::Value, verbose: bool) {
    let conflicts = find_conflicts_from_json(page);
    let limit = if verbose { conflicts.len() } else { 5 };
    for c in conflicts.iter().take(limit) {
        println!("  │   - {}", c);
    }
    if !verbose && conflicts.len() > 5 {
        println!("  │   ... und {} weitere (--verbose für alle)", conflicts.len() - 5);
    }
}

/// Findet nicht-diatonische Noteheads durch Vergleich mit der Tonart.
fn find_conflicts_from_json(page: &serde_json::Value) -> Vec<String> {
    let mut conflicts = Vec::new();

    let Some(noteheads) = page["noteheads"].as_array() else {
        return conflicts;
    };
    let Some(key_sigs) = page["key_signatures"].as_array() else {
        return conflicts;
    };
    if key_sigs.is_empty() {
        return conflicts;
    }

    // Baue Map: system_idx → fifths
    let mut sys_to_fifths: std::collections::HashMap<u32, i8> = std::collections::HashMap::new();
    for k in key_sigs {
        let sys = k["system_idx"].as_u64().unwrap_or(0) as u32;
        let fifths = k["fifths"].as_i64().unwrap_or(0) as i8;
        sys_to_fifths.insert(sys, fifths);
    }

    for (i, nh) in noteheads.iter().enumerate() {
        let Some(midi) = nh["midi"].as_u64() else { continue };
        let sys = nh["system_idx"].as_u64().unwrap_or(0) as u32;
        let Some(&fifths) = sys_to_fifths.get(&sys) else { continue };

        if !omr_sig::is_diatonic(midi as u8, fifths) {
            let step = nh["step"].as_str().unwrap_or("?");
            let alter = nh["alter"].as_i64().unwrap_or(0);
            let octave = nh["octave"].as_i64().unwrap_or(4);
            let cx = nh["center"][0].as_f64().unwrap_or(0.0) as u32;
            let cy = nh["center"][1].as_f64().unwrap_or(0.0) as u32;
            let alter_str = match alter {
                1 => "#",
                -1 => "b",
                2 => "##",
                -2 => "bb",
                _ => "♮",
            };
            let expected = expected_alter_in_key(step, fifths);
            conflicts.push(format!(
                "Head#{} {}{}{} at ({}, {}) — erwartet {} in {}",
                i,
                step,
                alter_str,
                octave,
                cx,
                cy,
                expected,
                key_name(fifths),
            ));
        }
    }
    conflicts
}

/// Gibt den erwarteten Alterations-String für einen Schritt in einer Tonart zurück.
fn expected_alter_in_key(step: &str, fifths: i8) -> String {
    // Circle of fifths: Sharps sind F,C,G,D,A,E,B; Flats sind B,E,A,D,G,C,F
    let sharp_order = ["F", "C", "G", "D", "A", "E", "B"];
    let flat_order = ["B", "E", "A", "D", "G", "C", "F"];

    if fifths > 0 {
        let n = fifths as usize;
        if sharp_order[..n.min(7)].contains(&step) {
            return format!("{}#", step);
        }
    } else if fifths < 0 {
        let n = (-fifths) as usize;
        if flat_order[..n.min(7)].contains(&step) {
            return format!("{}b", step);
        }
    }
    step.to_string()
}

/// Gibt den Tonart-Namen für `fifths` zurück (z.B. 1 → "G major").
fn key_name(fifths: i8) -> &'static str {
    match fifths {
        0 => "C major",
        1 => "G major",
        2 => "D major",
        3 => "A major",
        4 => "E major",
        5 => "B major",
        6 => "F# major",
        7 => "C# major",
        -1 => "F major",
        -2 => "Bb major",
        -3 => "Eb major",
        -4 => "Ab major",
        -5 => "Db major",
        -6 => "Gb major",
        -7 => "Cb major",
        _ => "unknown",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_detection_json(n_heads: usize, n_stems: usize, fifths: i8, include_sig: bool) -> serde_json::Value {
        let noteheads: Vec<serde_json::Value> = (0..n_heads)
            .map(|i| {
                serde_json::json!({
                    "id": i,
                    "bbox": [100, 200, 8, 6],
                    "center": [104.0, 203.0],
                    "kind": "Filled",
                    "system_idx": 0,
                    "confidence": 0.85,
                    "midi": if i % 2 == 0 { 66 } else { 65 },  // F# (diatonic) / F natural (conflict)
                    "step": "F",
                    "alter": if i % 2 == 0 { 1 } else { 0 },
                    "octave": 4
                })
            })
            .collect();

        let stems: Vec<serde_json::Value> = (0..n_stems)
            .map(|i| serde_json::json!({"id": i, "x": 104, "y_top": 180, "y_bot": 230}))
            .collect();

        let key_sigs = vec![serde_json::json!({"system_idx": 0, "fifths": fifths, "bbox": [50, 100, 30, 40]})];
        let time_sigs = vec![serde_json::json!({"system_idx": 0, "beats": 4, "beat_type": 4, "bbox": [80, 100, 20, 40]})];

        let mut page = serde_json::json!({
            "page_index": 0,
            "width": 1000,
            "height": 1000,
            "staff_systems": [{"system_idx": 0, "top_y": 100.0, "bot_y": 140.0, "line_spacing": 10.0}],
            "noteheads": noteheads,
            "stems": stems,
            "beams": [],
            "bars": [],
            "key_signatures": key_sigs,
            "time_signatures": time_sigs,
        });

        if include_sig {
            page["sig"] = serde_json::json!({
                "n_inters": n_heads + n_stems + 1,
                "n_heads": n_heads,
                "n_stems": n_stems,
                "n_beams": 0,
                "n_bars": 0,
                "n_keysigs": 1,
                "n_timesigs": 1,
                "n_relations": n_heads,
                "n_keyconsistency_supports": n_heads / 2,
                "n_keyconsistency_conflicts": (n_heads + 1) / 2,
                "n_headstem_links": n_stems,
                "n_beamstem_links": 0,
                "n_measurebudget_edges": n_heads
            });
        }

        serde_json::json!({"schema_version": 1, "pages": [page]})
    }

    #[test]
    fn smoke_inspect_with_sig() {
        let json = make_detection_json(4, 2, 1, true);
        let pages = json["pages"].as_array().unwrap();
        assert_eq!(pages.len(), 1);
        let page = &pages[0];
        assert!(page["sig"].is_object(), "sig field present");
        assert_eq!(page["sig"]["n_heads"].as_u64().unwrap(), 4);
        assert_eq!(page["sig"]["n_keyconsistency_conflicts"].as_u64().unwrap(), 2);
    }

    #[test]
    fn smoke_inspect_without_sig() {
        let json = make_detection_json(4, 2, 1, false);
        let pages = json["pages"].as_array().unwrap();
        let page = &pages[0];
        assert!(page["sig"].is_null(), "no sig field when not included");
    }

    #[test]
    fn find_conflicts_detects_non_diatonic() {
        let json = make_detection_json(2, 0, 1, false);
        let pages = json["pages"].as_array().unwrap();
        let conflicts = find_conflicts_from_json(&pages[0]);
        // Head#0: F#4 MIDI 66 → diatonic in G (fifths=1)
        // Head#1: F♮4 MIDI 65 → NOT diatonic in G (fifths=1)
        assert_eq!(conflicts.len(), 1, "exactly 1 non-diatonic head");
        assert!(conflicts[0].contains("Head#1"), "conflict is Head#1");
    }

    #[test]
    fn key_name_roundtrip() {
        assert_eq!(key_name(0), "C major");
        assert_eq!(key_name(1), "G major");
        assert_eq!(key_name(-1), "F major");
        assert_eq!(key_name(2), "D major");
    }
}
