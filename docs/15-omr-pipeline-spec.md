# 15 — OMR-Pipeline-Spezifikation (Eigenimplementation in Rust)

> **Status:** Entwurf / Recherche-Spezifikation
> **Adressaten:** Backend-Architekt, ML/CV-Spezialist, Rust-Implementer
> **Ziel:** Technische Grundlage für eine eigenentwickelte Optical-Music-Recognition-Pipeline für Sheetstorm. Dieser Text ist **konzeptionell** — er beschreibt Algorithmen, Datenstrukturen und Architektur, **nicht** Code aus existierenden Projekten. Insbesondere wurde **kein Audiveris-Quellcode (AGPL)** gelesen oder kopiert; alle hier beschriebenen Algorithmen entstammen frei verfügbarer wissenschaftlicher Literatur und allgemeinem CV-Wissen.

---

## 1. Übersicht & Anforderungen

### 1.1 Eingabe / Ausgabe

| Aspekt | Spezifikation |
|--------|---------------|
| **Eingabe** | PDF-Seiten (rasterisiert mit `pdfium`/`mupdf` zu 300 dpi PNG) **oder** PNG/JPEG-Scans |
| **Eingabe-DPI** | Empfohlen ≥ 300 dpi, intern auf eine Ziel-Stafflinien-Höhe normalisiert (siehe §2.1) |
| **Eingabe-Domäne** | Gedruckte Blasmusik-Stimmen (1 Instrument pro Stimme, 1–2 Systeme pro Zeile, monophon bis leicht polyphon) |
| **Ausgabe** | MusicXML 4.0 `score-partwise` |
| **Sekundär-Ausgabe** | JSON-Debug-Trace pro Pipeline-Stufe (Bounding-Boxes, Klassifikations-Confidence) für UI-Reviewer |

### 1.2 Performance- und Qualitätsziele

| Ziel | Wert | Begründung |
|------|------|------------|
| **Latenz** | < 30 s pro DIN-A4-Seite (1 CPU-Kern, x86-64, 300 dpi) | Nutzer wartet bei Upload synchron; bei mehreren Seiten parallelisierbar |
| **Speicher** | < 1 GB RAM pro Seite | Container-tauglich (Aspire-Sidecar) |
| **Genauigkeit (sauberer Verlagsdruck)** | > 95 % korrekt erkannte Tonhöhen + Dauern auf Notenebene | Vergleichbar mit kommerziellem Niveau; Note-Edit-Distance als Metrik |
| **Genauigkeit (gute Scans, 300 dpi, leichte Schiefe)** | > 80 % | Realistisch nach OMR-Survey 2020 |
| **Genauigkeit (handgeschrieben / stark degradiert)** | **explizit nicht garantiert** | Out of scope für v1 |

### 1.3 Realismus-Disclaimer (ehrliche Einschätzung)

OMR ist **schwer**. Selbst kommerzielle Systeme (PhotoScore, SmartScore, capella-scan) erreichen auf realen Scans selten dauerhaft > 95 % auf Note-Ebene; Audiveris liegt je nach Material zwischen 70 % und 95 %. **Note-Level-Accuracy ist multiplikativ:** Wenn jede Stufe (Staff-Detection, Notehead, Pitch, Duration) zu 98 % korrekt ist, kommen am Ende ~92 % heraus. Eine Eigenimplementation, die in 6–12 Personenmonaten entsteht, erreicht realistisch **70–85 %** auf Verlagsdruck und **50–70 %** auf typischen Vereinsarchiv-Scans. Für Sheetstorm ist das nur dann ausreichend, wenn ein **menschlicher Review-Step** in der UI vorgesehen ist (Notewise-Edit nach OSMD-Anzeige).

---

## 2. Pipeline-Stufen

Die klassische OMR-Pipeline (Rebelo et al. 2012; Calvo-Zaragoza/Hajič/Pacha 2020) gliedert sich in vier Hauptphasen — Preprocessing, Music Object Detection, Notation Reconstruction, Score Encoding — die wir in 12 ausführbare Stufen unterteilen. Jede Stufe hat ein klar definiertes Input/Output-Tensor- bzw. Datenstruktur-Profil.

```
PDF/PNG
  │
  ▼ §2.1
[1] Preprocessing  ──►  Grayscale + Binary + Skew-korrigiertes Image
  │
  ▼ §2.2
[2] Staff-Line Detection  ──►  StaffSystem[] mit StaffLine-Koordinaten
  │
  ▼ §2.3
[3] Staff-Line Removal    ──►  Symbol-only Binary Image
  │
  ▼ §2.4
[4] Symbol Segmentation   ──►  SymbolCandidate[] (Bounding-Boxes)
  │
  ▼ §2.5
[5] Symbol Classification ──►  ClassifiedSymbol[]
  │
  ├─►[6] Notehead Recognition (Spezialisierung)
  ├─►[7] Stem & Beam Detection
  ▼ §2.8
[8] Pitch Estimation      ──►  Note.pitch
  │
  ▼ §2.9
[9] Duration Estimation   ──►  Note.duration
  │
  ▼ §2.10
[10] Symbol Reconstruction ──►  Clef, Key, Time, Articulations bound to notes
  │
  ▼ §2.11
[11] Voice/Layer Reconstruction
  │
  ▼ §2.12
[12] MusicXML Export      ──►  score-partwise.xml
```

---

### 2.1 Image Preprocessing

**Input:** RGB/Grayscale-Bild (PNG/PDF-Page-Render)
**Output:** Binäres Bild (1 bpp), Grayscale-Original, geschätzte Stafflinien-Dicke `staffLineHeight` und Stafflinien-Abstand `staffSpace`.

#### Algorithmen

