//! HeadInterMulti — HeadInter mit Multi-Hypothesis-Distributions.
//!
//! Ergaenzt das existierende `HeadInter` (single pitch/duration) um
//! Distributions, die ML-Detektoren befuellen koennen. Ermoeglicht
//! graph-basiertes Re-Ranking und Active-Learning-Kandidaten-Selektion.

use omr_core::{NoteheadKind, Point};
use serde::{Deserialize, Serialize};

use crate::distribution::Distribution;
use crate::inter::{Inter, InterId, InterMeta};
use crate::inters::HeadInter;

/// HeadInter mit Multi-Hypothesis-Distributions fuer Pitch und Duration.
///
/// Statt eines einzelnen MIDI-Werts und einer Duration traegt jeder Inter
/// eine vollständige Wahrscheinlichkeitsverteilung. `midi()` und `duration()`
/// geben jeweils den `argmax` zurück — identisch zum klassischen `HeadInter`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeadInterMulti {
    /// Gemeinsame Inter-Metadaten.
    pub meta: InterMeta,
    /// Bbox-Center in Pixel-Koordinaten.
    pub center: Point<f32>,
    /// Filled / Open / Whole.
    pub notehead_kind: NoteheadKind,

    /// Multi-Hypothesis Pitch (MIDI 0..127). `argmax` wird in `midi()` gespiegelt.
    pub pitch_distribution: Distribution<u8>,
    /// Multi-Hypothesis Duration (1=16th, 2=8th, 4=quarter, 8=half, 16=whole).
    pub duration_distribution: Distribution<u32>,
    /// Optional: Accidental-Distribution (-2..2).
    pub accidental_distribution: Option<Distribution<i8>>,

    /// Octave-Nummer (4 = mittlere Oktave).
    pub octave: i8,
    /// Punktierung (0/1/2).
    pub augmentation_dots: u8,
}

impl Inter for HeadInterMulti {
    fn meta(&self) -> &InterMeta {
        &self.meta
    }
    fn meta_mut(&mut self) -> &mut InterMeta {
        &mut self.meta
    }
    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any {
        self
    }
}

impl HeadInterMulti {
    /// Erstellt einen `HeadInterMulti` aus einem einzelnen `HeadInter`.
    ///
    /// Pitch und Duration werden als `certain` Distributions kodiert
    /// (Entropie = 0), was dem bisherigen Verhalten entspricht.
    pub fn from_single(head: &HeadInter) -> Self {
        Self {
            meta: head.meta.clone(),
            center: head.center,
            notehead_kind: head.notehead_kind,
            pitch_distribution: Distribution::certain(head.midi),
            duration_distribution: Distribution::certain(head.duration),
            accidental_distribution: None,
            octave: head.octave,
            augmentation_dots: head.augmentation_dots,
        }
    }

    /// Erstellt einen `HeadInterMulti` mit expliziten Distributions.
    pub fn new(
        id: InterId,
        meta: InterMeta,
        center: Point<f32>,
        notehead_kind: NoteheadKind,
        pitch_distribution: Distribution<u8>,
        duration_distribution: Distribution<u32>,
    ) -> Self {
        let _ = id; // ID ist bereits in meta enthalten.
        Self {
            meta,
            center,
            notehead_kind,
            pitch_distribution,
            duration_distribution,
            accidental_distribution: None,
            octave: 4,
            augmentation_dots: 0,
        }
    }

    /// Convenience: argmax MIDI-Pitch.
    pub fn midi(&self) -> u8 {
        *self.pitch_distribution.argmax()
    }

    /// Convenience: argmax Duration.
    pub fn duration(&self) -> u32 {
        *self.duration_distribution.argmax()
    }

    /// Hat dieser Inter unsichere Hypothese?
    ///
    /// Gibt `true` zurück wenn Pitch- oder Duration-Entropy den Schwellwert
    /// überschreitet — diese Inters sind gute Kandidaten fuer User-Annotation
    /// (Active Learning).
    pub fn is_uncertain(&self, entropy_threshold: f32) -> bool {
        self.pitch_distribution.entropy() > entropy_threshold
            || self.duration_distribution.entropy() > entropy_threshold
    }
}

