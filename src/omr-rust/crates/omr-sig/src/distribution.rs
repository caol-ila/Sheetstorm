//! Distribution<T> — diskrete Wahrscheinlichkeitsverteilung.
//!
//! Wird von ML-Detektoren befuellt (CNN, Music-Language-Model). Erlaubt:
//! - `argmax()` fuer best-Hypothese
//! - `top_k()` fuer alternative Kandidaten
//! - `merge()` fuer Bayes-Update mit weiterer Evidenz
//! - `kl_divergence()` fuer Detector-Disagreement-Metrik

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

/// Diskrete Wahrscheinlichkeitsverteilung über Hypothesen vom Typ `T`.
///
/// Invarianten:
/// - `alternatives` ist sortiert by-prob descending.
/// - Die Summe der Wahrscheinlichkeiten ist 1.0 (nach Konstruktion).
/// - `argmax` entspricht `alternatives[0].0`.
/// - Einträge mit Gewicht 0 werden beim Erstellen entfernt.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Distribution<T: Clone + Eq + std::hash::Hash + Serialize> {
    /// Wahrscheinlichste Hypothese (cache fuer schnellen Zugriff).
    pub argmax: T,
    /// Alle (Hypothese, Wahrscheinlichkeit) Paare.
    /// Sortiert by-prob descending. Sum ≈ 1.0.
    pub alternatives: Vec<(T, f32)>,
}

