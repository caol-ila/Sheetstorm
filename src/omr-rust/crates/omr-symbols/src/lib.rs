// Symbol-Detection-Pipeline:
//   1. Connected Components → SymbolCandidate
//   2. Aspect-/Größen-Filter: Standard-Noteheads (rundlich) + Notehead+Stem-Kombinationen
//      (tall-narrow CCs, häufig nach Staff-Removal).
//   3. Bei tall-narrow-CCs: finde die "klobige" Y-Region innerhalb des CC
//      über horizontale Pixel-Density → das ist der eigentliche Notehead.
//   4. Notehead-Klassifikation: Filled vs. Open vs. Whole anhand
//      Fläche/Aspect-Ratio + Innen-Pixel-Verhältnis.

use omr_core::{Binary, Notehead, NoteheadKind, Point, Rect, ScoreNote, StaffSystem, Stem};
use tracing::debug;

pub mod accidentals;
pub mod bars;
pub mod beam_pitch_validation;
pub mod beams;
pub mod cc;
#[cfg(feature = "cnn")]
pub mod cnn_classifier;
pub mod flags;
pub mod ledger_lines;
pub mod meta;
pub mod pitch;
pub mod plausibility;
pub mod reader;
pub mod rests;
pub mod slurs;
pub mod stem_validation;
pub mod stems;
pub mod template;
pub mod templates;
pub mod classifier;
pub mod hog;
pub mod jump_marks;
pub mod svm_model;
pub use accidentals::detect_local_accidentals;
pub use bars::{detect_measure_bars, MeasureBar};
pub use beams::{detect_beams, beams_per_stem, filter_noteheads_on_beams, Beam};
pub use cc::{connected_components, ConnectedComponent};
pub use flags::detect_flags;
pub use meta::{detect_clef, detect_key_signature};
pub use plausibility::{check_measure, repair_measure, validate_and_repair_part, MeasureCheck, MeasurePlausibility};
pub use reader::{read_page_sequentially, read_system_sequentially, PageReadingStream, ReadingAnomaly, ReadingEvent, SystemReadingStream};
pub use rests::{detect_rests, Rest, RestKind};
pub use slurs::{detect_slurs, Slur};
pub use template::{detect_noteheads_template_v2, detect_wholes_template, rerank_with_template};
pub mod logical_groups;
pub use logical_groups::{detect_logical_groups, class_id_for_group, LogicalGroup, LogicalGroupKind};

/// Hauptfunktion: detektiere Noteheads in einem staff-line-removed Binary.
/// `bin_original` wird genutzt um den Schlüssel/Vorzeichen-Bereich zu finden,
/// in dem keine Noteheads zugelassen werden.
pub fn detect_noteheads(staff_removed: &Binary, systems: &[StaffSystem]) -> Vec<Notehead> {
    detect_noteheads_with_skip(staff_removed, systems, &[])
}

/// Filtert Duplicate-Noteheads, die zu nah aneinander liegen (CC-Splits über Beam-Gruppen,
/// doppelte Detection durch CC-Merge + extract_complex). Behält den NH mit der größeren
/// Bbox (= mehr Pixel = wahrscheinlich vollständigerer Detection).
///
/// Drei-Schwellen-Heuristik:
///   - VERY-SAME-Y (dy < max(3px, 0.15*spacing)) UND dx < max(16px, 1.0*spacing) → DUPLICATE
///   - SAME-Y     (dy < 0.2*spacing)            UND dx < 0.9*spacing            → DUPLICATE
///   - NEAR-Y     (dy < 0.4*spacing)            UND dx < 0.6*spacing            → DUPLICATE
///
/// Akkord-NHs am gleichen Stem haben dy >= 0.5*spacing. Sechzehntel-Sequenz hat
/// dx >= 1.0*spacing (ca. 0.8-1.2*spacing). Bei sehr kleinem spacing (~11px in
/// hoch aufgelösten Scans) decken die absoluten Untergrenzen physikalische
/// Mindest-Pixel-Distanzen ab.
pub fn dedupe_close_noteheads(noteheads: Vec<Notehead>, spacing: f32) -> Vec<Notehead> {
    let very_dx_max = (spacing * 1.0).max(16.0);
    let very_dy_max = (spacing * 0.15).max(3.0);
    let same_dx_max = spacing * 0.9;
    let same_dy_max = spacing * 0.2;
    let near_dx_max = spacing * 0.6;
    let near_dy_max = spacing * 0.4;
    let break_dx = very_dx_max.max(near_dx_max).max(same_dx_max);

    let mut sorted = noteheads;
    sorted.sort_by(|a, b| {
        a.staff_idx
            .cmp(&b.staff_idx)
            .then(a.center.x.partial_cmp(&b.center.x).unwrap_or(std::cmp::Ordering::Equal))
    });
    let mut keep = vec![true; sorted.len()];
    for i in 0..sorted.len() {
        if !keep[i] { continue; }
        for j in (i + 1)..sorted.len() {
            if !keep[j] { continue; }
            if sorted[j].staff_idx != sorted[i].staff_idx { break; }
            let dx = sorted[j].center.x - sorted[i].center.x;
            if dx > break_dx { break; }
            let dy = (sorted[j].center.y - sorted[i].center.y).abs();
            let is_dup = (dy < very_dy_max && dx < very_dx_max)
                || (dy < same_dy_max && dx < same_dx_max)
                || (dy < near_dy_max && dx < near_dx_max);
            if is_dup {
                let area_i = sorted[i].bbox.area();
                let area_j = sorted[j].bbox.area();
                if area_i >= area_j {
                    keep[j] = false;
                } else {
                    keep[i] = false;
                    break;
                }
            }
        }
    }
    sorted
        .into_iter()
        .enumerate()
        .filter_map(|(i, nh)| if keep[i] { Some(nh) } else { None })
        .collect()
}

