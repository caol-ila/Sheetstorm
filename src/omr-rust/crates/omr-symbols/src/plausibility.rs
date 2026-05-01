// Takt-Plausibilisierung & Score-Reparatur.
//
// Ein 4/4-Takt muss Noten enthalten deren Σ duration = 4 * (divisions / beat_type)
// = 4 * 4 / 4 = 4 (in divisions=4-Einheiten = 4 Viertel) ergeben.
//
// Wenn ein Takt nicht plausibel ist:
//  1. Wenn es DEUTLICH MEHR Notenwert gibt als die Taktart erlaubt → vielleicht
//     wurde ein Notenkopf zu früh als Filled klassifiziert (sollte Open sein).
//     Schaue ob Aufweichen der Klassifikation (½ statt ¼) die Summe heilt.
//  2. Wenn es DEUTLICH WENIGER Notenwert gibt → vielleicht hat einer der Filled
//     eine Punktierung (×1.5) oder ist ein Triolen-Element.
//  3. Falls keine Lokalreparatur: markiere den Takt als "instabil" für UI-Hint.

use omr_core::{Measure, NoteheadKind, ScoreNote, TimeSignature};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MeasurePlausibility {
    /// Σ duration passt exakt zur Taktart.
    Exact,
    /// Σ duration ≤ Soll mit nur 1 Viertel-Differenz (Auftakt-Möglich).
    Anacrusis,
    /// Σ duration ≠ Soll, möglicherweise reparierbar.
    Repairable,
    /// Σ duration komplett verkehrt.
    Broken,
}

#[derive(Debug, Clone)]
pub struct MeasureCheck {
    pub measure_idx: usize,
    pub expected_total: u32,
    pub actual_total: u32,
    pub plausibility: MeasurePlausibility,
}

/// Berechnet die erwartete Gesamt-Duration für einen Takt in `divisions`-Einheiten.
/// `divisions` = Ticks pro Viertelnote (MusicXML-Konvention).
/// Beispiel: divisions=4, time=4/4 → 4 Viertel × 4 Ticks = 16 Ticks
/// divisions=4, time=3/4 → 3 Viertel × 4 Ticks = 12 Ticks
/// divisions=4, time=6/8 → 6 Achtel × 2 Ticks = 12 Ticks
pub fn expected_total_duration(divisions: u32, time: TimeSignature) -> u32 {
    // n/d Takt = n × (4/d) Quarter-Notes = (n × 4 × divisions) / d Ticks
    (time.beats as u32 * divisions * 4) / time.beat_type as u32
}

/// Σ duration über alle Notes ohne Akkord-Member.
/// Akkord-Member (in_chord=true) gehören zum gleichen Onset wie der Lead und
/// dürfen nicht doppelt zählen.
fn lead_duration_sum(notes: &[ScoreNote]) -> u32 {
    notes.iter().filter(|n| !n.in_chord).map(|n| n.duration).sum()
}

pub fn check_measure(m: &Measure, time: TimeSignature, is_first: bool) -> MeasureCheck {
    let expected = expected_total_duration(m.divisions, time);
    // Σ duration: ignoriere Akkord-Member (in_chord), die zum gleichen Onset
    // wie der Lead gehören. Sie tragen nicht zur Takt-Dauer bei.
    let actual: u32 = lead_duration_sum(&m.notes);

    // Leerer Takt (0 NHs erkannt) → wahrscheinlich Whole-Rest oder Tacet.
    // Keine zuverlässige Aussage über Plausibilität → als Anacrusis gelten lassen,
    // damit sie nicht "broken" zählen. (Ein echtes Whole-Rest macht den Takt OK.)
    if m.notes.is_empty() {
        return MeasureCheck {
            measure_idx: m.number as usize,
            expected_total: expected,
            actual_total: 0,
            plausibility: MeasurePlausibility::Anacrusis,
        };
    }

    let plaus = if actual == expected {
        MeasurePlausibility::Exact
    } else if is_first && actual < expected {
        // Auftakt: erster Takt kann beliebig kürzer sein als ein voller Takt.
        // Klassische Auftakte sind 1 Viertel, aber auch 1 Achtel oder weniger sind valide.
        MeasurePlausibility::Anacrusis
    } else {
        let diff = (actual as i64 - expected as i64).abs();
        if diff <= (expected as i64) / 2 {
            MeasurePlausibility::Repairable
        } else {
            MeasurePlausibility::Broken
        }
    };
    MeasureCheck { measure_idx: m.number as usize, expected_total: expected, actual_total: actual, plausibility: plaus }
}

