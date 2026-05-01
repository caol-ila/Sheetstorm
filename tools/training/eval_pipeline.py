"""
eval_pipeline.py

Misst die OMR-Qualität auf einem Korpus realer User-PDFs. Liefert:
- Plausibility (% measures exact + repaired)
- Stem-Coverage (% NHs mit detected stem)
- Slur/Tie/Reading-Anomaly Counts
- Per-PDF Breakdown
- JSON Report fuer CI-Integration / Trend-Tracking

Aufruf:
    python eval_pipeline.py \\
        --filestore ../../src/.filestore/parts \\
        --server http://localhost:8091 \\
        --output reports/eval_$(date +%Y%m%d).json
"""
from __future__ import annotations
import argparse
import io
import json
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    import requests
except ImportError:
    print("FEHLER: pip install requests", file=sys.stderr)
    sys.exit(2)


def call_pipeline(pdf_path: Path, server_url: str, timeout: int = 120) -> Optional[dict]:
    try:
        with pdf_path.open("rb") as f:
            files = {"file": (pdf_path.name, f, "application/pdf")}
            r = requests.post(f"{server_url}/detections", files=files, timeout=timeout)
            r.raise_for_status()
            return r.json()
    except Exception as e:
        print(f"  HTTP-Fehler {pdf_path.name}: {e}", file=sys.stderr)
        return None


def analyze_response(detections: dict) -> dict:
    """Analysiert eine /detections-Response und liefert per-Page-Metrics."""
    summary = {
        "n_pages": 0,
        "n_measures": 0,
        "n_exact": 0,
        "n_repaired": 0,
        "n_broken": 0,
        "n_noteheads": 0,
        "n_stems": 0,
        "n_bars": 0,
        "n_rests": 0,
        "n_slurs": 0,
        "n_ties": 0,
        "n_anomalies": 0,
        "anomaly_breakdown": {},
        "kind_breakdown": {"Filled": 0, "Open": 0, "Whole": 0},
    }
    pages = detections.get("pages") or []
    for page in pages:
        summary["n_pages"] += 1
        nhs = page.get("noteheads") or []
        summary["n_noteheads"] += len(nhs)
        for nh in nhs:
            kind = nh.get("kind", "Filled")
            summary["kind_breakdown"][kind] = summary["kind_breakdown"].get(kind, 0) + 1
        summary["n_stems"] += len(page.get("stems") or [])
        summary["n_bars"] += len(page.get("bars") or [])
        summary["n_rests"] += len(page.get("rests") or [])
        slurs = page.get("slurs") or []
        summary["n_slurs"] += len([s for s in slurs if not s.get("is_tie")])
        summary["n_ties"] += len([s for s in slurs if s.get("is_tie")])
        for m in page.get("measures") or []:
            summary["n_measures"] += 1
            p = m.get("plausibility")
            if p == "exact": summary["n_exact"] += 1
            elif p == "broken": summary["n_broken"] += 1
            else: summary["n_repaired"] += 1
        rs = page.get("reading_stream") or {}
        for sys_data in rs.get("systems") or []:
            for a in sys_data.get("anomalies") or []:
                summary["n_anomalies"] += 1
                t = a.get("type", "unknown")
                summary["anomaly_breakdown"][t] = summary["anomaly_breakdown"].get(t, 0) + 1
    return summary


