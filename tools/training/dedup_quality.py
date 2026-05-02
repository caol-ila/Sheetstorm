"""dedup_quality.py — Aggregiert Quality-Stats pro UNIQUE PDF.

Der reale Test-Filestore enthält viele Kopien desselben PDFs (durch
unterschiedliche User-Sessions). Diese Aggregation verfälscht die
Quality-Metriken — eine einzelne broken-Measure in einem oft-hochgeladenen
PDF wird vielfach gezählt.

Dieses Skript dedupliziert per filename-stem (alles nach dem ersten "-")
und zeigt die wahre Quality auf eindeutigen PDFs.

Usage:
    python dedup_quality.py [--report reports/eval_xxx.json]
"""
import argparse
import json
from collections import defaultdict
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument(
        "--report",
        default="reports/eval_fixed_metrics.json",
        type=Path,
        help="Eval-Report JSON",
    )
    args = parser.parse_args()

    report_path = args.report
    if not report_path.is_absolute():
        report_path = Path(__file__).parent / report_path

    with open(report_path, encoding="utf-8") as f:
        j = json.load(f)

    by_base: dict[str, list[dict]] = defaultdict(list)
    for p in j["per_pdf"]:
        # Filestore-Namen sind typisch "<guid>-<original>.pdf" — splitte am ersten "-"
        base = p["name"].split("-", 1)[1] if "-" in p["name"] else p["name"]
        by_base[base].append(p)

    unique_pdfs: list[dict] = []
    for base, copies in by_base.items():
        p = dict(copies[0])
        p["name"] = base
        p["n_copies_in_dataset"] = len(copies)
        unique_pdfs.append(p)

    n_total = len(j["per_pdf"])
    print(f"Unique PDFs: {len(unique_pdfs)} (from {n_total} total copies)\n")

    total_meas = sum(p["n_measures"] for p in unique_pdfs)
    total_exact = sum(p["n_exact"] for p in unique_pdfs)
    total_rep = sum(p["n_repaired"] for p in unique_pdfs)
    total_ana = sum(p.get("n_anacrusis", 0) for p in unique_pdfs)
    total_br = sum(p["n_broken"] for p in unique_pdfs)
    total_nh = sum(p["n_noteheads"] for p in unique_pdfs)
    total_st = sum(p["n_stems"] for p in unique_pdfs)
    plau = (total_exact + total_rep + total_ana) / total_meas * 100
    exact_pct = total_exact / total_meas * 100
    stem_cov = total_st / total_nh * 100

    print(f"Deduplicated Quality (across {len(unique_pdfs)} unique PDFs):")
    print(f"  Total measures: {total_meas}")
    print(f"  Plausibility:   {plau:.2f}% (exact+repaired+anacrusis)")
    print(f"  Exact:          {exact_pct:.2f}%")
    print(f"  Repaired:       {total_rep}")
    print(f"  Anacrusis:      {total_ana}")
    print(f"  Broken:         {total_br}")
    print(f"  Stem-Coverage:  {stem_cov:.2f}%\n")

    print("Per unique PDF:")
    for p in sorted(
        unique_pdfs, key=lambda x: -x.get("n_broken", 0) - x.get("n_repaired", 0)
    ):
        nm = p["name"][:55]
        n_meas = p["n_measures"]
        n_ex = p["n_exact"]
        n_rep = p["n_repaired"]
        n_ana = p.get("n_anacrusis", 0)
        n_br = p["n_broken"]
        n_cop = p["n_copies_in_dataset"]
        print(
            f"  {nm:<55} meas={n_meas:3d} ex={n_ex:3d} "
            f"rep={n_rep:2d} ana={n_ana:2d} br={n_br:2d}  copies={n_cop}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

