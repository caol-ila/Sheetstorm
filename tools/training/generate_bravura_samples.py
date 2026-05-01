"""
generate_bravura_samples.py

Rendert SMuFL-Glyphen aus der Bravura-Schriftart (assets/Bravura.otf) als
64x64 Grayscale-Patches und legt sie in die Klassen-Verzeichnisstruktur.

Pro Klasse werden N Augmentationen erzeugt (Rotation, Scale, Position-Jitter,
Gaussian-Noise). Das gibt eine saubere Synth-Baseline der ~2000-5000 Samples
pro Klasse als Ergänzung zu User-Annotations und MUSCIMA++.

SMuFL Codepoints: https://www.smufl.org/version/latest/range/

Aufruf:
    python generate_bravura_samples.py \\
        --output data/training \\
        --augmentations 50 \\
        --bravura ../../src/omr-rust/crates/omr-symbols/assets/Bravura.otf
"""
from __future__ import annotations
import argparse
import io
import math
import random
import sys
from pathlib import Path
from typing import Dict, Tuple

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
    import numpy as np
except ImportError as e:
    print(f"FEHLER: {e}\n  pip install Pillow numpy", file=sys.stderr)
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

# SMuFL-Codepoints (https://www.smufl.org/version/latest/range/) für jede Klasse.
# String = einzelner Codepoint, Tuple = mehrere zur Auswahl.
CLASS_SMUFL_GLYPHS: Dict[int, str] = {
    0: "\uE0A4",   # noteheadBlack
    1: "\uE0A3",   # noteheadHalf
    2: "\uE0A2",   # noteheadWhole
    3: "\uE4E5",   # restQuarter
    4: "\uE4E4",   # restHalf
    5: "\uE4E3",   # restWhole
    6: "\uE4E6",   # rest8th
    7: "\uE4E7",   # rest16th
    8: "\uE050",   # gClef
    9: "\uE062",   # fClef
    10: "\uE05C",  # cClef (Alto-default-Position)
    11: "\uE05D",  # cClef alternate (Tenor)
    12: "\uE262",  # accidentalSharp
    13: "\uE260",  # accidentalFlat
    14: "\uE261",  # accidentalNatural
    15: "\uE263",  # accidentalDoubleSharp
    16: "\uE264",  # accidentalDoubleFlat
    17: "\uE082",  # timeSig2
    18: "\uE083",  # timeSig3
    19: "\uE084",  # timeSig4
    20: "\uE086",  # timeSig6
    21: "\uE088",  # timeSig8
    22: "\uE040",  # repeatLeft  (||:)
    23: "\uE041",  # repeatRight (:||)
    24: "\uE048",  # coda
    25: "\uE047",  # segno
    26: "\uE4A0",  # fermataAbove (proxy for "fine")
    27: "\uE520",  # dynamicPiano
    28: "\uE522",  # dynamicForte (mistakenly E523, but Bravura uses E522 for f)
    29: "\uE521",  # dynamicMP
    30: "\uE52C",  # dynamicMF
    31: "\uE52B",  # dynamicPP
    32: "\uE52F",  # dynamicFF
    33: "\uE53E",  # crescendo line (hairpin)
    34: "\uE53F",  # decrescendo line
    35: "\uE4BB",  # slur (proxy)
    36: "\uE4BA",  # tie (proxy)
    37: "\uE4A2",  # articStaccatoAbove
    38: "\uE4A0",  # articAccentAbove (NOTE: collision with fine; same proxy)
    39: "\uE4C0",  # fermataAbove
    40: "\uE56A",  # ornamentTrill
    41: "\uE1E7",  # augmentationDot
    42: "3",       # numeral 3 (tuplet)
    43: "\uE4A2",  # beam (proxy: solid block)
    44: "|",       # stem (proxy: vertical bar)
    45: "_",       # ledger line (proxy: underscore)
    46: "\uE030",  # barlineSingle
    47: "",        # noise: empty/random
}

PATCH = 64


