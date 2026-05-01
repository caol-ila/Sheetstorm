//! CNN-Klassifikator basiert auf einem ONNX-Modell (MobileNetV3-Small),
//! trainiert auf 48 Symbol-Klassen (Bravura-Synth + MUSCIMA++ + User-Annotations).
//!
//! Pure-Rust ONNX-Inferenz via `tract-onnx` (kein nativer C-Toolchain notwendig).
//!
//! Hybrid mit HoG+SVM:
//!   - CNN ist primary
//!   - Wenn CNN-Confidence < 0.5: fallback auf HoG+SVM
//!   - Klassen die NICHT NoteheadFilled/Open/Whole sind → reject
//!
//! Performance: tract auf CPU: ~5-10ms pro Patch (auf modernem Intel/AMD).
//! Pro Page (200 NHs) = ~1-2s — akzeptabel für Pipeline.

#![cfg(feature = "cnn")]

use crate::svm_model::HogSvmClassifier;
use omr_core::{Binary, Notehead, NoteheadKind};
use std::path::PathBuf;
use std::sync::OnceLock;
use tract_onnx::prelude::*;
use tracing::{debug, info, warn};

/// 48-Klassen-Schema, MUSS konsistent mit tools/training/CLASS_NAMES sein.
pub const CNN_CLASS_NAMES: [&str; 48] = [
    "NoteheadFilled", "NoteheadOpen", "NoteheadWhole",
    "RestQuarter", "RestHalf", "RestWhole", "RestEighth", "RestSixteenth",
    "ClefTreble", "ClefBass", "ClefAlto", "ClefTenor",
    "Sharp", "Flat", "Natural", "DoubleSharp", "DoubleFlat",
    "TimeSig2", "TimeSig3", "TimeSig4", "TimeSig6", "TimeSig8",
    "RepeatStart", "RepeatEnd", "Coda", "Segno", "Fine",
    "DynamicP", "DynamicF", "DynamicMP", "DynamicMF", "DynamicPP", "DynamicFF",
    "Crescendo", "Decrescendo", "Slur", "Tie",
    "StaccatoDot", "AccentMark", "Fermata", "TrillMark",
    "AugmentationDot", "TupletNumber", "Beam", "Stem", "LedgerLine",
    "Barline", "Noise",
];

const NOTEHEAD_CLASSES: &[(usize, NoteheadKind)] = &[
    (0, NoteheadKind::Filled),
    (1, NoteheadKind::Open),
    (2, NoteheadKind::Whole),
];

const PATCH_SIZE: usize = 64;
const MEAN: [f32; 3] = [0.485, 0.456, 0.406];
const STD: [f32; 3] = [0.229, 0.224, 0.225];

type RunnableModel = SimplePlan<TypedFact, Box<dyn TypedOp>, Graph<TypedFact, Box<dyn TypedOp>>>;

static CNN_MODEL: OnceLock<Option<RunnableModel>> = OnceLock::new();

fn try_load_model(model_path: &std::path::Path) -> Option<RunnableModel> {
    if !model_path.exists() {
        warn!(model = %model_path.display(), "CNN-Modell nicht vorhanden");
        return None;
    }
    let result: TractResult<RunnableModel> = (|| {
        let model = tract_onnx::onnx()
            .model_for_path(model_path)?
            .with_input_fact(0, f32::fact([1, 3, PATCH_SIZE, PATCH_SIZE]).into())?
            .into_optimized()?
            .into_runnable()?;
        Ok(model)
    })();
    match result {
        Ok(m) => {
            info!(model = %model_path.display(), "CNN-Klassifikator geladen (tract)");
            Some(m)
        }
        Err(e) => {
            warn!(error = %e, "tract-Modell-Init fehlgeschlagen");
            None
        }
    }
}

fn model_path() -> PathBuf {
    if let Ok(p) = std::env::var("OMR_CNN_MODEL") {
        return PathBuf::from(p);
    }
    let manifest = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    manifest.join("assets").join("cnn-model.onnx")
}

fn get_model() -> Option<&'static RunnableModel> {
    CNN_MODEL.get_or_init(|| try_load_model(&model_path())).as_ref()
}