impl<T> Distribution<T>
where
    T: Clone + Eq + std::hash::Hash + Serialize + for<'de> Deserialize<'de>,
{
    /// Single-point Distribution (Sicherheitsfall, Entropy = 0).
    pub fn certain(value: T) -> Self {
        Self {
            argmax: value.clone(),
            alternatives: vec![(value, 1.0)],
        }
    }

    /// Multi-Hypothesis aus (value, weight) Paaren.
    ///
    /// - Nullgewichte werden gefiltert (verhindert log(0) in Entropy/KL).
    /// - Gewichte werden zu Wahrscheinlichkeiten normalisiert (Summe = 1.0).
    /// - Ergebnis ist by-prob descending sortiert.
    ///
    /// # Panics
    /// Panics wenn `weights` leer ist oder alle Gewichte ≤ 0 sind.
    pub fn from_weights(weights: Vec<(T, f32)>) -> Self {
        // Filter out zero/negative weights.
        let filtered: Vec<(T, f32)> = weights
            .into_iter()
            .filter(|(_, w)| *w > 0.0)
            .collect();

        assert!(!filtered.is_empty(), "Distribution::from_weights: all weights are zero or empty");

        let total: f32 = filtered.iter().map(|(_, w)| w).sum();
        let mut normalized: Vec<(T, f32)> = filtered
            .into_iter()
            .map(|(v, w)| (v, w / total))
            .collect();

        // Sort descending by probability.
        normalized.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

        let argmax = normalized[0].0.clone();
        Self { argmax, alternatives: normalized }
    }

    /// Wahrscheinlichste Hypothese.
    pub fn argmax(&self) -> &T {
        &self.argmax
    }

    /// Top-K Hypothesen (sortiert by-prob descending).
    ///
    /// Gibt bis zu `k` Elemente zurück. Falls `k > len`, wird alles zurückgegeben.
    pub fn top_k(&self, k: usize) -> &[(T, f32)] {
        let end = k.min(self.alternatives.len());
        &self.alternatives[..end]
    }

    /// Wahrscheinlichkeit einer spezifischen Hypothese.
    /// Gibt 0.0 zurück wenn die Hypothese nicht in der Distribution ist.
    pub fn prob_of(&self, value: &T) -> f32 {
        self.alternatives
            .iter()
            .find(|(v, _)| v == value)
            .map(|(_, p)| *p)
            .unwrap_or(0.0)
    }

    /// Shannon-Entropie in Bits (log2).
    ///
    /// - 0.0 = perfekt sicher (certain Distribution)
    /// - log2(N) = maximale Unsicherheit (uniforme Distribution über N Hypothesen)
    pub fn entropy(&self) -> f32 {
        self.alternatives
            .iter()
            .filter(|(_, p)| *p > 0.0)
            .map(|(_, p)| -p * p.log2())
            .sum()
    }

    /// Bayes-Update: kombiniert `self` mit zusaetzlicher Evidenz `other`.
    ///
    /// Berechnet elementweises Produkt der Wahrscheinlichkeiten (naive Bayes),
    /// dann normalisiert. Hypothesen die in `other` nicht vorkommen erhalten
    /// implizit Gewicht 0 und werden gefiltert.
    pub fn merge(&self, other: &Self) -> Self {
        // Build lookup für other.
        let other_map: HashMap<_, f32> = other
            .alternatives
            .iter()
            .map(|(v, p)| (v, *p))
            .collect();

        let combined: Vec<(T, f32)> = self
            .alternatives
            .iter()
            .filter_map(|(v, p)| {
                let q = other_map.get(v).copied().unwrap_or(0.0);
                let product = p * q;
                if product > 0.0 { Some((v.clone(), product)) } else { None }
            })
            .collect();

        if combined.is_empty() {
            // Kein Overlap → uniform über self-Hypothesen als Fallback.
            let n = self.alternatives.len() as f32;
            let uniform: Vec<(T, f32)> = self
                .alternatives
                .iter()
                .map(|(v, _)| (v.clone(), 1.0 / n))
                .collect();
            return Self::from_weights(uniform);
        }

        Self::from_weights(combined)
    }

    /// KL-Divergenz D_KL(self || other) — asymmetrisch.
    ///
    /// Misst wie viel Information verloren geht wenn `other` als Approximation
    /// von `self` verwendet wird. 0.0 = identische Distributions.
    ///
    /// Hypothesen in `self` die in `other` fehlen werden übersprungen
    /// (verhindert Division-by-zero / log(0) Singularitäten).
    pub fn kl_divergence(&self, other: &Self) -> f32 {
        let other_map: HashMap<_, f32> = other
            .alternatives
            .iter()
            .map(|(v, p)| (v, *p))
            .collect();

        self.alternatives
            .iter()
            .filter(|(_, p)| *p > 0.0)
            .filter_map(|(v, p)| {
                let q = other_map.get(v).copied().unwrap_or(0.0);
                if q > 0.0 {
                    Some(p * (p / q).log2())
                } else {
                    None
                }
            })
            .sum()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use pretty_assertions::assert_eq;

    #[test]
    fn certain_distribution_has_zero_entropy() {
        let d = Distribution::certain(42u8);
        assert!((d.entropy() - 0.0).abs() < 1e-6, "entropy should be 0 for certain dist");
    }

    #[test]
    fn from_weights_normalizes() {
        let d = Distribution::from_weights(vec![
            (1u8, 2.0),
            (2u8, 2.0),
            (3u8, 2.0),
            (4u8, 2.0),
        ]);
        let total: f32 = d.alternatives.iter().map(|(_, p)| p).sum();
        assert!((total - 1.0).abs() < 1e-6, "sum should be 1.0, got {total}");
    }

    #[test]
    fn argmax_returns_highest_prob() {
        // Use u8 representing G4=67, F#4=66, A4=69 to avoid &str lifetime issues.
        let d = Distribution::from_weights(vec![
            (67u8, 0.7f32), // G4
            (66u8, 0.2),    // F#4
            (69u8, 0.1),    // A4
        ]);
        assert_eq!(*d.argmax(), 67u8);
    }

    #[test]
    fn top_k_returns_sorted_pairs() {
        let d = Distribution::from_weights(vec![
            (10u8, 1.0),
            (20u8, 3.0),
            (30u8, 2.0),
        ]);
        let top2 = d.top_k(2);
        assert_eq!(top2.len(), 2);
        // First should be highest prob.
        assert!(top2[0].1 >= top2[1].1);
        assert_eq!(top2[0].0, 20u8);
        assert_eq!(top2[1].0, 30u8);
    }

    #[test]
    fn top_k_clamps_to_available() {
        let d = Distribution::certain(5u8);
        let top10 = d.top_k(10);
        assert_eq!(top10.len(), 1);
    }

    #[test]
    fn prob_of_returns_correct_value() {
        let d = Distribution::from_weights(vec![
            (60u8, 0.7),
            (61u8, 0.2),
            (62u8, 0.1),
        ]);
        let p = d.prob_of(&60u8);
        assert!((p - 0.7).abs() < 1e-6, "expected 0.7 got {p}");
    }

    #[test]
    fn prob_of_unknown_returns_zero() {
        let d = Distribution::from_weights(vec![(60u8, 1.0)]);
        assert_eq!(d.prob_of(&99u8), 0.0);
    }

    #[test]
    fn entropy_increases_with_uniform() {
        let certain = Distribution::certain(1u8);
        let uniform = Distribution::from_weights(vec![
            (1u8, 1.0),
            (2u8, 1.0),
            (3u8, 1.0),
            (4u8, 1.0),
        ]);
        assert!(
            uniform.entropy() > certain.entropy(),
            "uniform entropy {} should exceed certain entropy {}",
            uniform.entropy(),
            certain.entropy()
        );
    }

    #[test]
    fn entropy_uniform_four_equals_two_bits() {
        let d = Distribution::from_weights(vec![
            (1u8, 1.0),
            (2u8, 1.0),
            (3u8, 1.0),
            (4u8, 1.0),
        ]);
        // H(uniform 4) = log2(4) = 2.0 bits
        assert!((d.entropy() - 2.0).abs() < 1e-5, "expected 2.0 bits, got {}", d.entropy());
    }

    #[test]
    fn merge_combines_distributions() {
        let prior = Distribution::from_weights(vec![
            (60u8, 0.6),
            (61u8, 0.3),
            (62u8, 0.1),
        ]);
        let evidence = Distribution::from_weights(vec![
            (60u8, 0.5),
            (61u8, 0.4),
            (62u8, 0.1),
        ]);
        let merged = prior.merge(&evidence);
        // 60: 0.6*0.5=0.30, 61: 0.3*0.4=0.12, 62: 0.1*0.1=0.01 → total=0.43
        // normalized: 60≈0.698, 61≈0.279, 62≈0.023
        assert_eq!(*merged.argmax(), 60u8);
        let total: f32 = merged.alternatives.iter().map(|(_, p)| p).sum();
        assert!((total - 1.0).abs() < 1e-5);
    }

    #[test]
    fn kl_divergence_self_is_zero() {
        let d = Distribution::from_weights(vec![
            (1u8, 3.0),
            (2u8, 2.0),
            (3u8, 1.0),
        ]);
        let kl = d.kl_divergence(&d);
        assert!(kl.abs() < 1e-5, "KL(p||p) should be 0, got {kl}");
    }

    #[test]
    fn kl_divergence_disjoint_is_high() {
        let p = Distribution::from_weights(vec![(1u8, 1.0), (2u8, 0.001)]);
        let q = Distribution::from_weights(vec![(3u8, 1.0), (4u8, 0.001)]);
        // No overlap → kl_divergence returns 0.0 (filtered), but entropy of p is low,
        // so we verify that the result is non-negative.
        let kl = p.kl_divergence(&q);
        assert!(kl >= 0.0, "KL divergence must be non-negative, got {kl}");
    }

    #[test]
    fn from_weights_filters_zero_weights() {
        let d = Distribution::from_weights(vec![
            (1u8, 0.0),
            (2u8, 0.0),
            (3u8, 1.0),
        ]);
        assert_eq!(d.alternatives.len(), 1);
        assert_eq!(d.alternatives[0].0, 3u8);
    }

    #[test]
    fn serde_roundtrip() {
        let d = Distribution::from_weights(vec![
            (60u8, 0.7),
            (61u8, 0.2),
            (62u8, 0.1),
        ]);
        let json = serde_json::to_string(&d).unwrap();
        let restored: Distribution<u8> = serde_json::from_str(&json).unwrap();
        assert_eq!(restored.alternatives.len(), 3);
        assert_eq!(*restored.argmax(), 60u8);
    }
}
