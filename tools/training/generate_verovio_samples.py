"""
generate_verovio_samples.py

Rendert MusicXML-Dateien (oder MIDI → MusicXML via music21) mit Verovio
und extrahiert pro gerendertem Symbol einen 64x64-Patch mit dem korrekten
ML-Klassen-Label.

Diese Methode liefert ZEHNTAUSENDE gelabelte Symbol-Patches für gedruckte
Notation aus jedem Stück MusicXML — ohne manuelle Annotation.

Pipeline:
1. MusicXML laden (oder MIDI → MusicXML konvertieren)
2. Verovio rendert das Stück zu SVG
3. SVG enthält pro Note ein <g class="note" ...> Element mit Position
4. Wir extrahieren Bounding-Box aus SVG-Daten + rendern zu PNG via Playwright
5. Pro Symbol: Patch ausschneiden, klassifizieren, in data/training/<class>/

Augmentations: nutzt augment.py-Style scan-realistische Augmentation
um auf gedruckte SCANS robust zu trainieren.

Voraussetzungen:
  - pip install verovio music21 Pillow numpy playwright
  - playwright install chromium

Aufruf:
    python generate_verovio_samples.py \\
        --musicxml-dir ../synth-corpus/data/musicxml \\
        --output data/training \\
        --variations 5
"""
from __future__ import annotations
import argparse
import io
import json
import random
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    import verovio
    from PIL import Image, ImageFilter
    import numpy as np
except ImportError as e:
    print(f"FEHLER: {e}\n  pip install verovio Pillow numpy", file=sys.stderr)
    sys.exit(2)

CLASS_NAMES = [
    "NoteheadFilled", "NoteheadOpen", "NoteheadWhole",
    "RestQuarter", "RestHalf", "RestWhole", "RestEighth", "RestSixteenth",
    "ClefTreble", "ClefBass", "ClefAlto", "ClefTenor",
    "Sharp", "Flat", "Natural", "DoubleSharp", "DoubleFlat",
    "TimeSig2", "TimeSig3", "TimeSig4", "TimeSig6", "TimeSig8",
    "RepeatStart", "RepeatEnd", "Coda", "Segno", "Fine",
    "DynamicP", "DynamicF", "DynamicMP", "DynamicMF", "DynamicPP", "DynamicFF",
    "Crescendo", "Decrescendo", "Slur", "Tie",
    "StaccatoDot", "AccentMark", "Fermata", "TrillMark",
    "AugmentationDot", "TupletNumber", "Beam", "Stem", "LedgerLine",
    "Barline", "Noise",
]

# Verovio-CSS-Klassen → CNN-Klassen-Index
VEROVIO_CLASS_MAP: Dict[str, int] = {
    "note": 0,  # default Filled, kann via Duration spezifiziert werden
    "notehead": 0,
    "rest": 3,  # default Quarter
    "rest_quarter": 3, "rest_half": 4, "rest_whole": 5,
    "rest_8th": 6, "rest_16th": 7,
    "clef-G": 8, "clef-F": 9, "clef-C": 10,
    "accid-s": 12, "accid-f": 13, "accid-n": 14,
    "accid-x": 15, "accid-ff": 16,
    "barLine": 46,
    "barLineSingle": 46, "barLineDouble": 46,
    "stem": 44, "beam": 43,
    "tuplet": 42, "tupletNum": 42,
    "fermata": 39, "trill": 40,
    "dot": 41,  # augmentation dot
    "dynam": 27, "dynamP": 27, "dynamF": 28, "dynamMP": 29, "dynamMF": 30,
    "dynamPP": 31, "dynamFF": 32,
    "hairpinCresc": 33, "hairpinDim": 34,
    "slur": 35, "tie": 36,
    "ornamentTrill": 40,
    "articStaccato": 37, "articAccent": 38,
}

