# Feature-Gap-Analyse — Sheetstorm vs. Konkurrenz

> **Erstellt:** 2026-03-28
> **Aktualisiert:** 2026-03-28 (v2 — Abgleich gegen spezifikation.md v2)
> **Autor:** Fury (Business Analyst)
> **Quellen:** docs/marktanalyse.md, docs/ux-research-konkurrenz.md, docs/spezifikation.md (v2), docs/vergleich-sheethappens.md
> **Status:** Zur Entscheidung durch Thomas
> **Zweck:** Übersicht aller Konkurrenz-Features, die in unserer Spezifikation fehlen oder nur teilweise abgedeckt sind.

---

## Zusammenfassung

Aus der Analyse von **17+ Konkurrenzprodukten** und dem Abgleich mit **SheetHappens (Vorläufer-Projekt)** wurden **39 Feature-Gaps** identifiziert — Funktionen, die mindestens ein Wettbewerber bietet und die in der aktuellen Spezifikation (v2) fehlen oder nur teilweise abgedeckt sind.

**Update v2:** Half-Page-Turn (F-SM-02), Bluetooth-Fußpedal (F-SM-03) und Aushilfen-Zugang (F-SM-06) wurden inzwischen in die Spezifikation aufgenommen (✅). GEMA-Meldung wurde als neuer 🔴-Gap ergänzt.

**Verteilung nach empfohlener Priorität:**
- 🔴 Hoch: 6 Features
- 🟡 Mittel: 13 Features
- 🟢 Niedrig: 13 Features
- ⚪ Nicht relevant: 7 Features

---

## Übersichtstabelle — Alle Gaps sortiert nach Priorität

| # | Feature | Priorität | In Spec? | Meilenstein | Aufwand |
|---|---------|:---------:|:--------:|:-----------:|:-------:|
| 0 | **GEMA-/Verwertungsgesellschaft-Meldung** | 🔴 Hoch | ❌ Nein | MS2 | Mittel |
| 1 | Half-Page-Turn | ✅ In Spec | ✅ F-SM-02 | MS1 | Klein |
| 2 | Bluetooth-Fußpedal-Support | ✅ In Spec | ✅ F-SM-03 | MS1 | Mittel |
| 3 | Aushilfen-Zugang ohne Registrierung | ✅ In Spec | ✅ F-SM-06 | MS1 | Mittel |
| 4 | 1-Klick-Stimmenneuverteilung | 🔴 Hoch | ⚠️ Teilweise | MS1 | Klein |
| 5 | Musikalische Stempel-Bibliothek | 🔴 Hoch | ⚠️ Teilweise | MS1 | Mittel |
| 6 | Kalender-Sync (Google/Apple/Outlook) | 🔴 Hoch | ⚠️ Teilweise | MS2 | Mittel |
| 7 | Chat / Gruppen-Messaging | 🔴 Hoch | ❌ Nein | MS2 | Groß |
| 8 | Zweiseitenansicht (Two-Up-Modus) | 🔴 Hoch | ❌ Nein | MS1 | Klein |
| 9 | Link Points für Wiederholungen | 🟡 Mittel | ❌ Nein | MS1 | Mittel |
| 10 | Dirigenten-Mastersteuerung (Song-Broadcast) | 🟡 Mittel | ❌ Nein | MS2 | Groß |
| 11 | Dark Mode / Nachtmodus / Sepia | 🟡 Mittel | ❌ Nein | MS1 | Klein |
| 12 | Anwesenheitsstatistiken | 🟡 Mittel | ❌ Nein | MS2 | Mittel |
| 13 | Register-basierte Benachrichtigungen | 🟡 Mittel | ⚠️ Teilweise | MS2 | Klein |
| 14 | Nachrichten-Board / Pinnwand | 🟡 Mittel | ❌ Nein | MS2 | Mittel |
| 15 | Umfragen / Abstimmungen | 🟡 Mittel | ❌ Nein | MS2 | Mittel |
| 16 | Verschiebbare Annotations-Toolbar | 🟡 Mittel | ❌ Nein | MS1 | Klein |
| 17 | Annotationstool-Favoriten | 🟡 Mittel | ❌ Nein | MS1 | Klein |
| 18 | Bewertungssystem für Stücke | 🟡 Mittel | ❌ Nein | MS2 | Klein |
| 19 | Excel-/CSV-Import für Archiv-Migration | 🟡 Mittel | ❌ Nein | MS1 | Mittel |
| 20 | Setlist teilen (auch an Nicht-Nutzer) | 🟡 Mittel | ❌ Nein | MS2 | Klein |
| 21 | Wiederkehrende Termine (Proben) | 🟡 Mittel | ❌ Nein | MS2 | Klein |
| 22 | Media Links (YouTube/Spotify) | 🟡 Mittel | ❌ Nein | MS2 | Klein |
| 23 | Lasso-/Auswahl-Werkzeug | 🟢 Niedrig | ❌ Nein | MS3 | Mittel |
| 24 | Playback-Integration (Begleitspuren) | 🟢 Niedrig | ❌ Nein | MS4 | Groß |
| 25 | Aufnahme-Funktion (Recorder) | 🟢 Niedrig | ❌ Nein | MS3 | Mittel |
| 26 | MusicXML-Import | 🟢 Niedrig | ❌ Nein | MS5 | Mittel |
| 27 | Konzertprogramm mit Timing | 🟢 Niedrig | ❌ Nein | MS2 | Klein |
| 28 | PDF-Export (Noten, Berichte) | 🟢 Niedrig | ❌ Nein | MS2 | Mittel |
| 29 | Platzhalter in Setlists | 🟢 Niedrig | ❌ Nein | MS2 | Klein |
| 30 | Aufgabenverwaltung / To-Do-Listen | 🟢 Niedrig | ❌ Nein | MS3 | Mittel |
| 31 | Auto-Scroll / Reflow | 🟢 Niedrig | ❌ Nein | MS3 | Mittel |
| 32 | Notenstore-Integration (IMSLP etc.) | 🟢 Niedrig | ❌ Nein | Backlog | Groß |
| 33 | Lokaler Relay-/Hotspot-Modus | 🟢 Niedrig | ❌ Nein | MS3 | Groß |
| 34 | AI-Annotations-Analyse (Cross-Part) | 🟢 Niedrig | ❌ Nein | MS4 | Groß |
| 35 | Face-Gesten für Seitenwechsel | ⚪ Nicht relevant | ❌ Nein | Backlog | Groß |
| 36 | MIDI-Controller-Support | ⚪ Nicht relevant | ❌ Nein | Backlog | Mittel |
| 37 | LiveScore AI (PDF → interaktive Partitur) | ⚪ Nicht relevant | ❌ Nein | Backlog | Groß |
| 38 | E-Reader-Unterstützung (PocketBook) | ⚪ Nicht relevant | ❌ Nein | Backlog | Groß |
| 39 | Finanzverwaltung / Buchhaltung | ⚪ Nicht relevant | ❌ Nein | Backlog | Groß |
| 40 | Inventarverwaltung (Instrumente) | ⚪ Nicht relevant | ❌ Nein | Backlog | Mittel |
| 41 | AI-Assistent (Sprach-Verwaltung) | ⚪ Nicht relevant | ❌ Nein | Backlog | Groß |

