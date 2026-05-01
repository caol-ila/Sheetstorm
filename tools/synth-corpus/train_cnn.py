"""
train_cnn.py — Trainings-Pipeline für CNN-basierten OMR-Symbol-Klassifikator.

Architektur: MobileNetV3-small (oder ResNet18-Variante)
Input: 64x64 grayscale patch
Output: softmax über SymbolType-Klassen (Note/Rest/Clef/TimeSig/...)

Trainings-Quellen:
1) Synth-Corpus (PNG-Pages aus MIDI + Augmentation) — patches gecropt aus Detection-Bboxes
2) MUSCIMA++ (NC-Lizenz, optional) — patches aus den Annotationen
3) Sheetstorm-Real-PDFs mit User-Annotationen aus dem Annotation-Tool

Aufruf:
    python train_cnn.py --synth-corpus data/augmented --gt data/musicxml \
        --out ../../assets/symbol-classifier-cnn.onnx \
        --epochs 30

Voraussetzung:
    pip install torch torchvision onnx Pillow numpy
"""
from __future__ import annotations
import argparse
import json
import sys
from pathlib import Path

# Lazy-Import: Torch ist groß, nur laden wenn wirklich gebraucht
def lazy_import_torch():
    try:
        import torch
        import torch.nn as nn
        import torch.optim as optim
        from torchvision import transforms, models
        return torch, nn, optim, transforms, models
    except ImportError:
        print("FEHLER: pip install torch torchvision onnx", file=sys.stderr)
        sys.exit(2)


# Symbol-Klassen — entspricht Sheetstorm.Domain.Music.SymbolType
SYMBOL_CLASSES = [
    "Note", "Rest",
    "ClefTreble", "ClefBass", "ClefAlto", "ClefTenor",
    "TimeSignature", "TimeSignatureCommon", "TimeSignatureCut",
    "KeySignature",
    "Barline", "BarlineDouble", "BarlineFinal",
    "RepeatStart", "RepeatEnd",
    "Volta1", "Volta2",
    "Coda", "Segno", "DalCapo", "DalSegno", "Fine",
    "DynamicPianissimo", "DynamicPiano", "DynamicMezzopiano",
    "DynamicMezzoforte", "DynamicForte", "DynamicFortissimo",
    "HairpinCrescendo", "HairpinDecrescendo",
    "TempoText", "Ritardando", "Accelerando", "Fermata",
    "AccentMark", "Staccato", "Tenuto", "Marcato",
    "Slur", "Tie", "Trill",
    "Triplet",
    "Other",
    "NotASymbol",  # für False-Positive-Training
]
NUM_CLASSES = len(SYMBOL_CLASSES)


def build_model(num_classes: int):
    """MobileNetV3-small mit angepasstem Classifier-Head + 1-Channel-Input."""
    torch, nn, _, _, models = lazy_import_torch()
    model = models.mobilenet_v3_small(weights=None)
    # Erste Conv-Schicht auf 1-Channel umstellen (statt 3 für RGB)
    first = model.features[0][0]
    model.features[0][0] = nn.Conv2d(
        1, first.out_channels,
        kernel_size=first.kernel_size,
        stride=first.stride,
        padding=first.padding,
        bias=False,
    )
    # Classifier-Head: NUM_CLASSES outputs
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, num_classes)
    return model


def export_onnx(model, output_path: Path, input_size: int = 64):
    torch, _, _, _, _ = lazy_import_torch()
    model.eval()
    dummy = torch.randn(1, 1, input_size, input_size)
    torch.onnx.export(
        model, dummy, str(output_path),
        input_names=["input"], output_names=["logits"],
        dynamic_axes={"input": {0: "batch"}, "logits": {0: "batch"}},
        opset_version=14,
    )
    print(f"ONNX exportiert: {output_path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--synth-corpus", type=Path, default=Path("data/augmented"),
                    help="Verzeichnis mit augmentierten PNG-Pages")
    ap.add_argument("--gt", type=Path, default=Path("data/musicxml"),
                    help="Verzeichnis mit Ground-Truth .gt.json (siehe midi_to_parts.py)")
    ap.add_argument("--out", type=Path, required=True,
                    help="Output ONNX-Pfad")
    ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--batch-size", type=int, default=64)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--patch-size", type=int, default=64)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--device", default="cuda" if 'cuda_available' else 'cpu')
    args = ap.parse_args()

    print(f"=== CNN-Training für OMR-Symbol-Klassifikator ===")
    print(f"  Klassen: {NUM_CLASSES}")
    print(f"  Synth-Corpus: {args.synth_corpus}")
    print(f"  Output: {args.out}")
    print()

    if not args.synth_corpus.exists():
        print(f"FEHLER: synth-corpus existiert nicht: {args.synth_corpus}")
        print("Vorher run_pipeline.py ausführen um Augmented-PNGs zu generieren.")
        sys.exit(1)

    # TODO: Implementation der Datasets-Klasse + Training-Loop
    # Pseudo-Code:
    #   1) Datasets.from_synth_corpus(args.synth_corpus, args.gt) -> patches mit labels
    #   2) DataLoader mit augmentation (random crop ±8px, brightness, contrast)
    #   3) Model = build_model(NUM_CLASSES)
    #   4) Optimizer = AdamW(lr=args.lr, weight_decay=1e-4)
    #   5) Scheduler = CosineAnnealingLR
    #   6) Train: for epoch in args.epochs: trainsplit + valsplit + checkpoint
    #   7) Export ONNX wenn val-acc > best
    print("STUB: Training-Loop noch nicht implementiert.")
    print("Architektur-Skelett + ONNX-Export-Funktionen sind vorbereitet.")
    print()
    print("Nächste Schritte:")
    print("  1) run_pipeline.py laufen lassen, um data/augmented zu erzeugen")
    print("  2) Patch-Extractor schreiben: aus jedem augmented PNG die NH-Bboxes")
    print("     croppen + Label aus .gt.json zuordnen")
    print("  3) Training-Loop implementieren (siehe TODO)")
    print()
    print("Architektur-Test:")
    model = build_model(NUM_CLASSES)
    n_params = sum(p.numel() for p in model.parameters())
    print(f"  MobileNetV3-small adapted: {n_params:,} Parameter")
    print(f"  Modell-Größe: ~{n_params * 4 / 1024 / 1024:.1f} MB (FP32)")


if __name__ == "__main__":
    main()
