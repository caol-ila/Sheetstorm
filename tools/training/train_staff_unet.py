"""
train_staff_unet.py

Trainiert ein leichtgewichtiges U-Net für Staff-Line-Removal aus
Notenbild-Patches. Nutzt den Synth-Corpus (Verovio-rendered) als
Trainingsdaten:
  - Input: Original-Page mit Stafflinien
  - Target: Stafflinien-entfernte Version (kann via klassischer
    omr-staff-Pipeline erzeugt werden ODER via SVG-Rendering ohne
    Stafflinien)

U-Net-Architektur:
  - Encoder: 3 Downsampling-Stages (32 → 64 → 128 Kanäle)
  - Decoder: 3 Upsampling-Stages mit Skip-Connections
  - Output: 1-channel Sigmoid (Wahrscheinlichkeit für "ist Symbol-Pixel")

Aufruf:
    python train_staff_unet.py \\
        --input-dir ../synth-corpus/data/pages \\
        --target-dir ../synth-corpus/data/pages-staff-removed \\
        --output models/staff_unet \\
        --epochs 30
"""
from __future__ import annotations
import argparse
import io
import sys
from pathlib import Path

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    import numpy as np
    import torch
    import torch.nn as nn
    import torch.nn.functional as F
    from torch.utils.data import Dataset, DataLoader
except ImportError:
    print("FEHLER: pip install torch", file=sys.stderr)
    sys.exit(2)
try:
    from PIL import Image
except ImportError:
    print("FEHLER: pip install Pillow", file=sys.stderr)
    sys.exit(2)


class StaffRemovalDataset(Dataset):
    def __init__(self, input_dir: Path, target_dir: Path, patch_size: int = 256):
        self.input_dir = Path(input_dir)
        self.target_dir = Path(target_dir)
        self.patch_size = patch_size
        self.pairs = []
        for img in self.input_dir.glob("*.png"):
            target = self.target_dir / img.name
            if target.exists():
                self.pairs.append((img, target))
        print(f"Dataset: {len(self.pairs)} input/target Paare")

    def __len__(self):
        return len(self.pairs)

    def __getitem__(self, idx):
        in_path, tgt_path = self.pairs[idx]
        inp = Image.open(in_path).convert("L")
        tgt = Image.open(tgt_path).convert("L")
        # Random crop
        ps = self.patch_size
        max_x = max(0, inp.width - ps)
        max_y = max(0, inp.height - ps)
        rx = np.random.randint(0, max_x + 1)
        ry = np.random.randint(0, max_y + 1)
        inp = inp.crop((rx, ry, rx + ps, ry + ps))
        tgt = tgt.crop((rx, ry, rx + ps, ry + ps))
        inp_np = np.array(inp, dtype=np.float32) / 255.0
        tgt_np = np.array(tgt, dtype=np.float32) / 255.0
        # Targets: 1 = symbol, 0 = staff-line oder weiß
        # Wir invertieren: schwarze Pixel = symbol = 1
        tgt_mask = (tgt_np < 0.5).astype(np.float32)
        return torch.tensor(inp_np).unsqueeze(0), torch.tensor(tgt_mask).unsqueeze(0)


class DoubleConv(nn.Module):
    def __init__(self, in_ch, out_ch):
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
    """Leichtgewichtiges U-Net (~250k params). Optimiert fuer schnelles
    Inferenz auf CPU/Mobile."""
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
        e1 = self.enc1(x); p1 = self.pool1(e1)
        e2 = self.enc2(p1); p2 = self.pool2(e2)
        e3 = self.enc3(p2); p3 = self.pool3(e3)
        b = self.bridge(p3)
        u3 = self.up3(b); d3 = self.dec3(torch.cat([u3, e3], dim=1))
        u2 = self.up2(d3); d2 = self.dec2(torch.cat([u2, e2], dim=1))
        u1 = self.up1(d2); d1 = self.dec1(torch.cat([u1, e1], dim=1))
        return torch.sigmoid(self.out(d1))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input-dir", type=Path, required=True)
    ap.add_argument("--target-dir", type=Path, required=True)
    ap.add_argument("--output", type=Path, default=Path("models/staff_unet"))
    ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--batch-size", type=int, default=8)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--patch-size", type=int, default=256)
    ap.add_argument("--cpu", action="store_true")
    args = ap.parse_args()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    device = torch.device("cuda" if (not args.cpu and torch.cuda.is_available()) else "cpu")
    print(f"Device: {device}")

    ds = StaffRemovalDataset(args.input_dir, args.target_dir, args.patch_size)
    if len(ds) == 0:
        print("FEHLER: keine Trainingsdaten gefunden", file=sys.stderr)
        sys.exit(1)
    loader = DataLoader(ds, batch_size=args.batch_size, shuffle=True, num_workers=2,
                        pin_memory=device.type == "cuda")

    model = StaffRemovalUNet().to(device)
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr)
    bce = nn.BCELoss()

    best_loss = float("inf")
    for epoch in range(args.epochs):
        model.train()
        total = 0.0
        n = 0
        for inp, tgt in loader:
            inp = inp.to(device); tgt = tgt.to(device)
            optimizer.zero_grad()
            pred = model(inp)
            loss = bce(pred, tgt)
            loss.backward()
            optimizer.step()
            total += loss.item() * inp.size(0)
            n += inp.size(0)
        avg = total / max(n, 1)
        print(f"Epoch {epoch+1}/{args.epochs}  loss={avg:.5f}")
        if avg < best_loss:
            best_loss = avg
            torch.save(model.state_dict(), str(args.output) + ".pt")
            print(f"  → Modell gespeichert ({avg:.5f})")

    # ONNX export
    model.eval()
    dummy = torch.randn(1, 1, args.patch_size, args.patch_size).to(device)
    onnx_path = str(args.output) + ".onnx"
    torch.onnx.export(
        model, dummy, onnx_path,
        export_params=True, opset_version=14,
        input_names=["input"], output_names=["mask"],
        dynamic_axes={"input": {0: "batch", 2: "height", 3: "width"},
                      "mask": {0: "batch", 2: "height", 3: "width"}},
    )
    print(f"\nU-Net exportiert: {onnx_path}")


if __name__ == "__main__":
    main()