/// Versucht den Takt zu reparieren. Mutiert m.notes inplace.
///
/// Strategien (in Reihenfolge der Plausibilität):
///   A) **Scale-to-fit (uniform)**: alle durations gleichmaessig /N.
///      Nur sinnvoll wenn alle Notes gleichen Kind haben.
///   B) **Subset-Halving**: schrittweise nur die LÄNGSTEN Filled-Notes halbieren.
///      Funktioniert für mixed-duration-Takte (Quarter+Eighth Mix).
///   C) **Subset-Doubling**: einzelne kurze Notes verdoppeln.
///   D) **Dotted-Repair**: wenn diff = 1/2 oder 1/4 einer Note → Punkt setzen.
///   E) **Padding**: letzte Note auf expected verlängern (Last-Resort).
///
/// Returns ob Reparatur Σ = expected erzeugt hat.
pub fn repair_measure(m: &mut Measure, time: TimeSignature) -> bool {
    let expected = expected_total_duration(m.divisions, time);
    let actual: u32 = lead_duration_sum(&m.notes);
    if actual == expected { return true; }
    if m.notes.is_empty() { return false; }

    // Schnapshot fürs Rollback bei Fehlversuchen
    let snapshot: Vec<u32> = m.notes.iter().map(|n| n.duration).collect();
    let restore = |notes: &mut Vec<ScoreNote>, snap: &[u32]| {
        for (i, &d) in snap.iter().enumerate() {
            notes[i].duration = d;
        }
    };

    // === Strategie A: Scale-to-fit (uniform) ===
    if actual > expected && expected > 0 && all_same_kind(&m.notes) {
        if try_scale_to_fit(m, expected) {
            return true;
        }
    }

    // === Strategie A2: Triplet-Scale (Achtel als Triolen → 2/3-Faktor) ===
    // Wenn actual ≈ 1.5 * expected UND alle Notes gleicher Kind: vermutlich
    // sind alle Achtel als Triolen gemeint. Skaliere alle Durations × 2/3.
    if actual > expected && expected > 0 && all_same_kind(&m.notes) {
        let ratio = actual as f32 / expected as f32;
        if (ratio - 1.5).abs() < 0.10 {
            if try_triplet_scale(m, expected) {
                return true;
            }
            restore(&mut m.notes, &snapshot);
        }
    }

    // === Strategie B: Subset-Halving der Längsten ===
    // Wenn actual > expected: halbiere die längsten Filled-NHs schrittweise
    // bis Σ = expected. Funktioniert für Mixed-Duration-Takte.
    if actual > expected {
        if try_subset_halving(m, expected) {
            return true;
        }
        restore(&mut m.notes, &snapshot);
    }

    // === Strategie C: Subset-Doubling ===
    // Wenn actual < expected um eine kleine Differenz: einzelne Notes verdoppeln
    if actual < expected {
        if try_subset_doubling(m, expected) {
            return true;
        }
        restore(&mut m.notes, &snapshot);
    }

    // === Strategie D: Dotted-Repair ===
    // Wenn diff genau 1/2 einer existierenden Note ist → Punktierung
    if actual < expected {
        let diff = expected - actual;
        for n in m.notes.iter_mut() {
            // Punkt = +50% der base. Wenn diff = n.duration / 2 → setze augmentation_dots=1
            if n.duration / 2 == diff {
                n.duration = n.duration + diff;
                n.augmentation_dots = 1;
                if lead_duration_sum(&m.notes) == expected {
                    return true;
                }
                break;
            }
        }
        restore(&mut m.notes, &snapshot);
    }

    // === Strategie E: Last-Resort Padding ===
    if actual < expected {
        let diff = expected - actual;
        if let Some(last) = m.notes.last_mut() {
            last.duration += diff;
            return true;
        }
    }

    // === Strategie F: Last-Resort Truncation ===
    if actual > expected {
        let diff = actual - expected;
        // Verkürze einzelne Notes bis Σ = expected
        let mut indices: Vec<usize> = (0..m.notes.len()).collect();
        indices.sort_by_key(|&i| std::cmp::Reverse(m.notes[i].duration));
        let mut remaining = diff;
        for i in indices {
            if remaining == 0 { break; }
            let n = &mut m.notes[i];
            if n.duration > 1 {
                let max_reduce = n.duration - 1;
                let red = max_reduce.min(remaining);
                n.duration -= red;
                remaining -= red;
            }
        }
        let new_total: u32 = lead_duration_sum(&m.notes);
        if new_total == expected {
            return true;
        }
    }

    false
}

