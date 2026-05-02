//! Grade-System — Confidence-Werte mit gewichtetem geometrischem Mittel.
//!
//! Inspiriert von Audiveris `GradeImpacts` + `GradeUtil`:
//! - **Intrinsic Grade**: Detektor-Score in [0.0, 1.0]
//! - **GradeImpacts**: gewichteter Vektor benannter Sub-Scores
//!   `score = ∏ impactᵢ^wᵢ`
//! - **Contextual Grade**: durch Nachbar-Inters modifiziert
//!   `cg = (1 + Σcontrib)·g / (1 + Σcontrib·g)`

use serde::{Deserialize, Serialize};

/// Grade in [0.0, 1.0]. Newtype für Type-Safety.
///
/// `0.0` = sicher falsch; `1.0` = sicher richtig. Durchschnittliche
/// Detektor-Confidence liegt bei 0.5..0.9.
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Serialize, Deserialize)]
#[serde(transparent)]
pub struct Grade(f64);

impl Grade {
    /// Schaffe einen Grade. Wert wird in [0.0, 1.0] geclamped.
    pub fn new(v: f64) -> Self {
        Self(v.clamp(0.0, 1.0))
    }
    /// Maximaler Grade (1.0).
    pub fn max() -> Self {
        Self(1.0)
    }
    /// Minimaler Grade (0.0) — Hard-Veto.
    pub fn min() -> Self {
        Self(0.0)
    }
    /// Default-Score wenn nichts genaueres bekannt ist (0.5).
    pub fn unknown() -> Self {
        Self(0.5)
    }
    /// Liefert den f64-Wert.
    pub fn value(&self) -> f64 {
        self.0
    }
    /// Ist der Grade eindeutig "akzeptabel"? (>= threshold)
    pub fn is_acceptable(&self, threshold: f64) -> bool {
        self.0 >= threshold
    }
}

impl Default for Grade {
    fn default() -> Self {
        Self::unknown()
    }
}

/// Gewichtetes geometrisches Mittel benannter Sub-Scores.
///
/// Beispiel — HeadInter könnte Impacts haben:
/// - "template_match"   weight=2.0  value=0.85
/// - "spacing_position" weight=1.0  value=0.95
/// - "stem_proximity"   weight=1.0  value=0.70
///
/// Geometric mean (Audiveris-Formel):
/// ```text
/// global = ∏ impactᵢ^wᵢ
/// score  = intrinsic_ratio · global^(1/Σwᵢ)
/// ```
///
/// Vorteile:
/// - **Hard-Veto**: ein einzelner Impact = 0 → score = 0
/// - **Nachvollziehbar**: jeder Sub-Impact ist benannt + loggbar
/// - **Tunbar**: Gewichte können pro Detektor konfiguriert werden
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GradeImpacts {
    /// Sub-Impact-Namen (für Logging/UI).
    pub names: Vec<String>,
    /// Gewichte pro Sub-Impact.
    pub weights: Vec<f64>,
    /// Werte pro Sub-Impact, in [0.0, 1.0].
    pub values: Vec<f64>,
    /// Multiplikator für intrinsic_ratio (Audiveris: meist 1.0).
    pub intrinsic_ratio: f64,
}

impl GradeImpacts {
    /// Erstellt neue Impacts aus parallelen Slices.
    /// Panics wenn Längen nicht übereinstimmen.
    pub fn new(names: &[&str], weights: &[f64], values: &[f64]) -> Self {
        assert_eq!(names.len(), weights.len(), "names/weights length mismatch");
        assert_eq!(weights.len(), values.len(), "weights/values length mismatch");
        Self {
            names: names.iter().map(|s| s.to_string()).collect(),
            weights: weights.to_vec(),
            values: values.iter().map(|v| v.clamp(0.0, 1.0)).collect(),
            intrinsic_ratio: 1.0,
        }
    }

    /// Berechnet den Grade als geometrisches Mittel.
    pub fn compute(&self) -> Grade {
        if self.values.is_empty() {
            return Grade::unknown();
        }
        let mut global: f64 = 1.0;
        let mut total_weight: f64 = 0.0;
        for (i, &impact) in self.values.iter().enumerate() {
            let weight = self.weights[i];
            total_weight += weight;
            if impact == 0.0 {
                // Hard-Veto: ein Impact = 0 disqualifiziert komplett
                return Grade::min();
            }
            if weight != 0.0 {
                global *= impact.powf(weight);
            }
        }
        if total_weight == 0.0 {
            return Grade::unknown();
        }
        let v = self.intrinsic_ratio * global.powf(1.0 / total_weight);
        Grade::new(v)
    }
}

/// Audiveris contextual-grade Formel:
///
/// ```text
/// cg = (1 + contribution) · intrinsic_grade
///      ─────────────────────────────────────
///      1 + contribution · intrinsic_grade
/// ```
///
/// `contribution` ist die Summe aller Support-Edge-Beiträge (Σ partner_grade · (ratio-1)).
/// Resultiert in einem Grade ≥ intrinsic, monoton steigend in contribution.
pub fn contextual_grade(intrinsic: Grade, contribution: f64) -> Grade {
    let g = intrinsic.value();
    let c = contribution.max(0.0);
    let cg = ((1.0 + c) * g) / (1.0 + c * g);
    Grade::new(cg)
}

#[cfg(test)]
mod tests {
    use super::*;
    use pretty_assertions::assert_eq;

    #[test]
    fn empty_impacts_is_unknown() {
        let impacts = GradeImpacts::new(&[], &[], &[]);
        assert_eq!(impacts.compute(), Grade::unknown());
    }

    #[test]
    fn zero_impact_is_hard_veto() {
        let impacts = GradeImpacts::new(
            &["a", "b", "c"],
            &[1.0, 1.0, 1.0],
            &[0.9, 0.0, 0.95], // mittlerer ist Veto
        );
        assert_eq!(impacts.compute(), Grade::min());
    }

    #[test]
    fn equal_weights_is_geometric_mean() {
        let impacts = GradeImpacts::new(
            &["a", "b"],
            &[1.0, 1.0],
            &[0.9, 0.9],
        );
        // Geometric mean of 0.9, 0.9 = 0.9
        assert!((impacts.compute().value() - 0.9).abs() < 1e-6);
    }

    #[test]
    fn higher_weight_dominates() {
        // Hohes Gewicht auf 0.5, niedriges auf 0.9
        let dominated = GradeImpacts::new(
            &["primary", "secondary"],
            &[3.0, 1.0],
            &[0.5, 0.9],
        );
        let g = dominated.compute().value();
        // Sollte näher an 0.5 als an 0.9 liegen
        assert!(g < 0.7);
        assert!(g > 0.55);
    }

    #[test]
    fn contextual_zero_contribution_returns_intrinsic() {
        let g = contextual_grade(Grade::new(0.7), 0.0);
        assert!((g.value() - 0.7).abs() < 1e-9);
    }

    #[test]
    fn contextual_increases_with_contribution() {
        let baseline = contextual_grade(Grade::new(0.5), 0.0).value();
        let with_support = contextual_grade(Grade::new(0.5), 0.5).value();
        let strong_support = contextual_grade(Grade::new(0.5), 1.0).value();
        assert!(baseline < with_support);
        assert!(with_support < strong_support);
    }

    #[test]
    fn contextual_cant_exceed_one() {
        for c in [0.0, 0.5, 1.0, 5.0, 100.0] {
            let g = contextual_grade(Grade::new(0.99), c);
            assert!(g.value() <= 1.0);
        }
    }
}
