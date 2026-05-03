"""
Triplet-Embedding-Training fuer OMR-Symbole.

Trainiert MobileNetV3-Small-Backbone mit projection-head zu 256-dim Embeddings.
Triplet-Loss mit online-Mining auf synthetic_corpus_v1.

Output:
    models/symbol_encoder_v1.pt   # PyTorch state-dict (bestes Epoch nach val top-1)
    models/symbol_encoder_v1.onnx # ONNX-Export fuer omr-embed::OnnxCnnEncoder
    models/symbol_encoder_v1.json # Class-Mapping + Trainings-Metadaten
    models/symbol_encoder_v1.log  # Epoch-Log (CSV)

Usage:
    python train_embedding.py --corpus data/synthetic_corpus_v1/single
    python train_embedding.py --corpus data/synthetic_corpus_v1/single --epochs 2 --device cpu
"""
from __future__ import annotations

import argparse
import io
import json
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    import numpy as np
    import torch
    import torch.nn as nn
    import torch.nn.functional as F
    from torch.utils.data import DataLoader, Dataset
    from torchvision import transforms
    from torchvision.models import mobilenet_v3_small
except ImportError as e:
    print(f"FEHLER: {e}\n  pip install torch torchvision", file=sys.stderr)
    sys.exit(2)

try:
    from PIL import Image
except ImportError:
    print("FEHLER: pip install Pillow", file=sys.stderr)
    sys.exit(2)


# ---- Corpus utilities -------------------------------------------------------

def discover_classes(root: Path) -> Tuple[List[str], Dict[str, int]]:
    """Findet alle Leaf-Klassen in root (category/class Struktur)."""
    classes = []
    for cat_dir in sorted(root.iterdir()):
        if not cat_dir.is_dir():
            continue
        for cls_dir in sorted(cat_dir.iterdir()):
            if not cls_dir.is_dir():
                continue
            if any(cls_dir.glob("*.png")):
                classes.append(f"{cat_dir.name}/{cls_dir.name}")
    class_to_idx = {c: i for i, c in enumerate(classes)}
    return classes, class_to_idx


def load_corpus(
    root: Path,
    max_per_class: Optional[int] = None,
    seed: int = 42,
) -> Tuple[List[str], Dict[str, int], Dict[str, List[Path]]]:
    """Laedt alle Samples aus root, optional mit max_per_class Limit."""
    classes, class_to_idx = discover_classes(root)
    rng = np.random.default_rng(seed)
    class_to_files: Dict[str, List[Path]] = {}
    for cls_name in classes:
        cat, cls = cls_name.split("/", 1)
        cls_dir = root / cat / cls
        files = sorted(cls_dir.glob("*.png"))
        if max_per_class and len(files) > max_per_class:
            idxs = rng.choice(len(files), max_per_class, replace=False)
            files = [files[i] for i in sorted(idxs)]
        class_to_files[cls_name] = list(files)
    return classes, class_to_idx, class_to_files


# ---- Dataset ----------------------------------------------------------------

class TripletDataset(Dataset):
    """Liefert (anchor, positive, negative) Triplets aus dem Corpus.

    Pro Epoch werden n_triplets zufaellige Triplets generiert.
    Aufruf von _regenerate_triplets() am Anfang jeder Epoch erzeugt neue Triplets.
    """

    def __init__(
        self,
        root: Path,
        class_to_files: Dict[str, List[Path]],
        class_to_idx: Dict[str, int],
        n_triplets: int,
        transform=None,
        seed: int = 42,
    ):
        self.root = root
        self.class_to_files = class_to_files
        self.class_to_idx = class_to_idx
        self.classes = [c for c in class_to_files if len(class_to_files[c]) >= 2]
        self.all_classes = list(class_to_files.keys())
        self.n_triplets = n_triplets
        self.transform = transform
        self.rng = np.random.default_rng(seed)
        self._regenerate_triplets()

    def _regenerate_triplets(self):
        """Generiert neue zufaellige Triplets (einmal pro Epoch aufrufen)."""
        triplets = []
        for _ in range(self.n_triplets):
            anc_cls = self.rng.choice(self.classes)
            files = self.class_to_files[anc_cls]
            idx_a, idx_p = self.rng.choice(len(files), size=2, replace=False)
            neg_cls = anc_cls
            while neg_cls == anc_cls:
                neg_cls = self.rng.choice(self.all_classes)
            neg_files = self.class_to_files[neg_cls]
            idx_n = int(self.rng.integers(0, len(neg_files)))
            triplets.append((
                files[idx_a],
                files[idx_p],
                neg_files[idx_n],
                self.class_to_idx[anc_cls],
                self.class_to_idx[neg_cls],
            ))
        self.triplets = triplets

    def __len__(self) -> int:
        return len(self.triplets)

    def __getitem__(self, idx):
        anc_path, pos_path, neg_path, anc_label, neg_label = self.triplets[idx]
        return (
            self._load(anc_path),
            self._load(pos_path),
            self._load(neg_path),
            anc_label,
            neg_label,
        )

    def _load(self, path: Path) -> "torch.Tensor":
        img = Image.open(path).convert("RGB")
        if self.transform:
            img = self.transform(img)
        return img


