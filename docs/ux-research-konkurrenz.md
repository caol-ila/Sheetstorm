# UX-Research: Konkurrenzanalyse — Workflows & Interface-Patterns

> **Erstellt:** 2026-03-28
> **Autorin:** Wanda (UX Designer)
> **Methode:** Systematische Analyse von App-Store-Screenshots, Herstellerseiten, User-Guides, Video-Tutorials und Hilfe-Dokumentationen
> **Status:** Abgeschlossen

---

## Inhaltsverzeichnis

1. [Übersicht der analysierten Apps](#1-übersicht)
2. [App-by-App-Analyse](#2-app-by-app-analyse)
   - 2.1 forScore
   - 2.2 MobileSheets
   - 2.3 Newzik
   - 2.4 Marschpat
   - 2.5 Notabl
   - 2.6 Glissandoo
   - 2.7 Konzertmeister
   - 2.8 Musicorum
   - 2.9 BandHelper
   - 2.10 Musicnotes
   - 2.11 SongBook (LinkeSOFT)
   - 2.12 BAND App
   - 2.13 Vereinsplaner
   - 2.14 WePlayIn.Band
3. [Lessons Learned — Best Practices für Sheetstorm](#3-lessons-learned)
4. [Anti-Patterns — Was wir vermeiden sollten](#4-anti-patterns)
5. [Ressourcen & Links](#5-ressourcen--links)

---

## 1. Übersicht

| App | Hauptkategorie | Analysefokus | Demo/Trial verfügbar |
|-----|---------------|-------------|---------------------|
| forScore | Notenanzeige | Goldstandard PDF-Viewer, Annotation, Setlists | Einmalkauf $24,99 (App Store) |
| MobileSheets | Notenanzeige | Cross-Platform, mächtige Bibliothek | Einmalkauf ~$15,99 (Google Play / App Store) |
| Newzik | Notenanzeige + Ensemble | Echtzeit-Kollaboration, AI-Features | Freemium (3 Partituren kostenlos) |
| Marschpat | Blasmusik-Noten | Stimmenverteilung, Dirigentenmodus | Freemium (eingeschränkt), Abo ab 97€/J |
| Notabl | Musikverein All-in-One | Notenverwaltung + Konzertplanung | Vereins-Grundgebühr (auf Anfrage) |
| Glissandoo | Musikverein-Organisation | Proben, Anwesenheit, Kommunikation | Bis 20 Mitglieder kostenlos |
| Konzertmeister | Vereinsorganisation | Termine, Zu-/Absagen, Pinnwand | Kostenlos bis 30 Mitglieder |
| Musicorum | Notenverwaltung | Digitales Notenarchiv, Stimmenverteilung | Demo kostenlos (eingeschränkt) |
| BandHelper | Band-Management | Setlists, MIDI, Proben/Gig-Kalender | Abo |
| Musicnotes | Notenstore + Viewer | Store-Integration, Viewer, Annotations | Kostenlose App + In-App-Käufe |
| SongBook | Setlist-Management | ChordPro-Format, Setlists, Transposition | Einmalkauf |
| BAND App | Gruppenkommunikation | Feed, Chat, Kalender, Dateien | Kostenlos |
| Vereinsplaner | Vereinsverwaltung | Termine, Mitglieder, Inventar | Kostenlos (Basis) |
| WePlayIn.Band | Orchester-Management | AI-Assistent, Analytics, Repertoire | Community Edition |

---

## 2. App-by-App-Analyse

### 2.1 forScore — Der Goldstandard für digitale Notenblätter

**Plattformen:** iOS, iPadOS, macOS, visionOS
**Website:** https://forscore.co
**App Store:** https://apps.apple.com/app/forscore/id363738376
**User Guide (PDF):** https://forscore.co/user-guides/
**Video-Tutorials:** https://www.youtube.com/playlist?list=PLKT1tUigAhGPiY47ecDF2YHfKQLGYWf5G

#### Haupt-Screens & Navigation

- **Vollbild-Notenansicht:** Beim Öffnen wird die Partitur ablenkungsfrei im Vollbild angezeigt. Alle Steuerelemente sind versteckt. Antippen der Bildschirmmitte blendet eine obere Navigationsleiste ein (Bibliothek, Setlists, Suche, Tools, Seitennavigation).
- **Sidebar / Hamburger-Menü:** Links oben — öffnet die Bibliothek mit Filtern nach Komponist, Genre, Tags, Labels. Unterstützt Smart-Bookmarks und mächtige Suche.
- **Metadaten-Editor:** Für jede Partitur können Titel, Komponist, Genre, Tags und benutzerdefinierte Felder bearbeitet werden. Übersichtlicher Formularstil.

#### Import/Upload-Flow

1. **Cloud-Import:** Integration mit Dropbox, Google Drive, OneDrive, Box, iCloud Drive, FTP/WebDAV. Über das Services-Panel (Werkzeugkasten-Icon) → Account hinzufügen → Ordner durchsuchen → PDF herunterladen.
2. **Kamera-Scan:** Integriertes Scan-Tool (Menü → Scan). Seiten fotografieren, zuschneiden, optimieren, als mehrseitiges PDF zusammenfügen und in der Bibliothek speichern.
3. **Files-App / E-Mail:** Über iOS Share-Sheet jede PDF an forScore senden.
4. **Drag & Drop:** Auf iPad/Mac PDFs direkt ins Fenster ziehen.
5. **Notenstore-Integration:** Direkter Login zu Musicnotes, Noteflight, Virtual Sheet Music im Services-Panel.

**UX-Bewertung Import:** ⭐⭐⭐⭐⭐ — Vielfältige Wege, kein Medienbruch. Best Practice für unseren Import-Flow.

#### Performance-/Auftrittsmodus

- **Distraction-Free:** Alle Menüs, Annotationstools und versehentliche Eingaben werden gesperrt. Nur gezielte Aktionen (Seitenwechsel) sind möglich.
- **Seitenwechsel-Optionen:**
  - Tap links/rechts am Bildschirmrand
  - Wisch-Geste
  - Bluetooth-Fußpedal
  - Half-Page-Turn (Hochformat): Untere Hälfte wird angezeigt während obere Hälfte sichtbar bleibt → nahtloser Lesefluss
  - Two-Up-Modus (Querformat): Zwei Seiten nebeneinander
  - Reflow (automatisches Scrollen)
  - Face-Gesten (Mund öffnen, Lächeln)
- **Visuelle Optionen:** Sepia-Modus, Nachtmodus, individuelles Cropping/Zoom

**UX-Bewertung Performance:** ⭐⭐⭐⭐⭐ — Half-Page-Turn ist genial für Blasmusiker. Fußpedal-Support essential.

#### Annotationen

- **Apple-Pencil-Integration:** Sofortiger Eintritt in den Annotationsmodus bei Pencil-Berührung. Konfigurierbar.
- **Toolbar (verschiebbar an jeden Bildschirmrand):**
  - **Stifte & Textmarker:** Vordefinierte Presets + eigene (Dicke, Farbe, Deckkraft)
  - **Stempel:** Musikalische Symbole (Vorzeichen, Dynamik, Noten), benutzerdefinierte Stempel aus Bildern
  - **Formen:** Linien, Bögen, Pfeile, Textboxen
  - **Lineal:** Für präzise gerade Linien
  - **Auswahlwerkzeug:** Rechteck/Kreis zum Verschieben, Kopieren, Einfügen
  - **Text-Tool:** Direkte Textnotizen auf den Noten
  - **Radierer:** Doppeltipp am Apple Pencil 2 für Schnellzugriff
- **Annotation-Layers:** Separate Ebenen für verschiedene Markierungstypen, ein-/ausblendbar
- **Instant Annotation & Hover:** Mit Apple Pencil Hover auto-exit aus Annotationsmodus

**UX-Bewertung Annotation:** ⭐⭐⭐⭐⭐ — Benchmark. Aber: Keine Mehrstufigkeit (privat/Stimme/Orchester). Nur lokale Layers.

#### Setlist-Management

- Setlist-Hub über Sidebar erreichbar. Erstellen, Benennen, Sortieren (manuell, alphabetisch, meistgespielt).
- Songs per Drag & Drop hinzufügen und umsortieren.
- Platzhalter für noch nicht importierte Stücke.
- Nahtlose Navigation: Innerhalb einer Setlist von Song zu Song wischen.
- Setlists teilen (auch an Nicht-forScore-Nutzer).

**UX-Bewertung Setlist:** ⭐⭐⭐⭐⭐ — Intuitiv, schnell, mit Sharing.

#### Was forScore richtig gut macht

- **Ablenkungsfreier Performance-Modus** — nichts zwischen Musiker und Noten
- **Half-Page-Turn** — verhindert "Page-Jump-Schock"
- **Pencil-First Annotation** — Start Drawing = Start Annotating
- **Vielfältige Import-Wege** ohne Medienbruch
- **Metronom, Stimmgerät, Piano** direkt integriert

#### Schwächen / Chancen für Sheetstorm

- Nur Apple-Ökosystem → wir müssen Cross-Platform sein
- Keine zentrale Verwaltung für eine Kapelle (keine Stimmenverteilung)
- Keine Mehrstufigkeit bei Annotationen (privat/Stimme/Dirigent)
- Kein Vereinsleben (Termine, Zu-/Absagen, Schichtplanung)
- Kein AI-Upload mit Metadaten-Erkennung

---

### 2.2 MobileSheets — Cross-Platform-Power für Musiker

**Plattformen:** Android, iOS, Windows, macOS
**Website:** https://zubersoft.com/mobilesheets/
**Google Play:** https://play.google.com/store/apps/details?id=com.zubersoft.mobilesheetspro
**Handbuch:** https://zubersoft.com/mobilesheets/manual.php?lang=en
**Annotations-Doku:** https://zubersoft.com/mobilesheets/features/annotations/

#### Haupt-Screens & Navigation

- **Bibliotheks-Ansicht (Startscreen):** Tabs oben — Komponisten, Titel, Zuletzt geöffnet. Tabs konfigurierbar für weniger Clutter.
- **Einstellungen:** Über 3-Punkte-Menü. Umfangreiche Anpassung von Theme, sichtbaren Metadaten, Tab-Auswahl.
- **Overlay-Modus:** Bildschirmmitte tippen → Overlay mit Bookmarks, Linkpoints, Annotations-Zugang, Seitenmanagement.

#### Import/Upload-Flow

- Import über Gerätespeicher oder Cloud (Google Drive, Dropbox etc.)
- Einzelimport empfohlen für präzise Metadaten-Eingabe
- 20+ Metadatenfelder pro Partitur (Genre, Schwierigkeitsgrad, Instrument etc.)

**UX-Bewertung Import:** ⭐⭐⭐⭐ — Mächtig, aber steile Lernkurve wegen Funktionsvielfalt.

#### Performance-Modus

- **Overlay wird gesperrt** — kein versehentliches Editieren
- **Zoom-Features werden deaktiviert** — nur Seitenwechsel möglich
- **Anzeigemodi:** Ein-Seite, Zwei-Seiten (Querformat), Half-Page-Turn, vertikales Scrolling
- **Hands-Free:** Bluetooth/USB-Fußpedale, Face-Gesten (Mund öffnen, Lächeln)
- **Bookmarks & Link Points:** Schnellsprünge zu bestimmten Stellen, ideal für Wiederholungen und Codas

**UX-Bewertung Performance:** ⭐⭐⭐⭐⭐ — Gleichwertig mit forScore. Link Points für Wiederholungen = einzigartig.

#### Annotationen

- **Stift:** Freihandzeichnen, druckempfindlich mit Stylus
- **Textmarker:** Halbtransparent für Hervorhebungen
- **Stempel-Bibliothek:** Große Sammlung musikalischer Symbole, plus Custom-Stempel-Import
- **Formen, Pfeile, Crescendo-Tool, Piano-Notensystem-Tool**
- **Radierer, Nudge-Tool** (Pixel-genaues Verschieben)
- **Layers:** Verschiedene Ebenen, ein-/ausblendbar
- **Favoriten:** Häufig genutzte Tool-Konfigurationen speichern
- **Undo/Redo, Autosave**
- **3-Finger-Tap** zum schnellen Ein-/Ausstieg aus dem Annotationsmodus

**UX-Bewertung Annotation:** ⭐⭐⭐⭐⭐ — Nudge-Tool und Favoriten sind clever. Ebenfalls nur lokale Layers.

#### Setlist-Management

- Scores in Setlists gruppieren, nahtlose Übergänge
- MIDI-Integration: Songs können MIDI-Befehle an externe Geräte senden
- WiFi/Bluetooth-Sync für Gruppen-Performance (alle Geräte zeigen gleiches Stück)

**UX-Bewertung Setlist:** ⭐⭐⭐⭐ — MIDI-Integration überlegen, aber Sync rudimentär.

#### Was MobileSheets richtig gut macht

- **Cross-Platform** — das breiteste Plattformangebot
- **Link Points** für Wiederholungen/Codas — musikalisch gedacht
- **20+ Metadatenfelder** für professionelle Archivierung
- **Favoriten-System** für Annotationstools
- **WiFi-Sync** für Gruppen (rudimentär aber funktional)

#### Schwächen / Chancen für Sheetstorm

- UI wirkt technisch / weniger poliert als forScore
- Steile Lernkurve — zu viele Optionen auf einmal
- Keine zentrale Vereinsverwaltung
- Separate Lizenzen pro Plattform (frustrierend)

---

### 2.3 Newzik — Ensemble-Kollaboration auf Profi-Niveau

**Plattformen:** iOS, Web
**Website:** https://newzik.com/en
**App Store:** https://apps.apple.com/app/newzik-sheet-music-reader/id966963109
**Ensemble-Info:** https://newzik.com/en/ensemble
**Support-Docs (Layers):** https://support.newzik.com/en/support/solutions/articles/77000152066-using-annotation-layers

#### Haupt-Screens & Navigation

- **Noten-Ansicht:** Crisp PDF- oder interaktive "LiveScore"-Darstellung. Pinch/Zoom, Wisch-Navigation.
- **Sidebar/Bibliothek:** Organisation nach Projekten, Setlists, Komponisten, Tags. Cloud-synchronisiert.
- **Web-Interface:** Für Bibliotheksverwaltung, Metadaten-Editing, LiveScore-Konvertierung optimiert.
- **iPad-Optimiert:** Lesen, Annotieren und Aufführen primär auf iPad. Web = Admin-Oberfläche.

#### Import/Upload-Flow

- PDF-Import oder direkte LiveScore-Konvertierung (AI-basiert: PDF → interaktive Partitur)
- Cloud-basierte Notenbibliothek mit Access-Control
- Projekte erstellen → Partituren hochladen → an Ensemble-Mitglieder verteilen

#### Performance-Modus

- Half-Page-Turns
- Bluetooth-Fußpedale, Face-Gesten
- Integriertes Metronom, Stimmgerät, Recorder
- Playback mit MIDI-Begleitung, On-Screen-Cursor für Partitur-Verfolgung

#### Annotationen — Das Highlight: Mehrstufige Layer

**Newzik hat das fortschrittlichste Annotations-Layer-System:**

1. **Private Layer:** Nur der Ersteller sieht und bearbeitet — persönliche Übungsnotizen
2. **Public Layer:** Alle Projektmitglieder können sehen, nur Owner editiert — Dirigenten-Anweisungen
3. **Shared Layer:** Alle können sehen UND editieren — kollaborative Eintragungen

**Workflow für Dirigenten:**
1. Dirigent erstellt ein Projekt, lädt Partituren hoch
2. Ensemble-Mitglieder werden zum Projekt eingeladen
3. Partituren werden verteilt — jeder bekommt die "Referenz-Version"
4. Dirigent annotiert auf einem Public Layer → alle Musiker sehen die Änderungen sofort
5. Musiker annotieren auf ihren Private Layers → nur für sie selbst sichtbar
6. Updates (Score-Ersetzungen, Korrekturen) werden in Echtzeit an alle synchronisiert

**UX-Bewertung Annotation:** ⭐⭐⭐⭐⭐ — Nächstes an unserem Drei-Ebenen-Modell (Privat/Stimme/Orchester). Aber kein explizites "Stimmen-Layer" — nur Privat vs. Projekt-Layer.

#### Was Newzik richtig gut macht

- **Echtzeit-Collaboration** — Annotationen live synchronisiert
- **LiveScore AI** — PDFs in interaktive, navigierbare Partituren konvertieren
- **Layer-System** (Privat/Public/Shared) — klarer Rollenseparation
- **Projekt-basierter Workflow** — Dirigent steuert zentral
- **Web-Admin + iPad-Performance** — klare Trennung Admin vs. Aufführung

#### Schwächen / Chancen für Sheetstorm

- Kein Android → kritisch für Blaskapellen mit gemischten Geräten
- Abo-Modell kann teuer werden
- Kein explizites Stimmen-Mapping (z.B. "2. Klarinette → Klarinette → 1. Klarinette" Fallback)
- Keine Vereinsfeatures (Termine, Feste, Schichtplanung)

---

### 2.4 Marschpat — Speziell für Blasmusik entwickelt

**Plattformen:** iOS, Android, Web, PocketBook E-Reader
**Website:** https://www.marschpat.com
**App Store:** https://apps.apple.com/at/app/marschpat/id1505765384
**Google Play:** https://play.google.com/store/apps/details?id=at.marschpat.Marschpat.Marching.App
**YouTube Tutorial:** https://www.youtube.com/watch?v=WWgyUwENYtQ
**Kurzanleitung:** https://de.readkong.com/page/kurzanleitungen-zum-marschpat-system-6921900

#### Haupt-Screens & Navigation

- **Dashboard/Startseite:** Übersicht der eigenen Notenbücher und Stücke. Button zum Anlegen neuer Notenbücher.
- **Notenanzeige:** Vollbildmodus, abhängig vom gewählten Instrument/Stimme. Instrumentenauswahl über Dropdown-Menü.
- **Stimmenmenü:** Für jedes Stück Drop-Down oder Instrumentenauswahl — zeigt nur die dem Musiker zugewiesene Stimme.
- **Offline-Modus:** Nach Download alle Stimmen auch ohne Netz verfügbar.

#### Import/Upload-Flow

- Eigene Arrangements (PDF, Bild, MusicXML) können hochgeladen und zugeordnet werden
- Über 10.000 Stücke im Marschpat-Katalog mit bis zu 50 Stimmen pro Stück
- Web-Interface für Verwaltung und Stimmenzuordnung

#### Stimmenverteilung — Das Kernfeature

- **Dirigenten-Masterfunktion:** Dirigent wählt Stück zentral aus → alle Geräte zeigen das gleiche Stück an
- **Gleichzeitiges Umblättern** für alle durch Dirigent gesteuert
- **Stimmenwechsel in Echtzeit:** Musiker kann zwischen verfügbaren Stimmen wechseln
- **Zuweisung:** Leiter ordnet Musikern gezielt Stimmen zu

#### Performance-Modus

- Hochformat und Querformat für verschiedene Geräte (Tablet, E-Reader, Smartphone)
- Kein dedizierter Performance-Lock-Modus erkennbar
- E-Reader-Unterstützung (PocketBook): Leicht, wetterfest, outdoor-tauglich — einzigartig am Markt

#### Annotationen

- **Keine Annotationen auf Notenblättern!** — Größte UX-Lücke
- Musiker können keine persönlichen Markierungen oder Dirigenten-Hinweise eintragen

#### Was Marschpat richtig gut macht

- **Einziger Anbieter mit E-Reader-Unterstützung** — outdoortauglich
- **Blasmusik-Kontext verstanden:** 50 Stimmen pro Stück, Registerlogik
- **Dirigenten-Steuerung** — zentrales Umblättern für alle
- **Termin-/Probenverwaltung** mit Zu-/Absagen integriert
- **Offline-Modus** für Auftritte essentiell

#### Schwächen / Chancen für Sheetstorm

- Keine Annotationen — absolutes No-Go für ernsthafte Musiker
- Account-/Support-Probleme (3,7/5 im App Store)
- Keine AI-Metadatenerkennung beim Upload
- Keine Mehrstufigkeit bei Markierungen
- E-Reader-Hardware = Extra-Kosten

---

### 2.5 Notabl — All-in-One für Musikvereine

**Plattformen:** Web, App
**Website:** https://notabl.de

#### Haupt-Screens & Navigation

- **Dashboard:** Tabellarische Übersicht mit Terminen, Proben, Stücken
- **Notenarchiv:** Digitale Konzertmappe für alle Mitglieder, filterbar nach Setlist, Instrument/Stimme, Konzert
- **Terminverwaltung:** Listen- und Kalenderansicht, direkte Zu-/Absage
- **Responsives Design:** Vereinfachte Ansicht für Smartphone, erweitert für Tablet/Desktop

#### Stimmenzuordnung

- Digitale Zuweisung von Stimmen an einzelne Musiker
- **Dynamische Stimmenzuweisung bei Ausfällen** — ein Klick, um Stimme an Ersatzmusiker zu übergeben
- Mitglieder sehen immer nur die für sie relevanten Noten

#### Was Notabl richtig gut macht

- **Ein-Klick-Stimmenneuverteilung** bei Ausfällen — extrem pragmatisch
- **Alles in einer App:** Noten + Konzertplanung + Stimmenzuordnung
- **Mitglieder nutzen kostenlos** — Verein zahlt
- **DSGVO-konform, gehostet in Deutschland**

#### Schwächen / Chancen für Sheetstorm

- Kein leistungsfähiger PDF-Viewer (kein Cropping, kein Auto-Zoom, keine Annotationen)
- Keine AI-Features
- Keine persönliche Notensammlung
- Keine Multi-Kapellen-Zugehörigkeit
- Preise nicht transparent

---

### 2.6 Glissandoo — Vereinsorganisation mit Musikfokus

**Plattformen:** iOS, Android, Web
**Website:** https://glissandoo.com/de
**App Store:** https://apps.apple.com/app/glissandoo/id1493953499
**Google Play:** https://play.google.com/store/apps/details?id=com.glissandoo

#### Haupt-Screens & Navigation

- **Zentrales Dashboard:** Anstehende Events, Proben, Aktivitäten auf einen Blick
- **Probenplanung:** Zeitraum, Dauer, Ort, Repertoire verknüpfen. Wiederkehrende Proben automatisierbar.
- **Anwesenheit:** Echtzeit-Anwesenheitskontrolle, RSVP direkt in der App, Statistiken pro Mitglied/Sektion/Ensemble
- **Kommunikation:** Gruppen- und 1:1-Messaging, Push-Benachrichtigungen
- **Mitgliederverwaltung:** Profile mit Kontaktdaten, Anwesenheitshistorie, Filter nach Instrument/Register
- **Repertoire & Dateien:** Upload, Zuordnung und Freigabe von Noten (PDF, Audio, Video) an Events

#### Was Glissandoo richtig gut macht

- **Anwesenheitsstatistiken** — motivierend visualisiert
- **Noten an Proben verknüpft** — kontextueller Zugang
- **Bis 20 Mitglieder kostenlos** — niedrige Einstiegshürde
- **Push-Benachrichtigungen** für Probenänderungen

#### Schwächen / Chancen für Sheetstorm

- Kein PDF-Viewer, keine Annotations
- Notenverteilung = reiner Datei-Upload (keine intelligente Stimmenzuordnung)
- Kein Metronom, kein Stimmgerät

---

### 2.7 Konzertmeister — Terminplanung perfektioniert

**Plattformen:** iOS, Android, Web
**Website:** https://konzertmeister.app/de
**App Store:** https://apps.apple.com/at/app/konzertmeister/id1114620982
**Google Play:** https://play.google.com/store/apps/details?id=rocks.konzertmeister.Production
**PDF-Anleitung (mit Screenshots):** https://www.musikverein-fremdingen.de/pdf/downloads/konzertmeister-anleitung-mvf-250308.pdf

#### Haupt-Screens & Navigation

- **Terminübersicht:** Modernes Kalendermodul. Jeder Termin mit Uhrzeit, Ort, Kommentarfeld, Rückmeldepflicht.
- **Rückmeldung (1-Click):** Große Zu-/Absage-Buttons direkt am Termin. Anwesenheitsübersicht sofort sichtbar.
- **Gruppeneinteilung:** Register, Stimmlage, Vereinsrolle
- **Kommunikation:** Pinnwand, Chat, Push-Benachrichtigungen
- **Setlist-/Musikstückverwaltung:** Stücke an Termine anhängen
- **Umfragen & Aufgabenverwaltung**
- **Kalender-Sync:** Google, Apple, Outlook Integration

#### Was Konzertmeister richtig gut macht

- **1-Click Zu-/Absage** — minimaler Aufwand für Mitglieder
- **Sofortige Anwesenheitsübersicht** für Vorstand/Dirigent
- **Register-Benachrichtigungen** — nur relevante Infos an relevante Gruppen
- **DSGVO-konform, Basic kostenlos** bis 30 Mitglieder
- **Kalender-Sync** — kein Medienbruch mit privatem Kalender

#### Schwächen / Chancen für Sheetstorm

- Keine Notenanzeige, keine PDFs, keine Annotationen
- Keine Notenverteilung
- Begrenzter Online-Speicher

---

### 2.8 Musicorum — Intelligentes Notenarchiv

**Plattformen:** iOS, Android, Web
**Website:** https://musicorum.de/en/
**App Store:** https://apps.apple.com/de/app/musicorum/id6740430635
**Google Play:** https://play.google.com/store/apps/details?id=de.gertheiss.joshua.musicorum.musicorum_app

#### Haupt-Screens & Navigation

- **Listenansicht:** Stücke/Alben in übersichtlichen Listen, filterbar
- **Detailseite pro Stück:** Metadaten (Kaufdatum, Komponist, Arrangeur, Genre, Verlag), Audio-Dateien, Stimmen-Übersicht
- **Album-Management:** Stücke zu Konzertprogrammen zusammenstellen
- **Download/Sharing:** Stimmen-Download direkt in App, Weitergabe an Aushilfen per Link (ohne Registrierung)

#### Stimmenzuordnung

- Automatische Zuordnung der passenden Stimme an jeden Musiker basierend auf Instrumentenprofil
- System kennt die richtige Stimme für jedes Instrument, ob Quartett oder großes Ensemble
- Import bestehender Archive (z.B. aus Excel)

#### Was Musicorum richtig gut macht

- **Aushilfen-Link ohne Registrierung** — extrem pragmatisch für Ersatzmusiker
- **Auto-Stimmenzuordnung** nach Instrumentenprofil
- **Bewertungssystem** für Stücke (anonyme Bewertungen zur Konzertauswahl)
- **Excel-Import** für Migration bestehender Archive
- **DSGVO-konform**

#### Schwächen / Chancen für Sheetstorm

- Kein integrierter Noten-Viewer — verweist auf PiaScore/MobileSheets
- Keine Annotations
- Keine Vereinsverwaltung (Termine, Events)
- Keine AI-basierte Erkennung

---

### 2.9 BandHelper — Band-Management mit MIDI-Power

**Plattformen:** iOS, Android, Mac, Windows, Web
**Website:** https://www.bandhelper.com
**App Store:** https://apps.apple.com/app/bandhelper/id552012927
**Google Play:** https://play.google.com/store/apps/details?id=com.arlomedia.bandhelper
**Screenshots:** https://www.bandhelper.com/screenshots.html

#### Haupt-Screens & Navigation

- **Tablet-Layout:** Linkes Panel = Setlists, rechtes Panel = Song-Details (Lyrics, Chords, Tempo, Notizen, MIDI-Actions)
- **Song-Ansicht:** Auto-Scroll Lyrics, Akkorde, Tonart, Tempo, Performance-Anweisungen — pro Musiker individuell konfigurierbar
- **Individuelle Layouts:** Sänger können Akkorde ausblenden, Instrumentalisten einblenden
- **Cloud-Sync:** Änderungen sofort an alle Bandmitglieder

#### MIDI-Integration

- Jeder Song/Setlist-Eintrag kann MIDI-Messages triggern (Programmwechsel an Synths, Gitarren-Effektgeräte)
- Mehrere MIDI-Presets pro Song für verschiedene Song-Sections
- Bluetooth/USB-MIDI-Adapter-Unterstützung

#### Weitere Features

- Proben-/Gig-Kalender, Anwesenheitsbestätigung
- Charts, MP3-Demos an Songs/Gigs anhängen
- Finanz-/Booking-Tools, Bühnenplan-Verwaltung

#### Was BandHelper richtig gut macht

- **Rollenbasierte Views** — jeder Musiker sieht, was für ihn relevant ist
- **MIDI-Automation** pro Song — professionell für Live-Performance
- **Cloud-Sync in Echtzeit** — Last-Minute-Setlist-Änderungen funktionieren
- **Split-Panel-UI** auf Tablets — effiziente Nutzung der Bildschirmfläche

#### Schwächen / Chancen für Sheetstorm

- Abo-basiert, komplex
- Kein Vereinsfokus (keine Stimmenverteilung, keine Registerlogik)
- Kein dedizierter PDF-Noten-Viewer

---

### 2.10 Musicnotes — Store + Viewer in einem

**Plattformen:** iOS, Android, Windows, Kindle Fire, Web
**Website:** https://www.musicnotes.com
**Support-Docs:** https://help.musicnotes.com/hc/en-us/categories/360003336892-App-Support

#### Haupt-Screens & Navigation

- **Bibliothek/Hauptscreen:** Eigene gekaufte und importierte Noten
- **Notenstore:** 500.000+ lizenzierte Arrangements direkt in der App durchsuchbar und kaufbar
- **Viewer:** Interaktive Partitur mit Playback, Transposition, Markup-Tools, Seitenwechsel per Touch oder Fußpedal
- **Multi-Page-View:** Auf iPad zwei Seiten nebeneinander

#### Import

- PDF-Import über Files-App (iOS 12+) oder iTunes/Finder
- Importierte PDFs sind statisch (Playback/Transposition nur für gekaufte Noten)

#### Annotations

- Farbige Stifte, Textmarker, Text — direkt auf Partituren
- Sync über Geräte mit Musicnotes Pro Abo

#### Was Musicnotes richtig gut macht

- **Nahtlose Store-Integration** — entdecken, kaufen, sofort spielen
- **Annotation-Sync** über Geräte (Pro-Feature)
- **Playback mit Mixer** — Instrumente stummschalten, Tempo ändern
- **Setlists & Ordner** für Organisation

#### Schwächen / Chancen für Sheetstorm

- Hauptfokus = Notenverkauf, nicht Vereinsverwaltung
- Importierte PDFs stark eingeschränkt
- Kein Ensemble/Kapellen-Feature

---

### 2.11 SongBook (LinkeSOFT) — ChordPro-Profi

**Plattformen:** iOS, Android, Windows, macOS
**Website/Handbuch:** https://linkesoft.com/songbook/manual.html
**App Store:** https://apps.apple.com/app/songbook-chordpro/id392888837

#### Haupt-Screens & Navigation

- **Songliste:** Kategorien, Tags, Sets. Filter und Suche.
- **Setlist-Editor:** Drag & Drop zum Umsortieren, Songs hinzufügen/entfernen mit einem Tap
- **Song-Ansicht:** Große Lyrics + Chords im ChordPro-Format, interaktive Akkorddiagramme bei Tap
- **ChordPro-Editor:** Inline-Editing mit Syntax-Helfern und Chord-Picker

#### Features

- Transposition mit einem Tap
- Auto-Scroll, Metronom, MIDI
- Akkord-Bibliothek für verschiedene Instrumente
- Offline + optionaler Cloud-Sync

#### Was SongBook richtig gut macht

- **ChordPro-Format native** — Standard für Text+Akkord-Songs
- **Akkorddiagramm-Popup** bei Tap — lernfreundlich
- **Auto-Scroll** mit konfigurierbarer Geschwindigkeit

#### Schwächen / Chancen für Sheetstorm

- Fokus auf Lyrics+Chords, nicht auf Notenblätter/PDFs
- Kein Ensemble-Feature
- Für Blaskapellen nicht direkt relevant (kein Notensatz-Format)

---

### 2.12 BAND App — Gruppenkommunikation

**Plattformen:** iOS, Android, Web
**Website:** https://about.band.us/features
**Tutorials:** https://about.band.us/resources/tutorials

#### Haupt-Screens & Navigation

- **Home-Screen:** Alle "Bands" (Gruppen) als Thumbnails mit Unread-Badges
- **Gruppen-Feed:** Social-Media-ähnlicher Verlauf mit Posts, Bildern, Links, Kommentaren, Reaktionen
- **Chat:** Gruppen- und 1:1-Messaging, Untergruppen-Chats
- **Kalender:** Integrierter Gruppen-Kalender mit RSVP und Erinnerungen
- **Dateien/Alben:** Organisierte Ordner für Gruppenmedien
- **Umfragen & To-Do-Listen**
- **Admin-Controls:** Berechtigungen, Mitglieder-Genehmigung, Content-Moderation

#### Was BAND richtig gut macht

- **Familiäre Social-Feed-UX** — niedrige Lernkurve
- **Subgruppen-Chats** — z.B. nur Blechbläser
- **Einladungsbasiert** — datenschutzfreundlich
- **Kostenlos** — kein Preisargument gegen Adoption

#### Schwächen / Chancen für Sheetstorm

- Nicht musikspezifisch — keine Noten, keine Stimmen
- Kein Notenmanagement
- Wir könnten die Feed + Chat UX für unser Vereinsleben-Feature adaptieren

---

### 2.13 Vereinsplaner — Professionelle Vereinsverwaltung

**Plattformen:** Web + App (iOS, Android)
**Website:** https://vereinsplaner.at/v/software-fuer-musikvereine
**App Store:** https://apps.apple.com/de/app/vereinsplaner-app-f%C3%BCr-vereine/id1067566347
**Google Play:** https://play.google.com/store/apps/details?id=at.vereinsplaner.app

#### Haupt-Screens & Navigation

- **Dashboard:** Anstehende Termine, News, Vereinsinfos auf einen Blick
- **Terminplanung:** Proben, Konzerte, Vorstandssitzungen anlegen. Auto-Erinnerungen, Zu-/Absagen, Kalender-Übernahme. Anwesenheitsprotokolle.
- **Mitgliederverwaltung:** Stammdaten, Gruppen (Register, Jugendorchester, Vorstand), Rollen, Beiträge. Flexible Berechtigungen.
- **Inventarverwaltung:** Instrumente, Equipment
- **News & Chat:** DSGVO-konformer Newsfeed, Chat, Umfragen, Benachrichtigungen
- **Für Musikvereine optimiert:** Registergruppen, Probenbeteiligungen, Inventar

#### Was Vereinsplaner richtig gut macht

- **Musikverein-spezifische Module** (Register, Inventar)
- **Modernes UI** — zeitgemäß, intuitiv für alle Altersklassen
- **Automatische Erinnerungen** — reduzieren Verwaltungsaufwand
- **Cloudbasiert & plattformübergreifend**

#### Schwächen / Chancen für Sheetstorm

- Keine Notenanzeige, keine Notenverteilung
- Kein PDF-Viewer, keine Annotations
- Fokus auf Administration, nicht auf Musikmachen

---

### 2.14 WePlayIn.Band — Modernes Orchester-Management

**Plattformen:** iOS, Android, Web
**Website:** https://weplayin.band/
**Google Play:** https://play.google.com/store/apps/details?id=com.weplayin.band
**App Store:** https://apps.apple.com/app/we-play-in-band/id6743351042

#### Haupt-Screens & Navigation

- **Dashboard:** Nächste Events und Anwesenheit auf einen Blick, Quick-Response-Buttons
- **Event-Management:** Konzerte, Proben, Sektionsproben. Details mit Venue, Dresscode, Verfügbarkeit.
- **Anwesenheits-Tracking:** Echtzeit, nach Sektionen und Positionen. Export als PDF.
- **Repertoire:** Katalogisierung nach Genre, Komponist, Arrangeur, Schwierigkeitsgrad, Dauer. Noten verteilen, Stimmen zuweisen.
- **Konzertprogramm-Planung:** Exakte Reihenfolge und Timing pro Stück
- **Analytics-Dashboard:** Teilnahme-Trends, Lückenanalyse
- **AI-Assistent:** Events erstellen, Repertoire verwalten per Sprachbefehl
- **Operations-Log:** Protokoll aller Vereinsaktivitäten

#### Was WePlayIn.Band richtig gut macht

- **AI-Assistent für Verwaltungsaufgaben** — innovativ
- **Analytics mit Lückenanalyse** — datengetriebene Probenplanung
- **Event-spezifische Fragen** (Essen, Parkplatz, Equipment) — durchdacht
- **Kalender-Sync** (iOS, Google)
- **PDF-Export** für Berichte

#### Schwächen / Chancen für Sheetstorm

- Kein vollwertiger Noten-Viewer mit Annotationen
- Relativ neuer Anbieter — wenig Community
- Keine Echtzeit-Metronom-Synchronisation

---

## 3. Lessons Learned — Best Practices für Sheetstorm

### 3.1 Notenanzeige & Performance

| Pattern | Quelle | Empfehlung für Sheetstorm |
|---------|--------|--------------------------|
| **Ablenkungsfreier Performance-Modus** | forScore, MobileSheets | MUST HAVE. Alle UI-Elemente verstecken, nur Seitenwechsel erlauben. Dedizierter "Auftritt"-Modus. |
| **Half-Page-Turn** | forScore, Newzik | MUST HAVE. Untere Hälfte anzeigen, obere bleibt sichtbar. Verhindert den gefürchteten "Page-Jump-Schock". |
| **Bluetooth-Fußpedal-Support** | forScore, MobileSheets, Newzik | MUST HAVE. Hands-free Seitenwechsel ist für Blasmusiker essentiell. |
| **Face-Gesten** | forScore, MobileSheets | NICE TO HAVE. Innovativ, aber unzuverlässig in Probe-Umgebungen. |
| **Link Points für Wiederholungen** | MobileSheets | SHOULD HAVE. D.S., D.C., Coda-Sprünge direkt auf der Partitur markieren. |
| **Auto-Scroll/Reflow** | forScore, SongBook | COULD HAVE. Für lineare Stücke nützlich, für Blasmusik weniger relevant. |
| **Two-Up-Modus (Querformat)** | forScore, MobileSheets, Musicnotes | SHOULD HAVE. Zwei Seiten nebeneinander auf großen Tablets. |

### 3.2 Annotations

| Pattern | Quelle | Empfehlung für Sheetstorm |
|---------|--------|--------------------------|
| **Pencil/Stylus-First** | forScore | MUST HAVE. Stift berührt Screen = sofort annotieren. Kein Menü-Umweg. |
| **Musikalische Stempel-Bibliothek** | forScore, MobileSheets | MUST HAVE. Vorzeichen, Dynamik, Noten, Artikulation als fertige Symbole. |
| **Annotation-Layers** | forScore, MobileSheets, Newzik | MUST HAVE. Unser 3-Ebenen-Modell (Privat/Stimme/Orchester) ist der Differenzierer. Newzik kommt am nächsten, hat aber nur Privat/Projekt. |
| **Favoriten für Tools** | MobileSheets | SHOULD HAVE. Häufig genutzte Tool-Configs speichern und schnell wechseln. |
| **Verschiebbare Toolbar** | forScore | SHOULD HAVE. Toolbar an jeden Rand schieben, stört nicht bei der Arbeit. |
| **Echtzeit-Sync von Annotations** | Newzik | MUST HAVE. Dirigenten-Anweisungen sofort bei allen Musikern sichtbar. |

### 3.3 Import & Bibliothek

| Pattern | Quelle | Empfehlung für Sheetstorm |
|---------|--------|--------------------------|
| **Vielfältige Import-Wege** | forScore | MUST HAVE. Cloud, Kamera, Share-Sheet, Drag & Drop. Kein Medienbruch. |
| **Kamera-Scan mit PDF-Erstellung** | forScore | SHOULD HAVE. Papier → Digital direkt in der App. Plus unser AI-Labeling. |
| **20+ Metadatenfelder** | MobileSheets | SHOULD HAVE. Aber intelligente Defaults und AI-Vorschläge statt manueller Eingabe. |
| **Aushilfen-Link ohne Registrierung** | Musicorum | MUST HAVE. Brillante UX für Ersatzmusiker. Temporärer Zugang per Link. |
| **Excel-Import für Migration** | Musicorum | SHOULD HAVE. Viele Vereine haben existierende Archive in Spreadsheets. |

### 3.4 Stimmenverwaltung

| Pattern | Quelle | Empfehlung für Sheetstorm |
|---------|--------|--------------------------|
| **Auto-Stimmenzuordnung nach Instrumentenprofil** | Musicorum, Marschpat | MUST HAVE. Unser Fallback-System (2. Klarinette → Klarinette → 1. Klarinette) geht weiter. |
| **1-Klick-Stimmenneuverteilung** | Notabl | MUST HAVE. Bei Absage → Stimme sofort an Ersatz übergeben. |
| **Dirigenten-Mastersteuerung** | Marschpat | SHOULD HAVE. Dirigent steuert alle Geräte gleichzeitig. |
| **Projekt-basierte Verteilung** | Newzik | SHOULD HAVE. Partituren an Ensemble-Projekte (= Konzerte) binden. |

### 3.5 Setlist-Management

| Pattern | Quelle | Empfehlung für Sheetstorm |
|---------|--------|--------------------------|
| **Drag & Drop Sortierung** | forScore, BandHelper | MUST HAVE. Intuitivste Methode zum Umsortieren. |
| **Nahtlose Song-zu-Song-Navigation** | forScore, MobileSheets | MUST HAVE. Innerhalb der Setlist einfach weiterwischen. |
| **Platzhalter für fehlende Stücke** | forScore | NICE TO HAVE. Setlist planen bevor alle Noten digital sind. |
| **Cloud-Sync der Setlist** | BandHelper | MUST HAVE. Setlist-Änderungen sofort bei allen sichtbar. |
| **Setlist teilen (auch an Nicht-Nutzer)** | forScore | SHOULD HAVE. PDF-Export oder temporärer Link. |

### 3.6 Vereinsleben & Termine

| Pattern | Quelle | Empfehlung für Sheetstorm |
|---------|--------|--------------------------|
| **1-Click Zu-/Absage** | Konzertmeister, Glissandoo | MUST HAVE. Maximale Reibungslosigkeit. |
| **Sofortige Anwesenheitsübersicht** | Konzertmeister, WePlayIn.Band | MUST HAVE. Vorstand/Dirigent sieht sofort, wer kommt. |
| **Register-basierte Benachrichtigungen** | Konzertmeister, Vereinsplaner | MUST HAVE. Nur relevante Infos an relevante Gruppen. |
| **Kalender-Sync** | Konzertmeister, Vereinsplaner, WePlayIn.Band | MUST HAVE. Google, Apple, Outlook. |
| **Social-Feed für Vereinsnews** | BAND App | SHOULD HAVE. Familiäre, niedrigschwellige Kommunikation. |
| **Event-spezifische Fragen** | WePlayIn.Band | NICE TO HAVE. "Brauchst du Parkplatz?" etc. |
| **Anwesenheitsstatistiken** | Glissandoo, WePlayIn.Band | SHOULD HAVE. Motivierend visualisiert. |
| **Analytics-Dashboard** | WePlayIn.Band | COULD HAVE. Teilnahme-Trends, Lückenanalyse. |

### 3.7 Navigation & Informationsarchitektur

| Pattern | Quelle | Empfehlung für Sheetstorm |
|---------|--------|--------------------------|
| **Vollbild-Default für Noten** | forScore | MUST HAVE. Noten = Hauptbildschirm. Alles andere ist Overlay. |
| **Tab-basierte Bibliothek** | MobileSheets | SHOULD HAVE. Konfigurierbare Tabs (Titel, Komponist, Zuletzt). |
| **Split-Panel auf Tablets** | BandHelper | SHOULD HAVE. Links: Setlist/Bibliothek, Rechts: Notenansicht. |
| **Sidebar für Navigation** | forScore, Newzik | SHOULD HAVE. Hamburger-Menü oder Sidebar für Bibliothek, Setlists, Einstellungen. |
| **Web = Admin, App = Performance** | Newzik | SHOULD HAVE. Verwaltung am Desktop, Aufführung am Tablet. |

---

## 4. Anti-Patterns — Was wir vermeiden sollten

| Anti-Pattern | Gesehen bei | Warum vermeiden |
|-------------|------------|----------------|
| **Keine Annotationen auf Notenblättern** | Marschpat | Absolutes No-Go. Musiker MÜSSEN ihre Noten markieren können. |
| **Separater Noten-Viewer nötig** | Musicorum (verweist auf PiaScore/MobileSheets) | App-Wechsel = Friction. Alles in einer App. |
| **Zu viele Optionen ohne Guidance** | MobileSheets (20+ Metadatenfelder manuell) | Überforderung. AI-gestützte Defaults + optionale Detailfelder. |
| **Nur Apple-Ökosystem** | forScore, Newzik | Blaskapellen = gemischte Geräte. Cross-Platform ist Pflicht. |
| **Preise nicht transparent** | Notabl | Vertrauensverlust. Klare Preisseite. |
| **Separate Lizenzen pro Plattform** | MobileSheets | Frustrierend. Ein Account, alle Plattformen. |
| **Abo-only ohne Einmalkauf-Option** | BandHelper | Vereine haben fixe Budgets. Flexible Preismodelle. |
| **Veraltete UI** | BNote (Open Source) | Adoptionshürde, besonders bei jüngeren Musikern. |
| **Kein Offline-Modus** | Cloud-abhängige Apps | Auftritte sind oft an Orten ohne gutes WLAN/Netz. |
| **WhatsApp als Fallback für Kommunikation** | Status quo bei Vereinen | Unsere integrierte Kommunikation muss BESSER sein als WhatsApp. |

---

## 5. Ressourcen & Links

### Demos & Trials

| App | Link | Typ |
|-----|------|-----|
| forScore | https://apps.apple.com/app/forscore/id363738376 | Einmalkauf |
| MobileSheets | https://play.google.com/store/apps/details?id=com.zubersoft.mobilesheetspro | Einmalkauf |
| Newzik | https://apps.apple.com/app/newzik-sheet-music-reader/id966963109 | Freemium |
| Marschpat | https://apps.apple.com/at/app/marschpat/id1505765384 | Freemium |
| Glissandoo | https://apps.apple.com/app/glissandoo/id1493953499 | Kostenlos bis 20 Mitgl. |
| Konzertmeister | https://apps.apple.com/at/app/konzertmeister/id1114620982 | Kostenlos bis 30 Mitgl. |
| Musicorum | https://apps.apple.com/de/app/musicorum/id6740430635 | Demo |
| BandHelper | https://apps.apple.com/app/bandhelper/id552012927 | Abo |
| Musicnotes | https://www.musicnotes.com/apps/ | Kostenlos + In-App |
| SongBook | https://apps.apple.com/app/songbook-chordpro/id392888837 | Einmalkauf |
| BAND | https://about.band.us/ | Kostenlos |
| Vereinsplaner | https://vereinsplaner.at/ | Kostenlos (Basis) |
| WePlayIn.Band | https://weplayin.band/ | Community Edition |

### User Guides & Handbücher

| App | Link |
|-----|------|
| forScore User Guides | https://forscore.co/user-guides/ |
| forScore Annotation Docs | https://forscore.co/documentation/annotation/ |
| forScore Import Docs | https://forscore.co/documentation/adding-files/ |
| MobileSheets Manual | https://zubersoft.com/mobilesheets/manual.php?lang=en |
| MobileSheets Annotations | https://zubersoft.com/mobilesheets/features/annotations/ |
| Newzik Layers Support | https://support.newzik.com/en/support/solutions/articles/77000152066-using-annotation-layers |
| Marschpat Kurzanleitung | https://de.readkong.com/page/kurzanleitungen-zum-marschpat-system-6921900 |
| Konzertmeister Anleitung (PDF) | https://www.musikverein-fremdingen.de/pdf/downloads/konzertmeister-anleitung-mvf-250308.pdf |
| Musicnotes Support | https://help.musicnotes.com/hc/en-us/categories/360003336892-App-Support |
| SongBook Manual | https://linkesoft.com/songbook/manual.html |
| BAND Tutorials | https://about.band.us/resources/tutorials |

### Video-Tutorials

| App | Link | Beschreibung |
|-----|------|-------------|
| forScore Walkthrough 2024 | https://www.youtube.com/watch?v=7ro5VpW492U | Vollständiger Durchgang |
| forScore Friday Summer 2025 | https://www.youtube.com/watch?v=z3I66zPVsSY | Wöchentliche Tipps kompiliert |
| forScore Annotations Guide | https://www.youtube.com/watch?v=l6dTpq6HJh0 | Annotationsmodus im Detail |
| forScore Tutorials Playlist | https://www.youtube.com/playlist?list=PLKT1tUigAhGPiY47ecDF2YHfKQLGYWf5G | 40+ Videos |
| Marschpat Webmaske Tutorial | https://www.youtube.com/watch?v=WWgyUwENYtQ | Notenverwaltung im Web |

### UI-Inspiration & Design-Pattern-Quellen

| Quelle | Link | Nutzen |
|--------|------|--------|
| Mobbin | https://mobbin.com/ | Echte App-Screenshots und User Flows |
| Page Flows | https://pageflows.com/ | User-Flow-Aufnahmen realer Apps |
| UX Library | https://www.uxlibrary.org/explore/ui-design/ui-patterns-and-inspiration | UI-Pattern-Katalog |
| Piano Pantry forScore Guide | https://pianopantry.com/utilizing-forscore-app-features-a-visual-guide/ | Visueller Guide mit Screenshots |

---

> **Nächste Schritte:** Die identifizierten Best Practices werden in die UX-Spezifikation und Wireframes für Sheetstorm übernommen. Besonderer Fokus auf:
> 1. Ablenkungsfreier Performance-Modus mit Half-Page-Turn
> 2. 3-Ebenen-Annotationssystem (Privat/Stimme/Orchester)
> 3. Vielfältige Import-Wege mit AI-Unterstützung
> 4. 1-Klick Zu-/Absage und sofortige Anwesenheitsübersicht
> 5. Cross-Platform von Tag 1
