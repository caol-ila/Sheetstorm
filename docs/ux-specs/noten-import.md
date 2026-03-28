# UX-Spec: Noten-Import & Labeling — Sheetstorm

> **Issue:** #19
> **Version:** 1.0
> **Status:** Entwurf
> **Autorin:** Wanda (UX Designer)
> **Datum:** 2026-03-28
> **Meilenstein:** M1 — Kern: Noten & Kapelle
> **Referenzen:** `docs/ux-design.md`, `docs/anforderungen.md`, `docs/spezifikation.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Design-Prinzipien](#1-übersicht--design-prinzipien)
2. [Flow A: Upload — Drag&Drop / Datei wählen / Kamera](#2-flow-a-upload)
3. [Flow B: Labeling — Seiten einem Lied zuordnen](#3-flow-b-labeling)
4. [Flow C: AI-Metadaten-Erkennung & manuelle Korrektur](#4-flow-c-ai-metadaten-erkennung--manuelle-korrektur)
5. [Flow D: Stimmen-Zuordnung nach Erkennung](#5-flow-d-stimmen-zuordnung)
6. [Flow E: Review & Bestätigung](#6-flow-e-review--bestätigung)
7. [Edge Cases](#7-edge-cases)
8. [Wireframes: Phone](#8-wireframes-phone)
9. [Wireframes: Tablet](#9-wireframes-tablet)
10. [Abhängigkeiten für Hill (Frontend)](#10-abhängigkeiten-für-hill-frontend)

---

## 1. Übersicht & Design-Prinzipien

### 1.1 Nutzer-Kontext

Der Noten-Import ist der **kritischste Onboarding-Flow für Notenwarte**. Wenn dieser Flow mühsam ist, wird die App nicht angenommen — egal wie gut der Spielmodus ist.

**Realität:** Ein Notenwart sitzt vor einem Stapel von 200 PDF-Scans einer Blaskapelle. Er will diese nicht einzeln hochladen und manuell beschriften. Er will: hochladen, kurz durchklicken, fertig.

**Primäre Persona:** Notenwart — lädt regelmäßig neue Noten hoch, verwaltet das Archiv der Kapelle.

**Sekundäre Persona:** Musiker (persönliche Sammlung) — lädt eigene Noten von seinem Scanner, Kamera oder Cloud-Storage hoch.

### 1.2 Design-Prinzipien für Import

1. **Upload-First:** Den Upload so schnell wie möglich starten. Kein Formular ausfüllen bevor der Upload läuft.
2. **AI-arbeitet-im-Hintergrund:** Während der Nutzer weitere Dateien auswählt, läuft die AI-Erkennung bereits.
3. **Batch-freundlich:** Mehrere PDFs gleichzeitig importieren — nicht eines nach dem anderen.
4. **Korrigieren, nicht neu eingeben:** AI-Vorschläge sind immer Vorausfüllung. Der Nutzer bestätigt oder korrigiert — nie auf leeres Formular.
5. **Fortschritt ist sichtbar:** Lange Prozesse (große PDFs, AI-Analyse) zeigen ehrlichen Fortschritt, keinen Fake-Progress-Bar.

### 1.3 Einstiegspunkte

| Kontext | Aktion |
|---------|--------|
| Bibliothek (leer) | Prominenter "Erste Noten hochladen"-Button |
| Bibliothek (mit Inhalt) | FAB `[+]` unten rechts → Import-Optionen |
| Toolbar → Import-Button | Direktzugriff für Notenwarte |
| Deep-Link `sheetstorm://import` | z.B. aus Share-Sheet |

---

## 2. Flow A: Upload

### 2.1 Upload-Methoden

| Methode | Plattform | Beschreibung |
|---------|-----------|-------------|
| **Drag & Drop** | Desktop/Web, Tablet | Dateien direkt in Upload-Zone ziehen |
| **Datei wählen** | Alle | System-Dateidialog öffnen |
| **Kamera** | Phone/Tablet | Direktaufnahme mit Kamera, mehrseitig |
| **Cloud-Storage** | Alle | OneDrive, Dropbox, Google Drive (Picker) |
| **Teilen aus anderer App** | Mobile | iOS/Android Share-Sheet → Sheetstorm |

### 2.2 Upload-Screen (Einstieg)

**Leere Importzone (Desktop/Tablet):**
```
┌──────────────────────────────────────────────────┐
│                                                  │
│              ⬆  Noten hochladen                  │
│                                                  │
│     Dateien hierher ziehen oder auswählen        │
│                                                  │
│     Unterstützt: PDF, JPG, PNG, HEIC             │
│     Max. 50 MB pro Datei · mehrere gleichzeitig  │
│                                                  │
│  ┌───────────────────┐  ┌──────────────────────┐ │
│  │  📁 Datei wählen  │  │  ☁ Cloud-Storage     │ │
│  └───────────────────┘  └──────────────────────┘ │
│                                                  │
│               [📷 Kamera]   ← nur Mobile         │
└──────────────────────────────────────────────────┘
```

### 2.3 Drag & Drop — Interaktion