---

## Detaillierte Gap-Analyse

---

### Kategorie 1: Notenanzeige & Performance

#### 1.1 Half-Page-Turn
- **Gefunden bei:** forScore, MobileSheets, Newzik
- **Was es tut:** Beim Blättern wird die untere Hälfte der nächsten Seite eingeblendet, während die obere Hälfte der aktuellen Seite noch sichtbar bleibt. So kann der Musiker nahtlos weiterlesen, ohne den gefürchteten "Page-Jump-Schock".
- **Warum relevant:** Für Blasmusiker im Konzert ist flüssiges Lesen entscheidend. Beim normalen Seitenwechsel verliert man kurz die Orientierung — Half-Page-Turn verhindert das komplett.
- **In unserer Spec?** ✅ Ja — F-SM-02 (Must, MS1), konfigurierbar mit Teilungsverhältnis
- **Empfohlene Priorität:** ✅ Erledigt
- **Empfohlener Meilenstein:** MS1 ✅
- **Aufwand:** Klein

---

#### 1.2 Bluetooth-Fußpedal-Support
- **Gefunden bei:** forScore, MobileSheets, Newzik, Musicnotes
- **Was es tut:** Seitenwechsel per Bluetooth-Fußpedal (z.B. AirTurn, PageFlip) ermöglicht hands-free Navigation. Der Musiker tritt mit dem Fuß auf ein Pedal, um vor- oder zurückzublättern.
- **Warum relevant:** Blasmusiker haben BEIDE Hände am Instrument. Sie können weder tippen noch wischen. Fußpedal-Support ist für viele Blasmusiker der Hauptgrund, überhaupt auf digitale Noten umzusteigen.
- **In unserer Spec?** ✅ Ja — F-SM-03 (Must, MS1), BLE HID, AirTurn/PageFlip/iRig-kompatibel
- **Empfohlene Priorität:** ✅ Erledigt
- **Empfohlener Meilenstein:** MS1 ✅
- **Aufwand:** Mittel

---

