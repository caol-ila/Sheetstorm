//! Beam-Slope-Validation für Pitch-Cross-Check.
//!
//! Wenn eine Beam-Gruppe NHs auf aufsteigender Tonleiter hat, geht der
//! Beam diagonal nach OBEN. Bei absteigender Tonleiter geht der Beam nach
//! UNTEN. Eine HORIZONTALE Beam zeigt gleichbleibende Pitches an.
//!
//! Die Pipeline kann das als Cross-Check nutzen:
//!   - Detected NH-Pitches haben mismatched-Slope zum Beam → wahrscheinlicher
//!     Pitch-Fehler (vermutlich Octave-Versatz oder interner Sortier-Bug)
//!
//! Strategie:
//! 1. Pro Beam: alle NHs deren Stem mit dem Beam verbunden ist sammeln
//! 2. Beam-Slope berechnen: (y_right - y_left) / (x_right - x_left)
//! 3. NH-Pitch-Slope: (midi_last - midi_first) / count → erwarteter Beam-Slope
//! 4. Mismatch erkennen wenn Vorzeichen entgegengesetzt
//!
//! Output: Liste von "verdaechtigen" NHs mit suggested-octave-correction

use omr_core::{Notehead, ScoreNote};
use crate::beams::Beam;

/// Validierungs-Resultat pro NH die in einer Beam-Gruppe ist.
#[derive(Debug, Clone, Copy)]
pub struct BeamPitchValidation {
    /// Index der NH im Input-Array.
    pub note_idx: usize,
    /// True wenn Pitch-Order zur Beam-Slope passt.
    pub valid: bool,
    /// Index des Beams in der dieser NH ist.
    pub beam_idx: usize,
}

