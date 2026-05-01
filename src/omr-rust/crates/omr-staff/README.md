# omr-staff

Staff-Line-Detection und Staff-Line-Removal für die Sheetstorm-OMR-Pipeline.

Zwei Removal-Pfade stehen zur Verfügung:

1. **RLE-Removal (Default, `pub fn remove_staff`)** — klassisch,
   Run-Length-basiert. Sehr schnell, aber zerschneidet *open notes* und
   *whole notes* mitunter in 2–4 Halbmonde, wenn deren Außenring auf
   einer Stafflinie liegt.
2. **U-Net-Removal (optional, Feature `unet`)** — Pixel-Segmentation via
   ONNX-Inferenz (pure Rust mittels [`tract-onnx`]). Modell-Datei wird
   *nicht* im Repo mitgeliefert (Größe 10–100 MB, Lizenzfragen, s.u.).

## U-Net-Setup

### 1. Crate mit Feature bauen

```sh
cargo build -p omr-staff --features unet
# oder workspace-weit
cargo build --workspace --features omr-staff/unet
```

Ohne das Feature kompiliert alles wie gewohnt; jeder Aufruf von
`try_remove_staff_unet()` liefert dann `None`, und die Pipeline fällt
automatisch auf das RLE-Removal zurück.

### 2. ONNX-Modell beschaffen

Aktueller Lizenz-Stand (Stand 2026-01, siehe
`docs/19-omr-research-2026.md`):

| Quelle | Lizenz Code | Lizenz Weights | Apache-2.0-kompatibel? |
|---|---|---|---|
| **oemer** ([`BreezeWhite/oemer`](https://github.com/BreezeWhite/oemer)) | MIT | nicht eindeutig dokumentiert; vermutlich auf CVC-MUSCIMA + DeepScores trainiert | ⚠ **unklar** — Weights-Lizenz nicht im Release/Modelcard verzeichnet |
| **CVC-MUSCIMA** Staff-Removal-Pairs | CC-BY 4.0 | (Trainings-Daten) | ✓ wenn man selbst trainiert |
| **MUSCIMA++** | CC-BY-NC-SA 4.0 | (Annotations-Layer) | ✗ NC-Klausel |
| **DeepScoresV2** | CC-BY-SA 4.0 | (Trainings-Daten) | ⚠ SA verschmutzt evtl. nach-trainierte Weights |

Da kein Modell mit *eindeutig dokumentierter* Apache-/MIT-Lizenz auf den
Weights gefunden wurde, liefert dieses Crate aktuell **nur die
Stub-Pipeline** (Loader + Inferenz-Code), ohne Modell-Datei. Das Modell
muss vom Anwender selbst bezogen oder trainiert werden.

Optionen:

- **Eigenes U-Net auf CVC-MUSCIMA trainieren** (Apache-kompatibel). Ein
  Standard-U-Net mit 4 Pooling-Stufen, ~5 M Parameter, 1 Stunde auf einer
  einzelnen GPU. Export via `torch.onnx.export(...)` oder `tf2onnx`.
- **oemer-Weights** verwenden, falls deren Lizenz im Einzelfall
  geklärt werden kann (Issue im oemer-Repo öffnen, Modelcard prüfen).

Gewünschtes ONNX-Interface (siehe `src/unet.rs`):

- **Input**: `f32` Tensor `[1, 1, H, W]`, Werte in `[0, 1]`
  (1.0 = schwarzer Pixel = Forderung). H und W werden auf das nächste
  Vielfache von 16 aufgepadded (Zero-Padding rechts/unten).
- **Output**: `f32` Tensor `[1, 1, H, W]` (Sigmoid-Maske der Stafflinien)
  oder `[1, C, H, W]` mit Channel 1 = Staff-Foreground (Softmax).
  Threshold default `0.5`.

### 3. Modell laden & verwenden

```rust
use omr_core::PipelineOptions;
use std::path::PathBuf;

let opts = PipelineOptions {
    unet_model_path: Some(PathBuf::from("assets/staff-removal-unet.onnx")),
    ..Default::default()
};
let result = omr_pipeline::process_image(path, &opts)?;
```

Findet die Pipeline kein ladbares Modell, loggt sie eine `warn!` und
nutzt RLE-Removal — der Aufruf schlägt **nicht** fehl.

## Tests

```sh
# Reine Stub-/Fallback-Tests (immer grün):
cargo test -p omr-staff

# Mit Modell-Datei (gesetzt via env var):
$env:SHEETSTORM_UNET_MODEL = "C:\path\to\staff-removal-unet.onnx"
cargo test -p omr-staff --features unet -- --ignored
```

[`tract-onnx`]: https://crates.io/crates/tract-onnx
