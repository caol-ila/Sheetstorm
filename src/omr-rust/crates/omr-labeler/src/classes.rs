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
///
/// **Konzept (User-Vorgabe 2026-05-04):**
/// Ein TON-EREIGNIS = eine Note + ALLES was dazugehoert (Akzidenz,
/// Stakkato, Akzent, Pralltriller, Punkt, Bindebogen-Anker, Fermate ...).
/// Der User labelt auf diesem aggregierten Level. Atome sind nur
/// Drill-Down-Hilfen.
///
/// **Ausnahmen** (kein Ton-Ereignis, eigenes Element):
/// Crescendo/Decrescendo-Gabel, Taktnummer, Texte (Tempo, Ausdruck,
/// Lyrics, Akkordsymbol, Sprungmarken), Probenzeichen, Segno, Coda,
/// Voltenklammern.
pub fn all_classes() -> Vec<ClassEntry> {
    let mut out = Vec::new();

    // ── ATOME (nur Drill-Down) ────────────────────────────────────────
    for (id, name) in [
        ("atom/notenkopf_gefuellt", "Notenkopf gefuellt (Viertel/Achtel/16tel/...)"),
        ("atom/notenkopf_offen", "Notenkopf offen (Halbe)"),
        ("atom/notenkopf_ganze", "Ganze Note (Notenkopf)"),
        ("atom/notenkopf_x", "X-Notenkopf (Schlagzeug)"),
        ("atom/notenkopf_raute", "Rauten-Notenkopf"),
        ("atom/hals_oben", "Notenhals nach oben"),
        ("atom/hals_unten", "Notenhals nach unten"),
        ("atom/balken_1", "Balken (Achtel, 1 Linie)"),
        ("atom/balken_2", "Balken (Sechzehntel, 2 Linien)"),
        ("atom/balken_3", "Balken (32tel, 3 Linien)"),
        ("atom/faehnchen_achtel", "Faehnchen Achtel"),
        ("atom/faehnchen_sechzehntel", "Faehnchen Sechzehntel"),
        ("atom/punktierung", "Punktierung (Aug.-Punkt)"),
        ("atom/akzidenz_kreuz", "Vorzeichen ♯"),
        ("atom/akzidenz_be", "Vorzeichen ♭"),
        ("atom/akzidenz_aufloesen", "Aufloesungszeichen ♮"),
        ("atom/akzidenz_doppelkreuz", "Doppelkreuz 𝄪"),
        ("atom/akzidenz_doppelbe", "Doppel-Be 𝄫"),
        ("atom/artikulation_staccato", "Staccato (Punkt)"),
        ("atom/artikulation_staccatissimo", "Staccatissimo (Spitze)"),
        ("atom/artikulation_tenuto", "Tenuto (Strich)"),
        ("atom/artikulation_akzent", "Akzent ( > )"),
        ("atom/artikulation_marcato", "Marcato ( ^ )"),
        ("atom/artikulation_fermate", "Fermate"),
        ("atom/verzierung_pralltriller", "Pralltriller"),
        ("atom/verzierung_mordent", "Mordent"),
        ("atom/verzierung_triller", "Triller (tr)"),
        ("atom/verzierung_doppelschlag", "Doppelschlag"),
        ("atom/verzierung_arpeggio", "Arpeggio"),
        ("atom/verzierung_glissando", "Glissando"),
        ("atom/hilfslinie", "Hilfslinie"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Atom,
            atoms: Vec::new(),
        });
    }

    // ── TON-EREIGNISSE (primaere Labeling-Ebene) ──────────────────────
    //
    // Note + alles was dranhängt = 1 Element.
    for (id, name, atoms) in [
        ("ton/ganze", "Ganze Note (mit Drumrum)", vec!["atom/notenkopf_ganze"]),
        ("ton/halbe", "Halbe Note", vec!["atom/notenkopf_offen", "atom/hals_oben"]),
        ("ton/viertel", "Viertelnote", vec!["atom/notenkopf_gefuellt", "atom/hals_oben"]),
        ("ton/achtel", "Achtelnote (mit Faehnchen)", vec!["atom/notenkopf_gefuellt", "atom/hals_oben", "atom/faehnchen_achtel"]),
        ("ton/sechzehntel", "Sechzehntelnote (mit Faehnchen)", vec!["atom/notenkopf_gefuellt", "atom/hals_oben", "atom/faehnchen_sechzehntel"]),
        ("ton/punktiert_halbe", "Punktierte Halbe", vec![]),
        ("ton/punktiert_viertel", "Punktierte Viertel", vec![]),
        ("ton/punktiert_achtel", "Punktierte Achtel", vec![]),
        ("ton/vorschlag", "Vorschlagsnote (Acciaccatura)", vec![]),
        ("akkord/2_noten", "Akkord (2 Noten, gleicher Hals)", vec!["atom/notenkopf_gefuellt", "atom/notenkopf_gefuellt", "atom/hals_oben"]),
        ("akkord/3_noten", "Akkord (3 Noten)", vec![]),
        ("akkord/4_noten", "Akkord (4 Noten)", vec![]),
        ("akkord/5_noten_plus", "Akkord (5+ Noten)", vec![]),
        ("balken/2_noten", "Beam-Gruppe (2 Noten)", vec![]),
        ("balken/3_noten", "Beam-Gruppe (3 Noten / Triole)", vec![]),
        ("balken/4_noten", "Beam-Gruppe (4 Noten)", vec![]),
        ("balken/5_plus_noten", "Beam-Gruppe (5+ Noten)", vec![]),
        ("balken/gemischt", "Beam-Gruppe gemischte Werte (8tel+16tel)", vec![]),
        ("triole/freistehend", "Triole ohne Balken (3-er-Klammer)", vec![]),
        ("bindebogen/phrase", "Phrase mit Bindebogen (Legato)", vec![]),
        ("haltebogen/paar", "Haltebogen (zwei gleiche Noten)", vec![]),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: atoms.into_iter().map(String::from).collect(),
        });
    }

    // ── PAUSEN ─────────────────────────────────────────────────────────
    for (id, name) in [
        ("pause/ganze", "Ganze Pause"),
        ("pause/halbe", "Halbe Pause"),
        ("pause/viertel", "Viertelpause"),
        ("pause/achtel", "Achtelpause"),
        ("pause/sechzehntel", "Sechzehntelpause"),
        ("pause/zweiunddreissigstel", "32tel-Pause"),
        ("pause/mehrtakt", "Mehrtaktpause (1 Strich + Zahl)"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: Vec::new(),
        });
    }

    // ── SCHLUESSEL ─────────────────────────────────────────────────────
    for (id, name) in [
        ("schluessel/violin", "Violinschluessel (G)"),
        ("schluessel/bass", "Bassschluessel (F)"),
        ("schluessel/alt", "Altschluessel (C)"),
        ("schluessel/tenor", "Tenorschluessel (C)"),
        ("schluessel/percussion", "Percussion-Schluessel"),
        ("schluessel/oktavierend_8va", "Oktavierender Schluessel (8va)"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: Vec::new(),
        });
    }

    // ── TAKTSTRICHE ────────────────────────────────────────────────────
    for (id, name) in [
        ("takt/normal", "Taktstrich (einfach)"),
        ("takt/doppel", "Doppelstrich"),
        ("takt/schluss", "Schlussstrich"),
        ("takt/wdh_anfang", "Wiederholungsanfang ‖:"),
        ("takt/wdh_ende", "Wiederholungsende :‖"),
        ("takt/wdh_doppel", "Wiederholungsende+anfang :‖:"),
        ("takt/gestrichelt", "Gestrichelter Taktstrich"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: Vec::new(),
        });
    }

    // ── TONART (Vorzeichen am Schluessel) ─────────────────────────────
    for (id, name) in [
        ("tonart/1_kreuz", "1 Kreuz (G-Dur / e-moll)"),
        ("tonart/2_kreuze", "2 Kreuze (D-Dur / h-moll)"),
        ("tonart/3_kreuze", "3 Kreuze (A-Dur)"),
        ("tonart/4_kreuze", "4 Kreuze (E-Dur)"),
        ("tonart/5_kreuze", "5 Kreuze (H-Dur)"),
        ("tonart/1_be", "1 ♭ (F-Dur / d-moll)"),
        ("tonart/2_be", "2 ♭ (B-Dur)"),
        ("tonart/3_be", "3 ♭ (Es-Dur)"),
        ("tonart/4_be", "4 ♭ (As-Dur)"),
        ("tonart/5_be", "5 ♭ (Des-Dur)"),
        ("tonart/keine", "Keine Vorzeichen (C-Dur)"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: Vec::new(),
        });
    }

    // ── TAKTART ────────────────────────────────────────────────────────
    for (id, name) in [
        ("taktart/2_4", "2/4-Takt"),
        ("taktart/3_4", "3/4-Takt"),
        ("taktart/4_4", "4/4-Takt"),
        ("taktart/3_8", "3/8-Takt"),
        ("taktart/6_8", "6/8-Takt"),
        ("taktart/9_8", "9/8-Takt"),
        ("taktart/12_8", "12/8-Takt"),
        ("taktart/c_takt", "C (4/4)"),
        ("taktart/alla_breve", "Alla breve ¢ (2/2)"),
        ("taktart/anders", "Andere Taktart"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: Vec::new(),
        });
    }

    // ── DYNAMIK (Buchstaben — eigenes Element pro Position) ───────────
    for (id, name) in [
        ("dyn/p", "p (piano)"),
        ("dyn/pp", "pp (pianissimo)"),
        ("dyn/ppp", "ppp"),
        ("dyn/mp", "mp (mezzopiano)"),
        ("dyn/mf", "mf (mezzoforte)"),
        ("dyn/f", "f (forte)"),
        ("dyn/ff", "ff (fortissimo)"),
        ("dyn/fff", "fff"),
        ("dyn/sfz", "sfz (sforzando)"),
        ("dyn/sf", "sf"),
        ("dyn/fp", "fp"),
        ("dyn/cresc_text", "cresc. (Text)"),
        ("dyn/decresc_text", "decresc. / dim. (Text)"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: Vec::new(),
        });
    }

    // ── DYNAMIK-GABELN (Hairpins — eigenes Element, AUSNAHME) ────────
    for (id, name) in [
        ("hairpin/crescendo", "Crescendo-Gabel <"),
        ("hairpin/decrescendo", "Decrescendo-Gabel >"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: Vec::new(),
        });
    }

    // ── TEXT (eigene Elemente, AUSNAHME) ───────────────────────────────
    for (id, name) in [
        ("text/tempo", "Tempoangabe (Allegro, ♩=120)"),
        ("text/ausdruck", "Ausdruck (espressivo, dolce)"),
        ("text/taktnummer", "Taktnummer / Bar Number"),
        ("text/sprungmarke", "Sprungmarke (D.C., D.S., Fine, al Coda)"),
        ("text/probenzeichen", "Probenzeichen (A, B, C in Box)"),
        ("text/instrument", "Instrumentenname"),
        ("text/akkordsymbol", "Gitarrenakkord (C7, Am, ...)"),
        ("text/liedtext", "Liedtext / Lyric"),
        ("text/anweisung", "Spielanweisung (mit Daempfer, pizz., ...)"),
        ("text/sonstiges", "Sonstiger Text"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: Vec::new(),
        });
    }

    // ── MARKEN / ZEICHEN ──────────────────────────────────────────────
    for (id, name) in [
        ("marke/segno", "Segno (𝄋)"),
        ("marke/coda", "Coda (𝄌)"),
        ("marke/atem", "Atemzeichen (')"),
        ("marke/cesur", "Cesur ( // )"),
        ("marke/voltenklammer_1", "Voltenklammer 1 (1.|—)"),
        ("marke/voltenklammer_2", "Voltenklammer 2 (2.|—)"),
        ("marke/oktava_oben", "Oktava 8va (eine Oktave hoeher)"),
        ("marke/oktava_unten", "Oktava 8vb (eine Oktave tiefer)"),
        ("marke/pedal_ab", "Ped (Pedal druecken)"),
        ("marke/pedal_auf", "* (Pedal loslassen)"),
        ("marke/akkolade", "Akkolade (geschweifte Klammer)"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
            atoms: Vec::new(),
        });
    }

    // ── SPEZIAL (Meta-Antworten) ──────────────────────────────────────
    for (id, name) in [
        ("spezial/kein_element", "Kein gueltiges Element (Rauschen / kaputter bbox)"),
        ("spezial/unklar", "Unklar — kann nicht zuordnen"),
        ("spezial/teil_eines_elements", "Nur Teil eines Elements (zu klein gefasst)"),
        ("spezial/mehrere_elemente", "Mehrere Elemente in einer Box (zu gross gefasst)"),
    ] {
        out.push(ClassEntry {
            id: id.to_string(),
            display_name: name.to_string(),
            level: ClassLevel::Group,
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
            .find(|c| c.id == "ton/viertel")
            .expect("Viertelnote-Gruppe vorhanden");
        assert_eq!(group.level, ClassLevel::Group);
        assert!(!group.atoms.is_empty());
    }

    #[test]
    fn drill_down_returns_atoms() {
        let drilled = drill_down("ton/viertel");
        assert!(!drilled.is_empty());
        assert!(drilled.iter().all(|c| c.level == ClassLevel::Atom));
    }

    #[test]
    fn drill_down_unknown_group_is_empty() {
        let drilled = drill_down("ton/does_not_exist");
        assert!(drilled.is_empty());
    }

    #[test]
    fn classes_of_level_filters() {
        let atoms = classes_of_level(ClassLevel::Atom);
        let groups = classes_of_level(ClassLevel::Group);
        assert!(atoms.len() > 20);
        assert!(groups.len() > 40);
        assert!(atoms.iter().all(|c| c.level == ClassLevel::Atom));
        assert!(groups.iter().all(|c| c.level == ClassLevel::Group));
    }
}