/// Wie [`detect_noteheads`], aber mit explicit "verbotenen" X-Range pro System
/// (z.B. der Schlüssel/Key/Time-Bereich).
pub fn detect_noteheads_with_skip(
    staff_removed: &Binary,
    systems: &[StaffSystem],
    skip_x_per_system: &[std::ops::Range<u32>],
) -> Vec<Notehead> {
    if systems.is_empty() {
        return vec![];
    }
    let spacing = systems[0].line_spacing;
    if spacing < 4.0 {
        return vec![];
    }

    let expected_w = (spacing * 1.2).round() as u32;
    let expected_h = spacing.round() as u32;
    // Min-w gelockert von 0.4 → 0.35: bei kleinen NHs (z.B. Achtelnoten in dichten
    // Beam-Gruppen) ist die NH-Breite oft 30-40% kleiner als typisch.
    let min_w = (expected_w as f32 * 0.35).round() as u32;
    // KEIN harter max_w mehr: Beam-Gruppen können beliebig breit sein (5-10x
    // einzelner Notehead). Wir lassen extract_noteheads_from_complex pro X-Spalte
    // entscheiden ob ein NH da ist. Begrenze nur auf "absurd breit" (>20*spacing).
    let max_w_simple = (expected_w as f32 * 2.5).round() as u32;
    let max_w_complex = (spacing * 20.0).round() as u32;
    // Real NHs sind ~0.7-0.9*spacing hoch. Untergrenze 0.45*spacing eliminiert
    // dünne horizontale Bar-Fragmente (MMR-Slices, Beam-Pieces) — vorher 0.55,
    // gelockert um auch kleine NHs in komprimierten Layouts zu fangen.
    let min_h_simple = (expected_h as f32 * 0.45).round() as u32;
    let max_h_simple = (expected_h as f32 * 2.0).round() as u32;
    let max_h_tall = (spacing * 5.0).round() as u32;

    let ccs = connected_components(staff_removed);
    debug!(n = ccs.len(), "connected components");

    // Vorab: kleine CCs zu größeren mergen wenn sie sehr nah beieinander
    // liegen. Häufiger Fall: Open/Whole-Note durch Staff-Removal in 2-4
    // kleine CCs zerschnitten (Top-Bogen, Bottom-Bogen, Innen-Punkte).
    let merged = merge_close_ccs(&ccs, spacing);
    debug!(merged = merged.len(), "after CC-merge");

    let mut noteheads = Vec::new();
    for bb in &merged {
        if bb.w < min_w || bb.w > max_w_complex { continue; }
        if bb.h < min_h_simple || bb.h > max_h_tall { continue; }
        let aspect = bb.aspect();

        // Schmaler einzelner CC (Notehead allein oder NH+kurzer-Stem).
        // Aspect-Filter: 0.85..1.8 (echte NH ist 1.2-1.5*spacing breit, ~0.9*spacing hoch
        // → aspect ~1.3-1.7). Aspect > 1.8 ist meistens Bar-Fragment/Beam-Slice.
        if bb.w <= max_w_simple && bb.h <= max_h_simple && (0.85..=1.8).contains(&aspect) {
            if let Some(nh) = classify_simple_notehead(staff_removed, bb, spacing, systems) {
                if is_in_skip_region(&nh, skip_x_per_system) { continue; }
                noteheads.push(nh);
            }
            continue;
        }

        // Tall/wide CC kann mehrere Noteheads enthalten (Beam-Gruppen!).
        let extracted = extract_noteheads_from_complex(staff_removed, bb, spacing, systems);
        for nh in extracted {
            if is_in_skip_region(&nh, skip_x_per_system) { continue; }
            noteheads.push(nh);
        }
    }

    // Final-Filter: NHs müssen auf einer gültigen Pitch-Position liegen.
    let noteheads: Vec<Notehead> = noteheads
        .into_iter()
        .filter(|nh| is_on_pitch_grid(nh, systems))
        .collect();

    // Final-Filter 2: Text-Cluster filtern.
    // Heuristik: 4+ kleine CCs in horizontaler Reihe mit unterschiedlichen
    // Y-Positionen → wahrscheinlich Text (Tempo-Marken, Liedtext).
    let noteheads = filter_text_clusters(noteheads, spacing);

    // Final-Filter 3: Bow-Marks (▽) und Articulations FAR above/below staff.
    // Bow-mark ▽ ist eine Triangle-Form ÜBER der Staff, oft DIREKT ÜBER einem
    // echten NH (das es akzentuiert). Charakteristik:
    //  - midi-Position deutlich außerhalb der Staff (>= 4 half-steps above top
    //    oder unter bottom)
    //  - kind = Open (Triangle hat ein "Hole" wie Open-NH)
    //  - direkter Nachbar (echter NH) innerhalb ±0.7*spacing in X UND
    //    1.5..3.5*spacing in Y unterhalb
    // Filter ausschließlich Open NHs (Filled = real darkened note, kein Bow-mark).
    let noteheads = filter_bow_marks_and_articulations(staff_removed, noteheads, systems);

    debug!(kept = noteheads.len(), "noteheads after filter");
    noteheads
}

