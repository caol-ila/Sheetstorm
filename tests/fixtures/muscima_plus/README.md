# MUSCIMA++ Test-Fixtures

Realistische Ground-Truth-Daten für die OMR-Pipeline auf **handschriftlicher**
Notation. Quelle: das MUSCIMA++-Korpus (Hajič jr. & Pecina, ICDAR 2017).

## ⚠️ Lizenz-Warnung — Daten sind NICHT im Repo enthalten

Sheetstorm wird unter **Apache-2.0** distribuiert (siehe `LICENSE-APACHE-2.0.txt`).
MUSCIMA++ und das zugrundeliegende CVC-MUSCIMA-Korpus sind dagegen unter
**CC-BY-NC-SA 4.0** lizenziert — der **NonCommercial**-Klausel wegen
**inkompatibel** mit Apache-2.0.

Daher werden die Daten

* **nicht** im Repo eingecheckt (siehe `.gitignore` in diesem Verzeichnis),
* **nicht** in Release-Builds, Docker-Images oder verteilten Artefakten
  ausgeliefert,
* **nur** lokal von Entwicklern für nicht-kommerzielle Test-/Forschungszwecke
  abgerufen.

Die ursprüngliche Aufgabenstellung ging fälschlich von "CC-BY 4.0" aus — die
korrekte Lizenz steht auf <https://ufal.mff.cuni.cz/muscima> und in der mit dem
Datensatz ausgelieferten LICENSE-Datei.

## Was wird gebraucht?

Pro Testfall ein Paar `<stem>.png` + `<stem>.xml`:

| Stem (Dateiname)       | Inhalt / Schwerpunkt                          | Quelle (Vorschlag)                              |
|------------------------|-----------------------------------------------|-------------------------------------------------|
| `easy_01_scale`        | Einfache Tonleiter, wenig Beam-Gruppen        | `CVC-MUSCIMA_W-01_N-19_D-ideal`                 |
| `medium_02_beams`      | Viele 8tel-/16tel-Beam-Gruppen                | `CVC-MUSCIMA_W-02_N-06_D-ideal`                 |
| `medium_03_voltas`     | Wiederholungen mit Volta-Klammern             | `CVC-MUSCIMA_W-13_N-16_D-ideal`                 |
| `hard_04_polyphony`    | Mehrstimmigkeit, Akkorde, mehrere Voices      | `CVC-MUSCIMA_W-15_N-15_D-ideal`                 |
| `medium_05_slurs`      | Bögen / Bindebögen                            | `CVC-MUSCIMA_W-31_N-07_D-ideal`                 |
| `medium_06_band`       | Typisches Vereinslied (Marsch, 4/4)           | `CVC-MUSCIMA_W-30_N-13_D-ideal`                 |
| `easy_07_quarters`     | Viertel-Noten, klare Bars                     | `CVC-MUSCIMA_W-12_N-04_D-ideal`                 |
| `medium_08_keysig`     | Vorzeichen-Wechsel                            | `CVC-MUSCIMA_W-28_N-08_D-ideal`                 |
| `medium_09_dynamics`   | Dynamik-Hairpins, Articulation                | `CVC-MUSCIMA_W-39_N-12_D-ideal`                 |
| `hard_10_dense`        | Dichte Notation, viele Symbole                | `CVC-MUSCIMA_W-15_N-14_D-ideal`                 |
| `easy_11_clear`        | Sehr saubere Handschrift                      | `CVC-MUSCIMA_W-31_N-01_D-ideal`                 |
| `medium_12_mixed`      | Gemischte Rhythmen, Triolen                   | `CVC-MUSCIMA_W-30_N-17_D-ideal`                 |

(Konkrete Writer/Sheet-Auswahl ist ein Vorschlag — entscheidend ist die
**Vielfalt** an Komplexitätsmerkmalen, nicht die exakten IDs.)

## Manuelle Beschaffung (lokal, nicht-kommerziell)

### 1. MuNG-Annotationen (klein, ~11 MB)

