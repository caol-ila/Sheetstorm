"""
generate_synthetic_patterns.py

Comprehensive synthetic corpus generator for Sheetstorm OMR training.
Generates Level 1 (single symbols), Level 2 (logical groups), and
Level 3 (phrase snippets) as 64×64 grayscale patches.

Architecture:
  - Single symbols  : Bravura SMuFL font rendering via PIL (fast, no browser)
  - Logical groups  : MusicXML → Verovio SVG → Playwright PNG
  - Phrase snippets : MusicXML → Verovio SVG → Playwright PNG
  - All levels      : scan-realistic augmentation (re-uses augment_for_print_scan)

Usage:
    python generate_synthetic_patterns.py \\
        --output data/synthetic_corpus_v1 \\
        --n-per-class 800 \\
        --n-augmentations 5

Public API (importable):
    generate_single_symbols(out_dir, n_per_class, bravura_path, rng)
    generate_logical_groups(out_dir, n_per_group, bravura_path, rng)
    generate_phrase_snippets(out_dir, n_per_snippet, bravura_path, rng)
    generate_manifest(out_dir)
"""
from __future__ import annotations

import argparse
import io
import json
import math
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

if sys.platform == "win32" and __name__ == "__main__":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
    import numpy as np
except ImportError as e:
    print(f"FEHLER: {e}\n  pip install Pillow numpy", file=sys.stderr)
    sys.exit(2)

PATCH = 64
DEFAULT_BRAVURA = Path("../../src/omr-rust/crates/omr-symbols/assets/Bravura.otf")

# ── SMuFL codepoints (Bravura.otf) ──────────────────────────────────────────
# Ref: https://www.smufl.org/version/latest/range/
SMUFL: Dict[str, str] = {
    # Noteheads
    "notehead_filled":    "\uE0A4",
    "notehead_half":      "\uE0A3",
    "notehead_whole":     "\uE0A2",
    "notehead_x":         "\uE0B4",
    "notehead_diamond":   "\uE0D9",
    # Rests
    "rest_whole":         "\uE4E3",
    "rest_half":          "\uE4E4",
    "rest_quarter":       "\uE4E5",
    "rest_8th":           "\uE4E6",
    "rest_16th":          "\uE4E7",
    "rest_32nd":          "\uE4E8",
    # Clefs
    "clef_treble":        "\uE050",
    "clef_bass":          "\uE062",
    "clef_alto":          "\uE05C",
    "clef_tenor":         "\uE05D",
    "clef_percussion":    "\uE069",
    "clef_tab":           "\uE06D",
    # Accidentals
    "accid_sharp":        "\uE262",
    "accid_flat":         "\uE260",
    "accid_natural":      "\uE261",
    "accid_double_sharp": "\uE263",
    "accid_double_flat":  "\uE264",
    # Time-signature digits / symbols
    "time_0": "\uE080", "time_1": "\uE081", "time_2": "\uE082",
    "time_3": "\uE083", "time_4": "\uE084", "time_5": "\uE085",
    "time_6": "\uE086", "time_7": "\uE087", "time_8": "\uE088",
    "time_9": "\uE089", "time_12": "\uE08C",
    "time_common": "\uE08A", "time_cut": "\uE08B",
    # Augmentation dot
    "aug_dot": "\uE1E7",
    # Barlines
    "barline_single": "\uE030",
    "barline_double": "\uE031",
    "barline_final":  "\uE032",
    "repeat_start":   "\uE040",
    "repeat_end":     "\uE041",
    "repeat_both":    "\uE042",
    # Articulations
    "artic_staccato": "\uE4A2",
    "artic_accent":   "\uE4A0",
    "artic_tenuto":   "\uE4A4",
    "artic_marcato":  "\uE4AC",
    "fermata":        "\uE4C0",
    "breath_mark":    "\uE4CE",
    # Dynamics
    "dyn_ppp": "\uE52A", "dyn_pp":  "\uE52B", "dyn_p":   "\uE520",
    "dyn_mp":  "\uE52C", "dyn_mf":  "\uE52D", "dyn_f":   "\uE522",
    "dyn_ff":  "\uE52F", "dyn_fff": "\uE530", "dyn_sf":  "\uE53A",
    "dyn_sfz": "\uE53C", "dyn_fp":  "\uE52E",
    # Jump / navigation marks
    "coda":  "\uE048",
    "segno": "\uE047",
    # Ornaments
    "trill":   "\uE56A",
    "mordent": "\uE56B",
    # Stem (proxy: vertical bar drawn via PIL)
    # Volta (drawn via PIL)
}


# ── Augmentation (scan-realistic) ────────────────────────────────────────────

def augment_for_print_scan(img: Image.Image, rng: random.Random) -> Image.Image:
    """Scan-realistic augmentation: noise, JPEG, rotation, skew, toner artefacts.

    Mirrors the implementation in generate_verovio_samples.py but with the
    extended parameter ranges requested for synthetic_patterns.
    """
    arr = np.array(img, dtype=np.uint8)

    # Rotation ±2°
    angle = rng.uniform(-2.0, 2.0)
    img = Image.fromarray(arr).rotate(angle, resample=Image.BILINEAR, fillcolor=255)

    # Scale 0.85..1.15 + position jitter
    scale = rng.uniform(0.85, 1.15)
    new_size = max(20, int(PATCH * scale))
    img = img.resize((new_size, new_size), Image.LANCZOS)
    out = Image.new("L", (PATCH, PATCH), color=255)
    px = (PATCH - new_size) // 2 + rng.randint(-3, 3)
    py = (PATCH - new_size) // 2 + rng.randint(-3, 3)
    out.paste(img, (px, py))

    arr = np.array(out, dtype=np.float32)

    # Brightness / contrast jitter  (faded-ink effect)
    brightness = rng.uniform(0.75, 1.05)
    contrast = rng.uniform(0.85, 1.15)
    arr = (arr - 128) * contrast + 128 * brightness

    # Toner-smear (dilate dark pixels)
    if rng.random() < 0.35:
        mask = arr < 128
        tmp = arr.copy()
        tmp[1:, :][mask[:-1, :]] = np.minimum(tmp[1:, :][mask[:-1, :]], 80)
        tmp[:-1, :][mask[1:, :]] = np.minimum(tmp[:-1, :][mask[1:, :]], 80)
        arr = tmp

    # Faded-ink (lighten dark pixels)
    if rng.random() < 0.30:
        mask = arr < 128
        fade = rng.uniform(0.35, 0.65)
        arr[mask] = arr[mask] * fade + 255 * (1 - fade)

    arr = np.clip(arr, 0, 255).astype(np.uint8)

    # Salt-pepper noise (0.5 – 2 %)
    if rng.random() < 0.60:
        sp = rng.uniform(0.005, 0.020)
        mask = np.random.random(arr.shape)
        arr[mask < sp / 2] = 0
        arr[mask > 1 - sp / 2] = 255

    # Gaussian noise σ = 1..3
    if rng.random() < 0.70:
        sigma = rng.uniform(1.0, 3.0)
        arr = np.clip(arr.astype(np.float32) + np.random.normal(0, sigma, arr.shape),
                      0, 255).astype(np.uint8)

    out = Image.fromarray(arr)

    # Blur (optics)
    if rng.random() < 0.40:
        out = out.filter(ImageFilter.GaussianBlur(rng.uniform(0.3, 1.0)))

    # JPEG compression (quality 60-90)
    if rng.random() < 0.35:
        buf = io.BytesIO()
        out.convert("RGB").save(buf, format="JPEG", quality=rng.randint(60, 90))
        buf.seek(0)
        out = Image.open(buf).convert("L")

    # Skew ±1° (simulate auto-deskew residual)
    if rng.random() < 0.25:
        skew = rng.uniform(-1.0, 1.0)
        out = out.rotate(skew, resample=Image.BILINEAR, fillcolor=255)

    return out