/// Filter bow-marks (▽), staccato dots, and articulation marks that the
/// classifier picked up as Open NHs.
///
/// Diskriminator: STEM-PRESENCE. Echte Noteheads (Filled/Open) haben einen
/// Stem (vertikale Linie). Bow-Marks haben keinen Stem. Daher: für jeden
/// nicht-Filled NH außerhalb des Staff prüfen wir, ob ein Stem in Richtung
/// Staff vorhanden ist. Wenn nicht → reject.
///
/// Ausnahme: Whole-Notes haben keinen Stem, sind aber NUR im Staff oder
/// auf benachbarten Ledger-Lines. Ein Whole außerhalb-Staff (cy weiter
/// als 1.5*spacing entfernt) muss durch Stem-Heuristik geprüft werden,
/// aber ein Whole IM Staff hat keinen Stem-Check nötig.
pub fn filter_bow_marks_and_articulations(
    bin: &Binary,
    noteheads: Vec<Notehead>,
    systems: &[StaffSystem],
) -> Vec<Notehead> {
    if noteheads.len() < 2 {
        return noteheads;
    }
    let mut to_remove = vec![false; noteheads.len()];

    for (i, nh) in noteheads.iter().enumerate() {
        // Open/Whole-NHs: prüfen wenn AUSSERHALB staff (Bow-Marks ▽).
        // Filled-NHs: prüfen wenn WEIT-AUSSERHALB staff (Akzente, Dynamik "f", "p", "Trp").
        let outside_threshold = if nh.kind == NoteheadKind::Filled {
            1.4_f32 // Filled muss WEIT entfernt sein (sonst valide Ledger-Note)
        } else {
            0.5_f32
        };
        let staff = match systems.get(nh.staff_idx) {
            Some(s) => s,
            None => continue,
        };
        let spacing = staff.line_spacing;
        let cx = nh.center.x as usize;
        let top_line = &staff.lines[0];
        let bot_line = &staff.lines[staff.lines.len() - 1];
        let top_y = top_line.y_per_x.get(cx).copied()
            .unwrap_or_else(|| top_line.y_per_x[0]) as f32;
        let bot_y = bot_line.y_per_x.get(cx).copied()
            .unwrap_or_else(|| bot_line.y_per_x[0]) as f32;
        let cy = nh.center.y;

        // Above staff (>= threshold*spacing über Top-Line) ODER below staff
        let is_above_staff = top_y - cy >= spacing * outside_threshold;
        let is_below_staff = cy - bot_y >= spacing * outside_threshold;
        if !is_above_staff && !is_below_staff {
            continue;
        }

        {

            // Sehr-weit-Außerhalb-Filter: Wenn weiter als 5*spacing über/unter Staff,
            // NICHT als Bow-Mark filtern (kann eine valide Ledger-Note sein).
            // Bow-Marks sitzen typisch 1-2*spacing über Top-Line.
            let dist_to_staff = if is_above_staff { top_y - cy } else { cy - bot_y };
            if dist_to_staff > spacing * 5.0 {
                continue;
            }

            // STEM-CHECK: Echte Noteheads haben einen Stem in Richtung Staff.
            // Wir scannen die Spalte links UND rechts der Notehead-Mitte (nicht durch
            // den Notehead selbst, sondern an seinem Rand) und suchen einen
            // vertikalen Pixel-Strang mit Länge ≥ 1.5*spacing.
            //
            // Stem-Position: bei stem-up ~rechts vom NH, bei stem-down ~links.
            // Daher beide Seiten checken.
            let stem_search_dy = (spacing * 3.0) as i32;
            let stem_min_len = (spacing * 1.5).round() as i32;
            let stem_max_break = 2_i32; // erlaubt 2px Lücke
            let stem_x_offsets: [i32; 4] = [
                -(nh.bbox.w as i32 / 2) + 1,        // linker Rand
                -(nh.bbox.w as i32 / 2) + 2,
                (nh.bbox.w as i32 / 2) - 1,         // rechter Rand
                (nh.bbox.w as i32 / 2) - 2,
            ];

            let has_stem_towards_staff = stem_x_offsets.iter().any(|&off| {
                let stem_x = nh.center.x as i32 + off;
                if stem_x < 0 || stem_x >= bin.w as i32 { return false; }

                // Scan-Richtung: bei is_above → DOWN (in Richtung Staff)
                //                bei is_below → UP (in Richtung Staff)
                let (start_dy, dir): (i32, i32) = if is_above_staff {
                    ((nh.bbox.h as i32 / 2) + 1, 1)
                } else {
                    (-(nh.bbox.h as i32 / 2) - 1, -1)
                };

                let mut consecutive: i32 = 0;
                let mut breaks: i32 = 0;
                let mut max_run: i32 = 0;
                for k in 0..stem_search_dy {
                    let y = nh.center.y as i32 + start_dy + dir * k;
                    if y < 0 || y >= bin.h as i32 { break; }
                    if bin.get(stem_x as u32, y as u32) != 0 {
                        consecutive += 1;
                        max_run = max_run.max(consecutive);
                    } else {
                        if consecutive > 0 {
                            breaks += 1;
                            if breaks > stem_max_break { break; }
                        }
                        consecutive = 0;
                    }
                }
                max_run >= stem_min_len
            });

            if has_stem_towards_staff {
                continue; // echter NH mit Stem
            }

            // Filled-NHs ohne Stem WEIT-AUSSERHALB Staff: direkt rejekten
            // (Akzente >, Dynamik f/p, Buchstaben Trp/dolce). Stem-Check ist
            // ausreichend — echte Ledger-Notes haben IMMER einen Stem.
            if nh.kind == NoteheadKind::Filled {
                debug!(x = nh.center.x, y = nh.center.y, "rejected as filled-articulation");
                to_remove[i] = true;
                continue;
            }

            // Whole-Notes haben keinen Stem. Aber sie sitzen auf oder direkt
            // neben einer Staff-Linie (max 0.6*spacing entfernt vom nächsten
            // Staff-Rand auf einer Ledger-Line). Bow-Marks sitzen mind.
            // 1.0*spacing entfernt. Daher: Whole-Pass nur bei sehr geringer
            // Distanz zur Staff.
            if nh.kind == NoteheadKind::Whole && dist_to_staff <= spacing * 0.6 {
                continue; // Whole auf/neben Staff → ok
            }

            // Suche einen ECHTEN NH (Filled or Open) in der Nähe als Anker:
            //  - dx <= 0.5 * spacing (Bow-Mark sitzt fast direkt über/unter der Note)
            //  - dy in [0.8..3.0] * spacing
            //  - der Anker ist im oder nahe am Staff
            let has_anchor = noteheads.iter().enumerate().any(|(j, other)| {
                if i == j || to_remove[j] { return false; }
                if other.staff_idx != nh.staff_idx { return false; }
                let dx = (other.center.x - nh.center.x).abs();
                if dx > spacing * 0.5 { return false; }
                let dy = if is_above_staff {
                    other.center.y - cy
                } else {
                    cy - other.center.y
                };
                if !(dy >= spacing * 0.8 && dy <= spacing * 3.0) {
                    return false;
                }
                // Anker muss im oder nah am Staff sein
                let other_top = top_line.y_per_x.get(other.center.x as usize).copied()
                    .unwrap_or_else(|| top_line.y_per_x[0]) as f32;
                let other_bot = bot_line.y_per_x.get(other.center.x as usize).copied()
                    .unwrap_or_else(|| bot_line.y_per_x[0]) as f32;
                other.center.y >= other_top - spacing * 1.0 && other.center.y <= other_bot + spacing * 1.0
            });

            if has_anchor {
                debug!(x = nh.center.x, y = nh.center.y, kind = ?nh.kind, "rejected as bow-mark/articulation");
                to_remove[i] = true;
            }
        }
    }

    noteheads
        .into_iter()
        .enumerate()
        .filter(|(i, _)| !to_remove[*i])
        .map(|(_, nh)| nh)
        .collect()
}

/// Filtert NH-Cluster die wie Text aussehen.
/// Text-Charakteristika: viele kleine CCs nah beieinander, leicht unterschiedliche Y-Höhen,
/// regelmäßige horizontale Anordnung.
fn filter_text_clusters(noteheads: Vec<Notehead>, spacing: f32) -> Vec<Notehead> {
    if noteheads.len() < 4 {
        return noteheads;
    }

    // Gruppiere NHs nach Y-Band (Stride: 0.7 * spacing) und suche horizontal-Reihen.
    let mut to_remove = vec![false; noteheads.len()];

    for (i, nh) in noteheads.iter().enumerate() {
        if to_remove[i] { continue; }
        // Suche andere NHs INNERHALB ±0.6*spacing in Y und ≤ 1.5*spacing in X-Distanz.
        let mut neighbors: Vec<usize> = Vec::new();
        for (j, other) in noteheads.iter().enumerate() {
            if i == j || other.staff_idx != nh.staff_idx { continue; }
            let dx = (other.center.x - nh.center.x).abs();
            let dy = (other.center.y - nh.center.y).abs();
            if dx < spacing * 1.5 && dy < spacing * 0.6 {
                neighbors.push(j);
            }
        }
        // Wenn 3+ Nachbarn (= 4 zusammen mit self), prüfe ob es wie Text aussieht.
        if neighbors.len() >= 3 {
            // Berechne X-Spread und Y-Variation
            let mut xs: Vec<f32> = vec![nh.center.x];
            let mut ys: Vec<f32> = vec![nh.center.y];
            for &n in &neighbors {
                xs.push(noteheads[n].center.x);
                ys.push(noteheads[n].center.y);
            }
            xs.sort_by(|a, b| a.partial_cmp(b).unwrap());
            let x_span = xs[xs.len() - 1] - xs[0];
            let y_min = ys.iter().cloned().fold(f32::INFINITY, f32::min);
            let y_max = ys.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
            let y_var = y_max - y_min;

            // Text: viele in engem Y-Bereich (0.4*spacing) mit regelmäßigem X-Abstand.
            // Bbox-Sizes der Cluster-NHs sind alle deutlich kleiner als typisches NH (kleine Buchstaben).
            let avg_w = (nh.bbox.w as f32 + neighbors.iter().map(|&j| noteheads[j].bbox.w as f32).sum::<f32>())
                / (neighbors.len() as f32 + 1.0);
            let is_small = avg_w < spacing * 0.7;

            // Wenn Y-Variation klein UND alle Cluster-NHs klein UND mehr als 4 nahe → Text
            if y_var < spacing * 0.5 && is_small && neighbors.len() >= 4 && x_span > spacing * 2.0 {
                to_remove[i] = true;
                for &n in &neighbors {
                    to_remove[n] = true;
                }
            }
        }
    }

    noteheads
        .into_iter()
        .enumerate()
        .filter(|(i, _)| !to_remove[*i])
        .map(|(_, nh)| nh)
        .collect()
}