/// Prüft pro Beam-Gruppe ob die NH-Pitches der Beam-Slope folgen.
///
/// Inputs:
///   - `beams`: detektierte Beam-Bboxes (Pixel-Koordinaten)
///   - `noteheads`: alle NHs einer Page mit zugewiesenen MIDI-Werten
///   - `score_notes`: Pipeline-output ScoreNotes mit pitch
///
/// Returns: Validierungs-Resultate (nur für NHs die auf einem Beam liegen).
pub fn validate_beam_pitches(
    beams: &[Beam],
    noteheads: &[Notehead],
    score_notes: &[ScoreNote],
) -> Vec<BeamPitchValidation> {
    let mut results = Vec::new();

    for (beam_idx, beam) in beams.iter().enumerate() {
        // Sammle NHs die UNTER dem Beam liegen (stem-up, NH ist unten)
        // oder ÜBER dem Beam liegen (stem-down, NH ist oben).
        let beam_x0 = beam.x_start as f32;
        let beam_x1 = beam.x_end as f32;
        let beam_y_top = beam.y_top as f32;
        let beam_y_bot = beam.y_bot as f32;

        let mut beam_nhs: Vec<(usize, f32)> = Vec::new(); // (idx, x)
        for (i, nh) in noteheads.iter().enumerate() {
            let cx = nh.center.x;
            let cy = nh.center.y;
            // X-Range mit kleinem Tol-Abstand
            let in_x_range = cx >= beam_x0 - 4.0 && cx <= beam_x1 + 4.0;
            if !in_x_range { continue; }
            // Y muss unter ODER über dem Beam sein (NH ist nicht ON dem Beam)
            let below_beam = cy > beam_y_bot + 8.0;
            let above_beam = cy < beam_y_top - 8.0;
            if below_beam || above_beam {
                beam_nhs.push((i, cx));
            }
        }
        if beam_nhs.len() < 2 { continue; }
        beam_nhs.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal));

        // Beam-Slope berechnen
        let beam_w_f = (beam.x_end as f32 - beam.x_start as f32).max(1.0);
        let beam_slope = 0.0_f32; // Beams sind achsenaligned in unserer Datenstruktur

        // Da Beam.bbox nur achsenaligned ist, nehmen wir die Annahme dass die slope
        // 0 ist (perfekt-horizontale Beams). Stattdessen nutzen wir die Y-Range
        // als Indikator.

        // NH-Pitch-Slope: midi vom ersten zur letzten NH
        let first_idx = beam_nhs[0].0;
        let last_idx = beam_nhs.last().unwrap().0;
        let first_score = score_notes.iter().find(|n| {
            (n.center.x - noteheads[first_idx].center.x).abs() < 4.0 &&
            (n.center.y - noteheads[first_idx].center.y).abs() < 4.0
        });
        let last_score = score_notes.iter().find(|n| {
            (n.center.x - noteheads[last_idx].center.x).abs() < 4.0 &&
            (n.center.y - noteheads[last_idx].center.y).abs() < 4.0
        });
        let (first_midi, last_midi) = match (first_score, last_score) {
            (Some(a), Some(b)) => (a.midi as i32, b.midi as i32),
            _ => continue,
        };
        let pitch_slope: i32 = last_midi - first_midi;

        // Y-Slope der NHs: erste NH y-coord vs letzte NH y-coord
        let first_y = noteheads[first_idx].center.y;
        let last_y = noteheads[last_idx].center.y;
        let y_slope = last_y - first_y;

        // Konsistenz-Check: y_slope und pitch_slope sollten ENTGEGENGESETZTES
        // Vorzeichen haben (höhere Pitch = niedriges y, da Y wächst nach unten).
        // NH-Y nimmt ab (negativer y_slope) wenn pitch steigt.
        let y_sign = y_slope.signum() as i32;
        let p_sign = -pitch_slope.signum(); // negiert weil hoehere pitch = niedriger y
        let consistent = y_sign == p_sign || (pitch_slope.abs() < 2);

        // Markiere alle NHs in dieser Beam-Gruppe mit consistency-Flag
        for (idx, _) in &beam_nhs {
            results.push(BeamPitchValidation {
                note_idx: *idx,
                valid: consistent,
                beam_idx,
            });
        }
        let _ = beam_slope; // unused, future expansion
    }
    results
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{NoteheadKind, PitchStep, Point, Rect};
    use crate::beams::Beam;

    fn mk_nh(x: f32, y: f32) -> Notehead {
        Notehead {
            bbox: Rect { x: (x as u32).saturating_sub(8), y: (y as u32).saturating_sub(8), w: 16, h: 16 },
            center: Point { x, y },
            confidence: 0.9, kind: NoteheadKind::Filled, staff_idx: 0,
        }
    }
    fn mk_score(x: f32, y: f32, midi: u8) -> ScoreNote {
        ScoreNote {
            midi, step: PitchStep::C, alter: 0, octave: (midi as i8 / 12) - 1,
            duration: 2, onset: 0, voice: 1, kind: NoteheadKind::Filled,
            center: Point { x, y }, augmentation_dots: 0,
            in_chord: false, is_rest: false,
        }
    }
    fn mk_beam(x: u32, y: u32, w: u32, h: u32) -> Beam {
        Beam {
            x_start: x,
            x_end: x + w,
            y_top: y,
            y_bot: y + h,
        }
    }

    #[test]
    fn ascending_pitch_with_correct_y_slope_is_valid() {
        // Aufsteigende Pitches: midi 60→62→64
        // Y-Werte: 200→195→190 (höhere Pitch = niedriger Y) → consistent
        let beam = mk_beam(100, 100, 100, 4); // beam at (100..200, 100..104)
        let nhs = vec![
            mk_nh(110.0, 200.0),
            mk_nh(150.0, 195.0),
            mk_nh(190.0, 190.0),
        ];
        let scores = vec![
            mk_score(110.0, 200.0, 60),
            mk_score(150.0, 195.0, 62),
            mk_score(190.0, 190.0, 64),
        ];
        let v = validate_beam_pitches(&[beam], &nhs, &scores);
        assert_eq!(v.len(), 3);
        assert!(v.iter().all(|val| val.valid));
    }

    #[test]
    fn ascending_pitch_with_wrong_y_slope_is_invalid() {
        // Aufsteigende Pitches: 60→64
        // Y-Werte: 190→200 (steigt mit Pitch — wäre falsch) → inconsistent
        let beam = mk_beam(100, 100, 100, 4);
        let nhs = vec![
            mk_nh(110.0, 190.0),
            mk_nh(190.0, 200.0),
        ];
        let scores = vec![
            mk_score(110.0, 190.0, 60),
            mk_score(190.0, 200.0, 64),
        ];
        let v = validate_beam_pitches(&[beam], &nhs, &scores);
        // Mind. 1 Validation invalid
        assert_eq!(v.len(), 2);
        assert!(v.iter().any(|val| !val.valid));
    }
}
