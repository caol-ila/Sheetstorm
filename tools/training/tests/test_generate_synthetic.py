"""
tests/test_generate_synthetic.py

Smoke and validation tests for generate_synthetic_patterns.py.

Run with:
    cd tools/training
    .venv/Scripts/pytest tests/test_generate_synthetic.py -v
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

# Ensure the parent directory is on sys.path so the module can be imported
sys.path.insert(0, str(Path(__file__).parent.parent))

from generate_synthetic_patterns import (
    generate_logical_groups,
    generate_manifest,
    generate_phrase_snippets,
    generate_single_symbols,
    VerovioRenderer,
    PATCH,
)

from PIL import Image


# ── Fixtures ──────────────────────────────────────────────────────────────────

BRAVURA_PATH = (
    Path(__file__).parent.parent.parent.parent
    / "src" / "omr-rust" / "crates" / "omr-symbols" / "assets" / "Bravura.otf"
)

SAMPLES_PER_CLASS = 3  # small for fast smoke run


@pytest.fixture(scope="module")
def corpus(tmp_path_factory):
    """Generate a minimal corpus once per test session."""
    out = tmp_path_factory.mktemp("synthetic_corpus")
    single_dir = out / "single"
    groups_dir = out / "groups"
    snippets_dir = out / "snippets"

    import random
    import numpy as np
    rng = random.Random(0)
    np.random.seed(0)

    generate_single_symbols(
        single_dir,
        n_per_class=SAMPLES_PER_CLASS,
        bravura_path=BRAVURA_PATH,
        rng=rng,
    )

    with VerovioRenderer() as renderer:
        generate_logical_groups(
            groups_dir,
            n_per_group=SAMPLES_PER_CLASS,
            bravura_path=BRAVURA_PATH,
            rng=rng,
            renderer=renderer,
        )
        generate_phrase_snippets(
            snippets_dir,
            n_per_snippet=SAMPLES_PER_CLASS,
            bravura_path=BRAVURA_PATH,
            rng=rng,
            renderer=renderer,
        )

    generate_manifest(out)
    return out


# ── Tests ─────────────────────────────────────────────────────────────────────

class TestDirectoryStructure:
    def test_single_dir_exists(self, corpus):
        assert (corpus / "single").is_dir()

    def test_groups_dir_exists(self, corpus):
        assert (corpus / "groups").is_dir()

    def test_snippets_dir_exists(self, corpus):
        assert (corpus / "snippets").is_dir()

    def test_noteheads_subdir(self, corpus):
        assert (corpus / "single" / "noteheads").is_dir()

    def test_rests_subdir(self, corpus):
        assert (corpus / "single" / "rests").is_dir()

    def test_clefs_subdir(self, corpus):
        assert (corpus / "single" / "clefs").is_dir()

    def test_accidentals_subdir(self, corpus):
        assert (corpus / "single" / "accidentals").is_dir()

    def test_dynamics_subdir(self, corpus):
        assert (corpus / "single" / "dynamics").is_dir()

    def test_beam_groups_subdir(self, corpus):
        assert (corpus / "groups" / "beam_groups").is_dir()

    def test_chord_clusters_subdir(self, corpus):
        assert (corpus / "groups" / "chord_clusters").is_dir()

    def test_cadences_subdir(self, corpus):
        assert (corpus / "snippets" / "cadences").is_dir()


class TestManifest:
    @pytest.fixture(autouse=True)
    def _load_manifest(self, corpus):
        with open(corpus / "manifest.json", encoding="utf-8") as f:
            self.manifest = json.load(f)

    def test_manifest_exists(self, corpus):
        assert (corpus / "manifest.json").exists()

    def test_manifest_version(self):
        assert self.manifest["version"] == "v1"

    def test_manifest_has_generated_at(self):
        assert "generated_at" in self.manifest

    def test_manifest_n_samples_positive(self):
        assert self.manifest["n_samples"] > 0

    def test_manifest_n_samples_matches_samples_list(self):
        assert self.manifest["n_samples"] == len(self.manifest["samples"])

    def test_at_least_50_classes(self):
        n_classes = len(self.manifest["classes"])
        assert n_classes >= 50, (
            f"Expected ≥ 50 classes, got {n_classes}. "
            f"Classes: {sorted(self.manifest['classes'].keys())}"
        )

    def test_manifest_classes_non_zero(self):
        for cls, count in self.manifest["classes"].items():
            assert count > 0, f"Class {cls!r} has 0 samples"

    def test_sample_entries_have_required_fields(self):
        required = {"id", "path", "class", "augmentation", "size"}
        for sample in self.manifest["samples"][:50]:
            assert required.issubset(sample.keys()), (
                f"Sample {sample.get('id')} missing fields: "
                f"{required - sample.keys()}"
            )

    def test_sample_size_is_64x64(self):
        for sample in self.manifest["samples"][:50]:
            assert sample["size"] == [64, 64], (
                f"Sample {sample['id']} has size {sample['size']}, expected [64, 64]"
            )


class TestImageQuality:
    def test_all_pngs_are_64x64_grayscale(self, corpus):
        pngs = list(corpus.rglob("*.png"))
        assert len(pngs) > 0, "No PNG files found"
        errors = []
        for png in pngs[:200]:  # Check up to 200 files
            try:
                with Image.open(png) as img:
                    if img.size != (PATCH, PATCH):
                        errors.append(f"{png.name}: size={img.size}")
                    if img.mode != "L":
                        errors.append(f"{png.name}: mode={img.mode}")
            except Exception as e:
                errors.append(f"{png.name}: {e}")
        assert not errors, "PNG issues:\n" + "\n".join(errors[:10])

    def test_pngs_are_not_all_white(self, corpus):
        """Ensure at least some samples have actual content (not blank)."""
        import numpy as np
        pngs = list(corpus.rglob("*.png"))
        non_blank = 0
        for png in pngs[:100]:
            with Image.open(png) as img:
                arr = np.array(img)
                if arr.min() < 200:  # has some dark pixels
                    non_blank += 1
        # At least 50% of checked images should have content
        assert non_blank >= len(pngs[:100]) * 0.5, (
            f"Too many blank images: only {non_blank}/{min(100, len(pngs))} have content"
        )

    def test_sample_count_per_class(self, corpus):
        """Each class directory should have >= SAMPLES_PER_CLASS files."""
        # Find all leaf class directories (containing PNGs)
        for cls_dir in corpus.rglob("*"):
            if cls_dir.is_dir():
                pngs = list(cls_dir.glob("*.png"))
                if pngs:
                    assert len(pngs) >= SAMPLES_PER_CLASS, (
                        f"{cls_dir.relative_to(corpus)} has only {len(pngs)} samples, "
                        f"expected >= {SAMPLES_PER_CLASS}"
                    )


class TestSpecificClasses:
    """Verify that key expected class directories exist."""

    @pytest.mark.parametrize("rel_path", [
        "single/noteheads/filled_quarter",
        "single/noteheads/half",
        "single/noteheads/whole",
        "single/rests/whole",
        "single/rests/quarter",
        "single/clefs/treble",
        "single/clefs/bass",
        "single/accidentals/sharp",
        "single/accidentals/flat",
        "single/accidentals/natural",
        "single/time_sigs/4_4",
        "single/time_sigs/common",
        "single/key_sigs/c_major",
        "single/key_sigs/p1_sharps",
        "single/key_sigs/m1_flats",
        "single/dynamics/p",
        "single/dynamics/f",
        "single/articulations/staccato",
        "single/articulations/fermata",
        "single/barlines/single",
        "single/barlines/repeat_start",
        "single/jump_marks/coda",
        "single/jump_marks/segno",
        "groups/beam_groups/2_eighths",
        "groups/beam_groups/4_sixteenths",
        "groups/chord_clusters/2_notes",
        "groups/tied_notes/2_tied",
        "groups/tuplets/triplet",
        "groups/grace_notes/grace_before",
        "snippets/cadences/v_I",
        "snippets/marcia/marcia_pattern",
        "snippets/walzer/walzer_pattern",
    ])
    def test_class_directory_exists(self, corpus, rel_path):
        path = corpus / Path(rel_path)
        assert path.is_dir(), f"Expected class directory not found: {rel_path}"
        assert len(list(path.glob("*.png"))) > 0, (
            f"Class directory empty: {rel_path}"
        )
