# 18 — Symbol-Library & Layout-Hints für die OMR-Pipeline

> **Status:** Entwurf / Spezifikation (keine Implementation)
> **Adressaten:** OMR-Engine-Entwickler, Backend-Architekt, Reviewer
> **Ziel:** Konzeptionelle Grundlage für eine erweiterte Symbol-Erkennung
> jenseits von Noteheads/Stems/Beams/Bars. Beschreibt eine Library
> standardisierter Musik-Symbole, strukturelle Layout-Erwartungen und einen
> Text-vs-Musik-Diskriminator, mit dem typische Fehlerquellen (z.B.
> "espressivo" → fälschlich als Notehead erkannt) systematisch reduziert
> werden können.
>
> Dieses Dokument ergänzt:
> * `docs/15-omr-pipeline-spec.md` (Pipeline-Stufen, Datenstrukturen)
> * `docs/16-omr-algorithm-research.md` (Algorithmen-Recherche)
>
> Es enthält **keine Implementation und keinen Code aus Audiveris**.
> Templates basieren ausschließlich auf frei lizenzierten Schriften
> (Bravura/SMuFL, Emmentaler) bzw. synthetischer Generierung.

---

## 1. Motivation

Die aktuelle OMR-Engine in `src/omr-rust/` erkennt zuverlässig Noteheads,
Stems, Beams und Taktstriche. Auf realen Vereinsnoten treten dabei zwei
Klassen von Fehlern systematisch auf:

1. **False Positives durch Text:** Text wie *espressivo*, *rit.*, *Allegro*,
   Tempo-Marken oder Liedtext erzeugt kompakte runde Connected Components,
   die der Notehead-Detektor nicht sicher von echten Notenköpfen
   unterscheidet.
2. **Stille False Negatives:** Symbole, die musikalisch relevant sind, aber
   gar nicht Teil der aktuellen Pipeline sind (Fermate, Akzent, Staccato,
   Slur, Volta-Klammern, *D.C. al Fine* …) — sie fehlen im MusicXML-Export
   ohne Hinweis.

Beide Probleme lassen sich nicht durch ein besseres Notehead-Filter lösen,
sondern brauchen **mehr Modellwissen über das, was auf einem Notenblatt
überhaupt vorkommen kann und wo es typischerweise steht**:

* eine **Symbol-Library** (was kann vorkommen?),
* **Layout-Hints** (wo darf was vorkommen?),
* einen **Text-Diskriminator** (was ist gar keine Musik?).

---

## 2. Symbol-Library

### 2.1 Lese-Hilfen für die Tabellen

* **Größe:** relativ zum Stafflinien-Abstand `s` (interspace) — bei 300 dpi
  typischerweise `s ≈ 8–10 px`. Die Pipeline normalisiert auf eine feste
  Ziel-`s`, siehe `docs/15-omr-pipeline-spec.md §2.1`.
* **Position:** Bezug auf das nächstgelegene Notensystem. „Innerhalb" =
  zwischen Top- und Bottom-Linie; „über/unter" = außerhalb.
* **Schwierigkeit:** subjektive Skala für die Detektor-Implementation.
  1 = trivial (klare Form, wenige Varianten), 5 = sehr schwer (variable
  Form, Überlappung, semantisch kontextabhängig).
* **Priorität:**
  * **must-have** = ohne diese Symbole ist der MusicXML-Export
    nennenswert falsch.
  * **nice-to-have** = Verbesserung der musikalischen Treue, aber kein
    Blocker.
  * **phase-2** = klar nach allen must-haves, oft semantisch komplex
    (Wiederholungs-Strukturen).

### 2.2 Notenköpfe