/// Prüft ob ein Notehead auf einer Halb-Step-Position liegt (Linie oder Zwischenraum).
/// Toleranz: 0.3 * spacing. Erlaubt bis zu ±5 Hilfslinien außerhalb des Systems.
/// Zusätzlich: filtert Volta-Brackets/Digits über der Stafflinie (schmaler aspect).
fn is_on_pitch_grid(nh: &Notehead, systems: &[StaffSystem]) -> bool {
    let staff = match systems.get(nh.staff_idx) {
        Some(s) => s,
        None => return false,
    };
    let spacing = staff.line_spacing;
    let cx = nh.center.x as usize;
    let top_line = &staff.lines[0];
    let top_line_y = if cx < top_line.y_per_x.len() {
        top_line.y_per_x[cx] as f32
    } else {
        top_line.y_per_x.first().copied().unwrap_or(0) as f32
    };
    let half_step = spacing * 0.5;
    let cy = nh.center.y;

    let pos = (cy - top_line_y) / half_step;
    let nearest = pos.round();
    let delta = (pos - nearest).abs() * half_step;

    if delta > spacing * 0.3 {
        return false;
    }
    // Range: 5-Linien-Staff hat 8 half-steps (line 0 = pos 0, line 4 = pos 8).
    if nearest < -10.0 || nearest > 18.0 {
        return false;
    }

    // Volta-Filter: NHs deutlich über dem Top-Line (>= 1.5 spacings = 3 half-steps)
    // mit schmalem Aspect (< 0.85, d.h. höher-als-breit) sind wahrscheinlich
    // Volta-Digits ("1.", "2.").
    let above_top = top_line_y - cy;
    if above_top > spacing * 1.5 && nh.bbox.aspect() < 0.85 {
        return false;
    }

    true
}

/// Merged kleine, nah benachbarte CCs zu größeren Bboxes.
/// Heuristik: Nur kleine CCs (jeweils < spacing*0.6 in Größe) werden gemerged.
/// Resultat muss NH-shape haben (aspect 0.7..1.8, h ≈ spacing).
/// Verhindert dass Noise-Cluster zu Fake-NHs werden.
fn merge_close_ccs(ccs: &[ConnectedComponent], spacing: f32) -> Vec<Rect> {
    let max_dx = spacing * 0.65;
    let max_dy = spacing * 0.4;
    let bboxes: Vec<Rect> = ccs.iter().map(|c| c.bbox).collect();

    // Trenne große CCs (intakt lassen) von Fragmenten (Kandidat für Merge).
    // Fragment-Definition: w < 0.9*spacing UND h < 1.2*spacing UND aspect ∈ [0.3, 3.0].
    // Damit fliegen lange schmale Stems (aspect > 5) raus, gefilterte sind Notehead-Halves.
    let (large, small): (Vec<Rect>, Vec<Rect>) = bboxes.into_iter().partition(|b| {
        let aspect = b.aspect();
        let is_fragment = (b.w as f32) < spacing * 0.9
            && (b.h as f32) < spacing * 1.2
            && (0.3..=3.0).contains(&aspect);
        !is_fragment
    });

    // Merge nur unter den "small"-Kandidaten.
    let mut small_bboxes = small;
    let mut changed = true;
    while changed {
        changed = false;
        let mut i = 0;
        while i < small_bboxes.len() {
            let mut j = i + 1;
            while j < small_bboxes.len() {
                let a = small_bboxes[i];
                let b = small_bboxes[j];
                if rects_close_xy(&a, &b, max_dx, max_dy) {
                    let m = rect_union(&a, &b);
                    let aspect = m.aspect();
                    // Nur wenn das Ergebnis NH-shape ist
                    if (m.w as f32) <= spacing * 2.5
                        && (m.h as f32) <= spacing * 1.6
                        && (m.h as f32) >= spacing * 0.5
                        && (m.w as f32) >= spacing * 0.6
                        && (0.6..=3.0).contains(&aspect)
                    {
                        small_bboxes[i] = m;
                        small_bboxes.remove(j);
                        changed = true;
                        continue;
                    }
                }
                j += 1;
            }
            i += 1;
        }
    }

    // Aus small_bboxes nur die behalten die NH-Größe haben (w ≥ spacing*0.6).
    // Damit fliegt Noise allein nicht durch.
    let valid_small: Vec<Rect> = small_bboxes
        .into_iter()
        .filter(|b| b.w as f32 >= spacing * 0.6 && b.h as f32 >= spacing * 0.5)
        .collect();

    let mut out = large;
    out.extend(valid_small);
    out
}

fn rects_close_xy(a: &Rect, b: &Rect, max_dx: f32, max_dy: f32) -> bool {
    let ax_end = a.x + a.w;
    let bx_end = b.x + b.w;
    let ay_end = a.y + a.h;
    let by_end = b.y + b.h;
    let dx = if a.x > bx_end {
        (a.x - bx_end) as f32
    } else if b.x > ax_end {
        (b.x - ax_end) as f32
    } else {
        0.0
    };
    let dy = if a.y > by_end {
        (a.y - by_end) as f32
    } else if b.y > ay_end {
        (b.y - ay_end) as f32
    } else {
        0.0
    };
    dx <= max_dx && dy <= max_dy
}

fn rect_union(a: &Rect, b: &Rect) -> Rect {
    let x = a.x.min(b.x);
    let y = a.y.min(b.y);
    let x_end = (a.x + a.w).max(b.x + b.w);
    let y_end = (a.y + a.h).max(b.y + b.h);
    Rect { x, y, w: x_end - x, h: y_end - y }
}

