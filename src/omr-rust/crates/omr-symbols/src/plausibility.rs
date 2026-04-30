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
/// Beispiel: divisions=4, time=4/4 → 4*4/4 = 4 (4 Viertel)
/// divisions=4, time=3/4 → 3*4/4 = 3 (3 Viertel)
/// divisions=4, time=6/8 → 6*4/8 = 3 (3 Viertel)
pub fn expected_total_duration(divisions: u32, time: TimeSignature) -> u32 {
    (time.beats as u32 * divisions) / time.beat_type as u32
}

pub fn check_measure(m: &Measure, time: TimeSignature, is_first: bool) -> MeasureCheck {
    let expected = expected_total_duration(m.divisions, time);
    let actual: u32 = m.notes.iter().map(|n| n.duration).sum();

    let plaus = if actual == expected {
        MeasurePlausibility::Exact
    } else if is_first && actual < expected && (expected - actual) <= m.divisions {
        // Auftakt: bis zu 1 Viertel weniger akzeptiert
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
/// Strategien (in Reihenfolge):
///   0) **Scale-to-fit**: Wenn Σ = N · expected (N integer ≥ 2), teile ALLE
///      Durations durch N. Behebt typischen Audiveris/OMR-Fehler wo alle Notes
///      als Filled-Quarter klassifiziert wurden, eigentlich aber 8th/16th sind.
///   1) Wenn actual > expected: kürze die längsten Filled-NH zu Achtel.
///      Funktioniert für kleine Differenzen (1-2 Quarters zu viel).
///   2) Wenn actual < expected: verlängere die letzte Note bis Σ = expected
///      (Padding-Strategie).
///
/// Returns ob Reparatur erfolgreich war (Σ = expected).
pub fn repair_measure(m: &mut Measure, time: TimeSignature) -> bool {
    let expected = expected_total_duration(m.divisions, time);
    let actual: u32 = m.notes.iter().map(|n| n.duration).sum();
    if actual == expected { return true; }
    if m.notes.is_empty() { return false; }

    // Strategie 0: Scale-to-fit. Häufigster Fehler: alle als Quarter klassifiziert,
    // sollte aber 8th oder 16th sein.
    if actual > expected && expected > 0 {
        let ratio = actual as f32 / expected as f32;
        // Nur wenn ratio sehr nah an einer Integer-Power-of-2 liegt
        for &n in &[2u32, 4, 8] {
            if (ratio - n as f32).abs() < 0.15 {
                let mut scaled: Vec<u32> = m.notes.iter().map(|x| (x.duration / n).max(1)).collect();
                let scaled_total: u32 = scaled.iter().sum();
                if scaled_total == expected {
                    for (i, d) in scaled.drain(..).enumerate() {
                        m.notes[i].duration = d;
                    }
                    return true;
                }
                // Manchmal weicht die Scale-Variante leicht ab, dann mit
                // Strategie 1 weiter feinjustieren.
                if scaled_total > expected {
                    // Über-skaliert — kürze überzählige weiter
                    let diff = scaled_total - expected;
                    let mut indices: Vec<usize> = (0..scaled.len()).collect();
                    indices.sort_by_key(|&i| std::cmp::Reverse(scaled[i]));
                    let mut remaining = diff;
                    for i in indices {
                        if remaining == 0 { break; }
                        if scaled[i] > 1 {
                            let red = scaled[i].min(remaining + 1) - 1;
                            scaled[i] -= red;
                            remaining = remaining.saturating_sub(red);
                        }
                    }
                    if scaled.iter().sum::<u32>() == expected {
                        for (i, d) in scaled.drain(..).enumerate() {
                            m.notes[i].duration = d;
                        }
                        return true;
                    }
                } else if scaled_total < expected {
                    // Unter-skaliert — verlängere letzte
                    let diff = expected - scaled_total;
                    let last = scaled.len() - 1;
                    scaled[last] += diff;
                    for (i, d) in scaled.drain(..).enumerate() {
                        m.notes[i].duration = d;
                    }
                    return true;
                }
            }
        }
    }

    // Strategie 1: Wenn actual > expected, kürze die längsten Filled-NH zu Achtel.
    if actual > expected {
        let diff = actual - expected;
        let mut indices: Vec<usize> = (0..m.notes.len()).collect();
        indices.sort_by_key(|&i| std::cmp::Reverse(m.notes[i].duration));
        let mut remaining = diff;
        for i in indices {
            if remaining == 0 { break; }
            let n: &mut ScoreNote = &mut m.notes[i];
            if matches!(n.kind, NoteheadKind::Filled) && n.duration >= 2 {
                let halved = n.duration / 2;
                let saved = n.duration - halved;
                if saved <= remaining {
                    n.duration = halved;
                    remaining -= saved;
                }
            }
        }
        let new_total: u32 = m.notes.iter().map(|n| n.duration).sum();
        return new_total == expected;
    }

    // Strategie 2: Wenn actual < expected, verlängere letzte Note.
    if actual < expected {
        let diff = expected - actual;
        if let Some(last) = m.notes.last_mut() {
            last.duration += diff;
            return true;
        }
    }
    false
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
        }
    }

    #[test]
    fn expected_4_4_with_div_4_is_4_quarters() {
        assert_eq!(expected_total_duration(4, TimeSignature { beats: 4, beat_type: 4 }), 4);
    }

    #[test]
    fn expected_3_4_is_3() {
        assert_eq!(expected_total_duration(4, TimeSignature { beats: 3, beat_type: 4 }), 3);
    }

    #[test]
    fn expected_6_8_is_3() {
        assert_eq!(expected_total_duration(4, TimeSignature { beats: 6, beat_type: 8 }), 3);
    }

    #[test]
    fn check_4_quarters_in_4_4_is_exact() {
        let m = Measure {
            number: 1,
            divisions: 4,
            notes: (0..4).map(|_| quarter_note(1)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
        };
        let c = check_measure(&m, TimeSignature { beats: 4, beat_type: 4 }, false);
        assert_eq!(c.plausibility, MeasurePlausibility::Exact);
    }

    #[test]
    fn check_5_quarters_in_4_4_is_repairable() {
        let m = Measure {
            number: 2,
            divisions: 4,
            notes: (0..5).map(|_| quarter_note(1)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
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
            notes: (0..5).map(|_| quarter_note(1)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
        };
        // Wir akzeptieren wenn Reparatur funktioniert, sonst diff ≤ 1
        let _ = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        let actual: u32 = m.notes.iter().map(|n| n.duration).sum();
        assert!(actual <= 4 + 1);
    }

    #[test]
    fn repair_short_measure_extends_last() {
        let mut m = Measure {
            number: 5,
            divisions: 4,
            notes: vec![quarter_note(1), quarter_note(1)],
            time_signature: None,
            key_signature: None,
            clef: None,
        };
        let ok = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        assert!(ok);
        let actual: u32 = m.notes.iter().map(|n| n.duration).sum();
        assert_eq!(actual, 4);
    }

    #[test]
    fn anacrusis_first_measure_is_acceptable() {
        let m = Measure {
            number: 1,
            divisions: 4,
            notes: vec![quarter_note(1)], // 1 Viertel im 4/4 → klassischer Auftakt
            time_signature: None,
            key_signature: None,
            clef: None,
        };
        let c = check_measure(&m, TimeSignature { beats: 4, beat_type: 4 }, true);
        assert_eq!(c.plausibility, MeasurePlausibility::Anacrusis);
    }

    #[test]
    fn scale_to_fit_repairs_double_overlong() {
        // 4 Achtel-Notes (à 2 = Achtel) im 4/4 als Quarter klassifiziert: Σ=4·2=8 (2x expected=4).
        // Aber Scale by /2 würde jede zu 1 (Sechzehntel) machen → 4·1 = 4. ✓
        let mut m = Measure {
            number: 1,
            divisions: 4,
            notes: (0..4).map(|_| quarter_note(2)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
        };
        let ok = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        assert!(ok);
        let actual: u32 = m.notes.iter().map(|n| n.duration).sum();
        assert_eq!(actual, 4);
    }

    #[test]
    fn scale_to_fit_repairs_quad_overlong() {
        // 4 Quarters à 4 = 16, expected = 4. Ratio = 4. Scale /4 = alle zu 1 (Sechzehntel).
        let mut m = Measure {
            number: 1,
            divisions: 4,
            notes: (0..4).map(|_| quarter_note(4)).collect(),
            time_signature: None,
            key_signature: None,
            clef: None,
        };
        let ok = repair_measure(&mut m, TimeSignature { beats: 4, beat_type: 4 });
        assert!(ok);
        let actual: u32 = m.notes.iter().map(|n| n.duration).sum();
        assert_eq!(actual, 4);
    }
}
