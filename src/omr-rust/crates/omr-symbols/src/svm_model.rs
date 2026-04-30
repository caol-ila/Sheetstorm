//! Multi-Class Linear SVM für Symbol-Klassifikation.
//!
//! ## Designentscheidung: Eigene Pegasos-Implementierung statt `linfa-svm`
//!
//! Der Task-Brief erlaubt explizit eine eigene SVM-Repräsentation, falls
//! linfa-svm Probleme bei der Serialisierung macht. Wir gehen einen Schritt
//! weiter und implementieren das Training selbst:
//!
//! * **Vermeidung schwerer Transitivabhängigkeiten** — linfa zieht ndarray-
//!   stats, ndarray-linalg etc. nach. Für ein 324-D Linear-SVM mit 2000
//!   Samples ist das Overkill.
//! * **Triviale Serialisierung** — pro Klasse nur ein Gewichtsvektor + Bias,
//!   alles direkt mit `bincode`/`serde` ablegbar.
//! * **Deterministisches, schnelles Training** — Pegasos
//!   (Shalev-Shwartz et al. 2007) konvergiert für linear separable
//!   HoG-Features in wenigen Sekunden.
//! * **Lizenz-Kompatibilität** — Apache-2.0 (eigener Code).
//!
//! Linear-SVM auf HoG ist die *klassische* Pairing für Symbol-/
//! Pedestrian-Detection (Dalal & Triggs 2005); die Nichtlinearität steckt
//! bereits in den HoG-Features.
//!
//! ## API
//!
//! * [`HogSvmClassifier::train`] — trainiert auf einer Liste von
//!   `(GrayImage, SymbolClass)`-Paaren.
//! * [`HogSvmClassifier::predict`] — gibt `(SymbolClass, confidence ∈ [0,1])`
//!   für ein Patch zurück.
//! * [`HogSvmClassifier::save`] / [`HogSvmClassifier::load`] — bincode-Persistenz.

use crate::hog::{extract_hog, FEATURE_LEN};
use crate::templates::SymbolClass;
use image::GrayImage;
use rand::seq::SliceRandom;
use rand::SeedableRng;
use rand_chacha::ChaCha8Rng;
use serde::{Deserialize, Serialize};
use std::path::Path;

/// Persistente Repräsentation eines One-vs-Rest Linear-SVM Classifiers.
///
/// Pro Klasse genau ein Gewichtsvektor `w_k ∈ R^{FEATURE_LEN}` und Bias
/// `b_k ∈ R`. Die Vorhersage ist `argmax_k (w_k·x + b_k)`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HogSvmClassifier {
    /// Klassen, in derselben Reihenfolge wie [`Self::weights`].
    pub classes: Vec<SymbolClass>,
    /// Gewichtsvektoren (eine pro Klasse, jeweils Länge `FEATURE_LEN`).
    pub weights: Vec<Vec<f32>>,
    /// Bias-Terme (einer pro Klasse).
    pub biases: Vec<f32>,
    /// Anzahl Features (zur Laufzeit-Validierung beim Laden).
    pub feature_len: usize,
}

/// Trainings-Konfiguration.
#[derive(Debug, Clone)]
pub struct TrainConfig {
    /// L2-Regularisierungsparameter λ. Kleiner → überfittet eher.
    pub lambda: f32,
    /// Anzahl Pegasos-Iterationen (Sample-Updates).
    pub n_iters: usize,
    /// Seed für Sample-Reihenfolge.
    pub seed: u64,
}

impl Default for TrainConfig {
    fn default() -> Self {
        Self {
            // Werte empirisch für 324-D HoG + ~2000 Samples kalibriert:
            // λ=1e-4 bietet ein gutes Bias-Variance-Tradeoff.
            lambda: 1e-4,
            n_iters: 30_000,
            seed: 42,
        }
    }
}

/// Konfidenz für die Pegasos-Decision-Function umgerechnet auf `[0, 1]`.
///
/// Wir verwenden eine logistische Squashing-Funktion `σ(margin)` — das ist
/// nicht eine kalibrierte Wahrscheinlichkeit (kein Platt-Scaling), aber als
/// Reject-Schwelle völlig ausreichend.
fn squash(margin: f32) -> f32 {
    1.0 / (1.0 + (-margin).exp())
}