**Hover-Zustand:**
- Upload-Zone leuchtet auf (Hintergrundfarbe wechselt zu Blau/Primärfarbe, 20% Opacity)
- Gestrichelte Border wird solid
- Text: „Loslassen zum Hochladen"

**Mehrere Dateien:**
- Alle werden angenommen
- Badge: „12 Dateien erkannt"
- Start der Uploads sofort nach Drop

**Falsche Dateitypen:**
- Inline-Warnung: „2 Dateien konnten nicht gelesen werden (docx, mp3). Unterstützt: PDF, JPG, PNG, HEIC."
- Gültige Dateien werden trotzdem hochgeladen

### 2.4 Kamera-Flow (Phone)

```
Schritt 1: Kamera-Screen
→ Anweisung: „Notenblatt fotografieren. Seite liegt flach, gute Beleuchtung."
→ Auto-Crop-Erkennung (Ecken werden erkannt, rechteckiges Overlay)
→ [📸 Aufnehmen]
→ Nach Aufnahme: „Weitere Seite?" → [Weiter fotografieren] / [Fertig]

Schritt 2: Scan-Ergebnis-Preview
→ Aufgenommene Seiten als Thumbnails
→ Qualitäts-Indikator pro Seite (grün/gelb/rot)
→ Schlechte Qualität: Hinweis „Diese Seite könnte unscharf sein. [Neu aufnehmen]"
→ [Upload starten →]
```

### 2.5 Upload-Fortschritt

**Während des Uploads (mehrere Dateien):**
```
Upload läuft...
────────────────────────────────
📄 Marsch_Blasmusik.pdf     ████████░░  80%
📄 Polka_Festzug.pdf        ██████████ ✓
📄 Konzertmarsch.pdf        ░░░░░░░░░░  0%  (Queue)
📄 20240301_scan.jpg        █████░░░░░  50%

4 Dateien · 2.4 / 12.8 MB hochgeladen
────────────────────────────────
[Abbrechen]   [Hintergrund]
```

**„Hintergrund"-Button:** Upload läuft weiter während Nutzer andere Dinge macht — Statusanzeige in der Bottom-Navigation.

**Nach Upload:** Automatisch weiter zu Flow B (Labeling).

---

## 3. Flow B: Labeling

### 3.1 Konzept

Ein hochgeladenes PDF kann **mehrere Lieder** enthalten. Der Nutzer sieht alle Seiten als Thumbnails und markiert, wo neue Lieder beginnen.

**Ziel:** So schnell wie möglich durch viele Seiten klicken. Keine unnötigen Taps.

### 3.2 Labeling-Screen — Grundlayout

**Standard-Modus (AI schlägt Trennungen vor):**

AI analysiert das Dokument und schlägt automatisch Lied-Grenzen vor (erkennbar an Titeln, Seiten-Nummerierungswechsel, Notenformat-Änderungen). Der Nutzer sieht die Vorschläge und kann korrigieren.

```
Seiten zuordnen                    12 Seiten erkannt
──────────────────────────────────────────────────────
  AI hat 3 Lieder erkannt. Bitte prüfe und korrigiere.
──────────────────────────────────────────────────────

  LIED 1  [Titel wird erkannt...]              [✎ Edit]
  ┌────┐  ┌────┐  ┌────┐  ┌────┐
  │ 1  │  │ 2  │  │ 3  │  │ 4  │
  │[🎵]│  │[🎵]│  │[🎵]│  │[🎵]│
  └────┘  └────┘  └────┘  └────┘
  Seiten 1–4

  [+ Hier neues Lied beginnen]  ← zwischen Lied 1 und 2

  LIED 2  „Böhmischer Traum"                   [✎ Edit]
  ┌────┐  ┌────┐  ┌────┐
  │ 5  │  │ 6  │  │ 7  │
  │[🎵]│  │[🎵]│  │[🎵]│
  └────┘  └────┘  └────┘
  Seiten 5–7

  [+ Hier neues Lied beginnen]

  LIED 3  „Alpenrose Marsch"                   [✎ Edit]
  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐
  │ 8  │  │ 9  │  │ 10 │  │ 11 │  │ 12 │
  │[🎵]│  │[🎵]│  │[🎵]│  │[🎵]│  │[🎵]│
  └────┘  └────┘  └────┘  └────┘  └────┘
  Seiten 8–12

──────────────────────────────────────────────────────
  [Alles löschen]          [Weiter: Metadaten →]
```

### 3.3 Seite verschieben

- **Drag & Drop:** Seite in andere Gruppe ziehen
- **Long-Press:** Seite anwählen → Kontext-Menu: „Zu Lied 1" / „Zu Lied 2" / „Neues Lied erstellen"
- **Tap auf Seite:** Seite im Vollbild ansehen (zur Orientierung)

### 3.4 Lied-Grenzen manuell setzen

- **`[+ Hier neues Lied beginnen]`** zwischen zwei Seiten-Gruppen: Teilt die aktuelle Gruppe
- **Gruppen zusammenführen:** Lied-1-Header tap → Menü „Mit vorherigem Lied zusammenführen"
- **Gruppe löschen:** Lied-Header → „Dieses Lied entfernen" (Seiten bleiben im Pool, nicht gelöscht)

