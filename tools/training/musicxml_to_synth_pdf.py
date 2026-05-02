"""
musicxml_to_synth_pdf.py

Rendert MusicXML-Dateien zu synthetischen PDFs/PNGs (via Verovio) und
erzeugt parallel Ground-Truth-JSON mit Notenkopf-Positionen.

Augmentation (Scan-Simulation) wird auf die gerenderten Bilder angewendet.

Aufruf:
    python musicxml_to_synth_pdf.py \\
        --input-dir data/midi_xml \\
        --output-dir data/synth_corpus \\
        --gt-output reports/synth_gt.json
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import random
import re
import sys
from pathlib import Path
from typing import Any

from tqdm import tqdm

try:
    import verovio
except ImportError as e:
    print(f"ERROR: {e}\n  pip install verovio", file=sys.stderr)
    sys.exit(2)

try:
    from PIL import Image, ImageFilter
    import numpy as np
except ImportError as e:
    print(f"ERROR: {e}\n  pip install Pillow numpy", file=sys.stderr)
    sys.exit(2)

try:
    from music21 import converter
    from music21 import note as m21note
    from music21 import chord as m21chord
    HAS_MUSIC21 = True
except ImportError:
    HAS_MUSIC21 = False

try:
    from lxml import etree as ET
    HAS_LXML = True
except ImportError:
    import xml.etree.ElementTree as ET  # type: ignore
    HAS_LXML = False

# SVG namespace
SVG_NS = "http://www.w3.org/2000/svg"
XLINK_NS = "http://www.w3.org/1999/xlink"

# A4 at 150 DPI → 1240×1754 pixels
A4_W_PX = 1240
A4_H_PX = 1754
A4_DPI = 150

# Verovio units: 1 unit = ~0.1 mm, A4 = 2100×2970 verovio units
VRV_PAGE_W = 2100
VRV_PAGE_H = 2970


# ─── Augmentation (reuses logic from generate_verovio_samples.py) ─────────────

def augment_for_print_scan(img: Image.Image, rng: random.Random) -> Image.Image:
    """Scan-realistic augmentation: slight rotation, contrast, noise, blur."""
    arr = np.array(img, dtype=np.uint8)
    angle = rng.uniform(-1.5, 1.5)
    img = Image.fromarray(arr).rotate(angle, resample=Image.BILINEAR, fillcolor=255)
    arr = np.array(img, dtype=np.float32)
    arr = (arr - 128) * rng.uniform(0.88, 1.12) + 128 * rng.uniform(0.88, 1.0)
    if rng.random() < 0.5:
        sigma = rng.uniform(1.5, 6.0)
        noise = np.random.normal(0, sigma, arr.shape)
        arr = arr + noise
    if rng.random() < 0.4:
        sp = rng.uniform(0.0005, 0.005)
        rand_mask = np.random.random(arr.shape)
        arr[rand_mask < sp / 2] = 0
        arr[rand_mask > 1 - sp / 2] = 255
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    out = Image.fromarray(arr)
    if rng.random() < 0.35:
        out = out.filter(ImageFilter.GaussianBlur(rng.uniform(0.2, 0.8)))
    # JPEG artifact simulation
    buf = io.BytesIO()
    quality = rng.randint(70, 92)
    out.save(buf, format="JPEG", quality=quality)
    buf.seek(0)
    return Image.open(buf).copy()


# ─── Verovio toolkit (singleton per process) ──────────────────────────────────

def make_toolkit() -> Any:
    tk = verovio.toolkit()
    tk.setOptions({
        "pageWidth": VRV_PAGE_W,
        "pageHeight": VRV_PAGE_H,
        "adjustPageHeight": 0,
        "adjustPageWidth": 0,
        "scale": 40,
        "spacingStaff": 8,
        "spacingSystem": 12,
        "pageMarginTop": 100,
        "pageMarginBottom": 100,
        "pageMarginLeft": 150,
        "pageMarginRight": 150,
        "font": "Leipzig",
    })
    return tk


# ─── Note extraction from music21 ─────────────────────────────────────────────

def _pitch_name(p: Any) -> str:
    """Return pitch string like 'G4'."""
    return f"{p.name}{p.octave}"


def extract_notes_music21(xml_path: Path) -> list[dict]:
    """Extract note data (pitch, duration, onset, measure, voice) from MusicXML."""
    if not HAS_MUSIC21:
        return []
    try:
        score = converter.parse(str(xml_path))
    except Exception as e:
        print(f"  WARN: music21 parse failed {xml_path.name}: {e}", file=sys.stderr)
        return []

    notes_out: list[dict] = []
    for part_idx, part in enumerate(score.parts):
        for measure in part.getElementsByClass("Measure"):
            m_num = measure.number if hasattr(measure, "number") else 0
            ts_elem = measure.getElementsByClass("TimeSignature")
            ts_str = "4/4"
            if ts_elem:
                ts = ts_elem[0]
                ts_str = f"{ts.numerator}/{ts.denominator}"
            # Iterate Voice containers (or fall back to whole measure as voice 1)
            voices = list(measure.getElementsByClass("Voice"))
            voices_iter = [(v_idx + 1, v) for v_idx, v in enumerate(voices)] if voices else [(1, measure)]

            for voice_id, container in voices_iter:
                try:
                    elements = list(container.flatten().notesAndRests)
                except Exception:
                    elements = list(container.notesAndRests)
                for el in elements:
                    onset_q = float(el.offset)
                    dur_q = float(el.quarterLength)

                    if isinstance(el, m21note.Note):
                        notes_out.append({
                            "pitch": _pitch_name(el.pitch),
                            "duration": dur_q,
                            "onset": onset_q,
                            "measure": m_num,
                            "voice": voice_id,
                            "part": part_idx,
                            "time_signature": ts_str,
                            "x_pdf": None,
                            "y_pdf": None,
                        })
                    elif isinstance(el, m21chord.Chord):
                        for p in el.pitches:
                            notes_out.append({
                                "pitch": _pitch_name(p),
                                "duration": dur_q,
                                "onset": onset_q,
                                "measure": m_num,
                                "voice": voice_id,
                                "part": part_idx,
                                "time_signature": ts_str,
                                "x_pdf": None,
                                "y_pdf": None,
                            })
    return notes_out


# ─── SVG note-position extraction ─────────────────────────────────────────────

# Verovio SVG class names for noteheads
_NOTEHEAD_CLASSES = {"notehead", "note"}

def _transform_to_xy(transform_str: str) -> tuple[float, float] | None:
    """Parse SVG transform="translate(x,y)" → (x, y)."""
    m = re.search(r"translate\(\s*([0-9.\-]+)\s*,\s*([0-9.\-]+)\s*\)", transform_str or "")
    if m:
        return float(m.group(1)), float(m.group(2))
    return None


def _vrv_to_pixel(x_vrv: float, y_vrv: float, page_w: int = A4_W_PX, page_h: int = A4_H_PX) -> tuple[int, int]:
    """Convert verovio SVG coordinates to pixel coordinates."""
    x_px = int(x_vrv / VRV_PAGE_W * page_w)
    y_px = int(y_vrv / VRV_PAGE_H * page_h)
    return x_px, y_px


def extract_note_positions_from_svg(svg_string: str, page_num: int = 1) -> dict[str, tuple[float, float]]:
    """
    Parse SVG and extract (x,y) positions for note elements.
    Returns dict of {note_id: (x_vrv, y_vrv)}.
    """
    positions: dict[str, tuple[float, float]] = {}
    try:
        if HAS_LXML:
            root = ET.fromstring(svg_string.encode("utf-8"))
        else:
            root = ET.fromstring(svg_string)
    except Exception:
        return positions

    # Walk all elements looking for <g class="note ..."> or <g class="notehead ...">
    def walk(el: Any, parent_x: float = 0.0, parent_y: float = 0.0) -> None:
        trans = el.get("transform", "")
        local_x, local_y = parent_x, parent_y
        xy = _transform_to_xy(trans)
        if xy:
            local_x += xy[0]
            local_y += xy[1]

        el_class = el.get("class", "")
        el_id = el.get("id", "")

        if el_id and any(c in el_class.split() for c in _NOTEHEAD_CLASSES):
            positions[el_id] = (local_x, local_y)

        for child in el:
            walk(child, local_x, local_y)

    walk(root)
    return positions


# ─── Main rendering + GT extraction ──────────────────────────────────────────

def process_musicxml(
    xml_path: Path,
    output_dir: Path,
    tk: Any,
    rng: random.Random,
    augment: bool = True,
) -> dict | None:
    """
    Render one MusicXML to PNG + build GT dict.
    Returns GT record or None on failure.
    """
    try:
        with open(xml_path, "r", encoding="utf-8", errors="replace") as f:
            xml_content = f.read()
    except Exception as e:
        print(f"  WARN: read failed {xml_path.name}: {e}", file=sys.stderr)
        return None

    try:
        if not tk.loadData(xml_content):
            print(f"  WARN: verovio load failed {xml_path.name}", file=sys.stderr)
            return None
    except Exception as e:
        print(f"  WARN: verovio error {xml_path.name}: {e}", file=sys.stderr)
        return None

    n_pages = tk.getPageCount()
    stem = xml_path.stem

    # Extract note metadata via music21
    notes_gt = extract_notes_music21(xml_path)

    # Collect note positions from all SVG pages
    all_svg_positions: dict[str, tuple[float, float]] = {}
    png_paths: list[str] = []

    for page_idx in range(1, n_pages + 1):
        svg = tk.renderToSVG(page_idx)
        page_positions = extract_note_positions_from_svg(svg, page_idx)
        # Offset y by page number for multi-page documents
        for nid, (x, y) in page_positions.items():
            all_svg_positions[nid] = (x, y + (page_idx - 1) * VRV_PAGE_H)

        # Render page to PNG via SVG → PIL
        try:
            png_b64 = tk.renderToSVG(page_idx)
            # Convert SVG to PNG using cairosvg if available, else use PIL/svglib fallback
            page_img = _svg_to_pil(svg, A4_W_PX, A4_H_PX)
            if page_img is None:
                continue

            if augment:
                page_img = augment_for_print_scan(page_img, rng)

            page_name = f"{stem}_p{page_idx:02d}.png"
            page_path = output_dir / page_name
            page_img.save(str(page_path), format="PNG")
            png_paths.append(page_name)
        except Exception as e:
            print(f"  WARN: render page {page_idx} of {xml_path.name}: {e}", file=sys.stderr)
            continue

    if not png_paths:
        return None

    # Build GT record
    gt_record: dict = {
        "source_xml": xml_path.name,
        "pages": png_paths,
        "noteheads": notes_gt,
        "note_positions_svg": {
            nid: {"x_vrv": x, "y_vrv": y}
            for nid, (x, y) in all_svg_positions.items()
        },
        "measures": _extract_measure_gt(notes_gt),
        "stems": [],
    }
    return gt_record


def _extract_measure_gt(notes: list[dict]) -> list[dict]:
    """Build per-measure GT summary."""
    measures: dict[int, dict] = {}
    for n in notes:
        m_num = n.get("measure", 0)
        if m_num not in measures:
            ts = n.get("time_signature", "4/4")
            try:
                num, denom = ts.split("/")
                expected_duration = 4.0 * int(num) / int(denom)
            except Exception:
                expected_duration = 4.0
            measures[m_num] = {
                "number": m_num,
                "time_signature": ts,
                "expected_duration": expected_duration,
                "note_count": 0,
            }
        measures[m_num]["note_count"] += 1
    return sorted(measures.values(), key=lambda x: x["number"])



# Module-level Playwright state (lazy initialized)
_PW_STATE: dict = {}


def _init_playwright() -> bool:
    """Initialize Playwright browser singleton. Returns True on success."""
    if "browser" in _PW_STATE:
        return True
    try:
        import atexit
        from playwright.sync_api import sync_playwright  # type: ignore
        pw = sync_playwright().start()
        browser = pw.chromium.launch(args=["--no-sandbox"])
        _PW_STATE["pw"] = pw
        _PW_STATE["browser"] = browser

        def _cleanup():
            try:
                _PW_STATE["browser"].close()
                _PW_STATE["pw"].stop()
            except Exception:
                pass

        atexit.register(_cleanup)
        return True
    except Exception as e:
        print(f"  WARN: Playwright init failed: {e}", file=sys.stderr)
        return False


def _svg_to_pil(svg_string: str, width: int, height: int) -> Image.Image | None:
    """
    Convert SVG string to PIL Image.
    Uses Playwright (headless Chromium) as primary renderer,
    falls back to white placeholder if unavailable.
    """
    # Primary: Playwright with headless Chromium (best font support)
    try:
        if _init_playwright():
            browser = _PW_STATE["browser"]
            page = browser.new_page(viewport={"width": width, "height": height})
            html = '<html><body>' + svg_string + '</body></html>'

            page.set_content(html)
            page.wait_for_load_state("networkidle", timeout=10_000)
            png_bytes = page.screenshot(full_page=False)
            page.close()
            return Image.open(io.BytesIO(png_bytes)).convert("L")
    except Exception as e:
        print(f"  WARN: Playwright render failed: {e}", file=sys.stderr)

    # Fallback: white placeholder (GT extraction still works)
    return Image.new("L", (width, height), 255)


# ─── Entry point ──────────────────────────────────────────────────────────────

def main() -> None:
    ap = argparse.ArgumentParser(description="MusicXML → synth PNG + GT JSON")
    ap.add_argument("--input-dir", type=Path, default=Path("data/midi_xml"))
    ap.add_argument("--output-dir", type=Path, default=Path("data/synth_corpus"))
    ap.add_argument("--gt-output", type=Path, default=Path("reports/synth_gt.json"))
    ap.add_argument("--no-augment", action="store_true", help="Skip scan augmentation")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--max-files", type=int, default=0, help="Limit files (0=all)")
    args = ap.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    args.gt_output.parent.mkdir(parents=True, exist_ok=True)

    xml_files = sorted(args.input_dir.glob("*.musicxml")) + sorted(args.input_dir.glob("*.xml"))
    if args.max_files > 0:
        xml_files = xml_files[: args.max_files]

    if not xml_files:
        print(f"No MusicXML files found in {args.input_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"Processing {len(xml_files)} MusicXML files...")
    rng = random.Random(args.seed)
    np.random.seed(args.seed)
    tk = make_toolkit()

    all_gt: list[dict] = []
    failed = 0

    for xml_path in tqdm(xml_files, desc="XML→PNG"):
        record = process_musicxml(
            xml_path, args.output_dir, tk, rng,
            augment=not args.no_augment,
        )
        if record:
            all_gt.append(record)
        else:
            failed += 1

    with open(args.gt_output, "w", encoding="utf-8") as f:
        json.dump(all_gt, f, indent=2, ensure_ascii=False)

    total_notes = sum(len(r["noteheads"]) for r in all_gt)
    total_pages = sum(len(r["pages"]) for r in all_gt)
    print(
        f"\nDone — {len(all_gt)} XML files rendered, "
        f"{total_pages} pages, {total_notes} GT noteheads, "
        f"{failed} failed"
    )
    print(f"GT written to {args.gt_output}")


if __name__ == "__main__":
    main()