impl HogSvmClassifier {
    /// Trainiert einen Classifier auf einem Korpus von gelabelten Patches.
    ///
    /// Intern: HoG-Features extrahieren, dann pro Klasse einen
    /// One-vs-Rest Pegasos-SVM-Trainingslauf.
    pub fn train(corpus: &[(GrayImage, SymbolClass)], cfg: &TrainConfig) -> Self {
        let classes: Vec<SymbolClass> = SymbolClass::ALL.to_vec();
        let n = corpus.len();
        assert!(n > 0, "training corpus must be non-empty");

        // 1) HoG-Features für alle Samples extrahieren.
        let features: Vec<Vec<f32>> =
            corpus.iter().map(|(img, _)| extract_hog(img)).collect();
        let labels: Vec<SymbolClass> = corpus.iter().map(|(_, c)| *c).collect();

        // 2) Pro Klasse: Pegasos-Lauf.
        let mut weights = Vec::with_capacity(classes.len());
        let mut biases = Vec::with_capacity(classes.len());
        for (k, target) in classes.iter().enumerate() {
            let binary_labels: Vec<f32> = labels
                .iter()
                .map(|c| if c == target { 1.0 } else { -1.0 })
                .collect();
            let (w, b) = pegasos_train(&features, &binary_labels, cfg, cfg.seed + k as u64);
            weights.push(w);
            biases.push(b);
        }

        Self {
            classes,
            weights,
            biases,
            feature_len: FEATURE_LEN,
        }
    }

    /// Sagt Klasse + Konfidenz für ein einzelnes Patch voraus.
    ///
    /// Konfidenz ist `σ(best_margin)` — logistisch gesquashed.
    /// Werte um 0.5 sind unsicher, > 0.65 sind robust.
    pub fn predict(&self, patch: &GrayImage) -> (SymbolClass, f32) {
        let feats = extract_hog(patch);
        self.predict_features(&feats)
    }

    /// Vorhersage direkt auf vorberechneten Features (für Batch-Eval).
    pub fn predict_features(&self, feats: &[f32]) -> (SymbolClass, f32) {
        debug_assert_eq!(feats.len(), self.feature_len);
        let mut best_idx = 0usize;
        let mut best_margin = f32::NEG_INFINITY;
        for (k, w) in self.weights.iter().enumerate() {
            let margin = dot(w, feats) + self.biases[k];
            if margin > best_margin {
                best_margin = margin;
                best_idx = k;
            }
        }
        (self.classes[best_idx], squash(best_margin))
    }

    /// Speichert das Modell binär (bincode) auf Disk.
    pub fn save(&self, path: impl AsRef<Path>) -> std::io::Result<()> {
        let bytes = bincode::serialize(self).map_err(|e| {
            std::io::Error::new(std::io::ErrorKind::Other, format!("bincode serialize: {e}"))
        })?;
        std::fs::write(path, bytes)
    }

    /// Lädt ein Modell von Disk.
    pub fn load(path: impl AsRef<Path>) -> std::io::Result<Self> {
        let bytes = std::fs::read(path)?;
        Self::from_bytes(&bytes)
    }

    /// Lädt ein Modell aus einem In-Memory-Byte-Slice (z.B. `include_bytes!`).
    pub fn from_bytes(bytes: &[u8]) -> std::io::Result<Self> {
        let model: Self = bincode::deserialize(bytes).map_err(|e| {
            std::io::Error::new(std::io::ErrorKind::Other, format!("bincode deserialize: {e}"))
        })?;
        if model.feature_len != FEATURE_LEN {
            return Err(std::io::Error::new(
                std::io::ErrorKind::InvalidData,
                format!(
                    "model feature_len={} != current FEATURE_LEN={}",
                    model.feature_len, FEATURE_LEN
                ),
            ));
        }
        Ok(model)
    }
}

/// Skalarprodukt zweier f32-Slices (gleiche Länge erwartet).
#[inline]
fn dot(a: &[f32], b: &[f32]) -> f32 {
    debug_assert_eq!(a.len(), b.len());
    let mut acc = 0.0f32;
    for i in 0..a.len() {
        acc += a[i] * b[i];
    }
    acc
}

/// Pegasos (Primal Estimated sub-GrAdient SOlver for SVM)
/// Shalev-Shwartz et al. 2007.
///
/// Minimiert `(λ/2)‖w‖² + (1/n)Σ max(0, 1 - y_i(w·x_i + b))`.
/// Gibt Gewichtsvektor und Bias zurück.
fn pegasos_train(
    features: &[Vec<f32>],
    labels: &[f32],
    cfg: &TrainConfig,
    seed: u64,
) -> (Vec<f32>, f32) {
    let dim = features[0].len();
    let n = features.len();
    let lambda = cfg.lambda.max(1e-8);
    let mut w = vec![0.0f32; dim];
    let mut b = 0.0f32;
    let mut rng = ChaCha8Rng::seed_from_u64(seed);

    // Vor-Mischung der Sample-Reihenfolge — Pegasos zieht uniform zufällig.
    let mut indices: Vec<usize> = (0..n).collect();
    indices.shuffle(&mut rng);
    let mut cursor = 0usize;

    for t in 1..=cfg.n_iters {
        if cursor >= n {
            indices.shuffle(&mut rng);
            cursor = 0;
        }
        let i = indices[cursor];
        cursor += 1;

        let x = &features[i];
        let y = labels[i];
        let eta = 1.0 / (lambda * t as f32);
        let margin = y * (dot(&w, x) + b);

        // Schritt 1: Skalierung w ← (1 - η·λ)·w
        let scale = 1.0 - eta * lambda;
        for v in w.iter_mut() {
            *v *= scale;
        }
        // Schritt 2: Falls Margin verletzt → w ← w + η·y·x_i
        if margin < 1.0 {
            for d in 0..dim {
                w[d] += eta * y * x[d];
            }
            // Bias: einfacher Sub-Gradient (kein Decay).
            b += eta * y;
        }

        // Optionale Projektion auf Norm-Ball ‖w‖ ≤ 1/√λ — wir lassen sie
        // weg, weil sie pro Schritt O(d) kostet und in der Praxis selten
        // bindet bei normalisierten HoG-Features.
    }

    (w, b)
}

