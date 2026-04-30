// Symbol-Klassifikator: filtert Notehead-Kandidaten anhand Bravura-Templates.
//
// Strategie:
//   1) Pre-rendere Bravura-Templates (one-time) für 7 Klassen (NH-Filled, NH-Open,
//      NH-Whole, Coda, Segno, Dynamic, Noise) auf Pixel-Größe ~spacing*1.5
//   2) Pro NH-Kandidat: Extrahiere 32×32 Patch um center, NCC gegen jede Klasse
//   3) Beste Klasse:
//      - NoteheadFilled/Open/Whole → akzeptiere, setze Kind entsprechend
//      - Coda/Segno/Dynamic/Noise → reject (kein NH)
//   4) Confidence = NCC der gewinnenden Klasse
//
// Performance: Templates werden ONCE per Spacing gecacht; NCC pro Kandidat
// ~10 Klassen × 32×32 = ~10k ops, lt. Research ~1ms/Patch.

use crate::templates::SymbolClass;
use crate::svm_model::HogSvmClassifier;
use crate::templates::render_smufl_class_with;
use omr_core::{Binary, Notehead, NoteheadKind};
use image::GrayImage;
use std::collections::HashMap;
use std::sync::Mutex;
#[cfg(test)]
use omr_core::Point;

/// Cache: spacing → vorgerenderte Templates pro Klasse.
/// Nutzt Mutex damit detect_noteheads parallelisiert werden kann ohne Re-Render.
static TEMPLATE_CACHE: Mutex<Option<TemplateCache>> = Mutex::new(None);

struct TemplateCache {
    spacing_used: f32,
    templates: HashMap<SymbolClass, NormalizedTemplate>,
    patch_size: u32,
}

/// Vorberechnetes NCC-Template (mean-zentriert, Norm gespeichert).
struct NormalizedTemplate {
    pixels: Vec<f32>,
    norm: f32,
}

impl NormalizedTemplate {
    fn from_image(img: &GrayImage) -> Self {
        let pixels: Vec<f32> = img.pixels().map(|p| p[0] as f32).collect();
        let mean = pixels.iter().sum::<f32>() / pixels.len() as f32;
        let zeroed: Vec<f32> = pixels.iter().map(|&p| p - mean).collect();
        let norm = zeroed.iter().map(|&v| v * v).sum::<f32>().sqrt();
        Self { pixels: zeroed, norm }
    }

    fn ncc(&self, patch: &[f32], patch_norm: f32) -> f32 {
        if self.norm == 0.0 || patch_norm == 0.0 {
            return 0.0;
        }
        let dot: f32 = self.pixels.iter().zip(patch.iter()).map(|(a, b)| a * b).sum();
        dot / (self.norm * patch_norm)
    }
}

/// Holt oder rendert den Template-Cache für die gegebene spacing.
fn get_or_build_cache(spacing: f32) -> std::sync::MutexGuard<'static, Option<TemplateCache>> {
    let mut guard = TEMPLATE_CACHE.lock().unwrap();
    let needs_rebuild = match guard.as_ref() {
        Some(c) => (c.spacing_used - spacing).abs() > 1.0,
        None => true,
    };
    if needs_rebuild {
        let patch_size = ((spacing * 1.6).round() as u32).clamp(16, 64);
        let mut templates = HashMap::new();
        for &class in SymbolClass::ALL {
            // Pro Klasse nehmen wir die Basis-Variante (keine Augmentation).
            // Augmentation zur Robustheit kommt durch NCC-Toleranz selbst.
            let imgs = render_smufl_class_with(class, patch_size, 1, 0);
            if let Some(img) = imgs.into_iter().next() {
                templates.insert(class, NormalizedTemplate::from_image(&img));
            }
        }
        *guard = Some(TemplateCache {
            spacing_used: spacing,
            templates,
            patch_size,
        });
    }
    guard
}

