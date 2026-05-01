"""
train_cnn.py

CNN-Training für Sheetstorm-Symbol-Klassifikation. Architektur:
  MobileNetV3-Small (transfer-trained from ImageNet) → 47-class output

Inputs:  64x64 grayscale patches (auto-converted to 3-channel for ImageNet pretrained)
Output:  symbol_classifier.pt + symbol_classifier.onnx

Training:
  - 80/20 train/val split per class (stratified)
  - AdamW optimizer, cosine LR schedule
  - Augmentation: random crop, slight rotation (±5°), brightness, noise
  - Class-balanced sampling (weighted)
  - Mixed precision (FP16) auf GPU für Speed
  - Early stopping nach 5 epochs ohne val-improvement

Aufruf:
    python train_cnn.py \\
        --data data/training \\
        --output models/symbol_classifier \\
        --epochs 50 \\
        --batch-size 128
"""
from __future__ import annotations
import argparse
import io
import os
import sys
import time
from pathlib import Path
from typing import List, Optional

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    import numpy as np
    import torch
    import torch.nn as nn
    import torch.nn.functional as F
    from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler
    from torchvision import models, transforms
except ImportError as e:
    print(f"FEHLER: {e}\n  pip install torch torchvision", file=sys.stderr)
    sys.exit(2)

try:
    from PIL import Image
except ImportError:
    print("FEHLER: pip install Pillow", file=sys.stderr)
    sys.exit(2)

CLASS_NAMES = [
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
]
N_CLASSES = len(CLASS_NAMES)
assert N_CLASSES == 48, f"Erwarte 48 Klassen, gefunden {N_CLASSES}"


class SymbolPatchDataset(Dataset):
    """Lädt 64x64-Grayscale-Patches aus Verzeichnisstruktur:
        data_dir/
            00_NoteheadFilled/sample_*.png
            01_NoteheadOpen/sample_*.png
            ...
    """
    def __init__(self, data_dir: Path, transform=None, file_list: Optional[List[tuple]] = None):
        self.data_dir = Path(data_dir)
        self.transform = transform
        if file_list is not None:
            self.samples = file_list
        else:
            self.samples = []
            for cls_dir in sorted(self.data_dir.iterdir()):
                if not cls_dir.is_dir(): continue
                cls_name = cls_dir.name
                # Format: "01_ClassName"
                if "_" in cls_name:
                    try:
                        cid = int(cls_name.split("_", 1)[0])
                    except ValueError:
                        continue
                else:
                    continue
                if cid >= N_CLASSES: continue
                for img_path in cls_dir.glob("*.png"):
                    self.samples.append((str(img_path), cid))
            print(f"Dataset: {len(self.samples)} samples in {self.data_dir}")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        path, cid = self.samples[idx]
        img = Image.open(path).convert("L")
        # 1-channel zu 3-channel für ImageNet-pretrained MobileNet
        img = img.convert("RGB")
        if self.transform:
            img = self.transform(img)
        return img, cid


def get_transforms(train: bool):
    if train:
        return transforms.Compose([
            transforms.Resize((64, 64)),
            transforms.RandomAffine(degrees=4, translate=(0.05, 0.05), scale=(0.9, 1.1)),
            transforms.ColorJitter(brightness=0.15, contrast=0.15),
            transforms.RandomApply([transforms.GaussianBlur(3, sigma=(0.1, 0.5))], p=0.3),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])
    else:
        return transforms.Compose([
            transforms.Resize((64, 64)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])


def stratified_split(samples: List[tuple], val_ratio: float = 0.2, seed: int = 42):
    """Pro Klasse 80/20 split. Returns (train_list, val_list)."""
    by_class: dict = {}
    for path, cid in samples:
        by_class.setdefault(cid, []).append((path, cid))
    rng = np.random.default_rng(seed)
    train_list, val_list = [], []
    for cid, items in by_class.items():
        rng.shuffle(items)
        n_val = max(1, int(len(items) * val_ratio))
        val_list.extend(items[:n_val])
        train_list.extend(items[n_val:])
    return train_list, val_list


def build_model(n_classes: int = N_CLASSES, pretrained: bool = True):
    weights = models.MobileNet_V3_Small_Weights.IMAGENET1K_V1 if pretrained else None
    model = models.mobilenet_v3_small(weights=weights)
    # Letzten FC ersetzen
    in_features = model.classifier[-1].in_features
    model.classifier[-1] = nn.Linear(in_features, n_classes)
    return model


def class_weights(samples: List[tuple], n_classes: int = N_CLASSES) -> torch.Tensor:
    counts = np.zeros(n_classes, dtype=np.float64)
    for _, cid in samples:
        counts[cid] += 1
    counts = np.maximum(counts, 1.0)
    weights = 1.0 / counts
    weights = weights / weights.mean()
    return torch.tensor(weights, dtype=torch.float32)


def train_one_epoch(model, loader, optimizer, criterion, device, scaler=None):
    model.train()
    total_loss = 0.0
    correct = 0
    total = 0
    for imgs, labels in loader:
        imgs = imgs.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)
        optimizer.zero_grad()
        if scaler is not None:
            with torch.cuda.amp.autocast():
                out = model(imgs)
                loss = criterion(out, labels)
            scaler.scale(loss).backward()
            scaler.step(optimizer)
            scaler.update()
        else:
            out = model(imgs)
            loss = criterion(out, labels)
            loss.backward()
            optimizer.step()
        total_loss += loss.item() * imgs.size(0)
        preds = out.argmax(dim=1)
        correct += (preds == labels).sum().item()
        total += imgs.size(0)
    return total_loss / max(total, 1), correct / max(total, 1)