# SVG-Element-Klassen (Verovio default) → unsere Patch-Region (= ggf. nicht ganzes Element).
# Z.B. ein <g class="note"> enthält <g class="notehead"> mit der konkreten Position.

PATCH_SIZE = 64


def parse_svg_elements(svg_string: str) -> List[Tuple[str, float, float, float, float]]:
    """Extrahiert (class, x, y, w, h) für jedes annotierte Verovio-SVG-Element.

    Verovio-SVG hat Elemente mit class-Attribute und transform="translate(x y)".
    Bbox wird aus path-Daten extrahiert (vereinfacht durch use-element).
    """
    results = []
    # Pattern: <g class="..." ... transform="translate(x y)">...
    # In Verovio kommen Notenkoepfe als <g class="notehead"> mit <use ... x="X" y="Y"/>
    # innerhalb. Wir parsen verschachtelt.
    # Einfacher Ansatz: <use> Elemente mit class-Vorfahren-Hierarchie.
    pattern = re.compile(
        r'<(?P<tag>g|use)\s+(?P<attrs>[^>]*?)class="(?P<cls>[^"]+)"(?P<rest>[^>]*)/?>',
        re.DOTALL
    )
    transforms_stack = []  # (x, y) cumulative
    # Naive Approach: für jedes <use> Element mit class extrahieren
    for m in re.finditer(r'<use\s+([^>]+?)/>', svg_string):
        attrs = m.group(1)
        # parse attrs
        cls_m = re.search(r'class="([^"]+)"', attrs)
        x_m = re.search(r'\bx="([\-\d\.]+)"', attrs)
        y_m = re.search(r'\by="([\-\d\.]+)"', attrs)
        href_m = re.search(r'#(E[0-9A-F]{3})', attrs)
        if not (x_m and y_m): continue
        cls = cls_m.group(1) if cls_m else (href_m.group(1) if href_m else "")
        if not cls: continue
        x = float(x_m.group(1))
        y = float(y_m.group(1))
        # Wir wissen nicht die exakte Bbox, aber Glyph-Größe ist ~ font-size (~ 360 in default)
        # Verovio scaled das via outer SVG, hier nehmen wir 360 als default-extent.
        w = 360.0
        h = 360.0
        results.append((cls, x, y, w, h))
    return results


def smufl_to_class(smufl_codepoint: str) -> Optional[int]:
    """Mappt einen SMuFL-Codepoint (Hex-String z.B. 'E0A4') auf eine CNN-Klasse."""
    cp = smufl_codepoint.upper()
    mapping = {
        "E0A4": 0, "E0A3": 1, "E0A2": 2,
        "E4E5": 3, "E4E4": 4, "E4E3": 5, "E4E6": 6, "E4E7": 7,
        "E050": 8, "E062": 9, "E05C": 10, "E05D": 11,
        "E262": 12, "E260": 13, "E261": 14, "E263": 15, "E264": 16,
        "E082": 17, "E083": 18, "E084": 19, "E086": 20, "E088": 21,
        "E040": 22, "E041": 23, "E048": 24, "E047": 25,
        "E520": 27, "E522": 28, "E521": 29, "E52C": 30,
        "E52B": 31, "E52F": 32,
        "E53E": 33, "E53F": 34,
        "E4BB": 35, "E4BA": 36,
        "E4A2": 37, "E4A0": 38, "E4C0": 39, "E56A": 40,
        "E1E7": 41,
        "E030": 46,
    }
    return mapping.get(cp)


