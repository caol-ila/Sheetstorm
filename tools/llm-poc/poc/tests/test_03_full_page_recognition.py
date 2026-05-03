"""Test 03 — Full-page music recognition (OMR).

Expected: Poor — LLMs hallucinate pitches and durations heavily.
Output format: ABC notation or informal description.
"""

from pathlib import Path

from poc.client import GitHubModelsClient, IMAGE_CAPABLE_MODELS, pdf_page_to_png

PROMPT_ABC = (
    "Look at this sheet music page. Try to transcribe the first 4 bars "
    "into ABC notation format. Include: key signature (K:), time signature (M:), "
    "and note sequence. Example: X:1\nT:Example\nM:4/4\nK:C\nCDEF|GABC|\n\n"
    "If you cannot read it accurately, write what you can see and mark uncertain "
    "notes with '?'. Be honest about your confidence."
)

PROMPT_DESCRIPTION = (
    "Analyse this sheet music page and answer:\n"
    "1. What clef is used? (treble/bass/other)\n"
    "2. What is the key signature? (how many sharps/flats)\n"
    "3. What is the time signature? (e.g. 4/4, 3/4)\n"
    "4. What is the approximate tempo marking if visible?\n"
    "5. How many staves per system?\n"
    "6. Describe the first 4 notes (pitch + duration if possible)\n"
    "Answer in JSON format."
)

FILESTORE_OMR = Path(__file__).parents[4] / "src" / ".filestore" / "omr"
FILESTORE_PARTS = Path(__file__).parents[4] / "src" / ".filestore" / "parts"

TEST_PDFS = ["ANGELS.pdf", "Radetzky", "Florentiner"]


def _find_pdf(fragment: str) -> Path | None:
    for root in [FILESTORE_OMR, FILESTORE_PARTS]:
        for pdf in root.rglob("*.pdf"):
            if fragment in pdf.name:
                return pdf
    return None


def run(models: list[str] | None = None) -> dict:
    if models is None:
        models = IMAGE_CAPABLE_MODELS

    results = {}
    for model in models:
        client = GitHubModelsClient(model=model)
        model_results = {"samples": []}

        for fragment in TEST_PDFS:
            pdf = _find_pdf(fragment)
            if pdf is None:
                print(f"  [SKIP] No PDF for '{fragment}'")
                continue
            try:
                png = pdf_page_to_png(pdf, page_index=0)

                abc_output = client.vision_query(png, PROMPT_ABC, max_tokens=1024)
                desc_output = client.vision_query(png, PROMPT_DESCRIPTION, max_tokens=512)

                # Subjective completeness score: does the output have key/time/notes?
                has_key = "K:" in abc_output or "key" in abc_output.lower()
                has_time = "M:" in abc_output or "time" in abc_output.lower() or "4/4" in abc_output
                has_notes = any(c in abc_output for c in "CDEFGAB")
                completeness = round((int(has_key) + int(has_time) + int(has_notes)) / 3, 2)

                model_results["samples"].append(
                    {
                        "pdf": pdf.name,
                        "abc_output": abc_output[:800],
                        "description": desc_output[:600],
                        "completeness_score": completeness,
                        "has_key": has_key,
                        "has_time": has_time,
                        "has_notes": has_notes,
                    }
                )
                print(f"  [{model}] {fragment}: completeness={completeness:.0%}  has_notes={has_notes}")
            except Exception as e:
                print(f"  [{model}] ERROR on {fragment}: {e}")
                model_results["samples"].append({"pdf": fragment, "error": str(e)})

        scores = [s.get("completeness_score", 0) for s in model_results["samples"] if "error" not in s]
        avg = round(sum(scores) / len(scores), 3) if scores else None
        results[model] = {
            "avg_completeness": avg,
            "n_samples": len(model_results["samples"]),
            "samples": model_results["samples"],
            "cost": client.cost_summary(),
        }

    return results


if __name__ == "__main__":
    import json as _json

    print("=== Test 03: Full-Page Recognition ===")
    r = run(models=["gpt-4o-mini", "gpt-4o"])
    print(_json.dumps(r, indent=2, ensure_ascii=False))
