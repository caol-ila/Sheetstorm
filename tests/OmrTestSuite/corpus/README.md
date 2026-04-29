# OMR Test Suite - Corpus Management

## Übersicht

Diese Sammlung enthält Public-Domain-Notenblätter zur Validierung von OMR (Optical Music Recognition) Algorithmen.

**Status:** 2/13 PDFs heruntergeladen, 11 ausstehend  
**Gesamtgröße:** ~265 KB (heruntergeladen), ~3.5 MB (full corpus mit pending)

---

## Schwierigkeitsgrade

### Leicht (3 geplant, 0 heruntergeladen)
Klare Verlagsdrucke, überwiegend einstimmig oder einfache Akkordstruktur:
- **Händel: Menuett HWV 434** — Baroque clarity, binary form
- **Purcell: Dido and Aeneas** — Vocal melody, moderate accompaniment
- **Telemann: Flute Fantasia** — Solo instrument, ornaments

**Verwendung:** Baseline-Genauigkeit, grundlegende Note/Rest-Erkennung

---

### Mittel (3 geplant, 1 heruntergeladen)
Klassisches Multi-System-Layout, Akkorde, dynamische Markierungen:
- **Mozart: Sonata K.545** — Sonata form, two staves
- **Beethoven: Bagatelle Op.33 No.1** — Romantic-era notation
- **Haydn: Sonata Hob. XVI/21** — Classical trills, grace notes
- **Schubert: Impromptu Op.142 No.2** — Harmonic complexity
- **Schumann: Dichterliebe Op.48 No.1** ✅ (heruntergeladen)

**Verwendung:** Akkordberkennung, mehrfache Notensysteme, dynamische Markierungen

---

### Schwer (2 geplant, 0 heruntergeladen)
Polyphone Strukturen oder dichte Orchesterarrangements:
- **Bach: Invention BWV 773** — Two-part polyphony, baroque complexity
- **Chopin: Prelude Op.28 No.4** — Dense chord clusters, subtle dynamics
- **Brahms: Variations on Haydn Theme** — Extended orchestral arrangement, dense notation

**Verwendung:** Polyphonie-Handhabung, komplexe rhythmische Figuren

---

### Blasmusik-Stimmen (1 geplant, 0 heruntergeladen)
Instrumentalstimmen aus Blasmusik-Partituren:
- **Sousa: Stars and Stripes Forever (Trumpet)** — Transposing instrument, band notation

**Verwendung:** Instrumentale Einzelstimmen, typische Blasmusik-Notation, Wiederholungszeichen

---

## Dateistruktur

```
tests/
  OmrTestSuite/
    corpus/
      manifest.json                                  # Metadaten
      README.md                                      # Diese Datei
      download_corpus.ps1                            # Herunterlade-Skript
      
      leicht-bach-choral-085.pdf                     # ✅ Downloaded
      mittel-schumann-dichterliebe-01.pdf            # ✅ Downloaded
      leicht-handel-minuet-hwv434.pdf                # ⏳ Pending
      leicht-purcell-dido-aeneas.pdf                 # ⏳ Pending
      leicht-telemann-fantasia-flute.pdf             # ⏳ Pending
      mittel-mozart-sonata-k545.pdf                  # ⏳ Pending
      mittel-beethoven-bagatelle-op33-1.pdf          # ⏳ Pending
      mittel-haydn-sonata-hob-xvi-21.pdf             # ⏳ Pending
      mittel-schubert-impromptus-op142-2.pdf         # ⏳ Pending
      schwer-bach-invention-c-major-bwv773.pdf       # ⏳ Pending
      schwer-chopin-prelude-op28-4-e-minor.pdf       # ⏳ Pending
      schwer-brahms-variations-haydn-theme.pdf       # ⏳ Pending
      blasmusik-sousa-stars-stripes-trumpet.pdf      # ⏳ Pending
```

---

## Public-Domain-Verifizierung

**Kriterien für alle Noten:**
1. ✅ Komponist verstorben vor 1956 (>70 Jahre in der EU)
2. ✅ Edition von Verlag/Quelle vor 1928 (außer Länderausnahmen)
3. ✅ Keine modernen kritischen Editionen (die könnten noch geschützt sein)
4. ✅ Lizenziert als Public Domain oder CC0

**Quellen:**
- **IMSLP.org** (International Music Score Library Project) — Größte Public-Domain-Notensammlung
- **archive.org** — Mirror und zusätzliche PD-Sammlungen

---

## Installation / Download der ausstehenden PDFs

### Automatisierter Download (PowerShell)

```powershell
cd tests\OmrTestSuite\corpus
.\download_corpus.ps1
```

### Manueller Download

Jede PDF kann manuell heruntergeladen werden über die URLs in `manifest.json`:

```powershell
# Beispiel:
$url = "https://imslp.simssa.ca/files/imglnks/usimg/4/47/IMSLP23490-Handel_HWV434_Minuet.pdf"
$outfile = "leicht-handel-minuet-hwv434.pdf"
Invoke-WebRequest -Uri $url -OutFile $outfile
```

---

## OMR-Test-Nutzung

Die `manifest.json` wird von OMR-Tests gelesen. Beispiel:

```csharp
using System.Text.Json;

var manifest = JsonSerializer.Deserialize<List<OmrTestCase>>(
    File.ReadAllText("corpus/manifest.json")
);

foreach (var testCase in manifest.Where(t => t.difficulty == "leicht"))
{
    var pdf = testCase.filename;
    var result = new AudioverisOcrEngine().Process(pdf);
    Assert.NotNull(result);
}
```

---

## Lizenzierung und Attribution

Alle Noten sind Public Domain (Komponisten >70 Jahre verstorben). 

**Quellenangabe:**
- Komponist: [Name] (†[Tod-Jahr])
- Verlag: [Originaler Verlag]
- Quelle: IMSLP / archive.org

**Kein Copyright oder License-Warnung erforderlich**, aber es ist höflich, die Quelle (IMSLP) zu erwähnen.

---

## Bekannte Probleme

| Problem | Status | Lösung |
|---------|--------|--------|
| IMSLP Captcha blockt Direktlinks | ⚠️ Häufig | Nutze SIMSSA mirror oder archive.org |
| Beschädigte / nicht-lesbare PDFs | ⚠️ Selten | Re-download oder alternative Edition wählen |
| Zu kleine PDF-Dateien (<50 KB) | ⚠️ Test-Fehler | Datei ist wahrscheinlich eine HTML-Fehlerseite |

---

## Erweiterung des Corpus

Um weitere PDFs hinzuzufügen:

1. **Recherche:** IMSLP.org durchsuchen nach Komponisten mit †-Jahr vor 1956
2. **Verify:** Sicherstellen, dass die **Edition** auch PD ist (nicht nur der Komponist)
3. **Kategorie:** In `manifest.json` nach Schwierigkeit eintragen
4. **Download:** URL hinzufügen und Download-Skript aktualisieren
5. **Validierung:** PDF >50 KB und öffnet korrekt in PDF-Reader

---

## Kontakt / Lizenzfragen

Bei Fragen zu Public-Domain-Status:
- **IMSLP Copyright Info:** https://imslp.org/wiki/Copyright_and_licensing
- **EU Copyright:** Public Domain nach 70 Jahren post mortem (Richtlinie 2006/115/EC)