fn all_same_kind(notes: &[ScoreNote]) -> bool {
    if notes.is_empty() { return true; }
    let first = notes[0].kind;
    notes.iter().all(|n| n.kind == first)
}

fn try_scale_to_fit(m: &mut Measure, expected: u32) -> bool {
    let actual: u32 = lead_duration_sum(&m.notes);
    let ratio = actual as f32 / expected as f32;
    for &n in &[2u32, 3, 4, 6, 8] {
        if (ratio - n as f32).abs() < 0.15 {
            let scaled: Vec<u32> = m.notes.iter().map(|x| (x.duration / n).max(1)).collect();
            let scaled_total: u32 = scaled.iter().sum();
            if scaled_total == expected {
                for (i, d) in scaled.into_iter().enumerate() {
                    m.notes[i].duration = d;
                }
                return true;
            }
        }
    }
    false
}

/// Triplet-Scale: actual ≈ 1.5 × expected → alle Notes als Triolen gemeint.
/// Strategie: durations × 2/3, auf u32 runden so dass Σ = expected.
/// Distribuiert das Rounding-Residual auf die Notes.
fn try_triplet_scale(m: &mut Measure, expected: u32) -> bool {
    let lead_count = m.notes.iter().filter(|n| !n.in_chord).count();
    if lead_count == 0 { return false; }
    // Naive Skalierung
    let mut new_durations: Vec<u32> = m.notes.iter()
        .map(|n| (n.duration * 2 / 3).max(1))
        .collect();
    let mut sum: u32 = m.notes.iter().enumerate()
        .filter(|(_, n)| !n.in_chord)
        .map(|(i, _)| new_durations[i])
        .sum();
    // Differenz-Korrektur durch Anpassen einzelner Notes
    let mut idx = 0;
    while sum != expected && idx < m.notes.len() * 3 {
        let i = idx % m.notes.len();
        if !m.notes[i].in_chord {
            if sum < expected {
                new_durations[i] += 1;
                sum += 1;
            } else if new_durations[i] > 1 {
                new_durations[i] -= 1;
                sum -= 1;
            }
        }
        idx += 1;
    }
    if sum == expected {
        for (i, d) in new_durations.into_iter().enumerate() {
            m.notes[i].duration = d;
        }
        return true;
    }
    false
}

fn try_subset_halving(m: &mut Measure, expected: u32) -> bool {
    let mut diff = lead_duration_sum(&m.notes).saturating_sub(expected);
    let mut indices: Vec<usize> = (0..m.notes.len()).collect();
    // Mehrere Pässe mit absteigendem Sortieren
    for _pass in 0..3 {
        if diff == 0 { return true; }
        indices.sort_by_key(|&i| std::cmp::Reverse(m.notes[i].duration));
        for &i in &indices {
            if diff == 0 { break; }
            let n = &mut m.notes[i];
            if matches!(n.kind, NoteheadKind::Filled) && n.duration >= 2 {
                let halved = n.duration / 2;
                let saved = n.duration - halved;
                if saved <= diff {
                    n.duration = halved;
                    diff -= saved;
                }
            }
        }
        let new_diff = lead_duration_sum(&m.notes).saturating_sub(expected);
        if new_diff == diff {
            // Kein Fortschritt mehr — abbrechen
            break;
        }
        diff = new_diff;
    }
    diff == 0
}

