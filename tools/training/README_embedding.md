# Embedding-Training fuer OMR-Symbole

Trainiert ein **MobileNetV3-Small + 256-dim Projection-Head** via Triplet-Loss
auf dem synthetischen Korpus `data/synthetic_corpus_v1`.

## Architektur

```
Input: [B, 3, 64x64]  (RGB, ImageNet-normiert)
  └─> MobileNetV3-Small backbone (2.5M param, kein ImageNet-Pretraining)
  └─> Linear(576, 512) + Hardswish + Dropout(0.2)
  └─> Linear(512, 256)
  └─> L2-Normalisierung
Output: [B, 256]  (L2-normierte Embeddings)
```

**Loss:** Standard Triplet-Loss mit cosine distance und Margin = 0.5

## Schnellstart

```powershell
cd tools/training

# Abhaengigkeiten installieren (falls noetig)
.\.venv\Scripts\pip.exe install -r requirements.txt

# Training starten (30 Epochs, ~2h auf CPU)
.\.venv\Scripts\python.exe train_embedding.py \
    --corpus data/synthetic_corpus_v1/single \
    --epochs 30 \
    --device cpu

# Evaluierung
.\.venv\Scripts\python.exe eval_embedding.py \
    --model models/symbol_encoder_v1.pt \
    --corpus data/synthetic_corpus_v1/single

# Smoke-Test (2 Epochs, Mini-Corpus)
.\.venv\Scripts\python.exe -m pytest tests/test_train_embedding.py -v
```

## Output-Dateien

| Datei | Beschreibung |
|-------|-------------|
| `models/symbol_encoder_v1.pt` | PyTorch state-dict (bestes Epoch nach k-NN Top-1) |
| `models/symbol_encoder_v1.onnx` | ONNX-Export fuer `omr-embed::OnnxCnnEncoder` |
| `models/symbol_encoder_v1.json` | Class-Mapping + Trainings-Metadaten |
| `models/symbol_encoder_v1.log` | Epoch-Log: loss, top1/3/5, lr |

## Trainings-Parameter

| Parameter | Default | Beschreibung |
|-----------|---------|-------------|
| `--epochs` | 30 | Anzahl Trainings-Epochs |
| `--batch-size` | 64 | Batch-Groesse |
| `--lr` | 1e-4 | Lernrate (AdamW, cosine decay) |
| `--embedding-dim` | 256 | Embedding-Dimension |
| `--margin` | 0.5 | Triplet-Margin |
| `--n-triplets-per-epoch` | 10000 | Triplets pro Epoch |
| `--device` | auto | auto/cpu/cuda |

## Cold-Start vs Warm-Start

### Cold-Start (kein trainiertes Modell)

Der `HogEncoder` liefert sofort verwertbare Embeddings:
- 1764-dim HoG-Deskriptor
- Keine Trainingszeit
- Geeignet fuer erste Explorationen
- Top-1 ca. 40-50% auf `synthetic_corpus_v1`

```rust
use omr_embed::HogEncoder;
let enc = HogEncoder::new();
```

### Warm-Start (trainiertes CNN-Modell)

Der `OnnxCnnEncoder` mit trainiertem `symbol_encoder_v1.onnx`:
- 256-dim Embedding
- Top-1 ca. 70-85% auf `synthetic_corpus_v1` (nach 30 Epochs)
- Benoetigt einmalig Training (~1-2h CPU, ~20 min GPU)

```rust
#[cfg(feature = "cnn")]
use omr_embed::OnnxCnnEncoder;

// Eingebettetes Modell (nach Generierung und Rebuild):
let enc = OnnxCnnEncoder::embedded().unwrap();

// Oder aus Datei:
let enc = OnnxCnnEncoder::from_path(Path::new("models/symbol_encoder_v1.onnx")).unwrap();
```

## Modell-Deployment (ONNX -> Rust)

1. Training ausfuehren:
   ```powershell
   python train_embedding.py --corpus data/synthetic_corpus_v1/single
   ```

2. ONNX-Datei in Crate-Assets kopieren (nur wenn <= 5 MB):
   ```powershell
   $size = (Get-Item models/symbol_encoder_v1.onnx).Length / 1MB
   if ($size -le 5) {
       Copy-Item models/symbol_encoder_v1.onnx \
           ../../src/omr-rust/crates/omr-embed/assets/symbol_encoder_v1.onnx
   } else {
       Write-Host "Modell zu gross ($size MB), nicht committed"
   }
   ```
   > **Hinweis:** MobileNetV3-Small in float32 ist ~10 MB (> 5 MB Git-Limit).
   > Das Modell wird daher NICHT ins Repo committed.
   > Stattdessen wird es lokal generiert und bei Bedarf in `assets/` abgelegt.

3. Rust neu bauen:
   ```powershell
   cd src/omr-rust
   cargo build -p omr-embed --features cnn
   ```
   `build.rs` erkennt automatisch ob `assets/symbol_encoder_v1.onnx` vorhanden ist
   und setzt den `has_embedded_model` cfg-Flag.

## Erwartete Accuracy auf synthetic_corpus_v1

| Metrik | HogEncoder | CNN (5 Epochs) | CNN (30 Epochs) |
|--------|-----------|----------------|-----------------|
| Top-1  | ~40-50%   | ~55-65%        | ~70-85%         |
| Top-3  | ~60-70%   | ~75-85%        | ~85-93%         |
| Top-5  | ~70-80%   | ~82-90%        | ~90-96%         |

*Noten: 94 Klassen, 50 Samples/Klasse, CPU-Training ohne Pretrained-Weights*

## Corpus-Struktur

```
data/synthetic_corpus_v1/single/
  accidentals/
    double_flat/   *.png  (50 Samples)
    flat/          *.png
    sharp/         *.png
    ...
  clefs/
    treble/        *.png
    bass/          *.png
    ...
  noteheads/
    filled_quarter/ *.png
    half/           *.png
    ...
  [14 Kategorien, 94 Klassen gesamt]
```

## Active Learning (User-Labels integrieren)

Um Real-Welt-Annotationen vom User in den Korpus zu integrieren:

1. User annotiert Symbole im Sheetstorm-UI
2. `export_user_annotations.py` exportiert die Labels als PNG-Patches
3. Patches in neue Klasse oder bestehende Klasse unter `data/synthetic_corpus_v1/single/` kopieren
4. Training neu starten:
   ```powershell
   python train_embedding.py \
       --corpus data/synthetic_corpus_v1/single \
       --output models/symbol_encoder_v2
   ```
5. Neues Modell evaluieren:
   ```powershell
   python eval_embedding.py \
       --model models/symbol_encoder_v2.pt \
       --output reports/v2_eval
   ```

## ONNX-Kompatibilitaet mit tract-onnx

Das Modell wird mit `opset_version=17` und `do_constant_folding=True` exportiert.
Getestete Kompatibilitaet:
- `onnxruntime`: max_diff < 1e-3 (verifiziert in `train_embedding.py`)
- `tract-onnx 0.21`: kompatibel (kein LeakyReLU mit alpha != 0.01, Hardswish wird unterstuetzt)

Sollte `tract-onnx` einen Operator nicht unterstuetzen, als Workaround ReLU statt Hardswish verwenden:
```python
# In EmbeddingModel.__init__():
backbone.classifier = nn.Sequential(
    nn.Linear(in_features, 512),
    nn.ReLU(),   # statt nn.Hardswish()
    nn.Dropout(p=0.2),
    nn.Linear(512, embedding_dim),
)
```