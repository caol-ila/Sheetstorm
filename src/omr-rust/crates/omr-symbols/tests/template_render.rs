//! Integrationstests für den Bravura-Template-Renderer.
//!
//! Validiert:
//! - Jede Symbol-Klasse rendert ein 32×32 Patch ungleich leer.
//! - Augmentation ist deterministisch (gleicher Seed → identische Pixel).
//! - Korpus-Generierung liefert die erwartete Sample-Zahl.

use omr_symbols::templates::{
    generate_training_corpus, render_glyph, render_smufl_class_with, SymbolClass, BRAVURA_OTF,
};

const SIZE: u32 = 32;

fn non_empty(img: &image::GrayImage) -> bool {
    img.as_raw().iter().any(|p| *p > 0)
}

#[test]
fn renders_notehead_filled_non_empty() {
    let imgs = render_smufl_class_with(SymbolClass::NoteheadFilled, SIZE, 1, 1);
    assert_eq!(imgs.len(), 1);
    assert_eq!(imgs[0].dimensions(), (SIZE, SIZE));
    assert!(non_empty(&imgs[0]), "Notehead filled darf nicht leer sein");
}

#[test]
fn renders_all_symbol_classes_non_empty() {
    for class in SymbolClass::ALL {
        if matches!(class, SymbolClass::Noise) {
            continue;
        }
        let imgs = render_smufl_class_with(*class, SIZE, 1, 7);
        assert_eq!(imgs.len(), 1, "Klasse {:?}", class);
        assert_eq!(imgs[0].dimensions(), (SIZE, SIZE));
        assert!(
            non_empty(&imgs[0]),
            "Klasse {:?} hat ein leeres Patch erzeugt",
            class
        );
    }
}

#[test]
fn render_glyph_returns_correct_size() {
    let img = render_glyph(BRAVURA_OTF, 0xE0A4, SIZE);
    assert_eq!(img.dimensions(), (SIZE, SIZE));
    assert!(non_empty(&img));
}

#[test]
fn augmentation_is_deterministic_for_same_seed() {
    let a = render_smufl_class_with(SymbolClass::Coda, SIZE, 10, 1234);
    let b = render_smufl_class_with(SymbolClass::Coda, SIZE, 10, 1234);
    assert_eq!(a.len(), b.len());
    for (i, (x, y)) in a.iter().zip(b.iter()).enumerate() {
        assert_eq!(x.as_raw(), y.as_raw(), "Variante {i} unterscheidet sich");
    }
}

#[test]
fn augmentation_differs_for_different_seeds() {
    let a = render_smufl_class_with(SymbolClass::Segno, SIZE, 5, 1);
    let b = render_smufl_class_with(SymbolClass::Segno, SIZE, 5, 2);
    // Basis (Index 0) ist identisch, mind. eine Variante muss abweichen.
    let differs = a
        .iter()
        .skip(1)
        .zip(b.iter().skip(1))
        .any(|(x, y)| x.as_raw() != y.as_raw());
    assert!(
        differs,
        "Verschiedene Seeds müssen unterschiedliche Augmentationen erzeugen"
    );
}

#[test]
fn corpus_has_expected_sample_count() {
    let variants = 5;
    let corpus = generate_training_corpus(SIZE, variants, 99);
    assert_eq!(corpus.len(), SymbolClass::ALL.len() * variants);
    for class in SymbolClass::ALL {
        let n = corpus.iter().filter(|(_, c)| *c == *class).count();
        assert_eq!(n, variants, "Klasse {:?} hat {} Samples", class, n);
    }
}
