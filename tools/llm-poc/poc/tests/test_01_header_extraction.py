"""Test 01 — Header extraction (Title, Composer, Instrument, Tempo).

Expected: Good performance (F1 ~ 0.8+) — text is large and structured.
"""

import json
import re
from pathlib import Path

from poc.client import GitHubModelsClient, IMAGE_CAPABLE_MODELS, pdf_page_to_png

# ---------------------------------------------------------------------------
# Ground-truth derived from filenames in src/.filestore/parts
# format: { filename_fragment: {title, composer, instrument} }
# ---------------------------------------------------------------------------
GROUND_TRUTH = {
    "Radetzky-Marsch-Trompete": {
        "title": "Radetzky-Marsch",
        "composer": "Strauss",
        "instrument": "Trompete",
    },
    "Festliche Eröffnung-Trompete": {
        "title": "Festliche Eröffnung",
        "composer": None,  # unknown from filename
        "instrument": "Trompete",
    },
    "Florentiner Marsch-Klarinette": {
        "title": "Florentiner Marsch",
        "composer": None,
        "instrument": "Klarinette",
    },
    "Dichterliebe": {
        "title": "Im wunderschönen Monat Mai",  # first song from Dichterliebe cycle
        "composer": "Schumann",
        "instrument": None,
    },
    "Anita": {
        "title": "Anita",
        "composer": None,
        "instrument": None,
    },
}

PROMPT = (
    "Extract the following metadata from this sheet music image. "
    "Return ONLY valid JSON with these fields: "
    '{"title": "...", "composer": "...", "instrument": "...", "tempo": "..."}. '
    "Use null if a field is not visible. Do not add any explanation."
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

FILESTORE_PARTS = Path(__file__).parents[4] / "src" / ".filestore" / "parts"


def _find_pdf_for(fragment: str) -> Path | None:
    """Find a PDF whose name contains the fragment."""
    for pdf in FILESTORE_PARTS.rglob("*.pdf"):
        if fragment in pdf.name:
            return pdf
    return None


def _parse_json(raw: str) -> dict:
    """Extract JSON from raw LLM response (handles markdown code blocks)."""
    raw = raw.strip()
    match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", raw, re.DOTALL)
    if match:
        raw = match.group(1)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        # Try to find JSON object in text
        match = re.search(r"\{[^{}]+\}", raw, re.DOTALL)
        if match:
            return json.loads(match.group(0))
        return {}


def _token_f1(pred: str | None, truth: str | None) -> float:
    """Compute token-level F1 between two strings (case-insensitive)."""
    if truth is None:
        return 1.0  # unknown ground truth → skip
    if pred is None:
        return 0.0
    pred_tokens = set(pred.lower().split())
    truth_tokens = set(truth.lower().split())
    if not truth_tokens:
        return 1.0
    if not pred_tokens:
        return 0.0
    tp = len(pred_tokens & truth_tokens)
    precision = tp / len(pred_tokens) if pred_tokens else 0.0
    recall = tp / len(truth_tokens)
    if precision + recall == 0:
        return 0.0
    return 2 * precision * recall / (precision + recall)


# ---------------------------------------------------------------------------
# Main test runner
# ---------------------------------------------------------------------------

def run(models: list[str] | None = None, max_samples: int = 5) -> dict:
    """Run Test 01 across models, return results dict."""
    if models is None:
        models = IMAGE_CAPABLE_MODELS

    results = {}

    for model in models:
        client = GitHubModelsClient(model=model)
        model_results = {"samples": [], "f1_title": [], "f1_composer": [], "f1_instrument": []}

        for fragment, truth in list(GROUND_TRUTH.items())[:max_samples]:
            pdf = _find_pdf_for(fragment)
            if pdf is None:
                print(f"  [SKIP] No PDF found for '{fragment}'")
                continue

            try:
                png = pdf_page_to_png(pdf, page_index=0)
                raw = client.vision_query(png, PROMPT)
                parsed = _parse_json(raw)

                f1_t = _token_f1(parsed.get("title"), truth["title"])
                f1_c = _token_f1(parsed.get("composer"), truth["composer"])
                f1_i = _token_f1(parsed.get("instrument"), truth["instrument"])

                model_results["f1_title"].append(f1_t)
                model_results["f1_composer"].append(f1_c)
                model_results["f1_instrument"].append(f1_i)
                model_results["samples"].append(
                    {
                        "pdf": pdf.name,
                        "predicted": parsed,
                        "f1_title": f1_t,
                        "f1_composer": f1_c,
                        "f1_instrument": f1_i,
                    }
                )
                print(
                    f"  [{model}] {fragment}: title={parsed.get('title')!r}  "
                    f"F1(title)={f1_t:.2f}"
                )
            except Exception as e:
                print(f"  [{model}] ERROR on {fragment}: {e}")
                model_results["samples"].append({"pdf": fragment, "error": str(e)})

        def _avg(lst):
            return round(sum(lst) / len(lst), 3) if lst else None

        results[model] = {
            "f1_title": _avg(model_results["f1_title"]),
            "f1_composer": _avg(model_results["f1_composer"]),
            "f1_instrument": _avg(model_results["f1_instrument"]),
            "f1_overall": _avg(
                model_results["f1_title"]
                + model_results["f1_composer"]
                + model_results["f1_instrument"]
            ),
            "n_samples": len(model_results["samples"]),
            "samples": model_results["samples"],
            "cost": client.cost_summary(),
        }

    return results


if __name__ == "__main__":
    import json as _json

    print("=== Test 01: Header Extraction ===")
    r = run(models=["gpt-4o-mini", "gpt-4o"])
    print(_json.dumps(r, indent=2, ensure_ascii=False))
