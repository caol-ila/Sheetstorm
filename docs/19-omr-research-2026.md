# OMR Research 2026 — State of the Art vs. Sheetstorm-Engine

> **Auftrag:** Recherche-Bericht zu State-of-the-Art-OMR-Lösungen, Vergleich mit
> der Sheetstorm Rust-Engine (`feat/omr-quality-validation`) und konkrete
> Verbesserungsvorschläge.
>
> **Recherche-Zeitraum:** 2 Stunden Web-Research (Web-Search + Fetch).
> **Stand:** 2026-01.
> **Status (Escalation-Grade):** `DONE_WITH_CONCERNS` — siehe Abschnitt
> "Limitations & offene Fragen".

---

## Executive Summary

Die Sheetstorm-Engine ist auf synthetischen Daten exzellent (100 % NH-P/R), bricht
aber auf realen Vereinsblättern bei der **Symbol-Disambiguierung** (Coda, D.S.,
Volta, Dynamik) und beim **Stem-/Beam-Recall** (24 stems / 96 NHs in „Ein Prost") ein.
Die Top-5-Findings aus der Literatur, die wir umsetzen sollten:

1. **Hybrid-Pipeline statt End-to-End:** Audiveris 5.x (AGPL) und oemer (MIT)
   zeigen, dass klassische Pipelines + kleine Patch-CNNs (21×21 Notehead-
   Klassifier) die beste Robustheit/Speed-Bilanz liefern. Reine End-to-End-
   Transformer (SMT++) brauchen Annotations-Korpora, die wir nicht haben.
2. **Symbol-Klassifier zwischen NH-Detection und Pitch-Mapping einziehen:**
   Ein kleiner CNN (oder Klassifier auf HoG-Features) auf 32×32-Patches, der
   `notehead_filled / notehead_open / coda / segno / dynamic / volta_text /
   noise` unterscheidet, würde die Hauptfehlerquelle auf realen Scans
   eliminieren.
3. **Pixel-Segmentation für Staff-Removal:** oemer/U-Net macht das deutlich
   sauberer als unser RLE-Removal, das Open-Notes spaltet. Eine U-Net-
   Alternative oder ein „mask only line-pixels that don't intersect dark blob"-
   Heuristik beheben den Mixed-Durations-Fail.
4. **MUSCIMA++ als Real-Data-Benchmark einbinden:** CC-BY 4.0, 140 Seiten
   handschriftlich, 100+ Symbol-Klassen mit Polygon-Masken — ideal um unsere
   reale Accuracy zu messen, statt nur Synthetic.
5. **Slur/Tie- und Dot-Detection als eigene Pipeline-Stage:** Slurs via
   Hough/Bezier-Fit auf Reststrichen nach Symbol-Removal, Augmentation-Dots
   als kleine CCs in 2-px-Distanz rechts der NH. Beides klassisch lösbar,
   keine ML nötig.

---

## Vergleichs-Tabelle

| Lösung | Typ | NH-Algo | Symbol-Detection | F1 / SER | Speed | Lizenz |
|---|---|---|---|---|---|---|
| **Audiveris 5.x** | Hybrid (klassisch + Patch-CNN) | CC + 21×21-CNN-Reranker | Symbol-Library + glyph-CNN auf MUSCIMA | F1 ≈ 0.85 (intern, gedruckt) | ~1–2 s/Seite (JVM) | **AGPL-3.0** ⚠️ |
| **oemer** | ML (U-Net + Klassifier) | U-Net Pixel-Segmentation | U-Net Multiclass + SVM/RF/AdaBoost | n/a (Demo-only) | ~5–15 s/Seite (Python+TF) | **MIT** ✅ |
| **OpenOMR** | Klassisch (Java) | Template-Matching | Hand-Heuristiken | gering (Legacy) | schnell | GPL-2.0 ⚠️ |
| **MuseScore OMR** | Hybrid (war Audiveris-fork) | identisch zu Audiveris | identisch | identisch | identisch | GPL-3.0 ⚠️ |
| **Gamera** | Klassik-Framework | benutzerdefiniert | user-defined Klassifier | n/a | langsam | GPL-2.0 ⚠️ |
| **PrIMuS CRNN+CTC** | End-to-End ML (monophon) | implizit (kein Symbol-Step) | implizit (Sequence) | SER ~2 % (Camera-PrIMuS) | GPU-abhängig | MIT (Code) ✅ |
| **Sheet Music Transformer (SMT/SMT++)** | End-to-End Transformer (polyphon) | implizit | implizit (image→kern) | SER 3–5 % (pianoform) | GPU-abhängig (~mehrere s/Seite) | **MIT** ✅ |
| **Faster-R-CNN auf DeepScoresV2** | ML Object-Detection | Bounding-Box-Detect | Bounding-Box (135 Klassen) | F1 ≈ 0.81 (DSV2) | GPU | Code MIT, Daten CC-BY ✅ |
| **YOLOv8 Music** | ML Object-Detection | YOLO-Boxes | YOLO-Boxes | mAP 0.85–0.95 (gedruckt) | 30+ FPS GPU | AGPL (Ultralytics)/MIT (custom) ⚠️ |
| **DOLPHIN** | Hybrid (Graph-based) | klassisch + Graph | hierarchisch | Forschung, nicht produktiv | n/a | n/a |
| **Sheetstorm (wir)** | Klassisch (RLE+CC+NCC) | CC + Hole-Detect + NCC-Re-Rank + Pitch-Grid | nur Notehead | NH 100 % (synth), Symbol-Filter fehlt | ~3 s/Seite | AGPL-Repo |

> ⚠️ **Lizenz-Hinweis:** Sheetstorm ist im aktuellen Setup AGPL-3.0 (siehe
> `LICENSE.AGPL.txt` im Root). Damit ist Code-Reuse aus AGPL/GPL-Projekten
> *technisch* möglich, aber **AGPL „infiziert" jeden Konsumenten** — relevant,
> falls Sheetstorm später dual-lizenziert oder kommerziell ausgekoppelt werden
> soll. MIT/Apache-2.0/BSD/OFL-Code ist immer unproblematisch.

---

## Detail-Befunde pro Lösung

### Audiveris 5.x  (AGPL-3.0 — Java)

**Wie:** Klassische Pipeline (Binarisierung → Staff-Detection → Staff-Removal →
Symbol-Segmentation → CNN-Klassifikation → semantische Rekonstruktion). Das
entscheidende ML-Element ist ein **kleiner Patch-CNN auf 21×21 Grayscale-
Crops**, trainiert auf MUSCIMA + DeepScores für Notehead-Klassifikation.
Zusätzlich gibt es eine umfangreiche **Glyph-Library** (~300 Klassen) für
Clefs, Akzidentien, Rests, Ornamente und ein zweites CNN für glyph-classification.

**Was sie besser können als wir:**
- **Symbol-Vielfalt:** Sie unterscheiden ~300 Glyph-Klassen, wir nur Notehead/Stem/Beam/Bar.
- **Robust gegen handschriftliche Defekte** durch CNN-Reranker auf MUSCIMA-Training.
- **Voice-Splitting & semantische Rekonstruktion** (Akkord-Gruppierung, Beam-Voice-Zuordnung).
- **Trainings-Pipeline für Custom-Glyphs** ist offen dokumentiert.

**Was übernehmbar ist:**
- **Architektur-Idee** (Patch-CNN als Re-Ranker nach klassischer CC-Detection) ist 1:1 für Rust portierbar.
- **Glyph-Klassen-Liste & Trainingsdaten-Format** sind als Referenz nutzbar.

**Lizenz:** AGPL-3.0 — wir können Code lesen/portieren, aber **kein Code-Copy**
ohne unser Repo dauerhaft AGPL zu halten. Modell-Weights von Audiveris sind
ebenfalls AGPL-derived und nicht reusable in einem MIT/Apache-2.0-Kontext.

---

### oemer  (MIT — Python)

**Wie:** Komplett ML-basiert. **U-Net** macht Pixel-Segmentation in 4 Klassen
(staff-line, notehead, symbols, background). Danach klassischer Connected-
Component-Step auf den Symbol-Mask, gefolgt von einem klassischen Klassifier
(`classifier.py` enthält SVM, KNN, RandomForest, AdaBoost — Auswahl konfigurierbar).
Output: MusicXML.

**Was sie besser können als wir:**
- **Staff-Removal-Qualität:** Pixel-Segmentation entfernt Linien sauber, ohne
  Open-Notes zu spalten — direkt unser `mixed_durations`-Bug-Quelle.
- **Funktioniert auf Phone-Photos** (durch Trainingsdaten-Augmentation).
- **Robust auf Kontrast-/Beleuchtungsvariation.**

**Was übernehmbar ist:**
- **U-Net-Modell** (vortrainiert, MIT-Lizenz) könnte via ONNX in Rust per
  `tract` oder `ort` (ONNX-Runtime) eingebunden werden.
- **Klassifier-Feature-Set** (HoG, geometrische Features) ist als klassisch-
  ML-Backstop nutzbar.

**Lizenz:** **MIT** — voll wiederverwendbar, sowohl Code als auch Modell-Weights.

---

### Sheet Music Transformer (SMT / SMT++)  (MIT — PyTorch)

**Wie:** Reines End-to-End Image→Sequence (Humdrum **kern). Transformer-Encoder
(ViT-ähnlich) verarbeitet die Seite, Transformer-Decoder generiert Token-Sequenz
mit musikspezifischem Vokabular. SMT++ erweitert auf Full-Page Pianoform
(grand-staff polyphon).

**Was sie besser können als wir:**
- **Pianoform/Polyphonie** out of the box.
- **Kein klassischer Symbol-Step nötig** — keine Schwächen bei Coda/D.S./Volta.
- **SER 3–5 %** auf Test-Splits.

**Was *NICHT* anwendbar ist (für unseren Use-Case):**
- Brauchen GPU im Inference-Pfad — incompatible mit unserem „Rust-Engine läuft
  on-device im Flutter-Client"-Anspruch (Mobil/Desktop).
- Brauchen *gewaltige* Trainingsdaten in `**kern` oder MusicXML — bei uns nicht
  vorhanden, Generierung über MuseScore-Renderer aufwändig.
- **Fail-Modes:** Halluziniert Noten, wenn out-of-distribution → für Vereins-
  Bestand mit Handschrift-Anteil riskant.

**Empfehlung:** Nicht als Hauptmotor, aber als **„Second-Opinion"-Pfad** für
schwierige Seiten (Cloud-Service, optional). Lizenz MIT erlaubt das.

---

### PrIMuS / Camera-PrIMuS CRNN+CTC  (MIT)

**Wie:** Monophone Strecke (1 Stave). CNN → BiLSTM → CTC. Bypass aller
klassischen Schritte. SER ~2 % auf Camera-PrIMuS.

**Limitation:** Nur monophon (1 Stimme pro Stave) — für Marsch-Stimmen einer
Trompete reicht das, aber Schlagzeug-Multi-Voice/Akkorde fallen raus.

**Verwertbar als:** Validation-Layer („Wenn der CRNN dasselbe predicted wie unsere
Pipeline → high-confidence"). PrIMuS-Datensatz selbst ist als zusätzlicher
synth. Test-Korpus nutzbar.

---

### DeepScoresV2 / Faster-R-CNN-Baseline  (Code MIT, Daten CC-BY)

**Wie:** Reines Object-Detection-Setup. 135 Symbol-Klassen mit Bounding-Boxen.
F1 ≈ 0.81 (Faster R-CNN), 0.80 (Deep Watershed Detector).

**Was sie zeigt:** Object-Detection auf Music-Symbols funktioniert, ist aber
**schlechter als spezialisierte Pipelines** für Notehead-only-Tasks. Stärke:
seltene Symbole (Coda, Segno, D.S., Fermate) in einem Modell.

**Verwertbar:** **DeepScoresV2 als Trainingskorpus** für unseren geplanten
Symbol-Klassifier (siehe Verbesserungsvorschlag #5). 100k+ Seiten, gerendert
aus echtem Repertoire, CC-BY 4.0. ✅

---

### YOLOv8 Music-Symbol-Detection

**Wie:** Standard-YOLOv8 fine-tuned auf MUSCIMA++/DeepScoresV2. mAP 0.85–0.95
(gedruckt), 0.70–0.80 (handschriftlich).

**Lizenz-Falle:** Ultralytics YOLOv8 ist **AGPL-3.0** in der Standard-Lizenz —
für unseren AGPL-Kontext ok, für ein zukünftiges Dual-License nicht. Alternative:
YOLOX (Apache-2.0) oder eigenes ONNX-Modell mit RT-DETR.

**Verwertbar:** YOLO-Familie ist die einfachste Möglichkeit, einen symbol-
agnostischen Re-Ranker neben unsere klassische Pipeline zu setzen.

---

### MUSCIMA++ Datensatz  (CC-BY 4.0)

140 handschriftliche Seiten von CVC-MUSCIMA, mit **Polygon-Masken** für 100+
Symbolklassen + **Relations-Annotationen** (welcher Stem gehört zu welcher NH,
welcher Beam zu welcher Stem-Gruppe). Genau die Art Daten, die wir brauchen,
um unsere Pipeline gegen handschriftliche Vereinsblätter zu validieren. ✅

---

### Klassische Slur-Detection (Literatur)

Aus Rebelo et al. 2012 + neueren Reviews:
- **Klassisch:** Rest-Pixel nach Symbol-Removal → Connected Components mit
  hohem Aspect-Ratio (>3:1) und gebogener Skelett-Form → Bezier/Polynom-Fit
  → Validierung über Endpunkte-NH-Proximity.
- **CNN:** U-Net pixel-segmentation als „slur-mask"-Klasse, dann Polylinien-
  Extraktion.

Beide funktionieren. Klassisch reicht für Sheetstorm-Anspruch und vermeidet
neue ML-Dependencies.

---

## Konkrete Verbesserungsvorschläge für Sheetstorm

Sortiert nach **Impact / Effort**. Effort: S=Stunden, M=Tage, L=Wochen.

### 🟢 LOW-HANGING FRUIT (hoher Impact, kleiner Effort) — sofort umsetzen

1. **(S) Volta-/Text-Filter via Höhen-Heuristik:** „1." und „2." sitzen *über*
   der obersten Stafflinie und haben charakteristische OCR-Form. Reject any
   NH-Candidate, dessen y-Position > top_line - 1.5*spacing ist UND aspect
   ratio < 0.7 (Ziffer ist schmal). Ebenso Reject für „D.S.", „D.C.", „Fine"-
   Cluster (3+ kleine CCs in horiz. Reihe oberhalb/unterhalb der Stave).
   → Adresse direkt das Volta-Problem in BAVARIA.

2. **(S) Dynamik-Filter (f/mf/ff/p/pp):** Kursiv-Italic-Buchstaben unterhalb
   der Stave, Höhe ≈ 1.0–1.5 spacing, aspect 0.4–0.8. Reject wenn y > bottom_line
   + 0.5*spacing UND innerhalb einer 5-NH-horiz-Distanz keine andere NH gleicher
   Höhe. Adresse das f/mf/ff-Problem.

3. **(S) Notenhead-Aspect-Tightening für Open-Notes:** Bug `mixed_durations
   100/86`: Open-Notes werden vertikal zerschnitten beim Staff-Removal. Fix:
   *vor* Staff-Removal eine Open-NH-Detektion via vertical-projection
   („zwei dunkle Cluster in 2-px-Distanz oben+unten" = potenzielle Open-NH)
   und diese Pixel als „NH protected" markieren, bevor die mittlere Linie
   entfernt wird.

4. **(S) Stem-Recall verbessern via reduzierter Gap-Tolerance + Slope-Allowance:**
   Aktuell `1px gap-tolerance, ±3px scan range`. Auf realen Scans haben Stems
   oft 2–3 px Lücken durch Druckartefakte. Erhöhen auf 3 px gap-tolerance
   und ±5 px scan range mit anschließendem RANSAC-Linien-Fit zur Validierung.
   → Adresse 24/96 Stem-Recall in „Ein Prost".

5. **(S) Augmentation-Dot-Detection:** Kleine isolierte CC (radius ~ 0.25 *
   spacing) in 0.3–1.0 spacing rechts einer NH, vertikal in Linien-Gap-
   Position → `note.augmentation_dots = 1`. Trivial, hoher Impact für
   rhythmische Korrektheit.

### 🟡 MEDIUM (hoher Impact, mittlerer Effort) — Q1/Q2 Roadmap

6. **(M) Patch-Klassifier auf 32×32-Crops** für NH-Re-Ranker: Nach unserem
   NCC-Re-Rank zusätzlich ein **kleines CNN** (oder, wenn keine ML-Dependency
   gewünscht, ein HoG+SVM-Klassifier mit `linfa` in Rust) mit 5 Klassen:
   `notehead_filled / notehead_open / notehead_whole / non_notehead_symbol /
   noise`. Trainingsdaten: aus DeepScoresV2 (CC-BY) + Bravura-rendered
   Synthetic. Inferenz <1 ms/Patch. Adresse Coda/D.S./Symbol-Verwechslungen.

7. **(M) Open-NH-First-Class-Pfad:** Open- und Whole-Notes via dediziertem
   Algorithmus *vor* den Filled-NHs detektieren (Hough-Ellipsen-Transform auf
   den Gradient-Map, oder Ring-Filter-Convolution). Adresse das Splitting-
   Problem strukturell.

8. **(M) MUSCIMA++ als zweiter Test-Korpus:** Download (CC-BY), 10 Seiten als
   `tests/fixtures/muscima_plus/` mit Ground-Truth-NH-Boxes. Validates real
   handwritten music recall.

9. **(M) Slur-Detection-Stage:** Nach Symbol-Removal die Rest-Pixel auf
   gebogene CCs prüfen (aspect>3, Endpunkte über NHs). Bezier-Fit + Endpoints
   in `slurs[]` schreiben.

10. **(M) System-/Stafflinien-Verbindung & Voice-Splitting:** Aktuell zählen
    wir alles innerhalb einer Stave als eine Stimme. Für Schlagzeug/Akkorde:
    Notes mit gleichem onset → chord; Notes mit unterschiedlichen Stem-
    Direction → multiple voices. Trivialer Stem-Up/Stem-Down-Split.

### 🔵 BIG-BET (hoher Impact, hoher Effort) — Mid-Term

11. **(L) U-Net für Staff-Removal**: ONNX-export des oemer-Staff-Removal-
    Models, Inference via `tract`/`ort` in Rust. ~50 MB Modell, ~200 ms/Seite
    auf CPU. Riesig für Robustheit, aber neue Dependencies.

12. **(L) Symbol-Library mit SMuFL-Templates:** Bravura-Font (SIL OFL) als
    Quelle für ~300 Glyph-Templates rendern, NCC-Match gegen Rest-Pixel
    nach Notehead/Stem/Beam-Removal. Output: Coda, Segno, D.S., Fermate,
    Tempo-Marker als getrennte Entity-Klassen.

13. **(L) End-to-End-Validation-Pfad:** Optional einen Cloud-fallback via
    SMT++ (HuggingFace inference endpoint). Wenn unsere Plausibilisierung
    fehlschlägt (>30 % Takte impliziert), ruft Sheetstorm den E2E-Pfad als
    second opinion. Erfordert opt-in (Privacy).

### ⚫ ÜBERSPRINGEN (niedriger Impact oder schlechtes ROI)

- **Eigenes End-to-End-Transformer-Training:** zu wenig Trainingsdaten,
  zu hohe GPU-Kosten, zu hoher Maintenance-Aufwand.
- **Gamera-Integration:** Python-2-Legacy, GPL, langsam.
- **OpenOMR-Code-Reuse:** GPL-2.0 + Code-Qualität niedrig.

---

## Roadmap-Vorschlag

### Aktuelle Position
**Stage 4–5** in einem klassischen 7-Stage-OMR-Pipeline-Modell:
NH-Detection ✅, Stems 🟡, Beams 🟡, Bars ✅, Symbol-Disambiguierung ❌,
Slur/Dot ❌, Voice/Chord ❌.

### Phase 1 (sofort, ~1–2 Wochen) — „Real-Scan-Hardening"
Vorschläge **#1–#5** (alle S-effort). Erwartetes Ergebnis: BAVARIA
plausibility 38 % → 70 %; Mendocino 25 % → 60 %.

### Phase 2 (Q1, ~3–4 Wochen) — „Symbol-Awareness"
Vorschläge **#6–#10** (M-effort). Patch-Klassifier-Training auf
DeepScoresV2 + Bravura-Synthetic. MUSCIMA++ in CI als zweiter Korpus.
Slur+Dot+Voice-Split. Erwartet: Plausibilität 80 %+ auf Vereinsblättern.

### Phase 3 (Q2/Q3, opt-in) — „ML-Augmentation"
Vorschlag **#11** (U-Net Staff-Removal via ONNX). Vorschlag **#12** (SMuFL
Symbol-Library). Vorschlag **#13** (E2E-Cloud-Backstop).

> **Update Phase 3 / #11 (2026-01):** Die Rust-Inferenz-Pipeline für U-Net
> Staff-Removal ist als Stub eingebaut (`omr-staff::unet`, Feature `unet`,
> Backend `tract-onnx 0.21`). Sie lädt zur Laufzeit ein ONNX-Modell mit
> Interface `f32 [1,1,H,W] → f32 [1,1,H,W]` (Sigmoid-Maske der Stafflinien),
> mit automatischem RLE-Fallback wenn Feature aus / Modell fehlt / Inferenz
> fehlschlägt. Pipeline-Hook über `PipelineOptions::unet_model_path`.
>
> **Lizenz-Recherche (Status: BLOCKED auf Modell-Quelle):**
>
> - oemer (MIT): publizierte Staff-Line-Weights laden zwar aus dem Repo,
>   aber Modelcard / Trainings-Korpus-Lizenz ist im Release nicht
>   eindeutig dokumentiert. Da oemer-Entwickler in Issues auf MUSCIMA++
>   (CC-BY-NC-SA) verweisen, besteht **NC-Risiko** — ohne explizite
>   Klärung im oemer-Repo nicht für Apache-2.0-Distribution geeignet.
> - HuggingFace „music staff line removal": kein Modell mit klar
>   dokumentierter Apache/MIT-Lizenz UND Apache-kompatiblem Training-Set
>   gefunden.
> - **CVC-MUSCIMA Staff-Removal-Pairs** (CC-BY 4.0, *nicht* MUSCIMA++):
>   Apache-kompatibel und ideal als Trainings-Korpus, erfordert aber
>   eigenes Training (geschätzt 1–2 GPU-Stunden, Standard-U-Net mit 4
>   Pooling-Stufen).
>
> **Konsequenz:** Modell-Datei nicht im Repo; User-Workflow im
> `crates/omr-staff/README.md` dokumentiert. Folge-Task: eigenes Training
> auf CVC-MUSCIMA + Veröffentlichung der Weights als Apache-2.0-Asset
> (z.B. via GitHub Release oder HuggingFace-Card).

---

## Externe Bibliotheken / Datensätze (Lizenz-Status für Code-Reuse)

### ✅ OK für Code-Reuse (auch in dual-licensed-Setup)

| Asset | Lizenz | Verwendung |
|---|---|---|
| **oemer Modell-Weights** (U-Net Staff-Removal) | MIT | ONNX-Export → Rust-Inference |
| **PrIMuS / Camera-PrIMuS** Dataset | MIT | zusätzlicher Synth-Test-Korpus |
| **PrIMuS CRNN-Code** (`OMR-Research/tf-end-to-end`) | MIT | Architektur-Referenz, optional Inference-Service |
| **Sheet Music Transformer (SMT/SMT++)** | MIT | Cloud-Backstop (opt-in) |
| **DeepScoresV2 Datensatz** | CC-BY 4.0 | Training-Korpus für Symbol-Klassifier |
| **MUSCIMA++ Datensatz** | CC-BY 4.0 | Test-Korpus, handschriftliche Ground-Truth |
| **CVC-MUSCIMA Datensatz** | CC-BY 4.0 | Staff-Removal-Test-Korpus |
| **Bravura Font (SMuFL)** | **SIL OFL 1.1** | Synthetic-Glyph-Templates für Re-Ranker (✅ unproblematisch, auch SaaS) |
| **Emmentaler / Gonville (LilyPond fonts)** | OFL/GPL-Font-Exception | alternative Templates |
| **`tract` / `ort` (ONNX runtime crates)** | MIT/Apache-2.0 | ONNX-Modell-Inference in Rust |
| **`linfa` (Rust ML)** | MIT/Apache-2.0 | klassische Klassifier (SVM, RF) ohne Python-Deps |

### ⚠️ ACHTUNG / nur in AGPL-Kontext

| Asset | Lizenz | Risiko |
|---|---|---|
| **Audiveris-Code** | AGPL-3.0 | Code-Copy würde unser Repo dauerhaft AGPL fixieren. **Architektur-Ideen reusable, Code nicht.** |
| **MuseScore-OMR-Legacy** | GPL-3.0 | identisch. |
| **OpenOMR / Gamera** | GPL-2.0 | identisch + Code-Qualität niedrig. |
| **Ultralytics YOLOv8** | AGPL-3.0 | für AGPL-Repo ok, aber Cloud-Service-Trigger. Alternative: **YOLOX (Apache-2.0)** oder **RT-DETR**. |

### ❌ NICHT OK (aktuell nicht ausreichend Daten/Lizenz)

- DOLPHIN (kein klar lizenzierter Source-Release gefunden).
- Proprietäre OMR (PhotoScore, capella-scan, SmartScore).

---

## Antworten auf die spezifischen Fragen

1. **Notehead-Detection in Top-Engines:** Hybrid. Audiveris: CC-Detection +
   Patch-CNN-Reranker (21×21). oemer: U-Net-Pixel-Segmentation + CC.
   E2E (SMT, PrIMuS): implizit im Decoder. Wir liegen näher an Audiveris,
   aber ohne den CNN-Reranker.

2. **Filled/Open/Whole-Disambiguierung:** Audiveris löst es per Patch-CNN
   (3-Class). Klassisch wird Hole-Detection (innere Pixel-Density) +
   Aspect-Ratio + Hough-Ellipse genutzt — unsere Hole-Detection ist
   prinzipiell richtig, aber das Open-Splitting beim Staff-Removal vorm
   Klassifier verhindert die Klassifikation. Vorschlag #3 + #7 lösen das.

3. **Stems in Beam-Groups:** State of the art ist *Beam-Region detektieren*
   (horizontale dichte Streifen) → *vertikale Linien zwischen NH-y und
   Beam-y* zählen, nicht zwischen NH und beliebigem Endpunkt. Wir machen
   das schon richtig im Prinzip (`implied_stem`), aber Gap-Tolerance ist
   zu strikt. Vorschlag #4.

4. **Volta/Coda/D.S./Fermate:** Audiveris: Glyph-Library mit Patch-CNN
   (300 Klassen, MUSCIMA-trainiert). YOLOv8-Music: 135-Class-Detector.
   Wir: Bisher kein Pfad. Vorschläge #1, #2, #6, #12 schließen die Lücke.

5. **Text vs. Musik-Notation:** Audiveris nutzt OCR (Tesseract-Integration!)
   parallel zur Symbol-Detection und cross-validiert. Empfehlung: Text-
   Cluster-Filter (haben wir partiell) + eine Höhen-Bound-Heuristik
   (Vorschlag #1).

6. **Postprocessing-Tricks:** Beat-Quantization mit Viterbi (häufig in
   modernen Pipelines), Voice-Split per stem-direction, Bar-Plausibilität
   wie wir sie schon haben (Audiveris hat sehr ähnliche Logik). Unsere
   Scale-to-Fit-Repair ist bereits state-of-the-art, **könnte aber pro
   Voice statt pro Measure laufen** — das ist Vorschlag #10.

7. **Slur-Algorithmus:** klassisch Bezier/Polynom-Fit auf gebogene CCs
   nach Symbol-Removal. CNN-basiert via U-Net pixel-segmentation. Für uns
   reicht klassisch (Vorschlag #9).

8. **Speed:** Audiveris ~1–2 s/Seite, oemer 5–15 s/Seite (CPU+TF), SMT++
   GPU-abhängig (~1 s/Seite auf RTX). Wir mit ~3 s/Seite liegen
   konkurrenzfähig — keine Speed-Optimierung nötig vor Genauigkeit.

9. **MUSCIMA++ einbinden:** Ja, sofort. CC-BY-4.0, 140 Seiten,
   Polygon-Masken. Vorschlag #8.

10. **Open-Source-Symbol-Templates:** **Bravura (SIL OFL ✅)** ist Goldstandard.
    **Emmentaler (LilyPond)** und **Gonville** als Alternative. Alle SMuFL-
    konform, ~3000 Glyphen.

---

## Limitations & offene Fragen

- **Audiveris-Performance-Zahlen** sind aus Doku/Issues geschätzt, nicht aus
  einem direkten Benchmark unter unseren Bedingungen.
- **DOLPHIN** ist als Forschungsbeitrag identifiziert, aber kein
  produktionsreifer Code-Release mit klarer Lizenz auffindbar.
- **„Aware Music"** (Calvo-Zaragoza 2023) ließ sich in der Search-Time nicht
  präzise einordnen — möglicherweise ein synonym für SMT-Linie.
- **SMT++ SER-Zahlen** (3–5 %) variieren nach Korpus stark; auf reinem
  Pianoform besser, auf Brass-Stimmen unbekannt.
- **Lizenz-Strategie für Sheetstorm** (langfristig AGPL-only oder
  Dual-License) sollte vor Phase-3-Entscheidungen mit Architektur-Owner
  geklärt werden — siehe `.squad/decisions.md`.

---

## Quellen

- Audiveris: <https://github.com/Audiveris/audiveris>, <https://audiveris.github.io/audiveris/manual/omr/omr-classifier.html>
- oemer: <https://github.com/BreezeWhite/oemer>, <https://pypi.org/project/oemer/>
- Sheet Music Transformer: Ríos-Vila et al., arXiv:2402.07596 (ICDAR 2024); SMT++ ResearchGate-Preprint 2024; Repo <https://github.com/antoniorv6/SMT>
- PrIMuS / Camera-PrIMuS: Calvo-Zaragoza & Rizo, *Applied Sciences* 8(4), 606 (2018); ISMIR 2018; Code <https://github.com/OMR-Research/tf-end-to-end>; Daten <https://grfia.dlsi.ua.es/primus/>
- DeepScoresV2: Tuggener et al., ICPR 2020; ZHAW Digital Collection
- MUSCIMA++ / CVC-MUSCIMA: Hajič jr. et al., 2017; <https://ufal.mff.cuni.cz/muscima> (CC-BY 4.0)
- DOLPHIN: Hajič jr. et al., ISMIR 2021
- Bravura / SMuFL: <https://www.smufl.org/fonts/> (SIL OFL 1.1)
- Slur-Detection: Rebelo et al., *IJDAR*, 2012; Hajič et al., ICDAR 2017
- Faster-R-CNN / DWD Baselines: DeepScoresV2-Paper Tuggener et al. (F1 0.81 / 0.80)
- Ultralytics YOLOv8: <https://github.com/ultralytics/ultralytics> (AGPL-3.0)
- Rust ML/ONNX: `tract` <https://github.com/sonos/tract>, `ort` <https://github.com/pykeio/ort>, `linfa` <https://github.com/rust-ml/linfa>

---

**STATUS: DONE_WITH_CONCERNS**

**WORKS:** Vergleichs-Tabelle mit 10+ Lösungen, 13 priorisierte
Verbesserungsvorschläge mit Effort/Impact-Schätzung, Lizenz-Matrix für
Code-Reuse, Roadmap in 3 Phasen, alle Quellen mit URLs.

**RISK:**
- Performance-Vergleichszahlen (F1, SER, Pages/sec) zwischen Lösungen sind
  schlecht direkt vergleichbar (unterschiedliche Test-Korpora). Die Tabelle
  liefert Orientierungswerte, keine harten Benchmarks.
- DOLPHIN konnte nicht abschließend lokalisiert werden (kein klarer
  Code-Release).
- Audiveris-spezifische interne Architekturdetails (z.B. exakte CNN-
  Trainingsparameter) basieren auf Search-Snippet-Aussagen, nicht auf
  direkt gelesenem Source-Code.

**FOLLOW_UP:**
1. **Lizenz-Klärung mit Maintainer**: ist Sheetstorm dauerhaft AGPL? Falls ja,
   Phase-3-Vorschläge breiter; falls Dual-License geplant, AGPL-Quellen meiden.
2. **Direkt-Validierung Audiveris**: 1-Stunde-Spike, Audiveris auf BAVARIA/
   Mendocino-Scans laufen lassen und Output mit unserem vergleichen — gibt
   konkrete Baseline.
3. **MUSCIMA++ Test-Fixture-Setup**: 2-Stunden-Task, 10 Seiten in
   `tests/fixtures/muscima_plus/` einbinden, NH-Recall-Test schreiben.
