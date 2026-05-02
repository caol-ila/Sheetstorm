"""
generate_unet_training_data.py

Erzeugt Trainings-Paare (input, target) für das U-Net Staff-Removal:
  - input/  : Notenbild mit Stafflinien (Original)
  - target/ : Gleiches Bild OHNE Stafflinien (via Python-RLE-Removal als Pseudo-GT)

Variante 1 (Standard): Verovio-rendered Seiten aus MusicXML
  → Rendert demo-score.musicxml bei verschiedenen Scales zu PNG-Seiten
  → Erzeugt typische 800-2500px breite Seiten mit mehreren Staffsystemen

Variante 2 (Fallback): PrIMuS-PNG-Tiling
  → Stapelt mehrere PrIMuS-Einzelzeilen vertikal zu einer zusammengesetzten Seite

Patches: 256x256 mit Overlap-Grid aus jeder Seite ausgeschnitten.

Aufruf:
    python generate_unet_training_data.py \\
        --output-dir data/unet \\
        --musicxml src/Sheetstorm.Web/wwwroot/samples/demo-score.musicxml \\
        --primus-dir data/primus/package_aa \\
        --n-pairs 800
"""
from __future__ import annotations
import argparse
import io
import random
import sys
from pathlib import Path

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    import numpy as np
    from PIL import Image
except ImportError:
    print("FEHLER: pip install numpy Pillow", file=sys.stderr)
    sys.exit(2)

import subprocess
import tempfile
import os

try:
    import verovio as _verovio_module
    HAS_VEROVIO = True
except ImportError:
    HAS_VEROVIO = False
    print("Hinweis: verovio nicht verfügbar — nur PrIMuS-Fallback", file=sys.stderr)

# Inkscape für SVG→PNG-Konvertierung (Windows-Pfad)
_INKSCAPE_CANDIDATES = [
    "inkscape",
    r"C:\Program Files\Inkscape\bin\inkscape.exe",
    r"C:\Program Files (x86)\Inkscape\bin\inkscape.exe",
]
_INKSCAPE_EXE: str | None = None
for _candidate in _INKSCAPE_CANDIDATES:
    try:
        r = subprocess.run([_candidate, "--version"], capture_output=True, timeout=5)
        if r.returncode == 0:
            _INKSCAPE_EXE = _candidate
            break
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

PATCH_SIZE = 256


# ─────────────────────────────────────────────────────────────────────────────
# Python-Port des Rust RLE-Staff-Removal-Algorithmus
# (Cardoso et al. 2009, eigenständige Implementierung)
# ─────────────────────────────────────────────────────────────────────────────