def evaluate(model, loader, criterion, device):
    model.eval()
    total_loss = 0.0
    correct = 0
    total = 0
    confusion = np.zeros((N_CLASSES, N_CLASSES), dtype=np.int64)
    with torch.no_grad():
        for imgs, labels in loader:
            imgs = imgs.to(device, non_blocking=True)
            labels = labels.to(device, non_blocking=True)
            out = model(imgs)
            loss = criterion(out, labels)
            total_loss += loss.item() * imgs.size(0)
            preds = out.argmax(dim=1)
            correct += (preds == labels).sum().item()
            total += imgs.size(0)
            for t, p in zip(labels.cpu().numpy(), preds.cpu().numpy()):
                confusion[t, p] += 1
    return total_loss / max(total, 1), correct / max(total, 1), confusion


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", type=Path, required=True,
                    help="Verzeichnis mit Klassen-Unterordnern")
    ap.add_argument("--output", type=Path, default=Path("models/symbol_classifier"),
                    help="Output-Praefix (.pt + .onnx + .log werden geschrieben)")
    ap.add_argument("--epochs", type=int, default=50)
    ap.add_argument("--batch-size", type=int, default=128)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--val-ratio", type=float, default=0.2)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--patience", type=int, default=5,
                    help="Early-Stop nach N Epochs ohne val-Verbesserung")
    ap.add_argument("--num-workers", type=int, default=2)
    ap.add_argument("--cpu", action="store_true")
    args = ap.parse_args()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    torch.manual_seed(args.seed)
    np.random.seed(args.seed)

    device = torch.device("cuda" if (not args.cpu and torch.cuda.is_available()) else "cpu")
    print(f"Device: {device}")

    full = SymbolPatchDataset(args.data, transform=None)
    if len(full) == 0:
        print("FEHLER: keine Samples gefunden", file=sys.stderr)
        sys.exit(1)

    train_samples, val_samples = stratified_split(full.samples, args.val_ratio, args.seed)
    print(f"Train: {len(train_samples)}  Val: {len(val_samples)}")

    train_ds = SymbolPatchDataset(args.data, transform=get_transforms(True), file_list=train_samples)
    val_ds = SymbolPatchDataset(args.data, transform=get_transforms(False), file_list=val_samples)

    # Weighted sampling für Class-Balance
    cw = class_weights(train_samples, N_CLASSES)
    sample_weights = torch.tensor([cw[cid].item() for _, cid in train_samples], dtype=torch.float32)
    sampler = WeightedRandomSampler(sample_weights, num_samples=len(train_samples), replacement=True)

    train_loader = DataLoader(train_ds, batch_size=args.batch_size, sampler=sampler,
                              num_workers=args.num_workers, pin_memory=device.type == "cuda")
    val_loader = DataLoader(val_ds, batch_size=args.batch_size, shuffle=False,
                            num_workers=args.num_workers, pin_memory=device.type == "cuda")

    model = build_model(N_CLASSES, pretrained=True).to(device)
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs)
    criterion = nn.CrossEntropyLoss(weight=cw.to(device))
    scaler = torch.cuda.amp.GradScaler() if device.type == "cuda" else None

    best_val_acc = 0.0
    epochs_without_improvement = 0
    log_path = args.output.with_suffix(".log")
    with log_path.open("w", encoding="utf-8") as logf:
        logf.write("epoch,train_loss,train_acc,val_loss,val_acc,lr\n")
        for epoch in range(args.epochs):
            t0 = time.time()
            train_loss, train_acc = train_one_epoch(model, train_loader, optimizer, criterion, device, scaler)
            val_loss, val_acc, confusion = evaluate(model, val_loader, criterion, device)
            scheduler.step()
            lr_now = optimizer.param_groups[0]["lr"]
            elapsed = time.time() - t0
            print(f"Epoch {epoch+1}/{args.epochs}  train_loss={train_loss:.4f} train_acc={train_acc:.4f}"
                  f"  val_loss={val_loss:.4f} val_acc={val_acc:.4f}  lr={lr_now:.2e}  ({elapsed:.1f}s)")
            logf.write(f"{epoch+1},{train_loss:.4f},{train_acc:.4f},{val_loss:.4f},{val_acc:.4f},{lr_now:.6f}\n")
            logf.flush()
            if val_acc > best_val_acc:
                best_val_acc = val_acc
                torch.save(model.state_dict(), str(args.output) + ".pt")
                print(f"  → bestes Modell gespeichert ({val_acc:.4f})")
                epochs_without_improvement = 0
            else:
                epochs_without_improvement += 1
                if epochs_without_improvement >= args.patience:
                    print(f"  Early-Stop nach {args.patience} Epochs ohne val-Verbesserung")
                    break

    print(f"\nBeste Val-Accuracy: {best_val_acc:.4f}")

    # Final evaluation + Confusion-Matrix
    model.load_state_dict(torch.load(str(args.output) + ".pt"))
    val_loss, val_acc, confusion = evaluate(model, val_loader, criterion, device)
    print(f"Final Val-Accuracy: {val_acc:.4f}")
    np.savetxt(str(args.output) + ".confusion.csv", confusion, fmt="%d", delimiter=",",
               header=",".join(CLASS_NAMES))
    print(f"Confusion-Matrix: {args.output}.confusion.csv")
    print(f"Modell:           {args.output}.pt")


if __name__ == "__main__":
    main()