/// Aus komplexem CC (Notehead+Stem oder Notehead+Beam-Group) alle enthaltenen
/// Notenköpfe extrahieren via Sliding-Window auf Spalten-Densität.
fn extract_noteheads_from_complex(
    bin: &Binary,
    bb: &Rect,
    spacing: f32,
    systems: &[StaffSystem],
) -> Vec<Notehead> {
    // Multi-Measure-Rest (MMR) Filter:
    // MMR-Bar = solider horizontaler Strich im Mittelbereich des Systems,
    // typisch > 4*spacing breit, ~0.4-1.0*spacing hoch, sehr dicht.
    // Charakteristikum: horizontale Pixel-Reihe(n) mit Density > 70% der Breite
    // dominieren das CC.
    let mmr_check = check_multi_measure_rest_bar(bin, bb, spacing);
    if mmr_check.is_mmr {
        debug!(x = bb.x, y = bb.y, w = bb.w, h = bb.h, "rejected as multi-measure-rest bar");
        return vec![];
    }

    // Hardline-Filter: Thin-Wide CCs können physisch keine Noteheads enthalten.
    // Real Beam-Group hat h ≥ 2.5*spacing (NH + Stem + Beam, mit Stem ≥ 2*spacing).
    // Tied-Slur/Underline/Augmentation-Slur hinterlassen wide-thin Reststreifen
    // (h ≤ 2*spacing, w ≥ 3*spacing), die dem MMR-Check entkommen, weil leichte
    // Krümmungen das `inner-outside-pixels` Limit reißen. Diese CCs enthalten
    // keine NHs — REJECT.
    if (bb.h as f32) <= spacing * 2.0 && (bb.w as f32) >= spacing * 3.0 {
        debug!(x = bb.x, y = bb.y, w = bb.w, h = bb.h, "rejected as thin-wide non-NH stripe");
        return vec![];
    }

    // Wenn das CC schmaler als 2*spacing ist, ist es definitiv NUR ein Notehead+Stem.
    let nh_w = (spacing * 1.3).round() as u32;
    if bb.w < (spacing * 2.0) as u32 {
        if let Some(nh) = extract_single_notehead_from_tall(bin, bb, spacing, systems) {
            return vec![nh];
        }
        return vec![];
    }

    // Wide CC = Beam-Gruppe. Scanne X-Spalten in Schritten von spacing*0.6
    // und extrahiere an jeder X-Position eine potentielle Notehead-Region.
    let mut noteheads = Vec::new();
    let step = (spacing * 0.6).max(2.0) as u32;
    let mut x = bb.x;
    let nh_h = spacing.round() as u32;
    while x + nh_w <= bb.x + bb.w {
        let sub_bb = Rect { x, y: bb.y, w: nh_w, h: bb.h };
        let row_density = local_row_density(bin, &sub_bb);
        if row_density.is_empty() { x += step; continue; }
        let win = (nh_h as usize).min(row_density.len());
        if win == 0 { x += step; continue; }

        let mut window_sum: u32 = row_density[..win].iter().sum();
        let mut best_sum = window_sum;
        let mut best_start: usize = 0;
        for i in win..row_density.len() {
            window_sum += row_density[i];
            window_sum -= row_density[i - win];
            if window_sum > best_sum {
                best_sum = window_sum;
                best_start = i + 1 - win;
            }
        }

        let avg_density = best_sum as f32 / win as f32;
        // Mindest-Densität: 0.55 * NH-Breite.
        if avg_density < nh_w as f32 * 0.55 {
            x += step;
            continue;
        }

        // Beam-vs-Notehead-Discrimination:
        // Ein Beam hat HOMOGENE Density über seine ganze Höhe (Dicke ~0.4*spacing).
        // Ein Notenkopf hat MAX-Density im Zentrum, abnehmend nach oben/unten.
        //
        // Test: Vergleiche das beste Window mit den DIREKT angrenzenden Zeilen.
        // Bei Beam: angrenzende Zeilen haben ähnliche Density wie Window.
        // Bei NH: angrenzende Zeilen sind viel weniger dense (sparse).
        // Bei Stem: window-Density ist niedriger als nh_w*0.55, ist schon
        //   gefiltert.
        let above_avg = if best_start >= 4 {
            (best_start - 4..best_start).map(|i| row_density[i]).sum::<u32>() as f32 / 4.0
        } else { 0.0 };
        let below_idx = best_start + win;
        let below_avg = if below_idx + 4 <= row_density.len() {
            (below_idx..below_idx + 4).map(|i| row_density[i]).sum::<u32>() as f32 / 4.0
        } else { 0.0 };
        let surrounding = above_avg.max(below_avg);
        // Wenn surrounding > 0.7 * avg_density UND avg_density > 0.85 * nh_w,
        // dann ist es wahrscheinlich ein Beam (homogen).
        if surrounding > avg_density * 0.7 && avg_density > nh_w as f32 * 0.85 {
            x += step;
            continue;
        }

        let nh_y = bb.y + best_start as u32;
        let nh_bbox = Rect { x, y: nh_y, w: nh_w, h: nh_h };
        let staff_idx = match closest_staff(&nh_bbox, systems) {
            Some(s) => s,
            None => { x += step; continue; }
        };
        let kind = classify_notehead_kind(bin, &nh_bbox, spacing);
        let pixel_count = count_pixels_in_rect(bin, &nh_bbox);
        let fill_ratio = pixel_count as f32 / nh_bbox.area().max(1) as f32;
        let (cx, cy) = subpixel_center(bin, &nh_bbox);
        let too_close = noteheads.iter().any(|prev: &Notehead| {
            (prev.center.x - cx).abs() < spacing * 0.8
                && (prev.center.y - cy).abs() < spacing * 0.5
        });
        if !too_close {
            noteheads.push(Notehead {
                bbox: nh_bbox,
                center: Point { x: cx, y: cy },
                confidence: confidence_score(fill_ratio, nh_bbox.aspect(), kind) * 0.85,
                kind,
                staff_idx,
            });
        }
        x += step;
    }
    noteheads
}

fn extract_single_notehead_from_tall(
    bin: &Binary,
    bb: &Rect,
    spacing: f32,
    systems: &[StaffSystem],
) -> Option<Notehead> {
    extract_notehead_from_tall(bin, bb, spacing, systems)
}

/// Erkennt eine Multi-Measure-Rest (MMR) Bar oder ähnlichen "thin horizontal
/// solid stripe" der durch staff-removal als wide-thin CC übrig bleibt.
///
/// Robuste Heuristik (auch wenn End-Ticks im Bbox enthalten sind):
///  1. Finde die Reihen mit Density >= 50% der Breite (das sind die BAR-Reihen).
///  2. Diese Reihen müssen kontigues + dünn (≤ 0.9*spacing) sein.
///  3. Ermittele die X-Range der Bar (bar_x_min..bar_x_max).
///  4. AUSSERHALB der Bar-Reihen, IM INNEREN der Bar-X-Range (mit Margin von
///     1*spacing für End-Ticks), darf KAUM Pixel-Aktivität sein.
///     - MMR-Pattern: Ticks am Rand des Bars → inneres Außerhalb-Gebiet leer.
///     - Beam-Gruppe: Stems im ganzen Bereich verteilt → inneres Außerhalb voll.
#[derive(Debug)]
struct MmrCheck {
    is_mmr: bool,
    reason: &'static str,
    bar_height: f32,
    bar_width: f32,
    inner_outside_pixels: u32,
    max_allowed: u32,
}

