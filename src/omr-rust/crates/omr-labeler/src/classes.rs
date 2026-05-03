//! Klassen-Hierarchie fuer das Labeling-System.
//!
//! Dieses Modul kennt die bekannten Klassen (Single Symbols + Logical Groups)
//! und gibt sie strukturiert an die UI weiter. Es kommt mit dem Output von
//! `tools/training/generate_synthetic_patterns.py` ueberein.
//!
//! Hierarchie:
//! - **Level "Group"** (Top-Level, was meistens gelabelt wird):
//!   `single_note`, `beamed_group_2_eighths`, `chord`, …
//! - **Level "Atom"** (Drill-Down nach `[d]`-Hotkey):
//!   `notehead_filled`, `stem_up`, `beam_1`, …

use serde::{Deserialize, Serialize};

/// Eine Klasse mit Display-Name + Klassen-ID + Hotkey-Suggestion.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClassEntry {
    /// Stable klassen-ID (entspricht synthetic_corpus_v1 Pfad ohne Praefix).
    pub id: String,
    /// User-faehiger Name fuer die UI ("zwei Achtel mit Balken").
    pub display_name: String,
    /// Welche Ebene gehoert die Klasse zu.
    pub level: ClassLevel,
    /// Optionale Sub-Klassen (Drill-Down).
    pub atoms: Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Hash)]
#[serde(rename_all = "lowercase")]
pub enum ClassLevel {
    /// Single Symbol (atomare Klasse): notehead_filled, stem_up, beam_1, ...
    Atom,
    /// Logische Gruppe: beamed_group_4_sixteenths, chord, tied_phrase, ...
    Group,
    /// Phrase-Pattern (selten, nur fuer fortgeschrittenes Tagging): cadence, marcia, …
    Phrase,
}

/// Liefert die komplette Klassen-Hierarchie. Wird in der Frontend-API
/// als `/api/classes` ausgeliefert.
pub fn all_classes() -> Vec<ClassEntry> {
    let mut out = Vec::new();

    // ── Atome — was im "Drill-Down" einzeln klassifizierbar ist ─────────
    for (id, name) in [
        ("atom/notehead_filled", "Notenkopf gefuellt (Viertel/8tel/16tel/...)"),
        ("atom/notehead_open", "Notenkopf offen (Halbe)"),
        ("atom/notehead_whole", "Ganze Note"),
        ("atom/notehead_x", "X-Notenkopf (Schlagzeug)"),
        ("atom/notehead_diamond", "Rauten-Notenkopf"),
        ("atom/stem_up", "Stem nach oben"),
        ("atom/stem_down", "Stem nach unten"),
        ("atom/beam_1", "Balken (Achtel-Verbindung, 1 Linie)"),
        ("atom/beam_2", "Balken (Sechzehntel, 2 Linien)"),
        ("atom/beam_3", "Balken (32stel, 3 Linien)"),
        ("atom/flag_eighth_up", "Faehnchen Achtel (Stem hoch)"),
        ("atom/flag_eighth_down", "Faehnchen Achtel (Stem runter)"),
        ("atom/flag_sixteenth_up", "Faehnchen 16tel (Stem hoch)"),
        ("atom/flag_sixteenth_down", "Faehnchen 16tel (Stem runter)"),
        ("atom/aug_dot_one", "Punktierung (1 Punkt)"),
        ("atom/aug_dot_two", "Doppelpunktierung"),
        ("atom/accidental_sharp", "Vorzeichen ♯ Kreuz"),
        ("atom/accidental_flat", "Vorzeichen ♭ Be"),
        ("atom/accidental_natural", "Aufloesungszeichen ♮"),
        ("atom/accidental_double_sharp", "Doppelkreuz 𝄪"),
        ("atom/accidental_double_flat", "Doppel-Be 𝄫"),
        ("atom/rest_whole", "Ganze Pause"),
        ("atom/rest_half", "Halbe Pause"),
        ("atom/rest_quarter", "Viertelpause"),
        ("atom/rest_eighth", "Achtelpause"),
        ("atom/rest_sixteenth", "Sechzehntelpause"),
        ("atom/clef_treble", "Violinschluessel"),
        ("atom/clef_bass", "Bassschluessel"),
        ("atom/clef_alto", "Altschluessel"),
        ("atom/clef_tenor", "Tenorschluessel"),
        ("atom/clef_percussion", "Percussion-Schluessel"),
        ("atom/bar_single", "Taktstrich"),
        ("atom/bar_double", "Doppelstrich"),
        ("atom/bar_final", "Schlussstrich"),
        ("atom/bar_repeat_start", "Wiederholungsanfang ‖:"),
        ("atom/bar_repeat_end", "Wiederholungsende :‖"),
        ("atom/articulation_staccato", "Staccato"),
        ("atom/articulation_accent", "Akzent"),
        ("atom/articulation_tenuto", "Tenuto"),
        ("atom/articulation_marcato", "Marcato"),
        ("atom/articulation_fermata", "Fermate"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Atom,
            atoms: Vec::new(),
        });
    }

    // ── Gruppen — primaere Labeling-Ebene ────────────────────────────────
    for (id, name, atoms) in [
        ("group/single_note_eighth", "Einzel-Achtel", vec!["atom/notehead_filled", "atom/stem_up", "atom/flag_eighth_up"]),
        ("group/single_note_quarter", "Einzel-Viertel", vec!["atom/notehead_filled", "atom/stem_up"]),
        ("group/single_note_half", "Einzel-Halbe", vec!["atom/notehead_open", "atom/stem_up"]),
        ("group/single_note_whole", "Einzel-Ganze", vec!["atom/notehead_whole"]),
        ("group/beamed_group_2_eighths", "Zwei Achtel mit Balken", vec!["atom/notehead_filled", "atom/notehead_filled", "atom/stem_up", "atom/stem_up", "atom/beam_1"]),
        ("group/beamed_group_3_eighths", "Drei Achtel mit Balken", vec![]),
        ("group/beamed_group_4_eighths", "Vier Achtel mit Balken", vec![]),
        ("group/beamed_group_4_sixteenths", "Vier Sechzehntel mit Doppelbalken", vec!["atom/notehead_filled", "atom/notehead_filled", "atom/notehead_filled", "atom/notehead_filled", "atom/beam_2"]),
        ("group/beamed_group_8_sixteenths", "Acht Sechzehntel mit Doppelbalken", vec![]),
        ("group/beamed_group_mixed_8_16", "Gemischte 8tel + 16tel mit Balken", vec![]),
        ("group/chord_2_notes", "Akkord (2 Noten)", vec!["atom/notehead_filled", "atom/notehead_filled", "atom/stem_up"]),
        ("group/chord_3_notes", "Akkord (3 Noten)", vec![]),
        ("group/chord_4_notes", "Akkord (4 Noten)", vec![]),
        ("group/chord_5_notes", "Akkord (5 Noten)", vec![]),
        ("group/tied_pair", "Zwei Noten mit Bindebogen", vec![]),
        ("group/tied_triple", "Drei Noten mit Bindebogen", vec![]),
        ("group/triplet", "Triole", vec!["atom/notehead_filled", "atom/notehead_filled", "atom/notehead_filled", "atom/beam_1"]),
        ("group/grace_before", "Vorschlagsnote", vec![]),
        ("group/mordent", "Mordent (Triller-Schnoerkel)", vec![]),
        ("group/trill", "Triller", vec![]),
        ("group/clef_with_keysig", "Schluessel + Tonart-Vorzeichen", vec![]),
        ("group/keysig_with_timesig", "Tonart + Taktangabe", vec![]),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: atoms.into_iter().map(String::from).collect(),
        });
    }

    // ── Phrasen-Patterns (selten gelabelt, fuer fortgeschrittene UX) ─────
    for (id, name) in [
        ("phrase/cadence_v_i", "Kadenz V-I"),
        ("phrase/marcia_pattern", "Marsch-Pattern"),
        ("phrase/polka_pattern", "Polka-Pattern"),
        ("phrase/walzer_pattern", "Walzer-Pattern"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Phrase,
            atoms: Vec::new(),
        });
    }

    out
}

