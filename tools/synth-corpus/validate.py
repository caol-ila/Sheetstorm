"""
validate.py — laeuft die OMR-Pipeline auf augmentierte PNGs und vergleicht
mit der Ground-Truth aus den .gt.json-Dateien (vom midi_to_parts.py).

Voraussetzungen:
    - Die Sheetstorm-OMR-Engine laeuft (z.B. http://localhost:8091)
    - oder: cargo build --release -p omr-pipeline (lokal aufrufen)

Aufruf:
    python validate.py --pages data/augmented --truth data/musicxml --report report.json
"""
from __future__ import annotations
import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path

try:
    import requests
except ImportError:
    requests = None


def find_truth(page_path: Path, truth_dir: Path) -> Path | None:
    """Mappt augmented-PNG zurück auf seine Ground-Truth-MusicXML.

    Schema: <name>-<inst>-<idx>-pageN-vX.png  →  <name>-<inst>-<idx>.gt.json
    """
    base = page_path.stem
    base = re.sub(r"-page\d+(-v\d+(-\w+)?)?$", "", base)
    base = re.sub(r"-v\d+(-\w+)?$", "", base)
    candidate = truth_dir / f"{base}.gt.json"
    if candidate.exists():
        return candidate
    return None


def call_pipeline_http(png_path: Path, server_url: str) -> dict | None:
    """POST /detections gegen omr-server."""
    if requests is None:
        print("FEHLER: pip install requests", file=sys.stderr)
        return None
    with png_path.open("rb") as f:
        files = {"file": (png_path.name, f, "image/png")}
        try:
            r = requests.post(f"{server_url}/detections", files=files, timeout=120)
            r.raise_for_status()
            return r.json()
        except Exception as e:
            print(f"  HTTP-Fehler: {e}", file=sys.stderr)
            return None


