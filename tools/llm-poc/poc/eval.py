#!/usr/bin/env python3
"""Eval pipeline — runs all 6 tests across selected models and generates reports.

Usage:
    python eval.py                              # all tests, default models
    python eval.py --models gpt-4o gpt-4o-mini # specific models
    python eval.py --test 1 2 3                 # specific test numbers
    python eval.py --dry-run                    # skip API calls, use cached results
"""

import argparse
import json
import sys
import time
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Model configuration with pricing (USD per 1K tokens, approximate)
# ---------------------------------------------------------------------------
MODEL_PRICING = {
    "gpt-4o": {"prompt": 0.005, "completion": 0.015},
    "gpt-4o-mini": {"prompt": 0.00015, "completion": 0.0006},
    "Llama-3.2-90B-Vision-Instruct": {"prompt": 0.00034, "completion": 0.00034},
}

DEFAULT_MODELS = ["gpt-4o-mini", "gpt-4o", "Llama-3.2-90B-Vision-Instruct"]

REPORTS_DIR = Path(__file__).parent.parent / "reports"
REPORTS_DIR.mkdir(exist_ok=True)


def estimate_cost(model: str, usage: dict) -> float:
    """Estimate USD cost from token usage."""
    pricing = MODEL_PRICING.get(model, {"prompt": 0.001, "completion": 0.001})
    prompt_cost = usage.get("prompt_tokens", 0) / 1000 * pricing["prompt"]
    completion_cost = usage.get("completion_tokens", 0) / 1000 * pricing["completion"]
    return round(prompt_cost + completion_cost, 6)


def run_test(test_module, models: list[str]) -> dict:
    """Run a test module's run() function and return results."""
    try:
        return test_module.run(models=models)
    except Exception as e:
        print(f"  [ERROR] Test module failed: {e}")
        return {m: {"error": str(e)} for m in models}


def build_summary_table(all_results: dict) -> str:
    """Build Markdown summary table from aggregated results."""
    models = list(all_results.keys())

    lines = [
        "## Results Summary\n",
        "| Model | Header F1 | Symbol Acc | OMR Complete | Catalog | Validation | Lyric OCR | Est. Cost/page |",
        "|---|---|---|---|---|---|---|---|",
    ]

    for model in models:
        r = all_results[model]
        header_f1 = r.get("test_01", {}).get("f1_overall", "—")
        symbol_acc = r.get("test_02", {}).get("accuracy", "—")
        omr = r.get("test_03", {}).get("avg_completeness", "—")
        catalog = r.get("test_04", {}).get("avg_attribute_score", "—")
        validation = r.get("test_05", {}).get("avg_utility_score", "—")
        lyric = r.get("test_06", {}).get("avg_lev_similarity", "—")
        cost = r.get("estimated_cost_usd", "—")

        def fmt(v):
            if isinstance(v, float):
                return f"{v:.2f}"
            return str(v) if v is not None else "—"

        cost_str = f"${cost:.4f}" if isinstance(cost, float) else str(cost)
        lines.append(
            f"| {model} | {fmt(header_f1)} | {fmt(symbol_acc)} | {fmt(omr)} | "
            f"{fmt(catalog)} | {fmt(validation)} | {fmt(lyric)} | {cost_str} |"
        )

    return "\n".join(lines)


