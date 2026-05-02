//! Cross-Part-Validation — Konsistenz-Checks zwischen mehreren Stimmen
//! desselben Stueckes.
//!
//! Eine "Part" hier = ein einzelnes Sig (eine Stimme). Mehrere Parts werden
//! aligned per Measure-Nummer + System-Index, dann auf Konsistenz geprueft.
//!
//! ## Anwendungsfall
//! Ein Blasmusik-Verein laedt 10+ Stimmen-PDFs desselben Stueckes hoch.
//! Diese Funktion vergleicht die erkannten Sigs und meldet Inkonsistenzen,
//! die auf OMR-Fehler hinweisen (z.B. verlorener Taktstrich → falsche
//! Taktanzahl, falsch erkannte Tonart).

use crate::{InterKind, Sig};
use serde::{Deserialize, Serialize};

// ============================================================================
// Öffentliche Typen
// ============================================================================

/// Art der erkannten Inkonsistenz zwischen Parts.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum InconsistencyKind {
    /// Anzahl Takte unterschiedlich (z.B. Trumpet 1 hat 64 Takte, Trumpet 2 hat 65).
    MeasureCountMismatch {
        /// (part_name, measure_count) pro Part.
        per_part: Vec<(String, u32)>,
    },
    /// Time-Signature in einem Takt unterschiedlich (z.B. Part A 4/4, Part B 3/4).
    TimeSignatureMismatch {
        /// Takt-Nummer (1-basiert).
        measure: u32,
        /// (part_name, Some((beats, beat_type))) — None wenn kein TimeSig in diesem Takt.
        per_part: Vec<(String, Option<(u8, u8)>)>,
    },
    /// Tonart unterschiedlich (nach Transposition).
    KeySignatureMismatch {
        /// (part_name, transposed_fifths) pro Part.
        per_part: Vec<(String, i8)>,
    },
    /// Repeat-Struktur unterschiedlich (z.B. RepeatEnd in einem Part, nicht im anderen).
    RepeatStructureMismatch {
        /// Takt-Nummer (1-basiert).
        measure: u32,
        /// (part_name, Some(marker)) — None wenn kein Repeat in diesem Takt.
        per_part: Vec<(String, Option<RepeatMarker>)>,
    },
    /// Tempo-Marker fehlt in einem Part.
    TempoMissing {
        /// Takt-Nummer.
        measure: u32,
        /// Parts, in denen der Marker vorhanden ist.
        present_in: Vec<String>,
        /// Parts, in denen er fehlt.
        missing_in: Vec<String>,
    },
}

/// Einfache Kategorisierung eines Repeat-Markers.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum RepeatMarker {
    /// Wiederholungsanfang (||:).
    Start,
    /// Wiederholungsende (:||).
    End,
    /// Volta-Klammer (1./2./...-Endung), Wert = Nummer.
    Volta(u8),
}

/// Ergebnis des Cross-Part-Vergleichs.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrossPartReport {
    /// Anzahl verglichener Parts.
    pub n_parts: u32,
    /// Maximale Taktanzahl über alle Parts.
    pub max_measure_count: u32,
    /// Liste aller gefundenen Inkonsistenzen.
    pub inconsistencies: Vec<InconsistencyKind>,
}

/// Eine einzelne Stimme im Cross-Part-Vergleich.
pub struct Part<'a> {
    /// Anzeige-Name dieser Stimme (z.B. "Trumpet 1", "Horn 2").
    pub name: String,
    /// Referenz auf den zugehörigen Sig.
    pub sig: &'a Sig,
    /// Transposition in Halbtönen (0 = C-Instrument, -2 = Bb-Instrument, -3 = Eb-Instrument).
    pub transposition_semitones: i8,
}

// ============================================================================
// Hauptfunktion
// ============================================================================

