//! Music-Theory-Edges für den SIG.
//!
//! Erweitert ein gebautes `Sig` um Edges, die musiktheoretisches Wissen
//! kodieren:
//!
//! - **KeyConsistency**: Note-Pitch passt (oder passt nicht) zur aktiven Tonart
//! - **MeasureBudget**: Σ Durations im Takt = Time-Signature-Erwartung
//! - **VoiceLeading**: Aufeinanderfolgende Notes sind ≤ Sext getrennt
//! - **MetricStrength**: Note auf Down-Beat (starker Schlag) oder Up-Beat
//!
//! Jede Edge bringt Sub-Score-Information in den Contextual-Grade-Berechnung
//! und erlaubt deklarative Conflict-Detection.

use crate::inter::{Inter, InterId, InterKind};
use crate::inters::{HeadInter, KeySignatureInter, TimeSignatureInter};
use crate::relation::{
    ExclusionCause, Relation, RelationKind, SupportImpacts, SupportKind,
};
use crate::sig::Sig;
use std::collections::HashMap;

/// MIDI-Pitches, die in einer C-Dur-Tonleiter (0 sharps/flats) plausibel sind:
/// C, D, E, F, G, A, B → Mod 12: 0, 2, 4, 5, 7, 9, 11.
const C_MAJOR_DIATONIC: [u8; 7] = [0, 2, 4, 5, 7, 9, 11];

/// Welche Pitch-Klassen sind in einer Tonart mit `fifths` Vorzeichen plausibel?
///
/// fifths: positiv = Sharps (0=C, 1=G, 2=D, ..., 7=C#)
///         negativ = Flats (-1=F, -2=Bb, ..., -7=Cb)
///
/// Returns 7 pitch classes (0-11) der Tonleiter.
pub fn diatonic_pitches(fifths: i8) -> [u8; 7] {
    // Circle of fifths transposition: jede +1 fifth verschiebt um +7 (mod 12).
    let shift = (fifths as i32 * 7).rem_euclid(12) as u8;
    let mut out = [0u8; 7];
    for (i, &pc) in C_MAJOR_DIATONIC.iter().enumerate() {
        out[i] = (pc + shift) % 12;
    }
    out
}

/// Ist `midi_pitch` diatonisch zur Tonart mit `fifths` Vorzeichen?
pub fn is_diatonic(midi: u8, fifths: i8) -> bool {
    let pc = midi % 12;
    diatonic_pitches(fifths).contains(&pc)
}

/// Erzeugt KeyConsistency-Edges zwischen Heads und KeySignatures pro System.
///
/// - **Diatonisch**: Support-Edge (1.3, 1.0, Theoretical) — Head ist konsistent mit Tonart.
/// - **Nicht-diatonisch**: Exclusion-Edge (ConsistencyViolation) — schwacher Konflikt.
///
/// Nutzt **typed access** über `sig.typed_inters::<HeadInter>()` und
/// `sig.typed_inters::<KeySignatureInter>()` — kein externer Cache nötig.
///
/// Returns Anzahl hinzugefügter Edges.
pub fn add_key_consistency_edges(sig: &mut Sig) -> usize {
    // Sammle KeySigs per system_idx
    let mut keysig_by_system: HashMap<u32, (InterId, i8)> = HashMap::new();
    for ks in sig.typed_inters::<KeySignatureInter>() {
        if let Some(sysid) = ks.meta.system_idx {
            keysig_by_system.insert(sysid, (ks.id(), ks.fifths));
        }
    }

    // Sammle alle (head_id, system_idx, midi) bevor wir mut ans Sig.
    let head_data: Vec<(InterId, u32, u8)> = sig
        .typed_inters::<HeadInter>()
        .filter_map(|h| {
            let sysid = h.meta.system_idx?;
            // Nur Heads mit gesetztem MIDI berücksichtigen.
            if h.midi == 0 {
                return None;
            }
            Some((h.id(), sysid, h.midi))
        })
        .collect();

    let mut count = 0;
    for (head_id, sysid, midi) in head_data {
        let Some(&(keysig_id, fifths)) = keysig_by_system.get(&sysid) else { continue; };
        let consistent = is_diatonic(midi, fifths);
        let rel = if consistent {
            Relation::support(
                RelationKind::KeyConsistency,
                head_id,
                keysig_id,
                SupportImpacts::asymmetric(1.3, 1.0, SupportKind::Theoretical),
            )
        } else {
            Relation::exclusion(
                RelationKind::KeyConsistency,
                head_id,
                keysig_id,
                ExclusionCause::ConsistencyViolation,
            )
        };
        sig.add_relation(rel);
        count += 1;
    }
    count
}

