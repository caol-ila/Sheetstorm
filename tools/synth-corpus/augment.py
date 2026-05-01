"""
augment.py — generiert realistische Scan-Varianten aus sauberen PNGs.

Voraussetzung:
    pip install Pillow numpy

Aufruf:
    python augment.py --input data/pages --output data/augmented --variants 5
"""
from __future__ import annotations
import argparse
import io
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter, ImageOps

# Reproduzierbare Augmentation
DEFAULT_SEED = 42


def jpeg_recompress(img: Image.Image, quality: int = 50) -> Image.Image:
    """JPEG mit niedriger Qualität → PNG: simuliert Scanner/Photocopier-Artefakte."""
    buf = io.BytesIO()
    img.convert("RGB").save(buf, format="JPEG", quality=quality)
    buf.seek(0)
    return Image.open(buf).convert("RGB")


def add_gaussian_noise(img: Image.Image, sigma: float = 6.0) -> Image.Image:
    arr = np.array(img.convert("RGB"), dtype=np.float32)
    noise = np.random.normal(0, sigma, arr.shape)
    arr = np.clip(arr + noise, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGB")


def add_salt_pepper(img: Image.Image, prob: float = 0.005) -> Image.Image:
    arr = np.array(img.convert("RGB"))
    mask = np.random.random(arr.shape[:2])
    arr[mask < prob / 2] = 0
    arr[mask > 1 - prob / 2] = 255
    return Image.fromarray(arr, "RGB")


def slight_skew(img: Image.Image, max_deg: float = 2.0) -> Image.Image:
    angle = random.uniform(-max_deg, max_deg)
    return img.rotate(angle, resample=Image.BICUBIC, fillcolor=(255, 255, 255))


def adjust_contrast(img: Image.Image, factor: float) -> Image.Image:
    return ImageEnhance.Contrast(img).enhance(factor)


def adjust_brightness(img: Image.Image, factor: float) -> Image.Image:
    return ImageEnhance.Brightness(img).enhance(factor)


def slight_blur(img: Image.Image, radius: float = 0.6) -> Image.Image:
    return img.filter(ImageFilter.GaussianBlur(radius))


def folding_marks(img: Image.Image, n: int = 1) -> Image.Image:
    """Vertikale dünne dunkle Linien (alte Notenblätter mit Falz)."""
    if n <= 0:
        return img
    arr = np.array(img.convert("RGB"))
    h, w = arr.shape[:2]
    for _ in range(n):
        x = random.randint(int(w * 0.3), int(w * 0.7))
        thickness = random.randint(1, 2)
        darkness = random.randint(150, 220)
        arr[:, x:x + thickness] = np.minimum(arr[:, x:x + thickness], darkness)
    return Image.fromarray(arr, "RGB")


VARIANTS = [
    # (name, fn)
    ("v1-light",        lambda im: jpeg_recompress(add_gaussian_noise(im, 3), 80)),
    ("v2-photocopy",    lambda im: jpeg_recompress(add_gaussian_noise(adjust_contrast(im, 1.15), 8), 35)),
    ("v3-skewed",       lambda im: slight_skew(jpeg_recompress(add_gaussian_noise(im, 5), 60), 2.5)),
    ("v4-faded",        lambda im: jpeg_recompress(adjust_brightness(adjust_contrast(im, 0.85), 1.08), 70)),
    ("v5-darkold",      lambda im: jpeg_recompress(folding_marks(slight_blur(adjust_brightness(im, 0.75), 0.8), 1), 45)),
    ("v6-saltpepper",   lambda im: add_salt_pepper(jpeg_recompress(im, 55), 0.008)),
    ("v7-printraster",  lambda im: jpeg_recompress(slight_blur(add_gaussian_noise(im, 4), 0.4), 50)),
]


def augment_one(in_path: Path, out_dir: Path, n_variants: int):
    img = Image.open(in_path).convert("RGB")
    selected = VARIANTS[: max(1, n_variants)]
    written = []
    for name, fn in selected:
        out = out_dir / f"{in_path.stem}-{name}.png"
        try:
            res = fn(img)
            res.save(out, format="PNG", optimize=True)
            written.append(out)
        except Exception as e:
            print(f"  ERR {name}: {e}")
    return written


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", type=Path, required=True)
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument("--variants", type=int, default=5)
    ap.add_argument("--seed", type=int, default=DEFAULT_SEED)
    args = ap.parse_args()

    random.seed(args.seed)
    np.random.seed(args.seed)

    args.output.mkdir(parents=True, exist_ok=True)
    pngs = sorted(args.input.rglob("*.png"))
    print(f"Gefundene PNGs: {len(pngs)}")

    total = 0
    for png in pngs:
        out_files = augment_one(png, args.output, args.variants)
        total += len(out_files)
        print(f"[{png.name}] -> {len(out_files)} Varianten")

    print(f"\nFertig — {total} augmentierte Seiten in {args.output}")


if __name__ == "__main__":
    main()