def rasterize_glyph(font_path: Path, codepoint: str, size_px: int = 56) -> Image.Image:
    """Rendert einen SMuFL-Glyph als grayscale-Bild auf weißem Hintergrund."""
    img = Image.new("L", (PATCH, PATCH), color=255)
    if not codepoint:
        return img  # noise-class: empty
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype(str(font_path), size_px)
    except Exception as e:
        print(f"WARN: Bravura-Font konnte nicht geladen werden ({e})", file=sys.stderr)
        return img
    try:
        # Center the glyph
        bbox = draw.textbbox((0, 0), codepoint, font=font)
        gw = bbox[2] - bbox[0]
        gh = bbox[3] - bbox[1]
        cx = (PATCH - gw) // 2 - bbox[0]
        cy = (PATCH - gh) // 2 - bbox[1]
        draw.text((cx, cy), codepoint, fill=0, font=font)
    except Exception:
        pass
    return img


def augment(img: Image.Image, rng: random.Random) -> Image.Image:
    """Aggressive Augmentation für scan-realistische Print-Notation.

    Simuliert echte Scanner-Artefakte:
      - JPEG-Compression (häufig in PDFs)
      - Salt-Pepper-Rauschen (Scanner-Sensor)
      - Slight Blur (Scanner-Optik / Toner-Spread)
      - Brightness/Contrast-Jitter (verschiedene Belichtungen)
      - Rotation ±3° (wackeliger Scan)
      - Skew/Affine (Auto-Deskew-Reste)
      - Toner-Smear (dicke schwarze Pixel)
      - Faded-Ink (helle schwarze Pixel)
      - Edge-Erosion (gefalzte Seiten)
    """
    arr = np.array(img, dtype=np.uint8)

    # Rotation ±3° (deskew lässt typisch Reste von ±1°)
    angle = rng.uniform(-3.0, 3.0)
    img = Image.fromarray(arr).rotate(angle, resample=Image.BILINEAR, fillcolor=255)

    # Scale 0.85..1.15 + Position-Jitter
    scale = rng.uniform(0.85, 1.15)
    new_size = max(20, int(PATCH * scale))
    img = img.resize((new_size, new_size), Image.LANCZOS)
    out = Image.new("L", (PATCH, PATCH), color=255)
    px = (PATCH - new_size) // 2 + rng.randint(-4, 4)
    py = (PATCH - new_size) // 2 + rng.randint(-4, 4)
    out.paste(img, (px, py))

    arr = np.array(out, dtype=np.float32)

    # Brightness/Contrast jitter (verschiedene Belichtungen / faded ink)
    brightness = rng.uniform(0.7, 1.05)
    contrast = rng.uniform(0.8, 1.2)
    arr = (arr - 128) * contrast + 128 * brightness

    # Toner-Smear ODER Faded-Ink (50/50 chance)
    if rng.random() < 0.5:
        # Toner-Smear: alle dunklen Pixel etwas erweitern (slight dilation)
        if rng.random() < 0.4:
            mask = arr < 128
            arr_dilated = arr.copy()
            arr_dilated[1:, :][mask[:-1, :]] = np.minimum(arr_dilated[1:, :][mask[:-1, :]], 80)
            arr_dilated[:-1, :][mask[1:, :]] = np.minimum(arr_dilated[:-1, :][mask[1:, :]], 80)
            arr = arr_dilated
    else:
        # Faded-Ink: dunkle Pixel werden heller (graue, nicht schwarze Pixel)
        if rng.random() < 0.4:
            mask = arr < 128
            fade = rng.uniform(0.4, 0.7)
            arr[mask] = arr[mask] * fade + 255 * (1 - fade)

    arr = np.clip(arr, 0, 255).astype(np.uint8)

    # Salt-Pepper-Noise (Scanner-Sensor-Artefakte)
    if rng.random() < 0.6:
        sp_prob = rng.uniform(0.001, 0.01)
        rand_mask = np.random.random(arr.shape)
        arr[rand_mask < sp_prob / 2] = 0  # pepper
        arr[rand_mask > 1 - sp_prob / 2] = 255  # salt

    # Gaussian noise (allgemeines Sensor-Rauschen)
    if rng.random() < 0.7:
        sigma = rng.uniform(2.0, 10.0)
        noise = np.random.normal(0, sigma, arr.shape)
        arr = np.clip(arr.astype(np.float32) + noise, 0, 255).astype(np.uint8)

    out = Image.fromarray(arr)

    # Blur (Scanner-Optik)
    if rng.random() < 0.5:
        out = out.filter(ImageFilter.GaussianBlur(rng.uniform(0.3, 1.2)))

    # JPEG-Compression (in PDF-Workflow häufig)
    if rng.random() < 0.4:
        from io import BytesIO
        buf = BytesIO()
        out.convert("RGB").save(buf, format="JPEG", quality=rng.randint(40, 80))
        buf.seek(0)
        out = Image.open(buf).convert("L")

    # Edge-Erosion (gefalzte Seiten am Rand)
    if rng.random() < 0.15:
        arr = np.array(out, dtype=np.uint8)
        edge = rng.choice(["top", "bottom", "left", "right"])
        depth = rng.randint(2, 6)
        if edge == "top": arr[:depth, :] = np.minimum(arr[:depth, :], 200)
        elif edge == "bottom": arr[-depth:, :] = np.minimum(arr[-depth:, :], 200)
        elif edge == "left": arr[:, :depth] = np.minimum(arr[:, :depth], 200)
        else: arr[:, -depth:] = np.minimum(arr[:, -depth:], 200)
        out = Image.fromarray(arr)

    return out


