# OMR Algorithm Research — State of the Art für eine Rust-Implementierung

> **Scope:** Konkrete, umsetzbare Algorithmen-Empfehlungen pro Pipeline-Stufe für eine Rust-Reimplementierung der OMR-Funktionalität in Sheetstorm.
>
> **AGPL-Hygiene:** Dieses Dokument basiert ausschließlich auf wissenschaftlichen Papers (Cardoso, Rebelo, Calvo-Zaragoza, Pacha, Ríos-Vila u.a.), Konzept-Beschreibungen aus Blog-Posts und der öffentlichen API-Dokumentation von Open-Source-Projekten. **Audiveris-Quellcode wurde nicht eingesehen.** Ähnlichkeiten ergeben sich aus der gemeinsamen wissenschaftlichen Grundlage (insbesondere Cardoso 2009, Rebelo 2012), nicht aus Code-Übernahme.
>
> **Status:** Research-Dokument. Architektur-Entscheidungen werden in `.squad/decisions.md` separat festgehalten.

---

## Inhalt

1. [Image Preprocessing](#1-image-preprocessing)
2. [Staff-Line Detection](#2-staff-line-detection)
3. [Staff-Line Removal](#3-staff-line-removal)
4. [Symbol Segmentation](#4-symbol-segmentation)
5. [Notehead Recognition](#5-notehead-recognition-kernstück)
6. [Stem & Beam Detection](#6-stem--beam-detection)
7. [Pitch Estimation](#7-pitch-estimation)
8. [Duration Estimation](#8-duration-estimation)
9. [Voice / Layer Reconstruction](#9-voice--layer-reconstruction)
10. [MusicXML Export](#10-musicxml-export)
11. [End-to-End Modelle](#11-end-to-end-modelle)
12. [Performance-Optimierung in Rust](#12-performance-optimierung-in-rust)
13. [Ground-Truth & Eval](#13-ground-truth--eval)
14. [Konkrete Empfehlung für Sheetstorm](#14-konkrete-empfehlung-für-sheetstorm-v1)
15. [5-Punkt-Action-List](#15-5-punkt-action-list)

---

## 1. Image Preprocessing

### 1.1 Ausgangslage

Eingabe ist eine A4-Seite, in der Regel als 300 dpi Scan (≈ 2480 × 3508 Pixel, Graustufen oder RGB) oder als Foto vom Smartphone (variable Auflösung, perspektivische Verzerrung, ungleichmäßige Beleuchtung). Verlagsdrucke (z.B. Notensatz aus MuseScore, Finale, Sibelius) haben:

- gleichmäßige Linienstärke (typisch 1–2 px bei 300 dpi)
- Notenliniensystem-Höhe (`staff_height`) typisch 28–40 px (das ist **das wichtigste Längenmaß** im gesamten OMR-Stack — alles andere wird relativ dazu skaliert)
- gleichmäßiger Schwarzwert
- moderate JPEG/Scanner-Artefakte

Smartphone-Fotos und alte Drucke sind ein anderer Schwierigkeitsgrad und sollten in v1 nicht das primäre Ziel sein.

### 1.2 Binarisierung — Vergleich

Globale Schwellwerte (Otsu) versagen bei ungleichmäßiger Beleuchtung und sind für OMR nur bei perfekt gescannten Verlagsdrucken brauchbar. Lokale, adaptive Verfahren sind Standard.

| Verfahren | Formel | Sweet-Spot Window | Sweet-Spot k | Typische Stärke |
|---|---|---|---|---|
| Otsu (global) | bimodaler Histogramm-Split | – | – | schnell, scheitert bei Beleuchtungs-Gradienten |
| Niblack 1986 | `T = m + k·s` | 25–31 px | −0.2 | empfindlich gegen Rauschen in Hintergrundregionen |
| Sauvola 2000 | `T = m·(1 + k·(s/R − 1))` | 25–31 px (≈ `staff_height`) | 0.34 (kontrastarm) … 0.5 (Standard) | **Stand der Technik für Dokumentenscans**; kaum Speckle |
| Wolf-Jolion 2004 | `T = m − k·(1 − s/R_max)·(m − M_min)` | 25–31 px | 0.5 | wie Sauvola, aber stabiler bei stark schwankendem Hintergrund |

**Empfehlung Sheetstorm v1:** **Sauvola** mit `window = 25 px` und `k = 0.34`, ausgehend von einer geschätzten `staff_space ≈ 8–10 px`. Faustregel: `window ≈ 2.5 × staff_space`. Wenn `staff_space` noch nicht bekannt ist (Sauvola läuft *vor* Staff-Detection), dann fester Default `25 px` für 300-dpi-Eingaben und nach erster Staff-Schätzung optional eine zweite Sauvola-Pass mit kalibriertem Window.

`R` ist der dynamische Wertebereich der Standardabweichung; für 8-Bit-Bilder ist `R = 128` Standard, viele Implementierungen nutzen `R = 0.5 · max(s)` adaptiv.

**Warum nicht Wolf-Jolion?** Bei sauberen Verlagsdrucken bringt der zusätzliche `M_min`-Term keinen messbaren Vorteil, kostet aber einen extra Globalwert-Pass. Für Smartphone-Fotos in v2 dann lohnenswert.

**Warum nicht Niblack?** Negatives `k` lässt Rauschen in Hintergrundbereichen (Notenrand, weiße Stellen zwischen Systemen) zu Schwarz werden. Sauvola normalisiert über `m`, was genau das verhindert.

### 1.3 Integral-Image-Trick

Sauvola in naiver Form ist O(W² · width · height). Mit **Summed Area Table** (Crow 1984, “integral image”) wird Mittelwert und Quadrate-Mittelwert in O(1) pro Pixel berechnet:

```
integral[x,y]    = Σ pixel[i,j]   für i≤x, j≤y
integral_sq[x,y] = Σ pixel[i,j]²  für i≤x, j≤y
```

Aus `integral` lassen sich `m(x,y)` und `s(x,y)` über vier Lookup-Operationen bestimmen. Das macht Sauvola praktisch genauso schnell wie Otsu.

### 1.4 Deskewing

Drei Varianten:

1. **Hough-Linien-Detektion** auf horizontalen Kanten, Median-Winkel als Skew-Schätzung.
   - Genauigkeit: ±0.1°
   - Kosten: ein Edge-Pass (Sobel) + Hough-Akkumulator. Bei 2480 × 3508 ≈ 200–400 ms in Rust.

2. **Horizontal-Projection-Profile** mit Rotation-Search.
   - Schwarzpixel-Summe pro Zeile aufsummieren, das Bild in z.B. 0.1°-Schritten zwischen −5° und +5° rotieren, jeweils die Varianz der Projektion berechnen. Maximum-Varianz = beste Ausrichtung.
   - Genauigkeit: ±0.05° (schritthängig)
   - Kosten: 100 Rotationen × Projektion. Jede Rotation ist O(N), aber Cache-unfreundlich. ~1–2 s.

3. **Stable-Paths-impliziert (Cardoso 2009)**
   - Stable Paths arbeiten direkt auf gekrümmten Notenlinien und brauchen *kein* explizites Deskewing als Vorstufe.
   - Bonus: funktioniert auch bei moderaten lokalen Verzerrungen (Buchscanner-Effekt).

**Empfehlung:**
- Für gerade gescannte Vorlagen: **kein** explizites Deskewing — direkt zu Stable-Paths gehen.
- Wenn Deskewing nötig (>2° Skew): **Hough mit beschränktem Winkelbereich** (−10°…+10°, 0.1°-Schritte). In Rust mit `imageproc::hough::detect_lines` ca. **5× schneller** als die Projection-Profile-Variante, weil ein einziger Sobel + Hough-Akkumulator-Pass ausreicht statt 100 Rotationen.

### 1.5 Noise Removal

| Filter | Wirkung | Geeignet für OMR? |
|---|---|---|
| Gauss σ=0.8 | glättet, Kanten weichen auf | nur als Vorstufe für Sobel/Canny, **nicht** vor Binarisierung |
| Median 3×3 | entfernt Salt-and-Pepper, erhält Kanten | **ja**, Standard-Pre-Sauvola-Schritt |
| Bilateral | kantenerhaltend, langsam | overkill |
| Morphologisches Opening 1×1 nach Binarisierung | entfernt isolierte Pixel | **ja** |
| Morphologisches Closing 1×1 | schließt 1-px-Lücken in Linien | **ja**, kritisch für Stable-Paths |

**Empfehlung:** Nach der Binarisierung Closing mit einem horizontalen 1×3-Strukturelement, um Notenlinien-Lücken zu schließen, gefolgt von Opening mit 1×1, um Speckle zu entfernen. **Kein** Median oder Gauss vor der Binarisierung — das verschmiert die Notenlinien.

### 1.6 Rust-Crates

| Crate | Version (Stand 2025) | Was es kann | Was es nicht kann |
|---|---|---|---|
| `image` | 0.25 | Decoding/Encoding (PNG, JPEG, TIFF, WebP), `ImageBuffer<P, Vec<u8>>` als Speicherlayout | keine Algorithmen |
| `imageproc` | 0.25 | Sauvola, Otsu, Sobel, Canny, Hough, Connected Components, Distance Transform, Median, Morphology, Template Matching | keine SIMD, kein Rayon-Default |
| `ndarray` | 0.16 | N-D-Arrays, BLAS-Integration | keine Image-Ops |
| `ndarray-image` | 0.5 | Brücke zwischen `image` und `ndarray` | nur Konvertierung |
| `fast_image_resize` | 5.x | SIMD-optimiertes Resizing | nur Resize |
| `opencv` (Bindings) | 0.94 | alles aus OpenCV via FFI | großes Build-Footprint, FFI-Overhead |

**Empfehlung Sheetstorm:** Hauptpfad in `imageproc` + `image`. Für rechenkritische Stufen (Stable-Paths-Score-Matrix, HOG-Feature-Extraction) wechseln wir zu `ndarray`, weil `ImageBuffer<Luma<u8>, Vec<u8>>` keine effiziente `axis_iter`-Semantik hat. Konvertierung via `ndarray::ArrayView2::from_shape((h,w), buf.as_raw())` ist zero-copy.

### 1.7 Performance-Schätzung A4 / 300 dpi (Rust, 1 Thread, M1/Ryzen-Klasse)

| Schritt | Zeit |
|---|---|
| Decode PNG | 80–120 ms |
| Grayscale-Konvertierung | 10 ms |
| Sauvola (Integral-Image) | 40–80 ms |
| Closing 1×3 + Opening 1×1 | 20 ms |
| Optional Hough-Deskew | 200 ms |
| **Stage 1 Total** | **~150–250 ms ohne Deskew, ~400 ms mit** |

---

## 2. Staff-Line Detection

### 2.1 Anforderungen

Eine OMR-Pipeline muss Notenlinien finden, die:
- horizontal verlaufen, aber leicht gekrümmt sein können (Buchfalz, Scan-Verzerrung),
- streckenweise unterbrochen sind (Notenhälse, Köpfe, Akzidenzen),
- gleichmäßig beabstandet sind (innerhalb eines Systems),
- in 5er-Gruppen vorkommen (Standardnotation; Schlagzeug nutzt 1- oder 5-Linien).

Die zwei Schlüsselgrößen, aus denen die gesamte restliche Pipeline ihre Toleranzen ableitet:
- `staff_space` = Abstand zwischen zwei benachbarten Notenlinien
- `line_thickness` = Dicke einer Notenlinie

Bei 300 dpi Verlagsdruck typischerweise `staff_space ≈ 9 px`, `line_thickness ≈ 1.5 px`.

### 2.2 Klassische Verfahren

**Horizontal Projection Profile** — Schwarzpixel pro Zeile zählen, Peaks finden.
- Vorteil: O(N), trivial.
- Nachteil: scheitert bei Krümmung > 1 px, da Linien-Energie über mehrere Zeilen verschmiert wird.

**Run-Length Encoding (RLE)** — Vertikale Schwarz-Runs der Länge ≤ `line_thickness + tol` als Linien-Kandidaten markieren.
- Schätzt `line_thickness` aus dem Histogramm der vertikalen Schwarz-Run-Längen (Modus = Linienstärke; zweiter Peak = Stem-Stärke ≈ 1.5–2 × Linienstärke).
- Schätzt `staff_space` aus dem Histogramm der vertikalen Weiß-Run-Längen (Modus = Zwischenraum).
- **Schritt 1 jeder seriösen OMR-Pipeline.** Liefert die Skala.

**Hough-Transform** — Linien im Parameter-Raum suchen.
- Vorteil: Toleranz gegen Rotation.
- Nachteil: scheitert bei Krümmung; teuer.

### 2.3 Stable Paths (Cardoso et al. 2009)

Die Standard-Methode für robuste Staff-Detection seit über 15 Jahren. Idee: Eine Notenlinie ist ein **stabiler horizontaler Pfad mit minimalen Kosten** durch das Bild.

#### Pseudocode (algorithmisch, nicht Rust-Syntax):

```
Eingabe: Binärbild B (Schwarz = 1 = Vordergrund), Breite W, Höhe H
Eingabe: line_thickness lt (aus RLE)
Ausgabe: Liste von 5-Linien-Staff-Systemen

# 1. Cost-Matrix bauen
für jeden Pixel (x,y):
    wenn B[y,x] == 1 und vertikaler Run an (x,y) ≤ lt + 1:
        cost[y,x] = 0    # ein "billiger" Pfadpunkt
    sonst:
        cost[y,x] = 8    # teuer: hier *nicht* langgehen

# 2. Dynamic-Programming von links nach rechts
# acc[y,x] = minimale akkumulierte Kosten, um (x,y) zu erreichen
für y in 0..H:
    acc[y,0] = cost[y,0]
für x in 1..W:
    für y in 0..H:
        # erlaubte Vorgänger: (x-1, y-1), (x-1, y), (x-1, y+1)
        acc[y,x] = cost[y,x] + min(
            acc[y-1, x-1] + diagonal_penalty,
            acc[y,   x-1],
            acc[y+1, x-1] + diagonal_penalty
        )
        link[y,x] = arg_min  # zur Backtrace

# 3. Stable Paths extrahieren
PATHS = []
wiederhole bis keine günstigen Pfade mehr gefunden werden:
    # 3a. besten Endpunkt rechts finden
    y_end = argmin_y(acc[y, W-1])
    wenn acc[y_end, W-1] / W > kosten_schwelle:  # z.B. 0.5
        break
    # 3b. Pfad rückwärts rekonstruieren
    pfad = backtrace(link, y_end)
    PATHS.append(pfad)
    # 3c. Pfad und einen vertikalen Korridor von ±lt blockieren
    für jeden (x,y) in pfad:
        für dy in -lt..+lt: cost[y+dy, x] = ∞

# 4. Pfade zu 5er-Systemen gruppieren
sortiere PATHS nach mittlerer y-Position
gruppe PATHS, deren y-Abstand zum nächsten Pfad ≈ staff_space (±20%) ist
behalte nur Gruppen mit genau 5 Linien
```

#### Rust-Implementations-Tipps

1. **Speicherlayout:** `cost`, `acc` als `ndarray::Array2<u32>` in **Spalten-Major** (`F`-Order) speichern, damit der innere Loop über `y` cache-freundlich ist. Standard `image::ImageBuffer` ist Row-Major — hier explizit mit `ndarray::Array::from_shape_vec((W,H), ...)` oder Transpose vorab.
2. **DP-Rekurrenz** vektorisieren: für eine Spalte `x` ist
   ```
   acc[:, x] = cost[:, x] + min(
       shift_down(acc[:, x-1]) + p,
       acc[:, x-1],
       shift_up(acc[:, x-1])   + p
   )
   ```
   Drei Slice-Subtraktionen + ein elementweises Min. Das ist SIMD-trivial, ca. 100 MFLOPS sind realistisch.
3. **Branch-frei min:** `let m = a.min(b).min(c);` Rust-LLVM erzeugt CMOV-Instructions, kein Branch-Misprediction-Risiko.
4. **Blocking nach Stage 4:** Statt `cost[y±lt, x] = ∞` jedes Mal die volle Matrix neu zu kopieren, einen `mask: BitVec` mitführen und `acc` nur aktualisieren, wo `mask == 0`.

#### Laufzeit

A4 / 300 dpi → 2480 × 3508 ≈ 8.7 M Pixel. Eine DP-Pass kostet ~9 M × 3 Adds + 1 Min = ~36 M Ops. In Rust mit Auto-Vektorisierung: **80–150 ms pro Pass**. Typisch 10–15 Passes bis Cost-Schwelle erreicht. **Total ~1.0–1.5 s** für Stage 2.

### 2.4 Robustheit gegen gekrümmte Linien

Stable Paths sind hier ungeschlagen, weil der DP-Pfad in jeder Spalte um ±1 Pixel wandern darf. Das integriert sich kontinuierlich zu einer Krümmung von bis zu `H/W` Anstieg, was bei A4 gut 1 cm Durchhang über die Seite bedeutet — mehr als jeder Buchscanner produziert.

Bei stärkerer Krümmung (eingescannter Buchfalz mit > 2 cm Verlust) hilft auch das nicht, dann ist eine Vorab-Dewarping nötig (Page-Curl-Korrektur via Surface-Fitting), aber das ist v3-Material.

### 2.5 CNN-Alternativen

**ScoreNet, U-Net-Varianten** (z.B. Hajič 2018, Pacha 2018) erreichen pixelweise IoU-Werte von ~0.95 für Staff-Line-Segmentation auf MUSCIMA++ und CVC-MUSCIMA. Stable Paths erreichen ~0.93. Der ML-Ansatz holt also die letzten 2 % heraus, kostet aber:

- ~5 MB ONNX-Modell
- ~100–300 ms Inferenz pro Seite (CPU, tract)
- Trainings-Pipeline + Daten

**Empfehlung:** Stable Paths in v1. CNN-Fallback erst, wenn Stable Paths empirisch < 90 % Recall liefert (auf eigenem Eval-Set messen).

---

## 3. Staff-Line Removal

### 3.1 Warum überhaupt entfernen?

Notenlinien überlagern Symbole. Connected-Component-Analyse auf nicht-entfernten Linien liefert eine einzige riesige Komponente (das ganze System), nicht einzelne Symbole. Removal ist Voraussetzung für jede komponentenbasierte Symbol-Extraktion.

### 3.2 Verfahren

**Run-Length-basiert** (Standard, schnell, gut genug):
```
für jede Spalte x:
    finde alle vertikalen schwarz-Runs
    für jeden Run der Länge ≤ line_thickness + 1:
        wenn der Run zentriert auf einer detektierten Staff-Line liegt
              UND der Run nicht Teil einer längeren Struktur ist
              (geprüft via lokale 8-Connectivity in einer Box ±2px):
            lösche den Run (setze auf Hintergrund)
```
Heuristik *“nicht Teil einer längeren Struktur”* zentral: ein Notenkopf, der von einer Linie gekreuzt wird, hat oberhalb und unterhalb des Linien-Runs weiteres Schwarz. Das schützt ihn.

**Skeleton-basiert (TopoLogical, dos Santos Cardoso 2008)**:
```
1. Skelettiere das Binärbild (Zhang-Suen oder Distance-Transform-basiert)
2. Auf dem Skelett: jede Pixel mit horizontalem Run > k·staff_space markiert als Linien-Kandidat
3. Backprojection ins Originalbild: lösche eine Box von ±line_thickness um jede Skelett-Linie
4. Schütze Knotenpunkte: wo das Skelett T-Junctions oder X-Junctions hat (also Symbol kreuzt Linie), nicht löschen.
```
- Vorteil: erhält Symbole sehr sauber, weil Junction-Detection mathematisch wohldefiniert ist.
- Nachteil: Skelettierung ist O(N · iter) und langsam (~500 ms für A4).

**Empfehlung:** RLE-basiert, mit zwei Verfeinerungen:
1. Pro Spalte den Run *nicht* einfach löschen, sondern durch den Median der ±3 Spalten ersetzen. Das rekonstruiert Notenkopf-Pixel, die zufällig auf der Linie lagen.
2. Nach Removal eine **Dilate-1px** auf dem Symbolbild, dann **Erode-1px**, um Riss-Artefakte an Symbol-Linien-Übergängen zu schließen.

### 3.3 Effekt auf Symbol-Erkennung

Tests aus Rebelo et al. 2012 (“A Method for the Optical Music Recognition…”): nach RLE-Removal mit Junction-Schutz steigt der F1-Score der nachgelagerten Notenkopf-Detektion von ~78 % (ohne Removal) auf ~92 % (mit). Skeleton-Removal liefert ~93 % — der Unterschied ist im Rauschen.

**Performance:** RLE-Removal in Rust: ~50 ms für A4.

---

## 4. Symbol Segmentation

### 4.1 Connected-Component-Labeling

**4-Connectivity vs. 8-Connectivity:** Für OMR fast immer **8**, weil Symbol-Bestandteile diagonal verbunden sein können (z.B. Hals-Notenkopf-Übergang). 4-Connectivity zerlegt einen einzelnen Notenkopf manchmal in zwei Komponenten.

**Crate:** `imageproc::region_labelling::connected_components(&img, Connectivity::Eight, background_color)` — liefert ein `GrayImage<u32>` mit Labels.

Algorithmus intern: Two-Pass Union-Find (Rosenfeld-Pfaltz). Laufzeit für A4: ~120 ms.

### 4.2 Bounding-Box-Filter

Pro Komponente das Bounding Rect berechnen, dann filtern:

| Filter | Schwelle (relativ zu `staff_space`) | Begründung |
|---|---|---|
| `min(w, h) < 0.2 · staff_space` | verwerfen | Speckle, Punkt-Noise |
| `max(w, h) > 8 · staff_space` UND `min(w,h)/max(w,h) < 0.05` | verwerfen | übersehene Notenlinien-Reste |
| `area < 0.05 · staff_space²` | verwerfen | Speckle |
| `aspect_ratio = w/h, 0.5 < aspect < 2.0` | **Notenkopf-Kandidat** | runde/elliptische Form |
| `aspect_ratio > 5` | **Beam- oder Linien-Kandidat** | langes horizontales Element |
| `aspect_ratio < 0.2` | **Stem- oder Bar-Kandidat** | langes vertikales Element |

Die Aspect-Ratio-Klassifikation ist eine *Vorab-Klassifikation* für die nachgelagerten Stages (Notenkopf, Stem, Beam getrennt verarbeiten).

### 4.3 Multi-Scale & überlappende Symbole

Akkorde, Trillerketten, eng gebundene Sechzehntel produzieren Komponenten, die zwei oder mehr Symbole umfassen. Drei Strategien:

1. **Watershed auf der Distance Transform:** Distance-Transform liefert für jeden Vordergrund-Pixel den Abstand zum nächsten Hintergrund-Pixel. Lokale Maxima sind Symbol-Zentren. Watershed-Segmentierung trennt Komponenten an den “Tälern” zwischen Maxima.
   - In Rust: `imageproc::distance_transform::distance_transform` + manueller Watershed.
2. **Vertikale Profile:** Für längliche horizontale Komponenten (Beams mit mehreren Köpfen) das vertikale Schwarz-Profil pro Spalte berechnen, lokale Minima trennen Symbole.
3. **Aufschieben auf die Klassifikations-Stage:** Statt zu früh zu segmentieren, dem Notenkopf-Detektor (Template-Matching oder HOG-Sliding) erlauben, *innerhalb* einer Komponente mehrere Treffer zu finden.

**Empfehlung:** Strategie 3 ist die einfachste und für v1 ausreichend.

---

## 5. Notehead Recognition (KERNSTÜCK!)

### 5.1 Warum kritisch?

Der Notenkopf ist das einzige Symbol, dessen **subpixel-genaue Position** über die Tonhöhe entscheidet. Bei `staff_space = 9 px` ist ein Halbton (= halber Linienabstand) **4.5 px**. Eine Verschiebung von 2 px in y-Richtung kippt also die Pitch um einen Halbton — das ist 1/12 Oktave und für Musiker hörbar und unakzeptabel.

Ziel: y-Position des Notenkopf-Zentrums auf **±0.5 px** genau.

### 5.2 Template-Matching

Der klassische, robuste Ansatz.

**Templates:**
- `filled` (Viertel/Achtel/…): elliptisch, ~`staff_space × 1.2·staff_space`, vollschwarz, leicht geneigt (~20° gegen Horizontale, das ist Notensatz-Standard).
- `open` (Halbe): elliptisch, schwarzer Rand 1.5–2 px, weiße Mitte.
- `whole` (Ganze): breitere Ellipse, ~1.5·staff_space × staff_space, schwarzer Rand mit innenseitigem Loch.

**Matching:**
- Normalisierte Kreuzkorrelation (NCC) mit `imageproc::template_matching::match_template_parallel(..., MatchTemplateMethod::CrossCorrelationNormalized)`.
- Drei separate Korrelations-Passes (filled, open, whole), pro Pass das Argmax über NMS-Fenster der Größe `0.8·staff_space`.

**Sub-Pixel-Lokalisation via parabolische Interpolation:**

Um die NCC-Karte nach dem groben Argmax `(x*, y*)` herum:
```
peak_offset_y = 0.5·(NCC[x*, y*-1] − NCC[x*, y*+1]) /
                    (NCC[x*, y*-1] − 2·NCC[x*, y*] + NCC[x*, y*+1])
peak_offset_x analog
```
Liefert ±0.05 px Genauigkeit, falls die NCC-Karte glatt ist (Gauss σ=0.5 vorab anwenden).

**Phase Correlation** wäre noch genauer, aber für den Use-Case overkill — parabolische Interpolation reicht.

### 5.3 HOG + SVM

Klassischer Machine-Learning-Ansatz, weiterhin sehr gut für Noteheads.

**Empfohlene HOG-Parameter (300 dpi, `staff_space = 9 px`):**
| Parameter | Wert | Begründung |
|---|---|---|
| Window-Size | 24 × 24 px | ≈ 2.5 · staff_space, Notenkopf + Margin |
| Cell-Size | 4 × 4 px | feine Auflösung für kleine Symbole |
| Block-Size | 2 × 2 cells (8 × 8 px) | Standard-Normalisierung |
| Block-Stride | 1 cell (4 px) | dichte Überlappung |
| Bin-Count | 9 | unsigned 0–180°, Standard |
| Feature-Vektor | 5×5 cells × 4 blocks × 9 bins ≈ 900 dim | überschaubar für SVM |

**Training:** Linear-SVM mit Hard-Negative-Mining auf MUSCIMA++ oder DeepScores. Public verfügbare HOG+SVM-Modelle für OMR sind selten, das Training muss man selbst aufsetzen (1–2 PT mit MUSCIMA++).

**Crate:** `imageproc::hog::hog` für Feature-Extraktion. SVM via `linfa-svm` oder `rusty-machine`. Klassifikator-Größe: ~10 KB.

### 5.4 CNN-basiert

**Kandidaten-Modelle:**
- **YOLOv8-nano** (3.2 M Params, 6 MB ONNX) — overkill für reine Notenkopf-Detektion, aber als Multi-Class-Symbol-Detector (Notenkopf + Schlüssel + Vorzeichen + Pause + …) attraktiv.
- **TinyDeepScores** (Pacha et al. 2018, 5 MB) — Faster-RCNN auf DeepScores-Vokabular.
- **Custom-U-Net** mit nur 2 Klassen (notehead, background): ~500 KB möglich, ~50 ms Inferenz/Seite.

**Inference in Rust:**
- `tract-onnx` (pure Rust, kein C-Dependency, gut für Cross-Compilation) — 100–200 ms für ein 5-MB-Modell auf A4.
- `ort` (ONNX Runtime FFI) — 30–80 ms, dafür großes Build-Footprint.
- `candle` — pure Rust, GPU-fähig, aber ONNX-Support noch immatur.

**Pretrained-Verfügbarkeit:** Stand 2024/2025 gibt es **kein offizielles, öffentlich gewichtetes ONNX-Modell für DeepScores 2.0**. Es gibt PyTorch-Checkpoints in Forschungs-Repos, die manuell nach ONNX exportiert werden müssen.

### 5.5 Empfehlung Sheetstorm v1

**Hybrid: Template-Matching als Primärpfad, HOG+SVM als Reranker bei Konfidenz < 0.85.**

Begründung:
- Template-Matching ist deterministisch, skalierungsrobust (wenn `staff_space` korrekt geschätzt ist), und liefert subpixel-genaue Positionen via parabolische Interpolation. Genau das, was für Pitch-Estimation nötig ist.
- HOG+SVM rettet schwierige Fälle (Notenköpfe direkt auf Linien, dicht geclusterte Akkord-Köpfe), wo NCC-Score niedrig ist.
- CNN-Pfad als v2-Erweiterung, wenn nötig.

**Aufwand:** Template-Matching ist 0.5 PT. HOG+SVM-Training (mit MUSCIMA++-Subset) 2 PT.

**Performance-Schätzung:**
- Template-Matching (3 Templates, NCC, Sliding): 200–400 ms / A4 ohne SIMD, 80–150 ms mit `imageproc::template_matching::match_template_parallel`.
- HOG+SVM für ~50 Konfidenz-Hard-Cases: 50 ms.

---

## 6. Stem & Beam Detection

### 6.1 Stems (Notenhälse)

**Vertikales Run-Length-Tracking:**

```
für jede Spalte x:
    finde alle vertikalen schwarz-Runs der Länge ≥ 2.5·staff_space
    und Breite (geschätzt durch lokale horizontale Run-Länge an y-Mitte) ≤ 2·line_thickness
    → Stem-Kandidat
für jeden Notenkopf NK:
    suche Stem-Kandidaten in Box [NK.x ± staff_space, NK.y ± 4·staff_space]
    falls Stem rechts und unten von NK → Stem-down
    falls Stem links und oben von NK → Stem-up
```

`line_thickness` aus Stage 2 nutzen. Stems sind typisch 1.5–2 × `line_thickness` breit.

**Hough vs. lokales Tracking:** Hough ist für Stems übertrieben — sie sind kurz, gerade und ihre x-Position ist durch den Notenkopf bekannt. Lokales Tracking entlang y ist 10× schneller.

### 6.2 Beams (Balken)

Beams sind dicke horizontale Balken, die mehrere Stems verbinden (Achtel/Sechzehntel/…).

**Erkennung:**
```
Filtere Connected Components mit aspect_ratio > 5 und h > 0.5·staff_space
für jeden Beam-Kandidaten:
    finde alle Stems, deren x in [Beam.x_left, Beam.x_right] liegt
    und deren y-Endpunkt innerhalb Beam.y ± h liegt
    → diese Stems sind durch den Beam verbunden
zähle Beam-Layer:
    untersuche das vertikale Profil der Beam-Komponente
    → ein Layer = ein Strich → 1 Layer = Achtel, 2 = Sechzehntel, …
```

**Heuristik für Layer-Zählung:** Mittlere Beam-Höhe `h_beam`. Wenn die Komponente vertikal `n · h_beam + (n-1) · gap` hoch ist (mit `gap ≈ h_beam`), dann hat sie `n` Layer.

### 6.3 Performance

Stems + Beams: 50 ms für A4.

---

## 7. Pitch Estimation

### 7.1 Notenkopf → Linien-Position → Pitch

Pro detektiertem Notenkopf-Zentrum `(x_n, y_n)`:

```
1. Finde das umgebende Staff-System S (5 Linien y_1 < y_2 < ... < y_5)
2. Interpoliere die lokale Linien-Position bei x = x_n:
       für jede Linie L_i: y_L_i(x_n) = lineare Interpolation entlang L_i
3. Berechne die "Linien-Index"-Position p:
       staff_position = 2 · (y_n − y_L_3(x_n)) / staff_space
   → p = 0 bedeutet exakt auf Mittellinie
   → p = +1 bedeutet eine halbe Stufe (ein Halbtonschritt im Notensystem) tiefer
   → ganzzahliges p = auf Linie, halbzahliges p = im Zwischenraum
4. Lookup in Schlüssel-Tabelle (G-, F-, C-, …):
       für G-Schlüssel: p=0 → B4 (deutsch H4), p=+1 → A4, …
5. Akzidenz-Korrektur:
       prüfe, ob links vom Notenkopf in derselben Maße/Stufe ein ♯/♭/♮ steht
       wende auf die diatonische Pitch an
6. Tonart-Korrektur (Key Signature):
       für jeden Notennamen ohne explizite Akzidenz: nutze Vorzeichen aus key
```

### 7.2 Sub-Notenlinien-Genauigkeit

Sub-Pixel-y-Position des Notenkopfs (aus parabolischer Interpolation, Stage 5) **direkt** in `staff_position` einsetzen. Dann auf `round(2·staff_position) / 2` runden — das ergibt die nächstgelegene Halb-Stufe.

**Anti-Halbton-Fehler:** Wenn `|staff_position − round(2·staff_position)/2| > 0.25`, ist die Detektion unsicher → flag setzen, in Eval-Report aufnehmen.

### 7.3 Ledger Lines (Hilfslinien)

Ledger Lines sind kurze Hilfslinien außerhalb des 5-Linien-Systems für hohe/tiefe Töne.

**Erkennung:**
```
für jeden Notenkopf NK mit |staff_position| > 5 (außerhalb des Systems):
    suche horizontale Schwarz-Runs der Länge ≈ 2·staff_space
    in der Box [NK.x ± 1.5·staff_space, NK.y ± 0.5·staff_space]
    → Ledger Line gefunden
   → bestätige die staff_position via Ledger-Line-y-Position
```

Ledger Lines werden bei Staff-Removal in Stage 3 entfernt — daher müssen sie *vor* Removal extra erkannt und gespeichert werden, oder das Original-Binärbild bleibt verfügbar.

---

## 8. Duration Estimation

### 8.1 Notenkopf-Typ

Klassifikation `filled` vs. `open` durch:
- **Foreground-Ratio** im Bounding-Box des Notenkopfs:
  - `> 0.7` → filled (Viertel und kürzer)
  - `< 0.5` → open (Halbe / Ganze)
- **Whole** vs. **Half** durch An-/Abwesenheit eines Stems:
  - kein Stem + open → whole
  - mit Stem + open → half

Schwellen empirisch zu kalibrieren; in Praxis sind die Modi sehr getrennt.

### 8.2 Kombinationsregeln

```
notehead_filled UND kein_stem                        → unmöglich, Fehler
notehead_filled UND stem UND keine_flags UND kein_beam → quarter (1/4)
notehead_filled UND stem UND 1 flag                  → eighth (1/8)
notehead_filled UND stem UND 2 flags                 → sixteenth (1/16)
notehead_filled UND stem UND beam_layers=1           → eighth
notehead_filled UND stem UND beam_layers=2           → sixteenth
notehead_filled UND stem UND beam_layers=n           → 1/(2^(n+2))
notehead_open UND stem                               → half (1/2)
notehead_open UND kein_stem                          → whole (1/1)
+ jeder Augmentationspunkt rechts → ×1.5
+ Triolenkennzeichnung („3“ über Beam) → ×2/3
```

**Flags:** kleine geschwungene Striche am Stem-Ende. Erkennung als Connected Component am Stem-Top/Bottom mit Aspect-Ratio < 1 und Pixelflächeninhalt < 0.5·staff_space².

### 8.3 Tuplets

Triolen, Quintolen, Sextolen erkennt man am **Zahl-Glyph + Bracket** über/unter der Note-Gruppe.

**Heuristik:**
```
suche nahe einer beam_group nach kleinem Zahl-Symbol (Glyph)
falls Zahl in {3, 5, 6, 7}: Tuplet vom Grad n erkannt
korrigiere Dauer aller Noten der Gruppe um Faktor 2/3 (Triole)
oder allgemein durch Tuplet-Tabelle
```

Zahl-Erkennung via separates kleines CNN-Klassifikator-Modell oder Template-Match auf Standard-Notensatz-Glyphen.

In v1 reicht es, Tuplets *zu kennzeichnen* aber zunächst als normale Achtel/Sechzehntel zu exportieren — MusicXML kann das Tuplet auch nachträglich annotieren.

---

## 9. Voice / Layer Reconstruction

### 9.1 Heuristiken

**Stem-Richtung:** Stem-up = Stimme 1, Stem-down = Stimme 2 (sehr robust für 2-stimmige Sätze in einem System, z.B. Sopran/Alt).

**Vertikale Position:** wenn nur Stem-up vorhanden, aber zwei vertikal getrennte Notenkopf-Cluster: oberer = Stimme 1, unterer = Stimme 2.

**Zeitliche Verträglichkeit:** Innerhalb einer Stimme müssen die Notendauern an jeder Zeitposition aufgehen. Wenn an Beat *t* zwei Köpfe stehen, die nicht zu einem Akkord gehören (vertikal weit getrennt → unterschiedliche Pitches), dann sind das zwei Stimmen.

**Akkord-Detektion:** Mehrere Notenköpfe an *demselben* Stem (innerhalb ±0.5·staff_space horizontal) → Akkord, eine Stimme.

### 9.2 Polyphonie

Realistisch trennbar in einer Pipeline-OMR:
- **Klavier (2 Systeme, je 2 Stimmen)**: gut.
- **Streichquartett auf 1 System pro Stimme**: sehr gut.
- **Chor-Partitur (4 Stimmen auf 2 Systemen)**: machbar mit Stem-Direction-Heuristik.
- **Orgel-Partitur (3 Systeme, Pedal + Manual)**: schwierig, oft nur das obere System belastbar.

Über 2 Stimmen pro System wird Pipeline-OMR unzuverlässig — End-to-End-Modelle (Sheet Music Transformer) sind dort besser.

---

## 10. MusicXML Export

### 10.1 Format-Wahl: Score-Partwise

**Score-Partwise vs. Score-Timewise:** Score-Partwise (pro Part die Maße sequenziell) ist der **De-facto-Standard** und wird von MuseScore, OSMD, Sibelius, Finale, Dorico und allen Web-Renderern (VexFlow, OpenSheetMusicDisplay) gelesen. Score-Timewise (pro Maß alle Parts) ist legal, aber praktisch keine Software akzeptiert es als einzige Form.

→ **Immer Score-Partwise.**

### 10.2 Minimal valides MusicXML 4.0

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE score-partwise PUBLIC
  "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
  "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="4.0">
  <part-list>
    <score-part id="P1"><part-name>Music</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note>
        <pitch><step>C</step><octave>4</octave></pitch>
        <duration>4</duration>
        <type>quarter</type>
      </note>
      <!-- weitere notes / rests -->
    </measure>
  </part>
</score-partwise>
```

**Pflichtelemente:**
- `<score-partwise version="4.0">` Root mit Version-Attribut
- `<part-list>` mit mindestens einem `<score-part id="P*">`
- `<part id="P*">` matched zur ID
- pro `<part>` mindestens eine `<measure number="*">`
- in der **ersten** Maße eines Parts: `<attributes>` mit
  - `<divisions>` (PPQ — pulses per quarter; üblich 4, 8, 16, oder 480 für DAW-Kompat)
  - `<key><fifths>n</fifths></key>` (n ∈ −7…+7)
  - `<time><beats>·</beats><beat-type>·</beat-type></time>`
  - `<clef><sign>·</sign><line>·</line></clef>`

Pro `<note>` ist Minimum: `<pitch>` (oder `<rest/>`), `<duration>`, `<type>`. Akkord-Köpfe haben `<chord/>` als Marker (alle Köpfe außer dem ersten).

### 10.3 Rust-Crate

| Crate | Stärke | Schwäche |
|---|---|---|
| `quick-xml` 0.36 | sehr schnell, streaming, kontrolliertes Output-Format | manuelles Element-Bauen |
| `xml-rs` 0.8 | seit Jahren stabil | langsamer |
| `serde-xml-rs` | Derive-Macros | output-Reihenfolge nicht kontrollierbar (kritisch für DTD-Validität) |
| `yaserde` | Derive-Macros, ordentliche Reihenfolge | mehr Boilerplate |

**Empfehlung:** **`quick-xml`** mit `Writer`-API, manuell Element für Element bauen. Das ist nur ~300 Zeilen für vollen MusicXML-Export und liefert byte-identisch reproduzierbares Output.

### 10.4 Reader-Robustheit testen

Output gegen MuseScore 4 (Round-Trip), Verovio (Web-Renderer) und OpenSheetMusicDisplay (JS) testen. Die drei haben unterschiedliche Toleranzen gegenüber:
- fehlendem `<duration>` bei Grace Notes
- `<voice>`-Elementen (MuseScore mag sie, OSMD ignoriert sie)
- `<staff>`-Elementen bei Multi-Staff-Parts (Klavier)

---

## 11. End-to-End Modelle (alternative zur Pipeline)

### 11.1 Sheet Music Transformer (Ríos-Vila et al. 2024)

- Architektur: Image-to-Sequence-Transformer, ähnlich Vision-Transformer + Encoder-Decoder.
- Trainiert auf **GrandStaff** (Klavier-Pages) und **Quartets** (Streichquartett-Systeme).
- Reported State-of-the-Art für **polyphone** OMR, übertrifft Calvo-Zaragoza-CRNN für Mehrstimmigkeit.
- Reale Genauigkeit auf eigenen Daten (nicht im Trainingsset): typisch **70–85 % Symbol-Accuracy**, deutlich abhängig von Drucksatz-Stil (Verovio-trainiert vs. Lilypond vs. Verlagsdruck).
- Modellgröße: ~50 M Parameter, ONNX ~200 MB. **Zu groß für mobile Inferenz**, OK für Server-Side.

### 11.2 CRNN+CTC (Calvo-Zaragoza/Rizo 2018)

- Klassische monophone OMR-Baseline.
- Trainiert auf **PrIMuS** (~87.000 monophone Snippets).
- ~2 % Symbol-Error-Rate auf Camera-PrIMuS — also ~98 % Accuracy.
- Limit: nur monophon. Versagt bei Akkorden, mehrstimmigen Takten.
- Modellgröße: ~5 M Params, ONNX ~20 MB — passt für lokale Inferenz.

### 11.3 DeepScores 2.0

- Datenset von 255.000 synthetisch generierten Pages mit Bounding-Box-Annotationen für ~135 Symbol-Klassen.
- Pretrained-Modelle (Faster-RCNN, RetinaNet) sind in Forschungs-Repos vorhanden, **nicht** als offizielle ONNX-Releases. Manuelle Konvertierung nötig.
- Eignung: Symbol-Detection-Stage (Stage 5–6 der Pipeline).

### 11.4 Empfehlung

**Pipeline-Architektur mit ML-Fallback in der Klassifikations-Stufe ist die beste Balance.** Reine End-to-End-Modelle:
- haben unzuverlässige Confidence-Schätzungen (man weiß nicht *welche* Note falsch ist),
- sind in ihrem Output undeterministisch (Ausgaben können Reihenfolge-Inkonsistenzen haben),
- sind teuer im Inferenz-Pfad.

Pipeline-OMR mit klassischen Stufen (Sauvola → Stable Paths → Removal → CC → Notehead+Stem+Beam) und einem optionalen CNN-Re-Klassifikator für ambivalente Fälle liefert:
- 80–90 % Note-Accuracy auf sauberen Verlagsdrucken,
- pro-Symbol-Konfidenz (für UI-Korrektur-Hinweise),
- 2–5 s Laufzeit pro A4 (statt 30 s mit großem Transformer),
- deterministisches, debugbares Verhalten.

End-to-End wird in v3 interessant, sobald Daten und Server-GPU vorhanden.

---

## 12. Performance-Optimierung in Rust

### 12.1 Audiveris-Schwächen (Java)

- **Garbage-Collected Heap:** Image-Buffer-Allocation und -Free pro Pipeline-Stufe verursachen GC-Pausen.
- **Single-Thread-Pipeline:** trotz Java-Threads ist die Audiveris-Pipeline überwiegend sequenziell.
- **JIT-Warmup:** erste Seite langsamer als folgende.
- **Java-Object-Overhead:** `int[][]` ist teurer als `&[u32]` (Header pro Sub-Array).

### 12.2 Wo Rust 5–10× gewinnt

- **Pixel-Iteration ohne Bounds-Check:** Mit `unsafe { *buf.get_unchecked(i) }` oder `chunks_exact`-Iterator-Pattern fallen die Bounds-Checks weg. LLVM kann dann SIMD-Auto-Vektorisieren.
- **SIMD via `wide` (stable) oder `std::simd` (nightly):** Sauvola-Mittelwert, NCC-Korrelation, HOG-Histogramme alle SIMD-freundlich.
  - Beispiel: NCC-Inner-Loop von ~600 MFLOPS auf ~3 GFLOPS mit AVX2.
- **Multi-Threading via `rayon`:** `par_iter` über Bildzeilen oder Kacheln. Sauvola, Template-Matching, Connected-Components-Labeling sind alle parallelisierbar.
- **No-Heap-Allocation in Hot Loops:** vorab allozierte `Vec`s wiederverwenden statt `vec![]` pro Pixel.

### 12.3 Speicher-Layout

| Layout | Vorteil | Nachteil |
|---|---|---|
| `image::ImageBuffer<Luma<u8>, Vec<u8>>` | Standard, viele Crates kompatibel | Pixel-Wrapper-Type, kleiner Overhead bei `pixel(x,y)` |
| `ndarray::Array2<u8>` | starke Slice-Ops, `axis_iter`, BLAS | externe Konvertierung zu `image` |
| `Vec<u8>` flach + `(W, H)` | minimal, maximal kontrolliert | manuell |

**Empfehlung:** `image::ImageBuffer` als Storage-Layer (Decoding/Encoding), für Hot-Loop-Algorithmen ein **zero-copy `ndarray::ArrayView2`** darüber legen. So nutzen wir die Ergonomie von `ndarray` (Slicing, `axis_iter`, broadcasting) ohne Daten zu kopieren.

### 12.4 Mess-Schätzungen Sheetstorm-Pipeline (A4, 300 dpi, Single-Core M1/Ryzen-Klasse)

| Stufe | Zeit |
|---|---|
| Decode + Grayscale | ~100 ms |
| Sauvola + Morphology | ~70 ms |
| RLE-Stats (line_thickness, staff_space) | ~30 ms |
| Stable Paths (10 Pässe) | ~1.0–1.5 s |
| Staff-Line Removal | ~50 ms |
| Connected Components | ~120 ms |
| Notehead Template-Matching (3 Templates) | ~150 ms (parallel) |
| HOG-Reranker (Hard-Cases) | ~30 ms |
| Stem + Beam Detection | ~50 ms |
| Pitch + Duration Inference | ~10 ms |
| MusicXML Export | ~20 ms |
| **Total** | **~1.6–2.2 s** |

Mit Multi-Core (`rayon`) auf 4 Threads realistisch **~0.8–1.2 s** — mehr als 5× schneller als Audiveris auf gleichem Material (Audiveris liegt typisch bei 8–15 s pro A4-Seite).

---

## 13. Ground-Truth & Eval

### 13.1 OMR-Edit-Distance (Calvo-Zaragoza)

Standard-Metrik für sequenzielle OMR-Outputs.

```
Eingabe: gt_seq = [Symbol, ...]   # Ground-Truth-Symbolfolge
         pr_seq = [Symbol, ...]   # Predicted

# Wagner-Fischer DP
N = len(gt_seq); M = len(pr_seq)
D = (N+1) × (M+1) Matrix
D[0,j] = j; D[i,0] = i
für i in 1..=N:
    für j in 1..=M:
        D[i,j] = min(
            D[i-1, j]   + 1,                                   # delete
            D[i,   j-1] + 1,                                   # insert
            D[i-1, j-1] + (0 wenn gt_seq[i] == pr_seq[j] sonst 1)  # subst
        )

SER = D[N, M] / N
```

Symbole sind dabei Tupel `(Type, Pitch, Duration)` — kein einfacher String. Die Identitätsprüfung kann parametrisierbar sein: nur Type, Type+Pitch, Type+Pitch+Duration usw.

**Crate-Empfehlung:** Levenshtein-Crates wie `strsim` operieren auf Strings. Für Symbol-Tupel selbst implementieren — 50 Zeilen Wagner-Fischer.

### 13.2 MV2H

**Multi-pitch / Voice / Meter / Harmony.** Vier separate Sub-Scores für tiefere Diagnose:
- `multi_pitch_F1`: Pitch-Set pro Zeitschritt
- `voice`: Stimmen-Zuordnung
- `meter`: Takt-Strukturierung
- `harmony`: harmonische Funktion

MV2H ist sinnvoll, wenn das Output-Format MIDI-/Performance-orientiert ist. Für notensatzorientiertes Sheetstorm-OMR ist **Note-Accuracy + SER** ausreichend.

### 13.3 MusicXML-Diff

Music21 (Python) hat `corpus.compare()` und Stream-Diff. In Rust gibt es das **nicht**.

**Eigenimplementation, minimal:**
```
1. Parse beide MusicXML in Sequenz (Part × Measure × Voice → Note-Liste)
2. Für jede Voice-Sequenz: Wagner-Fischer auf Tupel (Pitch, Duration, OnsetBeat)
3. Pro Part F1-Score: 2·Match / (Match·2 + Insertions + Deletions + Substitutions)
4. Globaler Score = gewichteter Mittelwert über alle Parts
```

Eval-Tooling sollte **separate Test-Crate** sein, die die OMR-Pipeline aufruft und gegen ein Set bekannter Verlagsdrucke + GT-MusicXML scort. Anfangs MUSCIMA++ (handwritten, schwer) und PrIMuS (synthetisch, leicht) als Bandbreite.

---

## 14. Konkrete Empfehlung für Sheetstorm v1

### 14.1 Algorithmen-Stack

| Stage | Algorithmus | Crate | Parameter |
|---|---|---|---|
| Decode | PNG/JPEG → Luma8 | `image` 0.25 | – |
| Pre-Filter | Closing 1×3 | `imageproc` 0.25 | – |
| Binarization | Sauvola (Integral-Image) | eigene impl auf `imageproc` | window=25, k=0.34, R=128 |
| RLE-Stats | line_thickness + staff_space | eigene impl | Schwarz/Weiß-Run-Modi |
| Staff Detection | Stable Paths (Cardoso 2009) | eigene impl auf `ndarray` | diagonal_penalty=2, cost_threshold=0.5 |
| Staff Removal | RLE-basiert mit Junction-Schutz | eigene impl | run_len ≤ line_thickness+1 |
| Connected Components | 8-Connectivity | `imageproc::region_labelling` | – |
| BBox-Filter | aspect/area-Heuristik | eigene impl | siehe §4.2 |
| Notehead | NCC-Template (filled, open, whole) + parabol. Subpixel | `imageproc::template_matching` | Templates aus `staff_space` skaliert |
| Notehead-Reranker | HOG+SVM | `imageproc::hog` + `linfa-svm` | win=24, cell=4, block=8, bins=9 |
| Stems | vertikales RLE-Tracking | eigene impl | min_length=2.5·staff_space |
| Beams | CC-aspect-filter + Layer-Counting | eigene impl | min_aspect=5 |
| Pitch | Linien-Lookup + Subpixel | eigene impl | – |
| Duration | Notehead-Type + Stem + Flag/Beam | eigene impl | – |
| Voice | Stem-Richtung + y-Cluster | eigene impl | – |
| MusicXML Export | Score-Partwise, Quick-XML | `quick-xml` 0.36 | `<divisions>4</divisions>` Standard |
| Eval | Wagner-Fischer auf Symbol-Tupel | eigene impl | – |

### 14.2 Realistische Genauigkeit auf sauberen Verlagsdrucken

- **Pitch-Accuracy:** 92–95 %
- **Duration-Accuracy:** 88–92 %
- **Combined Note-Accuracy** (Pitch + Duration korrekt): **80–88 %**
- **Voice-Accuracy** (bei 2 Stimmen): 75–85 %

Auf handgeschriebenen Manuscript-Scans dramatisch schlechter (typisch 50–70 % Note-Accuracy) — das ist v3-Material mit ML-Fallback.

### 14.3 Aufwand

| PT | Inhalt |
|---|---|
| 0.5 PT | Pre-Processing + Binarization + RLE-Stats |
| 1.0 PT | Stable Paths + Removal |
| 0.5 PT | Connected Components + BBox-Filter |
| 0.5 PT | Notehead Template-Matching + Subpixel |
| 0.5 PT | Stems + Beams + Pitch + Duration |
| 0.5 PT | MusicXML Export |
| 0.5 PT | Eval-Tooling (SER, Note-Accuracy) |
| **4.0 PT** | **v1, ohne HOG-Reranker** |

HOG-Reranker (Training + Integration) zusätzlich 1.5–2 PT, lohnt sich erst, wenn v1-Eval stabil läuft und Hard-Cases identifiziert sind.

### 14.4 Performance-Schätzung

- **A4 / 300 dpi / 1 Thread:** 1.6–2.2 s
- **A4 / 300 dpi / 4 Threads (rayon):** 0.8–1.2 s
- **Speicher-Footprint:** ~150 MB Peak (Bild + Cost-Matrix + Acc-Matrix für Stable Paths)

---

## 15. 5-Punkt-Action-List

Was als erstes implementieren:

1. **Sauvola-Binarisierung mit Integral-Image-Trick implementieren und gegen Otsu auf einem 10-Seiten-Verlagsdruck-Sample benchmarken.** Liefert die Skala (`staff_space`, `line_thickness`) und ist Voraussetzung für alles andere. Akzeptanzkriterium: Notenlinien sind als zusammenhängende Schwarz-Runs sichtbar, Notenköpfe als einzelne Komponenten klar trennbar — visuell auf 3 Test-Bildern überprüfen.

2. **RLE-Stats-Modul:** vertikale Schwarz-Run-Längen-Histogramm + Weiß-Run-Längen-Histogramm → robuste Schätzung von `line_thickness` und `staff_space`. Akzeptanzkriterium: ±1 px Abweichung gegenüber manueller Messung auf 10 Test-Bildern.

3. **Stable-Paths-Implementierung mit `ndarray::Array2<u32>` als Cost-Matrix.** Kern-DP-Loop SIMD-freundlich strukturieren (Spalten-Major, Slice-Min). Akzeptanzkriterium: 100 % Recall der 5er-Linien-Systeme auf 10 Test-Bildern, < 2 s Laufzeit pro A4 Single-Thread.

4. **Eval-Tooling parallel zur Pipeline aufbauen:** Wagner-Fischer auf Symbol-Tupeln, MUSCIMA++- oder PrIMuS-Subset als Eval-Set, Symbol-Error-Rate und Note-Accuracy als Pflicht-Metriken. Ohne diese Infrastruktur ist Pipeline-Tuning blind. Akzeptanzkriterium: pro PR ein automatischer SER-Score als CI-Metrik.

5. **Notehead-Template-Matching mit NCC + parabolische Subpixel-Lokalisation.** Drei Templates (filled / open / whole) zur Laufzeit aus `staff_space` synthetisieren. Akzeptanzkriterium: ≥ 90 % Notehead-Recall + ≤ 0.5 px Median-Y-Fehler vs. manuell annotiertem Sample. Erst danach Stems/Beams/Pitch/Duration angehen.

---

**Stand:** Recherche-Snapshot 2025. Quellen: Cardoso et al. 2009 *“Staff Detection with Stable Paths”* (TPAMI), Rebelo et al. 2012 *“Optical Music Recognition: state-of-the-art and open issues”* (IJMIR), Pacha 2018 *“A survey on optical music recognition”* (arXiv:1805.00750), Calvo-Zaragoza & Rizo 2018 *“End-to-End Neural Optical Music Recognition of Monophonic Scores”* (Applied Sciences), Ríos-Vila et al. 2024 *“Sheet Music Transformer”* (arXiv:2402.07596), Sauvola & Pietikäinen 2000 *“Adaptive document image binarization”* (Pattern Recognition). Crate-Versionen geprüft auf crates.io Stand 2024/2025.

STATUS: DONE