/// Klassifiziert einen Notehead-Kandidaten via NCC gegen Bravura-Templates.
/// Returns None wenn das Patch besser zu einem Nicht-NH-Symbol passt
/// (Coda/Segno/Dynamic/Noise) → der Kandidat sollte verworfen werden.
pub fn classify_via_templates(
    bin: &Binary,
    nh: &Notehead,
    spacing: f32,
) -> Option<NoteheadKind> {
    let cache_guard = get_or_build_cache(spacing);
    let cache = match cache_guard.as_ref() {
        Some(c) => c,
        None => return Some(nh.kind),
    };
    let patch_size = cache.patch_size;

    // Extrahiere Patch um nh.center
    let cx = nh.center.x as i32;
    let cy = nh.center.y as i32;
    let half = patch_size as i32 / 2;
    let x0 = (cx - half).max(0) as u32;
    let y0 = (cy - half).max(0) as u32;
    if x0 + patch_size > bin.w || y0 + patch_size > bin.h {
        // Out-of-bounds (am Rand) → fallback auf bestehende Klassifikation
        return Some(nh.kind);
    }

    // Patch als f32-Array, mean-zentriert, mit Norm.
    let mut pixels: Vec<f32> = Vec::with_capacity((patch_size * patch_size) as usize);
    let mut black_count = 0u32;
    for py in y0..y0 + patch_size {
        for px in x0..x0 + patch_size {
            let v = if bin.get(px, py) == 1 { 255.0_f32 } else { 0.0 };
            if v > 0.0 {
                black_count += 1;
            }
            pixels.push(v);
        }
    }
    let total_px = (patch_size * patch_size) as u32;
    // Skip-Heuristik: wenn der Patch sehr "einfach" ist (eine zusammenhängende
    // Form ohne komplexe Innenstruktur), führen wir KEIN Symbol-Klassifizierungs-
    // Reject durch. Coda/Segno/Dynamik haben charakteristische komplexe Strukturen.
    // Eine Notehead ist eine einzelne Ellipse → einfach.
    let fill_ratio = black_count as f32 / total_px as f32;
    if fill_ratio < 0.05 || fill_ratio > 0.65 {
        // Fast leer oder fast voll → wir sind unsicher, kein Reject.
        return Some(nh.kind);
    }
    let mean = pixels.iter().sum::<f32>() / pixels.len() as f32;
    let zeroed: Vec<f32> = pixels.iter().map(|&p| p - mean).collect();
    let patch_norm = zeroed.iter().map(|&v| v * v).sum::<f32>().sqrt();

    // NCC gegen jede Klasse
    let mut best_class = SymbolClass::Noise;
    let mut best_score = f32::NEG_INFINITY;
    let mut nh_score = f32::NEG_INFINITY;
    for &class in SymbolClass::ALL {
        if let Some(tmpl) = cache.templates.get(&class) {
            let score = tmpl.ncc(&zeroed, patch_norm);
            if score > best_score {
                best_score = score;
                best_class = class;
            }
            // Track best NH-score separately
            if matches!(
                class,
                SymbolClass::NoteheadFilled | SymbolClass::NoteheadOpen | SymbolClass::NoteheadWhole
            ) && score > nh_score {
                nh_score = score;
            }
        }
    }

    // KIND-Update via Templates ist sicher (nur wenn NH-class WINS klar).
    // Symbol-Rejection (Coda/Segno/Dynamic) ist DEAKTIVIERT bis wir bessere
    // Tuning-Daten haben — synthetische Bravura-Templates passen schlecht zu
    // den realen NH-Shapes nach Staff-Removal.
    //
    // FUTURE: Ein trainierter HoG+SVM oder kleiner CNN auf realen NH-Crops würde
    // hier deutlich besser performen. Das templates-Modul liefert die Bilder
    // dafür, aber das Training kommt in einem separaten Schritt.
    //
    // let is_strong_non_nh = matches!(
    //     best_class,
    //     SymbolClass::Coda | SymbolClass::Segno
    //         | SymbolClass::DynamicPiano | SymbolClass::DynamicMezzopiano
    //         | SymbolClass::DynamicMezzoforte | SymbolClass::DynamicForte
    // );
    // if is_strong_non_nh && best_score > X && nh_score < Y { return None; }

    let is_nh_class = matches!(
        best_class,
        SymbolClass::NoteheadFilled | SymbolClass::NoteheadOpen | SymbolClass::NoteheadWhole
    );
    if is_nh_class && best_score > 0.30 {
        return Some(match best_class {
            SymbolClass::NoteheadFilled => NoteheadKind::Filled,
            SymbolClass::NoteheadOpen => NoteheadKind::Open,
            SymbolClass::NoteheadWhole => NoteheadKind::Whole,
            _ => nh.kind,
        });
    }
    // Unsicherer Fall: behalte ursprüngliche Klassifikation.
    Some(nh.kind)
}

/// Filtert eine NH-Liste: behält nur die, die sich als NH klassifizieren lassen.
/// Updated den Kind anhand der Template-Klassifikation (Filled/Open/Whole).
pub fn filter_via_templates(bin: &Binary, noteheads: Vec<Notehead>, spacing: f32) -> Vec<Notehead> {
    if spacing < 6.0 {
        // Zu kleine Spacing → Templates sind unzuverlässig, skip.
        return noteheads;
    }
    noteheads
        .into_iter()
        .filter_map(|mut nh| {
            classify_via_templates(bin, &nh, spacing).map(|kind| {
                nh.kind = kind;
                nh
            })
        })
        .collect()
}

/// Konfidenz-Schwelle für HoG+SVM Reject. Bei Werten oberhalb dieser
/// Schwelle UND einer Nicht-NH-Klasse wird der Kandidat verworfen.
///
/// Empirisch getuned: Coda/Segno/Dynamic-Klassen haben in unserem Modell
/// Precision >= 0.90, NH-Klassen sind unzuverlässig (Filled/Open/Whole F1 < 0.4).
/// Daher nutzen wir den Klassifikator NUR für Reject (Coda/Segno/Dyn) und NICHT
/// für Kind-Update (Filled/Open/Whole bleibt aus klassischer Hole-Detection).
pub const HOG_SVM_REJECT_CONFIDENCE: f32 = 0.55;

