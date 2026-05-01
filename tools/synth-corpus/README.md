# Synthetic OMR Training-Corpus

Generiert realistisch aussehende Notenseiten aus MIDI-Dateien für Training/Validierung
der OMR-Pipeline. **Garantierte Ground Truth** — jede Note kommt aus dem MIDI und ist
exakt bekannt (Pitch + Onset + Duration).

## Pipeline

```
MIDI-Datei (Blasmusik)                   ← öffentlich verfügbare Quellen
    ↓
music21 / mido (MIDI-Parser)
    ↓
MusicXML pro Stimme/Track
    ↓                                    ← + zufällige Layout-Variation
Verovio / MuseScore CLI → SVG/PNG        ← + realistische Schriftarten
    ↓
Augmentation:
  • JPEG-Recompression (Qualität 30–60)
  • Skew (-3° bis +3°)
  • Gaussian-/Salt-Pepper-Noise
  • Heller/dunkler (Contrast 0.7–1.3)
  • Druck-Raster simulieren
  • Folding-Marks (vertikale Linien)
    ↓
Synthetic-PDF (sieht aus wie ein gescannter Notensatz)
    ↓
OMR-Pipeline
    ↓
Vergleich mit Ground-Truth → Metriken: Pitch-F1, Duration-F1, Onset-Accuracy
```

## Quellen für Public-Domain-MIDI (Blasmusik)

### Automatisch mit `download_midis.py`:
- **Mutopia Project** — `https://www.mutopiaproject.org/` (CC0/PD)
- **Free-Scores.com** — Filter "wind band", "brass band"
- **IMSLP** — Petrucci Music Library (PD)
- **Classic Cat** — `https://www.classiccat.net/midi.htm`

### Empfohlene Komponisten (PD):
- John Philip Sousa (Märsche): "Stars and Stripes Forever", "Washington Post"
- Henry Fillmore: "American Patrol", "His Honor"
- Karl King: "Barnum and Bailey's Favorite"
- Ernst Mollerup, Max Richter (klassische Wind-Band-Arrangements)
- Anton Bruckner, Antonín Dvořák (orchestrale Auszüge)

### Manuelle Sammlung
Lege MIDI-Dateien einfach in `tools/synth-corpus/data/midi/` ab.

## Setup

```powershell
# Python-Dependencies installieren (Windows)
cd tools/synth-corpus
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# MuseScore (für Rendering) — optional, sonst Verovio
# Download: https://musescore.org/de/download
# Pfad notieren, in render.py konfigurierbar
```

`requirements.txt`:
```
music21>=9.1
verovio>=4.0
mido>=1.3
Pillow>=10.0
numpy>=1.26
cairosvg>=2.7
```

## Workflow

### 1) MIDIs sammeln
```powershell
python download_midis.py --target data/midi --max 50
```
Lädt 50 MIDIs aus Public-Domain-Quellen.

### 2) MIDI → MusicXML pro Stimme
```powershell
python midi_to_parts.py --input data/midi --output data/musicxml
```
Splittet jede MIDI nach Tracks. Pro Track entsteht eine MusicXML mit:
- Korrekter Tonart, Taktart
- Komplettem Pitch + Duration je Note
- Instrument-Bezeichnung aus MIDI-Track-Name (z.B. "Trumpet 1")

### 3) MusicXML → Realistische Notenseite
```powershell
python render_pages.py --input data/musicxml --output data/pages --format png --dpi 300
```
- Pro MusicXML wird ein PDF/PNG gerendert
- Mit Titel, Komponist, Stimme, Taktnummern
- Verovio/MuseScore CLI sorgen für ein realistisches Layout

### 4) Augmentation
```powershell
python augment.py --input data/pages --output data/augmented --variants 5
```
Generiert 5 Varianten pro Bild:
- v1: leichter Noise (sieht wie 200dpi-Scan aus)
- v2: starker Noise + JPEG-Kompression Q30
- v3: leicht verzerrt (skew ±2°)
- v4: heller (verblasstes altes Notenpapier)
- v5: dunkler (kopierter alter Druck)

### 5) Validation: Pipeline gegen Ground-Truth
```powershell
python validate.py --pages data/augmented --truth data/musicxml --report report.json
```
Run der OMR-Pipeline auf jedes augmentierte Bild, dann Vergleich mit der MusicXML-Ground-Truth.

**Metriken** (per Stimme + global):
- **Pitch-F1**: % korrekt erkannte (Pitch+Octave) Noten
- **Duration-F1**: % korrekte Notenlängen
- **Onset-Accuracy**: % Noten an korrekter Takt-Position
- **Symbol-Recall**: % erkannte Notenschlüssel/Taktart/Vorzeichen
- **Plausibility-Score**: aus Pipeline (% Takte die summieren)

## Output-Format

`report.json`:
```json
{
  "summary": {
    "total_pages": 250,
    "pitch_f1": 0.87,
    "duration_f1": 0.81,
    "onset_accuracy": 0.92,
    "symbol_recall": 0.95
  },
  "per_page": [
    {
      "page": "data/augmented/sousa-stars-trp1-v1.png",
      "ground_truth": "data/musicxml/sousa-stars-trp1.musicxml",
      "pipeline_output": "data/pipeline-out/sousa-stars-trp1-v1.musicxml",
      "metrics": { "pitch_f1": 0.91, ... }
    }
  ]
}
```

## Integration in CI

Sobald die Pipeline ein neues Feature/Filter bekommt:
```powershell
python validate.py --pages data/augmented --truth data/musicxml --baseline last-baseline.json
```
→ alarmiert wenn Metriken schlechter werden (Regression).

## Status

- [x] Konzept dokumentiert
- [ ] `download_midis.py` — MIDI-Fetcher
- [ ] `midi_to_parts.py` — MIDI-Splitter
- [ ] `render_pages.py` — MusicXML-Renderer
- [ ] `augment.py` — Augmentation
- [ ] `validate.py` — Validation + Report
- [ ] CI-Integration