fn extract_patch_tensor(bin: &Binary, nh: &Notehead) -> ndarray::Array3<f32> {
    let mut tensor = ndarray::Array3::<f32>::zeros((3, PATCH_SIZE, PATCH_SIZE));
    for c in 0..3 {
        let normalized_white = (1.0 - MEAN[c]) / STD[c];
        for y in 0..PATCH_SIZE {
            for x in 0..PATCH_SIZE {
                tensor[[c, y, x]] = normalized_white;
            }
        }
    }

    let bb = nh.bbox;
    let cx_src = (bb.x as f32 + bb.w as f32 / 2.0) as i32;
    let cy_src = (bb.y as f32 + bb.h as f32 / 2.0) as i32;
    let half = (PATCH_SIZE as i32) / 2;
    let bb_max_dim = bb.w.max(bb.h).max(1) as f32;
    let scale = ((PATCH_SIZE as f32) / bb_max_dim) * 0.7;
    let scale = scale.clamp(0.5, 4.0);

    for py in 0..PATCH_SIZE as i32 {
        for px in 0..PATCH_SIZE as i32 {
            let dx = (px - half) as f32 / scale;
            let dy = (py - half) as f32 / scale;
            let sx = (cx_src as f32 + dx) as i32;
            let sy = (cy_src as f32 + dy) as i32;
            if sx < 0 || sy < 0 || sx >= bin.w as i32 || sy >= bin.h as i32 {
                continue;
            }
            let gray = if bin.get(sx as u32, sy as u32) != 0 { 0.0 } else { 1.0 };
            for c in 0..3 {
                let normalized = (gray - MEAN[c]) / STD[c];
                tensor[[c, py as usize, px as usize]] = normalized;
            }
        }
    }
    tensor
}

fn softmax(logits: &[f32]) -> Vec<f32> {
    let max = logits.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
    let exp_sum: f32 = logits.iter().map(|x| (x - max).exp()).sum();
    logits.iter().map(|x| (x - max).exp() / exp_sum.max(1e-9)).collect()
}

fn predict_one(model: &RunnableModel, patch: ndarray::Array3<f32>) -> Option<Vec<f32>> {
    let batched = patch.insert_axis(ndarray::Axis(0));
    let input_tensor: Tensor = batched.into();
    let result = match model.run(tvec!(input_tensor.into())) {
        Ok(r) => r,
        Err(e) => { debug!(error = %e, "tract inference failed"); return None; }
    };
    let output = result[0].to_array_view::<f32>().ok()?;
    let logits: Vec<f32> = output.iter().cloned().collect();
    Some(softmax(&logits))
}

/// Filtert NHs via CNN-Klassifikation. Wenn `fallback` gegeben + CNN-Confidence
/// niedrig: HoG+SVM-Fallback.
pub fn filter_via_cnn(
    bin: &Binary,
    noteheads: Vec<Notehead>,
    spacing: f32,
    fallback: Option<&HogSvmClassifier>,
) -> Vec<Notehead> {
    let model = match get_model() {
        Some(m) => m,
        None => {
            warn!("CNN-Modell nicht verfügbar — fallback auf HoG+SVM");
            if let Some(clf) = fallback {
                return crate::classifier::filter_via_hog_svm(bin, noteheads, spacing, clf);
            }
            return noteheads;
        }
    };

    let n = noteheads.len();
    if n == 0 { return noteheads; }

    let mut result = Vec::with_capacity(n);
    let mut accepted = 0;
    let mut rejected = 0;
    let mut fallback_used = 0;
    let min_confidence = 0.5_f32;

    for nh in noteheads.into_iter() {
        let patch = extract_patch_tensor(bin, &nh);
        let probs = match predict_one(model, patch) {
            Some(p) => p,
            None => {
                if let Some(clf) = fallback {
                    let single = crate::classifier::filter_via_hog_svm(bin, vec![nh.clone()], spacing, clf);
                    fallback_used += 1;
                    if !single.is_empty() {
                        result.push(single.into_iter().next().unwrap());
                        accepted += 1;
                    } else {
                        rejected += 1;
                    }
                }
                continue;
            }
        };
        let (best_idx, best_prob) = probs.iter().enumerate()
            .fold((0usize, f32::NEG_INFINITY), |(bi, bp), (i, &p)| {
                if p > bp { (i, p) } else { (bi, bp) }
            });

        if best_prob < min_confidence {
            if let Some(clf) = fallback {
                let single = crate::classifier::filter_via_hog_svm(bin, vec![nh.clone()], spacing, clf);
                fallback_used += 1;
                if !single.is_empty() {
                    result.push(single.into_iter().next().unwrap());
                    accepted += 1;
                } else {
                    rejected += 1;
                }
                continue;
            }
        }

        if let Some((_, kind)) = NOTEHEAD_CLASSES.iter().find(|(idx, _)| *idx == best_idx) {
            let mut nh = nh;
            nh.kind = *kind;
            nh.confidence = best_prob;
            result.push(nh);
            accepted += 1;
        } else {
            rejected += 1;
        }
    }

    info!(
        n_input = n,
        accepted,
        rejected,
        fallback_used,
        cnn_class_names_len = CNN_CLASS_NAMES.len(),
        "CNN-Klassifikation abgeschlossen"
    );
    result
}