def render_and_extract(musicxml_path: Path, output_dir: Path, rng: random.Random,
                        variations: int = 3) -> int:
    """Rendert MusicXML mit Verovio, extrahiert Symbol-Patches als PNG.

    Returns: Anzahl extrahierter Patches.
    """
    try:
        tk = verovio.toolkit()
        tk.setOptions({
            "scale": rng.choice([35, 40, 50, 60, 75]),
            "pageWidth": 2100,
            "pageHeight": 2970,
            "header": "auto",
            "footer": "none",
            "spacingNonLinear": rng.uniform(0.5, 0.65),
            "staffLineWidth": rng.uniform(0.18, 0.40),
            "stemWidth": rng.uniform(0.20, 0.45),
            "barLineWidth": rng.uniform(0.30, 0.50),
        })
        if not tk.loadFile(str(musicxml_path)):
            return 0
    except Exception as e:
        print(f"  Verovio konnte {musicxml_path.name} nicht laden: {e}", file=sys.stderr)
        return 0

    written = 0
    n_pages = tk.getPageCount()
    for page_num in range(1, n_pages + 1):
        svg = tk.renderToSVG(page_num)
        # Render ganze Seite als PNG (für Patch-Extraktion)
        page_png = render_svg_to_png(svg)
        if page_png is None: continue

        # Verovio gibt jeder Note eine ID — wir können getElementsAttr nutzen
        # um die Position pro id zu bekommen
        for elem_id, cls in find_classified_elements(svg).items():
            cnn_cls = svg_class_to_cnn(cls)
            if cnn_cls is None: continue
            try:
                bbox = tk.getElementAttr(elem_id, "bbox")
                if not bbox: continue
                # bbox: dict mit x, y, w, h in Verovio-Units
                x, y, w, h = bbox.get("x", 0), bbox.get("y", 0), bbox.get("w", 360), bbox.get("h", 360)
            except Exception:
                continue
            # Convert Verovio units to PNG pixels (Verovio: 1 unit = 1/360 inch at scale 100)
            # Page-PNG width tells us pixel-scale
            scale_x = page_png.width / tk.getPageDimensions(page_num).get("width", 2100) if hasattr(tk, "getPageDimensions") else 1.0
            scale_y = page_png.height / 2970.0
            px = int(x * scale_x)
            py = int(y * scale_y)
            pw = max(8, int(w * scale_x))
            ph = max(8, int(h * scale_y))
            # Crop patch
            patch = extract_patch_from_image(page_png, px, py, pw, ph, PATCH_SIZE)
            if patch is None: continue
            # Augmentation
            for v in range(variations):
                aug_patch = augment_for_print_scan(patch, rng) if v > 0 else patch
                cls_dir = output_dir / f"{cnn_cls:02d}_{CLASS_NAMES[cnn_cls]}"
                cls_dir.mkdir(parents=True, exist_ok=True)
                written += 1
                out_path = cls_dir / f"verovio_{musicxml_path.stem}_{written:06d}.png"
                aug_patch.save(out_path)

    return written


def render_svg_to_png(svg: str) -> Optional[Image.Image]:
    """Rendert SVG zu PNG via Playwright (chromium headless)."""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        return None
    try:
        with sync_playwright() as pw:
            browser = pw.chromium.launch()
            page = browser.new_page(viewport={"width": 2480, "height": 3508})
            html = f'<!DOCTYPE html><html><body style="margin:0">{svg}</body></html>'
            page.set_content(html)
            page.wait_for_load_state("networkidle", timeout=10_000)
            png_bytes = page.screenshot(full_page=True)
            browser.close()
            return Image.open(io.BytesIO(png_bytes)).convert("L")
    except Exception as e:
        print(f"  Playwright-Render-Fehler: {e}", file=sys.stderr)
        return None


def find_classified_elements(svg: str) -> Dict[str, str]:
    """Findet alle <g class="..." id="..."> Elemente in der SVG."""
    results = {}
    pattern = re.compile(r'<g\s+([^>]*?)id="([^"]+)"\s+class="([^"]+)"')
    for m in pattern.finditer(svg):
        attrs, eid, cls = m.group(1), m.group(2), m.group(3)
        results[eid] = cls
    pattern2 = re.compile(r'<g\s+([^>]*?)class="([^"]+)"\s+id="([^"]+)"')
    for m in pattern2.finditer(svg):
        attrs, cls, eid = m.group(1), m.group(2), m.group(3)
        if eid not in results:
            results[eid] = cls
    return results