| Symbol | Visuelle Beschreibung | Layout-Position | Bedeutung (MusicXML) | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Notehead **filled** (Viertel/Achtel/…) | Schräg-elliptisch gefüllt, ca. `1.2s × s` | innerhalb / über / unter Stafflinien, auf Linie oder Zwischenraum | `<note><type>quarter\|eighth\|...`, kombiniert mit Stem/Flag/Beam | 1 | must-have ✅ |
| Notehead **half / open** | Schräg-elliptisch, hohle Mitte | wie filled | `<type>half</type>` | 2 | must-have ✅ |
| Notehead **whole** | Ovaler offener Kopf, breiter und nicht geneigt | wie open, **kein Stem** | `<type>whole</type>` | 2 | must-have ✅ |
| Notehead **breve / double whole** | Rechteckig mit zwei vertikalen Strichen | wie whole | `<type>breve</type>` | 3 | nice-to-have |
| Notehead **X / cross** (Schlagzeug) | × statt Oval | meist auf 1 Linie, neutral platziert | `<notehead>x</notehead>` | 3 | phase-2 |
| Notehead **slashed / diamond** (Cue, Harmonics) | Raute oder durchgestrichen | wie filled | `<notehead>diamond</notehead>` | 4 | phase-2 |

### 2.3 Hälse, Fähnchen, Beams

| Symbol | Visuelle Beschreibung | Layout-Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Stem | Vertikale Linie, Länge `≈ 3.5s`, dünn (`≈ 0.1s`) | rechts oben am Notehead (Stem-up) oder links unten (Stem-down) | Pflicht für Viertel und kürzer | 1 | must-have ✅ |
| Flag (Achtel) | Eine geschwungene Fahne am Stem-Ende | außen am Stem | Dauer 1/8 (alleinstehend) | 2 | must-have ✅ |
| Flag (16tel/32tel) | 2 bzw. 3 Fähnchen | wie Flag | Dauer 1/16, 1/32 | 3 | must-have ✅ |
| Beam (1×) | Dicker schräger Balken zwischen Stems | verbindet 2+ Notenköpfe | gruppiert in 1/8 | 2 | must-have ✅ |
| Beams (2×, 3×) | 2 bzw. 3 parallele Balken | wie Beam | gruppiert in 1/16, 1/32 | 3 | must-have ✅ |
| Tremolo-Schrägstriche | 1–3 kurze Schrägstriche **am Stem** (nicht zwischen Stems) | mittig am Stem | `<tremolo>` | 4 | phase-2 |

### 2.4 Schlüssel

| Symbol | Visuelle Beschreibung | Layout-Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| G-/Violinschlüssel | Stilisiertes G mit großer Schleife | linker Rand jedes Systems, auf Linie 2 | `<sign>G</sign><line>2</line>` | 2 | must-have ✅ |
| F-/Bassschlüssel | Stilisiertes F mit zwei Punkten | linker Rand, auf Linie 4 | `<sign>F</sign><line>4</line>` | 2 | must-have ✅ |
| C-Schlüssel (Alt/Tenor) | Symmetrische Klammer um eine Linie | linker Rand, Linie 3 (Alt) oder 4 (Tenor) | `<sign>C</sign>` | 3 | nice-to-have |
| Tab-Clef | Kursives "TAB" über mehreren Linien | linker Rand bei Tabulaturen | `<sign>TAB</sign>` | 4 | phase-2 |
| Oktavierungs-Zusatz (8va/8vb) | Kleine "8" über/unter dem Schlüssel | direkt am Schlüssel | `<clef-octave-change>` | 3 | nice-to-have |

### 2.5 Vorzeichen / Akzidenzien

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| ♯ (Kreuz) | Zwei Querbalken, zwei Vertikale | direkt **vor** Notehead **oder** in Tonart-Block am Systembeginn | `<alter>1</alter>` | 2 | must-have ✅ |
| ♭ (b) | Stilisiertes b | wie ♯ | `<alter>-1</alter>` | 2 | must-have ✅ |
| ♮ (Auflöser) | Rechteckige Klammer mit Querbalken | wie ♯ | `<alter>0</alter>` | 2 | must-have ✅ |
| 𝄪 (Doppelkreuz) | × | wie ♯ | `<alter>2</alter>` | 4 | nice-to-have |
| 𝄫 (Doppel-b) | bb | wie ♯ | `<alter>-2</alter>` | 4 | nice-to-have |

