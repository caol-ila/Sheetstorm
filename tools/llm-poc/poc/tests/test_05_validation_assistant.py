"""Test 05 — Validation assistant (OMR output cross-check).

The idea: give the LLM a scanned page + a MusicXML excerpt and ask
"does the XML match what you see in the image?"

Expected: Potentially very useful — even without perfect pitch detection,
models can flag obvious structural mismatches.
"""

import json
import re
from pathlib import Path

from poc.client import GitHubModelsClient, IMAGE_CAPABLE_MODELS, pdf_page_to_png

PROMPT_TEMPLATE = (
    "You are a music notation expert and OMR validation assistant.\n\n"
    "Here is a page of scanned sheet music (image) and a MusicXML excerpt "
    "that an OMR system produced from it.\n\n"
    "MusicXML excerpt:\n```xml\nMUSICXML_PLACEHOLDER\n```\n\n"
    "Tasks:\n"
    "1. Does the XML roughly match what you see in the image?\n"
    "2. List up to 5 specific discrepancies (if any) you notice.\n"
    "3. Rate overall OMR quality: 1=very poor, 3=acceptable, 5=excellent.\n\n"
    "Answer in JSON with exactly these keys: "
    "matches (boolean), discrepancies (array of strings), quality_score (integer 1-5), "
    "explanation (string)."
)

# Synthetic MusicXML snippets — simplified representations for testing
SYNTHETIC_MUSICXML_GOOD = """<measure number="1">
  <note><pitch><step>C</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
  <note><pitch><step>D</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
  <note><pitch><step>E</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
  <note><pitch><step>F</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
</measure>"""

SYNTHETIC_MUSICXML_WRONG = """<measure number="1">
  <note><pitch><step>A</step><octave>5</octave></pitch><duration>4</duration><type>whole</type></note>
  <barline location="right"><bar-style>light-heavy</bar-style></barline>
</measure>"""

FILESTORE_OMR = Path(__file__).parents[4] / "src" / ".filestore" / "omr"
FILESTORE_PARTS = Path(__file__).parents[4] / "src" / ".filestore" / "parts"

TEST_CASES = [
    # (pdf_fragment, musicxml_snippet, expected_match)
    ("ANGELS.pdf", SYNTHETIC_MUSICXML_GOOD, None),   # unknown — subjective
    ("ANGELS.pdf", SYNTHETIC_MUSICXML_WRONG, False),  # clearly wrong
    ("Radetzky",   SYNTHETIC_MUSICXML_GOOD, None),
]


def _find_pdf(fragment: str) -> Path | None:
    for root in [FILESTORE_OMR, FILESTORE_PARTS]:
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


def run(models: list[str] | None = None) -> dict:
    if models is None:
        models = IMAGE_CAPABLE_MODELS

    results = {}
    for model in models:
        client = GitHubModelsClient(model=model)
        samples = []
        utility_scores = []

        for fragment, musicxml, expected_match in TEST_CASES:
            pdf = _find_pdf(fragment)
            if pdf is None:
                print(f"  [SKIP] No PDF for '{fragment}'")
                continue
            try:
                png = pdf_page_to_png(pdf, page_index=0)
                prompt = PROMPT_TEMPLATE.replace("MUSICXML_PLACEHOLDER", musicxml)
                raw = client.vision_query(png, prompt, max_tokens=1024)
                parsed = _parse_json(raw)

                quality = parsed.get("quality_score", 0)
                num_discrepancies = len(parsed.get("discrepancies", []))

                # Utility: did the model correctly identify mismatch when expected=False?
                if expected_match is False:
                    utility = 1.0 if not parsed.get("matches", True) else 0.0
                else:
                    utility = min(1.0, quality / 5.0) if quality else 0.5

                utility_scores.append(utility)
                samples.append(
                    {
                        "pdf": pdf.name,
                        "musicxml_type": "good" if musicxml == SYNTHETIC_MUSICXML_GOOD else "wrong",
                        "response": parsed,
                        "num_discrepancies": num_discrepancies,
                        "quality_score": quality,
                        "utility_score": utility,
                    }
                )
                print(
                    f"  [{model}] {fragment}: quality={quality}/5  "
                    f"discrepancies={num_discrepancies}  utility={utility:.2f}"
                )
            except Exception as e:
                print(f"  [{model}] ERROR on {fragment}: {e}")
                samples.append({"pdf": fragment, "error": str(e)})

        avg_utility = round(sum(utility_scores) / len(utility_scores), 3) if utility_scores else None
        results[model] = {
            "avg_utility_score": avg_utility,
            "n_samples": len(samples),
            "samples": samples,
            "cost": client.cost_summary(),
        }

    return results


if __name__ == "__main__":
    import json as _json

    print("=== Test 05: Validation Assistant ===")
    r = run(models=["gpt-4o-mini", "gpt-4o"])
    print(_json.dumps(r, indent=2, ensure_ascii=False))
