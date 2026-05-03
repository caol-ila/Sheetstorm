"""
Evaluiert ein trainiertes Embedding-Modell auf k-NN-Accuracy.

Usage:
    python eval_embedding.py --model models/symbol_encoder_v1.pt \\
                             --corpus data/synthetic_corpus_v1/single

Output (stdout):
    Top-1 / Top-3 / Top-5 Accuracy
    Per-Class-Metrics (precision/recall/F1)
    Schwächste Klassen

Output (Dateien, mit --output):
    <prefix>.confusion.csv   # Confusion-Matrix
    <prefix>.metrics.json    # Alle Metriken als JSON
"""
from __future__ import annotations

import argparse
import io
import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    import numpy as np
    import torch
    from torchvision import transforms
except ImportError as e:
    print(f"FEHLER: {e}\n  pip install torch torchvision", file=sys.stderr)
    sys.exit(2)

try:
    from PIL import Image
except ImportError:
    print("FEHLER: pip install Pillow", file=sys.stderr)
    sys.exit(2)

sys.path.insert(0, str(Path(__file__).parent))
from train_embedding import EmbeddingModel, load_corpus


# ── Embedding computation ─────────────────────────────────────────────────────

def embed_all(
    model: torch.nn.Module,
    files: List[Tuple[Path, int]],
    device: torch.device,
) -> Tuple[np.ndarray, np.ndarray]:
    """Bettet alle Dateien ein. Gibt (embeddings [N, D], labels [N]) zurück."""
    transform = transforms.Compose([
        transforms.Resize((64, 64)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    model.eval()
    embeddings, labels = [], []

    with torch.no_grad():
        for path, lbl in files:
            img = Image.open(path).convert("RGB")
            x = transform(img).unsqueeze(0).to(device)
            emb = model(x).cpu().numpy()[0]
            embeddings.append(emb)
            labels.append(lbl)

    return np.array(embeddings, dtype=np.float32), np.array(labels, dtype=np.int32)


# ── Metrics ───────────────────────────────────────────────────────────────────

def knn_eval(
    embeddings: np.ndarray,
    labels: np.ndarray,
    k_values: Tuple[int, ...] = (1, 3, 5),
) -> Dict[str, float]:
    """k-NN Accuracy mit Leave-One-Out."""
    norms = np.linalg.norm(embeddings, axis=1, keepdims=True)
    normed = embeddings / (norms + 1e-8)
    sim = normed @ normed.T

    results = {}
    for k in k_values:
        if k >= len(labels):
            continue
        correct = 0
        for i in range(len(labels)):
            row = sim[i].copy()
            row[i] = -1e9
            top_idx = np.argsort(row)[::-1][:k]
            if labels[i] in labels[top_idx]:
                correct += 1
        results[f"top{k}"] = correct / len(labels)
    return results


def build_confusion_matrix(
    labels: np.ndarray,
    preds: np.ndarray,
    n_classes: int,
) -> np.ndarray:
    cm = np.zeros((n_classes, n_classes), dtype=np.int32)
    for t, p in zip(labels, preds):
        cm[t, p] += 1
    return cm


def per_class_metrics(cm: np.ndarray, class_names: List[str]) -> List[Dict]:
    metrics = []
    for i, name in enumerate(class_names):
        tp = int(cm[i, i])
        fp = int(cm[:, i].sum()) - tp
        fn = int(cm[i, :].sum()) - tp
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        f1 = (2 * precision * recall / (precision + recall)
              if (precision + recall) > 0 else 0.0)
        metrics.append({
            "class": name,
            "precision": round(precision, 4),
            "recall": round(recall, 4),
            "f1": round(f1, 4),
            "support": int(cm[i].sum()),
        })
    return metrics


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Evaluiert ein trainiertes Embedding-Modell")
    parser.add_argument("--model", required=True, help="Pfad zur .pt Modell-Datei")
    parser.add_argument("--corpus", default="data/synthetic_corpus_v1/single",
                        help="Pfad zum Corpus-Verzeichnis")
    parser.add_argument("--embedding-dim", type=int, default=256)
    parser.add_argument("--device", default="auto", help="auto|cpu|cuda")
    parser.add_argument("--output", default=None,
                        help="Optionaler Praefix fuer Ausgabe-Dateien (.confusion.csv, .metrics.json)")
    args = parser.parse_args()

    if args.device == "auto":
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    else:
        device = torch.device(args.device)

    corpus_root = Path(args.corpus)
    if not corpus_root.exists():
        corpus_root = Path(__file__).parent / args.corpus

    classes, class_to_idx, class_to_files = load_corpus(corpus_root)
    n_classes = len(classes)
    total = sum(len(v) for v in class_to_files.values())
    print(f"Klassen: {n_classes}, Samples: {total}, Device: {device}")

    all_files: List[Tuple[Path, int]] = [
        (f, class_to_idx[cls])
        for cls, files in class_to_files.items()
        for f in files
    ]

    model = EmbeddingModel(embedding_dim=args.embedding_dim).to(device)
    state = torch.load(args.model, map_location=device, weights_only=True)
    model.load_state_dict(state)
    print(f"Modell geladen: {args.model}")

    print(f"Berechne {len(all_files)} Embeddings...")
    embeddings, labels = embed_all(model, all_files, device)

    print("k-NN Evaluation (Leave-One-Out)...")
    knn_results = knn_eval(embeddings, labels)

    print(f"\n{'='*50}")
    print("k-NN Accuracy:")
    for k, acc in sorted(knn_results.items()):
        print(f"  {k}: {acc:.4f} ({acc*100:.1f}%)")

    # Top-1 Vorhersagen für Confusion Matrix
    norms = np.linalg.norm(embeddings, axis=1, keepdims=True)
    normed = embeddings / (norms + 1e-8)
    sim = normed @ normed.T
    preds = []
    for i in range(len(labels)):
        row = sim[i].copy()
        row[i] = -1e9
        preds.append(int(labels[np.argmax(row)]))
    preds = np.array(preds, dtype=np.int32)

    cm = build_confusion_matrix(labels, preds, n_classes)
    per_class = per_class_metrics(cm, classes)

    print(f"\n{'='*50}")
    print("Per-Class-Metrics — Top-10 nach F1:")
    per_class_sorted = sorted(per_class, key=lambda x: x["f1"], reverse=True)
    header = f"  {'Klasse':<38} {'Prec':>6} {'Rec':>6} {'F1':>6} {'N':>5}"
    print(header)
    print("  " + "-" * 62)
    for m in per_class_sorted[:10]:
        print(f"  {m['class']:<38} {m['precision']:>6.3f} {m['recall']:>6.3f} {m['f1']:>6.3f} {m['support']:>5}")

    print("\n  Schwächste 5 Klassen:")
    for m in per_class_sorted[-5:]:
        print(f"  {m['class']:<38} {m['precision']:>6.3f} {m['recall']:>6.3f} {m['f1']:>6.3f} {m['support']:>5}")

    macro_f1 = float(np.mean([m["f1"] for m in per_class]))
    print(f"\n  Macro-F1: {macro_f1:.4f}")

    if args.output:
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        np.savetxt(str(out) + ".confusion.csv", cm, fmt="%d", delimiter=",",
                   header=",".join(classes))
        metrics_path = Path(str(out) + ".metrics.json")
        metrics_path.write_text(
            json.dumps({"knn": knn_results, "macro_f1": macro_f1, "per_class": per_class},
                       indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        print(f"\nAusgabe: {out}.confusion.csv / .metrics.json")


if __name__ == "__main__":
    main()