### 2.6 Pausen

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Ganze Pause | Kleines gefülltes Rechteck **unter** Linie 4 | hängend an Linie 4 | `<rest/><type>whole</type>` | 2 | must-have ✅ |
| Halbe Pause | Wie ganze Pause, aber **auf** Linie 3 sitzend | sitzend auf Linie 3 | `<type>half</type>` | 2 | must-have ✅ |
| Viertelpause | Stilisierte „Z"-Form mit unterem Haken | mittig zwischen Linien | `<type>quarter</type>` | 2 | must-have ✅ |
| Achtelpause (1 Fähnchen) | Schrägstrich + 1 Punkt-Fahne | innerhalb Stafflinien | `<type>eighth</type>` | 2 | must-have ✅ |
| 16tel-/32tel-Pause | Schrägstrich + 2 bzw. 3 Fahnen | wie Achtel | `<type>16th\|32nd</type>` | 3 | must-have ✅ |
| Mehrtakt-Pause | Dicker Balken mit Zahl darüber | mittig im System, mit Zähler | `<measure-rest>` mit `multiple-rest` | 3 | nice-to-have |

### 2.7 Punktierung

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Augmentationspunkt (einfach) | Kleiner Punkt | rechts vom Notehead, im Zwischenraum | Dauer × 1.5 | 2 | must-have ✅ |
| Augmentationspunkt (doppelt) | Zwei Punkte | rechts vom Notehead | Dauer × 1.75 | 3 | nice-to-have |

### 2.8 Fermate

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Fermate 𝄐 (über) | Halbkreis-Bogen mit Punkt | über Notehead/Pausenkopf | `<fermata/>` | 2 | must-have ✅ |
| Fermate invers 𝄑 | gespiegelter Halbkreis mit Punkt | unter Notehead | `<fermata type="inverted"/>` | 3 | nice-to-have |

### 2.9 Artikulation

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Akzent `>` | Spitzes Häkchen | über/unter Notehead | `<accent/>` | 2 | must-have ✅ |
| Staccato `.` | Punkt | über/unter Notehead, innerhalb 1s | `<staccato/>` | 2 | must-have ✅ |
| Tenuto `−` | Kurzer Querstrich | über/unter Notehead | `<tenuto/>` | 3 | nice-to-have |
| Marcato `^` | Kleines Dach | über Notehead | `<strong-accent/>` | 3 | nice-to-have |
| Sforzando-Marker | (oft als Text "sfz", siehe Dynamik) | unter Notehead | `<dynamics><sfz/>` | 3 | nice-to-have |
| Staccatissimo | Schmales Dreieck/Keil | wie Staccato | `<staccatissimo/>` | 4 | phase-2 |

### 2.10 Slur / Tie / Phrasing-Bögen

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Slur (Bindebogen) | Gewölbter, dünner Bogen über mehrere Notenköpfe | über (Stems-down) oder unter (Stems-up) der Gruppe | `<slur type="start\|stop"/>` | 4 | nice-to-have |
| Tie (Haltebogen) | Wie Slur, aber **zwischen identischen Tonhöhen** | sehr nah an den Noteheads | `<tied type="start\|stop"/>` | 4 | nice-to-have |
| Phrasing-Bogen (lang) | Sehr langer Slur über ganze Phrase | weit über/unter dem System | wie Slur | 4 | phase-2 |

### 2.11 Dynamik

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| `pp`, `p`, `mp`, `mf`, `f`, `ff`, `fff` | Italic-Lettern, oft fett-kursiv | unterhalb des Systems | `<dynamics><p/>…</dynamics>` | 3 | must-have ✅ |
| `sfz`, `fp`, `sf`, `fz` | Italic-Kombinationen | unterhalb (gelegentlich oberhalb) | `<dynamics><sfz/>…</dynamics>` | 4 | nice-to-have |