fn check_multi_measure_rest_bar(bin: &Binary, bb: &Rect, spacing: f32) -> MmrCheck {
    let mut result = MmrCheck {
        is_mmr: false,
        reason: "init",
        bar_height: 0.0,
        bar_width: 0.0,
        inner_outside_pixels: 0,
        max_allowed: 0,
    };
    if (bb.w as f32) < spacing * 2.5 { result.reason = "bbox-too-narrow"; return result; }
    if bb.h < 2 || bb.w < 2 { result.reason = "bbox-tiny"; return result; }

    // Finde dichte (BAR) Zeilen: Density >= 50% der Breite.
    let row_density = local_row_density(bin, bb);
    if row_density.len() < 2 { result.reason = "no-rows"; return result; }

    let bar_threshold = (bb.w as f32 * 0.5) as u32;
    let mut bar_rows: Vec<usize> = row_density.iter().enumerate()
        .filter(|(_, &d)| d >= bar_threshold)
        .map(|(i, _)| i)
        .collect();
    if bar_rows.is_empty() { result.reason = "no-dense-rows"; return result; }
    bar_rows.sort();

    let bar_top = *bar_rows.first().unwrap();
    let bar_bot = *bar_rows.last().unwrap();
    if bar_rows.len() != (bar_bot - bar_top + 1) { result.reason = "rows-not-contiguous"; return result; }
    let bar_height = (bar_bot - bar_top + 1) as f32;
    result.bar_height = bar_height;
    if bar_height > spacing * 0.9 { result.reason = "bar-too-thick"; return result; }

    // Ermittele die X-Range der Bar.
    let mut bar_x_min = bb.w;
    let mut bar_x_max = 0u32;
    for y_off in bar_top..=bar_bot {
        let y = bb.y + y_off as u32;
        if y >= bin.h { continue; }
        for x_off in 0..bb.w {
            let x = bb.x + x_off;
            if x >= bin.w { continue; }
            if bin.get(x, y) == 1 {
                if x_off < bar_x_min { bar_x_min = x_off; }
                if x_off > bar_x_max { bar_x_max = x_off; }
            }
        }
    }
    if bar_x_max <= bar_x_min { result.reason = "bar-no-extent"; return result; }
    let bar_width = (bar_x_max - bar_x_min + 1) as f32;
    result.bar_width = bar_width;
    if bar_width < spacing * 2.5 { result.reason = "bar-too-narrow"; return result; }

    // Inner-X-Range: 1*spacing margin links und rechts, um End-Ticks
    // auszuschließen.
    let margin = spacing as u32;
    if bar_x_max < bar_x_min + 2 * margin { result.reason = "no-inner-region"; return result; }
    let inner_x_min = bar_x_min + margin;
    let inner_x_max = bar_x_max - margin;

    // Zähle aktive Pixel AUSSERHALB der Bar-Reihen, IM INNEREN der X-Range.
    let mut inner_outside_pixels: u32 = 0;
    for (i, _) in row_density.iter().enumerate() {
        if i >= bar_top && i <= bar_bot { continue; }
        let y = bb.y + i as u32;
        if y >= bin.h { continue; }
        for x_off in inner_x_min..=inner_x_max {
            let x = bb.x + x_off;
            if x >= bin.w { continue; }
            if bin.get(x, y) == 1 {
                inner_outside_pixels += 1;
            }
        }
    }
    result.inner_outside_pixels = inner_outside_pixels;

    // Schwellwert: erlauben bis zu 2*spacing Pixel als Noise (Punkte, schmale
    // Tick-Spitzen die in den Inner-Bereich ragen).
    let max_allowed = (spacing * 2.0) as u32;
    result.max_allowed = max_allowed;
    if inner_outside_pixels > max_allowed { result.reason = "inner-pixels-too-many"; return result; }

    // Sanity: Bar must extend at least 50% across the bbox width
    if bar_width < bb.w as f32 * 0.5 { result.reason = "bar-not-spanning-bbox"; return result; }

    result.is_mmr = true;
    result.reason = "mmr-confirmed";
    result
}

fn is_in_skip_region(nh: &Notehead, skip_x_per_system: &[std::ops::Range<u32>]) -> bool {
    if let Some(range) = skip_x_per_system.get(nh.staff_idx) {
        let x = nh.center.x as u32;
        x >= range.start && x < range.end
    } else { false }
}

fn classify_simple_notehead(
    bin: &Binary,
    bb: &Rect,
    spacing: f32,
    systems: &[StaffSystem],
) -> Option<Notehead> {
    let staff_idx = closest_staff(bb, systems)?;
    let kind = classify_notehead_kind(bin, bb, spacing);
    let pixel_count = count_pixels_in_rect(bin, bb);
    let fill_ratio = pixel_count as f32 / bb.area().max(1) as f32;
    let (cx, cy) = subpixel_center(bin, bb);
    Some(Notehead {
        bbox: *bb,
        center: Point { x: cx, y: cy },
        confidence: confidence_score(fill_ratio, bb.aspect(), kind),
        kind,
        staff_idx,
    })
}

/// Klassifiziert Notehead-Kind robust gegen Staff-Fragmente:
///  - Filled: Inner-Region (zentrale 60%) ist genauso dicht wie Outer-Region.
///  - Open: Inner-Region ist DEUTLICH weniger dicht (Hole) als Outer-Region.
///  - Whole: Wie Open, aber Bbox ist 1.6×spacing breit.
pub(crate) fn classify_notehead_kind(bin: &Binary, bb: &Rect, spacing: f32) -> NoteheadKind {
    if bb.w == 0 || bb.h == 0 {
        return NoteheadKind::Filled;
    }
    // Outer ring (alle Pixel im bbox)
    let total = count_pixels_in_rect(bin, bb);
    let outer_density = total as f32 / bb.area().max(1) as f32;

    // Inner-Region: zentrale 50% × 50% des bbox
    let inner_w = bb.w / 2;
    let inner_h = bb.h / 2;
    if inner_w < 2 || inner_h < 2 {
        // Zu klein für Hole-Check → fallback auf Outer-Density
        return if outer_density > 0.6 { NoteheadKind::Filled } else { NoteheadKind::Open };
    }
    let inner_x = bb.x + (bb.w - inner_w) / 2;
    let inner_y = bb.y + (bb.h - inner_h) / 2;
    let inner_bb = Rect { x: inner_x, y: inner_y, w: inner_w, h: inner_h };
    let inner_count = count_pixels_in_rect(bin, &inner_bb);
    let inner_density = inner_count as f32 / inner_bb.area().max(1) as f32;

    // Whole: sehr breit (>1.45×spacing) UND Hole vorhanden.
    let is_wide = bb.w as f32 > spacing * 1.45;

    // Hole-Detection: inner_density deutlich kleiner als outer_density.
    // Filled hat inner ≈ outer (beide ~0.85-1.0).
    // Open hat outer ~0.5, inner ~0.1 (Loch).
    let has_hole = inner_density < outer_density * 0.55 || inner_density < 0.35;

    if has_hole {
        if is_wide { NoteheadKind::Whole } else { NoteheadKind::Open }
    } else {
        NoteheadKind::Filled
    }
}

/// Aus einem tall-narrow-CC (Notehead+Stem oder Notehead+Stem+Beam) den
/// eigentlichen Notenkopf-Bereich extrahieren.
fn extract_notehead_from_tall(
    bin: &Binary,
    bb: &Rect,
    spacing: f32,
    systems: &[StaffSystem],
) -> Option<Notehead> {
    // Berechne horizontale Pixel-Density pro Zeile (innerhalb der bbox).
    let row_density = local_row_density(bin, bb);
    if row_density.is_empty() { return None; }

    // Notenkopf-Region = Sliding-Window von ca. spacing Zeilen mit max Σ row_density.
    let nh_h = spacing.round() as u32;
    let nh_h = nh_h.clamp(4, bb.h);
    let win = nh_h as usize;

    // Sliding-Window-Sum.
    let mut window_sum: u32 = row_density[..win.min(row_density.len())].iter().sum();
    let mut best_sum = window_sum;
    let mut best_start: usize = 0;
    for i in win..row_density.len() {
        window_sum += row_density[i];
        window_sum -= row_density[i - win];
        if window_sum > best_sum {
            best_sum = window_sum;
            best_start = i + 1 - win;
        }
    }

    // Mindest-Density um Stem-only-Region auszuschließen (Stem hat ~1-3 px/zeile,
    // Notehead-Zeile hat ~spacing px/zeile).
    let avg_density = best_sum as f32 / win as f32;
    if avg_density < spacing * 0.4 { return None; }

    let nh_y = bb.y + best_start as u32;
    let nh_bbox = Rect {
        x: bb.x,
        y: nh_y,
        w: bb.w,
        h: nh_h,
    };

    let staff_idx = closest_staff(&nh_bbox, systems)?;
    let kind = classify_notehead_kind(bin, &nh_bbox, spacing);
    let pixel_count = count_pixels_in_rect(bin, &nh_bbox);
    let fill_ratio = pixel_count as f32 / nh_bbox.area().max(1) as f32;
    let (cx, cy) = subpixel_center(bin, &nh_bbox);
    Some(Notehead {
        bbox: nh_bbox,
        center: Point { x: cx, y: cy },
        confidence: confidence_score(fill_ratio, nh_bbox.aspect(), kind) * 0.9,
        kind,
        staff_idx,
    })
}