# ── Bravura glyph rendering ──────────────────────────────────────────────────

def _load_bravura(path: Path, size_px: int) -> Optional[ImageFont.FreeTypeFont]:
    if not path.exists():
        return None
    try:
        return ImageFont.truetype(str(path), size_px)
    except Exception:
        return None


def rasterize_glyph(font: Optional[ImageFont.FreeTypeFont],
                    codepoint: str) -> Image.Image:
    """Render a single SMuFL glyph centered in a PATCH×PATCH grayscale image."""
    img = Image.new("L", (PATCH, PATCH), color=255)
    if not codepoint or font is None:
        return img
    draw = ImageDraw.Draw(img)
    try:
        bbox = draw.textbbox((0, 0), codepoint, font=font)
        gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
        cx = (PATCH - gw) // 2 - bbox[0]
        cy = (PATCH - gh) // 2 - bbox[1]
        draw.text((cx, cy), codepoint, fill=0, font=font)
    except Exception:
        pass
    return img


def rasterize_text(text: str, font_size: int = 18) -> Image.Image:
    """Render plain text centered in a PATCH×PATCH grayscale image."""
    img = Image.new("L", (PATCH, PATCH), color=255)
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default(size=font_size)
        bbox = draw.textbbox((0, 0), text, font=font)
        gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
        cx = (PATCH - gw) // 2 - bbox[0]
        cy = (PATCH - gh) // 2 - bbox[1]
        draw.text((cx, cy), text, fill=0, font=font)
    except Exception:
        pass
    return img


def rasterize_two_glyphs_stacked(font: Optional[ImageFont.FreeTypeFont],
                                  top: str, bottom: str) -> Image.Image:
    """Render two SMuFL glyphs stacked vertically (for time signatures)."""
    img = Image.new("L", (PATCH, PATCH), color=255)
    draw = ImageDraw.Draw(img)
    if font is None:
        return img
    half = PATCH // 2
    for glyph, offset_y in [(top, 0), (bottom, half)]:
        try:
            bbox = draw.textbbox((0, 0), glyph, font=font)
            gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
            cx = (PATCH - gw) // 2 - bbox[0]
            cy = offset_y + (half - gh) // 2 - bbox[1]
            draw.text((cx, cy), glyph, fill=0, font=font)
        except Exception:
            pass
    return img