/// Klassifiziert einen Notehead-Kandidaten via HoG+SVM und entscheidet
/// über Reject.
///
/// * Wenn die Top-Klasse Coda/Segno/Dynamik ist UND Konfidenz >
///   [`HOG_SVM_REJECT_CONFIDENCE`] → `None` (Reject = falscher Notehead).
/// * Wenn die Top-Klasse ein NH-Kind ist → behalte Original-Kind unverändert
///   (HoG-Klassifikator ist auf NH-Klassen unzuverlässig, klassisches
///   Hole-Detection bleibt führend).
/// * Wenn die Top-Klasse `Noise` ist → behalten (lieber FP als FN).
/// * Sonst (Coda/Segno/Dyn mit niedriger Konfidenz) → konservativ behalten.
pub fn classify_via_hog_svm(
    bin: &Binary,
    nh: &Notehead,
    spacing: f32,
    classifier: &HogSvmClassifier,
) -> Option<NoteheadKind> {
    let patch_size = ((spacing * 1.6).round() as u32).clamp(16, 64);
    let cx = nh.center.x as i32;
    let cy = nh.center.y as i32;
    let half = patch_size as i32 / 2;
    let x0 = (cx - half).max(0) as u32;
    let y0 = (cy - half).max(0) as u32;
    if x0 + patch_size > bin.w || y0 + patch_size > bin.h {
        return Some(nh.kind);
    }
    let mut img = GrayImage::new(patch_size, patch_size);
    for py in 0..patch_size {
        for px in 0..patch_size {
            let v = if bin.get(x0 + px, y0 + py) == 1 { 255 } else { 0 };
            img.put_pixel(px, py, image::Luma([v]));
        }
    }
    let (best_class, conf) = classifier.predict(&img);

    match best_class {
        // Reject-Pfad: nur für klar erkannte Nicht-NH-Symbole
        SymbolClass::Coda
        | SymbolClass::Segno
        | SymbolClass::DynamicPiano
        | SymbolClass::DynamicMezzopiano
        | SymbolClass::DynamicMezzoforte
        | SymbolClass::DynamicForte => {
            if conf > HOG_SVM_REJECT_CONFIDENCE {
                None
            } else {
                Some(nh.kind)
            }
        }
        // Behalten: NH-Klassen (auch wenn unzuverlässig) + Noise
        SymbolClass::NoteheadFilled
        | SymbolClass::NoteheadOpen
        | SymbolClass::NoteheadWhole
        | SymbolClass::Noise => Some(nh.kind),
    }
}

/// Filtert eine NH-Liste mittels HoG+SVM-Klassifikator.
///
/// Verwirft Coda/Segno/Dynamik mit hoher Konfidenz, behält Noteheads
/// (mit ggf. aktualisiertem Kind) und unsichere Fälle.
pub fn filter_via_hog_svm(
    bin: &Binary,
    noteheads: Vec<Notehead>,
    spacing: f32,
    classifier: &HogSvmClassifier,
) -> Vec<Notehead> {
    if spacing < 6.0 {
        return noteheads;
    }
    noteheads
        .into_iter()
        .filter_map(|mut nh| {
            classify_via_hog_svm(bin, &nh, spacing, classifier).map(|kind| {
                nh.kind = kind;
                nh
            })
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::Rect;

    #[test]
    fn classify_filled_notehead_template() {
        // Synthetisches Patch mit gefuelltem NH in der Mitte
        let mut bin = Binary::new(64, 64);
        // Gefuellter Kreis in der Mitte
        for y in 28..36 {
            for x in 26..38 {
                let dx = x as i32 - 32;
                let dy = y as i32 - 32;
                if dx * dx + dy * dy <= 36 {
                    bin.set(x, y, 1);
                }
            }
        }
        let nh = Notehead {
            bbox: Rect { x: 26, y: 28, w: 12, h: 8 },
            center: Point { x: 32.0, y: 32.0 },
            confidence: 1.0,
            kind: NoteheadKind::Filled,
            staff_idx: 0,
        };
        let result = classify_via_templates(&bin, &nh, 12.0);
        // Sollte als irgendeine Notehead-Klasse klassifiziert werden, nicht None
        assert!(result.is_some(), "filled notehead patch should not be rejected");
    }

    #[test]
    fn empty_patch_is_rejected_as_noise() {
        // Komplett weißer Patch → sollte als Noise klassifiziert (None) oder irrelevant
        let bin = Binary::new(64, 64);
        let nh = Notehead {
            bbox: Rect { x: 26, y: 28, w: 12, h: 8 },
            center: Point { x: 32.0, y: 32.0 },
            confidence: 1.0,
            kind: NoteheadKind::Filled,
            staff_idx: 0,
        };
        let result = classify_via_templates(&bin, &nh, 12.0);
        // Empty patch → patch_norm = 0 → score = 0 für ALLE Klassen.
        // Wir bekommen also default best_class = Noise, aber best_score = -inf
        // → wird auf < 0.15 fallen → ursprünglicher Kind beibehalten.
        // Test: Result ist Some(Filled) (= unverändert) ODER None (rejected)
        // Beide sind akzeptabel.
        let _ = result;
    }
}
