//! End-to-End-Test für den Active-Learning-Loop.
//!
//! Testet den vollständigen Zyklus:
//!   Synthethisches Label → HNSW-Index → k-NN-Abfrage → niedrige Entropie.

use image::{GrayImage, Luma};
use omr_labeler::embedding_corpus::EmbeddingState;

fn make_patch_png(pixel: u8) -> Vec<u8> {
    let img = GrayImage::from_pixel(64, 64, Luma([pixel]));
    let mut buf = Vec::new();
    img.write_to(
        &mut std::io::Cursor::new(&mut buf),
        image::ImageFormat::Png,
    )
    .unwrap();
    buf
}

#[tokio::test]
async fn full_active_learning_cycle() {
    // 1. Leeren In-Memory-Zustand initialisieren.
    let mut state = EmbeddingState::new().expect("EmbeddingState::new()");

    // 2. Fünf Patches als "notehead-filled" labeln.
    for i in 0..5u8 {
        let png = make_patch_png(100 + i * 10);
        state
            .add_user_label(
                "notehead-filled".to_string(),
                png,
                format!("test-patch-{i}"),
            )
            .expect("add_user_label");
    }

    // 3. Index hat mindestens 5 Einträge.
    let stats = state.corpus_stats();
    assert_eq!(stats["total"], 5, "Corpus sollte 5 Einträge haben");
    assert_eq!(stats["user"], 5, "Alle Einträge sollten User-Herkunft haben");

    // 4. k-NN-Abfrage: ähnlicher Patch sollte "notehead-filled" zurückgeben.
    let query_png = make_patch_png(105); // zwischen den trainierten Patches
    let top1 = state
        .knn_classify(&query_png)
        .expect("knn_classify sollte Some(Match) liefern");
    assert_eq!(
        top1.label, "notehead-filled",
        "Top-1 sollte 'notehead-filled' sein, nicht '{}'",
        top1.label
    );

    // 5. Entropie ist niedrig (alle Einträge in einer Klasse → H = 0).
    let entropy = state.entropy();
    assert!(
        entropy < 1e-6,
        "Single-Class-Entropie sollte ≈0 sein, ist aber {entropy}"
    );
}

#[tokio::test]
async fn multi_class_increases_entropy() {
    let mut state = EmbeddingState::new().expect("EmbeddingState::new()");

    // Vier verschiedene Klassen mit je einem Patch.
    let classes = ["notehead-filled", "notehead-open", "rest-quarter", "rest-half"];
    for (i, class) in classes.iter().enumerate() {
        let png = make_patch_png(50 + i as u8 * 50);
        state
            .add_user_label(class.to_string(), png, format!("patch-{i}"))
            .expect("add_user_label");
    }

    let entropy = state.entropy();
    // 4 gleichmäßige Klassen → H ≈ 2 Bits
    assert!(
        entropy > 1.9,
        "Balanced 4-class entropy sollte ~2 bits sein, ist {entropy}"
    );
}

#[tokio::test]
async fn empty_state_knn_returns_none() {
    let mut state = EmbeddingState::new().expect("EmbeddingState::new()");
    let png = make_patch_png(128);
    let result = state.knn_classify(&png);
    // Leerer Index → kein Match
    assert!(result.is_none(), "Leerer Index sollte None zurückgeben");
}