1. **Grayscale-Konvertierung** — Standard-Luminanz-Formel `Y = 0.299R + 0.587G + 0.114B`.
2. **Background-Removal** — Subtraktion eines morphologischen Openings mit großem Kernel (z. B. 51×51), um Schatten und Papierfärbung zu entfernen.
3. **Binarisierung** — drei Verfahren wählbar, automatischer Fallback:
   - **Otsu** (global): `T = argmax_T (σ_b²(T))` über Histogramm. Schnell, gut für sauberen Druck.
   - **Sauvola** (lokal): `T(x,y) = m(x,y) · [1 + k · (s(x,y)/R − 1)]` mit `k=0.34`, `R=128`, Window 25×25. Robust gegen ungleichmäßige Beleuchtung. Berechnung in `O(W·H)` über *integral images* (Crow 1984).
   - **Niblack** (lokal): `T(x,y) = m(x,y) + k · s(x,y)` mit `k=−0.2`. Empfindlicher als Sauvola, gut für sehr dünnen Druck.
4. **Skew-Detection / Deskewing**
   - Berechne horizontale Projektionsprofile bei rotierten Winkeln `θ ∈ [−10°, +10°]` in 0.1°-Schritten. Der Winkel mit der höchsten **Varianz** des Profils ist der Schiefwinkel (Postl 1986).
   - Alternative: Hough-Transform auf den längsten Linien-Segmenten.
   - Rotation per **bilinearer Interpolation**.
5. **Staff-Höhen-Schätzung** — Run-Length-Encoding (RLE) jeder Spalte: häufigster Schwarz-Run-Length = `staffLineHeight`, häufigster Weiß-Run zwischen zwei Schwarz-Runs = `staffSpace`. Diese beiden Konstanten kalibrieren *alle* nachfolgenden Stufen (Skalen-invariant!).

#### Pseudo-Code (Sauvola)

```
function sauvola_threshold(image, w, k=0.34, R=128):
    II  ← integral_image(image)
    II2 ← integral_image(image²)
    binary ← new_image(image.size)
    for each pixel (x, y):
        sum   ← box_sum(II,  x-w/2, y-w/2, w, w)
        sum2  ← box_sum(II2, x-w/2, y-w/2, w, w)
        n     ← w*w
        m     ← sum / n
        s     ← sqrt(sum2/n - m²)
        T     ← m * (1 + k*(s/R - 1))
        binary[x,y] ← (image[x,y] < T) ? 1 : 0
    return binary
```

#### Komplexität & Schwächen

- Sauvola/Otsu: `O(W·H)` (linear, mit Integralbildern).
- Skew-Suche: `O(N_θ · W · H)` — bei 200 Winkeln und A4@300dpi ≈ 1.5 G-ops, parallelisierbar pro Winkel.
- **Schwächen:** Sauvola verliert sehr feine Notenstiele bei zu großem Window; Otsu versagt bei ungleicher Beleuchtung; Skew per Projektion versagt bei stark gekrümmten Seiten (Buchscan-Falz) → dort Stafflinien-basierte De-Warping nötig (Dewarping out of scope für v1).

---

### 2.2 Staff-Line Detection

**Input:** Binäres Bild + `staffLineHeight`, `staffSpace`.
**Output:** Liste von `StaffSystem` mit jeweils 5 `StaffLine`-Polylines.

#### Algorithmen-Klassen

| Ansatz | Prinzip | Stärken | Schwächen |
|--------|---------|---------|-----------|
| **Horizontal Projection** | Zeilensumme schwarzer Pixel; Peaks = Stafflinien | Sehr schnell `O(W·H)` | Versagt bei Schiefe / gekrümmten Linien |
| **Run-Length Coding (RLC)** | Spaltenweises RLE; Stafflinien als horizontale Run-Cluster | Robust gegen kleine Schiefe | Aufwändiger bei Bruchstücken |
| **Hough-Transform** | Linien in `(ρ, θ)`-Raum | Robust gegen Rauschen | `O(W·H·N_θ)`, Speicher-intensiv |
| **Stable Paths** (Cardoso et al. 2009) | Dynamic-Programming-Pfad mit minimalen Kosten von links nach rechts; Pixel-Kosten ∝ 1/Schwärze | Hervorragend bei gekrümmten und unterbrochenen Linien | Komplexere Implementierung |

**Empfehlung für Sheetstorm v1:** **RLC + Stable-Paths-Verfeinerung**. RLC liefert grobe Kandidaten, Stable Paths verfeinern die Linien-Pfade pixelgenau. Cardoso/Capela/Rebelo (2009, ICDAR) zeigen, dass dies auf MUSCIMA-ähnlichen Daten zu Recall > 99 % führt.

#### Pseudo-Code (Stable-Path-Idee)

```
function stable_paths(binary, num_paths):
    # cost[y,x]: niedriger = wahrscheinlich Stafflinien-Pixel
    cost ← 1 - dilate(binary, kernel=staffLineHeight)

    # Dynamic Programming: minimum-cost path from any column 0 to any column W-1
    for x = 1 .. W-1:
        for y = 0 .. H-1:
            DP[y, x] = cost[y, x] + min(DP[y-1, x-1], DP[y, x-1], DP[y+1, x-1])
            BACK[y, x] = argmin
    paths ← []
    while len(paths) < num_paths:
        y_end ← argmin_y DP[y, W-1]
        path  ← backtrace(BACK, y_end)
        paths.append(path)
        invalidate_band(cost, path, height=2*staffLineHeight)  # remove found line
    return paths
```

Anschließend: **Cluster** der Pfade in 5er-Gruppen mit Y-Abstand ≈ `staffSpace` → `StaffSystem`.

#### Komplexität

- DP-Stable-Paths: `O(W·H)` pro Pfad, bei N Linien `O(N·W·H)`. Für A4@300dpi und ~50 Stafflinien noch < 1 s in Rust mit SIMD.

#### Schwächen

- Sehr enge System-Abstände (Klavier-Akkoladen) können false 5er-Gruppierungen erzeugen → für Blasmusik-Stimmen ein nicht-Problem (immer 1 Staff-System per Zeile).

---

### 2.3 Staff-Line Removal

**Input:** Binäres Bild + `StaffLine[]`.
**Output:** Symbol-only Binäres Bild (Notenköpfe, Hälse, Bögen ohne Linien).

Naives Schwarz-Setzen aller Pixel auf der Linie zerstört dünne Hälse und horizontale Strich-Anteile von Notenköpfen, die die Linie überqueren. Bessere Verfahren:

1. **Vertical-Run-Length-Test** — Lösche Linien-Pixel **nur**, wenn der vertikale schwarze Run an dieser Stelle ≤ 2 · `staffLineHeight` ist. Wenn er länger ist (= Hals oder Notenkopf), behalte Pixel. Sehr robust und einfach.
2. **Skeletonization-based** — Skelett der Linie; lösche nur Skelett-Pixel.
3. **Lineal-Filter / Morphologie** — Öffnen mit horizontalem `(1 × 5·staffSpace)`-Kernel, Subtraktion vom Original.
4. **Lernbasiert** — U-Net mit MUSCIMA-staff-removal-Annotationen; State-of-the-art-F1 > 0.98 (Calvo-Zaragoza et al. 2017).

**Empfehlung v1:** Vertical-Run-Length (Verfahren 1). Komplexität `O(W·H)`, kein Modell nötig.

#### Schwächen

- Notenköpfe, die genau auf einer Stafflinie liegen, können Lücken bekommen → Stufe 2.4 muss diese durch Closing-Morphologie heilen.

---

### 2.4 Symbol Segmentation

**Input:** Symbol-only Binärbild + StaffSystem-Koordinaten.
**Output:** `SymbolCandidate[]` — Bounding-Boxes + Pixel-Masken.

#### Algorithmen

1. **Connected-Component Labeling (CCL)** — 8-Konnektivität, Two-Pass-Union-Find (Wu/Otoo/Suzuki 2009: optimal `O(W·H·α(N))`).
2. **Morphologisches Closing** vor CCL, um durch Staff-Removal verursachte Bruchstellen zu schließen (Kernel: 1×`staffLineHeight`).
3. **Bounding-Box-Filterung** — Komponenten mit Höhe < 0.3·`staffSpace` oder Pixelzahl < 5 → Rauschen, verwerfen.
4. **Splitting/Merging-Heuristiken** — Komponenten mit Bounding-Box-Höhe > 4·`staffSpace` sind oft mehrere Symbole (z. B. Akkord+Hals+Beam) → Recursive Vertical-Cut bei Stelle minimaler Pixel-Dichte.

#### Datenstruktur

```
SymbolCandidate {
    bbox: Rect,
    pixel_mask: BitMap,   // optional, nur für ML-Klassifikation
    centroid: (f32, f32),
    area: u32,
    parent_staff: StaffId,
}
```

#### Komplexität

- CCL: `O(W·H)` mit moderner Union-Find-Implementierung.
- Morphologisches Closing: `O(W·H·k)` mit Kernel-Größe k; SIMD-beschleunigbar.

---

### 2.5 Symbol Classification

**Input:** `SymbolCandidate[]`.
**Output:** `ClassifiedSymbol[]` mit Klasse aus ≈ 50 Klassen (notehead-filled, notehead-half, whole-note, quarter-rest, eighth-rest, treble-clef, bass-clef, flat, sharp, natural, dot, beam, stem, slur-end, dynamic-f, dynamic-p, …).

#### Klassische Verfahren

- **HOG-Features** (Histogram of Oriented Gradients, 9 Bins, 8×8-Cells) + linearer SVM. Robust bei moderater Klassenzahl.
- **SIFT-Bag-of-Visual-Words** + Random Forest. Skalen-invariant, aber langsam.
- **Template-Matching** (NCC) mit Bibliothek aus ~ 200 Verlags-Glyphen. Einfach, aber nicht generalisierend.
- **Klassifikations-Features:** Bounding-Box-Aspect-Ratio, Pixel-Density, Anzahl Löcher (Euler-Number), Zernike-Moments, vertikale/horizontale Profil-Histogramme.

#### Deep-Learning-Verfahren

- **Image-Patch-CNN** (e.g. ResNet-18, MobileNet-V3) — Patch um Bounding-Box, Klassifikation in 50 Klassen. Reicht ~ 95–98 % auf MUSCIMA++/DeepScores (Tuggener et al. 2018).
- **Object Detection End-to-End** (YOLOv8, Faster-R-CNN, Mask-R-CNN) — überspringt CCL-Stufe 2.4 vollständig. Bessere Behandlung überlappender Symbole. F1 ≈ 0.85–0.95 auf DeepScores (Pacha/Calvo-Zaragoza 2018).

#### Empfehlung v1 (Trade-Off)

**Hybrid:** Klassische CCL + HOG-SVM für die "leichten 90 %" (Noteheads, Stems, Clefs, einfache Rests). **CNN-Patch-Klassifikator** als Fallback für Komponenten mit niedriger SVM-Confidence (< 0.7) oder mehrdeutiger Bounding-Box. Vorteil: kein GPU-Zwang im Default-Pfad, ML nur als Fallback.

#### Komplexität

- HOG: `O(W·H)` pro Patch.
- CNN-Inference (MobileNet-V3-small, 224×224): ~ 5–10 ms pro Symbol auf CPU mit `tract` oder `onnxruntime`.

---

### 2.6 Notehead Recognition (Spezial)

Da Noteheads das **einzige** Symbol sind, dessen exakte Position direkt Pitch und Duration bestimmt, lohnt sich eine spezialisierte, hochpräzise Stufe.

#### Algorithmen

1. **Template-Matching** mit drei Templates (filled/quarter, half, whole). NCC-Korrelation mit Schwelle ≥ 0.7. Templates aus `staffSpace` skaliert (auto-skaleninvariant!).
2. **Sub-Pixel-Refinement** via parabolischer Interpolation des NCC-Peaks:
   ```
   δx = (NCC[x-1,y] - NCC[x+1,y]) / (2·(NCC[x-1,y] - 2·NCC[x,y] + NCC[x+1,y]))
   ```
   Ergibt Position auf ±0.1 Pixel — kritisch für Pitch-Estimation, weil 1 Halbton = `staffSpace`/2 ≈ 5–6 px.
3. **Non-Maximum-Suppression** im Radius 0.7·`staffSpace`.
4. **Lernbasierte Alternative:** U-Net Center-Heatmap (Hajič jr./Pecina 2017) — direkter Heatmap-Output.