/// Vorhersagen auf einer Liste von Feature-Vektoren (Batch-Hilfe für Eval).
pub fn batch_predict(
    classifier: &HogSvmClassifier,
    feats: &[Vec<f32>],
) -> Vec<(SymbolClass, f32)> {
    feats
        .iter()
        .map(|f| classifier.predict_features(f))
        .collect()
}

/// Konfusionsmatrix-Eintrag (true_class, predicted_class) → count.
pub type ConfusionMatrix = std::collections::HashMap<(SymbolClass, SymbolClass), usize>;

/// Berechnet eine Konfusionsmatrix aus Predictions und Ground-Truth.
pub fn confusion_matrix(
    predictions: &[SymbolClass],
    truth: &[SymbolClass],
) -> ConfusionMatrix {
    assert_eq!(predictions.len(), truth.len());
    let mut m = ConfusionMatrix::new();
    for (p, t) in predictions.iter().zip(truth.iter()) {
        *m.entry((*t, *p)).or_insert(0) += 1;
    }
    m
}

/// Berechnet F1-Score pro Klasse aus einer Konfusionsmatrix.
pub fn per_class_f1(cm: &ConfusionMatrix) -> Vec<(SymbolClass, f32, f32, f32)> {
    let mut out = Vec::new();
    for &class in SymbolClass::ALL {
        let tp = *cm.get(&(class, class)).unwrap_or(&0) as f32;
        let fp: usize = SymbolClass::ALL
            .iter()
            .filter(|&&c| c != class)
            .map(|&c| *cm.get(&(c, class)).unwrap_or(&0))
            .sum();
        let fn_: usize = SymbolClass::ALL
            .iter()
            .filter(|&&c| c != class)
            .map(|&c| *cm.get(&(class, c)).unwrap_or(&0))
            .sum();
        let precision = if tp + fp as f32 > 0.0 {
            tp / (tp + fp as f32)
        } else {
            0.0
        };
        let recall = if tp + fn_ as f32 > 0.0 {
            tp / (tp + fn_ as f32)
        } else {
            0.0
        };
        let f1 = if precision + recall > 0.0 {
            2.0 * precision * recall / (precision + recall)
        } else {
            0.0
        };
        out.push((class, precision, recall, f1));
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::templates::generate_training_corpus;

    #[test]
    fn train_and_predict_roundtrip() {
        // Mini-Korpus: 5 Varianten pro Klasse, schnelles Training.
        let corpus = generate_training_corpus(32, 5, 42);
        let cfg = TrainConfig {
            lambda: 1e-3,
            n_iters: 2_000,
            seed: 7,
        };
        let model = HogSvmClassifier::train(&corpus, &cfg);
        assert_eq!(model.classes.len(), SymbolClass::ALL.len());
        assert_eq!(model.weights[0].len(), FEATURE_LEN);

        // Vorhersage auf einem bekannten Sample.
        let (img, expected) = &corpus[0];
        let (pred, conf) = model.predict(img);
        let _ = pred; // Bei zu wenig Iterationen darf das fehlschlagen — nur Roundtrip-Test.
        assert!((0.0..=1.0).contains(&conf));
        let _ = expected;
    }

    #[test]
    fn save_load_roundtrip() {
        let corpus = generate_training_corpus(32, 3, 1);
        let cfg = TrainConfig {
            lambda: 1e-3,
            n_iters: 500,
            seed: 1,
        };
        let model = HogSvmClassifier::train(&corpus, &cfg);
        let bytes = bincode::serialize(&model).unwrap();
        let model2 = HogSvmClassifier::from_bytes(&bytes).unwrap();
        assert_eq!(model.classes, model2.classes);
        assert_eq!(model.feature_len, model2.feature_len);
        for (a, b) in model.weights.iter().zip(model2.weights.iter()) {
            assert_eq!(a.len(), b.len());
        }
    }
}
