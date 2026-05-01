// U-Net-basiertes Staff-Removal via ONNX-Inference.
//
// Status: STUB-Pipeline. Aktuell konnte kein Apache-2.0-kompatibles
// vortrainiertes Staff-Removal-U-Net mit verifizierbarer Lizenz lokalisiert
// werden (siehe `README.md` und `docs/19-omr-research-2026.md`). Die
// Modul-Architektur ist jedoch vollständig: ein passendes ONNX-Modell kann
// zur Laufzeit geladen werden, ohne dass weitere Code-Änderungen nötig
// sind.
//
// Erwartetes Modell-Interface:
//   - Input  : Tensor `f32` shape `[1, 1, H, W]`, normalisiert auf `[0,1]`
//              (1.0 = schwarz / Forderung). H und W werden auf das nächste
//              Vielfache von `PAD_MULTIPLE` (Default 16) hochgepadded.
//   - Output : Tensor `f32` shape `[1, 1, H, W]` (oder `[1, 2, H, W]` für
//              Hintergrund/Vordergrund-Logits). Werte > `THRESHOLD` werden
//              als „Staff-Line-Pixel" interpretiert und im Output-Binary
//              entfernt.
//
// Workflow zur Laufzeit:
//   1. `UnetStaffRemover::load(path)` lädt das ONNX-Modell einmalig
//      (teuer, ~50–200 ms je nach Modellgröße).
//   2. `remover.remove(&bin)` führt für ein Binary die Inferenz aus und
//      gibt ein neues Binary zurück, in dem alle vorhergesagten
//      Staff-Pixel auf 0 gesetzt sind. Notenköpfe, die die Linien
//      kreuzen, bleiben dabei (im Gegensatz zum RLE-Removal) intakt.
//
// Falls das Feature `unet` nicht aktiviert ist, kompiliert dieses Modul
// trotzdem als kleiner Fallback-Stub (siehe `mod fallback`), damit
// `omr-pipeline` bedingungslos `try_remove_staff_unet()` aufrufen kann.

use omr_core::Binary;
use std::path::Path;

/// Schwellwert auf der Modell-Output-Maske (nach Sigmoid bzw. Softmax),
/// ab dem ein Pixel als Stafflinie klassifiziert wird.
pub const DEFAULT_THRESHOLD: f32 = 0.5;

/// Padding-Vielfaches für H/W. U-Nets mit 4 Pooling-Stufen brauchen i.d.R.
/// Eingaben deren Kantenlängen durch 16 teilbar sind.
pub const PAD_MULTIPLE: u32 = 16;

#[cfg(feature = "unet")]
pub use real::UnetStaffRemover;

#[cfg(not(feature = "unet"))]
pub use fallback::UnetStaffRemover;

/// Versucht ein U-Net-Staff-Removal durchzuführen.
///
/// Liefert `Some(bin)` nur, wenn das Feature `unet` aktiv ist UND die
/// Modell-Datei unter `model_path` ladbar ist UND die Inferenz erfolgreich
/// war. In allen anderen Fällen `None` — der Aufrufer soll dann auf das
/// klassische RLE-Removal zurückfallen.
pub fn try_remove_staff_unet(bin: &Binary, model_path: &Path) -> Option<Binary> {
    match UnetStaffRemover::load(model_path) {
        Ok(remover) => match remover.remove(bin) {
            Ok(out) => Some(out),
            Err(e) => {
                tracing::warn!(error = %e, "U-Net inference failed, falling back to RLE");
                None
            }
        },
        Err(e) => {
            tracing::warn!(
                error = %e,
                path = %model_path.display(),
                "U-Net model not loadable, falling back to RLE"
            );
            None
        }
    }
}

// ─────────────────────────────────────────────────────────────────────
// Real implementation (feature `unet` active)
// ─────────────────────────────────────────────────────────────────────
#[cfg(feature = "unet")]
mod real {
    use super::{DEFAULT_THRESHOLD, PAD_MULTIPLE};
    use anyhow::{anyhow, Context, Result};
    use omr_core::Binary;
    use std::path::Path;
    use tract_onnx::prelude::*;

    type OnnxModel = SimplePlan<TypedFact, Box<dyn TypedOp>, Graph<TypedFact, Box<dyn TypedOp>>>;

    /// Geladenes ONNX-U-Net für Staff-Line-Segmentation.
    pub struct UnetStaffRemover {
        model: OnnxModel,
        threshold: f32,
    }