def compare_pitches(detected_pages: list[dict], gt_notes: list[dict]) -> dict:
    """Vergleicht Pipeline-NHs mit Ground-Truth-Notes.

    Match-Strategie: pro Ground-Truth-Note suchen wir die Pipeline-NH mit dem
    nähesten MIDI-Wert. Wenn der MIDI exakt matcht → True-Positive.

    Wir können hier KEINE räumliche Korrelation machen weil wir die
    GT-Notes als Sequenz haben (onset_q + midi) und die NHs als Bbox-Coords
    (in Render-Pixel-Koordinaten). Wir sortieren beide nach Reading-Order
    und matchen positional.
    """
    pipeline_notes = []
    for page in detected_pages:
        for nh in page.get("noteheads", []):
            if nh.get("midi") is not None:
                pipeline_notes.append({
                    "midi": nh["midi"],
                    "duration": nh.get("duration"),
                    "x": nh["bbox"][0],
                    "y": nh["bbox"][1],
                })
    # Sortiere nach Reading-Order (oben-zu-unten in Zeile, links-zu-rechts)
    pipeline_notes.sort(key=lambda n: (n["y"] // 100, n["x"]))
    gt_sorted = [n for n in gt_notes if not n.get("in_chord")]
    gt_sorted.sort(key=lambda n: n["onset_q"])

    n_gt = len(gt_sorted)
    n_pipe = len(pipeline_notes)
    n_match = min(n_gt, n_pipe)

    pitch_correct = 0
    duration_correct = 0
    for i in range(n_match):
        if pipeline_notes[i]["midi"] == gt_sorted[i]["midi"]:
            pitch_correct += 1
        # Duration-Vergleich: Pipeline-duration ist in ticks (1=16th, 2=8th, 4=quarter, ...)
        # GT-duration ist quarterLength (1.0=quarter, 0.5=8th, ...)
        gt_dur_q = gt_sorted[i]["duration_q"]
        pipe_dur = pipeline_notes[i].get("duration")
        if pipe_dur is not None:
            pipe_q = pipe_dur / 4.0
            if abs(pipe_q - gt_dur_q) < 0.05:
                duration_correct += 1

    pitch_recall = pitch_correct / n_gt if n_gt > 0 else 0.0
    pitch_precision = pitch_correct / n_pipe if n_pipe > 0 else 0.0
    pitch_f1 = (2 * pitch_recall * pitch_precision / (pitch_recall + pitch_precision)
                if pitch_recall + pitch_precision > 0 else 0.0)

    duration_recall = duration_correct / n_gt if n_gt > 0 else 0.0

    return {
        "n_gt_notes": n_gt,
        "n_pipeline_notes": n_pipe,
        "pitch_correct": pitch_correct,
        "duration_correct": duration_correct,
        "pitch_recall": pitch_recall,
        "pitch_precision": pitch_precision,
        "pitch_f1": pitch_f1,
        "duration_recall": duration_recall,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pages", type=Path, required=True, help="Verzeichnis mit augmented PNGs")
    ap.add_argument("--truth", type=Path, required=True, help="Verzeichnis mit .gt.json")
    ap.add_argument("--report", type=Path, default=Path("report.json"))
    ap.add_argument("--server", default="http://localhost:8091",
                    help="omr-server URL (default: lokaler Sidecar)")
    ap.add_argument("--limit", type=int, default=0, help="Nur ersten N Seiten verarbeiten")
    args = ap.parse_args()

    pages = sorted(args.pages.rglob("*.png"))
    if args.limit > 0:
        pages = pages[: args.limit]
    print(f"Validiere {len(pages)} Seiten gegen GT in {args.truth}")

    per_page = []
    sums = {"pitch_correct": 0, "duration_correct": 0, "n_gt": 0, "n_pipe": 0}
    t0 = time.time()
    for i, png in enumerate(pages):
        truth = find_truth(png, args.truth)
        if truth is None:
            print(f"  [{i+1}/{len(pages)}] {png.name}: GT fehlt, skip")
            continue
        gt_doc = json.loads(truth.read_text(encoding="utf-8"))
        gt_notes = gt_doc.get("notes", [])

        detect = call_pipeline_http(png, args.server)
        if detect is None:
            print(f"  [{i+1}/{len(pages)}] {png.name}: Pipeline-Fehler, skip")
            continue

        metrics = compare_pitches(detect.get("pages", []), gt_notes)
        per_page.append({
            "page": str(png),
            "truth": str(truth),
            "metrics": metrics,
        })
        sums["pitch_correct"] += metrics["pitch_correct"]
        sums["duration_correct"] += metrics["duration_correct"]
        sums["n_gt"] += metrics["n_gt_notes"]
        sums["n_pipe"] += metrics["n_pipeline_notes"]
        elapsed = time.time() - t0
        rate = (i + 1) / elapsed if elapsed > 0 else 0
        print(f"  [{i+1}/{len(pages)}] {png.name}: pitch_f1={metrics['pitch_f1']:.2f} "
              f"({rate:.1f} pages/sec)")

    summary = {
        "total_pages": len(per_page),
        "total_gt_notes": sums["n_gt"],
        "total_pipeline_notes": sums["n_pipe"],
        "pitch_recall": sums["pitch_correct"] / sums["n_gt"] if sums["n_gt"] > 0 else 0.0,
        "pitch_precision": sums["pitch_correct"] / sums["n_pipe"] if sums["n_pipe"] > 0 else 0.0,
        "duration_recall": sums["duration_correct"] / sums["n_gt"] if sums["n_gt"] > 0 else 0.0,
    }
    summary["pitch_f1"] = (2 * summary["pitch_recall"] * summary["pitch_precision"]
                          / (summary["pitch_recall"] + summary["pitch_precision"])
                          if summary["pitch_recall"] + summary["pitch_precision"] > 0 else 0.0)

    report = {"summary": summary, "per_page": per_page}
    args.report.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nReport: {args.report}")
    print(f"Gesamt-Pitch-F1: {summary['pitch_f1']:.3f} "
          f"({summary['pitch_recall']:.3f} R / {summary['pitch_precision']:.3f} P)")
    print(f"Gesamt-Duration-Recall: {summary['duration_recall']:.3f}")


if __name__ == "__main__":
    main()
