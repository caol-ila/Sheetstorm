"""
eval_synth_corpus.py

Evaluiert die OMR-Pipeline gegen die synthetischen Ground-Truth-Daten.

Workflow:
  1. Lade GT-JSON (erzeugt von musicxml_to_synth_pdf.py)
  2. Sende jedes PNG/PDF an den OMR-Server (POST /detections)
  3. Vergleiche erkannte Notenköpfe mit GT:
     - Recall:    % GT-NHs die einen Match in den Detections haben
     - Precision: % Detections die einem GT-NH entsprechen
     - Pitch-Acc: % korrekt identifizierter Pitches
     - Dur-Acc:   % korrekt identifizierter Durations

Aufruf:
    python eval_synth_corpus.py \\
        --filestore data/synth_corpus \\
        --gt-file reports/synth_gt.json \\
        --server http://localhost:8091 \\
        --output reports/eval_synth.json
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any

from tqdm import tqdm

try:
    import requests
except ImportError as e:
    print(f"ERROR: {e}\n  pip install requests", file=sys.stderr)
    sys.exit(2)

try:
    import numpy as np
except ImportError as e:
    print(f"ERROR: {e}\n  pip install numpy", file=sys.stderr)
    sys.exit(2)

# Match radius: 0.5 * staff_spacing in pixels
# We estimate 1 staff space ≈ 20px at 150 DPI with scale=40
DEFAULT_MATCH_RADIUS_PX = 20.0

# VRV page dimensions (must match musicxml_to_synth_pdf.py)
VRV_PAGE_W = 2100
VRV_PAGE_H = 2970
A4_W_PX = 1240
A4_H_PX = 1754


def vrv_to_pixel(x_vrv: float, y_vrv: float) -> tuple[int, int]:
    x_px = int(x_vrv / VRV_PAGE_W * A4_W_PX)
    y_px = int(y_vrv / VRV_PAGE_H * A4_H_PX)
    return x_px, y_px


# ─── OMR Server API ────────────────────────────────────────────────────────────

def send_to_omr(server_url: str, image_path: Path, timeout: int = 30) -> dict | None:
    """POST an image to the OMR server. Returns parsed response or None."""
    url = server_url.rstrip('/') + '/detections'
    try:
        suffix = image_path.suffix.lower()
        ct = 'image/png' if suffix == '.png' else 'image/jpeg' if suffix in ('.jpg', '.jpeg') else 'application/pdf'
        with open(image_path, 'rb') as f:
            files = {'file': (image_path.name, f, ct)}
            resp = requests.post(url, files=files, timeout=timeout)
        if resp.status_code == 200:
            return resp.json()
        # Handle known server states gracefully
        try:
            body = resp.json()
            kind = body.get('kind', '')
            if kind == 'missing-detections':
                # Server processed the image but found no noteheads
                return {'noteheads': [], '_server_status': 'missing-detections'}
        except Exception:
            pass
        print(
            f'  WARN: OMR server returned {resp.status_code} for {image_path.name}',
            file=sys.stderr,
        )
        return None
    except requests.exceptions.ConnectionError:
        print(f'  ERROR: Cannot connect to OMR server at {server_url}', file=sys.stderr)
        return None
    except Exception as e:
        print(f'  WARN: OMR request failed for {image_path.name}: {e}', file=sys.stderr)
        return None

def extract_detections(omr_response: dict) -> list[dict]:
    """
    Normalize OMR server response to list of detection dicts.
    Expected formats:
      - {"noteheads": [{"x": .., "y": .., "pitch": .., "duration": ..}, ...]}
      - {"detections": [...]}
      - [{"x": .., "y": ..}, ...]
    """
    if isinstance(omr_response, list):
        return omr_response
    if "noteheads" in omr_response:
        return omr_response["noteheads"]
    if "detections" in omr_response:
        return omr_response["detections"]
    # Try to find any list in the response
    for v in omr_response.values():
        if isinstance(v, list) and v:
            return v
    return []


# ─── Matching logic ────────────────────────────────────────────────────────────

def match_noteheads(
    gt_notes: list[dict],
    detections: list[dict],
    svg_positions: dict[str, dict],
    match_radius_px: float = DEFAULT_MATCH_RADIUS_PX,
) -> dict:
    """
    Match GT noteheads against detected noteheads.

    GT coordinates come from SVG positions (converted to pixels).
    Detection coordinates come from the OMR server response.

    Returns metrics dict.
    """
    # Build list of (x_px, y_px) for GT noteheads that have position data
    gt_with_pos: list[tuple[float, float, dict]] = []

    # Use svg_positions for coordinate lookup; fall back to x_pdf/y_pdf in the note dict
    for n in gt_notes:
        x_px = n.get("x_pdf")
        y_px = n.get("y_pdf")
        if x_px is None or y_px is None:
            # SVG positions are keyed by note element IDs — we don't have a direct mapping
            # here. Use estimated positions from measure/onset if available.
            continue
        gt_with_pos.append((float(x_px), float(y_px), n))

    # If we have SVG positions, prefer them
    if svg_positions and not gt_with_pos:
        for nid, pos in svg_positions.items():
            x_px, y_px = vrv_to_pixel(pos.get("x_vrv", 0), pos.get("y_vrv", 0))
            gt_with_pos.append((float(x_px), float(y_px), {"note_id": nid}))

    det_coords: list[tuple[float, float, dict]] = []
    for d in detections:
        x = d.get("x") or d.get("cx") or d.get("col") or 0
        y = d.get("y") or d.get("cy") or d.get("row") or 0
        det_coords.append((float(x), float(y), d))

    if not gt_with_pos or not det_coords:
        return {
            "recall": None,
            "precision": None,
            "pitch_accuracy": None,
            "duration_accuracy": None,
            "gt_count": len(gt_notes),
            "det_count": len(detections),
            "gt_with_pos": len(gt_with_pos),
            "matched": 0,
            "note": "insufficient position data",
        }

    gt_arr = np.array([(x, y) for x, y, _ in gt_with_pos])
    det_arr = np.array([(x, y) for x, y, _ in det_coords])

    # For each GT note, find nearest detection
    tp_gt = 0
    tp_det_indices: set[int] = set()
    pitch_correct = 0
    dur_correct = 0
    pitch_total = 0

    for i, (gx, gy, gn) in enumerate(gt_with_pos):
        dists = np.sqrt(((det_arr[:, 0] - gx) ** 2) + ((det_arr[:, 1] - gy) ** 2))
        j = int(np.argmin(dists))
        if dists[j] <= match_radius_px:
            tp_gt += 1
            tp_det_indices.add(j)
            # Check pitch/duration if available
            d_info = det_coords[j][2]
            gt_pitch = gn.get("pitch")
            det_pitch = d_info.get("pitch")
            if gt_pitch is not None and det_pitch is not None:
                pitch_total += 1
                if str(gt_pitch) == str(det_pitch):
                    pitch_correct += 1

    recall = tp_gt / len(gt_with_pos) if gt_with_pos else None
    precision = len(tp_det_indices) / len(det_coords) if det_coords else None
    pitch_acc = (pitch_correct / pitch_total) if pitch_total > 0 else None

    return {
        "recall": round(recall, 4) if recall is not None else None,
        "precision": round(precision, 4) if precision is not None else None,
        "pitch_accuracy": round(pitch_acc, 4) if pitch_acc is not None else None,
        "duration_accuracy": None,  # requires structured OMR output
        "gt_count": len(gt_notes),
        "det_count": len(detections),
        "gt_with_pos": len(gt_with_pos),
        "matched": tp_gt,
    }


# ─── Per-file evaluation ────────────────────────────────────────────────────────

def eval_one_record(
    record: dict,
    filestore: Path,
    server_url: str,
    match_radius_px: float,
) -> dict:
    """Evaluate a single GT record (one MusicXML → N pages)."""
    pages = record.get("pages", [])
    gt_notes = record.get("noteheads", [])
    svg_positions = record.get("note_positions_svg", {})

    page_results: list[dict] = []
    all_detections: list[dict] = []

    for page_name in pages:
        img_path = filestore / page_name
        if not img_path.exists():
            page_results.append({"page": page_name, "error": "file not found"})
            continue

        omr_resp = send_to_omr(server_url, img_path)
        if omr_resp is None:
            page_results.append({"page": page_name, "error": "omr request failed"})
            continue

        dets = extract_detections(omr_resp)
        all_detections.extend(dets)
        page_results.append({
            "page": page_name,
            "detection_count": len(dets),
        })

    metrics = match_noteheads(gt_notes, all_detections, svg_positions, match_radius_px)

    return {
        "source": record.get("source_xml", ""),
        "pages": page_results,
        "metrics": metrics,
    }


# ─── Entry point ──────────────────────────────────────────────────────────────

def main() -> None:
    ap = argparse.ArgumentParser(description="Eval OMR pipeline against synth GT corpus")
    ap.add_argument("--filestore", type=Path, default=Path("data/synth_corpus"),
                    help="Directory containing synth PNG files")
    ap.add_argument("--gt-file", type=Path, default=Path("reports/synth_gt.json"),
                    help="Ground truth JSON from musicxml_to_synth_pdf.py")
    ap.add_argument("--server", default="http://localhost:8091",
                    help="OMR server base URL")
    ap.add_argument("--output", type=Path, default=Path("reports/eval_synth.json"),
                    help="Output report JSON")
    ap.add_argument("--match-radius", type=float, default=DEFAULT_MATCH_RADIUS_PX,
                    help="Match radius in pixels (0.5 × staff spacing)")
    ap.add_argument("--max-files", type=int, default=0,
                    help="Limit evaluation to N records (0=all)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Skip OMR server calls, output GT-only report")
    args = ap.parse_args()

    if not args.gt_file.exists():
        print(f"ERROR: GT file not found: {args.gt_file}", file=sys.stderr)
        sys.exit(1)

    with open(args.gt_file, "r", encoding="utf-8") as f:
        gt_records: list[dict] = json.load(f)

    if args.max_files > 0:
        gt_records = gt_records[: args.max_files]

    print(f"Evaluating {len(gt_records)} records against {args.server}...")
    print(f"Match radius: {args.match_radius}px")

    # Check server connectivity (unless dry-run)
    if not args.dry_run:
        try:
            requests.get(args.server.rstrip("/") + "/health", timeout=5)
        except Exception:
            try:
                # Try the detections endpoint with a dummy
                pass
            except Exception:
                print(f"  INFO: OMR server may not be reachable at {args.server}", file=sys.stderr)

    results: list[dict] = []
    for record in tqdm(gt_records, desc="Evaluating"):
        if args.dry_run:
            results.append({
                "source": record.get("source_xml", ""),
                "metrics": {
                    "gt_count": len(record.get("noteheads", [])),
                    "note": "dry-run, no OMR evaluation",
                },
            })
        else:
            result = eval_one_record(record, args.filestore, args.server, args.match_radius)
            results.append(result)

    # Aggregate metrics
    recall_vals = [r["metrics"]["recall"] for r in results if r["metrics"].get("recall") is not None]
    prec_vals = [r["metrics"]["precision"] for r in results if r["metrics"].get("precision") is not None]
    pitch_vals = [r["metrics"]["pitch_accuracy"] for r in results if r["metrics"].get("pitch_accuracy") is not None]

    summary = {
        "total_records": len(results),
        "records_with_metrics": len(recall_vals),
        "mean_recall": round(float(np.mean(recall_vals)), 4) if recall_vals else None,
        "mean_precision": round(float(np.mean(prec_vals)), 4) if prec_vals else None,
        "mean_pitch_accuracy": round(float(np.mean(pitch_vals)), 4) if pitch_vals else None,
        "total_gt_notes": sum(r["metrics"].get("gt_count", 0) for r in results),
        "total_detections": sum(r["metrics"].get("det_count", 0) for r in results),
        "total_matched": sum(r["metrics"].get("matched", 0) for r in results),
        "dry_run": args.dry_run,
        "match_radius_px": args.match_radius,
    }

    report = {"summary": summary, "per_file": results}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    # Print summary
    print("\n" + "=" * 60)
    print("EVAL SUMMARY")
    print("=" * 60)
    for k, v in summary.items():
        print(f"  {k}: {v}")
    print(f"\nReport written to {args.output}")


if __name__ == "__main__":
    main()
