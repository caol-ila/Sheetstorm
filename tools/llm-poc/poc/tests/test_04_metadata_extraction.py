"""Test 04 — Metadata + Catalog matching.

Expected: Medium — models know famous marches but may confuse similar works.
"""

import json
import re
from pathlib import Path

from poc.client import GitHubModelsClient, IMAGE_CAPABLE_MODELS, pdf_page_to_png

PROMPT = (
    "Analyse this sheet music cover page or first page. "
    "Return JSON with:\n"
    '{"possible_title": "...", "possible_composer": "...", '
    '"key_signature": "...", "time_signature": "...", '
    '"instrumentation": "...", "style_period": "...", '
    '"confidence": "low|medium|high", "reasoning": "..."}\n'
    "Base your guess on visible title, composer, musical style, "
    "and any recognisable thematic material. "
    "Answer with JSON only."
)

# Known works and expected catalog attributes
CATALOG_GROUND_TRUTH = {
    "Radetzky": {
        "composer": "strauss",
        "style_period": "romantic",
        "time_signature": "2/4",
    },
    "Florentiner": {
        "style_period": "romantic",
    },
    "Festliche": {
        "style_period": "romantic",
    },
    "ANGELS": {
        "style_period": None,
    },
}

FILESTORE_OMR = Path(__file__).parents[4] / "src" / ".filestore" / "omr"
FILESTORE_PARTS = Path(__file__).parents[4] / "src" / ".filestore" / "parts"


def _find_pdf(fragment: str) -> Path | None:
    for root in [FILESTORE_PARTS, FILESTORE_OMR]:
        for pdf in root.rglob("*.pdf"):
            if fragment in pdf.name:
                return pdf
    return None


def _parse_json(raw: str) -> dict:
    raw = raw.strip()
    m = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", raw, re.DOTALL)
    if m:
        raw = m.group(1)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        m = re.search(r"\{.*\}", raw, re.DOTALL)
        if m:
            try:
                return json.loads(m.group(0))
            except Exception:
                pass
        return {}


def _attribute_score(pred: dict, truth: dict) -> float:
    """Score 0-1 how many known attributes match."""
    matched = 0
    checked = 0
    for key, expected in truth.items():
        if expected is None:
            continue
        checked += 1
        pred_val = str(pred.get(key, "")).lower()
        if expected.lower() in pred_val or pred_val in expected.lower():
            matched += 1
    return round(matched / checked, 2) if checked else 1.0


def run(models: list[str] | None = None) -> dict:
    if models is None:
        models = IMAGE_CAPABLE_MODELS

    results = {}
    for model in models:
        client = GitHubModelsClient(model=model)
        samples = []

        for fragment, truth in CATALOG_GROUND_TRUTH.items():
            pdf = _find_pdf(fragment)
            if pdf is None:
                print(f"  [SKIP] No PDF for '{fragment}'")
                continue
            try:
                png = pdf_page_to_png(pdf, page_index=0)
                raw = client.vision_query(png, PROMPT, max_tokens=512)
                parsed = _parse_json(raw)
                score = _attribute_score(parsed, truth)

                samples.append(
                    {
                        "pdf": pdf.name,
                        "predicted": parsed,
                        "ground_truth": truth,
                        "attribute_score": score,
                    }
                )
                print(f"  [{model}] {fragment}: score={score:.2f}  confidence={parsed.get('confidence')}")
            except Exception as e:
                print(f"  [{model}] ERROR on {fragment}: {e}")
                samples.append({"pdf": fragment, "error": str(e)})

        scores = [s["attribute_score"] for s in samples if "attribute_score" in s]
        avg = round(sum(scores) / len(scores), 3) if scores else None
        results[model] = {
            "avg_attribute_score": avg,
            "n_samples": len(samples),
            "samples": samples,
            "cost": client.cost_summary(),
        }

    return results


if __name__ == "__main__":
    import json as _json

    print("=== Test 04: Metadata + Catalog Match ===")
    r = run(models=["gpt-4o-mini", "gpt-4o"])
    print(_json.dumps(r, indent=2, ensure_ascii=False))