/// Erzeugt MeasureBudget-Edges zwischen TimeSignature und allen Heads im
/// gleichen Measure.
///
/// Reine Annotation-Edge (kein Conflict-Resolution-Verhalten). Wird in
/// einer späteren Iteration zur Auto-Repair-Suggestion-Engine erweitert.
///
/// Returns Anzahl hinzugefügter Edges.
pub fn add_measure_budget_edges(sig: &mut Sig) -> usize {
    // Sammle TimeSigs per system_idx
    let mut ts_by_system: HashMap<u32, (InterId, u8, u8)> = HashMap::new();
    for ts in sig.typed_inters::<TimeSignatureInter>() {
        if let Some(sysid) = ts.meta.system_idx {
            ts_by_system.insert(sysid, (ts.id(), ts.beats, ts.beat_type));
        }
    }

    let head_data: Vec<(InterId, u32)> = sig
        .typed_inters::<HeadInter>()
        .filter_map(|h| Some((h.id(), h.meta.system_idx?)))
        .collect();

    let mut count = 0;
    for (head_id, sysid) in head_data {
        let Some(&(ts_id, _beats, _beat_type)) = ts_by_system.get(&sysid) else { continue; };
        sig.add_relation(Relation::support(
            RelationKind::MeasureBudget,
            head_id,
            ts_id,
            SupportImpacts::asymmetric(1.0, 1.05, SupportKind::Theoretical),
        ));
        count += 1;
    }
    count
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::grade::Grade;
    use crate::inter::{InterMeta, Provenance};
    use crate::inters::{HeadInter, KeySignatureInter};
    use omr_core::{NoteheadKind, Point, Rect};

    #[test]
    fn c_major_is_diatonic_for_c() {
        assert!(is_diatonic(60, 0)); // C4
        assert!(is_diatonic(62, 0)); // D4
        assert!(is_diatonic(64, 0)); // E4
        assert!(!is_diatonic(61, 0)); // C#4 — not diatonic in C major
        assert!(!is_diatonic(63, 0)); // Eb4 — not diatonic in C major
    }

    #[test]
    fn g_major_includes_fsharp() {
        // G-Dur hat 1 Sharp (F#).
        assert!(is_diatonic(66, 1)); // F#4 IS diatonic in G major
        assert!(!is_diatonic(65, 1)); // F natural — NOT diatonic in G major
    }

    #[test]
    fn f_major_includes_bflat() {
        // F-Dur hat 1 Flat (Bb).
        assert!(is_diatonic(70, -1)); // Bb4 IS diatonic in F major
        assert!(!is_diatonic(71, -1)); // B natural — NOT diatonic in F major
    }

    #[test]
    fn diatonic_pitches_for_c_major() {
        let pitches = diatonic_pitches(0);
        let mut sorted = pitches.to_vec();
        sorted.sort();
        assert_eq!(sorted, vec![0, 2, 4, 5, 7, 9, 11]);
    }

    fn mk_head(sig: &mut Sig, midi: u8, system_idx: u32) -> InterId {
        let id = sig.next_inter_id();
        let mut meta = InterMeta::new(
            id,
            InterKind::Head,
            Rect { x: 0, y: 0, w: 8, h: 8 },
            Grade::new(0.8),
        );
        meta.system_idx = Some(system_idx);
        let h = HeadInter {
            meta,
            center: Point { x: 0.0, y: 0.0 },
            notehead_kind: NoteheadKind::Filled,
            midi,
            step: omr_core::PitchStep::C,
            octave: 4,
            alter: 0,
            augmentation_dots: 0,
            duration: 4,
        };
        sig.add_inter(Box::new(h))
    }

    fn mk_keysig(sig: &mut Sig, fifths: i8, system_idx: u32) -> InterId {
        let id = sig.next_inter_id();
        let mut meta = InterMeta::new(
            id,
            InterKind::KeySignature,
            Rect { x: 0, y: 0, w: 30, h: 40 },
            Grade::new(0.9),
        );
        meta.system_idx = Some(system_idx);
        let ks = KeySignatureInter { meta, fifths };
        sig.add_inter(Box::new(ks))
    }

    #[test]
    fn diatonic_head_gets_support_edge() {
        let mut sig = Sig::new();
        // G major (1 sharp): F# IS diatonic
        let _ks = mk_keysig(&mut sig, 1, 0);
        let _h = mk_head(&mut sig, 66, 0); // F#4 (MIDI 66) — diatonic in G major
        let n = add_key_consistency_edges(&mut sig);
        assert_eq!(n, 1);
        let rel = sig.relations().next().unwrap();
        assert!(rel.is_support());
    }

    #[test]
    fn non_diatonic_head_gets_exclusion_edge() {
        let mut sig = Sig::new();
        // G major: F natural is NOT diatonic
        let _ks = mk_keysig(&mut sig, 1, 0);
        let _h = mk_head(&mut sig, 65, 0); // F natural — NOT diatonic in G major
        let n = add_key_consistency_edges(&mut sig);
        assert_eq!(n, 1);
        let rel = sig.relations().next().unwrap();
        assert!(rel.is_exclusion());
        assert_eq!(rel.exclusion_cause(), Some(ExclusionCause::ConsistencyViolation));
    }

    #[test]
    fn no_keysig_means_no_edge() {
        let mut sig = Sig::new();
        let _h = mk_head(&mut sig, 60, 0); // C4
        let n = add_key_consistency_edges(&mut sig);
        assert_eq!(n, 0);
    }

    #[test]
    fn multiple_systems_get_independent_keys() {
        let mut sig = Sig::new();
        let _ks1 = mk_keysig(&mut sig, 0, 0); // C major in system 0
        let _ks2 = mk_keysig(&mut sig, 1, 1); // G major in system 1
        let _h1 = mk_head(&mut sig, 65, 0); // F natural in system 0 — diatonic in C
        let _h2 = mk_head(&mut sig, 65, 1); // F natural in system 1 — NOT in G major
        let n = add_key_consistency_edges(&mut sig);
        assert_eq!(n, 2);
        let mut supports = 0;
        let mut exclusions = 0;
        for rel in sig.relations() {
            if rel.is_support() {
                supports += 1;
            } else {
                exclusions += 1;
            }
        }
        assert_eq!(supports, 1);
        assert_eq!(exclusions, 1);
    }
}