/// Liefert nur die Klassen einer Ebene.
pub fn classes_of_level(level: ClassLevel) -> Vec<ClassEntry> {
    all_classes().into_iter().filter(|c| c.level == level).collect()
}

/// Resolved Atoms-IDs einer Group → die ClassEntries dazu.
pub fn drill_down(group_id: &str) -> Vec<ClassEntry> {
    let groups = all_classes();
    let group = match groups.iter().find(|c| c.id == group_id && c.level == ClassLevel::Group) {
        Some(g) => g,
        None => return Vec::new(),
    };
    let atom_ids: std::collections::HashSet<_> = group.atoms.iter().cloned().collect();
    groups
        .into_iter()
        .filter(|c| atom_ids.contains(&c.id))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn all_classes_has_minimum_count() {
        let cs = all_classes();
        assert!(cs.len() > 50, "Erwartet mehr als 50 Klassen, gefunden: {}", cs.len());
    }

    #[test]
    fn group_class_has_atoms() {
        let cs = all_classes();
        let group = cs
            .iter()
            .find(|c| c.id == "group/beamed_group_4_sixteenths")
            .expect("4 sixteenths Gruppe vorhanden");
        assert_eq!(group.level, ClassLevel::Group);
        assert!(!group.atoms.is_empty());
    }

    #[test]
    fn drill_down_returns_atoms() {
        let drilled = drill_down("group/single_note_quarter");
        assert!(!drilled.is_empty());
        assert!(drilled.iter().all(|c| c.level == ClassLevel::Atom));
    }

    #[test]
    fn drill_down_unknown_group_is_empty() {
        let drilled = drill_down("group/does_not_exist");
        assert!(drilled.is_empty());
    }

    #[test]
    fn classes_of_level_filters() {
        let atoms = classes_of_level(ClassLevel::Atom);
        let groups = classes_of_level(ClassLevel::Group);
        assert!(atoms.len() > 30);
        assert!(groups.len() > 15);
        assert!(atoms.iter().all(|c| c.level == ClassLevel::Atom));
        assert!(groups.iter().all(|c| c.level == ClassLevel::Group));
    }
}