def compute_metrics(s: dict) -> dict:
    """Aggregierte Metriken aus Summary."""
    m = dict(s)
    n_meas = max(1, s["n_measures"])
    n_nh = max(1, s["n_noteheads"])
    m["plausibility_pct"] = round(100.0 * (s["n_exact"] + s["n_repaired"]) / n_meas, 2)
    m["exact_pct"] = round(100.0 * s["n_exact"] / n_meas, 2)
    m["broken_pct"] = round(100.0 * s["n_broken"] / n_meas, 2)
    m["stem_coverage_pct"] = round(100.0 * s["n_stems"] / n_nh, 2)
    return m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--filestore", type=Path, required=True,
                    help="Pfad zu src/.filestore/parts")
    ap.add_argument("--server", default="http://localhost:8091")
    ap.add_argument("--output", type=Path,
                    default=Path(f"reports/eval_{datetime.now():%Y%m%d_%H%M%S}.json"))
    ap.add_argument("--min-size-kb", type=int, default=50)
    ap.add_argument("--exclude-pattern", default="E2E-TEST",
                    help="Regex-Pattern fuer auszuschliessende PDFs")
    args = ap.parse_args()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    pdfs = []
    for p in args.filestore.rglob("*.pdf"):
        if p.stat().st_size < args.min_size_kb * 1024: continue
        if re.search(args.exclude_pattern, p.name): continue
        pdfs.append(p)

    print(f"Eval-Korpus: {len(pdfs)} PDFs aus {args.filestore}")
    print(f"Server: {args.server}")
    print()

    per_pdf = []
    aggregate = {
        "n_pages": 0, "n_measures": 0, "n_exact": 0, "n_repaired": 0, "n_broken": 0,
        "n_noteheads": 0, "n_stems": 0, "n_bars": 0, "n_rests": 0,
        "n_slurs": 0, "n_ties": 0, "n_anomalies": 0,
        "anomaly_breakdown": {}, "kind_breakdown": {"Filled": 0, "Open": 0, "Whole": 0},
    }
    pdfs_with_errors = []

    for i, pdf in enumerate(pdfs):
        t0 = time.time()
        det = call_pipeline(pdf, args.server)
        elapsed = time.time() - t0
        if det is None:
            pdfs_with_errors.append(pdf.name)
            continue
        summary = analyze_response(det)
        metrics = compute_metrics(summary)
        per_pdf.append({
            "name": pdf.name,
            "size_kb": round(pdf.stat().st_size / 1024, 1),
            "elapsed_sec": round(elapsed, 2),
            **metrics,
        })
        # Aggregate
        for k in ["n_pages", "n_measures", "n_exact", "n_repaired", "n_broken",
                  "n_noteheads", "n_stems", "n_bars", "n_rests",
                  "n_slurs", "n_ties", "n_anomalies"]:
            aggregate[k] += summary[k]
        for t, n in summary["anomaly_breakdown"].items():
            aggregate["anomaly_breakdown"][t] = aggregate["anomaly_breakdown"].get(t, 0) + n
        for k, n in summary["kind_breakdown"].items():
            aggregate["kind_breakdown"][k] = aggregate["kind_breakdown"].get(k, 0) + n
        print(f"  [{i+1}/{len(pdfs)}] {pdf.name[:50]:<50} "
              f"plausibility={metrics['plausibility_pct']:>6.2f}%  "
              f"stems={metrics['stem_coverage_pct']:>6.2f}%  "
              f"({elapsed:.1f}s)")

    # Final aggregate metrics
    final = compute_metrics(aggregate)
    final["n_pdfs"] = len(per_pdf)
    final["pdfs_with_errors"] = pdfs_with_errors
    final["timestamp"] = datetime.now().isoformat()
    final["server"] = args.server
    final["filestore"] = str(args.filestore)

    report = {
        "aggregate": final,
        "per_pdf": per_pdf,
    }
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    print()
    print("=" * 70)
    print(f"EVAL-SUMMARY ({len(per_pdf)} PDFs)")
    print("=" * 70)
    print(f"  Plausibility:     {final['plausibility_pct']:.2f}%  ({final['n_exact'] + final['n_repaired']} / {final['n_measures']})")
    print(f"    Exact:          {final['exact_pct']:.2f}%  ({final['n_exact']})")
    print(f"    Repaired:       {round(100.0 * final['n_repaired'] / max(1, final['n_measures']), 2):.2f}%  ({final['n_repaired']})")
    print(f"    Broken:         {final['broken_pct']:.2f}%  ({final['n_broken']})")
    print(f"  Stem-Coverage:    {final['stem_coverage_pct']:.2f}%  ({final['n_stems']} / {final['n_noteheads']})")
    print(f"  Slurs / Ties:     {final['n_slurs']} / {final['n_ties']}")
    print(f"  Anomalies (Reader): {final['n_anomalies']}")
    print(f"  NH-Kind-Breakdown: {final['kind_breakdown']}")
    if pdfs_with_errors:
        print(f"\n  ⚠️ {len(pdfs_with_errors)} PDFs mit Pipeline-Fehler")
    print(f"\nReport: {args.output}")


if __name__ == "__main__":
    main()