#### 1.3 Zweiseitenansicht (Two-Up-Modus)
- **Gefunden bei:** forScore, MobileSheets, Musicnotes
- **Was es tut:** Im Querformat werden zwei Notenblätter nebeneinander angezeigt — wie ein aufgeklapptes Notenheft. Auf großen Tablets (12,9" iPad Pro) bietet das eine nahezu papierähnliche Erfahrung.
- **Warum relevant:** Viele Blasmusiker nutzen iPads und haben dort genug Bildschirmfläche. Zwei Seiten sehen = weniger blättern = weniger Unterbrechung.
- **In unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🔴 Hoch
- **Empfohlener Meilenstein:** MS1
- **Aufwand:** Klein

---

#### 1.4 Link Points für Wiederholungen (D.S., D.C., Coda)
- **Gefunden bei:** MobileSheets
- **Was es tut:** Der Musiker kann Sprungmarken auf dem Notenblatt setzen (z.B. "Springe zu Coda", "D.S. al Fine"). Im Spielmodus wird beim Erreichen einer Marke automatisch zur Zielstelle gesprungen.
- **Warum es relevant sein könnte:** Blasmusik hat viele Stücke mit Wiederholungen, D.C., D.S. und Codas. Manuelles Zurückblättern in der Performance ist stressig. Link Points lösen das elegant.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS1
- **Aufwand-Schätzung:** Mittel — UI für Platzierung + Navigation-Logik im Spielmodus

---

#### 1.5 Dark Mode / Nachtmodus / Sepia
- **Gefunden bei:** forScore (Sepia, Night Mode), Setflow (Dark Mode)
- **Was es tut:** Verschiedene Farbschemata für die Notenansicht — dunkler Hintergrund mit hellen Noten (Nachtmodus), warmer Sepia-Ton (augenschonend), oder Standard-weiß.
- **Warum es relevant sein könnte:** Bei Auftritten in dunklen Umgebungen (z.B. Weihnachtskonzert, Kirche) blendet ein heller Bildschirm. Sepia-Modus ist bei langen Proben augenschonend.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS1
- **Aufwand-Schätzung:** Klein — CSS/Theme-Anpassung, Invertierung der Notenbilder

---

#### 1.6 Dirigenten-Mastersteuerung (Notenanzeige)
- **Gefunden bei:** Marschpat
- **Was es tut:** Der Dirigent wählt zentral ein Stück aus → alle verbundenen Geräte zeigen automatisch dasselbe Stück an. Der Dirigent kann für alle gleichzeitig umblättern.
- **Warum es relevant sein könnte:** Bei Marschmusik oder schnellen Programmwechseln spart es Zeit, wenn der Dirigent einfach das nächste Stück auswählt und alle Tablets automatisch wechseln.
- **Bereits in unserer Spec?** ❌ Nein — F7.2 Echtzeit-Metronom hat die Dirigenten-Controller-Logik, aber nicht für Notensteuerung.
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2 (nach Setlist-Feature, nutzt Sync-Infrastruktur von MS3)
- **Aufwand-Schätzung:** Groß — Echtzeit-Sync aller Geräte, Konfliktbehandlung bei lokaler vs. ferngesteuerter Navigation

---

#### 1.7 Auto-Scroll / Reflow
- **Gefunden bei:** forScore, SongBook
- **Was es tut:** Die Notenansicht scrollt automatisch in einstellbarer Geschwindigkeit nach unten, sodass der Musiker nicht manuell blättern muss.
- **Warum es relevant sein könnte:** Für lineare Stücke ohne Wiederholungen kann Auto-Scroll nützlich sein. Für Blasmusik-Arrangements mit Wiederholungen und Sprüngen ist es allerdings weniger geeignet.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** MS3
- **Aufwand-Schätzung:** Mittel — Scroll-Logik + Tempo-Konfiguration

---

#### 1.8 Face-Gesten für Seitenwechsel
- **Gefunden bei:** forScore, MobileSheets
- **Was es tut:** Seitenwechsel durch Gesichtsbewegungen (Mund öffnen, Lächeln, Kopfnicken) über die Frontkamera. Hands-free ohne Fußpedal.
- **Warum es relevant sein könnte:** Theoretisch attraktiv für hands-free Nutzung. In der Praxis aber unzuverlässig in lauten Probenräumen und bei Blasmusikern (Mund ist am Mundstück).
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** ⚪ Nicht relevant — Blasmusiker haben den Mund am Instrument. Fußpedal ist die bessere Lösung.
- **Empfohlener Meilenstein:** Backlog
- **Aufwand-Schätzung:** Groß — Computer Vision, Kamera-Zugriff, plattformspezifisch

---

### Kategorie 2: Import & Metadaten

#### 2.1 Excel-/CSV-Import für Archiv-Migration
- **Gefunden bei:** Musicorum
- **Was es tut:** Bestehende Notenarchive, die in Spreadsheets (Excel, CSV) gepflegt werden, können importiert werden — inklusive Metadaten wie Titel, Komponist, Stimmen, Kaufdatum.
- **Warum es relevant sein könnte:** Viele Blaskapellen haben seit Jahrzehnten Notenarchive in Excel-Listen oder ähnlichen Formaten. Ein Import-Tool senkt die Einstiegshürde drastisch und vermeidet tagelange manuelle Neueingabe.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS1
- **Aufwand-Schätzung:** Mittel — CSV/Excel-Parser, Mapping-UI für Spalten → Metadatenfelder

---

#### 2.2 MusicXML-Import
- **Gefunden bei:** Marschpat
- **Was es tut:** Noten im MusicXML-Format können importiert werden — ein standardisiertes Format für Notennotation, das aus Programmen wie MuseScore, Sibelius oder Finale exportiert wird.
- **Warum es relevant sein könnte:** Einige Kapellen erstellen eigene Arrangements in Notensatz-Software. MusicXML-Import würde diese Arrangements direkt nutzbar machen.
- **Bereits in unserer Spec?** ❌ Nein — F1.2 definiert nur Bilder, PDFs und Kamera-Fotos.
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** MS5
- **Aufwand-Schätzung:** Mittel — MusicXML-Parser, Rendering-Engine oder Konvertierung zu PDF

---

#### 2.3 Notenstore-Integration (IMSLP, Musicnotes etc.)
- **Gefunden bei:** forScore (Musicnotes, Noteflight, Virtual Sheet Music), Musicnotes (500.000+ Arrangements), Marschpat (10.000+ Stücke)
- **Was es tut:** Direkter Zugriff auf Online-Notenbibliotheken aus der App heraus — Noten suchen, kaufen/herunterladen und sofort in die Bibliothek aufnehmen.
- **Warum es relevant sein könnte:** Bequemlichkeitsfeature. IMSLP (gemeinfreie Noten) könnte für ältere Blasmusik-Literatur interessant sein. Für vereinseigene Arrangements und gekaufte Noten weniger relevant.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** Backlog
- **Aufwand-Schätzung:** Groß — API-Integration pro Anbieter, Lizenz- und Urheberrechtsfragen

---

#### 2.4 Bewertungssystem für Stücke
- **Gefunden bei:** Musicorum
- **Was es tut:** Musiker können Stücke anonym bewerten (z.B. 1–5 Sterne). Die Auswertung hilft Dirigenten bei der Konzertprogramm-Auswahl — beliebte Stücke werden priorisiert.
- **Warum es relevant sein könnte:** Blaskapellen haben oft 500+ Stücke im Archiv. Ein Bewertungssystem hilft dem Dirigenten, Stücke zu identifizieren, die bei den Musikern beliebt sind. Motivierend und demokratisch.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Klein — Bewertungs-UI + Aggregation im Backend

---

### Kategorie 3: Annotationen & Bearbeitung

#### 3.1 Erweiterte Stempel-Bibliothek (musikalische Symbole)
- **Gefunden bei:** forScore, MobileSheets
- **Was es tut:** Vorgefertigte musikalische Symbole als Stempel: Vorzeichen (♯, ♭, ♮), Dynamik (pp, p, mp, mf, f, ff, sfz), Artikulation (Staccato, Tenuto, Akzent, Marcato), Noten (Ganze, Halbe, Viertel), Atemzeichen, Fermaten, Bögen, Crescendo/Decrescendo-Gabeln. Plus: Möglichkeit, eigene Stempel aus Bildern zu erstellen.
- **Warum es relevant sein könnte:** Musiker nutzen diese Symbole ständig — "hier leiser", "hier Atemzeichen", "hier Akzent". Freihand-Zeichnen ist ungenau und unleserlich. Stempel sind schnell und sauber.
- **Bereits in unserer Spec?** ⚠️ Teilweise — F2.4 erwähnt "Symbole (Dynamik, Atemzeichen etc.)" aber keine detaillierte Stempel-Bibliothek und keine Custom-Stempel.
- **Empfohlene Priorität:** 🔴 Hoch
- **Empfohlener Meilenstein:** MS1
- **Aufwand-Schätzung:** Mittel — SVG-Symbolbibliothek, Drag & Drop Platzierung, Custom-Stempel-Import

---

#### 3.2 Verschiebbare Annotations-Toolbar
- **Gefunden bei:** forScore
- **Was es tut:** Die Annotations-Werkzeugleiste kann an jeden Bildschirmrand verschoben werden (oben, unten, links, rechts), damit sie nicht die Noten verdeckt, an denen man gerade arbeitet.
- **Warum es relevant sein könnte:** Bei der Annotation verdeckt eine fixe Toolbar oft genau die Stelle, an der man arbeiten möchte. Verschiebbarkeit beseitigt dieses Problem elegant.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS1
- **Aufwand-Schätzung:** Klein — UI-Anpassung, Drag-Handle

---

#### 3.3 Annotationstool-Favoriten
- **Gefunden bei:** MobileSheets
- **Was es tut:** Musiker können häufig genutzte Tool-Konfigurationen (z.B. "Roter dünner Stift", "Gelber Textmarker", "Blauer Dynamik-Stempel") als Favoriten speichern und mit einem Tap aktivieren.
- **Warum es relevant sein könnte:** Reduziert die Klicks beim Annotieren erheblich. Statt jedes Mal Farbe, Dicke, Tool neu einzustellen, wählt man den gespeicherten Favoriten.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS1
- **Aufwand-Schätzung:** Klein — Preset-Speicherung im User-Profil

---

#### 3.4 Lasso-/Auswahl-Werkzeug
- **Gefunden bei:** forScore (Rechteck/Kreis zum Verschieben, Kopieren, Einfügen)
- **Was es tut:** Annotationen können mit einem Auswahlwerkzeug (Rechteck oder Lasso) markiert und dann verschoben, kopiert, eingefügt oder gelöscht werden.
- **Warum es relevant sein könnte:** Ermöglicht präziseres Arbeiten mit Annotationen — eine falsch platzierte Markierung muss nicht gelöscht und neu gezeichnet werden, sondern kann einfach verschoben werden.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** MS3
- **Aufwand-Schätzung:** Mittel — Auswahl-Logik, Transformation (Move/Copy/Paste)

---

### Kategorie 4: Setlist & Aufführung

#### 4.1 Setlist teilen (auch an Nicht-Nutzer)
- **Gefunden bei:** forScore
- **Was es tut:** Eine Setlist kann als PDF oder über einen temporären Link geteilt werden — auch an Personen, die die App nicht installiert haben. Nützlich für Aushilfen oder Gäste.
- **Warum es relevant sein könnte:** Bei Blaskapellen kommen regelmäßig Aushilfen dazu (z.B. bei Konzerten). Diese brauchen schnell Zugriff auf das Programm — idealerweise ohne erst einen Account anlegen zu müssen.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Klein — PDF-Export der Setlist-Metadaten, temporärer Sharing-Link

---

#### 4.2 Platzhalter in Setlists
- **Gefunden bei:** forScore
- **Was es tut:** Man kann Platzhalter-Einträge in eine Setlist einfügen für Stücke, die noch nicht digital vorhanden sind. Name und Position sind definiert, aber die Noten fehlen noch.
- **Warum es relevant sein könnte:** Der Dirigent plant oft ein Konzertprogramm, bevor alle Noten digitalisiert sind. Platzhalter erlauben frühzeitige Programmplanung.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Klein — Setlist-Eintrag ohne Stück-Referenz erlauben

---

#### 4.3 Konzertprogramm mit exaktem Timing
- **Gefunden bei:** WePlayIn.Band
- **Was es tut:** Für jedes Stück in einem Konzertprogramm kann eine geschätzte Dauer hinterlegt werden. Das System berechnet die Gesamtdauer und zeigt Start-/Endzeiten pro Stück an.
- **Warum es relevant sein könnte:** Bei Konzerten mit fixem Zeitrahmen (z.B. 90 Minuten Festzeltprogramm) hilft die Timing-Übersicht bei der Planung. Ist aber kein kritisches Feature.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Klein — Dauer-Feld pro Setlist-Eintrag + Summenberechnung

---

#### 4.4 PDF-Export (Noten, Setlists, Berichte)
- **Gefunden bei:** Musicorum (Album-PDF-Export), WePlayIn.Band (Berichte als PDF), Konzertmeister
- **Was es tut:** Verschiedene Inhalte können als PDF exportiert werden — z.B. eine Setlist als druckbares Programm, ein Anwesenheitsbericht, oder eine Notenübersicht.
- **Warum es relevant sein könnte:** Nicht alles ist digital — bei Auftritten braucht man manchmal ein gedrucktes Programm für das Publikum oder einen Bericht für den Vereinsvorstand.
- **Bereits in unserer Spec?** ❌ Nein — nur iCal-Export für Termine erwähnt.
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Mittel — PDF-Generierung serverseitig oder clientseitig

---

### Kategorie 5: Kommunikation & Organisation

#### 5.0 GEMA-/Verwertungsgesellschaft-Meldung (NEU — SheetHappens-Vergleich)
- **Gefunden bei:** SheetHappens (Vorläufer-Projekt), WePlayIn.Band
- **Was es tut:** Automatische Generierung von Konzertberichten (Musikfolge) für Verwertungsgesellschaften (GEMA, SUISA, AKM) direkt aus der Setlist. Export als XML (GEMA-Format), CSV oder PDF. AI-gestützte Suche nach Werknummern. Erinnerung an ausstehende Meldungen.
- **Warum relevant:** Jeder Musikverein in DACH ist **gesetzlich verpflichtet**, Konzertprogramme an die zuständige Verwertungsgesellschaft zu melden. Heute erledigen die meisten das manuell — oft mit Papierformularen oder Excel-Listen. Automatisierung direkt aus der Setlist heraus wäre ein echter Differenzierer, der echte Arbeit spart.
- **In unserer Spec?** ❌ Nein — vollständig fehlend
- **Empfohlene Priorität:** 🔴 Hoch
- **Empfohlener Meilenstein:** MS2
- **Aufwand:** Mittel

---

#### 5.1 Chat / Gruppen-Messaging
- **Gefunden bei:** Glissandoo, Konzertmeister, BAND App, Socie, Vereinsplaner
- **Was es tut:** Integriertes Nachrichtensystem mit Gruppen-Chats (z.B. "Klarinetten-Register", "Vorstand", "Gesamtkapelle") und 1:1-Messaging. Push-Benachrichtigungen bei neuen Nachrichten.
- **Warum es relevant sein könnte:** Aktuell nutzen die meisten Blaskapellen WhatsApp-Gruppen für die Kommunikation. Ein integrierter Chat innerhalb der App vermeidet den Medienbruch und hält alle Vereinskommunikation an einem Ort. Wanda nennt dies als SHOULD HAVE.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🔴 Hoch
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Groß — Echtzeit-Messaging-System, Push-Infrastruktur, Moderation

---

#### 5.2 Nachrichten-Board / Pinnwand
- **Gefunden bei:** Konzertmeister, BAND App, Vereinsplaner
- **Was es tut:** Social-Media-ähnlicher Feed mit Posts, Bildern, Links, Kommentaren und Reaktionen. Vorstand oder Dirigent können Ankündigungen pinnen.
- **Warum es relevant sein könnte:** Für offizielle Ankündigungen ("Neues Stück im Repertoire", "Auftrittsbekleidung geändert") besser geeignet als Chat, weil Nachrichten nicht in der Flut untergehen. Niedrigschwellige Kommunikation.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Mittel — Feed-System, Kommentare, Reaktionen, Pin-Funktion

---

#### 5.3 Umfragen / Abstimmungen
- **Gefunden bei:** Konzertmeister, BNote, BAND App, Socie
- **Was es tut:** Erstellen von Umfragen innerhalb der Kapelle (z.B. "Welches Stück für das Sommerkonzert?", "Welcher Termin passt für die Generalprobe?"). Anonyme oder öffentliche Abstimmung.
- **Warum es relevant sein könnte:** Häufig müssen Entscheidungen in der Kapelle getroffen werden — Terminwahl, Repertoire-Auswahl, Bekleidungsfragen. Aktuell oft per WhatsApp-Umfrage gelöst.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Mittel — Umfrage-Editor, Abstimmungslogik, Auswertung

---

#### 5.4 Register-basierte Benachrichtigungen
- **Gefunden bei:** Konzertmeister, Vereinsplaner
- **Was es tut:** Benachrichtigungen können gezielt an bestimmte Register (z.B. "Alle Klarinetten") oder Gruppen (z.B. "Vorstand") gesendet werden, statt immer an die gesamte Kapelle.
- **Warum es relevant sein könnte:** Reduziert Benachrichtigungs-Überflutung. Registerprobe betrifft nur das Register, nicht die Trompeten.
- **Bereits in unserer Spec?** ⚠️ Teilweise — F5.1 erwähnt "Übersicht nach Registern" und Push-Notifications sind geplant, aber gezielte Register-Benachrichtigungen sind nicht explizit spezifiziert.
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Klein — Empfänger-Gruppen-Filter im Notification-System

---

#### 5.5 Anwesenheitsstatistiken
- **Gefunden bei:** Glissandoo, WePlayIn.Band
- **Was es tut:** Visualisierte Statistiken über die Anwesenheit bei Proben und Auftritten — pro Musiker, pro Register, pro Zeitraum. Trends und Lückenanalyse.
- **Warum es relevant sein könnte:** Vorstand und Dirigent brauchen Transparenz über die Probenbeteiligung. Motiviert Musiker, regelmäßig zu erscheinen. Hilft bei der Planung (welches Register ist chronisch unterbesetzt?).
- **Bereits in unserer Spec?** ❌ Nein — Zu-/Absagen sind geplant, aber keine Auswertung/Statistiken.
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Mittel — Aggregation der Teilnahme-Daten, Charts/Visualisierung

---

#### 5.6 Kalender-Sync (Google, Apple, Outlook)
- **Gefunden bei:** Konzertmeister, Vereinsplaner, WePlayIn.Band
- **Was es tut:** Bidirektionale Synchronisation mit externen Kalendern — Vereinstermine erscheinen automatisch im persönlichen Google/Apple/Outlook-Kalender. Änderungen werden in Echtzeit synchronisiert.
- **Warum es relevant sein könnte:** Musiker nutzen ihren privaten Kalender für alle Termine. Wenn Vereinstermine dort automatisch erscheinen, vergisst niemand die Probe. iCal-Export allein ist nur ein einmaliger Download.
- **Bereits in unserer Spec?** ⚠️ Teilweise — F5.3 definiert iCal-Export, aber keine bidirektionale Kalender-Sync (Google, Apple, Outlook).
- **Empfohlene Priorität:** 🔴 Hoch
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Mittel — iCal-Subscription-URL (CalDAV) statt nur Einmal-Export, oder Google/Apple Calendar API

---

#### 5.7 Wiederkehrende Termine (Proben)
- **Gefunden bei:** Glissandoo
- **Was es tut:** Proben können als wiederkehrende Termine angelegt werden (z.B. "Jeden Dienstag, 19:30 Uhr"). Einzelne Instanzen können angepasst oder gestrichen werden.
- **Warum es relevant sein könnte:** Die meisten Blaskapellen proben wöchentlich. Jede Woche manuell einen Termin anzulegen ist unnötig aufwendig.
- **Bereits in unserer Spec?** ❌ Nein — F5.3 Terminplanung definiert einzelne Termine, keine Wiederholungsregeln.
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2
- **Aufwand-Schätzung:** Klein — Recurrence-Rule (iCal RRULE), Instanz-Verwaltung

---

#### 5.8 Aufgabenverwaltung / To-Do-Listen
- **Gefunden bei:** Konzertmeister, BNote, BAND App
- **Was es tut:** Aufgaben können erstellt und Mitgliedern zugewiesen werden (z.B. "Festbühne aufbauen — Max, Moritz", "Programmheft drucken — Notenwart"). Status-Tracking (offen/erledigt).
- **Warum es relevant sein könnte:** Vereinsorganisation erfordert koordinierte Aufgaben. Aktuell werden diese oft per WhatsApp vergeben und gehen unter.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** MS3
- **Aufwand-Schätzung:** Mittel — Task-System mit Zuweisung und Status

---

### Kategorie 6: Übung & Lehre

#### 6.1 Playback-Integration (Begleitspuren)
- **Gefunden bei:** Tomplay, Musicnotes, Newzik
- **Was es tut:** Während der Musiker die Noten sieht, spielt eine Begleitspur (Orchester, Klavier, Rhythmus) synchron mit. Tempo anpassbar, einzelne Instrumente stummschaltbar.
- **Warum es relevant sein könnte:** Für das Üben zu Hause extrem wertvoll — der Musiker hört den Orchesterkontext und kann seinen Part darin spielen. Besonders für junge Musiker motivierend.
- **Bereits in unserer Spec?** ❌ Nein — Lehre-Modul hat Lernpfade, aber keine Audio-Begleitung.
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** MS4
- **Aufwand-Schätzung:** Groß — Audio-Engine, Synchronisation mit Notenansicht, Audio-Dateien pro Stück

---

#### 6.2 Aufnahme-Funktion (Recorder)
- **Gefunden bei:** Newzik
- **Was es tut:** Musiker können sich beim Spielen aufnehmen. Die Aufnahme wird dem aktuellen Stück zugeordnet. Nützlich für Selbstkontrolle oder zum Teilen mit dem Lehrer.
- **Warum es relevant sein könnte:** Für das Lehre-Modul interessant — Schüler nehmen sich auf, Lehrer hört die Aufnahme und gibt Feedback. Auch für die Selbstreflexion in der eigenen Übungsroutine.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟢 Niedrig
- **Empfohlener Meilenstein:** MS3
- **Aufwand-Schätzung:** Mittel — Audio-Recording, Zuordnung zum Stück, ggf. Sharing

---

### Kategorie 7: Hardware-Integration

#### 7.1 MIDI-Controller-Support
- **Gefunden bei:** MobileSheets, BandHelper, OnSong, SongBook
- **Was es tut:** Die App reagiert auf MIDI-Befehle von externen Controllern. Damit können z.B. Programwechsel an Synthesizer gesendet werden, oder Pedale über MIDI angesteuert werden.
- **Warum es relevant sein könnte:** Für Blaskapellen kaum relevant — es gibt selten MIDI-Equipment in traditionellen Blasorchestern. Eher für Bands und moderne Ensembles.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** ⚪ Nicht relevant — Blaskapellen nutzen kein MIDI-Equipment.
- **Empfohlener Meilenstein:** Backlog
- **Aufwand-Schätzung:** Mittel — MIDI-Bibliothek, plattformspezifische Anbindung

---

#### 7.2 E-Reader-Unterstützung (PocketBook)
- **Gefunden bei:** Marschpat
- **Was es tut:** Noten werden auf einem E-Ink-Reader (PocketBook) angezeigt — leicht, wetterfest, blendfrei, tagelange Akkulaufzeit. Ideal für Outdoor-Auftritte und Marschmusik.
- **Warum es relevant sein könnte:** E-Ink ist bei Sonneneinstrahlung besser lesbar als LCD/OLED. Für Marschkapellen bei Outdoor-Auftritten attraktiv. Aber: E-Ink ist langsam, keine Farbe, keine Touch-Annotations.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** ⚪ Nicht relevant — E-Ink-Geräte können keine Touch-Annotations und sind zu langsam für unsere interaktiven Features.
- **Empfohlener Meilenstein:** Backlog
- **Aufwand-Schätzung:** Groß — Eigene App für E-Ink, stark eingeschränkte Funktionalität

---

### Kategorie 8: Sharing & Kollaboration

#### 8.1 Aushilfen-Zugang ohne Registrierung
- **Gefunden bei:** Musicorum
- **Was es tut:** Stimmen/Noten können per Link an Aushilfen weitergegeben werden. Der Aushilfsmusiker braucht keinen Account — er klickt auf den Link und sieht seine Noten. Temporärer Zugang, automatisch ablaufend.
- **Warum relevant:** In Blaskapellen kommen regelmäßig Aushilfen zum Einsatz — bei Konzerten, Festen, Wertungsspielen. Für diese Personen einen Account anzulegen ist unverhältnismäßig. Ein temporärer Link ist die perfekte Lösung.
- **In unserer Spec?** ✅ Ja — F-SM-06 (Should, MS1): Token-basiert, Ablaufdatum konfigurierbar (7 Tage Standard), QR-Code, widerrufbar
- **Empfohlene Priorität:** ✅ Erledigt
- **Empfohlener Meilenstein:** MS1 ✅
- **Aufwand:** Mittel

---

#### 8.2 1-Klick-Stimmenneuverteilung bei Ausfällen
- **Gefunden bei:** Notabl
- **Was es tut:** Wenn ein Musiker absagt, kann seine Stimme mit einem einzigen Klick an einen Ersatzmusiker übergeben werden. Das System schlägt passende Kandidaten vor (basierend auf Instrumentenprofil).
- **Warum relevant:** Ausfälle vor Konzerten sind häufig. Die schnelle Neuverteilung einer Stimme an einen Ersatzmusiker (mit den richtigen Noten automatisch auf sein Gerät) ist ein enormer Zeitgewinn für den Dirigenten.
- **In unserer Spec?** ⚠️ Teilweise — F-VL-01 erwähnt "Vorschlag für Ersatzmusiker basierend auf Instrumentenprofil + Fallback-Logik", aber kein dedizierter 1-Klick-Workflow.
- **Empfohlene Priorität:** 🔴 Hoch
- **Empfohlener Meilenstein:** MS1
- **Aufwand:** Klein

---

### Kategorie 9: Sonstiges

#### 9.0 Dirigenten-Modus: Song-Broadcast (NEU — SheetHappens-Vergleich)
- **Gefunden bei:** SheetHappens (SignalR ConductorHub), Marschpat (Masterfunktion)
- **Was es tut:** Der Dirigent öffnet den Dirigenten-Modus und aktiviert eine Setlist. Wenn er ein Stück antippt, wird per SignalR an alle verbundenen Geräte gesendet: "Jetzt dieses Stück anzeigen." Alle Tablets wechseln automatisch auf die richtige Stimme. Verbundene Musiker-Zähler, Auto-Reconnect.
- **Warum relevant:** Bei schnellen Programmwechseln (Marschmusik, Festzeltkonzert) spart das erheblich Zeit. Kein Suchen, kein Blättern, kein "Welches Stück haben wir jetzt?" Besonders für Kapellen ohne Probendisziplin ein Mehrwert.
- **In unserer Spec?** ❌ Nein — F-MW-02 hat Metronom-Sync, aber kein Stück-Broadcast
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2
- **Aufwand:** Groß

---

#### 9.0b Media Links (YouTube / Spotify) (NEU — SheetHappens-Vergleich)
- **Gefunden bei:** SheetHappens, MusicNotes
- **Was es tut:** Pro Stück können YouTube- und Spotify-Referenzlinks gespeichert werden. AI schlägt passende Links vor. "Anhören"-Button auf Setlist-Einträgen. Eingebettete Vorschau oder Deep-Link in die App.
- **Warum relevant:** Musiker nutzen YouTube zum Vorhören von Stücken vor Proben. Wenn der Link direkt im Stück hinterlegt ist, spart das Suche. Besonders wertvoll für neue Repertoire-Stücke.
- **In unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** 🟡 Mittel
- **Empfohlener Meilenstein:** MS2
- **Aufwand:** Klein

---

#### 9.1 LiveScore AI (PDF → interaktive Partitur)
- **Gefunden bei:** Newzik
- **Was es tut:** PDFs werden von einer AI in interaktive, navigierbare Partituren konvertiert. Noten werden als einzelne Elemente erkannt — ermöglicht Transposition, Playback-Cursor, einzelne Stimmen-Extraktion.
- **Warum es relevant sein könnte:** Technologisch beeindruckend, aber für Blaskapellen mit ihren physischen Noten-PDFs nicht prioritär. Transposition per MusicXML wäre relevanter.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** ⚪ Nicht relevant — Zu komplex, unser Fokus liegt auf PDF-Anzeige mit Annotation, nicht auf OMR/Rendering.
- **Empfohlener Meilenstein:** Backlog
- **Aufwand-Schätzung:** Groß — Volle OMR-Engine, Notations-Rendering

---

#### 9.2 Finanzverwaltung / Buchhaltung
- **Gefunden bei:** easyVerein, Vereinsplaner, ComMusic
- **Was es tut:** Mitgliedsbeiträge verwalten, Rechnungen erstellen, Buchhaltung, Finanzberichte, SEPA-Lastschriften.
- **Warum es relevant sein könnte:** Finanzverwaltung ist für jeden Verein wichtig, aber es ist kein Musik-Feature. Die meisten Vereine haben bereits eine Buchhaltungslösung (easyVerein, Vereinsplaner, Excel). Hier zu konkurrieren wäre Scope Creep.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** ⚪ Nicht relevant — Nicht unser Kernbereich. Integration (z.B. Mitgliederliste exportieren) wäre sinnvoller als eigene Buchhaltung.
- **Empfohlener Meilenstein:** Backlog
- **Aufwand-Schätzung:** Groß — Komplettes Finanzsystem

---

#### 9.3 Inventarverwaltung (Instrumente, Equipment)
- **Gefunden bei:** Vereinsplaner
- **Was es tut:** Vereinseigene Instrumente und Equipment verwalten — wer hat welches Leihinstrument, wann ist die nächste Wartung, Zustandsberichte.
- **Warum es relevant sein könnte:** Blaskapellen besitzen oft teure Instrumente, die an Mitglieder ausgeliehen werden. Überblick ist wichtig, aber nicht kerngeschäftskritisch für eine Noten-App.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** ⚪ Nicht relevant — Feature Creep. Vereinsverwaltungs-Apps decken das besser ab.
- **Empfohlener Meilenstein:** Backlog
- **Aufwand-Schätzung:** Mittel — Inventar-CRUD mit Zuweisungslogik

---

#### 9.4 AI-Assistent (Sprach-gesteuerte Verwaltung)
- **Gefunden bei:** WePlayIn.Band
- **Was es tut:** Verwaltungsaufgaben per Sprachbefehl erledigen ("Erstelle einen Probentermin für nächsten Dienstag", "Zeige mir die Anwesenheit für letzten Monat"). AI-basierter Assistent.
- **Warum es relevant sein könnte:** Innovativ und bequem, aber noch in den Kinderschuhen. Kein Alleinstellungsmerkmal für Blaskapellen. Kann die Bedienung vereinfachen, ist aber nicht essentiell.
- **Bereits in unserer Spec?** ❌ Nein
- **Empfohlene Priorität:** ⚪ Nicht relevant — Nice-to-have für spätere Iteration, aber AI-Budget besser für Metadaten-Erkennung nutzen.
- **Empfohlener Meilenstein:** Backlog
- **Aufwand-Schätzung:** Groß — NLU, Intent-Erkennung, Action-Mapping

---

## Top 10 Empfehlungen

Basierend auf der Analyse empfehle ich Thomas, die folgenden 10 Features ernsthaft für die Aufnahme in die Spezifikation zu prüfen. Kriterien: Relevanz für Blaskapellen, gesetzliche Pflichten, Differenzierungspotenzial, Aufwand-Nutzen-Verhältnis.

> **Hinweis v2:** Half-Page-Turn, Bluetooth-Fußpedal und Aushilfen-Zugang (ehemals Top 3) sind inzwischen ✅ in der Spezifikation (F-SM-02, F-SM-03, F-SM-06). Folgendes sind die verbleibenden Prioritäten.

### 🥇 1. GEMA-/Verwertungsgesellschaft-Meldung (MS2)
**Warum:** Gesetzliche Pflicht für jeden Musikverein in DACH. Heute erledigen die meisten das manuell mit Papierformularen. Automatische Generierung aus der Setlist löst echten, universellen Schmerz. Kein Blasmusik-Konkurrent (Marschpat, Glissandoo, notabl) hat das — SheetHappens hatte das vollständig spezifiziert.

### 🥈 2. 1-Klick-Stimmenneuverteilung (MS1)
**Warum:** "Die 2. Klarinette ist krank — wer übernimmt?" Dieser Workflow passiert vor jedem Konzert. Unser Stimmen-Mapping (F-NV-02) legt die Grundlage — der 1-Klick-Workflow zur Neuverteilung fehlt noch. Kleiner Aufwand, großer Alltags-Nutzen.

### 🥉 3. Zweiseitenansicht (Two-Up-Modus) (MS1)
**Warum:** Auf einem 12,9"-iPad zwei Seiten gleichzeitig = halbe Blätterhäufigkeit. Klein im Aufwand, groß im Nutzen. forScore und MobileSheets setzen das als Standard.

### 4. Chat / Gruppen-Messaging (MS2)
**Warum:** WhatsApp ablösen ist strategisches Ziel. Solange Musiker für die Vereinskommunikation die App verlassen, verlieren wir Engagement. Groß im Aufwand, aber strategisch wichtig.

### 5. Kalender-Sync bidirektional (MS2)
**Warum:** iCal-Export allein reicht nicht. Musiker erwarten automatische Synchronisation mit Google/Apple-Kalender. CalDAV-Subscription-URL wäre pragmatisch und sehr günstig.

### 6. Wiederkehrende Termine / Serienproben (MS2)
**Warum:** "Jeden Dienstag, 19:30 Uhr Probe" jede Woche manuell anzulegen ist absurd. Kleiner Aufwand, großer Komfortgewinn.

### 7. Erweiterte Stempel-Bibliothek (MS1)
**Warum:** Unsere Spec erwähnt "Symbole (Dynamik, Atemzeichen)", aber keine dedizierte Stempel-Bibliothek mit Drag-and-Drop und Custom-Stempeln. forScore setzt den Standard.

### 8. Media Links (YouTube/Spotify) (MS2)
**Warum:** Kleiner Aufwand, hoher Nutzwert. Direkter Referenzlink pro Stück spart Suche vor Proben. AI-gestützte Vorschläge wären ein Add-on mit minimalem Mehraufwand.

### 9. Excel-/CSV-Import für Migration (MS1)
**Warum:** Viele Kapellen haben hunderte Stücke in Excel-Listen. Ohne Import-Tool ist die Einstiegshürde hoch. Einmaliger Migrationsaufwand für neue Kunden.

### 10. Dirigenten-Modus: Song-Broadcast (MS2)
**Warum:** Bei Marschmusik und schnellen Programmwechseln spart zentrales Stück-Auswählen erheblich Zeit. SheetHappens hat die SignalR-Architektur vollständig spezifiziert — übernehmen.

---

## Hinweis

Diese Analyse ist **bewusst vollständig** — auch Features, die ich als "Nicht relevant" einschätze, sind aufgeführt. Thomas entscheidet, was aufgenommen wird und mit welcher Priorität. Meine Empfehlungen sind Vorschläge auf Basis der Marktanalyse, nicht Vorgaben.

Features, die unsere Spec **bereits vollständig abdeckt** (z.B. Offline-Modus, mehrstufige Annotationsebenen, Auto-Rotation/Auto-Zoom, AI-Upload mit Labeling, Multi-Kapellen-Zugehörigkeit), sind NICHT in dieser Gap-Liste enthalten — diese sind bereits unsere Stärken.

---

*Dieses Dokument wurde von Fury (Business Analyst) erstellt und wartet auf Entscheidung durch Thomas.*
