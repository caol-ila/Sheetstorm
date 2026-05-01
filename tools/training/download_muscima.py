"""
download_muscima.py

Downloadet das MUSCIMA++ v2.0 Datenset (handgeschriebene Notation) und
extrahiert annotierte Symbol-Patches in unsere CNN-Klassen-Struktur.

MUSCIMA++:
  Repository: https://github.com/OMR-Research/muscima-pp
  Lizenz:     Creative Commons Attribution 4.0 International (CC BY 4.0)
  Quelle:     ETH Zürich + Filip Bystricky / OMR-Research
  Stats:      ~140.000 annotierte Symbole, 91 Seiten, 50 Komponisten

Die MUSCIMA++ XML-Annotations definieren Symbole mit class_name (z.B.
'noteheadFull', 'sharp', 'gClef'). Wir mappen diese auf unsere
CNN_CLASS_NAMES und extrahieren je einen 64x64-Grayscale-Patch pro Symbol.

Aufruf:
    python download_muscima.py --output data/training --max-per-class 800
"""
from __future__ import annotations
import argparse
import io
import os
import sys
import urllib.request
import zipfile
from pathlib import Path
from typing import Optional

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    from PIL import Image
except ImportError:
    print("FEHLER: pip install Pillow", file=sys.stderr)
    sys.exit(2)

try:
    from lxml import etree
except ImportError:
    print("FEHLER: pip install lxml", file=sys.stderr)
    sys.exit(2)

# Konsistent mit export_user_annotations.py
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

# MUSCIMA++ class_name → CNN_CLASS_NAMES Index
MUSCIMA_TO_CNN = {
    "noteheadFull": 0,
    "noteheadHalf": 1,
    "noteheadWhole": 2,
    "rest_quarter": 3, "quarterRest": 3,
    "rest_half": 4, "halfRest": 4,
    "rest_whole": 5, "wholeRest": 5,
    "rest_8th": 6, "eighthRest": 6,
    "rest_16th": 7, "sixteenthRest": 7,
    "gClef": 8, "g-clef": 8, "trebleClef": 8,
    "fClef": 9, "f-clef": 9, "bassClef": 9,
    "cClef": 10, "altoClef": 10, "tenorClef": 11,
    "sharp": 12, "accidentalSharp": 12,
    "flat": 13, "accidentalFlat": 13,
    "natural": 14, "accidentalNatural": 14,
    "doubleSharp": 15, "accidentalDoubleSharp": 15,
    "doubleFlat": 16, "accidentalDoubleFlat": 16,
    "timeSig2": 17, "numeral_2": 17,
    "timeSig3": 18, "numeral_3": 18,
    "timeSig4": 19, "numeral_4": 19,
    "timeSig6": 20, "numeral_6": 20,
    "timeSig8": 21, "numeral_8": 21,
    "repeatBarStart": 22, "startRepeat": 22,
    "repeatBarEnd": 23, "endRepeat": 23,
    "coda": 24, "codaSign": 24,
    "segno": 25, "segnoSign": 25,
    "fine": 26,
    "dynamic_p": 27, "dynamicPiano": 27,
    "dynamic_f": 28, "dynamicForte": 28,
    "dynamic_mp": 29, "dynamicMezzopiano": 29,
    "dynamic_mf": 30, "dynamicMezzoforte": 30,
    "dynamic_pp": 31,
    "dynamic_ff": 32,
    "crescendoHairpin": 33, "hairpinCresc": 33,
    "decrescendoHairpin": 34, "hairpinDim": 34,
    "slur": 35,
    "tie": 36,
    "staccatoDot": 37,
    "accent": 38, "accentMark": 38,
    "fermata": 39, "fermataAbove": 39,
    "trill": 40, "trillMark": 40,
    "augmentationDot": 41,
    "tupletNumber": 42, "tuplet_number": 42,
    "beam": 43,
    "stem": 44,
    "ledgerLine": 45,
    "barline": 46, "thinBarline": 46,
}

# Direct download URL (MUSCIMA++ v2.0 mirror, ~150 MB)
MUSCIMA_URL = "https://github.com/OMR-Research/muscima-pp/releases/download/v2.0/MUSCIMA-pp_v2.0.zip"