# ---- Model ------------------------------------------------------------------

class EmbeddingModel(nn.Module):
    """MobileNetV3-Small + projection-head zu embedding_dim-dim L2-normalized.

    Input:  [B, 3, 64, 64]  (RGB, ImageNet-normiert)
    Output: [B, embedding_dim]  (L2-normiert)
    """

    def __init__(self, embedding_dim: int = 256):
        super().__init__()
        backbone = mobilenet_v3_small(weights=None)
        in_features = backbone.classifier[0].in_features
        backbone.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.Hardswish(),
            nn.Dropout(p=0.2),
            nn.Linear(512, embedding_dim),
        )
        self.backbone = backbone

    def forward(self, x: "torch.Tensor") -> "torch.Tensor":
        x = self.backbone(x)
        return F.normalize(x, dim=1)


# ---- Loss -------------------------------------------------------------------

def triplet_loss(
    anchor: "torch.Tensor",
    positive: "torch.Tensor",
    negative: "torch.Tensor",
    margin: float = 0.5,
) -> "torch.Tensor":
    """Standard Triplet-Loss mit cosine distance."""
    pos_dist = 1.0 - (anchor * positive).sum(dim=1)
    neg_dist = 1.0 - (anchor * negative).sum(dim=1)
    return torch.clamp(pos_dist - neg_dist + margin, min=0.0).mean()


# ---- Transforms -------------------------------------------------------------

def build_transforms(train: bool) -> "transforms.Compose":
    mean = [0.485, 0.456, 0.406]
    std = [0.229, 0.224, 0.225]
    if train:
        return transforms.Compose([
            transforms.Resize((64, 64)),
            transforms.RandomAffine(degrees=5, translate=(0.05, 0.05), scale=(0.9, 1.1)),
            transforms.ColorJitter(brightness=0.2, contrast=0.2),
            transforms.RandomApply([transforms.GaussianBlur(3, sigma=(0.1, 0.5))], p=0.3),
            transforms.ToTensor(),
            transforms.Normalize(mean=mean, std=std),
        ])
    return transforms.Compose([
        transforms.Resize((64, 64)),
        transforms.ToTensor(),
        transforms.Normalize(mean=mean, std=std),
    ])


# ---- Validation -------------------------------------------------------------

@torch.no_grad()
def knn_accuracy(
    model: nn.Module,
    val_files: List[Tuple[Path, int]],
    device: "torch.device",
) -> Dict[str, float]:
    """k-NN-Accuracy (Leave-One-Out) auf val_files."""
    model.eval()
    transform = build_transforms(False)
    embeddings, labels = [], []
    for path, lbl in val_files:
        img = Image.open(path).convert("RGB")
        x = transform(img).unsqueeze(0).to(device)
        emb = model(x).cpu().numpy()[0]
        embeddings.append(emb)
        labels.append(lbl)
    emb_arr = np.array(embeddings, dtype=np.float32)
    lbl_arr = np.array(labels, dtype=np.int32)
    norms = np.linalg.norm(emb_arr, axis=1, keepdims=True)
    normed = emb_arr / (norms + 1e-8)
    sim = normed @ normed.T
    results = {}
    for k in [1, 3, 5]:
        if k >= len(lbl_arr):
            continue
        correct = 0
        for i in range(len(lbl_arr)):
            row = sim[i].copy()
            row[i] = -1e9
            top_idx = np.argsort(row)[::-1][:k]
            if lbl_arr[i] in lbl_arr[top_idx]:
                correct += 1
        results[f"top{k}"] = correct / len(lbl_arr)
    return results


