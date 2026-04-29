// Pitch-Estimation aus Notenkopf-Y und StaffSystem.
//
// Modell: jede halbe Linien-Spacing ist 1 Notenstufe (steps in C, D, E…).
// Ausgehend vom Schlüssel und Vorzeichen.

use omr_core::{Clef, KeySignature, PitchStep, StaffSystem};

#[derive(Debug, Clone, Copy)]
pub struct Pitch {
    pub midi: u8,
    pub step: PitchStep,
    pub alter: i8,
    pub octave: i8,
}

/// Bestimme die Tonhöhe an Y-Position innerhalb eines StaffSystems.
pub fn pitch_from_y(y: f32, staff: &StaffSystem, clef: Clef, key: KeySignature) -> Pitch {
    if staff.lines.is_empty() {
        return Pitch { midi: 60, step: PitchStep::C, alter: 0, octave: 4 };
    }
    let line_top = staff.lines.first().unwrap().mean_y();
    let spacing = staff.line_spacing.max(1.0);

    // Position relativ zur obersten Linie, in halben Spacings (0=top line, 1=top space, ...).
    let half_steps = ((line_top - y) / (spacing * 0.5)).round() as i32;

    // Ankerpunkt der obersten Linie je nach Schlüssel
    let (anchor_step, anchor_octave) = match clef {
        // Treble: top line F5
        Clef::Treble => (PitchStep::F, 5i8),
        // Bass: top line A3
        Clef::Bass => (PitchStep::A, 3i8),
        // Alto: top line G4 (Bratsche)
        Clef::Alto => (PitchStep::G, 4i8),
        // Tenor: top line E4 (Posaune Tenor)
        Clef::Tenor => (PitchStep::E, 4i8),
    };

    // Schritt in C-D-E-F-G-A-B (diatonische Skala).
    let steps_seq = [
        PitchStep::C, PitchStep::D, PitchStep::E,
        PitchStep::F, PitchStep::G, PitchStep::A, PitchStep::B,
    ];
    let anchor_idx = steps_seq.iter().position(|&s| s == anchor_step).unwrap() as i32;
    // Tonhöhe steigt nach oben → +1 half_step = +1 step im diatonischen Sinn.
    let target_idx_total = anchor_idx + 7 * anchor_octave as i32 + half_steps;
    let octave = target_idx_total.div_euclid(7) as i8;
    let step_idx = target_idx_total.rem_euclid(7) as usize;
    let step = steps_seq[step_idx];

    // Vorzeichen aus key signature applicieren.
    let alter = key_alter_for_step(step, key);

    let midi = step_octave_to_midi(step, alter, octave);

    Pitch { midi, step, alter, octave }
}

fn key_alter_for_step(step: PitchStep, key: KeySignature) -> i8 {
    // Ordnung der Vorzeichen: # → F C G D A E B
    //                      b → B E A D G C F
    let sharps_order = [PitchStep::F, PitchStep::C, PitchStep::G, PitchStep::D,
                        PitchStep::A, PitchStep::E, PitchStep::B];
    let flats_order  = [PitchStep::B, PitchStep::E, PitchStep::A, PitchStep::D,
                        PitchStep::G, PitchStep::C, PitchStep::F];
    if key.fifths > 0 {
        let n = key.fifths.min(7) as usize;
        if sharps_order[..n].contains(&step) { return 1; }
    } else if key.fifths < 0 {
        let n = (-key.fifths).min(7) as usize;
        if flats_order[..n].contains(&step) { return -1; }
    }
    0
}

fn step_octave_to_midi(step: PitchStep, alter: i8, octave: i8) -> u8 {
    let base_semis = match step {
        PitchStep::C => 0,
        PitchStep::D => 2,
        PitchStep::E => 4,
        PitchStep::F => 5,
        PitchStep::G => 7,
        PitchStep::A => 9,
        PitchStep::B => 11,
    };
    let midi = (octave as i32 + 1) * 12 + base_semis as i32 + alter as i32;
    midi.clamp(0, 127) as u8
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::StaffLine;

    fn dummy_staff(top_y: f32, spacing: f32) -> StaffSystem {
        StaffSystem {
            lines: (0..5)
                .map(|i| StaffLine {
                    y_per_x: vec![(top_y + i as f32 * spacing) as u32; 100],
                })
                .collect(),
            line_spacing: spacing,
            line_thickness: 1.0,
        }
    }

    #[test]
    fn treble_top_line_is_f5() {
        let s = dummy_staff(20.0, 10.0);
        let p = pitch_from_y(20.0, &s, Clef::Treble, KeySignature::default());
        assert_eq!(p.step, PitchStep::F);
        assert_eq!(p.octave, 5);
    }

    #[test]
    fn treble_middle_line_is_b4() {
        let s = dummy_staff(20.0, 10.0);
        let p = pitch_from_y(40.0, &s, Clef::Treble, KeySignature::default());
        assert_eq!(p.step, PitchStep::B);
        assert_eq!(p.octave, 4);
    }

    #[test]
    fn bass_top_line_is_a3() {
        let s = dummy_staff(20.0, 10.0);
        let p = pitch_from_y(20.0, &s, Clef::Bass, KeySignature::default());
        assert_eq!(p.step, PitchStep::A);
        assert_eq!(p.octave, 3);
    }
}