def download_with_progress(url: str, dest: Path):
    print(f"Lade {url}\n  → {dest}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        print("  (bereits vorhanden, skip)")
        return
    try:
        with urllib.request.urlopen(url) as resp:
            total = int(resp.headers.get("Content-Length", 0))
            with dest.open("wb") as out:
                downloaded = 0
                chunk_size = 1024 * 1024
                while True:
                    chunk = resp.read(chunk_size)
                    if not chunk: break
                    out.write(chunk)
                    downloaded += len(chunk)
                    if total > 0:
                        pct = downloaded * 100 / total
                        print(f"\r  {downloaded // 1048576} / {total // 1048576} MB ({pct:.1f}%)", end="")
                print()
    except Exception as e:
        print(f"FEHLER beim Download: {e}", file=sys.stderr)
        if dest.exists(): dest.unlink()
        sys.exit(2)


def extract_zip(zip_path: Path, target_dir: Path):
    print(f"Entpacke {zip_path}")
    target_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(target_dir)


def find_xml_files(muscima_root: Path):
    """Findet alle Symbol-XML-Files in MUSCIMA++ Distribution."""
    candidates = []
    for root in [muscima_root, muscima_root / "MUSCIMA-pp_v2.0", muscima_root / "v2.0"]:
        if root.exists():
            candidates.extend(root.rglob("CVC-MUSCIMA_W-*_N-*.xml"))
            candidates.extend((root / "data").rglob("*.xml") if (root / "data").exists() else [])
    return [p for p in candidates if p.suffix == ".xml"]


def find_image_for_xml(xml_path: Path) -> Optional[Path]:
    """Sucht das zugehoerige PNG für eine XML-Annotation-Datei."""
    name = xml_path.stem
    for ext in [".png", ".jpg", ".tiff"]:
        for parent_offset in range(5):
            parent = xml_path
            for _ in range(parent_offset + 1):
                parent = parent.parent
            for img in parent.rglob(name + ext):
                return img
    return None


def parse_muscima_xml(xml_path: Path):
    """Parsed MUSCIMA-Symbol-XML, gibt Liste von (class_name, x, y, w, h)."""
    try:
        tree = etree.parse(str(xml_path))
        root = tree.getroot()
    except Exception:
        return []
    results = []
    # MUSCIMA-XML hat <Node> oder <CropObject> Elemente mit class-Attribut
    for elem in root.iter():
        tag = etree.QName(elem.tag).localname.lower() if elem.tag else ""
        if tag in ("node", "cropobject"):
            class_name = elem.findtext("class_name") or elem.findtext("ClassName") or elem.get("class")
            x_text = elem.findtext("Top") or elem.findtext("top") or elem.findtext("y")
            y_text = elem.findtext("Left") or elem.findtext("left") or elem.findtext("x")
            w_text = elem.findtext("Width") or elem.findtext("width") or elem.findtext("w")
            h_text = elem.findtext("Height") or elem.findtext("height") or elem.findtext("h")
            try:
                if class_name and x_text and y_text and w_text and h_text:
                    # In MUSCIMA: Top = y, Left = x (verwirrend benannt)
                    y = int(x_text); x = int(y_text)
                    w = int(w_text); h = int(h_text)
                    results.append((class_name.strip(), x, y, w, h))
            except (ValueError, AttributeError):
                continue
    return results


def extract_patch(img: Image.Image, x: int, y: int, w: int, h: int, patch_size: int = 64) -> Optional[Image.Image]:
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
            img_scaled = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        except Exception:
            img_scaled = img
    else:
        img_scaled = img
    crop = Image.new("L", (patch_size, patch_size), color=255)
    src_left = max(0, cx - half)
    src_top = max(0, cy - half)
    src_right = min(img_scaled.width, cx + half)
    src_bot = min(img_scaled.height, cy + half)
    if src_right <= src_left or src_bot <= src_top:
        return None
    region = img_scaled.crop((src_left, src_top, src_right, src_bot))
    paste_x = max(0, half - (cx - src_left))
    paste_y = max(0, half - (cy - src_top))
    crop.paste(region, (paste_x, paste_y))
    return crop


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", type=Path, default=Path("data/training"),
                    help="Verzeichnis fuer extrahierte Patches")
    ap.add_argument("--cache", type=Path, default=Path("data/muscima"),
                    help="Wo das ZIP entpackt wird")
    ap.add_argument("--max-per-class", type=int, default=800)
    ap.add_argument("--patch-size", type=int, default=64)
    ap.add_argument("--no-download", action="store_true",
                    help="ZIP nicht runterladen, davon ausgehen dass cache schon da ist")
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    args.cache.mkdir(parents=True, exist_ok=True)

    zip_path = args.cache / "MUSCIMA-pp_v2.0.zip"
    if not args.no_download:
        download_with_progress(MUSCIMA_URL, zip_path)
        if zip_path.exists() and not (args.cache / "MUSCIMA-pp_v2.0").exists():
            extract_zip(zip_path, args.cache)

    xmls = find_xml_files(args.cache)
    print(f"Gefundene Annotation-XMLs: {len(xmls)}")
    if not xmls:
        print("WARN: keine XML-Files gefunden — Pfade pruefen", file=sys.stderr)
        sys.exit(1)

    written = {}
    counter = 0
    for xml_path in xmls:
        symbols = parse_muscima_xml(xml_path)
        if not symbols: continue
        img_path = find_image_for_xml(xml_path)
        if not img_path: continue
        try:
            page = Image.open(img_path).convert("L")
        except Exception:
            continue
        for class_name, x, y, w, h in symbols:
            cls = MUSCIMA_TO_CNN.get(class_name)
            if cls is None: continue
            if written.get(cls, 0) >= args.max_per_class: continue
            patch = extract_patch(page, x, y, w, h, args.patch_size)
            if patch is None: continue
            class_name_safe = CLASS_NAMES[cls]
            out_dir = args.output / f"{cls:02d}_{class_name_safe}"
            out_dir.mkdir(parents=True, exist_ok=True)
            counter += 1
            out_path = out_dir / f"muscima_{counter:06d}.png"
            patch.save(out_path)
            written[cls] = written.get(cls, 0) + 1
        if counter % 1000 == 0 and counter > 0:
            print(f"  ...{counter} Samples extrahiert")

    print(f"\nFertig — {counter} MUSCIMA++ Patches")
    for cls, n in sorted(written.items()):
        print(f"  Class {cls:02d} {CLASS_NAMES[cls]:<24}: {n} samples")


if __name__ == "__main__":
    main()
