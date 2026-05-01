// Pitch-Estimation aus Notenkopf-Y und StaffSystem.
//
// Verbesserte Variante: nutze die exakte Y-Position der oberen Linie an der
// X-Position des Noteheads (nicht den Mittelwert), um schiefes Papier oder
// gekrümmte Linien zu kompensieren.

use omr_core::{Clef, KeySignature, PitchStep, StaffSystem};

#[derive(Debug, Clone, Copy)]
pub struct Pitch {
    pub midi: u8,
    pub step: PitchStep,
    pub alter: i8,
    pub octave: i8,
}

/// Bestimme die Tonhöhe an Y-Position innerhalb eines StaffSystems.
/// Nutzt X-Koordinate für linien-genaue Y-Lookup (Kompensation für gekrümmte Linien).
pub fn pitch_from_xy(
    x: f32,
    y: f32,
    staff: &StaffSystem,
    clef: Clef,
    key: KeySignature,
) -> Pitch {
    pitch_from_xy_with_ledger(x, y, staff, clef, key, None, 0)
}

/// Wie [`pitch_from_xy`], aber mit optionaler Ledger-Line-Y-Position als
/// Pitch-Calibration-Anchor. Wenn `ledger_y` gegeben + `ledger_count` >= 1,
/// wird der Pitch relativ zur echten Ledger-Line berechnet statt zur top-Line
/// extrapoliert. Verbessert Pitch-Genauigkeit für hohe/tiefe NHs (octave error).
pub fn pitch_from_xy_with_ledger(
    x: f32,
    y: f32,
    staff: &StaffSystem,
    clef: Clef,
    key: KeySignature,
    ledger_y: Option<u32>,
    ledger_count: u8,
) -> Pitch {
    if staff.lines.is_empty() {
        return Pitch { midi: 60, step: PitchStep::C, alter: 0, octave: 4 };
    }
    let xi = x.round() as u32;
    let line_top = staff.line_y_at(0, xi).unwrap_or_else(|| staff.lines[0].mean_y());
    let line_bot = staff.line_y_at(4, xi).unwrap_or_else(|| staff.lines[4].mean_y());
    let spacing = staff.line_spacing.max(1.0);

    // Wenn Ledger-Line detected: nutze sie als anchor.
    // Convention: positive half_steps = HIGHER pitch (above top-line).
    // Top-Line = pos 0, Ledger 1 above top-line = pos +2, Ledger 1 below bottom = pos -10.
    // Bottom-line ist 4 spacings unter top-line = -8 half_steps.
    let half_steps = if let Some(ly) = ledger_y {
        let n = ledger_count.max(1) as i32;
        if (ly as f32) < line_top {
            // Ledger oberhalb der Staff: position +2*n
            let ledger_pos = 2 * n;
            // dy_from_ledger > 0 wenn NH ÜBER der ledger-line
            let dy_from_ledger = ((ly as f32) - y) / (spacing * 0.5);
            ledger_pos + dy_from_ledger.round() as i32
        } else if (ly as f32) > line_bot {
            // Ledger unterhalb der Staff (bottom-line ist -8): position -8 - 2*n
            let ledger_pos = -8 - 2 * n;
            let dy_from_ledger = ((ly as f32) - y) / (spacing * 0.5);
            ledger_pos + dy_from_ledger.round() as i32
        } else {
            ((line_top - y) / (spacing * 0.5)).round() as i32
        }
    } else {
        ((line_top - y) / (spacing * 0.5)).round() as i32
    };

    let (anchor_step, anchor_octave) = match clef {
        Clef::Treble => (PitchStep::F, 5i8),
        Clef::Bass => (PitchStep::A, 3i8),
        Clef::Alto => (PitchStep::G, 4i8),
        Clef::Tenor => (PitchStep::E, 4i8),
    };

    let steps_seq = [
        PitchStep::C, PitchStep::D, PitchStep::E,
        PitchStep::F, PitchStep::G, PitchStep::A, PitchStep::B,
    ];
    let anchor_idx = steps_seq.iter().position(|&s| s == anchor_step).unwrap() as i32;
    let target_idx_total = anchor_idx + 7 * anchor_octave as i32 + half_steps;
    let octave = target_idx_total.div_euclid(7) as i8;
    let step_idx = target_idx_total.rem_euclid(7) as usize;
    let step = steps_seq[step_idx];

    let alter = key_alter_for_step(step, key);

    let midi = step_octave_to_midi(step, alter, octave);

    Pitch { midi, step, alter, octave }
}

/// Backwards-compat Alias (X = bbox.cx war früher implizit).
pub fn pitch_from_y(y: f32, staff: &StaffSystem, clef: Clef, key: KeySignature) -> Pitch {
    let x = (staff.lines.first().map(|l| l.y_per_x.len() as f32 / 2.0).unwrap_or(0.0)).max(0.0);
    pitch_from_xy(x, y, staff, clef, key)
}

fn key_alter_for_step(step: PitchStep, key: KeySignature) -> i8 {
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

    #[test]
    fn key_g_major_raises_f() {
        let s = dummy_staff(20.0, 10.0);
        let key = KeySignature { fifths: 1 }; // G-Dur (1#)
        // F5 in G-Dur ist F# (alter=+1)
        let p = pitch_from_y(20.0, &s, Clef::Treble, key);
        assert_eq!(p.step, PitchStep::F);
        assert_eq!(p.alter, 1);
    }

    #[test]
    fn xy_uses_line_at_x() {
        let mut s = dummy_staff(20.0, 10.0);
        // Linie 0 hat y = 20 überall, aber an x=50 verändern wir auf y=25.
        s.lines[0].y_per_x[50] = 25;
        let p = pitch_from_xy(50.0, 25.0, &s, Clef::Treble, KeySignature::default());
        assert_eq!(p.step, PitchStep::F);
        assert_eq!(p.octave, 5);
    }
}