#### Pseudo-Code

```
function detect_noteheads(staff_image, staffSpace):
    templates ← load_templates(scaled_to=staffSpace)
    candidates ← []
    for tpl in templates:
        ncc_map ← normalized_cross_correlation(staff_image, tpl)
        peaks   ← local_maxima(ncc_map, threshold=0.7,
                               radius=0.7*staffSpace)
        for (x, y) in peaks:
            (dx, dy) ← parabolic_subpixel(ncc_map, x, y)
            candidates.append(Notehead(x+dx, y+dy, tpl.kind, ncc_map[x,y]))
    candidates ← non_maximum_suppression(candidates,
                                          radius=0.7*staffSpace)
    return candidates
```

---

### 2.7 Stem & Beam Detection

#### Stems (Hälse)

- **Vertikales Run-Length-Encoding**: Spalten mit mind. einem Run der Länge ≥ 2.5·`staffSpace` und Breite ≤ 1.5·`staffLineHeight` sind Stem-Kandidaten.
- Stems sind an Noteheads gebunden: Suche bei jedem Notehead in einem horizontalen Korridor von ±`staffSpace` nach passenden Stem-Endpunkten.
- Stem-Richtung (up/down) bestimmt später Voice/Layer-Zuordnung.

#### Beams (Balken)

- Horizontale **dunkle Rechtecke** zwischen zwei Stems. Detektion über morphologisches Opening mit Kernel `(1.5·staffSpace × 0.4·staffSpace)`.
- **Beam-Counting:** Anzahl der parallelen horizontalen Striche (1 = Achtel, 2 = Sechzehntel, 3 = 32stel) bestimmt Notenwert. Run-Length entlang vertikaler Achse zwischen den Stem-Endpunkten zählt die Beams.

---

### 2.8 Pitch Estimation

**Input:** Notehead-Position (x, y, sub-pixel), aktueller Clef, aktuelle Key-Signature.
**Output:** `Pitch { step: A–G, octave: i32, alter: i32 }`.

#### Algorithmus

1. **Staff-Position berechnen:** `pos = (y - staffline_top_y) / (staffSpace/2)`. Werte: 0=oberste Linie, 1=oberster Zwischenraum, …, 8=unterste Linie. Negativ/>8 = Hilfslinien (ledger lines).
2. **Clef-Mapping:** Treble-Clef → `pos=0` ist F5, `pos=2` ist E5, … (Lookup-Table). Bass-Clef, Alto, Tenor analog.
3. **Key-Signature-Anwendung:** Wenn Step in Key-Signature mit `#` oder `♭`, setze `alter = ±1`.
4. **Lokale Akzidenzien:** Vorzeichen, das in derselben Measure für dieselbe Step bereits gesetzt wurde, **überschreibt** Key-Signature bis Measure-Ende (MusicXML-Konvention).
5. **Hilfslinien-Detection:** Bei `pos < -1` oder `pos > 9` → suche horizontale Striche oberhalb/unterhalb des Notenkopfs zur Bestätigung. Falls keine vorhanden, Notehead verwerfen (false positive).

#### Datenstruktur

```
Pitch {
    step:    enum { A, B, C, D, E, F, G },
    octave:  i32,        // MIDI octave; C4 = middle C
    alter:   i32,        // -2..+2 (♭♭..##)
}
```

---

### 2.9 Duration Estimation

**Input:** Klassifizierter Notehead-Typ (filled/half/whole), zugeordnete Stems, Beams, Flags, Augmentation-Dots.
**Output:** `Duration { base: NoteValue, dots: u8, tuplet: Option<TupletInfo> }`.

#### Regelwerk

| Notehead | Stem | Beams/Flags | Resultierender Wert |
|----------|------|-------------|---------------------|
| Whole (offen) | nein | – | Ganze (1) |
| Half (offen) | ja | 0 | Halbe (1/2) |
| Filled | ja | 0 | Viertel (1/4) |
| Filled | ja | 1 Beam/Flag | Achtel (1/8) |
| Filled | ja | 2 | Sechzehntel (1/16) |
| Filled | ja | 3 | 32stel (1/32) |

- **Augmentation-Dot:** Punkt unmittelbar rechts vom Notenkopf, in einem Zwischenraum (nicht auf einer Linie!), Radius ≈ `staffLineHeight`. Erkennung: kleine Komponente in Distanz `[0.5, 1.2] × staffSpace` rechts vom Notenkopf.
- **Tuplet-Erkennung (Triolen, Quintolen):** über erkannte Zahl/Klammer oberhalb des Beams (Stufe 2.10).

---

### 2.10 Symbol Reconstruction (höhere Notation)

Nach den primitiven Symbolen werden **musikalisch interpretierte Konstrukte** zusammengesetzt. Diese Stufe ist regelbasiert und benötigt **kontextuelles Wissen**.

| Konstrukt | Erkennung |
|-----------|-----------|
| **Clef** | Klassifizierte Glyphe am Beginn jeder Zeile/nach Doppelstrich; Kontext: Y-Position auf Staff |
| **Key-Signature** | Sequenz von ♯/♭ direkt nach Clef; Reihenfolge muss F-C-G-D-A-E-B (♯) bzw. invertiert (♭) sein |
| **Time-Signature** | Zwei Ziffern übereinander am Anfang; ggf. C, ¢ |
| **Barlines** | Vertikale Linien quer durch Staff; klassifiziert in single/double/repeat-start/repeat-end/final |
| **Accidentals** | ♯/♭/♮ unmittelbar links eines Notenkopfs |
| **Articulations** | Punkt/Strich/Akzent oberhalb/unterhalb eines Notenkopfs in Abstand ≤ 0.5·staffSpace |
| **Slurs / Ties** | Bogenförmige dünne Kurven; Endpunkte bei Noteheads. Kandidaten via Skelett-Tracing erkennen |
| **Dynamics** | Klassifizierte Glyphen (p, f, mf, …) **außerhalb** des Stafs, plus Crescendo/Decrescendo-Hairpins (per Hough/Linien-Detect) |
| **Tempo / Rehearsal** | Text-OCR (out-of-scope für v1, optional via `tesseract`) |