> Hinweis: Dynamik ist **typografisch Text** und sollte über die
> Symbol-Library als Glyph-Match erkannt werden, nicht über den allgemeinen
> Text-Diskriminator.

### 2.12 Crescendo / Decrescendo

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Hairpin `<` (cresc.) | Zwei sich öffnende Linien | unter dem System | `<wedge type="crescendo"/>` | 3 | nice-to-have |
| Hairpin `>` (decresc.) | Zwei sich schließende Linien | unter dem System | `<wedge type="diminuendo"/>` | 3 | nice-to-have |
| Text `cresc.`, `dim.`, `decresc.` | Italic-Text | unter dem System | `<words>cresc.</words>` + `<wedge>` | 3 | nice-to-have |

### 2.13 Tempo

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Metronom-Marke `♩=120` | Notensymbol + `=` + Zahl | über erstem Takt eines Abschnitts | `<metronome>` | 4 | nice-to-have |
| Tempo-Wort `Allegro`, `Andante`, `Moderato` | Bold-Text, oft links über Takt 1 | über Takt 1 | `<words>Allegro</words>` | 3 | nice-to-have |
| `accel.`, `rit.`, `rall.`, `a tempo` | Italic-Text | über System | `<words>` + ggf. `<sound tempo=...>` | 3 | nice-to-have |

### 2.14 Wiederholungs-Marken

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Repeat `||:` / `:||` | Doppelter Taktstrich + zwei Punkte | Beginn / Ende eines Wiederholungs-Abschnitts | `<barline><repeat>` | 3 | must-have ✅ |
| Volta 1./2. | Eckige Klammer über Takten + Zahl | über System | `<ending number=…>` | 4 | nice-to-have |
| `D.C.`, `D.S.`, `al Coda`, `al Fine`, `Fine` | Bold/italic-Text | rechts unter letzten Takt | `<direction><words>` + `<sound>` | 4 | phase-2 |
| Coda 𝄌 | Kreuz mit Oval | über System | `<coda/>` | 4 | phase-2 |
| Segno 𝄋 | Stilisiertes S mit zwei Punkten und Schrägstrich | über System | `<segno/>` | 4 | phase-2 |
| Doppelter Taktstrich (final) | Zwei vertikale Linien (zweite dicker) | rechter Rand letzter Takt | `<bar-style>final</bar-style>` | 2 | must-have ✅ |

### 2.15 Akkord-Notation (Lead-Sheet)

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Akkord-Symbol `Cm`, `F7`, `G7sus4` | Bold-Text, oft mit Hochstellung | über System, ausgerichtet auf Beat | `<harmony>` | 4 | phase-2 |
| Slash-Chord `C/E` | Akkord-Symbol mit Schrägstrich | wie Akkord | `<harmony>` mit `<bass>` | 4 | phase-2 |

### 2.16 Sonstige Verzierungen

| Symbol | Beschreibung | Position | Bedeutung | Schwierigkeit | Priorität |
|---|---|---|---|---|---|
| Triller `tr` | "tr" + ggf. Wellenlinie | über Notehead | `<trill-mark/>` | 3 | nice-to-have |
| Mordent | Kleine Zickzack-Linie | über Notehead | `<mordent/>` | 4 | phase-2 |
| Vorschlag / Acciaccatura | Kleiner Notehead mit kleinem Stem, oft durchgestrichen | direkt vor Hauptnote | `<grace/>` | 4 | phase-2 |
| Glissando | Welle/Linie zwischen zwei Noteheads | diagonal zwischen Noten | `<glissando/>` | 4 | phase-2 |
| Probenmarken (A, B, C in Box) | Großer Buchstabe in Rechteck | über System | `<rehearsal>` | 3 | nice-to-have |

---

## 3. Layout-Hints — Strukturelle Erwartung

Ein Notenblatt ist nicht zufällig angeordnet. Die OMR-Pipeline kann viele
False Positives vermeiden, wenn sie **vor** der Detektion eine grobe
Bereichs-Karte der Seite aufbaut und pro Bereich nur die plausiblen
Symbol-Klassen sucht.