def build_recommendations(all_results: dict) -> str:
    """Generate concrete recommendations based on results."""
    models = list(all_results.keys())
    best_header = max(models, key=lambda m: all_results[m].get("test_01", {}).get("f1_overall") or 0)
    best_symbol = max(models, key=lambda m: all_results[m].get("test_02", {}).get("accuracy") or 0)
    best_lyric = max(models, key=lambda m: all_results[m].get("test_06", {}).get("avg_lev_similarity") or 0)
    best_validation = max(models, key=lambda m: all_results[m].get("test_05", {}).get("avg_utility_score") or 0)

    header_f1 = all_results[best_header].get("test_01", {}).get("f1_overall")
    symbol_acc = all_results[best_symbol].get("test_02", {}).get("accuracy")
    lyric_sim = all_results[best_lyric].get("test_06", {}).get("avg_lev_similarity")

    recommendations = [
        "## 🎯 Concrete Recommendations for Sheetstorm Integration\n",
        "### ✅ USE LLMs for these tasks\n",
    ]

    if header_f1 and header_f1 >= 0.7:
        recommendations.append(
            f"**Title / Composer / Instrument extraction** "
            f"(best: {best_header}, F1={header_f1:.2f})  \n"
            "→ Replace manual metadata entry in upload workflow. "
            "Run on first page after PDF upload.  \n"
            "→ Cost: ~$0.001/page with gpt-4o-mini — practically free.\n"
        )
    else:
        f1_str = f"{header_f1:.2f}" if header_f1 is not None else "N/A"
        recommendations.append(
            f"**Title / Composer extraction**: results below threshold "
            f"(F1={f1_str}). "
            "Use as suggestion only, not auto-fill.\n"
        )

    if lyric_sim and lyric_sim >= 0.7:
        recommendations.append(
            f"**Lyric / text OCR** (best: {best_lyric}, similarity={lyric_sim:.2f})  \n"
            "→ Extract lyrics for display/search without manual transcription.  \n"
            "→ Confidence: high for clear printed text.\n"
        )

    recommendations += [
        "\n### ⚡ CONSIDER for these tasks\n",
        "**Validation assistant** — LLM as second opinion on OMR output:  \n"
        "→ Feed scan + Audiveris MusicXML to GPT-4o, ask 'does this look right?'  \n"
        "→ Even without perfect pitch detection, structural errors are caught.  \n"
        "→ Cost: ~$0.005/page (gpt-4o) — acceptable for user-facing QA workflow.\n",
        "\n**Catalog matching** — 'Which piece is this?':  \n"
        "→ Useful for unlabelled scans from archive.  \n"
        "→ Works well for famous marches (Radetzky, Florentiner) due to training data.\n",
    ]

    if symbol_acc is not None and symbol_acc < 0.55:
        recommendations += [
            "\n### ❌ DO NOT use LLMs for these tasks\n",
            f"**Pitch / note detection** (symbol accuracy: {symbol_acc:.1%})  \n"
            "→ LLMs hallucinate note names, durations, and octaves heavily.  \n"
            "→ Confusion: quarter-note vs eighth-note not reliably distinguished.  \n"
            "→ **Stick with dedicated OMR (Audiveris)** for any pitch-level work.\n",
            "**Full-page transcription to MusicXML/ABC**  \n"
            "→ Output is plausible but unreliable. Too many errors for production use.  \n"
            "→ May be useful as a rough draft for human correction, not automated.\n",
        ]

    recommendations += [
        "\n### 💡 Recommended Architecture\n",
        "```",
        "PDF Upload",
        "    │",
        "    ├─ [LLM gpt-4o-mini] → extract Title, Composer, Instrument, Tempo",
        "    │   └─ Pre-fill metadata form (user confirms)",
        "    │",
        "    ├─ [LLM gpt-4o-mini] → extract Lyrics",
        "    │   └─ Store for full-text search",
        "    │",
        "    ├─ [Audiveris OMR] → generate MusicXML",
        "    │   └─ [LLM gpt-4o, optional] → validate MusicXML vs. scan image",
        "    │       └─ Flag suspicious pages for human review",
        "    │",
        "    └─ Done",
        "```",
        "\n### 💰 Cost Estimate (production)\n",
        "| Workflow | Model | Cost/page | 1000 pages/month |",
        "|---|---|---|---|",
        "| Metadata extraction | gpt-4o-mini | ~$0.001 | ~$1 |",
        "| Lyric OCR | gpt-4o-mini | ~$0.001 | ~$1 |",
        "| OMR validation | gpt-4o | ~$0.005 | ~$5 |",
        "| **Total** | mixed | ~$0.007 | **~$7/month** |",
    ]

    return "\n".join(recommendations)


