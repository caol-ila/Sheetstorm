"""
export_user_annotations.py

Sammelt alle User-Annotations aus dem Sheetstorm-Filestore und extrahiert
für jede confirmed/corrected NH einen 64x64-Patch um den Notenkopf herum.
Die Patches werden klassifiziert und in einer Verzeichnisstruktur abgelegt
die direkt vom CNN-Training-Loop konsumiert werden kann:

    data/training/
      0_NoteheadFilled/
        sample_00001.png
        sample_00002.png
      1_NoteheadOpen/
        sample_00003.png
      ...

Quellen:
- src/.filestore/parts/ (Original-PDFs + Page-PNGs)
- DB-Tabelle PartAnnotations (Korrektur-Records)

Benötigt: PostgreSQL-Connection-String + Pillow + psycopg2.

Aufruf:
    python export_user_annotations.py \\
        --connection "Host=localhost;Database=sheetstormdb;Username=...;Password=..." \\
        --filestore ../../src/.filestore \\
        --output data/training \\
        --patch-size 64 \\
        --skip-test-pieces
"""
from __future__ import annotations
import argparse
import io
import json
import os
import re
import sys
from pathlib import Path
from typing import Optional

# Sicherstellen dass Sonderzeichen im Output korrekt geloggt werden (Windows cp1252)
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

try:
    from PIL import Image
except ImportError:
    print("FEHLER: pip install Pillow", file=sys.stderr)
    sys.exit(2)

# Klassenmapping konsistent mit README.md
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


def class_dir(class_id: int, output_root: Path) -> Path:
    name = CLASS_NAMES[class_id] if 0 <= class_id < len(CLASS_NAMES) else f"Unknown{class_id}"
    return output_root / f"{class_id:02d}_{name}"


def map_annotation_to_class(annotation_kind: int, correction_json: Optional[str], detection_kind: Optional[str]) -> Optional[int]:
    """Bestimmt die ML-Klasse aus PartAnnotation-Daten.

    annotation_kind:
        0 = NotANote (nicht trainieren — ist Noise oder Falscher-Detection)
        1 = WrongPitch (correction_json hat midi/step/octave)
        2 = WrongDuration (correction_json hat duration)
        3 = WrongKind (correction_json hat kind)
        4 = MissedNote (NEUE Note vom User markiert — als NoteheadFilled)
        5 = Comment (kein training)
        6 = Confirmed (Detection korrekt — verwende detection_kind)
        7 = RegionConfirmed (alle in Region korrekt — wird separat behandelt)
        8 = WrongSymbol (correction_json hat symbol_type)
        9 = MissedSymbol (correction_json hat symbol_type)
    """
    if annotation_kind == 5:  # Comment
        return None
    if annotation_kind == 7:  # RegionConfirmed — separately
        return None
    if annotation_kind == 0:  # NotANote
        return CLASS_NAMES.index("Noise")
    if annotation_kind == 4:  # MissedNote → NH (most common case is filled)
        return CLASS_NAMES.index("NoteheadFilled")
    if annotation_kind == 6:  # Confirmed
        if detection_kind == "Filled":
            return CLASS_NAMES.index("NoteheadFilled")
        if detection_kind == "Open":
            return CLASS_NAMES.index("NoteheadOpen")
        if detection_kind == "Whole":
            return CLASS_NAMES.index("NoteheadWhole")
        return CLASS_NAMES.index("NoteheadFilled")
    if annotation_kind in (8, 9) and correction_json:
        try:
            payload = json.loads(correction_json)
            symbol_type = payload.get("symbol_type") or payload.get("kind")
            if symbol_type:
                if symbol_type in CLASS_NAMES:
                    return CLASS_NAMES.index(symbol_type)
        except (json.JSONDecodeError, AttributeError):
            return None
    if annotation_kind == 3 and correction_json:
        try:
            payload = json.loads(correction_json)
            kind = payload.get("kind")
            mapping = {"Filled": 0, "Open": 1, "Whole": 2}
            if kind in mapping:
                return mapping[kind]
        except (json.JSONDecodeError, AttributeError):
            return None
    return None


def extract_patch(page_image_path: Path, x: int, y: int, w: int, h: int, patch_size: int = 64) -> Optional[Image.Image]:
    """Extrahiert einen patch_size×patch_size Patch zentriert um die Bbox.

    Padding: weiß. Leichtes Margin (10% der Bbox) damit Kontext mitkommt.
    """
    try:
        img = Image.open(page_image_path).convert("L")  # grayscale
    except Exception:
        return None
    cx = x + w // 2
    cy = y + h // 2
    half = patch_size // 2
    # Skaliere bbox so dass es ~70% des patches einnimmt
    scale = patch_size / max(w, h, 1) * 0.7
    if scale != 1.0 and 0.5 < scale < 4.0:
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--connection", help="PostgreSQL connection string for direct DB access")
    ap.add_argument("--filestore", type=Path, default=Path("../../src/.filestore"),
                    help="Pfad zum Sheetstorm-Filestore")
    ap.add_argument("--output", type=Path, default=Path("data/training"),
                    help="Ausgabe-Verzeichnis (wird angelegt)")
    ap.add_argument("--patch-size", type=int, default=64)
    ap.add_argument("--skip-test-pieces", action="store_true", default=True,
                    help="[E2E-TEST]-Pieces ueberspringen")
    ap.add_argument("--from-json", type=Path,
                    help="Statt DB: Annotations aus einem JSON-Dump lesen "
                         "(Backend kann via REST exportieren)")
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    for cid in range(len(CLASS_NAMES)):
        class_dir(cid, args.output).mkdir(parents=True, exist_ok=True)

    if args.from_json:
        print(f"Lese Annotations aus JSON: {args.from_json}")
        with args.from_json.open("r", encoding="utf-8") as f:
            data = json.load(f)
        process_json_dump(data, args)
    elif args.connection:
        try:
            import psycopg2
            print(f"Verbinde zu DB: {args.connection[:30]}...")
            process_db(args)
        except ImportError:
            print("FEHLER: pip install psycopg2-binary", file=sys.stderr)
            sys.exit(2)
    else:
        print("FEHLER: --connection oder --from-json muss angegeben werden", file=sys.stderr)
        sys.exit(1)