### 3.1 Bereiche pro Seite

| Bereich | Lage | Erwartete Inhalte | Was hier **nicht** vorkommt |
|---|---|---|---|
| **Header** | oberhalb der ersten Stafflinie der Seite | Titel (groß, zentriert), Untertitel, Komponist (rechts), Arrangeur (rechts), Stimmname (links), Tempo-Bezeichnung, Tonart-Hinweis als Text | Noteheads, Stems |
| **Footer** | unterhalb des letzten Systems | Copyright, Verlagsnummer, Seitenzahl, "Score No.", Stempel | Noteheads, Stems |
| **Über System** | Band der Höhe `≈ 4s` über Top-Linie | Tempo-Marken (italic), Probenmarken (Box-Buchstaben), Volta-Klammern, Slurs nach oben (bei Stems-down), Coda/Segno-Symbole, Triller | Dynamik-Buchstaben |
| **Innerhalb System** | zwischen Top- und Bottom-Linie | Notenköpfe, Akzidenzien direkt vor Noten, Pausen, Punktierungen | Tempo-Text, Dynamik-Text, Liedtext |
| **Unter System** | Band der Höhe `≈ 4s` unter Bottom-Linie | Dynamik (italic), Hairpins, `cresc.`/`dim.`-Text, Slurs nach unten (bei Stems-up), Akkord-Symbole **direkt** unter dem Akkord-Zeitpunkt | Tempo-Marken, Probenmarken |
| **Erster Takt eines Systems** | linker Rand des Systems | Schlüssel, Tonart (Vorzeichen-Block), Taktart | Akzidenzien einzelner Noten |
| **Letzter Takt einer Zeile** | rechter Rand des Systems | Repeat-Marker, doppelter Taktstrich, "D.C.", "Fine" | normale Notenköpfe (eher selten) |

### 3.2 Konsequenz für die Pipeline

* **Header/Footer** werden vor der Detektion als „Skip-Region" markiert
  (kein Notehead-Detektor läuft dort).
* Im Bereich **Über/Unter System** läuft der **Text-Diskriminator zuerst**;
  was er als Text klassifiziert, geht in die Symbol-Library für
  Tempo/Dynamik/Slur, **nicht** in den Notehead-Detektor.
* Nur **Innerhalb System** (plus eine Toleranz von `≈ 1s` für Hilfslinien-
  Noten) ist der Notehead-Detektor zuständig.
* Akkord-Symbole und Liedtext stehen typischerweise **vertikal
  ausgerichtet** an Beat-Positionen — diese Ausrichtung kann als zusätzliches
  Signal dienen.

---

## 4. Text-vs-Musik-Diskriminator

Ziel: Bevor der Notehead-Detektor läuft, werden klar als Text erkannte
Bereiche (Titel, Tempo-Wort, Dynamik, Liedtext, *espressivo* …) markiert
und vom Notehead-Pfad ausgeschlossen.

### 4.1 Heuristiken

* **Connected-Component-Profile:** Text besteht aus vielen kleinen CCs
  ähnlicher Höhe (typische Glyph-Höhe `0.7s..1.5s`), die in einer
  horizontalen Linie aufgereiht sind.
* **Aspect-Ratio einzelner Glyphen:** Buchstaben haben i.d.R.
  `width/height ∈ [0.3, 1.5]`. Notenköpfe haben dagegen ein recht
  konstantes Verhältnis um `1.2` und eine sehr enge Größenverteilung.
* **Vertikale Variation innerhalb einer Gruppe:** In einem Wort
  schwanken die Top-Y-Koordinaten der CCs nur leicht (Ober-/Unterlängen).
  Eine Notenreihe schwankt dagegen oft über mehr als `2s`.
* **Regelmäßiger horizontaler Abstand:** Buchstaben haben kleine,
  vergleichbare Lücken (`< 0.5s`). Notenköpfe in einem Takt haben oft
  variable, größere Lücken (Beat-Abstände, `1s..3s`).
