"""
extract_primus_symbols.py

Extrahiert Symbol-Patches aus PrIMuS-Daten für CNN-Training.

PrIMuS-Format pro Sample:
  package_AA_NNN/
    package_AA_NNN.png       # Notenzeile als grayscale PNG
    package_AA_NNN.semantic  # 'gClef.G2 + keySignature.GM + ...'
    package_AA_NNN.agnostic  # Symbol-Sequence kompakt

Strategie:
  1. PNG laden, Stafflinie detektieren (zentrale 5 Linien finden)
  2. Symbol-Sequence aus .semantic parsen
  3. Pro Symbol: bbox approximieren via x-Position-Schätzung (gleichmäßig
     verteilt entlang der Notenzeile)
  4. Patch um Symbol-Center extrahieren
  5. Klassen-Label aus dem Symbol-Tag (z.B. "noteheadFull" → 0)

Aufruf:
    python extract_primus_symbols.py \\
        --primus-dir data/primus \\
        --output data/training \\
        --max-per-class 1500
"""
from __future__ import annotations
import argparse
import io
import re
import sys
import tarfile
from pathlib import Path
from typing import Dict, List, Optional

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("FEHLER: pip install Pillow numpy", file=sys.stderr)
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

# PrIMuS-Format-Regex: Tokens kommen ohne Whitespace im String, mit
# spezifischen Praefixen und _underscore_ zwischen pitch und duration.
# Format examples:
#   clef-G2  clef-F4  clef-C3  clef-C4
#   keySignature-CM  keySignature-EbM  keySignature-FM
#   timeSignature-3/4  timeSignature-4/4
#   note-G4_quarter  note-Bb5_eighth  note-C6_sixteenth_dotted
#   rest-quarter  rest-eighth  rest-whole
#   barline  tie  slur
#
# Token-Splitter findet Token-Boundaries via Praefix-Regex.
TOKEN_BOUNDARY_RE = re.compile(
    r"(?=clef-|keySignature-|timeSignature-|note-|rest-|barline|tie|slur|multirest-)"
)

SEMANTIC_PATTERNS = [
    # Notes: note-<pitch>_<duration>
    (re.compile(r"^note-[^_]+_quarter(?!_)"), 0),     # Filled (quarter)
    (re.compile(r"^note-[^_]+_eighth"), 0),            # Filled (eighth/sixteenth)
    (re.compile(r"^note-[^_]+_sixteenth"), 0),
    (re.compile(r"^note-[^_]+_thirty_second"), 0),
    (re.compile(r"^note-[^_]+_half"), 1),              # Open (half)
    (re.compile(r"^note-[^_]+_whole"), 2),             # Whole
    (re.compile(r"^note-[^_]+_double_whole"), 2),
    (re.compile(r"^note-[^_]+_quarter_dotted"), 0),    # Filled (dotted-quarter)
    (re.compile(r"^note-"), 0),                        # Default: Filled
    # Rests
    (re.compile(r"^rest-quarter"), 3),
    (re.compile(r"^rest-half"), 4),
    (re.compile(r"^rest-whole"), 5),
    (re.compile(r"^rest-eighth"), 6),
    (re.compile(r"^rest-sixteenth"), 7),
    (re.compile(r"^rest-thirty_second"), 7),
    # Clefs
    (re.compile(r"^clef-G[12]"), 8),     # Treble (G-clef)
    (re.compile(r"^clef-F[345]"), 9),    # Bass (F-clef)
    (re.compile(r"^clef-C[12]"), 10),    # Alto (C-clef on lines 1-2)
    (re.compile(r"^clef-C[345]"), 11),   # Tenor (C-clef on lines 3-5)
    # Bar / Repeat
    (re.compile(r"^barline"), 46),
    (re.compile(r"^multirest-"), 46),
    # Slur/Tie
    (re.compile(r"^slur"), 35),
    (re.compile(r"^tie"), 36),
]


def map_semantic_to_class(token: str) -> Optional[int]:
    for pattern, cls in SEMANTIC_PATTERNS:
        if pattern.match(token):
            return cls
    return None


def parse_semantic_file(path: Path) -> List[str]:
    """Parsed eine PrIMuS .semantic-Datei in eine Liste von Tokens.

    PrIMuS-Format hat KEINE Whitespace zwischen Tokens — Token-Boundaries
    werden via Praefix-Regex (TOKEN_BOUNDARY_RE) gefunden.
    """
    if not path.exists(): return []
    with path.open("r", encoding="utf-8", errors="ignore") as f:
        text = f.read().strip()
    # Wenn separator (' + ' oder whitespace) existiert: nutzen.
    if "+" in text or "\t" in text or "\n" in text:
        tokens = re.split(r"\s*\+\s*|\s+", text)
        return [t.strip() for t in tokens if t.strip()]
    # Sonst: split via prefix-boundary-regex
    tokens = TOKEN_BOUNDARY_RE.split(text)
    return [t.strip() for t in tokens if t.strip()]