/// Vergleicht mehrere Parts auf Konsistenz und gibt einen Report zurück.
///
/// # Algorithmus
/// 1. Sammle `measure_count` pro Part (= höchste measure_number im Sig).
/// 2. Prüfe Measure-Count-Konsistenz.
/// 3. Pro Takt: TimeSig-Vergleich.
/// 4. Gesamt-KeySig-Vergleich (nach Transposition).
/// 5. Pro Takt: Repeat-Struktur-Vergleich.
/// 6. Pro Takt: Tempo-Marker-Vergleich.
pub fn validate_cross_parts(parts: &[Part<'_>]) -> CrossPartReport {
    if parts.is_empty() {
        return CrossPartReport { n_parts: 0, max_measure_count: 0, inconsistencies: vec![] };
    }

    let mut inconsistencies = Vec::new();

    // 1. Measure counts pro Part
    let measure_counts: Vec<(String, u32)> = parts
        .iter()
        .map(|p| (p.name.clone(), measure_count(p.sig)))
        .collect();

    let max_measure_count = measure_counts.iter().map(|(_, c)| *c).max().unwrap_or(0);

    // 2. Measure-Count-Mismatch
    let all_equal = measure_counts.windows(2).all(|w| w[0].1 == w[1].1);
    if !all_equal {
        inconsistencies.push(InconsistencyKind::MeasureCountMismatch {
            per_part: measure_counts.clone(),
        });
    }

    // 3. TimeSig pro Takt
    for m in 1..=max_measure_count {
        let per_part: Vec<(String, Option<(u8, u8)>)> = parts
            .iter()
            .map(|p| (p.name.clone(), timesig_at_measure(p.sig, m)))
            .collect();

        // Nur prüfen wo mindestens ein Part eine TimeSig hat
        let any_some = per_part.iter().any(|(_, v)| v.is_some());
        if any_some {
            let first_val = per_part.iter().find_map(|(_, v)| *v);
            let mismatch = per_part
                .iter()
                .filter(|(_, v)| v.is_some())
                .any(|(_, v)| *v != first_val);
            if mismatch {
                inconsistencies.push(InconsistencyKind::TimeSignatureMismatch { measure: m, per_part });
            }
        }
    }

    // 4. KeySig-Vergleich (nach Transposition)
    let key_per_part: Vec<(String, i8)> = parts
        .iter()
        .map(|p| {
            let raw = keysig_fifths(p.sig);
            let transposed = transposed_fifths(raw, p.transposition_semitones);
            (p.name.clone(), transposed)
        })
        .collect();

    if parts.len() > 1 {
        let first = key_per_part[0].1;
        if key_per_part.iter().any(|(_, f)| *f != first) {
            inconsistencies.push(InconsistencyKind::KeySignatureMismatch {
                per_part: key_per_part,
            });
        }
    }

    // 5. Repeat-Struktur pro Takt
    for m in 1..=max_measure_count {
        let per_part: Vec<(String, Option<RepeatMarker>)> = parts
            .iter()
            .map(|p| (p.name.clone(), repeat_marker_at(p.sig, m)))
            .collect();

        let any_some = per_part.iter().any(|(_, v)| v.is_some());
        if any_some {
            let first_val = per_part.iter().find_map(|(_, v)| *v);
            let mismatch = per_part.iter().any(|(_, v)| *v != first_val);
            if mismatch {
                inconsistencies.push(InconsistencyKind::RepeatStructureMismatch {
                    measure: m,
                    per_part,
                });
            }
        }
    }

    // 6. Tempo pro Takt
    for m in 1..=max_measure_count {
        let has_tempo: Vec<bool> =
            parts.iter().map(|p| has_tempo_at(p.sig, m)).collect();

        let present_count = has_tempo.iter().filter(|&&b| b).count();
        // Nur melden wenn mindestens einer hat und mindestens einer fehlt
        if present_count > 0 && present_count < parts.len() {
            let present_in: Vec<String> = parts
                .iter()
                .zip(has_tempo.iter())
                .filter(|(_, &b)| b)
                .map(|(p, _)| p.name.clone())
                .collect();
            let missing_in: Vec<String> = parts
                .iter()
                .zip(has_tempo.iter())
                .filter(|(_, &b)| !b)
                .map(|(p, _)| p.name.clone())
                .collect();
            inconsistencies.push(InconsistencyKind::TempoMissing {
                measure: m,
                present_in,
                missing_in,
            });
        }
    }

    CrossPartReport {
        n_parts: parts.len() as u32,
        max_measure_count,
        inconsistencies,
    }
}

// ============================================================================
// Hilfsfunktionen
// ============================================================================

/// Gibt die Transposition in fifths zurück (nach Halbtönen-Umrechnung).
///
/// Mapping: Halbtonintervall → Quinte (Circle of Fifths)
/// Jede Quinte entspricht 7 Halbtönen (mod 12).
/// Um von Halbtönen in fifths umzurechnen: inverse, d.h. n fifths = n*7 mod 12 Halbtöne.
/// Umkehrung: für k Halbtöne → Anzahl fifths = k * 7 mod 12 (da 7 sein eigenes inverses mod 12 ist).
///
/// In der Praxis: Bb-Trompete (transp = -2) liest 2 Halbtöne höher als klingend.
/// C-Dur klingend → D-Dur notiert (2 Sharps = +2 fifths).
pub fn transposed_fifths(fifths: i8, semitones: i8) -> i8 {
    // semitones: Transposition in Halbtönen (positiv = höher notiert)
    // Für Konsistenz-Check: wir berechnen die klingende Tonart jedes Parts.
    // klingender_fifths = notierter_fifths + Korrektur_für_Transposition
    //
    // Bb-Trompete: notierter Ton ist 2 HT höher als klingend → transp = -2
    // Also klingend = notiert - 2 HT.
    // In fifths: -2 HT = -2 * 7 mod 12 = -14 mod 12 = -2 fifths (da Bb = -2 fifths)
    //
    // Formel: Jeder Halbton-Schritt nach oben = +7 fifths (mod 12, in [-6, 6])
    // Da wir klingend berechnen: klingend = notiert + semitones (semitones = klingend - notiert)
    // also semitones = klingend_HT - notiert_HT → klingend = notiert + semitones

    // fifths → Halbton-Offset: fifths * 7 mod 12
    // Aber einfacher: jeder Halbton-Schritt nach oben im Circle of Fifths = +7 Schritte
    // Wir addieren semitones * 7 (mod 12) zu fifths:
    let delta_fifths = ((semitones as i32).rem_euclid(12) * 7).rem_euclid(12);
    // delta_fifths ∈ [0, 11]; normalisiere zu [-6, 6]
    let delta_normalized = if delta_fifths > 6 { delta_fifths - 12 } else { delta_fifths };
    let result = (fifths as i32 + delta_normalized).rem_euclid(12) as i32;
    // Normalisiere Ergebnis zu [-6, 6]
    if result > 6 { (result - 12) as i8 } else { result as i8 }
}

/// Zählt die maximale Takt-Nummer im Sig (= Anzahl erkannter Takte).
fn measure_count(sig: &Sig) -> u32 {
    sig.inters()
        .filter_map(|i| i.meta().measure_number)
        .max()
        .unwrap_or(0)
}

/// Gibt die TimeSig (beats, beat_type) für den angegebenen Takt zurück.
/// Nimmt die erste TimeSig, deren measure_number <= m ist (letzte gültige TS).
fn timesig_at_measure(sig: &Sig, measure: u32) -> Option<(u8, u8)> {
    use crate::inters::TimeSignatureInter;
    // Finde den TimeSig-Inter mit der höchsten measure_number <= measure
    sig.typed_inters::<TimeSignatureInter>()
        .filter(|ts| {
            // TimeSig gilt ab der Takt-Nummer wo sie steht (oder measure_number == None → Takt 1)
            let m = ts.meta.measure_number.unwrap_or(1);
            m <= measure
        })
        .max_by_key(|ts| ts.meta.measure_number.unwrap_or(1))
        .map(|ts| (ts.beats, ts.beat_type))
}

/// Gibt die primäre KeySig (fifths) des Sigs zurück.
/// Nimmt die erste KeySig (niedrigste measure_number) als tonale Basis.
fn keysig_fifths(sig: &Sig) -> i8 {
    use crate::inters::KeySignatureInter;
    sig.typed_inters::<KeySignatureInter>()
        .min_by_key(|ks| ks.meta.measure_number.unwrap_or(0))
        .map(|ks| ks.fifths)
        .unwrap_or(0)
}

/// Gibt den Repeat-Marker im angegebenen Takt zurück (falls vorhanden).
/// Priorität: End > Start > Volta (bei Konflikten).
fn repeat_marker_at(sig: &Sig, measure: u32) -> Option<RepeatMarker> {
    let mut found: Option<RepeatMarker> = None;
    for inter in sig.inters() {
        if inter.meta().measure_number != Some(measure) {
            continue;
        }
        let marker = match inter.kind() {
            InterKind::RepeatEnd => Some(RepeatMarker::End),
            InterKind::RepeatStart => Some(RepeatMarker::Start),
            InterKind::Volta => Some(RepeatMarker::Volta(1)), // default Volta-Nummer
            _ => None,
        };
        if let Some(m) = marker {
            // Priorität: End > Start > Volta
            match (&found, &m) {
                (None, _) => found = Some(m),
                (Some(RepeatMarker::Volta(_)), RepeatMarker::Start) => found = Some(m),
                (Some(RepeatMarker::Volta(_)), RepeatMarker::End) => found = Some(m),
                (Some(RepeatMarker::Start), RepeatMarker::End) => found = Some(m),
                _ => {}
            }
        }
    }
    found
}

/// Prüft ob in diesem Takt ein Tempo-Marker vorhanden ist.
fn has_tempo_at(sig: &Sig, measure: u32) -> bool {
    sig.inters().any(|i| {
        i.kind() == InterKind::Tempo && i.meta().measure_number == Some(measure)
    })
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;
    use crate::grade::Grade;
    use crate::inter::{Inter, InterId, InterKind, InterMeta};
    use crate::inters::{KeySignatureInter, TimeSignatureInter};
    use omr_core::Rect;

    // --- Test-Helpers ---

    fn make_sig() -> Sig {
        Sig::new()
    }

    /// Fügt einen minimalen Inter ohne Geometrie in den Sig.
    fn add_inter_at(sig: &mut Sig, kind: InterKind, measure: u32) {
        let id = sig.next_inter_id();
        let bounds = Rect { x: 0, y: 0, w: 1, h: 1 };
        let mut meta = InterMeta::new(id, kind, bounds, Grade::new(0.9));
        meta.measure_number = Some(measure);

        #[derive(Debug)]
        struct MinInter { meta: InterMeta }
        impl Inter for MinInter {
            fn meta(&self) -> &InterMeta { &self.meta }
            fn meta_mut(&mut self) -> &mut InterMeta { &mut self.meta }
            fn as_any(&self) -> &dyn std::any::Any { self }
            fn as_any_mut(&mut self) -> &mut dyn std::any::Any { self }
        }
        sig.add_inter(Box::new(MinInter { meta }));
    }

    fn add_keysig(sig: &mut Sig, fifths: i8, measure: u32) {
        let id = sig.next_inter_id();
        let bounds = Rect { x: 0, y: 0, w: 1, h: 1 };
        let mut meta = InterMeta::new(id, InterKind::KeySignature, bounds, Grade::new(0.9));
        meta.measure_number = Some(measure);
        sig.add_inter(Box::new(KeySignatureInter { meta, fifths }));
    }

    fn add_timesig(sig: &mut Sig, beats: u8, beat_type: u8, measure: u32) {
        let id = sig.next_inter_id();
        let bounds = Rect { x: 0, y: 0, w: 1, h: 1 };
        let mut meta = InterMeta::new(id, InterKind::TimeSignature, bounds, Grade::new(0.9));
        meta.measure_number = Some(measure);
        sig.add_inter(Box::new(TimeSignatureInter { meta, beats, beat_type }));
    }

    /// Baut einen einfachen Sig mit `n` Takten (je ein HeadInter als Platzhalter).
    fn sig_with_n_measures(n: u32) -> Sig {
        let mut sig = make_sig();
        for m in 1..=n {
            add_inter_at(&mut sig, InterKind::Head, m);
        }
        sig
    }

    // -------------------------------------------------------------------------
    // Test 1: Zwei Parts, gleiche Taktanzahl, keine Inkonsistenz
    // -------------------------------------------------------------------------
    #[test]
    fn two_parts_same_count_no_inconsistency() {
        let sig1 = sig_with_n_measures(64);
        let sig2 = sig_with_n_measures(64);
        let parts = [
            Part { name: "Trumpet 1".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "Trumpet 2".into(), sig: &sig2, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        assert_eq!(report.n_parts, 2);
        assert_eq!(report.max_measure_count, 64);
        // Keine KeySig, keine TimeSig → keine Inkonsistenz außer ggf. keiner
        let count_mismatches = report.inconsistencies.iter()
            .filter(|i| matches!(i, InconsistencyKind::MeasureCountMismatch { .. }))
            .count();
        assert_eq!(count_mismatches, 0, "no measure count mismatch expected");
    }

    // -------------------------------------------------------------------------
    // Test 2: Taktanzahl-Mismatch gemeldet
    // -------------------------------------------------------------------------
    #[test]
    fn measure_count_mismatch_reported() {
        let sig1 = sig_with_n_measures(64);
        let sig2 = sig_with_n_measures(63);
        let parts = [
            Part { name: "Trumpet 1".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "Trumpet 2".into(), sig: &sig2, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        let mismatch = report.inconsistencies.iter().find(|i| {
            matches!(i, InconsistencyKind::MeasureCountMismatch { .. })
        });
        assert!(mismatch.is_some(), "MeasureCountMismatch expected");
        if let Some(InconsistencyKind::MeasureCountMismatch { per_part }) = mismatch {
            let t1 = per_part.iter().find(|(n, _)| n == "Trumpet 1").unwrap();
            let t2 = per_part.iter().find(|(n, _)| n == "Trumpet 2").unwrap();
            assert_eq!(t1.1, 64);
            assert_eq!(t2.1, 63);
        }
    }

    // -------------------------------------------------------------------------
    // Test 3: TimeSig-Mismatch in Takt 5 gemeldet
    // -------------------------------------------------------------------------
    #[test]
    fn time_sig_mismatch_in_measure_5_reported() {
        let mut sig1 = sig_with_n_measures(10);
        let mut sig2 = sig_with_n_measures(10);
        add_timesig(&mut sig1, 4, 4, 5);
        add_timesig(&mut sig2, 3, 4, 5);
        let parts = [
            Part { name: "Part A".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "Part B".into(), sig: &sig2, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        let mismatch = report.inconsistencies.iter().find(|i| {
            matches!(i, InconsistencyKind::TimeSignatureMismatch { measure: 5, .. })
        });
        assert!(mismatch.is_some(), "TimeSignatureMismatch in measure 5 expected");
    }

    // -------------------------------------------------------------------------
    // Test 4: KeySig-Mismatch ohne Transposition
    // -------------------------------------------------------------------------
    #[test]
    fn keysig_mismatch_without_transposition() {
        let mut sig1 = sig_with_n_measures(10);
        let mut sig2 = sig_with_n_measures(10);
        add_keysig(&mut sig1, 0, 1); // C-Dur
        add_keysig(&mut sig2, 2, 1); // D-Dur
        let parts = [
            Part { name: "Part A".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "Part B".into(), sig: &sig2, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        let mismatch = report.inconsistencies.iter().find(|i| {
            matches!(i, InconsistencyKind::KeySignatureMismatch { .. })
        });
        assert!(mismatch.is_some(), "KeySignatureMismatch expected");
    }

    // -------------------------------------------------------------------------
    // Test 5: Bb-Trompete nach Transposition konsistent
    // -------------------------------------------------------------------------
    #[test]
    fn keysig_consistent_after_bb_trumpet_transposition() {
        // C-Dur klingend (0 fifths)
        // Bb-Trompete notiert in D-Dur (2 fifths) weil sie 2 HT höher liest
        // transposition_semitones = -2 (klingend = notiert - 2 HT)
        // Nach Transposition: transposed_fifths(2, -2) soll 0 ergeben
        let mut sig_concert = sig_with_n_measures(8);
        let mut sig_bb = sig_with_n_measures(8);
        add_keysig(&mut sig_concert, 0, 1); // C-Dur (klingendes Instrument, transp=0)
        add_keysig(&mut sig_bb, 2, 1);      // D-Dur notiert (Bb-Trompete)
        let parts = [
            Part { name: "Flute".into(),     sig: &sig_concert, transposition_semitones: 0 },
            Part { name: "Trumpet Bb".into(), sig: &sig_bb,      transposition_semitones: -2 },
        ];
        let report = validate_cross_parts(&parts);
        let key_mismatches: Vec<_> = report.inconsistencies.iter().filter(|i| {
            matches!(i, InconsistencyKind::KeySignatureMismatch { .. })
        }).collect();
        assert!(
            key_mismatches.is_empty(),
            "No KeySignatureMismatch expected after Bb transposition: {:?}", key_mismatches
        );
    }

    // -------------------------------------------------------------------------
    // Test 6: RepeatStart nur in einem Part → gemeldet
    // -------------------------------------------------------------------------
    #[test]
    fn repeat_start_in_one_part_only_reported() {
        let mut sig1 = sig_with_n_measures(10);
        let sig2 = sig_with_n_measures(10);
        add_inter_at(&mut sig1, InterKind::RepeatStart, 5);
        let parts = [
            Part { name: "Trumpet 1".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "Trumpet 2".into(), sig: &sig2, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        let mismatch = report.inconsistencies.iter().find(|i| {
            matches!(i, InconsistencyKind::RepeatStructureMismatch { measure: 5, .. })
        });
        assert!(mismatch.is_some(), "RepeatStructureMismatch in measure 5 expected");
    }

    // -------------------------------------------------------------------------
    // Test 7: Volta-Mismatch gemeldet
    // -------------------------------------------------------------------------
    #[test]
    fn volta_mismatch_reported() {
        let mut sig1 = sig_with_n_measures(12);
        let mut sig2 = sig_with_n_measures(12);
        add_inter_at(&mut sig1, InterKind::Volta, 10);
        add_inter_at(&mut sig2, InterKind::RepeatEnd, 10);
        let parts = [
            Part { name: "Part A".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "Part B".into(), sig: &sig2, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        let mismatch = report.inconsistencies.iter().find(|i| {
            matches!(i, InconsistencyKind::RepeatStructureMismatch { measure: 10, .. })
        });
        assert!(mismatch.is_some(), "RepeatStructureMismatch for Volta vs RepeatEnd expected");
    }

    // -------------------------------------------------------------------------
    // Test 8: Tempo fehlt in einem Part
    // -------------------------------------------------------------------------
    #[test]
    fn tempo_missing_in_one_part_reported() {
        let mut sig1 = sig_with_n_measures(8);
        let sig2 = sig_with_n_measures(8);
        add_inter_at(&mut sig1, InterKind::Tempo, 1);
        let parts = [
            Part { name: "Part A".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "Part B".into(), sig: &sig2, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        let tempo_issue = report.inconsistencies.iter().find(|i| {
            matches!(i, InconsistencyKind::TempoMissing { measure: 1, .. })
        });
        assert!(tempo_issue.is_some(), "TempoMissing in measure 1 expected");
        if let Some(InconsistencyKind::TempoMissing { present_in, missing_in, .. }) = tempo_issue {
            assert!(present_in.contains(&"Part A".to_string()));
            assert!(missing_in.contains(&"Part B".to_string()));
        }
    }

    // -------------------------------------------------------------------------
    // Test 9: Drei Parts, ein Ausreißer korrekt identifiziert
    // -------------------------------------------------------------------------
    #[test]
    fn three_parts_with_one_outlier_correctly_identifies_outlier() {
        let sig1 = sig_with_n_measures(32);
        let sig2 = sig_with_n_measures(32);
        let sig3 = sig_with_n_measures(31); // Ausreißer
        let parts = [
            Part { name: "Part 1".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "Part 2".into(), sig: &sig2, transposition_semitones: 0 },
            Part { name: "Part 3".into(), sig: &sig3, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        let mismatch = report.inconsistencies.iter().find(|i| {
            matches!(i, InconsistencyKind::MeasureCountMismatch { .. })
        });
        assert!(mismatch.is_some(), "Outlier in Part 3 should cause MeasureCountMismatch");
        if let Some(InconsistencyKind::MeasureCountMismatch { per_part }) = mismatch {
            let outlier = per_part.iter().find(|(n, _)| n == "Part 3").unwrap();
            assert_eq!(outlier.1, 31);
        }
    }

    // -------------------------------------------------------------------------
    // Test 10: Leere Parts verursachen keinen Panic
    // -------------------------------------------------------------------------
    #[test]
    fn empty_parts_no_panics() {
        let sig1 = make_sig();
        let sig2 = make_sig();
        let parts = [
            Part { name: "Empty A".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "Empty B".into(), sig: &sig2, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        assert_eq!(report.max_measure_count, 0);
        // Keine Inkonsistenzen bei leeren Sigs (außer ggf. KeySig-Check mit 0)
        // Beide haben fifths=0 → kein Mismatch
        let key_mismatches = report.inconsistencies.iter()
            .filter(|i| matches!(i, InconsistencyKind::KeySignatureMismatch { .. }))
            .count();
        assert_eq!(key_mismatches, 0);
    }

    // -------------------------------------------------------------------------
    // Test 11: Einzelner Part → keine Inkonsistenzen
    // -------------------------------------------------------------------------
    #[test]
    fn single_part_no_inconsistencies() {
        let sig = sig_with_n_measures(16);
        let parts = [
            Part { name: "Solo".into(), sig: &sig, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        assert_eq!(report.n_parts, 1);
        assert!(
            report.inconsistencies.is_empty(),
            "Single part should have no inconsistencies: {:?}", report.inconsistencies
        );
    }

    // -------------------------------------------------------------------------
    // Test 12: CrossPartReport serialisiert nach JSON
    // -------------------------------------------------------------------------
    #[test]
    fn cross_part_report_serializes_to_json() {
        let sig1 = sig_with_n_measures(4);
        let sig2 = sig_with_n_measures(5);
        let parts = [
            Part { name: "A".into(), sig: &sig1, transposition_semitones: 0 },
            Part { name: "B".into(), sig: &sig2, transposition_semitones: 0 },
        ];
        let report = validate_cross_parts(&parts);
        let json = serde_json::to_string(&report).expect("serialization succeeds");
        assert!(json.contains("\"n_parts\":2"));
        assert!(json.contains("MeasureCountMismatch"));
    }

    // -------------------------------------------------------------------------
    // Test 13: transposed_fifths — Bb-Trompete Einzelfall
    // -------------------------------------------------------------------------
    #[test]
    fn transposed_fifths_bb_trumpet_c_major() {
        // C-Dur (0 fifths) klingend → Bb-Trompete notiert in D-Dur (+2 fifths)
        // transposed_fifths(2, -2) = 0 (klingend von D-Dur nach -2 HT = C-Dur)
        assert_eq!(transposed_fifths(2, -2), 0);
    }

    // -------------------------------------------------------------------------
    // Test 14: transposed_fifths — Eb-Klarinette
    // -------------------------------------------------------------------------
    #[test]
    fn transposed_fifths_eb_clarinet() {
        // Eb-Klarinette: transp = +3 (klingend = notiert + 3 HT, aber konventionell
        // in Lit.: notiert ist 3 HT höher → transp = -3... Check: Eb-Klar transponiert
        // nach oben: klingendes C → notiert als A → transp = +9 oder als -3?
        // Wir nutzen: transp = klingend - notiert in HT.
        // Eb-Klarinette: notiert A (klingend C) → transp = C - A = -9 HT = +3 mod 12.
        // transposed_fifths(0 [C-Dur notiert], +3) soll A-Dur (+3 fifths) klingend ergeben.
        // Warte: C-Dur ist 0 fifths klingend, Eb-Klar würde in A-Dur notieren (+3 fifths).
        // transposed_fifths(3 [A-Dur notiert], -9) soll 0 ergeben.
        // Aber hier testen wir: wenn klingend 0 (C) und transp=-9, dann notiert = 3 (A-Dur).
        // Für den Konsistenz-Check: wir transponieren den notierten fifths zurück zu klingend.
        // klingend = transposed_fifths(notiert_fifths, semitones)
        // wobei semitones = klingend_HT - notiert_HT = -9 für Eb-Klar.
        let klingend = transposed_fifths(3, -9);
        assert_eq!(klingend, 0, "Eb clarinet A-Dur notiert soll C-Dur klingend ergeben");
    }
}