def generate_noise_sample(rng: random.Random) -> Image.Image:
    """Erzeugt ein 'Noise'-Sample: leeres oder rauschendes Bild."""
    img = Image.new("L", (PATCH, PATCH), color=255)
    if rng.random() < 0.5:
        # Random fragments
        arr = np.array(img, dtype=np.float32)
        n_fragments = rng.randint(1, 8)
        for _ in range(n_fragments):
            x = rng.randint(0, PATCH - 1)
            y = rng.randint(0, PATCH - 1)
            r = rng.randint(1, 5)
            arr[max(0, y - r):y + r, max(0, x - r):x + r] = rng.randint(0, 200)
        img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    # Add general noise
    arr = np.array(img, dtype=np.float32)
    arr += np.random.normal(0, 15, arr.shape)
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    return Image.fromarray(arr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", type=Path, default=Path("data/training"))
    ap.add_argument("--augmentations", type=int, default=50,
                    help="Augmentation-Varianten pro Klasse (1 base + N-1 augs)")
    ap.add_argument("--bravura", type=Path,
                    default=Path("../../src/omr-rust/crates/omr-symbols/assets/Bravura.otf"))
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--font-size", type=int, default=56)
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    if not args.bravura.exists():
        print(f"FEHLER: Bravura.otf nicht gefunden: {args.bravura}", file=sys.stderr)
        sys.exit(2)

    rng = random.Random(args.seed)
    np.random.seed(args.seed)

    counter = 0
    for cid in range(len(CLASS_NAMES)):
        cls_name = CLASS_NAMES[cid]
        cls_dir = args.output / f"{cid:02d}_{cls_name}"
        cls_dir.mkdir(parents=True, exist_ok=True)
        glyph = CLASS_SMUFL_GLYPHS.get(cid, "")
        for k in range(args.augmentations):
            counter += 1
            if cid == 47 or not glyph:
                # Noise-class: explicit noise generator
                img = generate_noise_sample(rng)
            else:
                base = rasterize_glyph(args.bravura, glyph, args.font_size)
                img = augment(base, rng) if k > 0 else base
            out_path = cls_dir / f"bravura_{counter:06d}.png"
            img.save(out_path)
        print(f"  Class {cid:02d} {cls_name:<22}: {args.augmentations} samples")

    print(f"\nFertig — {counter} Bravura-Synth-Samples in {args.output}")


if __name__ == "__main__":
    main()