#### Voice/Layer-Reconstruction

In Polyphonie und Akkorden sind mehrere Notenköpfe gleichzeitig auf demselben Staff. Regeln:

1. **Akkord:** Mehrere Noteheads, die **denselben Stem** teilen → ein einzelner Note-Event mit Chord-Markup (`<chord/>` in MusicXML).
2. **Voices:** Notenköpfe mit verschiedenen Stem-Richtungen → verschiedene Voices. Standard: Stem-up = Voice 1, Stem-down = Voice 2.
3. **Beat-Alignment:** Innerhalb einer Measure müssen die Summen pro Voice die `time-signature` ergeben → Sanity-Check; bei Abweichung Warnung im JSON-Trace.

---

### 2.11 MusicXML Export

**Input:** Score-Tree (Parts → Measures → Voices → Notes/Rests).
**Output:** UTF-8-XML konform zu MusicXML 4.0 `score-partwise.dtd`/`.xsd`.

Minimaler Aufbau:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
                                "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="4.0">
  <work><work-title>…</work-title></work>
  <identification>
    <encoding><software>Sheetstorm OMR 0.1</software></encoding>
  </identification>
  <part-list>
    <score-part id="P1"><part-name>Trompete 1</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>2</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note>
        <pitch><step>A</step><octave>4</octave></pitch>
        <duration>2</duration>
        <type>eighth</type>
        <stem>up</stem>
      </note>
      …
    </measure>
  </part>
</score-partwise>
```

Implementation in Rust: `quick-xml` (Streaming-Writer). XSD-Validierung optional via `libxml2`-Bindings als Test-Gate.

---

## 3. Datenstrukturen (Rust-orientiert, sprachneutral notiert)

```
Image {
    width: u32, height: u32,
    pixels: Vec<u8>,         // grayscale or 1-bit packed
    dpi: u16,
    staff_line_height: f32,  // computed in §2.1
    staff_space: f32,
}

StaffLine {
    polyline: Vec<(f32, f32)>,   // sub-pixel y per x; allows curved staves
    thickness: f32,
}

StaffSystem {
    id: u32,
    lines: [StaffLine; 5],       // top to bottom
    bbox: Rect,
    measures: Vec<MeasureBoundary>,
}

SymbolCandidate {
    bbox: Rect,
    centroid: (f32, f32),
    pixel_mask: BitMap,
    parent_staff: StaffId,
}

ClassifiedSymbol {
    candidate: SymbolCandidate,
    class: SymbolClass,         // enum
    confidence: f32,
    alternatives: Vec<(SymbolClass, f32)>,  // top-3 for downstream Multi-Hypothesis
}

Note {
    pitch: Pitch,
    duration: Duration,
    voice: u8,
    chord_with: Option<NoteId>,
    articulations: Vec<Articulation>,
    ties: TieFlags,
    slur: Option<SlurId>,
}

Measure {
    number: u32,
    attributes: Option<Attributes>,   // clef/key/time changes
    voices: Vec<Voice>,
    barline_left: Barline,
    barline_right: Barline,
}