```powershell
$ROOT = (git rev-parse --show-toplevel).Trim()
$DEST = Join-Path $ROOT "tests/fixtures/muscima_plus"
$WORK = Join-Path $env:TEMP "muscima_pp_work"
New-Item $WORK -ItemType Directory -Force | Out-Null

Invoke-WebRequest `
    -Uri "https://github.com/OMR-Research/muscima-pp/releases/download/v2.0/MUSCIMA-pp_v2.0.zip" `
    -OutFile "$WORK\muscima.zip"
Expand-Archive "$WORK\muscima.zip" -DestinationPath "$WORK\muscima" -Force
```

### 2. CVC-MUSCIMA Bilddaten (~2 GB Gesamtgröße)

Die binären Notenseiten kommen aus dem CVC-MUSCIMA-Datensatz und sind
**separat** zu beziehen:

* <http://www.cvc.uab.es/cvcmuscima/index_database.html>
* Konkret das Sub-Paket `CVCMUSCIMA_WI.zip` (Writer Identification),
  enthält `ideal/w-XX/ideal/p0YY.png`.

Das Repo lädt diese Daten **nicht automatisch**, weil die CVC-Webseite
keine garantiert stabile Direkt-URL bietet und die Lizenz NC ist.

### 3. Auswahl in `tests/fixtures/muscima_plus/` einsortieren

Für jedes oben gelistete Stem-Paar:

```powershell
# Beispiel für easy_01_scale (Writer 01, Sheet 19)
Copy-Item "$WORK\muscima\v2.0\data\annotations\CVC-MUSCIMA_W-01_N-19_D-ideal.xml" `
          "$DEST\easy_01_scale.xml"
Copy-Item "<pfad-zur-CVC-MUSCIMA>\ideal\w-01\ideal\p019.png" `
          "$DEST\easy_01_scale.png"
```

Wichtig: **Bounding-Boxen in den XMLs sind absolut auf das Original-PNG
bezogen** — verändere die PNG-Dimensionen nicht (kein Resize, kein Crop).

## Tests aktivieren

Die MUSCIMA-Tests sind standardmäßig `#[ignore]`, so dass
`cargo test --workspace` ohne lokale Daten grün durchläuft. Mit Daten:

```powershell
cd src\omr-rust
cargo test -p omr-pipeline --test accuracy_bench -- --ignored --nocapture muscima
```

Die Asserts in `accuracy_bench.rs` verlangen 45–60 % Recall — bewusst niedrig,
weil eine ML-freie Pipeline auf Handschrift schlechter abschneidet als auf
synthetischer Notation. Die Tests dienen als **Regressions-Wächter**, nicht
als Ziel-SLA.

## XML-Format-Referenz (MuNG)

Vollständige Spec: <https://muscimarker.readthedocs.io/en/develop/instructions.html>.
Kurz-Schema:

```xml
<Nodes dataset="MUSCIMA-pp_2.0" document="CVC-MUSCIMA_W-01_N-19_D-ideal">
  <Node>
    <Id>0</Id>
    <ClassName>noteheadFull</ClassName>
    <Top>372</Top> <Left>494</Left> <Width>29</Width> <Height>20</Height>
    <Mask>0:15 1:10 0:14 1:16 ...</Mask>   <!-- RLE pixel mask -->
    <Outlinks>730 575 ...</Outlinks>        <!-- MuNG-Graph-Kanten -->
  </Node>
  ...
</Nodes>
```

Klassennamen-Vokabular siehe
`v2.0/specifications/mff-muscima-mlclasses-annot.xml` im Release.

Loader: `src/omr-rust/crates/omr-pipeline/src/muscima.rs`.

## Attribution (bei Nutzung der Daten)

Wenn du die heruntergeladenen Daten lokal verwendest, zitiere:

> Jan Hajič jr. and Pavel Pecina. **The MUSCIMA++ Dataset for Handwritten
> Optical Music Recognition**. *14th International Conference on Document
> Analysis and Recognition*, ICDAR 2017, Kyoto, pp. 39–46, 2017.

> Alicia Fornés, Anjan Dutta, Albert Gordo, Josep Lladós. **CVC-MUSCIMA: A
> Ground-truth of Handwritten Music Score Images for Writer Identification
> and Staff Removal**. *International Journal on Document Analysis and
> Recognition*, Vol. 15, Issue 3, pp. 243–251, 2012.