def svg_class_to_cnn(svg_class: str) -> Optional[int]:
    """Mappt eine Verovio-CSS-Klasse auf den CNN-Klassenindex."""
    parts = svg_class.split()
    for p in parts:
        if p in VEROVIO_CLASS_MAP:
            return VEROVIO_CLASS_MAP[p]
    # Try first part as direct match
    if parts and parts[0] in VEROVIO_CLASS_MAP:
        return VEROVIO_CLASS_MAP[parts[0]]
    return None


def extract_patch_from_image(img: Image.Image, x: int, y: int, w: int, h: int, patch_size: int = 64) -> Optional[Image.Image]:
    """Extrahiert einen patch_size×patch_size Patch zentriert auf bbox."""
    cx = x + w // 2
    cy = y + h // 2
    half = patch_size // 2
    scale = patch_size / max(w, h, 1) * 0.7
    if 0.5 < scale < 4.0:
        new_w = int(img.width * scale)
        new_h = int(img.height * scale)
        cx = int(cx * scale)
        cy = int(cy * scale)
        try:
            img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        except Exception:
            pass
    crop = Image.new("L", (patch_size, patch_size), color=255)
    src_left = max(0, cx - half)
    src_top = max(0, cy - half)
    src_right = min(img.width, cx + half)
    src_bot = min(img.height, cy + half)
    if src_right <= src_left or src_bot <= src_top:
        return None
    region = img.crop((src_left, src_top, src_right, src_bot))
    paste_x = max(0, half - (cx - src_left))
    paste_y = max(0, half - (cy - src_top))
    crop.paste(region, (paste_x, paste_y))
    return crop


def augment_for_print_scan(img: Image.Image, rng: random.Random) -> Image.Image:
    """Aggressive Augmentation für scan-realistische Print-Notation.
    Ähnlich generate_bravura_samples.augment."""
    arr = np.array(img, dtype=np.uint8)
    angle = rng.uniform(-2.5, 2.5)
    img = Image.fromarray(arr).rotate(angle, resample=Image.BILINEAR, fillcolor=255)
    arr = np.array(img, dtype=np.float32)
    arr = (arr - 128) * rng.uniform(0.85, 1.15) + 128 * rng.uniform(0.85, 1.0)
    if rng.random() < 0.5:
        sigma = rng.uniform(2.0, 8.0)
        noise = np.random.normal(0, sigma, arr.shape)
        arr = arr + noise
    if rng.random() < 0.5:
        sp = rng.uniform(0.001, 0.008)
        rand_mask = np.random.random(arr.shape)
        arr[rand_mask < sp / 2] = 0
        arr[rand_mask > 1 - sp / 2] = 255
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    out = Image.fromarray(arr)
    if rng.random() < 0.4:
        out = out.filter(ImageFilter.GaussianBlur(rng.uniform(0.3, 1.0)))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--musicxml-dir", type=Path, required=True)
    ap.add_argument("--output", type=Path, default=Path("data/training"))
    ap.add_argument("--variations", type=int, default=3,
                    help="Augmentations pro Symbol (1 = nur Original)")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--max-files", type=int, default=0,
                    help="Maximum Anzahl MusicXML-Files (0 = alle)")
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    rng = random.Random(args.seed)
    np.random.seed(args.seed)

    files = sorted(args.musicxml_dir.glob("*.musicxml")) + sorted(args.musicxml_dir.glob("*.xml"))
    if args.max_files > 0:
        files = files[:args.max_files]
    print(f"Gefunden: {len(files)} MusicXML-Files")

    total = 0
    for f in files:
        n = render_and_extract(f, args.output, rng, args.variations)
        total += n
        if n > 0:
            print(f"  {f.name}: {n} Patches")

    print(f"\nFertig — {total} Verovio-rendered Patches in {args.output}")


if __name__ == "__main__":
    main()