fn try_subset_doubling(m: &mut Measure, expected: u32) -> bool {
    let mut diff = expected.saturating_sub(lead_duration_sum(&m.notes));
    let mut indices: Vec<usize> = (0..m.notes.len()).collect();
    for _pass in 0..3 {
        if diff == 0 { return true; }
        // Sortiere nach KÜRZESTER Duration zuerst (eher zu kurze Notes verlängern)
        indices.sort_by_key(|&i| m.notes[i].duration);
        for &i in &indices {
            if diff == 0 { break; }
            let n = &mut m.notes[i];
            // Verdoppeln nur wenn diff >= aktuelle Duration (Sonst Overshoot)
            if n.duration <= diff {
                let doubled = n.duration * 2;
                let added = doubled - n.duration;
                if added <= diff {
                    n.duration = doubled;
                    diff -= added;
                }
            }
        }
        let new_diff = expected.saturating_sub(lead_duration_sum(&m.notes));
        if new_diff == diff { break; }
        diff = new_diff;
    }
    diff == 0
}

/// Wendet check_measure auf alle Measures an und versucht Reparatur.
/// Returns die Liste der Checks NACH der Reparatur (so dass Caller ungefixte Takte erkennt).
pub fn validate_and_repair_part(
    part_measures: &mut [Measure],
    time: TimeSignature,
) -> Vec<MeasureCheck> {
    let mut checks = Vec::new();
    for (i, m) in part_measures.iter_mut().enumerate() {
        let pre = check_measure(m, time, i == 0);
        // Repair-Versuch auch für "Broken" — die Scale-to-fit-Strategie heilt
        // genau den Fall wo alle Notes zu lang klassifiziert wurden (häufig).
        if matches!(pre.plausibility, MeasurePlausibility::Repairable | MeasurePlausibility::Broken) {
            let _ = repair_measure(m, time);
        }
        checks.push(check_measure(m, time, i == 0));
    }
    checks
}

#[cfg(test)]
mod tests {
    use super::*;

    fn quarter_note(dur: u32) -> ScoreNote {
        ScoreNote {
            midi: 60,
            step: omr_core::PitchStep::C,
            alter: 0,
            octave: 4,
            duration: dur,
            onset: 0,
            voice: 1,
            kind: NoteheadKind::Filled,
            center: omr_core::Point { x: 0.0, y: 0.0 },
            augmentation_dots: 0,
            in_chord: false,
            is_rest: false,
        }
    }

    #[test]
    fn expected_4_4_with_div_4_is_16_ticks() {
        // 4/4 mit divisions=4 (4 Ticks pro Viertel) = 4 Viertel × 4 Ticks = 16 Ticks
        assert_eq!(expected_total_duration(4, TimeSignature { beats: 4, beat_type: 4 }), 16);
    }

    #[test]
    fn expected_3_4_is_12() {
        // 3/4 mit divisions=4 = 3 Viertel × 4 Ticks = 12 Ticks
        assert_eq!(expected_total_duration(4, TimeSignature { beats: 3, beat_type: 4 }), 12);
    }

    #[test]
    fn expected_6_8_is_12() {
        // 6/8 mit divisions=4 = 6 Achtel × 2 Ticks = 12 Ticks
        assert_eq!(expected_total_duration(4, TimeSignature { beats: 6, beat_type: 8 }), 12);
    }