Score {
    parts: Vec<Part>,
    work_title: Option<String>,
    composer: Option<String>,
}
```

---

## 4. Test-Strategie

### 4.1 Synthetische Tests (Unit / Stage-Regression)

- **Generator:** Erzeuge MusicXML-Mini-Scores (1–4 Measures) mit der Bibliothek **Verovio** oder **MuseScore CLI** (PNG-Export). Eingabe → Pipeline → Vergleich mit Original-MusicXML.
- **Tests pro Stufe:**
  - §2.1: Gegebenes Bild mit bekanntem Skew-Winkel — Detection muss innerhalb 0.1° liegen.
  - §2.2: Bilder mit 1, 4, 12 Stafflinien-Systemen — alle erkannt, Y-Koordinaten ±1 Pixel.
  - §2.6: Bilder mit n Notenköpfen an exakt bekannten Positionen — Recall = 100 %, Precision ≥ 99 %.
  - §2.8: Pitch-Estimation für jede Position auf jedem Clef — 100 % korrekt.

### 4.2 Reale Korpora (Integration / End-to-End)

- **MUSCIMA++ v2.0** (handgeschrieben, CC-BY-NC-SA — beachten!) — nicht für Training kommerzieller Modelle, aber für Eval ok.
- **DeepScores v2** (synthetisch, MIT-ähnlich) — primär Symbol-Detection-Eval.
- **PrIMuS** (gedruckte Mono-Stimmen) — End-to-End-Eval auf MusicXML.
- **IMSLP-Public-Domain-Korpus** — selbst kuratierte Sammlung von ~200 Blasmusik-Stimmen mit händischer MusicXML-Ground-Truth (Aufwand: ~3 Personentage je 50 Stimmen).

### 4.3 Metriken

| Metrik | Berechnung | Verwendung |
|--------|-----------|------------|
| **Symbol-F1** pro Klasse | `2·P·R/(P+R)` mit IoU ≥ 0.5 | Pro Klassifikator |
| **Note-Level Precision/Recall/F1** | Match nach (onset, pitch, duration) | End-to-End |
| **OMR-Edit-Distance** (Hajič 2016) | Levenshtein auf Note-Sequenz pro Voice | Sequenz-Qualität |
| **Tree-Edit-Distance** auf MusicXML | optional, holistisch | Strukturelle Korrektheit |
| **MV2H** (Music-V2-Harmony, McLeod 2019) | Multi-Pitch + Voice + Meter + Harmony | Holistisch und musikalisch sinnvoll |

### 4.4 CI-Regression

- Snapshot-Tests pro Stufe: deterministische Hashes des Output-JSON gegen Erwartungswerte.
- Performance-Gate: `< 30 s` für Standard-Test-Page als CI-Härtetest.

---

## 5. Optimierungs- und Verbesserungsoptionen

### 5.1 Geschwindigkeit pro Stufe

| Stufe | SIMD | Multi-Threading | GPU |
|-------|------|-----------------|-----|
| §2.1 Preprocessing | Integralbilder via AVX2/NEON | Tile-basiert je Thread | nicht nötig |
| §2.2 Stable Paths | DP-Spalten-Vektorisierung | Pro Staff-Region parallel | optional |
| §2.4 CCL | wenig Nutzen | Run-basierte Parallel-CCL (He 2017) | wenig sinnvoll |
| §2.5 Klassifikation | – | Per-Symbol-Batch | **CNN auf GPU/ANE → 5–10×** |
| §2.6 Notehead-NCC | FFT-basierte Korrelation (`O(WH·log)`), AVX2 | Pro Staff-Zeile | CUDA/Metal-Conv |

### 5.2 Qualität pro Stufe

| Stufe | Verbesserungs-Idee |
|-------|--------------------|
| §2.1 | Lernbasiertes Binarization-Net (Howe 2013) bei degradierten Scans |
| §2.2 | U-Net-Staff-Pixel-Segmentation mit MUSCIMA-Pretraining |
| §2.4/2.5 | **Multi-Hypothesis** — Top-3-Klassen pro Symbol; finale Auswahl per **musikalischem Sprachmodell** (z. B. n-Gram über MIDI-Tonfolgen) |
| §2.8 | Akzidenzien-Cache pro Measure als FSM, um inkonsistente Pitch-Sequenzen zu detektieren |
| §2.10 | Beat-Sum-Constraint-Solver: gewichtete Suche nach Voice-Zuordnung, die Time-Signature respektiert (ILP-Löser) |
| End-to-End | **Hybrid-Postprocessing** mit Sequenz-Modell (Transformer auf Note-Token-Stream) zur Korrektur klassischer Pipeline-Fehler |

### 5.3 ML vs. Klassisch — Trade-Off

| Aspekt | Klassisch (CCL+HOG/SVM) | End-to-End-DL |
|--------|--------------------------|---------------|
| Trainingsdaten | minimal | viel (10⁵+ Annotations) |
| Determinismus / Erklärbarkeit | hoch | gering (Black-Box) |
| Latenz CPU | 5–15 s/Seite | 30–60 s/Seite (ohne GPU) |
| Robustheit gegen Layout-Vielfalt | mittel | hoch |
| Anfälligkeit gegen unbekannte Symbole | gering (Klassen-Lookup) | hoch (silent failure) |
| Iterations-Geschwindigkeit | schnell | sehr langsam (Re-Training) |

**Empfehlung:** Hybrid. Klassische Pipeline als Backbone, **CNN als Fallback** und **Sequenz-Modell als Postprocessor**. Vorteil: Sheetstorm hat bereits am Tag 1 ein lauffähiges System ohne Trainingsdaten und kann inkrementell ML-Komponenten hinzunehmen.

### 5.4 State-of-the-Art-Best-Practices (Stand 2024)

- **Pacha/Eidenberger 2018:** Deep Watershed Detector — gute Idee für überlappende Symbole.
- **Calvo-Zaragoza/Toselli/Vidal 2019:** CRNN+CTC für End-to-End Mono-Stimmen — vielversprechend für Kornett/Trompete-Stimmen.
- **Ríos-Vila et al. 2023:** Sheet Music Transformer — Vision-Transformer-Encoder + Score-Decoder, SOTA auf PrIMuS.
- **Camera-OMR (Calvo-Zaragoza 2018):** Kein Issue für Sheetstorm v1, später für Mobile-Scan relevant.

---

## 6. Architektur-Vorschlag (Rust-Workspace + Sheetstorm-Integration)

### 6.1 Crate-Struktur

```
omr/                                 (cargo workspace)
├── Cargo.toml                       (workspace = ["crates/*"])
├── crates/
│   ├── omr-image/                   §2.1 Preprocessing, image I/O, integral images
│   │   └── deps: image, imageproc, rayon
│   ├── omr-staff/                   §2.2/2.3 Staff detect+remove, Stable Paths
│   ├── omr-segmentation/            §2.4 CCL + morphology
│   ├── omr-classifier/              §2.5 HOG+SVM + ONNX-CNN-Fallback (tract / ort)
│   ├── omr-notehead/                §2.6 Template-Match + Sub-Pixel
│   ├── omr-rhythm/                  §2.7/2.9 Stems, Beams, Duration
│   ├── omr-semantic/                §2.8/2.10/2.11 Pitch, Reconstruction, Voicing
│   ├── omr-musicxml/                §2.12 Quick-XML Writer + Schema-Validate
│   ├── omr-pipeline/                Orchestrator, Trace-JSON, CLI binary
│   └── omr-eval/                    Test-Harness, Metriken, MusicXML-Diff
└── data/
    ├── templates/                   notehead/clef-Templates
    ├── models/                      *.onnx Klassifikator-Modelle
    └── fixtures/                    Synthetische Test-Bilder + GT