def rasterize_n_glyphs_row(font: Optional[ImageFont.FreeTypeFont],
                            glyph: str, n: int) -> Image.Image:
    """Render N copies of a glyph in a horizontal row (for key signatures)."""
    img = Image.new("L", (PATCH, PATCH), color=255)
    if font is None or n == 0:
        return img
    draw = ImageDraw.Draw(img)
    try:
        bbox = draw.textbbox((0, 0), glyph, font=font)
        gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
        spacing = min(gw + 2, PATCH // max(n, 1))
        total_w = spacing * n - (spacing - gw)
        start_x = (PATCH - total_w) // 2 - bbox[0]
        cy = (PATCH - gh) // 2 - bbox[1]
        for i in range(n):
            draw.text((start_x + i * spacing, cy), glyph, fill=0, font=font)
    except Exception:
        pass
    return img


def rasterize_stem(direction: str) -> Image.Image:
    """Draw a stem (vertical line) pointing up or down."""
    img = Image.new("L", (PATCH, PATCH), color=255)
    draw = ImageDraw.Draw(img)
    cx = PATCH // 2
    if direction == "up":
        draw.line([(cx, PATCH // 2), (cx, 8)], fill=0, width=2)
        # Notehead at bottom of stem
        draw.ellipse([cx - 6, PATCH // 2 - 5, cx + 6, PATCH // 2 + 5], fill=0)
    elif direction == "down":
        draw.line([(cx, PATCH // 2), (cx, PATCH - 8)], fill=0, width=2)
        draw.ellipse([cx - 6, PATCH // 2 - 5, cx + 6, PATCH // 2 + 5], fill=0)
    else:  # tied: two noteheads with a tie arc
        nx1, nx2 = PATCH // 3, 2 * PATCH // 3
        ny = PATCH // 2
        for nx in [nx1, nx2]:
            draw.ellipse([nx - 5, ny - 4, nx + 5, ny + 4], fill=0)
        # Tie arc
        draw.arc([nx1 + 3, ny - 12, nx2 - 3, ny + 4], start=0, end=180, fill=0, width=2)
    return img


def rasterize_volta(label: str) -> Image.Image:
    """Draw a volta bracket with label text."""
    img = Image.new("L", (PATCH, PATCH), color=255)
    draw = ImageDraw.Draw(img)
    # Bracket: top-left corner + horizontal line + vertical left side
    y = PATCH // 3
    draw.line([(6, y), (PATCH - 6, y)], fill=0, width=2)
    draw.line([(6, y), (6, y + 20)], fill=0, width=2)
    # Label
    try:
        font = ImageFont.load_default(size=14)
        draw.text((10, y + 3), label, fill=0, font=font)
    except Exception:
        pass
    return img


def autocrop_to_content(img: Image.Image, margin: int = 4) -> Image.Image:
    """Crop away white margins, then center-pad back to PATCH×PATCH."""
    arr = np.array(img)
    dark = arr < 200
    rows = np.any(dark, axis=1)
    cols = np.any(dark, axis=0)
    if not rows.any():
        return img
    rmin, rmax = int(np.where(rows)[0].min()), int(np.where(rows)[0].max())
    cmin, cmax = int(np.where(cols)[0].min()), int(np.where(cols)[0].max())
    rmin = max(0, rmin - margin)
    cmin = max(0, cmin - margin)
    rmax = min(arr.shape[0] - 1, rmax + margin)
    cmax = min(arr.shape[1] - 1, cmax + margin)
    cropped = img.crop((cmin, rmin, cmax + 1, rmax + 1))
    # Scale down to fit PATCH × PATCH while preserving aspect ratio
    w, h = cropped.size
    if w > PATCH or h > PATCH:
        ratio = min(PATCH / w, PATCH / h)
        cropped = cropped.resize(
            (max(1, int(w * ratio)), max(1, int(h * ratio))), Image.LANCZOS
        )
    # Center on white canvas
    out = Image.new("L", (PATCH, PATCH), color=255)
    cw, ch = cropped.size
    out.paste(cropped, ((PATCH - cw) // 2, (PATCH - ch) // 2))
    return out


# ── Verovio / Playwright rendering ───────────────────────────────────────────

_MUSICXML_HEADER = """\
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
  "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Music</part-name></score-part>
  </part-list>
  <part id="P1">
"""
_MUSICXML_FOOTER = "  </part>\n</score-partwise>\n"


def _measure(content: str, fifths: int = 0, beats: int = 4,
             beat_type: int = 4, clef_sign: str = "G",
             clef_line: int = 2, divisions: int = 4) -> str:
    return (
        f'    <measure number="1">\n'
        f'      <attributes>\n'
        f'        <divisions>{divisions}</divisions>\n'
        f'        <key><fifths>{fifths}</fifths></key>\n'
        f'        <time><beats>{beats}</beats>'
        f'<beat-type>{beat_type}</beat-type></time>\n'
        f'        <clef><sign>{clef_sign}</sign>'
        f'<line>{clef_line}</line></clef>\n'
        f'      </attributes>\n'
        f'{content}'
        f'    </measure>\n'
    )


def _note(step: str, octave: int, duration: int, ntype: str,
          beam_pos: Optional[str] = None,
          chord: bool = False,
          tie_start: bool = False, tie_stop: bool = False,
          tuplet_start: bool = False, tuplet_stop: bool = False,
          grace: bool = False,
          notations_extra: str = "") -> str:
    lines = ["      <note>"]
    if grace:
        lines.append("        <grace/>")
    if chord:
        lines.append("        <chord/>")
    lines += [
        f"        <pitch><step>{step}</step>"
        f"<octave>{octave}</octave></pitch>",
    ]
    if not grace:
        lines.append(f"        <duration>{duration}</duration>")
    lines.append(f"        <type>{ntype}</type>")
    if tie_start:
        lines.append('        <tie type="start"/>')
    if tie_stop:
        lines.append('        <tie type="stop"/>')
    if beam_pos:
        lines.append(f'        <beam number="1">{beam_pos}</beam>')
    # Notations block
    notations = ""
    if tie_start:
        notations += '        <tied type="start"/>\n'
    if tie_stop:
        notations += '        <tied type="stop"/>\n'
    if tuplet_start:
        notations += '        <tuplet type="start" bracket="yes"/>\n'
    if tuplet_stop:
        notations += '        <tuplet type="stop"/>\n'
    if notations_extra:
        notations += notations_extra
    if notations:
        lines.append("        <notations>")
        lines.append(notations.rstrip())
        lines.append("        </notations>")
    lines.append("      </note>")
    return "\n".join(lines) + "\n"


def _rest_note(duration: int, ntype: str) -> str:
    dot = ""
    base_type = ntype
    if ntype == "dotted-half":
        base_type = "half"
        dot = "<dot/>"
    elif ntype == "dotted-quarter":
        base_type = "quarter"
        dot = "<dot/>"
    return (
        f"      <note><rest/><duration>{duration}</duration>"
        f"<type>{base_type}</type>{dot}</note>\n"
    )


def build_musicxml(*measures_content: str,
                   fifths: int = 0, beats: int = 4, beat_type: int = 4,
                   clef_sign: str = "G", clef_line: int = 2,
                   divisions: int = 4) -> str:
    measures = "".join(
        f'    <measure number="{i+1}">\n'
        + (
            '      <attributes>\n'
            f'        <divisions>{divisions}</divisions>\n'
            f'        <key><fifths>{fifths}</fifths></key>\n'
            f'        <time><beats>{beats}</beats>'
            f'<beat-type>{beat_type}</beat-type></time>\n'
            f'        <clef><sign>{clef_sign}</sign>'
            f'<line>{clef_line}</line></clef>\n'
            '      </attributes>\n'
            if i == 0 else ""
        )
        + content
        + '    </measure>\n'
        for i, content in enumerate(measures_content)
    )
    return _MUSICXML_HEADER + measures + _MUSICXML_FOOTER


class VerovioRenderer:
    """Renders MusicXML → 64×64 grayscale patches via Verovio + Playwright.

    Use as a context manager to keep the browser open across many renders:
        with VerovioRenderer() as r:
            patch = r.render(musicxml_str)
    """

    _OPTS = {
        "scale": 80,
        "adjustPageHeight": 1,
        "adjustPageWidth": 1,
        "header": "none",
        "footer": "none",
        "pageMarginBottom": 20,
        "pageMarginTop": 20,
        "pageMarginLeft": 20,
        "pageMarginRight": 20,
    }

    def __init__(self) -> None:
        self._pw = None
        self._browser = None
        self._page = None
        self._available = False

    def __enter__(self) -> "VerovioRenderer":
        try:
            import verovio
            from playwright.sync_api import sync_playwright
            self._verovio = verovio
            self._pw_ctx = sync_playwright()
            self._pw = self._pw_ctx.__enter__()
            self._browser = self._pw.chromium.launch()
            self._page = self._browser.new_page(
                viewport={"width": 1600, "height": 1200}
            )
            self._available = True
        except Exception as e:
            print(f"  VerovioRenderer unavailable: {e}", file=sys.stderr)
        return self

    def __exit__(self, *args) -> None:
        if self._browser:
            try:
                self._browser.close()
            except Exception:
                pass
        if self._pw:
            try:
                self._pw_ctx.__exit__(*args)
            except Exception:
                pass

    def render(self, musicxml: str, extra_opts: Optional[dict] = None) -> Optional[Image.Image]:
        """Render MusicXML to a 64×64 grayscale Image, or None on failure."""
        if not self._available:
            return None
        try:
            tk = self._verovio.toolkit()
            opts = dict(self._OPTS)
            if extra_opts:
                opts.update(extra_opts)
            tk.setOptions(opts)
            if not tk.loadData(musicxml):
                return None
            svg = tk.renderToSVG(1)
            html = (
                '<!DOCTYPE html><html>'
                '<body style="margin:0;padding:0;background:white">'
                f'{svg}'
                '</body></html>'
            )
            self._page.set_content(html, wait_until="commit")
            png_bytes = self._page.screenshot()
            img = Image.open(io.BytesIO(png_bytes)).convert("L")
            return autocrop_to_content(img)
        except Exception as e:
            print(f"  VerovioRenderer.render failed: {e}", file=sys.stderr)
            return None


# ── Pitch helpers ─────────────────────────────────────────────────────────────

_PITCHES = ["C", "D", "E", "F", "G", "A", "B"]


def _rand_pitch(rng: random.Random, octave_range: Tuple[int, int] = (4, 5)
                ) -> Tuple[str, int]:
    return rng.choice(_PITCHES), rng.randint(*octave_range)


# ── Level 1: Single Symbols ──────────────────────────────────────────────────

def _make_single_defs(bravura: Optional[ImageFont.FreeTypeFont],
                      bravura_sm: Optional[ImageFont.FreeTypeFont]
                      ) -> Dict[str, Image.Image]:
    """Return {relative_class_path: base_image} for all single-symbol classes."""
    defs: Dict[str, Image.Image] = {}
    S = SMUFL

    # ── Noteheads ──────────────────────────────────────────────────────────
    defs["noteheads/filled_quarter"] = rasterize_glyph(bravura, S["notehead_filled"])
    defs["noteheads/half"]           = rasterize_glyph(bravura, S["notehead_half"])
    defs["noteheads/whole"]          = rasterize_glyph(bravura, S["notehead_whole"])
    defs["noteheads/x"]              = rasterize_glyph(bravura, S["notehead_x"])
    defs["noteheads/diamond"]        = rasterize_glyph(bravura, S["notehead_diamond"])

    # ── Stems ──────────────────────────────────────────────────────────────
    defs["stems/stem_up"]   = rasterize_stem("up")
    defs["stems/stem_down"] = rasterize_stem("down")
    defs["stems/stem_tied"] = rasterize_stem("tied")

    # ── Rests ──────────────────────────────────────────────────────────────
    defs["rests/whole"]    = rasterize_glyph(bravura, S["rest_whole"])
    defs["rests/half"]     = rasterize_glyph(bravura, S["rest_half"])
    defs["rests/quarter"]  = rasterize_glyph(bravura, S["rest_quarter"])
    defs["rests/eighth"]   = rasterize_glyph(bravura, S["rest_8th"])
    defs["rests/sixteenth"] = rasterize_glyph(bravura, S["rest_16th"])
    defs["rests/thirtysecond"] = rasterize_glyph(bravura, S["rest_32nd"])

    # ── Clefs ──────────────────────────────────────────────────────────────
    defs["clefs/treble"]     = rasterize_glyph(bravura, S["clef_treble"])
    defs["clefs/bass"]       = rasterize_glyph(bravura, S["clef_bass"])
    defs["clefs/alto"]       = rasterize_glyph(bravura, S["clef_alto"])
    defs["clefs/tenor"]      = rasterize_glyph(bravura, S["clef_tenor"])
    defs["clefs/percussion"] = rasterize_glyph(bravura, S["clef_percussion"])
    defs["clefs/tab"]        = rasterize_glyph(bravura, S["clef_tab"])

    # ── Accidentals ────────────────────────────────────────────────────────
    defs["accidentals/sharp"]       = rasterize_glyph(bravura, S["accid_sharp"])
    defs["accidentals/flat"]        = rasterize_glyph(bravura, S["accid_flat"])
    defs["accidentals/natural"]     = rasterize_glyph(bravura, S["accid_natural"])
    defs["accidentals/double_sharp"] = rasterize_glyph(bravura, S["accid_double_sharp"])
    defs["accidentals/double_flat"] = rasterize_glyph(bravura, S["accid_double_flat"])

    # ── Time Signatures ────────────────────────────────────────────────────
    def ts(n, d): return rasterize_two_glyphs_stacked(
        bravura_sm, S[f"time_{n}"], S[f"time_{d}"])

    defs["time_sigs/2_4"]   = ts(2, 4)
    defs["time_sigs/3_4"]   = ts(3, 4)
    defs["time_sigs/4_4"]   = ts(4, 4)
    defs["time_sigs/6_8"]   = ts(6, 8)
    defs["time_sigs/9_8"]   = ts(9, 8)
    # 12/8: render "12" top by using time_12 glyph if available else compose 1+2
    defs["time_sigs/12_8"]  = rasterize_two_glyphs_stacked(
        bravura_sm, S.get("time_12", S["time_1"] + S["time_2"]), S["time_8"])
    defs["time_sigs/2_2"]   = ts(2, 2)
    defs["time_sigs/3_2"]   = ts(3, 2)
    defs["time_sigs/common"]      = rasterize_glyph(bravura, S["time_common"])
    defs["time_sigs/cut"]         = rasterize_glyph(bravura, S["time_cut"])
    defs["time_sigs/alla_breve"]  = rasterize_glyph(bravura, S["time_cut"])  # same glyph

    # ── Key Signatures (simplified: N sharps or flats in a row) ───────────
    # C major (0) rendered as empty / natural symbol
    defs["key_sigs/c_major"] = rasterize_glyph(bravura_sm, S["accid_natural"])
    for n in range(1, 8):
        defs[f"key_sigs/p{n}_sharps"] = rasterize_n_glyphs_row(
            bravura_sm, S["accid_sharp"], n)
    for n in range(1, 8):
        defs[f"key_sigs/m{n}_flats"] = rasterize_n_glyphs_row(
            bravura_sm, S["accid_flat"], n)

    # ── Augmentation Dots ──────────────────────────────────────────────────
    defs["aug_dots/one_dot"] = rasterize_glyph(bravura, S["aug_dot"])
    # Two dots: render the dot glyph twice side by side
    img2 = Image.new("L", (PATCH, PATCH), color=255)
    d1 = rasterize_glyph(bravura, S["aug_dot"])
    img2.paste(d1.crop((PATCH // 2 - 10, PATCH // 2 - 10, PATCH // 2 + 10, PATCH // 2 + 10)),
               (PATCH // 2 - 14, PATCH // 2 - 10))
    img2.paste(d1.crop((PATCH // 2 - 10, PATCH // 2 - 10, PATCH // 2 + 10, PATCH // 2 + 10)),
               (PATCH // 2 + 2, PATCH // 2 - 10))
    defs["aug_dots/two_dots"] = img2

    # ── Bar Lines ──────────────────────────────────────────────────────────
    defs["barlines/single"]       = rasterize_glyph(bravura, S["barline_single"])
    defs["barlines/double"]       = rasterize_glyph(bravura, S["barline_double"])
    defs["barlines/final"]        = rasterize_glyph(bravura, S["barline_final"])
    defs["barlines/repeat_start"] = rasterize_glyph(bravura, S["repeat_start"])
    defs["barlines/repeat_end"]   = rasterize_glyph(bravura, S["repeat_end"])
    defs["barlines/repeat_both"]  = rasterize_glyph(bravura, S["repeat_both"])

    # ── Volta Brackets ─────────────────────────────────────────────────────
    defs["voltas/prima"]     = rasterize_volta("1.")
    defs["voltas/seconda"]   = rasterize_volta("2.")
    defs["voltas/terza"]     = rasterize_volta("3.")
    defs["voltas/prima_sec"] = rasterize_volta("1.-2.")

    # ── Articulations ──────────────────────────────────────────────────────
    defs["articulations/staccato"]   = rasterize_glyph(bravura, S["artic_staccato"])
    defs["articulations/accent"]     = rasterize_glyph(bravura, S["artic_accent"])
    defs["articulations/tenuto"]     = rasterize_glyph(bravura, S["artic_tenuto"])
    defs["articulations/marcato"]    = rasterize_glyph(bravura, S["artic_marcato"])
    defs["articulations/fermata"]    = rasterize_glyph(bravura, S["fermata"])
    defs["articulations/breath_mark"] = rasterize_glyph(bravura, S["breath_mark"])

    # ── Dynamics ───────────────────────────────────────────────────────────
    for key, subdir in [
        ("dyn_ppp", "ppp"), ("dyn_pp", "pp"),  ("dyn_p",  "p"),
        ("dyn_mp",  "mp"),  ("dyn_mf", "mf"),  ("dyn_f",  "f"),
        ("dyn_ff",  "ff"),  ("dyn_fff","fff"),  ("dyn_sf", "sf"),
        ("dyn_sfz", "sfz"), ("dyn_fp", "fp"),
    ]:
        defs[f"dynamics/{subdir}"] = rasterize_glyph(bravura, S[key])

    # ── Tempo Text ─────────────────────────────────────────────────────────
    for label in ["Allegro", "Adagio", "Andante", "Largo",
                  "Presto", "Grave", "Vivace", "Moderato"]:
        defs[f"tempo/{label.lower()}"] = rasterize_text(label, font_size=14)

    # ── Jump Marks ─────────────────────────────────────────────────────────
    defs["jump_marks/coda"]     = rasterize_glyph(bravura, S["coda"])
    defs["jump_marks/segno"]    = rasterize_glyph(bravura, S["segno"])
    defs["jump_marks/dc"]       = rasterize_text("D.C.", font_size=16)
    defs["jump_marks/ds"]       = rasterize_text("D.S.", font_size=16)
    defs["jump_marks/fine"]     = rasterize_text("Fine", font_size=16)
    defs["jump_marks/to_coda"]  = rasterize_text("To Coda", font_size=12)

    return defs


def generate_single_symbols(
    out_dir: Path,
    n_per_class: int = 800,
    bravura_path: Path = DEFAULT_BRAVURA,
    rng: Optional[random.Random] = None,
) -> int:
    """Render all single-symbol classes with augmentation.

    Returns number of samples written.
    """
    if rng is None:
        rng = random.Random(42)
    bravura = _load_bravura(bravura_path, 52)
    bravura_sm = _load_bravura(bravura_path, 36)  # smaller for stacked / row glyphs

    if bravura is None:
        print(f"WARN: Bravura font not found at {bravura_path}, "
              "symbols will be blank patches.", file=sys.stderr)

    defs = _make_single_defs(bravura, bravura_sm)
    total = 0
    for cls_path, base_img in defs.items():
        cls_dir = out_dir / cls_path
        cls_dir.mkdir(parents=True, exist_ok=True)
        base_img.save(cls_dir / "000001.png")
        total += 1
        for k in range(1, n_per_class):
            aug = augment_for_print_scan(base_img, rng)
            aug.save(cls_dir / f"{k + 1:06d}.png")
            total += 1

    return total


# ── Level 2: Logical Groups ───────────────────────────────────────────────────

def _beam_group_xml(n: int, note_type: str, pitches: List[Tuple[str, int]],
                    divisions: int = 8) -> str:
    """Build MusicXML for a beam group of n notes."""
    dur = divisions // ({"eighth": 2, "16th": 4, "32nd": 8}[note_type])
    notes = ""
    for i, (step, octave) in enumerate(pitches[:n]):
        bp = "begin" if i == 0 else ("end" if i == n - 1 else "continue")
        notes += _note(step, octave, dur, note_type, beam_pos=bp)
    # Fill rest of 4/4 measure
    filled = dur * n
    total = divisions * 4
    remainder = total - filled
    if remainder > 0:
        notes += _rest_note(remainder, "whole" if remainder >= divisions * 4
                            else "half" if remainder >= divisions * 2
                            else "quarter")
    return build_musicxml(notes, divisions=divisions, beats=4, beat_type=4)


def _chord_cluster_xml(n_notes: int, root: Tuple[str, int],
                       with_stem: bool = True) -> str:
    intervals = [0, 2, 4, 6, 9][:n_notes]  # C, D, E, G, A
    pitch_steps = _PITCHES
    root_idx = pitch_steps.index(root[0])
    notes = ""
    for i, semitone_offset in enumerate(intervals):
        step_idx = (root_idx + semitone_offset) % 7
        step = pitch_steps[step_idx]
        octave = root[1] + (root_idx + semitone_offset) // 7
        chord = i > 0
        notes += _note(step, octave, 4, "quarter", chord=chord)
    rest_dur = 4 * 3
    notes += (_rest_note(8, "half") + _rest_note(4, "quarter"))
    return build_musicxml(notes)


def _tied_notes_xml(n: int, step: str, octave: int) -> str:
    notes = ""
    for i in range(n):
        ts = (i < n - 1)
        tp = (i > 0)
        notes += _note(step, octave, 4, "quarter", tie_start=ts, tie_stop=tp)
    rest_dur = 4 * (4 - n)
    if rest_dur > 0:
        notes += _rest_note(rest_dur, "half" if rest_dur == 8 else "quarter")
    return build_musicxml(notes)


def _tuplet_xml(step: str, octave: int) -> str:
    notes = ""
    for i in range(3):
        ts = (i == 0)
        te = (i == 2)
        n = (f"        <time-modification>"
             f"<actual-notes>3</actual-notes>"
             f"<normal-notes>2</normal-notes>"
             f"</time-modification>\n")
        tuplet_notation = ""
        if ts:
            tuplet_notation = '        <tuplet type="start" bracket="yes"/>\n'
        if te:
            tuplet_notation = '        <tuplet type="stop"/>\n'
        # Build note manually with time-modification
        steps = _PITCHES
        s = steps[(steps.index(step) + i) % 7]
        note_lines = [
            "      <note>",
            f"        <pitch><step>{s}</step><octave>{octave}</octave></pitch>",
            f"        <duration>2</duration>",  # 2 of 6 per triplet eighth
            "        <type>eighth</type>",
            n.strip(),
        ]
        if tuplet_notation:
            note_lines += ["        <notations>",
                           tuplet_notation.strip(), "        </notations>"]
        note_lines.append("      </note>")
        notes += "\n".join(note_lines) + "\n"
    notes += _rest_note(16, "half")
    return build_musicxml(notes, divisions=6)


def _ornament_xml(ornament: str, step: str, octave: int) -> str:
    if ornament == "trill":
        extra = "        <ornaments><trill-mark/></ornaments>\n"
    else:
        extra = "        <ornaments><mordent/></ornaments>\n"
    note = _note(step, octave, 4, "quarter", notations_extra=extra)
    return build_musicxml(note + _rest_note(12, "dotted-half"))


def _grace_note_xml(grace_step: str, grace_oct: int,
                    main_step: str, main_oct: int) -> str:
    gn = _note(grace_step, grace_oct, 1, "eighth", grace=True)
    mn = _note(main_step, main_oct, 4, "quarter")
    return build_musicxml(gn + mn + _rest_note(12, "dotted-half"))


def _fallback_group(group_type: str, rng: random.Random) -> Image.Image:
    """PIL-based fallback for when Verovio is unavailable."""
    img = Image.new("L", (PATCH, PATCH), color=255)
    draw = ImageDraw.Draw(img)
    # Draw a simple representation
    draw.text((4, 4), group_type[:12], fill=0)
    # A few note-like shapes
    for i in range(3):
        x = 10 + i * 18
        y = PATCH // 2
        draw.ellipse([x - 5, y - 4, x + 5, y + 4], fill=0)
        draw.line([(x + 5, y), (x + 5, y - 20)], fill=0, width=1)
    return img


def generate_logical_groups(
    out_dir: Path,
    n_per_group: int = 400,
    bravura_path: Path = DEFAULT_BRAVURA,
    rng: Optional[random.Random] = None,
    renderer: Optional[VerovioRenderer] = None,
) -> int:
    """Generate Level 2 logical group patches.

    Returns number of samples written.
    """
    if rng is None:
        rng = random.Random(42)

    pitches_pool = [(s, o) for s in _PITCHES for o in (4, 5)]

    def _render_or_fallback(xml: str, cls_name: str) -> Image.Image:
        img = renderer.render(xml) if renderer and renderer._available else None
        if img is None:
            img = _fallback_group(cls_name, rng)
        return img

    def _save_class(subpath: str, base_imgs: List[Image.Image]) -> int:
        cls_dir = out_dir / subpath
        cls_dir.mkdir(parents=True, exist_ok=True)
        count = 0
        n_bases = len(base_imgs)
        for k in range(n_per_group):
            base = base_imgs[k % n_bases]
            img = augment_for_print_scan(base, rng) if k >= n_bases else base
            img.save(cls_dir / f"{k + 1:06d}.png")
            count += 1
        return count

    total = 0
    sample_pitches = rng.sample(pitches_pool, min(8, len(pitches_pool)))

    # ── Beam Groups ────────────────────────────────────────────────────────
    beam_configs = [
        ("beam_groups/2_eighths",       2, "eighth"),
        ("beam_groups/3_eighths",       3, "eighth"),
        ("beam_groups/4_eighths",       4, "eighth"),
        ("beam_groups/4_sixteenths",    4, "16th"),
        ("beam_groups/8_sixteenths",    8, "16th"),
        ("beam_groups/mixed_8_16",      4, "eighth"),  # render as mixed
    ]
    for subpath, n_notes, ntype in beam_configs:
        bases: List[Image.Image] = []
        for sp in sample_pitches[:3]:
            pitches = [sp] + [rng.choice(pitches_pool) for _ in range(n_notes - 1)]
            xml = _beam_group_xml(n_notes, ntype, pitches)
            bases.append(_render_or_fallback(xml, subpath))
        total += _save_class(subpath, bases)

    # ── Chord Clusters ─────────────────────────────────────────────────────
    for n_notes in range(2, 6):
        subpath = f"chord_clusters/{n_notes}_notes"
        bases = []
        for sp in sample_pitches[:3]:
            xml = _chord_cluster_xml(n_notes, sp)
            bases.append(_render_or_fallback(xml, subpath))
        total += _save_class(subpath, bases)

    # ── Chord without stem ─────────────────────────────────────────────────
    subpath = "chord_clusters/2_notes_whole"
    bases = []
    for sp in sample_pitches[:3]:
        xml = _chord_cluster_xml(2, sp, with_stem=False)
        bases.append(_render_or_fallback(xml, subpath))
    total += _save_class(subpath, bases)

    # ── Tied Notes ─────────────────────────────────────────────────────────
    for n in [2, 3]:
        subpath = f"tied_notes/{n}_tied"
        bases = []
        for sp in sample_pitches[:3]:
            xml = _tied_notes_xml(n, sp[0], sp[1])
            bases.append(_render_or_fallback(xml, subpath))
        total += _save_class(subpath, bases)

    # ── Tuplet Groups ──────────────────────────────────────────────────────
    subpath = "tuplets/triplet"
    bases = []
    for sp in sample_pitches[:3]:
        xml = _tuplet_xml(sp[0], sp[1])
        bases.append(_render_or_fallback(xml, subpath))
    total += _save_class(subpath, bases)

    # ── Mordents / Trills ──────────────────────────────────────────────────
    for ornament in ["trill", "mordent"]:
        subpath = f"mordents/{ornament}"
        bases = []
        for sp in sample_pitches[:3]:
            xml = _ornament_xml(ornament, sp[0], sp[1])
            bases.append(_render_or_fallback(xml, subpath))
        total += _save_class(subpath, bases)

    # ── Grace Notes ────────────────────────────────────────────────────────
    subpath = "grace_notes/grace_before"
    bases = []
    for sp in sample_pitches[:3]:
        gs = _PITCHES[(_PITCHES.index(sp[0]) + 1) % 7]
        xml = _grace_note_xml(gs, sp[1], sp[0], sp[1])
        bases.append(_render_or_fallback(xml, subpath))
    total += _save_class(subpath, bases)

    return total


# ── Level 3: Phrase Snippets ──────────────────────────────────────────────────

def _cadence_v_I_xml(major: bool = True) -> str:
    """V–I cadence in C major (or minor)."""
    fifths = 0
    # Measure 1: G major chord (V)
    m1 = (_note("G", 4, 4, "quarter") + _note("B", 4, 4, "quarter", chord=True)
          + _note("D", 5, 4, "quarter", chord=True)
          + _rest_note(4, "quarter"))
    # Measure 2: C major / minor chord (I)
    if major:
        m2 = (_note("C", 4, 4, "quarter") + _note("E", 4, 4, "quarter", chord=True)
              + _note("G", 4, 4, "quarter", chord=True)
              + _rest_note(4, "quarter"))
    else:
        m2 = (_note("C", 4, 4, "quarter") + _note("E", 4, 4, "quarter", chord=True)
              + _note("G", 4, 4, "quarter", chord=True)
              + _rest_note(4, "quarter"))
    return build_musicxml(m1, m2, fifths=fifths)


def _marcia_pattern_xml() -> str:
    """Dotted quarter + eighth + quarter (typical march figure)."""
    # divisions=8: dotted_quarter=12, eighth=4 → but 12+4 = 16 = 2 beats
    # In 2/4 with divisions=8: total=16
    notes = (
        f"      <note><pitch><step>G</step><octave>4</octave></pitch>"
        f"<duration>12</duration><type>quarter</type><dot/></note>\n"
        f"      <note><pitch><step>A</step><octave>4</octave></pitch>"
        f"<duration>4</duration><type>eighth</type>"
        f"<beam number=\"1\">begin</beam></note>\n"
        # Hmm, dotted+eighth finishes 2/4. Add the quarter separately
    )
    # Let me use a full 4/4 measure: dotted quarter + eighth + quarter + quarter
    # divisions=8: dotq=12, 8th=4, quarter=8
    notes = (
        f"      <note><pitch><step>G</step><octave>4</octave></pitch>"
        f"<duration>12</duration><type>quarter</type><dot/></note>\n"
        f"      <note><pitch><step>A</step><octave>4</octave></pitch>"
        f"<duration>4</duration><type>eighth</type></note>\n"
        f"      <note><pitch><step>B</step><octave>4</octave></pitch>"
        f"<duration>8</duration><type>quarter</type></note>\n"
        f"      <note><pitch><step>C</step><octave>5</octave></pitch>"
        f"<duration>8</duration><type>quarter</type></note>\n"
    )
    return build_musicxml(notes, divisions=8)


def _polka_pattern_xml() -> str:
    """Eighth rest + eighth + quarter (Polka upbeat feel)."""
    # divisions=8 in 2/4: total=16
    # eighth_rest=4, eighth=4, quarter=8 → 16 ✓
    notes = (
        "      <note><rest/><duration>4</duration><type>eighth</type></note>\n"
        f"      <note><pitch><step>E</step><octave>5</octave></pitch>"
        f"<duration>4</duration><type>eighth</type></note>\n"
        f"      <note><pitch><step>D</step><octave>5</octave></pitch>"
        f"<duration>8</duration><type>quarter</type></note>\n"
        # Fill remaining 2 beats of 4/4
        f"      <note><pitch><step>C</step><octave>5</octave></pitch>"
        f"<duration>8</duration><type>quarter</type></note>\n"
        "      <note><rest/><duration>4</duration><type>eighth</type></note>\n"
        f"      <note><pitch><step>G</step><octave>4</octave></pitch>"
        f"<duration>4</duration><type>eighth</type></note>\n"
    )
    return build_musicxml(notes, divisions=8)


def _walzer_pattern_xml() -> str:
    """Quarter + two eighths in 3/4 (Walzer feel)."""
    # divisions=8, 3/4: total=24
    # quarter=8, eighth=4, eighth=4, + 1 more beat = quarter=8
    notes = (
        f"      <note><pitch><step>C</step><octave>5</octave></pitch>"
        f"<duration>8</duration><type>quarter</type></note>\n"
        f"      <note><pitch><step>E</step><octave>5</octave></pitch>"
        f"<duration>4</duration><type>eighth</type>"
        f"<beam number=\"1\">begin</beam></note>\n"
        f"      <note><pitch><step>G</step><octave>5</octave></pitch>"
        f"<duration>4</duration><type>eighth</type>"
        f"<beam number=\"1\">end</beam></note>\n"
        f"      <note><pitch><step>E</step><octave>5</octave></pitch>"
        f"<duration>8</duration><type>quarter</type></note>\n"
    )
    return build_musicxml(notes, divisions=8, beats=3, beat_type=4)


def generate_phrase_snippets(
    out_dir: Path,
    n_per_snippet: int = 200,
    bravura_path: Path = DEFAULT_BRAVURA,
    rng: Optional[random.Random] = None,
    renderer: Optional[VerovioRenderer] = None,
) -> int:
    """Generate Level 3 phrase snippet patches.

    Returns number of samples written.
    """
    if rng is None:
        rng = random.Random(42)

    def _render_or_fallback(xml: str, cls_name: str) -> Image.Image:
        img = renderer.render(xml) if renderer and renderer._available else None
        if img is None:
            return _fallback_group(cls_name, rng)
        return img

    def _save_class(subpath: str, base_imgs: List[Image.Image]) -> int:
        cls_dir = out_dir / subpath
        cls_dir.mkdir(parents=True, exist_ok=True)
        count = 0
        n_bases = len(base_imgs)
        for k in range(n_per_snippet):
            base = base_imgs[k % n_bases]
            img = augment_for_print_scan(base, rng) if k >= n_bases else base
            img.save(cls_dir / f"{k + 1:06d}.png")
            count += 1
        return count

    total = 0

    snippets = [
        ("cadences/v_I",    [_cadence_v_I_xml(major=True)]),
        ("cadences/v_i",    [_cadence_v_I_xml(major=False)]),
        ("marcia/marcia_pattern", [_marcia_pattern_xml()]),
        ("polka/polka_pattern",   [_polka_pattern_xml()]),
        ("walzer/walzer_pattern", [_walzer_pattern_xml()]),
    ]
    for subpath, xmls in snippets:
        bases = [_render_or_fallback(xml, subpath) for xml in xmls]
        total += _save_class(subpath, bases)

    return total


# ── Manifest ──────────────────────────────────────────────────────────────────

def generate_manifest(out_dir: Path) -> Dict:
    """Scan out_dir and write manifest.json.  Returns the manifest dict."""
    samples = []
    class_counts: Dict[str, int] = {}

    for png in sorted(out_dir.rglob("*.png")):
        rel = png.relative_to(out_dir)
        parts = rel.parts  # e.g. ('single', 'noteheads', 'filled_quarter', '000001.png')
        if len(parts) < 2:
            continue
        class_path = "/".join(parts[:-1])
        sample_id = "/".join(str(p) for p in parts).replace("\\", "/").removesuffix(".png")
        augmentation = "none"
        try:
            seq = int(parts[-1].replace(".png", ""))
            if seq > 1:
                augmentation = "augmented"
        except ValueError:
            pass

        samples.append({
            "id": sample_id,
            "path": str(rel).replace("\\", "/"),
            "class": class_path.replace("/", "_"),
            "augmentation": augmentation,
            "size": [PATCH, PATCH],  # all images are 64×64 by design
        })
        class_counts[class_path] = class_counts.get(class_path, 0) + 1

    manifest = {
        "version": "v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "n_samples": len(samples),
        "classes": class_counts,
        "samples": samples,
    }
    manifest_path = out_dir / "manifest.json"
    with open(manifest_path, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2, ensure_ascii=False)
    return manifest


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> None:
    ap = argparse.ArgumentParser(
        description="Generate synthetic OMR training corpus (single symbols, "
                    "groups, phrase snippets).",
    )
    ap.add_argument("--output", type=Path,
                    default=Path("data/synthetic_corpus_v1"),
                    help="Output root directory")
    ap.add_argument("--n-per-class", type=int, default=800,
                    help="Samples per single-symbol class")
    ap.add_argument("--n-augmentations", type=int, default=5,
                    help="(Unused: kept for API compatibility; use --n-per-class)")
    ap.add_argument("--bravura", type=Path, default=DEFAULT_BRAVURA,
                    help="Path to Bravura.otf")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--no-groups", action="store_true",
                    help="Skip Level 2 groups (faster smoke runs)")
    ap.add_argument("--no-snippets", action="store_true",
                    help="Skip Level 3 snippets")
    args = ap.parse_args()

    rng = random.Random(args.seed)
    np.random.seed(args.seed)

    single_dir = args.output / "single"
    groups_dir = args.output / "groups"
    snippets_dir = args.output / "snippets"

    t0 = time.time()
    print(f"[1/4] Generating single symbols → {single_dir}")
    n_single = generate_single_symbols(
        single_dir, n_per_class=args.n_per_class,
        bravura_path=args.bravura, rng=rng)
    print(f"      {n_single} samples written  ({time.time() - t0:.1f}s)")

    n_groups = 0
    n_snippets = 0

    if not args.no_groups or not args.no_snippets:
        with VerovioRenderer() as renderer:
            if not args.no_groups:
                n_groups_per = max(1, args.n_per_class // 2)
                print(f"[2/4] Generating logical groups → {groups_dir}")
                n_groups = generate_logical_groups(
                    groups_dir, n_per_group=n_groups_per,
                    bravura_path=args.bravura, rng=rng, renderer=renderer)
                print(f"      {n_groups} samples written  ({time.time() - t0:.1f}s)")

            if not args.no_snippets:
                n_snip_per = max(1, args.n_per_class // 4)
                print(f"[3/4] Generating phrase snippets → {snippets_dir}")
                n_snippets = generate_phrase_snippets(
                    snippets_dir, n_per_snippet=n_snip_per,
                    bravura_path=args.bravura, rng=rng, renderer=renderer)
                print(f"      {n_snippets} samples written  ({time.time() - t0:.1f}s)")

    print(f"[4/4] Building manifest.json …")
    manifest = generate_manifest(args.output)
    elapsed = time.time() - t0

    total = manifest["n_samples"]
    n_classes = len(manifest["classes"])

    # Calculate total size
    total_bytes = sum(p.stat().st_size for p in args.output.rglob("*.png"))
    size_mb = total_bytes / (1024 * 1024)

    print(f"\n{'─' * 60}")
    print(f"  Synthetic corpus:  {args.output}")
    print(f"  Total samples  :  {total:,}")
    print(f"  Classes        :  {n_classes}")
    print(f"  Total size     :  {size_mb:.1f} MB")
    print(f"  Elapsed        :  {elapsed:.1f}s")
    print(f"{'─' * 60}")
    print(f"\nTop 20 classes by sample count:")
    for cls, cnt in sorted(manifest["classes"].items(),
                           key=lambda x: -x[1])[:20]:
        print(f"  {cls:<50} {cnt:>6}")


if __name__ == "__main__":
    main()
