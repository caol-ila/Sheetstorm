"""
export_onnx.py

Exportiert trainierte PyTorch-Modelle zu ONNX für Rust-Inference via
tract-onnx.

Unterstützte Modell-Typen:
  1. CNN Symbol-Klassifikator (MobileNetV3-Small, 48 Klassen)
  2. U-Net Staff-Removal (leichtgewichtiges U-Net, 1→1 Kanal)

CNN-Aufruf:
    python export_onnx.py \\
        --weights models/symbol_classifier.pt \\
        --output ../../src/omr-rust/crates/omr-symbols/assets/cnn-model.onnx

U-Net-Aufruf:
    python export_onnx.py --model unet \\
        --weights models/staff_unet.pt \\
        --output ../../src/omr-rust/crates/omr-staff/assets/staff-unet.onnx
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


def build_cnn_model(n_classes: int = N_CLASSES):
    model = models.mobilenet_v3_small(weights=None)
    in_features = model.classifier[-1].in_features
    model.classifier[-1] = nn.Linear(in_features, n_classes)
    return model


# ─────────────────────────────────────────────────────────────────────────────
# U-Net Staff-Removal (muss identisch zu train_staff_unet.py sein)
# ─────────────────────────────────────────────────────────────────────────────

class DoubleConv(nn.Module):
    def __init__(self, in_ch: int, out_ch: int):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(in_ch, out_ch, 3, padding=1),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_ch, out_ch, 3, padding=1),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True),
        )

    def forward(self, x):
        return self.conv(x)


class StaffRemovalUNet(nn.Module):
    """Leichtgewichtiges U-Net (~250k params). Identisch zu train_staff_unet.py."""

    def __init__(self):
        super().__init__()
        self.enc1 = DoubleConv(1, 16)
        self.pool1 = nn.MaxPool2d(2)
        self.enc2 = DoubleConv(16, 32)
        self.pool2 = nn.MaxPool2d(2)
        self.enc3 = DoubleConv(32, 64)
        self.pool3 = nn.MaxPool2d(2)
        self.bridge = DoubleConv(64, 128)
        self.up3 = nn.ConvTranspose2d(128, 64, 2, stride=2)
        self.dec3 = DoubleConv(128, 64)
        self.up2 = nn.ConvTranspose2d(64, 32, 2, stride=2)
        self.dec2 = DoubleConv(64, 32)
        self.up1 = nn.ConvTranspose2d(32, 16, 2, stride=2)
        self.dec1 = DoubleConv(32, 16)
        self.out = nn.Conv2d(16, 1, 1)

    def forward(self, x):
        e1 = self.enc1(x)
        p1 = self.pool1(e1)
        e2 = self.enc2(p1)
        p2 = self.pool2(e2)
        e3 = self.enc3(p2)
        p3 = self.pool3(e3)
        b = self.bridge(p3)
        u3 = self.up3(b)
        d3 = self.dec3(torch.cat([u3, e3], dim=1))
        u2 = self.up2(d3)
        d2 = self.dec2(torch.cat([u2, e2], dim=1))
        u1 = self.up1(d2)
        d1 = self.dec1(torch.cat([u1, e1], dim=1))
        return torch.sigmoid(self.out(d1))


def export_unet(weights: Path, output: Path, patch_size: int = 256, opset: int = 14):
    """Exportiert ein trainiertes Staff-Removal-U-Net nach ONNX.

    Input-Shape : [1, 1, patch_size, patch_size] — 1-Kanal Graustufen (0=weiß, 1=schwarz)
    Output-Shape: [1, 1, patch_size, patch_size] — Sigmoid-Maske (1=Stafflinie, 0=Symbol)

    Dynamic Axes für H/W erlauben Tile-Inferenz mit unterschiedlichen Patchgrößen.
    """
    output.parent.mkdir(parents=True, exist_ok=True)
    model = StaffRemovalUNet()
    state = torch.load(str(weights), map_location="cpu")
    model.load_state_dict(state)
    model.eval()

    dummy = torch.zeros(1, 1, patch_size, patch_size)

    print(f"Exportiere U-Net {weights} -> {output}")
    torch.onnx.export(
        model,
        dummy,
        str(output),
        export_params=True,
        opset_version=opset,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["mask"],
        dynamic_axes={
            "input": {2: "height", 3: "width"},
            "mask":  {2: "height", 3: "width"},
        },
    )
    # Merge external data back into a single self-contained file.
    # The dynamo-based torch.onnx exporter may split weights into a
    # separate *.data file; tract-onnx (Rust) expects a single file.
    data_file = output.with_suffix(".onnx.data")
    if data_file.exists():
        import onnx as onnx_lib
        proto = onnx_lib.load(str(output), load_external_data=True)
        output.unlink()
        data_file.unlink()
        onnx_lib.save(proto, str(output), save_as_external_data=False)

    size_kb = output.stat().st_size // 1024
    print(f"Done — {size_kb} KB")

    # Sanity-Check via onnxruntime (optional)
    try:
        import onnxruntime as ort
        sess = ort.InferenceSession(str(output), providers=["CPUExecutionProvider"])
        result = sess.run(None, {"input": dummy.numpy()})
        out_shape = result[0].shape
        assert out_shape == (1, 1, patch_size, patch_size), f"unexpected output shape: {out_shape}"
        print(f"ONNX-Sanity-Check: output shape = {out_shape} ✓")
    except ImportError:
        print("Hinweis: pip install onnxruntime für Sanity-Check")
    except Exception as e:
        print(f"Sanity-Check Fehler: {e}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", choices=["cnn", "unet"], default="cnn",
                    help="Modell-Typ: 'cnn' (Symbol-Klassifikator) oder 'unet' (Staff-Removal)")
    ap.add_argument("--weights", type=Path, required=True,
                    help="Pfad zur .pt Datei vom Training")
    ap.add_argument("--output", type=Path, required=True,
                    help="Ziel-Pfad für die .onnx Datei")
    ap.add_argument("--input-size", type=int, default=64,
                    help="(CNN) Eingabegröße in Pixeln")
    ap.add_argument("--patch-size", type=int, default=256,
                    help="(U-Net) Patch-Größe für Export-Dummy")
    ap.add_argument("--opset", type=int, default=14)
    args = ap.parse_args()

    if args.model == "unet":
        export_unet(args.weights, args.output, args.patch_size, args.opset)
        return

    # --- CNN (legacy) ---
    args.output.parent.mkdir(parents=True, exist_ok=True)
    model = build_cnn_model(N_CLASSES)
    model.load_state_dict(torch.load(str(args.weights), map_location="cpu"))
    model.eval()

    dummy_input = torch.randn(1, 3, args.input_size, args.input_size)

    print(f"Exportiere CNN {args.weights} → {args.output}")
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

    try:
        import onnxruntime as ort
        sess = ort.InferenceSession(str(args.output), providers=["CPUExecutionProvider"])
        result = sess.run(None, {"input": dummy_input.numpy()})
        print(f"ONNX-Sanity-Check: output shape = {result[0].shape}")
    except ImportError:
        print("Hinweis: pip install onnxruntime fuer Sanity-Check")


if __name__ == "__main__":
    main()
