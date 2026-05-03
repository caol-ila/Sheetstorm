"""
Smoke-Test: train_embedding.py

Prüft die gesamte Trainings-Pipeline mit einem Mini-Corpus:
  - 5 Klassen x 10 Samples = 50 synthetische Grayscale-Bilder
  - 2 Epochs Training
  - Verifikation: ONNX-Export, JSON-Mapping, Loss-Convergence

Ausfuehren:
    cd tools/training
    .venv\Scripts\python.exe -m pytest tests/test_train_embedding.py -v
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import List

import numpy as np
import pytest
import torch
from PIL import Image

from train_embedding import (
    EmbeddingModel,
    TripletDataset,
    build_transforms,
    discover_classes,
    export_onnx,
    load_corpus,
    train,
    triplet_loss,
)


# ── Mini-Corpus Fixture ───────────────────────────────────────────────────────

MINI_CLASSES = [
    "shapes/circle",
    "shapes/square",
    "shapes/triangle",
    "shapes/star",
    "shapes/cross",
]
N_SAMPLES = 10


@pytest.fixture(scope="module")
def mini_corpus(tmp_path_factory):
    """Erstellt Mini-Corpus: 5 Klassen x 10 Samples (64x64 Grau-Patches)."""
    base = tmp_path_factory.mktemp("mini_corpus")
    rng = np.random.default_rng(0)
    for i, cls_path in enumerate(MINI_CLASSES):
        cat, cls = cls_path.split("/")
        cls_dir = base / cat / cls
        cls_dir.mkdir(parents=True, exist_ok=True)
        base_val = i * 50
        for j in range(N_SAMPLES):
            val = base_val + int(rng.integers(0, 20))
            img = Image.fromarray(np.full((64, 64), val, dtype=np.uint8), mode="L")
            img.save(cls_dir / f"{j:05d}.png")
    return base


@pytest.fixture(scope="module")
def trained_model_dir(mini_corpus, tmp_path_factory):
    """Fuehrt 2-Epoch-Training durch und gibt das Ausgabeverzeichnis zurueck."""
    out = tmp_path_factory.mktemp("models")
    args = argparse.Namespace(
        corpus=str(mini_corpus),
        output=str(out / "test_encoder"),
        epochs=2,
        batch_size=10,
        lr=1e-3,
        embedding_dim=64,
        margin=0.5,
        device="cpu",
        n_triplets_per_epoch=50,
    )
    model, onnx_path, best_top1 = train(args)
    return out


# ── Unit Tests ────────────────────────────────────────────────────────────────

def test_discover_classes(mini_corpus):
    classes, class_to_idx = discover_classes(mini_corpus)
    assert len(classes) == 5
    assert all("/" in c for c in classes)
    assert set(classes) == set(MINI_CLASSES)
    assert len(class_to_idx) == 5


def test_load_corpus(mini_corpus):
    classes, class_to_idx, class_to_files = load_corpus(mini_corpus)
    assert len(classes) == 5
    for cls, files in class_to_files.items():
        assert len(files) == N_SAMPLES, f"{cls}: expected {N_SAMPLES}, got {len(files)}"


def test_triplet_dataset_len(mini_corpus):
    _, class_to_idx, class_to_files = load_corpus(mini_corpus)
    ds = TripletDataset(
        root=mini_corpus,
        class_to_files=class_to_files,
        class_to_idx=class_to_idx,
        n_triplets=50,
        transform=build_transforms(False),
        seed=0,
    )
    assert len(ds) == 50


def test_triplet_dataset_shapes(mini_corpus):
    _, class_to_idx, class_to_files = load_corpus(mini_corpus)
    ds = TripletDataset(
        root=mini_corpus,
        class_to_files=class_to_files,
        class_to_idx=class_to_idx,
        n_triplets=10,
        transform=build_transforms(False),
        seed=0,
    )
    anc, pos, neg, anc_lbl, neg_lbl = ds[0]
    assert anc.shape == (3, 64, 64), f"Anchor shape: {anc.shape}"
    assert pos.shape == (3, 64, 64)
    assert neg.shape == (3, 64, 64)
    assert anc_lbl != neg_lbl, "Anchor und Negative sollten verschiedene Klassen haben"


def test_embedding_model_output_shape():
    model = EmbeddingModel(embedding_dim=64)
    x = torch.randn(4, 3, 64, 64)
    out = model(x)
    assert out.shape == (4, 64), f"Erwartet (4, 64), bekam {out.shape}"


def test_embedding_model_l2_normalized():
    """Ausgabe muss L2-normiert sein (Norm ~= 1.0)."""
    model = EmbeddingModel(embedding_dim=64)
    model.eval()
    with torch.no_grad():
        x = torch.randn(8, 3, 64, 64)
        out = model(x)
    norms = torch.norm(out, dim=1)
    assert torch.allclose(norms, torch.ones(8), atol=1e-5), f"Nicht L2-normiert: {norms}"


def test_triplet_loss_zero_when_negative_far():
    """Loss = 0 wenn negative klar weiter als positive + margin."""
    import torch.nn.functional as F
    anchor = F.normalize(torch.tensor([[1.0, 0.0, 0.0]]), dim=1)
    positive = F.normalize(torch.tensor([[0.99, 0.14, 0.0]]), dim=1)
    negative = F.normalize(torch.tensor([[-1.0, 0.0, 0.0]]), dim=1)
    loss = triplet_loss(anchor, positive, negative, margin=0.5)
    assert loss.item() == 0.0


def test_triplet_loss_positive_when_negative_close():
    """Loss > 0 wenn negative zu nah an anchor ist."""
    import torch.nn.functional as F
    anchor = F.normalize(torch.tensor([[1.0, 0.0, 0.0]]), dim=1)
    positive = F.normalize(torch.tensor([[0.0, 1.0, 0.0]]), dim=1)
    negative = F.normalize(torch.tensor([[0.98, 0.20, 0.0]]), dim=1)
    loss = triplet_loss(anchor, positive, negative, margin=0.5)
    assert loss.item() > 0.0


# ── Integration Tests ─────────────────────────────────────────────────────────

def test_training_produces_output_files(trained_model_dir):
    """2-Epoch-Training erzeugt .pt, .onnx und .json Dateien."""
    prefix = str(trained_model_dir / "test_encoder")
    assert Path(prefix + ".pt").exists(), ".pt Datei fehlt"
    assert Path(prefix + ".onnx").exists(), ".onnx Datei fehlt"
    assert Path(prefix + ".json").exists(), ".json Datei fehlt"
    assert Path(prefix + ".log").exists(), ".log Datei fehlt"


def test_json_mapping_correct(trained_model_dir):
    """JSON enthaelt korrekte Klassen und Metadaten."""
    json_path = trained_model_dir / "test_encoder.json"
    data = json.loads(json_path.read_text(encoding="utf-8"))
    assert "class_names" in data
    assert len(data["class_names"]) == 5
    assert data["embedding_dim"] == 64
    assert data["n_classes"] == 5
    assert data["input_shape"] == [1, 3, 64, 64]
    assert data["output_shape"] == [1, 64]
    assert set(data["class_names"]) == set(MINI_CLASSES)


def test_onnx_output_shape(trained_model_dir):
    """ONNX-Export gibt korrekte Output-Shape [1, 64]."""
    try:
        import onnxruntime as ort
    except ImportError:
        pytest.skip("onnxruntime nicht installiert")
    onnx_path = trained_model_dir / "test_encoder.onnx"
    sess = ort.InferenceSession(str(onnx_path))
    dummy = np.random.randn(1, 3, 64, 64).astype(np.float32)
    out = sess.run(["embedding"], {"input": dummy})[0]
    assert out.shape == (1, 64), f"ONNX Output shape: {out.shape}"


def test_onnx_pytorch_agreement(trained_model_dir):
    """ONNX und PyTorch Ausgaben stimmen ueberein (max_diff < 1e-3)."""
    try:
        import onnxruntime as ort
    except ImportError:
        pytest.skip("onnxruntime nicht installiert")
    pt_path = trained_model_dir / "test_encoder.pt"
    onnx_path = trained_model_dir / "test_encoder.onnx"
    model = EmbeddingModel(embedding_dim=64)
    state = torch.load(str(pt_path), map_location="cpu", weights_only=True)
    model.load_state_dict(state)
    model.eval()
    dummy = torch.randn(1, 3, 64, 64)
    with torch.no_grad():
        pt_out = model(dummy).numpy()
    sess = ort.InferenceSession(str(onnx_path))
    ort_out = sess.run(["embedding"], {"input": dummy.numpy()})[0]
    max_diff = float(np.abs(pt_out - ort_out).max())
    assert max_diff < 1e-3, f"PyTorch vs ONNX max_diff={max_diff:.2e} > 1e-3"


def test_export_onnx_standalone(tmp_path):
    """export_onnx() funktioniert unabhaengig vom Training."""
    model = EmbeddingModel(embedding_dim=32)
    onnx_path = tmp_path / "standalone.onnx"
    size_kb = export_onnx(model, onnx_path)
    assert onnx_path.exists()
    assert size_kb > 0