# ---- Export -----------------------------------------------------------------

def export_onnx(model: nn.Module, output_path: Path, device=None) -> float:
    """Export PyTorch model als ONNX (input [1, 3, 64, 64], output [1, dim])."""
    model.eval()
    model_cpu = model.cpu()
    dummy = torch.randn(1, 3, 64, 64)
    torch.onnx.export(
        model_cpu,
        dummy,
        str(output_path),
        input_names=["input"],
        output_names=["embedding"],
        opset_version=17,
        dynamic_axes={"input": {0: "batch"}, "embedding": {0: "batch"}},
        do_constant_folding=True,
    )
    size_kb = output_path.stat().st_size / 1024
    print(f"ONNX-Export: {output_path} ({size_kb:.0f} KB)")
    return size_kb


def verify_onnx(model: nn.Module, onnx_path: Path) -> float:
    """Verifikation: max(|pytorch_output - onnx_output|) < 1e-3."""
    try:
        import onnxruntime as ort
    except ImportError:
        print("  (onnxruntime nicht installiert, Verifikation uebersprungen)")
        return float("nan")
    model.eval()
    dummy = torch.randn(1, 3, 64, 64)
    with torch.no_grad():
        pt_out = model.cpu()(dummy).numpy()
    sess = ort.InferenceSession(str(onnx_path))
    ort_out = sess.run(["embedding"], {"input": dummy.numpy()})[0]
    max_diff = float(np.abs(pt_out - ort_out).max())
    print(f"  ONNX-Verifikation: max_diff={max_diff:.2e} (threshold=1e-3)")
    assert max_diff < 1e-3, f"ONNX output weicht zu stark ab: max_diff={max_diff}"
    return max_diff


# ---- Training ---------------------------------------------------------------

