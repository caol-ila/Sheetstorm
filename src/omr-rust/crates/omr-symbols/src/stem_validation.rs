//! Stem-Direction-Validation für Pitch-Sanity-Check.
//!
//! Konvention der Notenschrift:
//! - Notenkopf ÜBER der Mittellinie → Stem geht NACH UNTEN
//! - Notenkopf UNTER der Mittellinie → Stem geht NACH OBEN
//! - Auf der Mittellinie: kontextabhängig (Beam-Group, etc.)
//!
//! Wenn die Pipeline einen Stem-Direction-Mismatch hat (z.B. NH erkannt als
//! "B5 mit Stem-up" obwohl das B5 hoch über der Linie liegt → Stem sollte
//! down sein), ist die Pitch-Erkennung wahrscheinlich um eine Oktave falsch.
//!
//! Das Modul liefert für jeden Notehead+Stem-Pair einen Validity-Score
//! und einen Korrektur-Vorschlag.
//!
//! ⚠️ Ausnahmen: Multi-Voice (Klavier hat oft beide Stems am Akkord),
//! Kreuzstimme (Tenor stem-up trotz hoher Position), bewusste Stem-Choice
//! des Komponisten. Wir geben daher nur einen Hint, kein hartes Reject.

use omr_core::{Notehead, ScoreNote, StaffSystem, Stem};

/// Validierungs-Resultat für eine einzelne Note.
#[derive(Debug, Clone, Copy)]
pub struct StemDirectionValidation {
    /// Index der NH/ScoreNote im Input-Array.
    pub note_idx: usize,
    /// True wenn Stem-Direction zur Pitch-Position passt.
    pub valid: bool,
    /// Wenn invalid: Vorschlag für korrekte Octave (z.B. -1 = octave runter).
    pub octave_correction: i8,
}

/// Prüft pro Notehead+Stem-Pair ob die Stem-Direction zur Y-Position passt.
///
/// Inputs:
///   - `noteheads`: alle NHs einer Page
///   - `stems`: alle detektierten Stems
///   - `score_notes`: Pipeline-output Notes mit pitch
///   - `systems`: StaffSystems für die middle_y-Bestimmung
///
/// Returns: Validierungs-Resultate pro NH die einen Stem haben.
pub fn validate_stem_directions(
    noteheads: &[Notehead],
    stems: &[Stem],
    systems: &[StaffSystem],
) -> Vec<StemDirectionValidation> {
    let mut results = Vec::new();

    for stem in stems {
        let nh_idx = match stem.notehead_idx { Some(i) => i, None => continue };
        let nh = match noteheads.get(nh_idx) { Some(n) => n, None => continue };
        let staff = match systems.get(nh.staff_idx) { Some(s) => s, None => continue };

        let middle_y = staff.middle_y();
        let nh_y = nh.center.y;

        // Stem-Direction: stem geht von NH-Center weg.
        // Wenn nh_y > stem.y_top: NH ist UNTEN, Stem geht nach OBEN (stem-up).
        // Wenn nh_y < stem.y_bot: NH ist OBEN, Stem geht nach UNTEN (stem-down).
        let stem_up = nh_y > stem.y_top as f32;
        let stem_down = nh_y < stem.y_bot as f32;
        if !stem_up && !stem_down { continue; }
        let actual_dir_up = stem_up;

        // Erwartet:
        //  - NH unter middle (nh_y > middle_y): expected stem-up
        //  - NH über middle (nh_y < middle_y): expected stem-down
        let expected_dir_up = nh_y > middle_y;

        // Nur eindeutige Mismatches melden — innerhalb 0.5 spacing der Mitte
        // ist die Direction freigestellt (Beam-Gruppen, etc.).
        let dist_from_middle = (nh_y - middle_y).abs();
        if dist_from_middle < staff.line_spacing * 0.5 {
            results.push(StemDirectionValidation {
                note_idx: nh_idx,
                valid: true,
                octave_correction: 0,
            });
            continue;
        }

        let valid = actual_dir_up == expected_dir_up;
        // Octave-Correction-Hint:
        // - actual_up + nh_y far above middle (= short stem) → erkannt als hoch, sollte tiefer (octave -1)
        // - actual_down + nh_y far below middle → erkannt als tief, sollte höher (octave +1)
        // Aber in der Praxis: zur Sicherheit nur als Hint, octave_correction 0
        // wenn unklar.
        let octave_correction = if !valid {
            if actual_dir_up && !expected_dir_up { 1 } // stem-up bei "high" NH → vielleicht eigentlich tiefer?
            else if !actual_dir_up && expected_dir_up { -1 }
            else { 0 }
        } else { 0 };

        results.push(StemDirectionValidation {
            note_idx: nh_idx,
            valid,
            octave_correction,
        });
    }

    results
}

/// Counts how many NHs have stem-direction-mismatch — useful as a
/// "confidence score" for the page's overall pitch-detection-quality.
pub fn stem_direction_mismatch_count(validations: &[StemDirectionValidation]) -> usize {
    validations.iter().filter(|v| !v.valid).count()
}

