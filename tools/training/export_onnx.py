"""
export_onnx.py

Exportiert ein trainiertes PyTorch-Modell zu ONNX für Rust-Inference via
ort (ONNX-Runtime-Rust-Crate).

Aufruf:
    python export_onnx.py \\
        --weights models/symbol_classifier.pt \\
        --output ../../src/omr-rust/crates/omr-symbols/assets/cnn-model.onnx
"""
from __future__ import annotations
import argparse
import sys
from pathlib import Path

try:
    import torch
    from torchvision import models
    import torch.nn as nn
except ImportError:
    print("FEHLER: pip install torch torchvision", file=sys.stderr)
    sys.exit(2)

N_CLASSES = 48


def build_model(n_classes: int = N_CLASSES):
    model = models.mobilenet_v3_small(weights=None)
    in_features = model.classifier[-1].in_features
    model.classifier[-1] = nn.Linear(in_features, n_classes)
    return model


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--weights", type=Path, required=True,
                    help="Pfad zur .pt Datei vom Training")
    ap.add_argument("--output", type=Path, required=True,
                    help="Ziel-Pfad für die .onnx Datei")
    ap.add_argument("--input-size", type=int, default=64)
    ap.add_argument("--opset", type=int, default=14)
    args = ap.parse_args()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    model = build_model(N_CLASSES)
    model.load_state_dict(torch.load(args.weights, map_location="cpu"))
    model.eval()

    dummy_input = torch.randn(1, 3, args.input_size, args.input_size)

    print(f"Exportiere {args.weights} zu {args.output}")
    torch.onnx.export(
        model,
        dummy_input,
        str(args.output),
        export_params=True,
        opset_version=args.opset,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["logits"],
        dynamic_axes={"input": {0: "batch_size"}, "logits": {0: "batch_size"}},
    )
    print(f"Done — {args.output.stat().st_size / 1024:.0f} KB")

    # Optional: testen mit onnxruntime
    try:
        import onnxruntime as ort
        sess = ort.InferenceSession(str(args.output), providers=["CPUExecutionProvider"])
        result = sess.run(None, {"input": dummy_input.numpy()})
        print(f"ONNX-Sanity-Check: output shape = {result[0].shape}")
    except ImportError:
        print("Hinweis: pip install onnxruntime fuer Sanity-Check")


if __name__ == "__main__":
    main()