```

Jeder Crate exportiert ein klares **Trait-Interface** (z. B. `trait StaffDetector { fn detect(&self, &Image) -> Vec<StaffSystem> }`), sodass alternative Implementierungen (klassisch / ML / GPU) austauschbar sind.

### 6.2 Integration in Sheetstorm

Heute ist **Audiveris** als Container-Sidecar in Aspire eingebunden (siehe `docs/07-audiveris-integration.md`). Drei Wege für die Eigen-OMR:

#### Option A — HTTP-Sidecar (analog Audiveris)

- Rust-Crate `omr-server` mit `axum` + `POST /omr` (multipart: PDF/PNG → MusicXML).
- Container: `Dockerfile` mit `cargo build --release`, Distroless-Base; Image ~ 50 MB.
- Aspire: in `Sheetstorm.AppHost`
  ```csharp
  var omr = builder.AddContainer("omr", "sheetstorm/omr:latest")
                   .WithHttpEndpoint(targetPort: 8080, name: "omr-api")
                   .WithEnvironment("OMR_LOG", "info");
  apiService.WithReference(omr);
  ```
- **Vorteile:** Klare Sprach-Grenze, einfaches Deployment, getrennte Skalierung, keine .NET↔Rust-FFI-Komplexität.
- **Nachteile:** HTTP-Overhead pro Request (kleine Latenz, vernachlässigbar bei OMR-Workloads).

#### Option B — Native Library (Rust → C-FFI → C# P/Invoke)

- Rust-Crate als `cdylib`; `cbindgen` generiert Header.
- C#: `[DllImport("omr_ffi")]` in `Sheetstorm.Infrastructure.Omr`.
- **Vorteile:** Niedrigste Latenz, kein Container-Stack.
- **Nachteile:** Plattform-spezifische Builds (Win/Linux/macOS×x64/arm64), schwierigere Updates, kein Sandboxing → Crash zieht API-Service mit.

#### Option C — gRPC-Sidecar (strukturierte Variante von A)

- Wie A, aber Protobuf-Schema; bessere Type-Safety als JSON, aber mehr Tooling.
- Empfohlen, wenn auch andere Konsumenten (Mobile?) das OMR-Service direkt nutzen.

#### Empfehlung

**Option A (HTTP-Sidecar)** für v1. Identisches Deployment-Pattern wie Audiveris, einfache Migration, A/B-Vergleich. Später optional gRPC, wenn der Service stabil ist.

### 6.3 Aspire-Integration im Detail

```csharp
// Sheetstorm.AppHost/AppHost.cs (Auszug)
var omr = builder.AddContainer("omr-rust", "ghcr.io/sheetstorm/omr:0.1")
                 .WithHttpEndpoint(targetPort: 8080, name: "http")
                 .WithEnvironment("RUST_LOG", "omr_pipeline=info")
                 .WithVolume("omr-models", "/var/lib/omr/models")
                 .WithHealthCheck("/healthz");

builder.AddProject<Projects.Sheetstorm_ApiService>("api")
       .WithReference(omr.GetEndpoint("http"))
       .WaitFor(omr);