    impl UnetStaffRemover {
        /// Lädt ein ONNX-Modell von Pfad. Einmalig pro Prozess aufrufen.
        pub fn load(path: &Path) -> Result<Self> {
            if !path.exists() {
                return Err(anyhow!("U-Net model file not found: {}", path.display()));
            }
            // Modell mit symbolischer Batchsize/Bildgröße laden, damit wir
            // unterschiedlich große Eingaben verarbeiten können.
            let model = tract_onnx::onnx()
                .model_for_path(path)
                .with_context(|| format!("loading ONNX model from {}", path.display()))?
                .into_optimized()
                .context("optimizing ONNX model")?
                .into_runnable()
                .context("making ONNX model runnable")?;
            Ok(Self { model, threshold: DEFAULT_THRESHOLD })
        }

        /// Optionaler Threshold-Override (Default `0.5`).
        pub fn with_threshold(mut self, t: f32) -> Self {
            self.threshold = t;
            self
        }

        /// Führt die Staff-Removal-Inferenz aus.
        pub fn remove(&self, bin: &Binary) -> Result<Binary> {
            let (w0, h0) = (bin.w, bin.h);
            let (w_pad, h_pad) = pad_dims(w0, h0, PAD_MULTIPLE);

            // Input-Tensor [1, 1, H, W], 1.0 = schwarz, 0.0 = weiß.
            let input = tract_ndarray::Array4::<f32>::from_shape_fn(
                (1, 1, h_pad as usize, w_pad as usize),
                |(_, _, y, x)| {
                    if (x as u32) < w0 && (y as u32) < h0 {
                        bin.get(x as u32, y as u32) as f32
                    } else {
                        0.0
                    }
                },
            );
            let input_tensor: Tensor = input.into();

            let outputs = self
                .model
                .run(tvec!(input_tensor.into()))
                .context("running U-Net inference")?;
            let out = outputs
                .first()
                .ok_or_else(|| anyhow!("U-Net produced no output tensor"))?;
            let arr = out
                .to_array_view::<f32>()
                .context("U-Net output is not f32")?;

            // Wir akzeptieren [1,1,H,W] (Sigmoid) oder [1,C,H,W] (Softmax;
            // Channel 1 = Staff-Line) — konservativ Channel 0 nehmen wenn
            // C==1, sonst Channel 1.
            let shape = arr.shape();
            if shape.len() != 4 {
                return Err(anyhow!(
                    "unexpected U-Net output rank {} (shape {:?})",
                    shape.len(),
                    shape
                ));
            }
            let channels = shape[1];
            let h_out = shape[2];
            let w_out = shape[3];
            if h_out < h0 as usize || w_out < w0 as usize {
                return Err(anyhow!(
                    "U-Net output ({}x{}) smaller than input ({}x{})",
                    w_out,
                    h_out,
                    w0,
                    h0
                ));
            }
            let staff_channel = if channels == 1 { 0 } else { 1.min(channels - 1) };

            // Output-Binary: starten mit Originalpixeln, predicted Staff-Pixel löschen.
            let mut out_bin = Binary {
                w: w0,
                h: h0,
                data: bin.data.clone(),
            };
            let thr = self.threshold;
            for y in 0..h0 as usize {
                for x in 0..w0 as usize {
                    let v = arr[[0, staff_channel, y, x]];
                    if v >= thr {
                        out_bin.data[y * w0 as usize + x] = 0;
                    }
                }
            }
            Ok(out_bin)
        }
    }

    fn pad_dims(w: u32, h: u32, m: u32) -> (u32, u32) {
        let pad = |v: u32| if v % m == 0 { v } else { v + (m - v % m) };
        (pad(w), pad(h))
    }
}

// ─────────────────────────────────────────────────────────────────────
// Fallback stub (feature `unet` not active)
// ─────────────────────────────────────────────────────────────────────
#[cfg(not(feature = "unet"))]
mod fallback {
    use anyhow::{anyhow, Result};
    use omr_core::Binary;
    use std::path::Path;

    /// Stub — gibt immer einen Fehler zurück, wenn das Feature `unet`
    /// nicht aktiviert ist. Existiert damit die Pipeline-Integration
    /// (Crate-übergreifend) auch ohne Feature kompiliert.
    pub struct UnetStaffRemover;

    impl UnetStaffRemover {
        pub fn load(_path: &Path) -> Result<Self> {
            Err(anyhow!(
                "U-Net staff removal not compiled in (rebuild omr-staff with `--features unet`)"
            ))
        }

        pub fn with_threshold(self, _t: f32) -> Self {
            self
        }

        pub fn remove(&self, _bin: &Binary) -> Result<Binary> {
            Err(anyhow!("U-Net staff removal not compiled in"))
        }
    }
}
