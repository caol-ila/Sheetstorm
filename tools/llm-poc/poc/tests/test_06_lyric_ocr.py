"""Test 06 — Lyric / text OCR from sheet music.

Expected: Good — large printed text is well within LLM vision capabilities.
Metric: Levenshtein distance normalised to 0-1.
"""

from pathlib import Path

from Levenshtein import ratio as lev_ratio

from poc.client import GitHubModelsClient, IMAGE_CAPABLE_MODELS, pdf_page_to_png

PROMPT = (
    "Extract ALL visible lyrics/text underneath or above the notes in this sheet music. "
    "Preserve the order as written (left to right, line by line). "
    "Include verse numbers if present. "
    "Return ONLY the lyrics text, no explanations. "
    "If no lyrics are present, reply 'NO_LYRICS'."
)

# Ground truth lyrics for known files (partial — first line)
# Derived from known pieces in the filestore
LYRIC_GROUND_TRUTH: dict[str, str] = {
    "lichterkinder": "Lichterkinder",  # the PDF is titled "lichterkinder", matches
    "Böhmischer Traum": "NO_LYRICS",  # instrumental
    "Anita": "NO_LYRICS",              # instrumental march
    "ANGELS": "NO_LYRICS",             # instrumental
}

FILESTORE_OMR = Path(__file__).parents[4] / "src" / ".filestore" / "omr"
FILESTORE_PARTS = Path(__file__).parents[4] / "src" / ".filestore" / "parts"


def _find_pdf(fragment: str) -> Path | None:
    for root in [FILESTORE_OMR, FILESTORE_PARTS]:
        for pdf in root.rglob("*.pdf"):
            if fragment in pdf.name:
                return pdf
    return None


def _lyric_score(pred: str, truth: str) -> float:
    """Levenshtein similarity: 1.0 = identical, 0.0 = completely different."""
    pred_clean = pred.strip().lower()
    truth_clean = truth.strip().lower()
    if truth_clean == "no_lyrics":
        return 1.0 if "no_lyrics" in pred_clean or len(pred_clean) < 20 else 0.0
    return round(lev_ratio(pred_clean, truth_clean), 3)


def run(models: list[str] | None = None) -> dict:
    if models is None:
        models = IMAGE_CAPABLE_MODELS

    results = {}
    for model in models:
        client = GitHubModelsClient(model=model)
        samples = []
        scores = []

        for fragment, truth in LYRIC_GROUND_TRUTH.items():
            pdf = _find_pdf(fragment)
            if pdf is None:
                print(f"  [SKIP] No PDF for '{fragment}'")
                continue
            try:
                png = pdf_page_to_png(pdf, page_index=0)
                pred = client.vision_query(png, PROMPT, max_tokens=512)
                score = _lyric_score(pred, truth)
                scores.append(score)

                samples.append(
                    {
                        "pdf": pdf.name,
                        "truth_first_line": truth,
                        "predicted": pred[:200],
                        "lev_similarity": score,
                    }
                )
                print(
                    f"  [{model}] {fragment}: similarity={score:.2f}  "
                    f"pred={pred[:60]!r}..."
                )
            except Exception as e:
                print(f"  [{model}] ERROR on {fragment}: {e}")
                samples.append({"pdf": fragment, "error": str(e)})

        avg = round(sum(scores) / len(scores), 3) if scores else None
        results[model] = {
            "avg_lev_similarity": avg,
            "n_samples": len(samples),
            "samples": samples,
            "cost": client.cost_summary(),
        }

    return results


if __name__ == "__main__":
    import json as _json

    print("=== Test 06: Lyric OCR ===")
    r = run(models=["gpt-4o-mini", "gpt-4o"])
    print(_json.dumps(r, indent=2, ensure_ascii=False))
