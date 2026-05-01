# Sheetstorm OMR Training Pipeline

End-to-End ML-Trainingspipeline für Sheetstorm-OMR. Erweitert die statische
Bravura-Template-basierte Klassifikation um echte ML-Modelle, trainiert auf:

1. **Bravura-Synth-Templates** (`omr-symbols/templates.rs`)
2. **User-Annotations** (vom Annotation-Tool gesammelt)
3. **MUSCIMA++** (öffentlicher handgeschriebener Notenkorpus)
4. **DorigeT** (öffentlicher gedruckter Notenkorpus)
5. **PrIMuS** (semantisches OMR-Datenset)

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Trainingsdaten sammeln                                    │
│    - export_user_annotations.py (User-Annotations als PNG)   │
│    - download_muscima.py (MUSCIMA++ corpus)                  │
│    - prepare_dorigetin.py (DorigeT corpus)                   │
│    → data/training/{class}/sample_NNNN.png                   │
├─────────────────────────────────────────────────────────────┤
│ 2. CNN-Training                                              │
│    - train_cnn.py (PyTorch, MobileNetV3-small)               │
│    → models/symbol_classifier.pt                             │
├─────────────────────────────────────────────────────────────┤
│ 3. ONNX-Export für Rust-Inference                           │
│    - export_onnx.py                                          │
│    → models/symbol_classifier.onnx                           │
│    → src/omr-rust/crates/omr-symbols/assets/cnn-model.onnx   │
├─────────────────────────────────────────────────────────────┤
│ 4. Evaluation                                                │
│    - eval.py: Accuracy + Confusion-Matrix auf Held-out-Set   │
└─────────────────────────────────────────────────────────────┘
```

## Setup

```powershell
cd tools/training
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
.\.venv\Scripts\playwright install chromium  # falls nicht von synth-corpus
```

## Klassen-Schema

| Class-ID | Label | Beschreibung |
|----------|-------|--------------|
| 0 | NoteheadFilled | gefüllter Notenkopf (Viertel/Achtel/...) |
| 1 | NoteheadOpen | offener Notenkopf (Halbe) |
| 2 | NoteheadWhole | Ganze Note |
| 3 | RestQuarter | Viertelpause |
| 4 | RestHalf | Halbe Pause |
| 5 | RestWhole | Ganze Pause |
| 6 | RestEighth | Achtelpause |
| 7 | RestSixteenth | Sechzehntelpause |
| 8 | ClefTreble | Violinschlüssel |
| 9 | ClefBass | Bassschlüssel |
| 10 | ClefAlto | Altschlüssel |
| 11 | ClefTenor | Tenorschlüssel |
| 12 | Sharp | Kreuz (♯) |
| 13 | Flat | Be (♭) |
| 14 | Natural | Auflösungszeichen (♮) |
| 15 | DoubleSharp | Doppelkreuz |
| 16 | DoubleFlat | Doppelbe |
| 17 | TimeSig2 | Zahl 2 in Taktart |
| 18 | TimeSig3 | Zahl 3 |
| 19 | TimeSig4 | Zahl 4 |
| 20 | TimeSig6 | Zahl 6 |
| 21 | TimeSig8 | Zahl 8 |
| 22 | RepeatStart | ‖: |
| 23 | RepeatEnd | :‖ |
| 24 | Coda | Coda-Symbol |
| 25 | Segno | Segno-Symbol |
| 26 | Fine | Fine-Text |
| 27 | DynamicP | piano (p) |
| 28 | DynamicF | forte (f) |
| 29 | DynamicMP | mezzo piano |
| 30 | DynamicMF | mezzo forte |
| 31 | DynamicPP | pianissimo |
| 32 | DynamicFF | fortissimo |
| 33 | Crescendo | < (Hairpin) |
| 34 | Decrescendo | > (Hairpin) |
| 35 | Slur | Bindebogen |
| 36 | Tie | Haltebogen |
| 37 | StaccatoDot | Staccato-Punkt |
| 38 | AccentMark | > Akzent |
| 39 | Fermata | Fermate |
| 40 | TrillMark | Triller |
| 41 | AugmentationDot | Punktierung |
| 42 | TupletNumber | Triolen-Zahl |
| 43 | Beam | Achtelbalken |
| 44 | Stem | Notenhals |
| 45 | LedgerLine | Hilfslinie |
| 46 | Barline | Taktstrich |
| 47 | Noise | Rauschen / nichts |

## Trainingsdaten-Statistik (Soll)

Pro Klasse mindestens 500 Samples (gemischt aus den Quellen):
- ~50 Bravura-Synth-Templates (Augmentationen)
- ~200 User-Annotations (real)
- ~250 MUSCIMA/DorigeT/PrIMuS

= 24.000 Samples gesamt. Mit Augmentation x10 → 240.000.

## Lizenzen

- **MUSCIMA++**: Creative Commons Attribution 4.0
- **DorigeT**: CC-BY-NC-SA 4.0 (NUR FORSCHUNG, KEINE KOMMERZIELLE NUTZUNG)
- **PrIMuS**: GNU GPL v3
- **Bravura**: SIL OFL 1.1

⚠️ User-Annotations werden NUR mit explizitem Opt-In ins gemeinsame
Sheetstorm-Modell aufgenommen.
