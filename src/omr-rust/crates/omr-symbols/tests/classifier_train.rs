//! Integration-Test: trainiert auf einem kleinen Subset und prüft
//! Train-Set-Recall pro Klasse.

use omr_symbols::svm_model::{confusion_matrix, per_class_f1, HogSvmClassifier, TrainConfig};
use omr_symbols::templates::{generate_training_corpus, SymbolClass};

#[test]
fn classifier_achieves_acceptable_train_recall() {
    // Klein gehaltener Lauf: 20 Varianten/Klasse, ~10k Iterations.
    // Reicht um zu zeigen dass der Algorithmus konvergiert.
    let corpus = generate_training_corpus(32, 20, 123);
    let cfg = TrainConfig {
        lambda: 1e-4,
        n_iters: 10_000,
        seed: 123,
    };
    let model = HogSvmClassifier::train(&corpus, &cfg);

    let mut preds = Vec::with_capacity(corpus.len());
    let mut truth = Vec::with_capacity(corpus.len());
    for (img, label) in &corpus {
        let (p, _) = model.predict(img);
        preds.push(p);
        truth.push(*label);
    }
    let cm = confusion_matrix(&preds, &truth);
    let f1s = per_class_f1(&cm);

    // Wir akzeptieren ≥ 70% Recall pro Klasse (Train-Set, also Lower Bound auf
    // Lernfähigkeit). Real-Daten-Generalisierung wird im train-classifier-Lauf
    // auf dem Test-Split gemessen.
    let mut failed = Vec::new();
    for (c, _p, r, _f) in &f1s {
        if *r < 0.70 {
            failed.push((*c, *r));
        }
    }
    assert!(
        failed.is_empty(),
        "classes with recall < 70% on training set: {failed:?}"
    );
    let _ = SymbolClass::ALL; // silence unused
}