/// Implied-Stem-Detection für eine Notehead die aus einem tall-narrow-CC kommt.
/// Returns den Stem WENN das CC oberhalb oder unterhalb der NH-Region noch
/// ein langes schmales Run-Gebiet hat.
///
/// Algorithmus mit erhöhter Robustheit für reale Scans:
/// - 3px Gap-Tolerance (verschmierter Druck, JPEG-Artefakte)
/// - ±5px Scan-Range um NH-Bbox
/// - Wählt die Spalte mit längstem zusammenhängenden Run
pub fn implied_stem_for_tall_notehead(
    bin: &Binary,
    nh: &Notehead,
    spacing: f32,
) -> Option<Stem> {
    let bb = nh.bbox;
    // Erweiterter Scan-Range: bb ± 5px (vorher 3px) — für reale Scans wo Stems
    // leicht versetzt zur idealen NH-Position liegen.
    let bx0 = bb.x.saturating_sub(5);
    let bx1 = (bb.x + bb.w + 5).min(bin.w);
    let min_stem = (spacing * 1.3) as i32;
    let max_gap = 3u32;
    let mut best: Option<Stem> = None;

    for x in bx0..bx1 {
        // Walk UP from bb.y mit erhöhter Lücken-Toleranz (3px statt 1px)
        let mut top = bb.y;
        let mut gap = 0u32;
        while top > 0 {
            if bin.get(x, top - 1) == 1 {
                top -= 1;
                gap = 0;
            } else if gap < max_gap {
                top = top.saturating_sub(1);
                gap += 1;
            } else {
                break;
            }
        }
        let above = bb.y as i32 - top as i32;

        // Walk DOWN mit gleicher Toleranz
        let bottom_start = bb.y + bb.h.saturating_sub(1);
        let mut bot = bottom_start;
        gap = 0;
        while bot + 1 < bin.h {
            if bin.get(x, bot + 1) == 1 {
                bot += 1;
                gap = 0;
            } else if gap < max_gap {
                bot += 1;
                gap += 1;
            } else {
                break;
            }
        }
        let below = bot as i32 - bottom_start as i32;

        if above >= min_stem || below >= min_stem {
            let candidate = Stem {
                x,
                y_top: top,
                y_bot: bot,
                notehead_idx: None,
            };
            best = match best {
                Some(s) if (s.y_bot - s.y_top) >= (bot - top) => Some(s),
                _ => Some(candidate),
            };
        }
    }
    best
}

fn local_row_density(bin: &Binary, bb: &Rect) -> Vec<u32> {
    let mut out = Vec::with_capacity(bb.h as usize);
    for y in bb.y..(bb.y + bb.h) {
        let mut s = 0u32;
        for x in bb.x..(bb.x + bb.w) {
            s += bin.get(x, y) as u32;
        }
        out.push(s);
    }
    out
}

fn count_pixels_in_rect(bin: &Binary, bb: &Rect) -> u32 {
    let mut s = 0u32;
    for y in bb.y..(bb.y + bb.h) {
        for x in bb.x..(bb.x + bb.w) {
            s += bin.get(x, y) as u32;
        }
    }
    s
}

fn closest_staff(bb: &Rect, systems: &[StaffSystem]) -> Option<usize> {
    let cy = bb.cy();
    // 3.5*spacing ≈ Stafflinien-Höhe (2 spacings) + 2 Hilfslinien-Spacings + Margin.
    // Damit werden Title/Copyright-Text die typisch 5+ spacings über der Stafflinie
    // liegen herausgefiltert.
    systems
        .iter()
        .enumerate()
        .map(|(i, s)| (i, (s.middle_y() - cy).abs()))
        .filter(|&(_, d)| d < 3.5 * systems[0].line_spacing)
        .min_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal))
        .map(|(i, _)| i)
}

fn subpixel_center(bin: &Binary, bb: &Rect) -> (f32, f32) {
    let mut sx = 0.0f64;
    let mut sy = 0.0f64;
    let mut n = 0u64;
    for y in bb.y..(bb.y + bb.h) {
        for x in bb.x..(bb.x + bb.w) {
            if bin.get(x, y) == 1 {
                sx += x as f64;
                sy += y as f64;
                n += 1;
            }
        }
    }
    if n == 0 {
        (bb.cx(), bb.cy())
    } else {
        (sx as f32 / n as f32 + 0.5, sy as f32 / n as f32 + 0.5)
    }
}

fn confidence_score(fill_ratio: f32, aspect: f32, kind: NoteheadKind) -> f32 {
    let (target_a, target_f) = match kind {
        NoteheadKind::Filled => (1.3, 0.85),
        NoteheadKind::Open => (1.2, 0.40),
        NoteheadKind::Whole => (1.6, 0.45),
    };
    let aspect_score = (1.0 - (aspect - target_a).abs() / 0.5).max(0.0);
    let fill_score = (1.0 - (fill_ratio - target_f).abs() / 0.3).max(0.0);
    (aspect_score * fill_score).clamp(0.0, 1.0)
}

/// Konvertiere Noteheads + Stems + Beams → ScoreNotes mit Pitch + Duration.
pub fn noteheads_to_notes(
    noteheads: &[Notehead],
    systems: &[StaffSystem],
    stems: &[Stem],
    beam_counts: &[u32],
    clef: omr_core::Clef,
    key: omr_core::KeySignature,
) -> Vec<ScoreNote> {
    noteheads_to_notes_with_dots(noteheads, systems, stems, beam_counts, clef, key, &[])
}

/// Wie `noteheads_to_notes`, aber mit Augmentation-Dot-Counts pro Notehead.
pub fn noteheads_to_notes_with_dots(
    noteheads: &[Notehead],
    systems: &[StaffSystem],
    stems: &[Stem],
    beam_counts: &[u32],
    clef: omr_core::Clef,
    key: omr_core::KeySignature,
    dots_per_nh: &[u8],
) -> Vec<ScoreNote> {
    noteheads_to_notes_with_ledger(noteheads, systems, stems, beam_counts, clef, key, dots_per_nh, &[])
}