### 3.5 Ein Bild / eine Seite

Wenn nur eine einzelne Seite hochgeladen wurde:
- Kein Labeling-Schritt nötig
- Direkt zu Flow C (Metadaten) springen
- Kurze Info: „Eine Seite erkannt — direkt zur Metadaten-Eingabe."

### 3.6 Großes PDF (>20 Seiten)

Besonderer Modus: Kompakte Thumbnail-Ansicht + Schnell-Navigation.

- Thumbnails kleiner (3 pro Zeile statt 4)
- Seitenleiste mit Lied-Übersicht (scroll)
- Tastaturkürzel (Desktop): Enter = „Gleiche Gruppe", Space = „Neue Gruppe beginnen"
- „Alles akzeptieren" Button wenn AI-Erkennung gut genug aussieht

---

## 4. Flow C: AI-Metadaten-Erkennung & manuelle Korrektur

### 4.1 AI-Erkennungs-Prozess

Die AI läuft **im Hintergrund** während der Nutzer noch im Labeling-Schritt ist. Wenn Metadaten erkannt werden, erscheinen sie bereits ausgefüllt wenn der Nutzer zu Schritt C kommt.

**Erkannte Felder:**

| Feld | AI-Quelle | Vertrauen |
|------|-----------|-----------|
| Titel | OCR auf Titelseite / Kopfzeile | Hoch |
| Komponist | OCR + Musikdatenbank-Abgleich | Mittel |
| Stimme/Register | OCR auf Notenblatt-Kopf | Hoch |
| Tonart | Notenanalyse (Vorzeichen) | Mittel |
| Takt | Notenanalyse | Hoch |
| Genre | Klassifikation (Marsch/Polka/Walzer/…) | Mittel |
| GEMA-Werk-Nummer | Datenbankabgleich | Niedrig |

**Konfidenz-Anzeige:**
- Hohes Vertrauen: Feld vorausgefüllt, grüner Checkmark
- Mittleres Vertrauen: Feld vorausgefüllt, gelbes Warn-Icon, Hinweis „Bitte prüfen"
- Niedriges Vertrauen: Feld leer, grauer Text „AI konnte nichts erkennen"

### 4.2 Metadaten-Formular (pro Lied)

```
Lied 1 von 3: Metadaten                  ← Lied-Selektor oben
──────────────────────────────────────────

  [Thumbnail Lied 1]  „Böhmischer Traum"
                       Seiten 1–4

GRUNDDATEN
  Titel *
  ┌──────────────────────────────────────┐
  │ Böhmischer Traum           ✓ AI      │ ← grüner Check = KI-Erkennung
  └──────────────────────────────────────┘

  Komponist
  ┌──────────────────────────────────────┐
  │ Ernst Mosch                ⚠ prüfen  │ ← gelb = unsicher
  └──────────────────────────────────────┘

  Genre / Stil
  ┌──────────────────────────────────────┐
  │ Polka                      ✓ AI      │
  └──────────────────────────────────────┘

  Tonart
  ┌──────────────────────────────────────┐
  │ B-Dur                      ✓ AI      │
  └──────────────────────────────────────┘

  Tempo / BPM (optional)
  ┌──────────────────────────────────────┐
  │                                      │ ← leer, optional
  └──────────────────────────────────────┘

  Jahr (optional)
  ┌──────────────────────────────────────┐
  │ 1960                       ⚠ prüfen  │
  └──────────────────────────────────────┘

GEMA (optional, für Pro-Tier)
  Werk-Nummer
  ┌──────────────────────────────────────┐
  │                          AI: unklar  │
  └──────────────────────────────────────┘

  [Alle als „kein GEMA-Eintrag" markieren]

──────────────────────────────────────────
  Dieses Lied wurde importiert:
  ☐ Für Kapelle: Stadtkapelle Musterstadt
  ☑ Für meine persönliche Sammlung
──────────────────────────────────────────
  [← Zurück]    [Nächstes Lied →]
                 2 weitere Lieder offen
```

### 4.3 Auto-Vervollständigung

- Titel-Feld: Suche in der eigenen Bibliothek + öffentlichem Notenregister (falls verfügbar)
- „Dieses Stück existiert bereits in deiner Bibliothek" → Option: „Stimme hinzufügen" statt neues Stück

### 4.4 KI nicht verfügbar

Wenn kein AI-Key konfiguriert ist (weder Nutzer noch Kapelle):

```
╔══════════════════════════════════════╗
║  ℹ AI-Erkennung nicht verfügbar      ║
║                                      ║
║  Kein AI-Key konfiguriert. Du kannst ║
║  Metadaten manuell eingeben oder     ║
║  einen Key in den Einstellungen      ║
║  hinterlegen.                        ║
║                                      ║
║  [Einstellungen]   [Manuell eingeben]║
╚══════════════════════════════════════╝
```

Alle Felder sind leer — Nutzer füllt manuell aus. Pflichtfelder markiert mit `*`.

### 4.5 „Bulk-Metadaten" für gleichartige Importe