/// Anwenden der octave-correction auf ScoreNotes (pro Index).
/// Modifiziert NUR notes mit valid=false UND octave_correction != 0.
/// Berechnet midi neu basierend auf step + neuer octave + alter.
pub fn apply_octave_corrections(
    score_notes: &mut [ScoreNote],
    nh_to_score_idx: &[Option<usize>],
    validations: &[StemDirectionValidation],
) {
    for v in validations {
        if v.valid || v.octave_correction == 0 { continue; }
        let score_idx = match nh_to_score_idx.get(v.note_idx).copied().flatten() {
            Some(i) => i, None => continue,
        };
        let n = match score_notes.get_mut(score_idx) { Some(n) => n, None => continue };
        if n.is_rest { continue; }
        let new_oct = (n.octave as i32 + v.octave_correction as i32).clamp(0, 9) as i8;
        n.octave = new_oct;
        // MIDI neu berechnen
        let base_semis: i32 = match n.step {
            omr_core::PitchStep::C => 0,
            omr_core::PitchStep::D => 2,
            omr_core::PitchStep::E => 4,
            omr_core::PitchStep::F => 5,
            omr_core::PitchStep::G => 7,
            omr_core::PitchStep::A => 9,
            omr_core::PitchStep::B => 11,
        };
        let midi = (new_oct as i32 + 1) * 12 + base_semis + n.alter as i32;
        n.midi = midi.clamp(0, 127) as u8;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{NoteheadKind, PitchStep, Point, Rect, StaffLine};

    fn mk_system(top_y: u32, spacing: u32) -> StaffSystem {
        let mut lines = Vec::new();
        for i in 0..5 {
            let y = top_y + i * spacing;
            let mut y_per_x = vec![0u32; 1000];
            for x in 50..950 { y_per_x[x] = y; }
            lines.push(StaffLine { y_per_x });
        }
        StaffSystem { lines, line_spacing: spacing as f32, line_thickness: 2.0 }
    }
    fn mk_nh(x: f32, y: f32) -> Notehead {
        Notehead {
            bbox: Rect { x: (x as u32).saturating_sub(8), y: (y as u32).saturating_sub(8), w: 16, h: 16 },
            center: Point { x, y },
            confidence: 0.9, kind: NoteheadKind::Filled, staff_idx: 0,
        }
    }
    fn mk_stem(x: u32, y_top: u32, y_bot: u32, nh_idx: usize) -> Stem {
        Stem { x, y_top, y_bot, notehead_idx: Some(nh_idx) }
    }

    #[test]
    fn valid_stem_up_for_low_note() {
        // System: top_y=100, spacing=18 → middle_y=136 (third line)
        // NH bei y=170 (UNTER middle), Stem geht von y_top=130 nach y_bot=170 (UP from NH)
        let system = mk_system(100, 18);
        let nhs = vec![mk_nh(200.0, 170.0)];
        let stems = vec![mk_stem(208, 130, 170, 0)];
        let v = validate_stem_directions(&nhs, &stems, &[system]);
        assert_eq!(v.len(), 1);
        assert!(v[0].valid, "stem-up bei tiefer Note ist korrekt");
    }

    #[test]
    fn invalid_stem_up_for_high_note_above_middle() {
        // NH bei y=105 (deutlich ÜBER middle 136), aber Stem-up suggested
        let system = mk_system(100, 18);
        let nhs = vec![mk_nh(200.0, 105.0)];
        // Stem geht von y_top=80 (ÜBER NH) → nh_y > stem.y_top? 105 > 80 = true → stem-up
        let stems = vec![mk_stem(208, 80, 105, 0)];
        let v = validate_stem_directions(&nhs, &stems, &[system]);
        assert_eq!(v.len(), 1);
        assert!(!v[0].valid, "stem-up bei hoher Note sollte als invalid markiert sein");
    }

    #[test]
    fn neutral_zone_within_half_spacing_always_valid() {
        let system = mk_system(100, 18);
        // NH genau auf der Mittellinie y=136
        let nhs = vec![mk_nh(200.0, 136.0)];
        let stems = vec![mk_stem(208, 100, 136, 0)];
        let v = validate_stem_directions(&nhs, &stems, &[system]);
        assert!(v[0].valid);
    }

    #[test]
    fn apply_correction_only_to_invalid() {
        let mut notes = vec![
            ScoreNote { midi: 72, step: PitchStep::C, alter: 0, octave: 5, duration: 4,
                        onset: 0, voice: 1, kind: NoteheadKind::Filled,
                        center: Point { x: 200.0, y: 105.0 }, augmentation_dots: 0,
                        in_chord: false, is_rest: false },
        ];
        let validations = vec![
            StemDirectionValidation { note_idx: 0, valid: false, octave_correction: -1 },
        ];
        let nh_to_score = vec![Some(0)];
        apply_octave_corrections(&mut notes, &nh_to_score, &validations);
        assert_eq!(notes[0].octave, 4);
        assert_eq!(notes[0].midi, 60); // C4 = 60
    }
}