* **Abstand zur nächsten Stafflinie:** Eine Gruppe, deren Mittellinie
  `> 1.5s` über/unter dem System liegt und die nicht zu erwarteten
  Hilfslinien-Bereichen passt, ist sehr wahrscheinlich Text.
* **Stems/Beams in der Nähe:** Hat eine CC keinen plausiblen Stem in
  Reichweite und steht sie in einer typografischen Reihe, → Text.

### 4.2 Pseudo-Code-Skizze (NICHT implementieren!)

```text
fn is_text_region(group: &CCGroup, staff: &StaffSystem) -> TextScore {
    // 1. Mindestens N CCs (z.B. 4) in horizontaler Folge
    // 2. Höhen aller CCs liegen in engem Band: stddev(height) / mean(height) < 0.25
    // 3. Aspect-Ratio jeder CC im typografischen Bereich [0.3, 1.5]
    // 4. Top-Y-Variation innerhalb der Gruppe < 0.6 * mean(height)
    // 5. Horizontale Abstände regelmäßig: stddev(gap) klein, mean(gap) < 0.6s
    // 6. Vertikaler Abstand zur nächsten Stafflinie > 1.5s
    // 7. Keine plausiblen Stems unmittelbar an den CCs
    //
    // Aus 1..7 wird ein gewichteter Score [0..1].
    // Schwelle z.B. 0.7 → "Text", < 0.3 → "Musik", dazwischen → "ambiguous"
    //                      (ambiguous geht in normales Pipeline-Voting).
    //
    // Wird ein Bereich als Text markiert, wandert er an den
    // Symbol-Library-Matcher (Tempo/Dynamik/Articulation-Words) und an
    // einen optionalen OCR-Pfad — aber NICHT mehr in den Notehead-Detektor.
}
```

> Diese Skizze ist bewusst informell. Konkrete Schwellen, Gewichte und die
> Group-Building-Strategie (DBSCAN, Run-Length-Smoothing, …) sind Teil der
> Phase-2-Implementation und sollen gegen das Validierungs-Korpus
> getunt werden (siehe §6).

---

## 5. Implementation-Phasen

| Phase | Inhalt | Liefer-Kontext |
|---|---|---|
| **Phase 1** *(jetzt)* | Notehead, Stem, Beam, Bar — Status quo der OMR-Engine | PR #136 + direkte Folge-PRs |
| **Phase 2** | Text-Diskriminator §4 → verhindert False-Positive-Noteheads in Titel, Tempo-Marken, Dynamik, Liedtext | Folgt direkt nach Phase 1 |
| **Phase 3** | Symbol-Library mit Templates für **must-have**-Symbole: Fermate, Akzent, Staccato, Dynamik (`p`/`mf`/`f`/…), Repeat-Bars, Augmentationspunkt, ganze/halbe/Viertel-Pause | Erste Erweiterung jenseits NH/Stem |
| **Phase 4** | Slur/Tie/Phrasing-Bögen, Crescendo/Decrescendo (Hairpins + Text) | Eigene PR-Reihe |
| **Phase 5** | Layout-Hints §3 vollständig in der Pipeline integriert: Skip-Region für Header/Footer, erwartete Symbole pro Bereich, Beat-Alignment für Akkord-Symbole | Refactor-PR auf Pipeline-Ebene |
| **Phase 6** | Wiederholungs-Semantik: D.C./D.S./Coda/Volta inklusive Score-Linearisierung im MusicXML-Export | Spätestens nach Phase 5 |

Jede Phase hat eigene Akzeptanz-Kriterien gegen das Validierungs-Korpus
(siehe §6). Eine Phase darf erst als "DONE" gelten, wenn die per-Symbol-
Targets erreicht sind.

---

## 6. Template-Quellen

Alle Templates und Referenz-Glyphen stammen aus permissiv lizenzierten
Quellen — **kein Audiveris-Code, keine GPL-/AGPL-Quellen**:

| Quelle | Lizenz | Verwendung |
|---|---|---|
| **Bravura** (SMuFL-Referenzschrift, Steinberg) | SIL Open Font License | Primäre Template-Quelle für alle SMuFL-Symbole (Noteheads, Schlüssel, Akzidenzien, Artikulation, Fermate, …) |
| **Emmentaler** (LilyPond) | SIL OFL | Alternative Stilrichtung; gut für Robustheits-Tests |
| **Synthetisch generiert** | eigen, MIT-kompatibel | Aus SMuFL-Maßangaben gerenderte Templates in mehreren Größen, Rotationen und mit künstlichem Noise (für Scan-Robustheit) |
| **System-Schriften** (für Text-Heuristik) | OFL/Apache/Eigentum des OS | Nur **zur Validierung** des Text-Diskriminators, **nicht** als Template im Vertrieb |

Lizenz-Disziplin:

* Jede Template-Datei trägt einen Header-Kommentar mit Quelle + Lizenz.
* Bravura-/Emmentaler-Glyphen werden über offizielle Distributionen
  bezogen, nicht aus Sekundärquellen.
* Audiveris (AGPL) bleibt explizit ausgeschlossen — siehe Disclaimer
  in `docs/15-omr-pipeline-spec.md §1`.

---

## 7. Ground-Truth & Validierung

Symbol-Detection wird gegen ein **Validierungs-Korpus** gemessen, das aus
zwei Teilen besteht:

1. **Synthetisches Korpus**: aus MusicXML-Beispielen via Renderer
   (LilyPond/Verovio) erzeugte Seiten in mehreren Stilen und mit
   kontrollierter Degradation (Skew, Rauschen, Kompression).
2. **Manuell annotierte Ground-Truth** auf mindestens **3 echten Scans**
   aus dem Vereinsarchiv-Profil (300 dpi, leichte Schiefe, Stempel,
   Annotationen). Annotation als Bounding-Box + Symbol-Klasse.

### 7.1 Per-Symbol Precision/Recall-Targets

| Korpus | must-have | nice-to-have |
|---|---|---|
| **clean** (synthetisch, Verlagsdruck) | P / R ≥ 0.95 | P / R ≥ 0.85 |
| **scan_heavy** (echte Scans, leicht degradiert) | P / R ≥ 0.80 | (Best-Effort, ohne harte Schwelle) |

Reporting:

* Pro PR, der die OMR-Engine berührt: Lauf gegen das gesamte Korpus,
  Tabelle mit P/R/F1 pro Symbol-Klasse als Anhang.
* Regression-Schwelle: **kein** Symbol darf gegenüber `main` mehr als
  2 Prozentpunkte F1 verlieren, ohne dass der Verlust im PR begründet ist.
* Zusätzlich: Confusion-Matrix für die häufigsten Fehlerklassen
  (insbesondere Notehead ↔ Text, Notehead ↔ Akzent, Slur ↔ Tie).

### 7.2 Verbindung zu Phase-Akzeptanz

Eine Phase aus §5 gilt als abgeschlossen, wenn:

* alle in dieser Phase eingeführten Symbol-Klassen ihr Target laut §7.1
  auf `clean` erreichen,
* keine Regression auf zuvor abgeschlossenen Symbol-Klassen entsteht,
* mindestens ein Test gegen `scan_heavy` für jede neue Klasse existiert
  (auch wenn das Target dort weicher ist).

---

## 8. Verweise

* `docs/15-omr-pipeline-spec.md` — Pipeline-Stufen, Datenstrukturen,
  Performance-Ziele
* `docs/16-omr-algorithm-research.md` — Recherche zu OMR-Algorithmen
* `docs/01-functional-spec.md §2.7` — funktionaler Hinweis auf Symbol-
  Library und Layout-Hints
* `.squad/decisions.md` — ADR-OMR-002 (Architektur-Entscheidung für diesen
  Ansatz)