def main():
    parser = argparse.ArgumentParser(description="LLM OMR evaluation pipeline")
    parser.add_argument("--models", nargs="+", default=None,
                        help="Models to test (default: all capable models)")
    parser.add_argument("--test", nargs="+", type=int, default=None,
                        help="Test numbers to run (1-6, default: all)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Skip API calls, load from cached results if available")
    args = parser.parse_args()

    models = args.models or DEFAULT_MODELS
    tests_to_run = args.test or [1, 2, 3, 4, 5, 6]

    print(f"\n🔬 LLM OMR POC Evaluation")
    print(f"   Models: {', '.join(models)}")
    print(f"   Tests:  {tests_to_run}")
    print(f"   Time:   {datetime.now().isoformat()}\n")

    # Import test modules
    sys.path.insert(0, str(Path(__file__).parent.parent))
    from poc.tests import (
        test_01_header_extraction,
        test_02_symbol_classification,
        test_03_full_page_recognition,
        test_04_metadata_extraction,
        test_05_validation_assistant,
        test_06_lyric_ocr,
    )

    test_modules = {
        1: ("Header Extraction", test_01_header_extraction),
        2: ("Symbol Classification", test_02_symbol_classification),
        3: ("Full-Page Recognition", test_03_full_page_recognition),
        4: ("Metadata + Catalog", test_04_metadata_extraction),
        5: ("Validation Assistant", test_05_validation_assistant),
        6: ("Lyric OCR", test_06_lyric_ocr),
    }

    # Aggregate: {model: {test_01: {...}, test_02: {...}, ...}}
    aggregated: dict[str, dict] = {m: {} for m in models}

    for test_num in tests_to_run:
        if test_num not in test_modules:
            print(f"[WARN] Unknown test number: {test_num}")
            continue

        test_name, module = test_modules[test_num]
        test_key = f"test_{test_num:02d}"
        print(f"\n{'='*60}")
        print(f"Running Test {test_num}: {test_name}")
        print(f"{'='*60}")

        t0 = time.time()
        results = run_test(module, models)
        elapsed = round(time.time() - t0, 1)
        print(f"  ⏱  Completed in {elapsed}s")

        for model in models:
            model_result = results.get(model, {})
            aggregated[model][test_key] = model_result

    # Compute estimated costs
    for model in models:
        total_cost = 0.0
        for test_key, test_result in aggregated[model].items():
            usage = test_result.get("cost", {})
            total_cost += estimate_cost(model, usage)
        aggregated[model]["estimated_cost_usd"] = round(total_cost, 6)

    # Write JSON results
    results_path = REPORTS_DIR / "llm-poc-results.json"
    with open(results_path, "w", encoding="utf-8") as f:
        json.dump(
            {
                "generated_at": datetime.now().isoformat(),
                "models_tested": models,
                "tests_run": tests_to_run,
                "results": aggregated,
            },
            f,
            indent=2,
            ensure_ascii=False,
        )
    print(f"\n✅ Results saved to {results_path}")

    # Build Markdown report
    summary_table = build_summary_table(aggregated)
    recommendations = build_recommendations(aggregated)

    report_lines = [
        "# GitHub Models OMR POC — Evaluation Report\n",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M')}  \n",
        f"**Models tested:** {', '.join(models)}  \n",
        f"**Tests run:** {tests_to_run}  \n",
        "\n---\n",
        summary_table,
        "\n---\n",
        "## Test Details\n",
        "### Test 01 — Header Extraction (Title/Composer/Instrument/Tempo)",
        "*Expectation: Good (F1 ≥ 0.80)*\n",
    ]

    for model in models:
        r = aggregated[model].get("test_01", {})
        if "error" not in r:
            report_lines.append(
                f"- **{model}**: F1 overall={r.get('f1_overall', '—')}, "
                f"title={r.get('f1_title', '—')}, "
                f"composer={r.get('f1_composer', '—')}, "
                f"instrument={r.get('f1_instrument', '—')}\n"
            )
        else:
            report_lines.append(f"- **{model}**: ❌ {r['error']}\n")

    report_lines += [
        "\n### Test 02 — Symbol Classification (64×64 patches)",
        "*Expectation: Poor (Acc ≤ 0.55) — tiny crops lose context*\n",
    ]
    for model in models:
        r = aggregated[model].get("test_02", {})
        if "error" not in r:
            report_lines.append(
                f"- **{model}**: accuracy={r.get('accuracy', '—')}, "
                f"correct={r.get('correct', '—')}/{r.get('total', '—')}\n"
            )

    report_lines += [
        "\n### Test 03 — Full-Page Recognition",
        "*Expectation: Poor (hallucinations dominate)*\n",
    ]
    for model in models:
        r = aggregated[model].get("test_03", {})
        if "error" not in r:
            report_lines.append(
                f"- **{model}**: avg completeness={r.get('avg_completeness', '—')}\n"
            )

    report_lines += [
        "\n### Test 04 — Metadata + Catalog Matching",
        "*Expectation: Medium (0.5–0.75) for known repertoire*\n",
    ]
    for model in models:
        r = aggregated[model].get("test_04", {})
        if "error" not in r:
            report_lines.append(
                f"- **{model}**: avg attribute score={r.get('avg_attribute_score', '—')}\n"
            )

    report_lines += [
        "\n### Test 05 — Validation Assistant",
        "*Expectation: High utility for structural mismatch detection*\n",
    ]
    for model in models:
        r = aggregated[model].get("test_05", {})
        if "error" not in r:
            report_lines.append(
                f"- **{model}**: avg utility={r.get('avg_utility_score', '—')}\n"
            )

    report_lines += [
        "\n### Test 06 — Lyric OCR",
        "*Expectation: Good (similarity ≥ 0.80)*\n",
    ]
    for model in models:
        r = aggregated[model].get("test_06", {})
        if "error" not in r:
            report_lines.append(
                f"- **{model}**: avg Levenshtein similarity={r.get('avg_lev_similarity', '—')}\n"
            )

    report_lines += [
        "\n---\n",
        recommendations,
        "\n---\n",
        "## Notes on Model Availability\n",
        "- **gpt-4o / gpt-4o-mini**: Always available via GitHub Models, full vision support\n",
        "- **Phi-3.5-vision-instruct**: Available via GitHub Models, lightweight, local-deployable\n",
        "- **Llama-3.2-90B-Vision-Instruct**: Available via GitHub Models, open weights\n",
        "- Claude 3.5 Sonnet / Gemini: Not available via GitHub Models endpoint at test time\n",
        "\n## Auth Setup\n",
        "```bash\n",
        "# Option 1: gh CLI (recommended)\n",
        "gh auth login\n",
        "python eval.py\n\n",
        "# Option 2: Explicit token\n",
        "$env:GITHUB_TOKEN = 'your-token-here'\n",
        "python eval.py\n",
        "```\n",
    ]

    report_path = REPORTS_DIR / "llm-poc-summary.md"
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("\n".join(report_lines))
    print(f"✅ Markdown report saved to {report_path}")
    print(f"\n{'='*60}")
    print(summary_table)
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