Wenn mehrere Lieder erkannt wurden und der Nutzer möchte gemeinsame Felder für alle setzen:

- „Auf alle anwenden": Kapellen-Zuweisung, Genre, Jahr — kann für alle Lieder im Batch gesetzt werden
- Individuell überschreibbar pro Lied

---

## 5. Flow D: Stimmen-Zuordnung

### 5.1 Konzept

Jede Seite gehört zu einer Stimme (z.B. „1. Klarinette"). Die AI versucht, Stimmen-Bezeichnungen aus dem Notenkopf zu lesen und automatisch zuzuordnen.

### 5.2 Stimmen-Erkennungs-Screen

```
Stimmen zuordnen: „Böhmischer Traum"
────────────────────────────────────────────────

  AI hat folgende Stimmen erkannt:

  ┌──────────────────────────────────────────┐
  │ Seite 1  [Thumbnail]  → 1. Klarinette ✓  │ ← AI erkannt
  │ Seite 2  [Thumbnail]  → 2. Klarinette ✓  │
  │ Seite 3  [Thumbnail]  → Es-Klarinette ⚠  │ ← unsicher
  │ Seite 4  [Thumbnail]  → Flöte         ✓  │
  └──────────────────────────────────────────┘

  NICHT ZUGEORDNET (2 Seiten)
  ┌──────────────────────────────────────────┐
  │ Seite 5  [Thumbnail]  → ?                │ ← Nutzer muss wählen
  │ Seite 6  [Thumbnail]  → ?                │
  └──────────────────────────────────────────┘

────────────────────────────────────────────────
  [← Zurück]            [Weiter: Review →]
```

### 5.3 Stimme manuell zuordnen

**Tap auf eine Zeile → Stimmen-Picker:**

```
Stimme wählen für Seite 5
────────────────────────────────────
  🔍 Stimme suchen...

  — MEINE INSTRUMENTE (oben)
  ✓ 1. Klarinette
    2. Klarinette
    Es-Klarinette

  — WEITERE STIMMEN DER KAPELLE
    Flöte
    Oboe
    1. Trompete
    2. Trompete
    Flügelhorn
    Posaune
    Tuba
    …

  — ANDERE
    [+ Neue Stimme eingeben]
────────────────────────────────────
```

- Stimmen des Nutzers eigenen Instruments erscheinen oben (Sortierung aus Anforderungen.md 1.1a)
- Freitext-Eingabe für unbekannte Stimmen — wird als neue Stimme angelegt
- Alias-Mechanismus: „Klar. I" → „1. Klarinette" (vom Notenwart konfiguriert, aus Flow D §1.5)

### 5.4 Mehrseiter: Stimme für mehrere Seiten gleichzeitig

- Checkbox vor jeder Zeile → Mehrfachauswahl
- „Alle markierten → Stimme X zuordnen"
- Nützlich wenn ein Stück viele Seiten gleicher Stimme hat

### 5.5 Stimme unbekannt / nicht relevant

- Option: „Diese Seite gehört keiner Stimme" (z.B. Titelblatt, leere Seite)
- Solche Seiten werden als „Cover" oder „Sonstiges" markiert und können ignoriert oder als Titelseite gespeichert werden

---

## 6. Flow E: Review & Bestätigung

### 6.1 Review-Screen

Eine Zusammenfassung aller zu importierenden Lieder vor dem endgültigen Speichern.

```
Review: 3 Lieder bereit zum Importieren
──────────────────────────────────────────────────────

  ✓ Böhmischer Traum
    Ernst Mosch · Polka · B-Dur
    4 Stimmen: 1.Klar, 2.Klar, Es-Klar, Flöte
    Für: Stadtkapelle Musterstadt + Meine Sammlung

  ⚠ Alpenrose Marsch                   [✎ Bearbeiten]
    Komponist fehlt · Genre: Marsch
    5 Stimmen: komplett
    Für: Stadtkapelle Musterstadt
    → Empfehlung: Komponist ergänzen

  ✓ Konzertmarsch Nr. 3
    Karl Müller · Marsch · Es-Dur
    6 Stimmen erkannt: komplett
    Für: Stadtkapelle Musterstadt

──────────────────────────────────────────────────────

  WARNUNGEN
  ⚠ 1 Lied hat fehlende Pflichtmetadaten (Komponist optional)
  ℹ 2 Stimmen konnten nicht automatisch erkannt werden — wurden manuell zugeordnet

──────────────────────────────────────────────────────
  [← Zurück]         [Jetzt importieren ✓]
```

### 6.2 Teilweiser Import

- Einzelne Lieder können aus dem Import entfernt werden: Lied-Karte → „Aus diesem Import entfernen"
- Entfernte Lieder werden nicht importiert, aber auch nicht gelöscht (können später erneut importiert werden)

### 6.3 Import-Fortschritt

```
Import läuft...
────────────────────────────────────────
  ✓ Böhmischer Traum         Gespeichert
  ⟳ Alpenrose Marsch         Wird verarbeitet...
  ○ Konzertmarsch Nr. 3      Wartet

  Thumbnails werden generiert... 67%
  Noten werden an Mitglieder verteilt...
────────────────────────────────────────
  [Im Hintergrund ausführen]
```

### 6.4 Erfolgs-Screen

```
  ✓  3 Lieder importiert!

  ┌────────────────────────────────────┐
  │  Böhmischer Traum         [›]      │
  │  Alpenrose Marsch         [›]      │
  │  Konzertmarsch Nr. 3      [›]      │
  └────────────────────────────────────┘

  [Weitere Noten hochladen]
  [Zur Bibliothek]
```

---

## 7. Edge Cases

### 7.1 Große PDFs (>50 Seiten)

**Problem:** Ladezeit und Labeling-Aufwand bei sehr großen Dateien.

**Lösung:**
- Upload-Limit: 50 MB pro Datei (konfigurierbar pro Kapelle)
- Bei >30 Seiten: Warnung vor Upload + Empfehlung die Datei zu teilen
- Während Upload: Seiten werden streaming verarbeitet (nicht erst nach vollständigem Upload)
- AI-Analyse läuft parallel zu Upload (Seiten kommen rein, AI analysiert sofort)
- Labeling-Screen zeigt Fortschrittsindikator: „Seite 1–12 von 47 geladen"
- Virtualisierte Thumbnail-Liste (nur sichtbare Thumbnails werden gerendert, Performance)
- „Aufteilen"-Option: Großes PDF automatisch bei erkannten Lied-Grenzen teilen → mehrere kleinere Imports

**UX:**
```
  ⚠ Diese Datei hat 67 Seiten.

  Der Import kann einige Minuten dauern.
  Die AI analysiert bereits im Hintergrund.

  [Trotzdem importieren]   [Datei aufteilen (empfohlen)]
```

### 7.2 Schlechte Bildqualität

**Erkennung:**
- Unschärfe-Detection: Sharpness-Score unter Schwellwert → Warnung
- Kontrast zu niedrig: Text-Erkennungsrate < 60%
- Verdrehte Seiten: Rotation >5° erkannt → Auto-Korrektur anbieten

**Feedback pro Seite in Thumbnail-Ansicht:**
- 🟢 Gut (Erkennungsrate >85%)
- 🟡 Akzeptabel (60–85%): „AI-Erkennung eingeschränkt"
- 🔴 Schlecht (<60%): „Schlechte Qualität — bitte neu scannen oder manuell eingeben"

**Optionen bei schlechter Qualität:**
```
  📷 Seite 3 hat schlechte Qualität (Score: 42%)

  ┌────────────────────────────────────┐
  │  [Seite neu aufnehmen]             │
  │  [Trotzdem importieren]            │
  │  [Metadaten manuell eingeben]      │
  └────────────────────────────────────┘
```

**Auto-Korrektur (wo möglich):**
- Verdrehte Seiten: automatisch begradigen (OCR-Preprocessing)
- Zu dunkle Scans: Helligkeit/Kontrast-Anpassung
- Nutzer sieht Original vs. Korrigiert: [Original] [Korrigiert ✓]

### 7.3 Mehrere Lieder in einem Dokument

**Normalfall:** AI erkennt Lied-Grenzen (Titelseitenformat, neue Kopfzeile, Seitennummerierungs-Reset).

**Wenn AI unsicher:**
- Markiert betroffene Übergänge mit `?` statt automatischer Trennung
- Nutzer entscheidet für diese Übergänge

**Manuell-Modus für komplexe Dokumente:**
- Alle AI-Vorschläge verwerfen: „Komplett manuell einteilen"
- Chronologische Seiten-Ansicht, Nutzer setzt Grenzen per Tap

**Spezialfall: Stimmen-Heft**
- Ein Dokument enthält die gleiche Stimme durch das gesamte Repertoire
- Erkennbar: Gleicher Stimmen-Vermerk auf allen Seiten, verschiedene Stücknamen
- AI-Erkennung: „Stimmen-Heft erkannt: 1. Klarinette, 12 Stücke"
- Labeling dann: Nur Stück-Grenzen markieren, Stimme ist global

### 7.4 Bereits importiertes Dokument

**Duplikat-Erkennung (hash-basiert):**
```
  ⚠ Diese Datei wurde bereits importiert.

  „Böhmischer Traum" (vor 3 Monaten)
  4 Stimmen · In 2 Setlists verwendet

  Was möchtest du tun?
  ◉ Vorhandenes Stück behalten (Import abbrechen)
  ○ Neue Version importieren (ersetzt die alte)
  ○ Als Duplikat mit anderen Metadaten importieren

  [Bestätigen]
```

### 7.5 Kamera-Import: Mehrseitige Aufnahme

- Nach jeder Aufnahme: sofortige Qualitätsanzeige (gut/schlecht)
- Bei schlechter Qualität: Direktes Neuaufnehmen anbieten
- Seiten-Reihenfolge sortierbar nach Aufnahme (drag & drop)
- Automatisches Zuschneiden (perspective correction) wenn 4 Ecken erkannt

### 7.6 Offline-Verhalten

- Upload startet sofort, wird in lokale Queue gestellt wenn offline
- Fortschrittsanzeige: „Datei wird hochgeladen sobald Verbindung verfügbar"
- Nach Verbindungswiederherstellung: automatischer Upload ohne Nutzer-Interaktion
- Metadaten-Eingabe ist offline möglich (lokal gespeichert, sync später)
- AI-Erkennung erfordert Online-Verbindung — Feld bleibt leer, manuell ausfüllbar

### 7.7 Import-Fehler / Unterbrochener Import

- Jeder Schritt wird lokal gespeichert (Crash-Recovery)
- Nach App-Neustart: „Du hattest einen Import in Arbeit. Fortfahren?"
- Teilweise hochgeladene Dateien: Resume-Upload (kein erneuter vollständiger Upload)
- Fehlgeschlagene Lieder: einzeln erneut versuchen, nicht den gesamten Batch

---

## 8. Wireframes: Phone

### 8.1 Import-Startscreen (Phone)

```
╔══════════════════════════════════╗
║ ←  Noten importieren       [✕]  ║
╠══════════════════════════════════╣
║                                  ║
║  ┌──────────────────────────┐    ║
║  │                          │    ║
║  │   ⬆                      │    ║
║  │                          │    ║
║  │  Tippe um Dateien        │    ║
║  │  auszuwählen             │    ║
║  │                          │    ║
║  │  PDF, JPG, PNG, HEIC     │    ║
║  └──────────────────────────┘    ║
║                                  ║
║  ┌──────────┐  ┌──────────────┐  ║
║  │ 📁 Datei │  │ ☁ Cloud      │  ║
║  └──────────┘  └──────────────┘  ║
║                                  ║
║  ┌──────────────────────────┐    ║
║  │ 📷 Mit Kamera scannen    │    ║
║  └──────────────────────────┘    ║
║                                  ║
╠══════════════════════════════════╣
║  📋  🎵  📅  👤                  ║
╚══════════════════════════════════╝
```

### 8.2 Upload läuft (Phone)

```
╔══════════════════════════════════╗
║ ←  Noten importieren             ║
╠══════════════════════════════════╣
║                                  ║
║  3 Dateien werden hochgeladen    ║
║                                  ║
║  📄 Marsch_Blasmusik.pdf         ║
║  ████████░░  80%  1.2 MB / 1.5MB ║
║                                  ║
║  📄 Polka_Festzug.pdf        ✓   ║
║  AI analysiert...  ⟳             ║
║                                  ║
║  📄 Konzertmarsch.pdf            ║
║  ░░░░░░░░░░  In Warteschlange    ║
║                                  ║
║  ─────────────────────────────   ║
║  [+ Weitere Dateien hinzufügen]  ║
║                                  ║
║  ─────────────────────────────   ║
║         [Im Hintergrund]         ║
╚══════════════════════════════════╝
```

### 8.3 Labeling-Screen (Phone)

```
╔══════════════════════════════════╗
║ ←  Seiten zuordnen      3 Lieder ║
╠══════════════════════════════════╣
║  AI hat 3 Lieder erkannt. Prüfen.║
╠══════════════════════════════════╣
║                                  ║
║  LIED 1  [Titel erkannt...] [✎]  ║
║  ┌──┐ ┌──┐ ┌──┐ ┌──┐            ║
║  │1 │ │2 │ │3 │ │4 │            ║
║  └──┘ └──┘ └──┘ └──┘            ║
║                                  ║
║  ┄┄┄┄ [+ Neues Lied hier] ┄┄┄┄  ║
║                                  ║
║  LIED 2  „Böhmischer Traum" [✎]  ║
║  ┌──┐ ┌──┐ ┌──┐                 ║
║  │5 │ │6 │ │7 │                 ║
║  └──┘ └──┘ └──┘                 ║
║                                  ║
║  ┄┄┄┄ [+ Neues Lied hier] ┄┄┄┄  ║
║                                  ║
║  LIED 3  „Alpenrose Marsch" [✎]  ║
║  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐      ║
║  │8 │ │9 │ │10│ │11│ │12│      ║
║  └──┘ └──┘ └──┘ └──┘ └──┘      ║
║                                  ║
╠══════════════════════════════════╣
║  [Zurück]      [Weiter: Daten →] ║
╚══════════════════════════════════╝
```

### 8.4 Metadaten-Eingabe (Phone)

```
╔══════════════════════════════════╗
║ ←  Metadaten       Lied 1 von 3  ║
╠══════════════════════════════════╣
║  [◀] ○●○  [▶]   Lied-Navigation  ║
╠══════════════════════════════════╣
║                                  ║
║  [Thumbnail]  Seiten 1–4         ║
║                                  ║
║  Titel *                         ║
║  ┌──────────────────────────┐    ║
║  │ Böhmischer Traum      ✓  │    ║
║  └──────────────────────────┘    ║
║                                  ║
║  Komponist                       ║
║  ┌──────────────────────────┐    ║
║  │ Ernst Mosch           ⚠  │    ║
║  └──────────────────────────┘    ║
║  Bitte prüfen — AI unsicher      ║
║                                  ║
║  Genre                           ║
║  ┌──────────────────────────┐    ║
║  │ Polka                 ✓  │    ║
║  └──────────────────────────┘    ║
║                                  ║
║  Für Kapelle:                    ║
║  ☑ Stadtkapelle Musterstadt      ║
║  ☐ Meine persönliche Sammlung    ║
║                                  ║
╠══════════════════════════════════╣
║  [Zurück]        [Nächstes Lied] ║
╚══════════════════════════════════╝
```

### 8.5 Stimmen-Zuordnung (Phone)

```
╔══════════════════════════════════╗
║ ←  Stimmen: Böhmischer Traum     ║
╠══════════════════════════════════╣
║                                  ║
║  ✓ Seite 1  → 1. Klarinette      ║
║  ✓ Seite 2  → 2. Klarinette      ║
║  ⚠ Seite 3  → Es-Klarinette      ║
║     KI unsicher — bitte prüfen   ║
║  ✓ Seite 4  → Flöte              ║
║  ? Seite 5  → [Stimme wählen ▾]  ║ ← offen
║  ? Seite 6  → [Stimme wählen ▾]  ║
║                                  ║
╠══════════════════════════════════╣
║  [Zurück]       [Weiter: Review] ║
╚══════════════════════════════════╝
```

### 8.6 Review & Bestätigung (Phone)

```
╔══════════════════════════════════╗
║ ←  Review & Importieren          ║
╠══════════════════════════════════╣
║                                  ║
║  ✓ Böhmischer Traum              ║
║    4 Stimmen · Polka             ║
║    [✎ Bearbeiten]                ║
║                                  ║
║  ⚠ Alpenrose Marsch              ║
║    Komponist fehlt               ║
║    [✎ Bearbeiten]                ║
║                                  ║
║  ✓ Konzertmarsch Nr. 3           ║
║    6 Stimmen · Marsch            ║
║    [✎ Bearbeiten]                ║
║                                  ║
║  ─────────────────────────────   ║
║  ⚠ 1 Lied hat fehlende Angaben   ║
║  ℹ Du kannst trotzdem importieren║
║                                  ║
╠══════════════════════════════════╣
║         [Jetzt importieren ✓]    ║
╚══════════════════════════════════╝
```

---

## 9. Wireframes: Tablet

### 9.1 Import-Startscreen (Tablet, Landscape)

```
╔════════════════════════════════════════════════════════════════╗
║  ←  Noten importieren                                    [✕]  ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║   ┌──────────────────────────────────────────────────────┐    ║
║   │                                                      │    ║
║   │                    ⬆                                 │    ║
║   │                                                      │    ║
║   │         Dateien hierher ziehen                       │    ║
║   │         oder auswählen                               │    ║
║   │                                                      │    ║
║   │    Unterstützt: PDF, JPG, PNG, HEIC                  │    ║
║   │    Max. 50 MB pro Datei · mehrere gleichzeitig       │    ║
║   │                                                      │    ║
║   │   ┌────────────────┐  ┌────────────────┐            │    ║
║   │   │  📁 Datei wähl.│  │  ☁ Cloud       │            │    ║
║   │   └────────────────┘  └────────────────┘            │    ║
║   │                                                      │    ║
║   └──────────────────────────────────────────────────────┘    ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

### 9.2 Labeling-Screen (Tablet, Split-View)

```
╔════════════════════════════════════════════════════════════════╗
║  ←  Seiten zuordnen                          3 Lieder erkannt  ║
╠══════════════════════╦═════════════════════════════════════════╣
║                      ║                                         ║
║  LIED 1              ║  [Seite 1 — Vollbild-Vorschau]         ║
║  [Titel erkannt] [✎] ║                                         ║
║  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ║  ┌─────────────────────────────┐      ║
║  │1●│ │2 │ │3 │ │4 │ ║  │                             │      ║ ← ● = ausgewählt
║  └──┘ └──┘ └──┘ └──┘ ║  │  [Notenblatt-Preview]       │      ║
║                      ║  │                             │      ║
║  [+ Neues Lied hier] ║  │  1. KLARINETTE              │      ║
║                      ║  │  Böhmischer Traum           │      ║
║  LIED 2              ║  │                             │      ║
║  „Böhmischer Traum"  ║  └─────────────────────────────┘      ║
║  ┌──┐ ┌──┐ ┌──┐      ║                                         ║
║  │5 │ │6 │ │7 │      ║  Seite 1 von 12                         ║
║  └──┘ └──┘ └──┘      ║  Erkannte Stimme: 1. Klarinette ✓      ║
║                      ║                                         ║
║  [+ Neues Lied hier] ║  [← Zurück]  [Seite zu Lied 2]  [→]   ║
║                      ║                                         ║
║  LIED 3              ║                                         ║
║  „Alpenrose Marsch"  ║                                         ║
║  ┌──┐ ┌──┐ ┌──┐ …    ║                                         ║
║  │8 │ │9 │ │10│      ║                                         ║
║  └──┘ └──┘ └──┘      ║                                         ║
╠══════════════════════╩═════════════════════════════════════════╣
║  [Zurück]                              [Weiter: Metadaten →]   ║
╚════════════════════════════════════════════════════════════════╝
```

### 9.3 Metadaten-Eingabe (Tablet, alle Lieder auf einmal)

```
╔════════════════════════════════════════════════════════════════╗
║  ←  Metadaten eingeben                               Lied 2/3  ║
╠══════════════════════╦═════════════════════════════════════════╣
║                      ║                                         ║
║  LIEDER              ║  „Böhmischer Traum"  — Lied 2 von 3    ║
║  ─────────────────   ║  ─────────────────────────────────────  ║
║  ✓ Böhmischer Traum  ║                                         ║
║  ⚠ Alpenrose Marsch● ║  Titel *                                ║
║  ✓ Konzertmarsch     ║  ┌─────────────────────────────────┐   ║
║                      ║  │ Böhmischer Traum             ✓  │   ║
║  ─────────────────   ║  └─────────────────────────────────┘   ║
║  [Bulk-Bearbeitung]  ║                                         ║
║                      ║  Komponist                              ║
║                      ║  ┌─────────────────────────────────┐   ║
║                      ║  │ Ernst Mosch                  ⚠  │   ║
║                      ║  └─────────────────────────────────┘   ║
║                      ║  KI unsicher — bitte prüfen            ║
║                      ║                                         ║
║                      ║  Genre        Tonart                    ║
║                      ║  ┌──────────┐  ┌──────────┐            ║
║                      ║  │ Polka  ✓ │  │ B-Dur  ✓ │            ║
║                      ║  └──────────┘  └──────────┘            ║
║                      ║                                         ║
║                      ║  Für:  ☑ Stadtkapelle  ☐ Meine Samml. ║
║                      ║                                         ║
╠══════════════════════╩═════════════════════════════════════════╣
║  [← Vorheriges Lied]                   [Nächstes Lied →]       ║
╚════════════════════════════════════════════════════════════════╝
```

---

## 10. Abhängigkeiten für Hill (Frontend)

### 10.1 Komponenten

| Komponente | Beschreibung | Priorität |
|-----------|-------------|-----------|
| `ImportDropzone` | Drag&Drop-Zone, Datei-Picker, Kamera-Button | P0 |
| `UploadProgressList` | Liste mit Datei-Upload-Fortschritt, Resume-Support | P0 |
| `LabelingCanvas` | Thumbnail-Grid mit Drag&Drop-Gruppen, Lied-Grenzen | P0 |
| `ThumbnailCard` | Vorschau-Karte mit Qualitäts-Indikator (grün/gelb/rot) | P0 |
| `MetadatenFormular` | Formular mit AI-Konfidenz-Badges, Auto-Complete | P0 |
| `StimmenZuordner` | Seiten-Liste mit Stimmen-Picker pro Zeile | P0 |
| `ImportReviewScreen` | Zusammenfassung aller Lieder vor Bestätigung | P0 |
| `KameraScanner` | Kamera-Ansicht mit Auto-Crop-Overlay, Qualitätsmessung | P1 |
| `CloudStoragePicker` | OneDrive/Dropbox/GDrive Dateiauswahl | P1 |
| `DuplikatWarning` | Bottom Sheet / Dialog bei erkanntem Duplikat | P0 |

### 10.2 API-Endpunkte (für Banner)

| Aktion | Methode | Endpunkt |
|--------|---------|----------|
| Upload starten | POST | `/api/import/upload` (multipart) |
| Upload-Status | GET | `/api/import/{jobId}/status` |
| AI-Analyse starten | POST | `/api/import/{jobId}/analyse` |
| Labeling speichern | PUT | `/api/import/{jobId}/labeling` |
| Metadaten speichern | PUT | `/api/import/{jobId}/metadaten` |
| Stimmen-Zuordnung | PUT | `/api/import/{jobId}/stimmen` |
| Import bestätigen | POST | `/api/import/{jobId}/bestaetigen` |
| Import abbrechen | DELETE | `/api/import/{jobId}` |
| Duplikat prüfen | POST | `/api/noten/duplikat-check` |

### 10.3 Offline-Anforderungen

- Upload-Queue muss in lokalem Storage (SQLite/Drift) persistiert werden
- Metadaten-Eingabe muss offline-fähig sein
- AI-Erkennung ist Online-Only — klare UI wenn offline
- Resume-Upload nach Verbindungsunterbrechung (byte-range upload oder chunk-based)

### 10.4 Offene Fragen für Thomas

1. **Upload-Limit:** 50 MB pro Datei — ist das ausreichend für große Notenhefte?
2. **AI-Provider:** Wird Azure AI Vision evaluiert oder gibt es bereits eine Entscheidung?
3. **Stimmen-Heft-Erkennung:** Soll die App automatisch erkennen wenn ein Dokument ein Stimmen-Heft (eine Stimme, viele Stücke) ist?
4. **GEMA-Daten:** Sollen GEMA-Werk-Nummern im Import-Flow erfasst werden oder ist das ein separater Schritt?
5. **Batch-Import-Grenze:** Wie viele Dateien dürfen gleichzeitig importiert werden (Queue-Limit)?