def process_json_dump(data: dict, args):
    """JSON-Format vom Backend-Export-Endpoint:
    {
        "parts": [
            {
                "part_id": "...",
                "piece_title": "...",
                "page_images": [{"page_index": 0, "blob_key": "..."}, ...],
                "annotations": [
                    {"page_index": 0, "x": 100, "y": 200, "w": 20, "h": 20,
                     "kind": 6, "correction_json": null,
                     "detection_kind": "Filled"}
                ]
            }
        ]
    }
    """
    written = {}
    counter = 0
    for part in data.get("parts", []):
        if args.skip_test_pieces and (part.get("piece_title") or "").startswith("[E2E-TEST]"):
            continue
        page_images = {p["page_index"]: p["blob_key"] for p in part.get("page_images", [])}
        for ann in part.get("annotations", []):
            cls = map_annotation_to_class(
                ann.get("kind", 0), ann.get("correction_json"), ann.get("detection_kind"))
            if cls is None:
                continue
            blob_key = page_images.get(ann.get("page_index", 0))
            if not blob_key:
                continue
            page_path = args.filestore / blob_key
            if not page_path.exists():
                continue
            patch = extract_patch(
                page_path, ann["x"], ann["y"], ann["w"], ann["h"], args.patch_size)
            if patch is None:
                continue
            counter += 1
            out_path = class_dir(cls, args.output) / f"sample_{counter:06d}_{part['part_id'][:8]}.png"
            patch.save(out_path)
            written[cls] = written.get(cls, 0) + 1
    print(f"\nFertig — {counter} Patches geschrieben")
    for cls, n in sorted(written.items()):
        print(f"  Class {cls:02d} {CLASS_NAMES[cls]:<24}: {n} samples")


def process_db(args):
    """Direkter DB-Zugriff via psycopg2."""
    import psycopg2
    # Connection string Format: "Host=...;Database=...;Username=...;Password=..."
    # Konvertiere zu URI
    parts = dict(p.split("=", 1) for p in args.connection.split(";") if "=" in p)
    dsn = (
        f"host={parts.get('Host', 'localhost')} "
        f"dbname={parts.get('Database', 'sheetstormdb')} "
        f"user={parts.get('Username', 'postgres')} "
        f"password={parts.get('Password', '')}"
    )
    if "Port" in parts:
        dsn += f" port={parts['Port']}"
    conn = psycopg2.connect(dsn)
    cur = conn.cursor()

    # Annotations + Part + Piece + PartFile (PageImage) joinen
    cur.execute("""
        SELECT
            pa.id, pa."PartId", pa."PageIndex",
            pa."BboxX", pa."BboxY", pa."BboxW", pa."BboxH",
            pa."Kind", pa."CorrectionJson",
            p."PieceId", pi."Title",
            pf."BlobKey"
        FROM "PartAnnotations" pa
        JOIN "Parts" p ON p."Id" = pa."PartId"
        LEFT JOIN "Pieces" pi ON pi."Id" = p."PieceId"
        LEFT JOIN "PartFiles" pf ON pf."PartId" = pa."PartId"
            AND pf."Kind" = 2  -- PageImage
            AND pf."PageNumber" = pa."PageIndex" + 1
        WHERE pa."Kind" IN (0, 1, 2, 3, 4, 6, 8, 9)
    """)
    rows = cur.fetchall()
    print(f"Gefunden: {len(rows)} Annotations")

    written = {}
    counter = 0
    for row in rows:
        (ann_id, part_id, page_idx, x, y, w, h, kind, correction_json, piece_id, piece_title, blob_key) = row
        if args.skip_test_pieces and (piece_title or "").startswith("[E2E-TEST]"):
            continue
        if not blob_key:
            continue
        cls = map_annotation_to_class(kind, correction_json, None)  # detection_kind optional
        if cls is None:
            continue
        page_path = args.filestore / blob_key
        if not page_path.exists():
            continue
        patch = extract_patch(page_path, x, y, w, h, args.patch_size)
        if patch is None:
            continue
        counter += 1
        out_path = class_dir(cls, args.output) / f"sample_{counter:06d}_{str(part_id)[:8]}.png"
        patch.save(out_path)
        written[cls] = written.get(cls, 0) + 1

    conn.close()
    print(f"\nFertig — {counter} Patches geschrieben")
    for cls, n in sorted(written.items()):
        print(f"  Class {cls:02d} {CLASS_NAMES[cls]:<24}: {n} samples")


if __name__ == "__main__":
    main()