```

Der API-Service ruft `omr` über `IHttpClientFactory` auf — derselbe Code-Pfad wie der existierende `IAudiverisClient` (siehe `Sheetstorm.Infrastructure.Omr`). Eine Feature-Flag `Omr:Provider = "audiveris" | "sheetstorm-rust"` erlaubt schrittweise Migration.

---

## 7. Referenzen

### 7.1 Wissenschaftliche Papers

- Calvo-Zaragoza, J., Hajič jr., J., Pacha, A. (2020). **Understanding Optical Music Recognition.** ACM Computing Surveys 53(4). DOI: [10.1145/3397499](https://doi.org/10.1145/3397499)
- Rebelo, A., Fujinaga, I., Paszkiewicz, F., Marçal, A. R. S., Guedes, C., Cardoso, J. S. (2012). **Optical music recognition: state-of-the-art and open issues.** Int. J. of Multimedia Information Retrieval 1, 173–190. DOI: [10.1007/s13735-012-0004-6](https://doi.org/10.1007/s13735-012-0004-6)
- Cardoso, J. S., Capela, A., Rebelo, A., Guedes, C., Pinto da Costa, J. (2009). **Staff Detection with Stable Paths.** IEEE TPAMI 31(6). DOI: [10.1109/TPAMI.2009.34](https://doi.org/10.1109/TPAMI.2009.34)
- Sauvola, J., Pietikäinen, M. (2000). **Adaptive document image binarization.** Pattern Recognition 33(2), 225–236. DOI: [10.1016/S0031-3203(99)00055-2](https://doi.org/10.1016/S0031-3203(99)00055-2)
- Hajič jr., J., Pecina, P. (2017). **The MUSCIMA++ Dataset for Handwritten Optical Music Recognition.** ICDAR. DOI: [10.1109/ICDAR.2017.16](https://doi.org/10.1109/ICDAR.2017.16)
- Tuggener, L., Elezi, I., Schmidhuber, J., Pelillo, M., Stadelmann, T. (2018). **DeepScores — A Dataset for Segmentation, Detection and Classification of Tiny Objects.** ICPR. arXiv: [1804.00525](https://arxiv.org/abs/1804.00525)
- Calvo-Zaragoza, J., Rizo, D. (2018). **End-to-End Neural Optical Music Recognition of Monophonic Scores.** Applied Sciences 8(4). DOI: [10.3390/app8040606](https://doi.org/10.3390/app8040606)
- Pacha, A., Calvo-Zaragoza, J. (2018). **Optical Music Recognition in Mensural Notation with Region-Based Convolutional Neural Networks.** ISMIR.
- Ríos-Vila, A., Calvo-Zaragoza, J., Rizo, D. (2023). **Sheet Music Transformer.** arXiv: [2312.10936](https://arxiv.org/abs/2312.10936)
- Hajič jr., J. et al. (2016). **Further Steps Towards a Standard Testbed for OMR.** ISMIR.
- McLeod, A. (2019). **Evaluating Automatic Polyphonic Music Transcription.** PhD thesis, U. of Edinburgh (MV2H-Metrik).
- Howe, N. R. (2013). **Document Binarization with Automatic Parameter Tuning.** IJDAR 16, 247–258.

### 7.2 Open-Source-Projekte (nur als **Konzept-Referenz**, keine Code-Übernahme)

| Projekt | Lizenz | Hinweis |
|---------|--------|---------|
| **Audiveris** | **AGPL-3.0** | ⚠️ **Code nicht lesen oder kopieren.** Architektur-Erkenntnisse nur aus öffentlichen Talks/Wikis. |
| **OEMER** (BreezeWhite) | MIT | End-to-End-DL, Konzepte frei nachbaubar |
| **OpenOMR / Pacha-Tools** | MIT | Datasets-Tooling |
| **CalvoZaragoza/tf-end-to-end** | MIT | Referenz-Architektur CRNN+CTC |
| **Mensura / Mensuralis** | MIT (gemischt) | Renaissance-Notation, nicht direkt relevant |
| **OpenCV** | Apache-2.0 | Operatoren-Referenz |
| **imageproc** (Rust) | MIT | Rust-Image-Algorithmen |
| **Verovio** | LGPL-3.0 | MusicXML→SVG, ideal als Test-Generator |

### 7.3 Public-Domain / Open-Datasets

- **PrIMuS** (Calvo-Zaragoza) — gedruckte Mono-Stimmen, Forschungs-Lizenz.
- **DeepScores v2** — synthetisch, große Skala.
- **MUSCIMA++ v2.0** — handgeschrieben, CC-BY-NC-SA (nur Eval, nicht Training kommerzieller Modelle).
- **CVC-MUSCIMA** — Staff-Removal-Ground-Truth.
- **IMSLP** — gemeinfreie Partituren als reale Test-Daten (Lizenz pro Werk prüfen).

---

## 8. Status-Report (Recherche-Reflexion)

### 8.1 Verwendete Quellen

- Calvo-Zaragoza/Hajič/Pacha **OMR-Survey 2020** (ACM CSUR) als zentrale Architektur-Referenz.
- Cardoso et al. **Stable Paths** für Staff-Line-Detection (ICDAR 2009 / TPAMI).
- Sauvola/Niblack-Original-Papers für Binarization-Formeln.
- Tuggener et al. **DeepScores** + Hajič **MUSCIMA++** für Datasets und Benchmarks.
- arXiv-Papers zu CRNN+CTC (Calvo-Zaragoza/Rizo) und Sheet Music Transformer (Ríos-Vila 2023).
- MusicXML 4.0 W3C-Spezifikation für Output-Format.
- Allgemeine CV-Literatur (Wu/Otoo/Suzuki CCL, Crow Integralbilder, Postl Skew-Detection).

**Bewusst nicht konsultiert:** Audiveris-Quellcode (AGPL-Risiko). Architektur-Vergleiche basieren ausschließlich auf der publizierten Literatur und allgemein bekannten OMR-Topologien.

### 8.2 Spannendste neue Erkenntnisse

1. **Hybrid-Pipelines schlagen reine End-to-End-Ansätze** auf realen, vielfältigen Korpora deutlich. Sheet Music Transformer (Ríos-Vila 2023) ist nur auf PrIMuS-ähnlichen Daten konkurrenzfähig; auf DeepScores v2 und MUSCIMA++ liegen klassische Pipelines mit ML-Komponenten vorn. Das stützt die hier vorgeschlagene Hybrid-Strategie.
2. **Stable-Paths ist nach 15 Jahren immer noch State-of-the-Art** für Staff-Line-Detection bei gekrümmten oder unterbrochenen Linien — und in Rust mit DP-Vektorisierung trivial in `O(W·H)` umsetzbar.
3. **Sub-Pixel-Notehead-Localization** ist unterschätzt: Bei A4@300dpi und `staffSpace ≈ 14 px` entscheidet ein Pixel-Versatz schon über einen Halbton. Parabolische Sub-Pixel-Interpolation kostet praktisch nichts und verbessert Pitch-Recall messbar.
4. **OMR-Edit-Distance und MV2H** sind weit aussagekräftiger als naive Symbol-Accuracy und sollten von Anfang an als CI-Metriken eingesetzt werden — sonst optimiert man auf irrelevante Zahlen.
5. **MusicXML 4.0 ist stabil**, der Schema-Pfad ist klar, und mit `quick-xml` lässt sich der Streaming-Writer in Rust in unter ~1500 LOC bauen.

### 8.3 Größte Risiken für die Eigenimplementation

| Risiko | Wahrscheinlichkeit | Auswirkung | Mitigation |
|--------|--------------------|------------|------------|
| **Realistische End-to-End-Genauigkeit < 80 %** auf realen Vereins-Scans, weil multiplikative Fehler-Akkumulation in 12 Stufen | hoch | Eigen-OMR liefert in v1 schlechtere Ergebnisse als Audiveris | UI-Review-Step, Multi-Hypothesis, schrittweise Stage-Verbesserung; **Audiveris als Fallback per Feature-Flag** behalten |
| **Trainingsdaten-Lizenz-Sackgasse** — MUSCIMA++ ist NC, DeepScores synthetisch, IMSLP heterogen | mittel | ML-Komponenten dürfen nur mit eigenen Daten oder synthetischen Quellen trainiert werden | Synthetische Datengenerierung mit Verovio + LilyPond; eigenes Annotations-Tool für Vereinsarchiv |
| **Polyphonie & komplexe Voicing** (Akkorde, Tuplets, mehrstimmig) sind algorithmisch sehr aufwendig korrekt zu rekonstruieren | hoch | "Sieht 80 % gut aus, ist aber rhythmisch falsch" | Constraint-basierte Voicing mit Beat-Sum-Check, Test-Korpus mit polyphonen Stücken früh in CI |
| **Implementierungs-Aufwand 6–12 Personenmonate** unterschätzt | mittel | Roadmap-Slip | Aufteilung in Crates mit klaren Trait-Interfaces; jede Stufe einzeln verifizierbar; HTTP-Sidecar erlaubt Teil-Ablösung von Audiveris stage-by-stage |
| **Slurs, Ties, Articulations, Lyrics** sind in OMR notorisch schwierig — selbst kommerzielle Tools sind hier unzuverlässig | sehr hoch | Erwartungs-Diskrepanz bei Endusern | Diese Features explizit als "best-effort" v1.x deklarieren, im UI als „unreviewt“ markieren |
| **AGPL-Kontamination** durch versehentlichen Audiveris-Code-Blick | gering | rechtlich kritisch für Sheetstorm-Lizenz | Strikte Repo-Hygiene: Audiveris nur als Black-Box-Container; Code-Reviews mit AGPL-Checkliste; eigene Implementer dürfen Audiveris-GitHub nicht öffnen |

**Fazit:** Eine Eigen-OMR in Rust ist technisch machbar und langfristig strategisch sinnvoll (kein AGPL-Anker, schlankes Deployment, deterministischer Code-Pfad). **Pragmatischer Pfad:** Stage-by-Stage neben Audiveris bauen, mit Feature-Flag schaltbar, und ehrliche Genauigkeitserwartung im Produkt kommunizieren. Volle Audiveris-Ablösung erst, wenn auf einem internen Vereinsarchiv-Korpus die Note-Level-F1 dokumentiert ≥ Audiveris liegt.