/// Wie [`noteheads_to_notes_with_dots`], aber mit Ledger-Info pro NH für
/// kalibrierte Pitch-Berechnung außerhalb der Staff.
pub fn noteheads_to_notes_with_ledger(
    noteheads: &[Notehead],
    systems: &[StaffSystem],
    stems: &[Stem],
    beam_counts: &[u32],
    clef: omr_core::Clef,
    key: omr_core::KeySignature,
    dots_per_nh: &[u8],
    ledger_per_nh: &[Option<crate::ledger_lines::LedgerInfo>],
) -> Vec<ScoreNote> {
    let mut notes = Vec::with_capacity(noteheads.len());
    for (idx, nh) in noteheads.iter().enumerate() {
        let staff = match systems.get(nh.staff_idx) {
            Some(s) => s,
            None => continue,
        };
        // Wenn ledger_info vorhanden: nutze pitch_from_xy_with_ledger fuer
        // kalibrierte Pitch-Berechnung. Sonst standard pitch_from_xy.
        let pitch = if let Some(Some(ledger)) = ledger_per_nh.get(idx) {
            pitch::pitch_from_xy_with_ledger(
                nh.center.x, nh.center.y, staff, clef, key,
                Some(ledger.ledger_y), ledger.ledger_count,
            )
        } else {
            pitch::pitch_from_xy(nh.center.x, nh.center.y, staff, clef, key)
        };
        let stem_idx = stems.iter().position(|s| s.notehead_idx == Some(idx));
        let has_stem = stem_idx.is_some();
        let n_beams = stem_idx.and_then(|i| beam_counts.get(i)).copied().unwrap_or(0);

        let base_duration = match (nh.kind, has_stem, n_beams) {
            (NoteheadKind::Whole, _, _) => 16,
            (NoteheadKind::Open, true, _) => 8,
            (NoteheadKind::Open, false, _) => 16,
            (NoteheadKind::Filled, true, 0) => 4,
            (NoteheadKind::Filled, true, 1) => 2,
            (NoteheadKind::Filled, true, 2) => 1,
            (NoteheadKind::Filled, true, _) => 1,
            (NoteheadKind::Filled, false, _) => 4,
        };
        let dots = dots_per_nh.get(idx).copied().unwrap_or(0);
        // Punktierung: 1 Punkt = ×1.5, 2 Punkte = ×1.75
        let duration = match dots {
            0 => base_duration,
            1 => base_duration + base_duration / 2,
            2 => base_duration + base_duration / 2 + base_duration / 4,
            _ => base_duration,
        };
        notes.push(ScoreNote {
            midi: pitch.midi,
            step: pitch.step,
            alter: pitch.alter,
            octave: pitch.octave,
            duration,
            onset: 0,
            voice: 1,
            kind: nh.kind,
            center: nh.center,
            augmentation_dots: dots,
            in_chord: false,
            is_rest: false,
        });
    }
    notes
}

/// Detektiert Augmentation-Dots (Punktierungen) für gegebene Noteheads.
/// Returns Vec<u8> mit gleicher Länge wie noteheads — jeweils 0, 1 oder 2.
///
/// Heuristik: Suche kleine isolierte CCs (radius ~ 0.2-0.35 spacing) im Bereich
/// 0.3-1.2 spacing rechts von der NH, in Y-Range ±0.5 spacing der NH-Mitte.
/// Wenn 2 Dots in Reihe: doppelt punktiert.
pub fn detect_augmentation_dots(
    bin: &Binary,
    noteheads: &[Notehead],
    spacing: f32,
) -> Vec<u8> {
    // Erweiterte Heuristik fuer Punktierungs-Recall:
    // - Untergrenze 0.10*spacing (war: 0.15) — Dots sind oft sehr klein (< 3px)
    // - Obergrenze 0.45*spacing (war: 0.40) — leicht groessere Dots zulassen
    // - dx-Range erweitert: 0.20 - 1.6 spacing (war: 0.30 - 1.40) — manche
    //   Dots sind direkt am NH (kleine spacing) oder weit weg (1.5+ spacing)
    // - dy-Toleranz: 0.6 spacing (war: 0.5) — Dots sind manchmal etwas oberhalb
    let dot_radius_min = (spacing * 0.10).max(1.0) as u32;
    let dot_radius_max = (spacing * 0.45).max(2.0) as u32;
    let dx_min = (spacing * 0.20) as i32;
    let dx_max = (spacing * 1.60) as i32;
    let dy_max = (spacing * 0.60) as i32;

    let ccs = connected_components(bin);
    // Erweiterte Aspect-Range: 0.5 - 2.0 (war: 0.6 - 1.7) — Dots können
    // leicht oval sein wegen Anti-Aliasing oder Druck-Spread.
    let dot_ccs: Vec<&ConnectedComponent> = ccs
        .iter()
        .filter(|c| {
            c.bbox.w >= dot_radius_min
                && c.bbox.w <= dot_radius_max
                && c.bbox.h >= dot_radius_min
                && c.bbox.h <= dot_radius_max
                && {
                    let aspect = c.bbox.aspect();
                    (0.5..=2.0).contains(&aspect)
                }
                // Dot muss "compact" sein — Pixel-Density > 50%
                && {
                    let area = (c.bbox.w * c.bbox.h) as f32;
                    let pixels = c.pixels.len() as f32;
                    pixels / area.max(1.0) > 0.5
                }
        })
        .collect();

    let mut dots_per_nh = vec![0u8; noteheads.len()];
    for (i, nh) in noteheads.iter().enumerate() {
        // Sammele alle in-range Dot-Kandidaten und sortiere nach dx (links zuerst)
        let mut candidates: Vec<(f32, u32)> = Vec::new(); // (dx, cc_x)
        for cc in &dot_ccs {
            let cdx = cc.bbox.cx() - nh.center.x;
            let cdy = cc.bbox.cy() - nh.center.y;
            if (cdx as i32) >= dx_min && (cdx as i32) <= dx_max && (cdy.abs() as i32) <= dy_max {
                candidates.push((cdx, cc.bbox.x));
            }
        }
        candidates.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap_or(std::cmp::Ordering::Equal));
        // Eine Punktierung: 1 Dot. Doppelpunktierung: 2 Dots in Reihe.
        // Limit count to 2 — mehr als 2 Punktierungen sind extrem selten.
        dots_per_nh[i] = (candidates.len() as u8).min(2);
    }
    dots_per_nh
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_filled_notehead() {
        let mut bin = Binary::new(160, 160);
        for y in 60..72 {
            for x in 60..74 {
                bin.set(x, y, 1);
            }
        }
        let staff = StaffSystem {
            lines: (0..5).map(|i| omr_core::StaffLine {
                y_per_x: vec![40 + i * 12; 160],
            }).collect(),
            line_spacing: 12.0,
            line_thickness: 2.0,
        };
        let nhs = detect_noteheads(&bin, &[staff]);
        assert!(!nhs.is_empty(), "expected at least one notehead");
        assert!(matches!(nhs[0].kind, NoteheadKind::Filled));
    }

    #[test]
    fn detects_notehead_with_stem() {
        // Notehead 14×12 unten + Stem 2×40 nach oben verbunden = ein langes CC.
        let mut bin = Binary::new(80, 200);
        for y in 80..92 {
            for x in 30..44 {
                bin.set(x, y, 1);
            }
        }
        // Stem 2px breit nach oben
        for y in 40..80 {
            for x in 36..38 {
                bin.set(x, y, 1);
            }
        }
        let staff = StaffSystem {
            lines: (0..5).map(|i| omr_core::StaffLine {
                y_per_x: vec![60 + i * 12; 80],
            }).collect(),
            line_spacing: 12.0,
            line_thickness: 2.0,
        };
        let nhs = detect_noteheads(&bin, &[staff]);
        assert!(!nhs.is_empty(), "expected notehead extracted from tall CC");
        // Notehead-bbox sollte um y≈85 zentriert sein (Bottom of CC).
        let center_y = nhs[0].center.y;
        assert!((center_y - 86.0).abs() < 4.0, "center.y expected ~86, got {}", center_y);
    }
}