def rle_remove_staff_from_array(bin_img: np.ndarray) -> np.ndarray:
    """Entfernt Stafflinien aus einem binären Array (1=schwarz, 0=weiß).

    Gibt ein neues Binary-Array zurück mit entfernten Stafflinien.
    Ports den Rust-Algorithmus aus omr-staff/src/lib.rs und removal.rs.
    """
    h, w = bin_img.shape

    # 1. RLE-Statistik: häufigste schwarze Run-Länge = Linienstärke,
    #    häufigste weiße Run-Länge = Zeilenabstand.
    black_hist = np.zeros(32, dtype=np.int32)
    white_hist = np.zeros(256, dtype=np.int32)

    step = max(1, w // 200)
    for x in range(0, w, step):
        col = bin_img[:, x]
        run_val = int(col[0])
        run_len = 1
        for y in range(1, h):
            v = int(col[y])
            if v == run_val:
                run_len += 1
            else:
                if run_val == 1 and 1 <= run_len < len(black_hist):
                    black_hist[run_len] += 1
                elif run_val == 0 and 1 <= run_len < len(white_hist):
                    white_hist[run_len] += 1
                run_val = v
                run_len = 1

    line_thickness = max(1, int(np.argmax(black_hist[1:]) + 1))

    lo = max(4, line_thickness * 2)
    hi = min(60, len(white_hist) - 1)
    if lo > hi:
        return bin_img.copy()

    line_spacing = int(np.argmax(white_hist[lo:hi + 1])) + lo + line_thickness

    if line_thickness == 0 or line_spacing == 0:
        return bin_img.copy()

    # 2. Kandidatenzeilen: Zeilen mit hoher Dichte (≥ 40% der Breite)
    row_density = bin_img.sum(axis=1)
    threshold = int(w * 0.4)
    peaks: list[int] = []
    last = -line_thickness
    for y in range(h):
        if row_density[y] >= threshold:
            if y - last >= line_thickness:
                peaks.append(y)
                last = y

    if not peaks:
        # Niedrigeren Threshold versuchen (fragmentierte Linien)
        threshold_low = int(w * 0.25)
        last = -line_thickness
        for y in range(h):
            if row_density[y] >= threshold_low:
                if y - last >= line_thickness:
                    peaks.append(y)
                    last = y

    # 3. Stafflinien-Pixel entfernen (RLE-basiert)
    out = bin_img.copy()
    max_remove_len = line_thickness + 4

    for y0 in peaks:
        for x in range(w):
            if out[y0, x] == 1:
                # Vertikalen Run um (x, y0) bestimmen
                top = y0
                while top > 0 and out[top - 1, x] == 1:
                    top -= 1
                bot = y0
                while bot + 1 < h and out[bot + 1, x] == 1:
                    bot += 1
                run_len = bot - top + 1
                if run_len <= max_remove_len:
                    out[top:bot + 1, x] = 0

    return out


def remove_staff_from_gray(gray: np.ndarray, thresh: int = 200) -> np.ndarray:
    """Entfernt Stafflinien aus einem Graustufen-Array.

    gray: H×W uint8, 0=schwarz, 255=weiß.
    Gibt ein neues Graustufen-Array zurück.
    """
    bin_img = (gray < thresh).astype(np.uint8)
    removed_bin = rle_remove_staff_from_array(bin_img)
    # Zurück in Graustufen: schwarz=0, weiß=255
    result = ((1 - removed_bin) * 255).astype(np.uint8)
    return result


# ─────────────────────────────────────────────────────────────────────────────
# Patch-Schneiden
# ─────────────────────────────────────────────────────────────────────────────

def extract_patches(
    inp_arr: np.ndarray,
    tgt_arr: np.ndarray,
    patch_size: int = PATCH_SIZE,
    stride: int = 192,
) -> list[tuple[np.ndarray, np.ndarray]]:
    """Schneidet überlappende Patches aus zwei gleich großen Arrays.

    Gibt nur Patches, deren Input-Array ≥ 5% schwarze Pixel enthält
    (d.h. Notationsinhalte, kein leeres Weiß).
    """
    h, w = inp_arr.shape
    patches = []
    ys = list(range(0, max(1, h - patch_size + 1), stride))
    xs = list(range(0, max(1, w - patch_size + 1), stride))

    # Sicherstellen dass wir den letzten Block am Rand abdecken
    if ys and ys[-1] + patch_size < h:
        ys.append(h - patch_size)
    if xs and xs[-1] + patch_size < w:
        xs.append(w - patch_size)
    if not ys:
        ys = [0]
    if not xs:
        xs = [0]

    for y in ys:
        for x in xs:
            y2 = min(y + patch_size, h)
            x2 = min(x + patch_size, w)
            ip = inp_arr[y:y2, x:x2]
            tp = tgt_arr[y:y2, x:x2]

            # Padding falls kleiner als patch_size (am Rand)
            if ip.shape != (patch_size, patch_size):
                ip_pad = np.full((patch_size, patch_size), 255, dtype=np.uint8)
                tp_pad = np.full((patch_size, patch_size), 255, dtype=np.uint8)
                ip_pad[:ip.shape[0], :ip.shape[1]] = ip
                tp_pad[:tp.shape[0], :tp.shape[1]] = tp
                ip, tp = ip_pad, tp_pad

            # Nur Patches mit echtem Inhalt
            black_ratio = (ip < 200).sum() / (patch_size * patch_size)
            if black_ratio < 0.02:
                continue
            patches.append((ip, tp))

    return patches


# ─────────────────────────────────────────────────────────────────────────────
# Variante 1: Verovio-basierte Seitenerzeugung (via Inkscape SVG→PNG)
# ─────────────────────────────────────────────────────────────────────────────

def svg_to_png_array(svg_str: str, dpi: int = 96) -> "np.ndarray | None":
    """Konvertiert SVG-String zu Graustufen-Array via Inkscape."""
    if not _INKSCAPE_EXE:
        return None
    pid = os.getpid()
    svg_file = Path(f"_tmp_vrvio_{pid}.svg")
    png_file = Path(f"_tmp_vrvio_{pid}.png")
    try:
        svg_file.write_text(svg_str, encoding="utf-8")
        result = subprocess.run(
            [_INKSCAPE_EXE, str(svg_file),
             "--export-type=png", f"--export-dpi={dpi}",
             f"--export-filename={str(png_file)}"],
            capture_output=True, timeout=30,
        )
        if result.returncode != 0 or not png_file.exists():
            return None
        img = Image.open(str(png_file)).convert("L")
        arr = np.array(img.copy())  # copy before file handle released
        return arr
    except Exception as e:
        print(f"  Inkscape-Fehler: {e}", file=sys.stderr)
        return None
    finally:
        for f in [svg_file, png_file]:
            try:
                f.unlink(missing_ok=True)
            except Exception:
                pass


def render_verovio_pages(musicxml_path: Path) -> list[np.ndarray]:
    """Rendert alle Seiten einer MusicXML-Datei als Graustufen-Arrays.

    Nutzt Verovio für SVG-Rendering + Inkscape für SVG→PNG.
    """
    if not HAS_VEROVIO:
        return []
    if not _INKSCAPE_EXE:
        print("  Inkscape nicht gefunden — überspringe Verovio-Variante", file=sys.stderr)
        return []

    import verovio
    pages = []
    scales = [35, 45, 55, 65, 75, 85]

    for scale in scales:
        try:
            tk = verovio.toolkit()
            tk.setOptions({
                "scale": scale,
                "pageWidth": 2100,
                "pageHeight": 2970,
                "header": "none",
                "footer": "none",
                "staffLineWidth": random.uniform(0.18, 0.40),
            })
            if not tk.loadFile(str(musicxml_path)):
                continue

            n_pages = tk.getPageCount()
            for page_num in range(1, n_pages + 1):
                svg = tk.renderToSVG(page_num)
                arr = svg_to_png_array(svg)
                if arr is None:
                    continue
                if arr.shape[0] >= PATCH_SIZE and arr.shape[1] >= PATCH_SIZE:
                    pages.append(arr)
                    print(f"  Verovio scale={scale} page={page_num}: {arr.shape}")
        except Exception as e:
            print(f"  Verovio Fehler bei scale={scale}: {e}", file=sys.stderr)
            continue

    return pages


# ─────────────────────────────────────────────────────────────────────────────
# Variante 2: PrIMuS-Tiling (Fallback)
# ─────────────────────────────────────────────────────────────────────────────

def load_primus_pngs(primus_dir: Path, max_count: int = 600) -> list[np.ndarray]:
    """Lädt PrIMuS-PNGs aus Unterverzeichnissen."""
    pngs: list[np.ndarray] = []
    dirs = sorted(primus_dir.iterdir()) if primus_dir.exists() else []
    rng = random.Random(42)
    rng.shuffle(dirs)

    for d in dirs:
        if not d.is_dir():
            continue
        png_path = d / f"{d.name}.png"
        if not png_path.exists():
            continue
        try:
            img = Image.open(png_path).convert("L")
            arr = np.array(img)
            # PrIMuS-Bilder können invers sein (schwarz auf weiß = ok, weiß auf schwarz = invertieren)
            if arr.mean() < 128:
                arr = 255 - arr
            pngs.append(arr)
            if len(pngs) >= max_count:
                break
        except Exception as e:
            print(f"  Überspringe {png_path.name}: {e}", file=sys.stderr)

    print(f"PrIMuS: {len(pngs)} PNGs geladen")
    return pngs


def tile_primus_pages(primus_pngs: list[np.ndarray],
                      rows_per_page: int = 4,
                      page_width: int = 1600,
                      gap: int = 20) -> list[np.ndarray]:
    """Stapelt mehrere PrIMuS-Einzelzeilen vertikal zu Seiten.

    Passt jede Zeile auf page_width an (resize mit Aspect-Ratio) und
    fügt einen weißen Abstand zwischen den Zeilen ein.
    """
    pages = []
    rng = random.Random(0)
    idxs = list(range(len(primus_pngs)))
    rng.shuffle(idxs)

    i = 0
    while i + rows_per_page <= len(idxs):
        rows_to_tile = [primus_pngs[idxs[i + r]] for r in range(rows_per_page)]

        # Resize jede Zeile auf page_width
        resized_rows = []
        for row_arr in rows_to_tile:
            h, w = row_arr.shape
            scale = page_width / w
            new_h = max(1, int(h * scale))
            row_img = Image.fromarray(row_arr).resize((page_width, new_h), Image.LANCZOS)
            resized_rows.append(np.array(row_img))

        # Vertikal zusammenkleben mit weißen Lücken
        parts = []
        for r_idx, row in enumerate(resized_rows):
            parts.append(row)
            if r_idx < rows_per_page - 1:
                parts.append(np.full((gap, page_width), 255, dtype=np.uint8))

        page = np.concatenate(parts, axis=0)
        if page.shape[0] >= PATCH_SIZE and page.shape[1] >= PATCH_SIZE:
            pages.append(page)
        i += rows_per_page

    print(f"PrIMuS-Tiling: {len(pages)} Seiten erzeugt")
    return pages


# ─────────────────────────────────────────────────────────────────────────────
# Hauptfunktion
# ─────────────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output-dir", type=Path, default=Path("data/unet"),
                    help="Ausgabeverzeichnis für input/ und target/")
    ap.add_argument("--musicxml", type=Path,
                    default=Path("../../src/Sheetstorm.Web/wwwroot/samples/demo-score.musicxml"),
                    help="Pfad zur MusicXML-Datei (Verovio-Rendering)")
    ap.add_argument("--primus-dir", type=Path, default=Path("data/primus/package_aa"),
                    help="Verzeichnis mit PrIMuS-Unterordnern (PNG-Fallback)")
    ap.add_argument("--n-pairs", type=int, default=800,
                    help="Ziel-Anzahl der Trainingspaare")
    ap.add_argument("--stride", type=int, default=192,
                    help="Schrittweite beim Patch-Schneiden (default 192 = 25%% Overlap)")
    ap.add_argument("--patch-size", type=int, default=256,
                    help="Patch-Größe in Pixeln")
    args = ap.parse_args()

    input_dir = args.output_dir / "input"
    target_dir = args.output_dir / "target"
    input_dir.mkdir(parents=True, exist_ok=True)
    target_dir.mkdir(parents=True, exist_ok=True)

    patch_size = args.patch_size
    pages: list[np.ndarray] = []

    # --- Variante 1: Verovio ---
    if HAS_VEROVIO and args.musicxml.exists():
        print(f"\n=== Verovio-Rendering: {args.musicxml} ===")
        verovio_pages = render_verovio_pages(args.musicxml)
        pages.extend(verovio_pages)
        print(f"Verovio: {len(verovio_pages)} Seiten")

    # --- Variante 2: PrIMuS-Tiling (immer als Ergänzung) ---
    if args.primus_dir.exists():
        print(f"\n=== PrIMuS-Tiling: {args.primus_dir} ===")
        primus_pngs = load_primus_pngs(args.primus_dir, max_count=800)
        if primus_pngs:
            primus_pages = tile_primus_pages(primus_pngs, rows_per_page=4, page_width=1400)
            pages.extend(primus_pages)
            print(f"PrIMuS-Tiling: {len(primus_pages)} Seiten ergänzt")

    if not pages:
        print("FEHLER: Keine Seiten generiert. "
              "Prüfe --musicxml und --primus-dir", file=sys.stderr)
        sys.exit(1)

    print(f"\n=== Patches schneiden ({len(pages)} Seiten) ===")
    all_pairs: list[tuple[np.ndarray, np.ndarray]] = []
    for idx, page_arr in enumerate(pages):
        # Stafflinien entfernen (Python RLE)
        target_arr = remove_staff_from_gray(page_arr)
        pairs = extract_patches(page_arr, target_arr,
                                patch_size=patch_size, stride=args.stride)
        all_pairs.extend(pairs)
        if (idx + 1) % 20 == 0:
            print(f"  Seite {idx + 1}/{len(pages)}: {len(all_pairs)} Paare bisher")

    print(f"\nGesamt: {len(all_pairs)} Paare generiert")

    if len(all_pairs) < 50:
        print("WARNUNG: Sehr wenige Paare! Training könnte schlecht werden.", file=sys.stderr)

    # Mischen und ggf. kürzen
    random.shuffle(all_pairs)
    pairs_to_save = all_pairs[:args.n_pairs] if len(all_pairs) > args.n_pairs else all_pairs

    print(f"Speichere {len(pairs_to_save)} Paare nach {args.output_dir} ...")
    for i, (inp, tgt) in enumerate(pairs_to_save):
        name = f"patch_{i:05d}.png"
        Image.fromarray(inp).save(input_dir / name)
        Image.fromarray(tgt).save(target_dir / name)

    print(f"\nFertig! {len(pairs_to_save)} Paare in:")
    print(f"  input/  → {input_dir}")
    print(f"  target/ → {target_dir}")
    print(f"\nNächster Schritt:")
    print(f"  .venv\\Scripts\\python.exe train_staff_unet.py \\")
    print(f"    --input-dir {args.output_dir / 'input'} \\")
    print(f"    --target-dir {args.output_dir / 'target'} \\")
    print(f"    --output models/staff_unet --epochs 20 --cpu")


if __name__ == "__main__":
    main()