def train(args) -> Tuple[nn.Module, Path, float]:
    """Triplet-Training-Pipeline. Gibt (model, onnx_path, best_val_top1) zurueck."""
    corpus_root = Path(args.corpus)
    if not corpus_root.exists():
        corpus_root = Path(__file__).parent / args.corpus
    if not corpus_root.exists():
        print(f"FEHLER: Corpus nicht gefunden: {corpus_root}", file=sys.stderr)
        sys.exit(1)

    output_prefix = Path(args.output)
    output_prefix.parent.mkdir(parents=True, exist_ok=True)

    device_str = args.device
    if device_str == "auto":
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    else:
        device = torch.device(device_str)
    print(f"Device: {device}")

    torch.manual_seed(42)
    np.random.seed(42)

    classes, class_to_idx, class_to_files = load_corpus(corpus_root)
    n_classes = len(classes)
    total_samples = sum(len(v) for v in class_to_files.values())
    print(f"Korpus: {n_classes} Klassen, {total_samples} Samples in {corpus_root}")

    rng = np.random.default_rng(42)
    val_files: List[Tuple[Path, int]] = []
    train_files: Dict[str, List[Path]] = {}
    for cls_name, files in class_to_files.items():
        n_val = max(1, int(len(files) * 0.1))
        val_idxs = set(rng.choice(len(files), n_val, replace=False).tolist())
        val_files.extend((files[i], class_to_idx[cls_name]) for i in val_idxs)
        train_files[cls_name] = [f for i, f in enumerate(files) if i not in val_idxs]

    n_train = sum(len(v) for v in train_files.values())
    print(f"Train: {n_train}  Val: {len(val_files)}")

    train_ds = TripletDataset(
        root=corpus_root,
        class_to_files=train_files,
        class_to_idx=class_to_idx,
        n_triplets=args.n_triplets_per_epoch,
        transform=build_transforms(True),
        seed=42,
    )
    loader = DataLoader(
        train_ds,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=0,
        pin_memory=(device.type == "cuda"),
    )

    model = EmbeddingModel(embedding_dim=args.embedding_dim).to(device)
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs)

    best_val_top1 = 0.0
    best_epoch = 0
    log_rows = ["epoch,loss,top1,top3,top5,lr"]
    pt_path = Path(str(output_prefix) + ".pt")

    for epoch in range(args.epochs):
        t0 = time.time()
        train_ds._regenerate_triplets()
        model.train()
        total_loss = 0.0
        n_batches = 0
        for anchors, positives, negatives, _, _ in loader:
            anchors = anchors.to(device)
            positives = positives.to(device)
            negatives = negatives.to(device)
            emb_a = model(anchors)
            emb_p = model(positives)
            emb_n = model(negatives)
            loss = triplet_loss(emb_a, emb_p, emb_n, margin=args.margin)
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
            n_batches += 1
        scheduler.step()
        avg_loss = total_loss / max(n_batches, 1)
        elapsed = time.time() - t0
        val_acc = knn_accuracy(model, val_files, device)
        top1 = val_acc.get("top1", 0.0)
        top3 = val_acc.get("top3", 0.0)
        top5 = val_acc.get("top5", 0.0)
        lr_now = optimizer.param_groups[0]["lr"]
        print(
            f"Epoch {epoch+1:3d}/{args.epochs}  loss={avg_loss:.4f}"
            f"  top1={top1:.4f}  top3={top3:.4f}  top5={top5:.4f}"
            f"  lr={lr_now:.2e}  ({elapsed:.1f}s)"
        )
        log_rows.append(f"{epoch+1},{avg_loss:.4f},{top1:.4f},{top3:.4f},{top5:.4f},{lr_now:.6f}")
        if top1 > best_val_top1:
            best_val_top1 = top1
            best_epoch = epoch + 1
            torch.save(model.state_dict(), str(pt_path))
            print(f"  -> Best model saved (top1={top1:.4f})")

    if not pt_path.exists():
        torch.save(model.state_dict(), str(pt_path))

    log_path = Path(str(output_prefix) + ".log")
    log_path.write_text("\n".join(log_rows), encoding="utf-8")
    print(f"\nBest val top-1: {best_val_top1:.4f} (epoch {best_epoch})")

    model.load_state_dict(torch.load(str(pt_path), map_location="cpu", weights_only=True))
    model.eval()
    onnx_path = Path(str(output_prefix) + ".onnx")
    size_kb = export_onnx(model, onnx_path)
    verify_onnx(model, onnx_path)

    json_path = Path(str(output_prefix) + ".json")
    json_path.write_text(
        json.dumps({
            "class_names": classes,
            "class_to_idx": class_to_idx,
            "embedding_dim": args.embedding_dim,
            "margin": args.margin,
            "best_val_top1": best_val_top1,
            "best_epoch": best_epoch,
            "epochs_trained": args.epochs,
            "architecture": "MobileNetV3-Small + projection",
            "corpus": str(corpus_root),
            "n_classes": n_classes,
            "input_shape": [1, 3, 64, 64],
            "output_shape": [1, args.embedding_dim],
            "onnx_size_kb": round(size_kb, 1),
        }, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"Class-Mapping: {json_path}")
    print(f"DONE. Model: {output_prefix}.pt / .onnx / .json")
    return model, onnx_path, best_val_top1


# ---- CLI --------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Triplet-Embedding-Training fuer OMR-Symbole")
    parser.add_argument("--corpus", default="data/synthetic_corpus_v1/single")
    parser.add_argument("--output", default="models/symbol_encoder_v1")
    parser.add_argument("--epochs", type=int, default=30)
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--embedding-dim", type=int, default=256)
    parser.add_argument("--margin", type=float, default=0.5)
    parser.add_argument("--device", default="auto")
    parser.add_argument("--n-triplets-per-epoch", type=int, default=10000)
    args = parser.parse_args()
    train(args)


if __name__ == "__main__":
    main()