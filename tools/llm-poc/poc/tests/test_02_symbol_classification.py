"""Test 02 — Symbol classification on 64×64 patches.

Expected: Poor-to-medium performance (~40-60%) — LLMs struggle with tiny crops.
"""

import random
from pathlib import Path

from poc.client import GitHubModelsClient, IMAGE_CAPABLE_MODELS, pdf_page_to_png, extract_patch

PROMPT_TEMPLATE = (
    "This is a small 64×64 pixel crop from sheet music. "
    "What single music notation symbol is shown? "
    "Answer with EXACTLY ONE of: quarter-note, half-note, whole-note, "
    "eighth-note, sixteenth-note, sharp, flat, natural, treble-clef, bass-clef, "
    "quarter-rest, eighth-rest, whole-rest, bar-line, time-signature, "
    "key-signature, beam, tie, slur, dynamic, fermata, unknown. "
    "Reply with only the label, nothing else."
)

VALID_LABELS = {
    "quarter-note", "half-note", "whole-note", "eighth-note", "sixteenth-note",
    "sharp", "flat", "natural", "treble-clef", "bass-clef",
    "quarter-rest", "eighth-rest", "whole-rest", "bar-line", "time-signature",
    "key-signature", "beam", "tie", "slur", "dynamic", "fermata", "unknown",
}

# ---------------------------------------------------------------------------
# Synthetic patch positions derived from known score layout
# Each entry: (pdf_fragment, page, patch_x, patch_y, expected_label)
# These are approximate — derived from visual inspection of score layout.
# ---------------------------------------------------------------------------
FILESTORE_PARTS = Path(__file__).parents[4] / "src" / ".filestore" / "parts"
FILESTORE_OMR = Path(__file__).parents[4] / "src" / ".filestore" / "omr"

# We generate patches from a known PDF at fixed positions
# and manually assign approximate ground-truth labels.
# The positions assume DPI=150 rendering of A4 sheet music.
PATCH_SPECS = [
    # (fragment, page, x, y, label)
    ("ANGELS.pdf",  0,  60,  80, "treble-clef"),
    ("ANGELS.pdf",  0, 120,  80, "time-signature"),
    ("ANGELS.pdf",  0, 200,  80, "key-signature"),
    ("ANGELS.pdf",  0, 300, 100, "quarter-note"),
    ("ANGELS.pdf",  0, 340, 100, "quarter-note"),
    ("ANGELS.pdf",  0, 380, 100, "half-note"),
    ("ANGELS.pdf",  0, 420,  80, "bar-line"),
    ("ANGELS.pdf",  0, 460, 100, "quarter-note"),
    ("Radetzky",    0,  60,  80, "treble-clef"),
    ("Radetzky",    0, 300, 100, "quarter-note"),
]


def _find_pdf_in(root: Path, fragment: str) -> Path | None:
    for pdf in root.rglob("*.pdf"):
        if fragment in pdf.name:
            return pdf
    return None


def run(models: list[str] | None = None) -> dict:
    if models is None:
        models = IMAGE_CAPABLE_MODELS

    # Build patch list
    patches = []
    for fragment, page, x, y, label in PATCH_SPECS:
        pdf = _find_pdf_in(FILESTORE_OMR, fragment) or _find_pdf_in(FILESTORE_PARTS, fragment)
        if pdf is None:
            continue
        try:
            png = pdf_page_to_png(pdf, page_index=page)
            patch_path = extract_patch(png, x, y)
            patches.append((patch_path, label))
        except Exception as e:
            print(f"  [PATCH] Could not create patch for {fragment}: {e}")

    if not patches:
        print("  [WARN] No patches generated — check PDF availability")
        return {}

    results = {}
    for model in models:
        client = GitHubModelsClient(model=model)
        correct = 0
        total = 0
        confusion = {}  # truth -> {pred: count}
        samples = []

        for patch_path, truth_label in patches:
            try:
                raw = client.vision_query(patch_path, PROMPT_TEMPLATE, max_tokens=32).strip().lower()
                # normalise
                pred = raw.split("\n")[0].strip()
                if pred not in VALID_LABELS:
                    pred = "unknown"

                is_correct = pred == truth_label
                correct += int(is_correct)
                total += 1

                confusion.setdefault(truth_label, {}).setdefault(pred, 0)
                confusion[truth_label][pred] += 1

                samples.append(
                    {"patch": patch_path.name, "truth": truth_label, "pred": pred, "correct": is_correct}
                )
                print(f"  [{model}] {patch_path.name}: truth={truth_label}, pred={pred} {'✓' if is_correct else '✗'}")
            except Exception as e:
                print(f"  [{model}] ERROR on {patch_path.name}: {e}")

        accuracy = round(correct / total, 3) if total else None
        results[model] = {
            "accuracy": accuracy,
            "correct": correct,
            "total": total,
            "confusion_matrix": confusion,
            "samples": samples,
            "cost": client.cost_summary(),
        }

    return results


if __name__ == "__main__":
    import json as _json

    print("=== Test 02: Symbol Classification ===")
    r = run(models=["gpt-4o-mini", "gpt-4o"])
    print(_json.dumps(r, indent=2, ensure_ascii=False))