/// Findet die Inters mit höchster Pitch-Entropy — gute Kandidaten fuer User-Annotation.
///
/// Gibt bis zu `n` `InterId`s zurück, sortiert by-entropy descending.
/// Nur `HeadInterMulti`-Inters werden betrachtet.
pub fn find_uncertain_inters(sig: &crate::sig::Sig, n: usize) -> Vec<InterId> {
    let mut scored: Vec<(InterId, f32)> = sig
        .inters()
        .filter_map(|inter| {
            inter
                .as_any()
                .downcast_ref::<HeadInterMulti>()
                .map(|h| {
                    let entropy = h.pitch_distribution.entropy() + h.duration_distribution.entropy();
                    (h.meta.id, entropy)
                })
        })
        .collect();

    scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    scored.into_iter().take(n).map(|(id, _)| id).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{NoteheadKind, Point, Rect};
    use pretty_assertions::assert_eq;

    use crate::distribution::Distribution;
    use crate::grade::Grade;
    use crate::inter::{InterId, InterKind, InterMeta};
    use crate::inters::HeadInter;

    fn dummy_head_inter(id: u64, midi: u8, duration: u32) -> HeadInter {
        let bounds = Rect { x: 10, y: 20, w: 8, h: 8 };
        let meta = InterMeta::new(InterId(id), InterKind::Head, bounds, Grade::new(0.8));
        HeadInter {
            meta,
            center: Point { x: 14.0, y: 24.0 },
            notehead_kind: NoteheadKind::Filled,
            midi,
            step: omr_core::PitchStep::C,
            octave: 4,
            alter: 0,
            augmentation_dots: 0,
            duration,
        }
    }

    #[test]
    fn headinter_multi_from_single_has_certain_dist() {
        let head = dummy_head_inter(1, 60, 4);
        let multi = HeadInterMulti::from_single(&head);

        // argmax must match original values.
        assert_eq!(multi.midi(), 60u8);
        assert_eq!(multi.duration(), 4u32);

        // Certain distributions have zero entropy.
        assert!(
            multi.pitch_distribution.entropy().abs() < 1e-6,
            "pitch entropy should be 0, got {}",
            multi.pitch_distribution.entropy()
        );
        assert!(
            multi.duration_distribution.entropy().abs() < 1e-6,
            "duration entropy should be 0, got {}",
            multi.duration_distribution.entropy()
        );
    }

    #[test]
    fn headinter_multi_uncertain_detection() {
        let bounds = Rect { x: 0, y: 0, w: 8, h: 8 };
        let meta = InterMeta::new(InterId(2), InterKind::Head, bounds, Grade::new(0.5));
        let pitch_dist = Distribution::from_weights(vec![
            (60u8, 0.4),
            (61u8, 0.35),
            (62u8, 0.25),
        ]);
        let dur_dist = Distribution::certain(4u32);

        let multi = HeadInterMulti {
            meta,
            center: Point { x: 4.0, y: 4.0 },
            notehead_kind: NoteheadKind::Filled,
            pitch_distribution: pitch_dist,
            duration_distribution: dur_dist,
            accidental_distribution: None,
            octave: 4,
            augmentation_dots: 0,
        };

        // With a loose threshold, uncertain should be detected.
        assert!(multi.is_uncertain(0.5), "expected uncertain with entropy > 0.5");
        // With a very tight threshold, it should pass as certain.
        assert!(!multi.is_uncertain(10.0), "expected certain with entropy < 10.0");
    }

    #[test]
    fn headinter_multi_midi_returns_argmax() {
        let head = dummy_head_inter(3, 69, 8); // A4, half
        let multi = HeadInterMulti::from_single(&head);
        assert_eq!(multi.midi(), 69u8);
        assert_eq!(multi.duration(), 8u32);
    }

    #[test]
    fn headinter_multi_implements_inter_trait() {
        let head = dummy_head_inter(4, 60, 4);
        let multi = HeadInterMulti::from_single(&head);
        let inter: &dyn Inter = &multi;
        assert_eq!(inter.kind(), InterKind::Head);
    }

    #[test]
    fn headinter_multi_serde_roundtrip() {
        let head = dummy_head_inter(5, 60, 4);
        let multi = HeadInterMulti::from_single(&head);
        let json = serde_json::to_string(&multi).unwrap();
        let restored: HeadInterMulti = serde_json::from_str(&json).unwrap();
        assert_eq!(restored.midi(), 60u8);
        assert_eq!(restored.duration(), 4u32);
    }

    #[test]
    fn accidental_distribution_optional() {
        let head = dummy_head_inter(6, 61, 4); // C#4
        let mut multi = HeadInterMulti::from_single(&head);
        assert!(multi.accidental_distribution.is_none());

        // Assign an accidental distribution.
        multi.accidental_distribution = Some(Distribution::from_weights(vec![
            (1i8, 0.8),
            (0i8, 0.2),
        ]));
        assert!(multi.accidental_distribution.is_some());
        assert_eq!(*multi.accidental_distribution.as_ref().unwrap().argmax(), 1i8);
    }
}