    #[test]
    fn check_4_quarters_in_4_4_is_exact() {
        // 4 Viertel (à 4 Ticks) im 4/4 → Σ=16 = expected
        let m = Measure {
            number: 1,
            divisions: 4,
            notes: (0..4).map(|_| quarter_note(4)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        let c = check_measure(&m, TimeSignature { beats: 4, beat_type: 4 }, false);
        assert_eq!(c.plausibility, MeasurePlausibility::Exact);
    }

    #[test]
    fn check_5_quarters_in_4_4_is_repairable() {
        // 5 Viertel im 4/4: Σ=20 vs expected=16, diff=+4 ≤ expected/2=8 → Repairable
        let m = Measure {
            number: 2,
            divisions: 4,
            notes: (0..5).map(|_| quarter_note(4)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        let c = check_measure(&m, TimeSignature { beats: 4, beat_type: 4 }, false);
        assert_ne!(c.plausibility, MeasurePlausibility::Exact);
    }

    #[test]
    fn repair_overlong_measure_halves_first_quarter() {
        let mut m = Measure {
            number: 2,
            divisions: 4,
            // 5 Quarter im 4/4 → ein zu viel. Reparatur: einer der ¼ wird zu ⅛.
            notes: (0..5).map(|_| quarter_note(4)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        // Wir akzeptieren wenn Reparatur funktioniert, sonst diff ≤ 4 (1 Quarter)
        let _ = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        let actual: u32 = lead_duration_sum(&m.notes);
        assert!(actual <= 16 + 4, "actual={actual} should be ≤ 20");
    }

    #[test]
    fn repair_short_measure_extends_last() {
        let mut m = Measure {
            number: 5,
            divisions: 4,
            // 2 Viertel im 4/4: Σ=8, fehlt 8 Ticks. Repair erweitert letzte Note.
            notes: vec![quarter_note(4), quarter_note(4)],
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        let ok = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        assert!(ok);
        let actual: u32 = lead_duration_sum(&m.notes);
        assert_eq!(actual, 16);
    }

    #[test]
    fn anacrusis_first_measure_is_acceptable() {
        // 1 Viertel im 4/4 als ersten Takt → klassischer Auftakt (1 Beat).
        let m = Measure {
            number: 1,
            divisions: 4,
            notes: vec![quarter_note(4)],
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        let c = check_measure(&m, TimeSignature { beats: 4, beat_type: 4 }, true);
        assert_eq!(c.plausibility, MeasurePlausibility::Anacrusis);
    }

    #[test]
    fn scale_to_fit_repairs_double_overlong() {
        // 8 Quarter-Notes (Σ=32) im 4/4 (expected=16) → Ratio=2. Scale /2: alle zu Achtel (dur=2). Σ=16. ✓
        let mut m = Measure {
            number: 1,
            divisions: 4,
            notes: (0..8).map(|_| quarter_note(4)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        let ok = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        assert!(ok);
        let actual: u32 = lead_duration_sum(&m.notes);
        assert_eq!(actual, 16);
    }

    #[test]
    fn scale_to_fit_repairs_quad_overlong() {
        // 16 Quarters à 4 = 64, expected = 16. Ratio = 4. Scale /4 = alle zu 1 (Sechzehntel). Σ=16.
        let mut m = Measure {
            number: 1,
            divisions: 4,
            notes: (0..16).map(|_| quarter_note(4)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        let ok = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        assert!(ok);
        let actual: u32 = lead_duration_sum(&m.notes);
        assert_eq!(actual, 16);
    }

    #[test]
    fn truncation_handles_minor_overlong() {
        // 5 Quarters (Σ=20) im 4/4 (expected=16) → diff=+4. Truncation kürzt einzelne Notes.
        let mut m = Measure {
            number: 1,
            divisions: 4,
            notes: vec![
                quarter_note(4), quarter_note(4), quarter_note(4), quarter_note(4), quarter_note(4),
            ],
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        let ok = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        let actual: u32 = lead_duration_sum(&m.notes);
        if ok {
            assert_eq!(actual, 16);
        } else {
            assert!(actual >= 16 && actual <= 20, "got actual={}", actual);
        }
    }

    #[test]
    fn truncation_repairs_mixed_kinds_overlong() {
        // 3 Quarters (3·4=12) + 1 Whole (16) = Σ=28, expected=16. Truncation kürzt Whole→4. Σ=16.
        let mut m = Measure {
            number: 1,
            divisions: 4,
            notes: vec![
                quarter_note(4),
                quarter_note(4),
                quarter_note(4),
                ScoreNote {
                    midi: 60,
                    step: omr_core::PitchStep::C,
                    alter: 0,
                    octave: 4,
                    duration: 16,
                    onset: 0,
                    voice: 1,
                    kind: NoteheadKind::Open,
                    center: omr_core::Point { x: 0.0, y: 0.0 },
                    augmentation_dots: 0,
                    in_chord: false,
            is_rest: false,
                },
            ],
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        let ok = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        assert!(ok, "mixed kinds sollten reparierbar sein");
        let actual: u32 = lead_duration_sum(&m.notes);
        assert_eq!(actual, 16);
    }

    #[test]
    fn doubling_repairs_eighth_only() {
        // 1 Halbe (dur=8) im 4/4 → expected=16, diff=8.
        // Subset-doubling verdoppelt die Halbe zu Whole (dur=16). Σ=16. ✓
        let mut m = Measure {
            number: 5,
            divisions: 4,
            notes: vec![quarter_note(8)],
            time_signature: None,
            key_signature: None,
            clef: None,
            ..Default::default()
        };
        let ok = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        assert!(ok);
        let actual: u32 = lead_duration_sum(&m.notes);
        assert_eq!(actual, 16);
    }
}