def extract_patches_from_sample(
    png_path: Path, semantic_path: Path,
    output_dir: Path, max_per_class: Dict[int, int],
    written_so_far: Dict[int, int],
    patch_size: int = 64,
) -> int:
    """Extrahiert Symbol-Patches aus einem PrIMuS-Sample."""
    tokens = parse_semantic_file(semantic_path)
    if not tokens: return 0
    try:
        img = Image.open(png_path).convert("L")
    except Exception:
        return 0
    W, H = img.size
    if W < 100 or H < 50: return 0

    n_tokens = len(tokens)
    written = 0
    for i, token in enumerate(tokens):
        cls = map_semantic_to_class(token)
        if cls is None: continue
        # Limit pro Klasse erreicht?
        if written_so_far.get(cls, 0) >= max_per_class.get(cls, 1000): continue
        # X-Position: gleichmäßig entlang der Linie
        x_center = int((i + 0.5) * W / n_tokens)
        y_center = H // 2
        # Patch extrahieren
        half = patch_size // 2
        # Estimated bbox für Symbol: ~0.5*staff-height breit (32x32 native für ~64 staff-h)
        crop_w = min(80, W // max(1, n_tokens))
        crop_h = min(H, 80)
        cx = max(crop_w // 2, min(W - crop_w // 2, x_center))
        cy = y_center
        # Crop region in source coords
        src_l = cx - crop_w // 2
        src_t = max(0, cy - crop_h // 2)
        src_r = src_l + crop_w
        src_b = min(H, src_t + crop_h)
        region = img.crop((src_l, src_t, src_r, src_b))
        # Resize to patch_size
        region = region.resize((patch_size, patch_size), Image.LANCZOS)
        # Save
        cls_dir = output_dir / f"{cls:02d}_{CLASS_NAMES[cls]}"
        cls_dir.mkdir(parents=True, exist_ok=True)
        out_path = cls_dir / f"primus_{png_path.stem}_{i:03d}.png"
        region.save(out_path)
        written_so_far[cls] = written_so_far.get(cls, 0) + 1
        written += 1
    return written


def find_primus_samples(primus_dir: Path) -> List[tuple]:
    """Findet alle (png, semantic) Paare im PrIMuS-Korpus."""
    samples = []
    for png in primus_dir.rglob("*.png"):
        sem = png.with_suffix(".semantic")
        if sem.exists():
            samples.append((png, sem))
    return samples


def maybe_extract_tgz(primus_dir: Path):
    """Entpackt .tgz Files falls noch nicht entpackt."""
    for tgz in primus_dir.glob("*.tgz"):
        marker = primus_dir / f".{tgz.stem}.extracted"
        if marker.exists(): continue
        print(f"Entpacke {tgz}...")
        with tarfile.open(tgz, "r:gz") as tar:
            tar.extractall(primus_dir)
        marker.touch()
        print(f"  done")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--primus-dir", type=Path, default=Path("data/primus"))
    ap.add_argument("--output", type=Path, default=Path("data/training"))
    ap.add_argument("--max-per-class", type=int, default=1500)
    ap.add_argument("--patch-size", type=int, default=64)
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    if not args.primus_dir.exists():
        print(f"FEHLER: {args.primus_dir} existiert nicht. Erst download_primus.py laufen lassen.")
        sys.exit(1)

    maybe_extract_tgz(args.primus_dir)
    samples = find_primus_samples(args.primus_dir)
    print(f"Gefunden: {len(samples)} PrIMuS-Samples in {args.primus_dir}")
    if not samples:
        print("Keine Samples gefunden. Sind die .tgz Files extrahiert?")
        sys.exit(1)

    max_per_class = {cls: args.max_per_class for cls in range(len(CLASS_NAMES))}
    written_per_class: Dict[int, int] = {}
    total = 0

    for i, (png, sem) in enumerate(samples):
        n = extract_patches_from_sample(
            png, sem, args.output, max_per_class, written_per_class, args.patch_size)
        total += n
        if (i + 1) % 500 == 0:
            print(f"  ...{i+1}/{len(samples)} samples, {total} patches written")

    print(f"\nFertig — {total} PrIMuS-Patches extrahiert")
    for cls, n in sorted(written_per_class.items()):
        print(f"  Class {cls:02d} {CLASS_NAMES[cls]:<24}: {n} samples")


if __name__ == "__main__":
    main()
