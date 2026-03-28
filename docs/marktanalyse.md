# Marktanalyse — Notenmanagement & Vereinsverwaltung für Blaskapellen

> **Erstellt:** 2026-03-28
> **Autor:** Fury (Business Analyst)
> **Quelle:** Umfangreiche Webrecherche (englisch- und deutschsprachig)
> **Status:** Abgeschlossen

---

## 1. Executive Summary

Der Markt für digitale Notenverwaltung und Vereinsorganisation im Musikbereich ist **fragmentiert**. Es existieren zahlreiche Lösungen, die jeweils einzelne Aspekte gut abdecken, aber **keine einzige Lösung vereint alle Kernbereiche**, die unsere App adressiert:

1. **Notenverwaltungs-Apps** (forScore, MobileSheets, Newzik) — exzellent beim Anzeigen und Annotieren von PDFs, aber schwach bei Vereinsorganisation und Stimmenzuordnung für ganze Kapellen.
2. **Blasmusik-spezifische Tools** (Marschpat, Notabl, Glissandoo, Musicorum) — verstehen den Blasmusik-Kontext, decken aber nur Teilbereiche ab und bieten selten hochwertige Notenanzeige-Funktionen.
3. **Vereinsverwaltungs-Software** (easyVerein, Vereinsplaner, ClubDesk, ComMusic) — stark bei Administration und Mitgliederverwaltung, aber ohne echte Noten-Funktionalität.
4. **Setlist-/Band-Management** (Bandhelper, OnSong, BandPlanr) — fokussiert auf Live-Performance, nicht auf Vereinsstruktur.
5. **Lehre-Plattformen** (Flat for Education, Tonara, Noteflight) — Lehrer-Schüler-Workflows, aber keine Vereinsintegration.

### Die zentrale Marktlücke

**Keine existierende Lösung kombiniert:**
- Zentrale Notenverwaltung mit intelligentem Stimmen-Mapping für Blaskapellen
- AI-gestützte Metadaten-Erkennung beim Upload
- Mehrstufige Annotationen (privat / Stimme / orchesterweit)
- Vereinsleben-Features (Konzertplanung, Schichtplanung, Zu-/Absagen)
- Multi-Kapellen-Zugehörigkeit
- Echtzeit-Metronom mit Geräte-Synchronisation
- Integriertes Lehre-Modul

Dies ist unsere strategische Chance.

---

## 2. Wettbewerber-Übersicht

### 2.1 Übersichtstabelle

| Produkt | Kategorie | Plattformen | Preismodell | Zielgruppe | Notenanzeige | Notenverwaltung (Kapelle) | Vereins-Features | Lehre |
|---------|-----------|-------------|-------------|------------|:------------:|:-------------------------:|:----------------:|:-----:|
| **forScore** | Sheet Music Reader | iOS/Mac | Einmalkauf $24,99 + opt. Abo $14,99/J | Einzelmusiker, Ensembles | ⭐⭐⭐⭐⭐ | ⭐⭐ | ❌ | ❌ |
| **MobileSheets** | Sheet Music Reader | Android/iOS/Win | Einmalkauf ~$15,99 | Einzelmusiker, Bands | ⭐⭐⭐⭐⭐ | ⭐⭐ | ❌ | ❌ |
| **Newzik** | Sheet Music + Ensemble | iOS/Web | Freemium + Abo | Orchester, Profis | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| **Marschpat** | Blasmusik-Noten | iOS/Android/Web/E-Reader | Abo ab 97€/J | Blaskapellen, Marschmusik | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ❌ |
| **Notabl** | Musikverein All-in-One | Web/App | Vereins-Grundgebühr | Musikvereine, Orchester | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| **Glissandoo** | Musikverein-Organisation | iOS/Android/Web | Bis 20 Mitgl. kostenlos | Musikvereine, Chöre | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| **Musicorum** | Notenverwaltung | iOS/Android/Web | Freemium/Abo | Musikvereine, Orchester | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ❌ |
| **SoftNote Web** | Notenarchiv | Web (plattformunabh.) | 39,95€/J | Musikvereine, Schulen | ❌ | ⭐⭐⭐ | ❌ | ❌ |
| **Konzertmeister** | Vereinsorganisation | iOS/Android/Web | Kostenlos bis 30 Mitgl., ab 33€/J | Musikvereine, Chöre | ❌ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ |
| **BNote** | Ensemble-Verwaltung | Web (Self-hosted) | Open Source, kostenlos | Ensembles, Vereine | ❌ | ⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| **Socie** | Vereins-App | iOS/Android/Web | Kostenlos bis Plus 37,50€/M | Vereine allgemein | ❌ | ⭐ | ⭐⭐⭐⭐ | ❌ |
| **easyVerein** | Vereinsverwaltung | Web | Abo (gestaffelt) | Vereine allgemein | ❌ | ⭐ | ⭐⭐⭐⭐⭐ | ❌ |
| **ComMusic** | Blasmusik-Verwaltung | Desktop/Web | Lizenz (auf Anfrage) | Blasmusikvereine, Verbände | ❌ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ |
| **WePlayIn.Band** | Orchester-Management | iOS/Android/Web | Community Edition (günstig) | Orchester, Bands | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| **Bandhelper** | Band-Management | iOS/Android/Mac/Win | Abo | Bands, Profis | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ❌ |
| **Flat for Education** | Lehre-Plattform | Web | Abo (Schullizenzen) | Schulen, Lehrer | ⭐⭐⭐ | ❌ | ❌ | ⭐⭐⭐⭐⭐ |
| **Tonara** | Lehre-Plattform | iOS/Android/Web | Freemium/Abo | Lehrer, Schüler | ⭐⭐ | ❌ | ❌ | ⭐⭐⭐⭐⭐ |
| **Tomplay** | Interaktives Üben | iOS/Android/Web/Mac/Win | Abo | Einzelmusiker, Schüler | ⭐⭐⭐⭐ | ❌ | ❌ | ⭐⭐⭐⭐ |

**Legende:** ⭐⭐⭐⭐⭐ = Exzellent | ⭐⭐⭐⭐ = Gut | ⭐⭐⭐ = Mittel | ⭐⭐ = Basisumsetzung | ⭐ = Minimal | ❌ = Nicht vorhanden

---

## 3. Detailanalyse der Wettbewerber

### 3.1 forScore

**Website:** https://forscore.co
**Zielgruppe:** Einzelmusiker, kleine Ensembles (Apple-Ökosystem)
**Plattformen:** iOS, iPadOS, macOS, visionOS

**Stärken:**
- Branchenführende Annotationstools mit Apple-Pencil-Integration
- Exzellente PDF-Verwaltung mit Tagging, Smart Bookmarks, mächtiger Suche
- Setlist-Management mit Performance-Modus
- Integriertes Metronom, Stimmgerät, Pitch Pipe, Piano
- Cropping & Zoom-Optimierung für optimale Darstellung
- Bluetooth-Fußpedal-Unterstützung für Seitenwechsel
- iCloud-Sync, Cloud-Import (Dropbox, Google Drive)
- Einmalkauf — keine laufenden Kosten

**Schwächen:**
- **Nur Apple** — kein Android, kein Windows
- Keine zentrale Verwaltung für eine Kapelle (keine Stimmenverteilung)
- Keine Vereinsorganisation (Termine, Zu-/Absagen, Schichtplanung)
- Keine AI-basierte Metadatenerkennung
- Keine mehrstufigen Annotationsebenen (privat/Stimme/Orchester)
- Kein Lehre-Modul

**Preise:** Einmalkauf $24,99 + optional forScore Pro $14,99/Jahr

---

### 3.2 MobileSheets

**Website:** https://zubersoft.com/mobilesheets/
**Zielgruppe:** Einzelmusiker, Bands mit gemischten Geräten
**Plattformen:** Android, iOS, Windows, macOS

**Stärken:**
- Cross-Platform — das breiteste Plattformangebot unter den Sheet-Music-Apps
- Mächtige Bibliotheksverwaltung mit 20+ Metadatenfeldern
- Setlists mit nahtlosen Übergängen
- MIDI-Integration für fortgeschrittene Bühnensteuerung
- Auto-Cropping und flexible Anzeigemodi
- Geräte-Sync über WiFi/Bluetooth für Gruppen-Performance
- Einmalkauf, kein Abo erforderlich

**Schwächen:**
- Keine zentrale Notenverwaltung für einen Verein
- Separate Lizenzen pro Plattform erforderlich
- Kein eingebauter Notenbestand — Nutzer müssen eigene PDFs mitbringen
- Steilere Lernkurve wegen Funktionsvielfalt
- Keine Vereins-Features (Termine, Anwesenheit)
- Keine AI-Features für automatische Erkennung

**Preise:** Einmalkauf ~$15,99 pro Plattform

---

### 3.3 Newzik

**Website:** https://newzik.com
**Zielgruppe:** Professionelle Orchester, Ensembles, Musikschulen
**Plattformen:** iOS, Web

**Stärken:**
- **Stärkster Ensemble-Fokus** unter den Sheet-Music-Apps
- Echtzeit-Kollaboration: Annotationen werden live für alle synchronisiert
- LiveScore AI: PDFs in interaktive, navigierbare Partituren konvertieren
- AI-gestützte Transposition und OMR (Optical Music Recognition)
- Cloud-basierte Notenbibliothek mit Access-Control
- Performance-Modus mit Half-Page-Turns
- Integriertes Metronom, Tuner, Recorder

**Schwächen:**
- **Kein Android** — nur iOS und Web
- Cloud-Abhängigkeit für viele Features
- Abo-Modell kann teuer werden für große Orchester
- Keine Vereinsverwaltung (Termine, Events, Schichtplanung)
- Kein Lehre-Modul
- Kein Stimmen-Mapping nach Instrumentenprofilen (Fallback-Logik)

**Preise:** Freemium (3 Partituren kostenlos), Essentials (Einmalkauf), Premium (Abo), Enterprise (auf Anfrage)

---

### 3.4 Marschpat

**Website:** https://www.marschpat.com
**Zielgruppe:** Blaskapellen, Marschmusik, traditionelle Blasorchester
**Plattformen:** iOS, Android, Web, PocketBook E-Reader

**Stärken:**
- **Einziger Anbieter mit E-Reader-Unterstützung** (PocketBook) — leicht, wetterfest, outdoor-tauglich
- Spezifisch für Blasmusik entwickelt — über 10.000 Stücke mit bis zu 50 Stimmen
- Stimmenverteilung an Mitglieder mit Echtzeit-Stimmenwechsel
- Dirigenten-Masterfunktion (gleichzeitiges Umblättern für alle)
- Offline-Modus für Auftritte
- Termin- und Probenverwaltung mit Zu-/Absagen
- Notenarchiv mit großem Bestand

**Schwächen:**
- Notenbibliothek enthält nicht immer vereinsspezifische Arrangements
- Account-/Support-Probleme laut einigen Nutzerbewertungen (3,7/5 App Store)
- E-Reader-Hardware kostet extra
- Keine AI-basierte Metadaten-Erkennung beim Upload eigener Noten
- Keine Annotation auf dem Notenblatt
- Keine mehrstufigen Annotationsebenen
- Kein Lehre-Modul
- Keine Schichtplanung für Feste

**Preise:** Freemium (stark eingeschränkt), Premium 97€/Jahr (Einzelmusiker), Gruppen ab 151€/Jahr (bis 5 Mitglieder), skaliert nach Gruppengröße

---

### 3.5 Notabl

**Website:** https://notabl.de
**Zielgruppe:** Musikvereine, Orchester, Chöre
**Plattformen:** Web, App

**Stärken:**
- All-in-One für Musikvereine: Notenverwaltung + Konzertplanung + Stimmenzuordnung
- Dynamische Stimmenzuweisung bei Ausfällen (ein Klick)
- Konzert-Zu-/Absagen direkt in der App
- Mitglieder nutzen die App kostenlos — Verein zahlt Grundgebühr
- DSGVO-konform, in Deutschland gehostet
- Intuitive Bedienung, überwiegend positive Nutzerbewertungen

**Schwächen:**
- **Keine leistungsfähige Notenanzeige-Engine** (kein PDF-Viewer mit Annotationen, Cropping, Auto-Zoom)
- Keine AI-basierte Upload-Unterstützung
- Keine persönliche Notensammlung (lokal/Cloud-Sync)
- Keine Multi-Kapellen-Zugehörigkeit
- Kein Stimmgerät, kein Metronom, keine Echtzeit-Sync-Tools
- Kein Lehre-Modul
- Preise nicht transparent auf der Website

**Preise:** Monatliche Grundgebühr für den Verein (auf Anfrage), kostenlos für Mitglieder

---

### 3.6 Glissandoo

**Website:** https://glissandoo.com
**Zielgruppe:** Musikvereine, Blasorchester, Chöre
**Plattformen:** iOS, Android, Web

**Stärken:**
- Gute Organisations-App: Proben, Auftritte, Anwesenheit, Kommunikation
- Notenverteilung nach Instrument/Stimmlage
- Cloud-Speicher für Noten (PDF, Audio, Video)
- Statistiken und Anwesenheitskontrolle
- Bis 20 Mitglieder kostenlos — niedrige Einstiegshürde
- Über 60.000 Nutzer und 400+ Musikgemeinschaften

**Schwächen:**
- **Kein dedizierter PDF-Viewer** mit Annotationen oder Performance-Modus
- Notenverteilung ist rudimentär (Datei-Upload, keine intelligente Stimmenzuordnung)
- Keine AI-Features
- Keine persönliche Notensammlung
- Keine Multi-Kapellen-Zugehörigkeit
- Kein Metronom, kein Stimmgerät
- Kein Lehre-Modul

**Preise:** Bis 20 Mitglieder kostenlos, darüber individuell (Tarif "Piano"), jederzeit kündbar

---

### 3.7 Musicorum

**Website:** https://musicorum.de
**Zielgruppe:** Musikvereine, Chöre, Orchester
**Plattformen:** iOS, Android, Web

**Stärken:**
- Fokussiert auf digitale Notenverwaltung und -verteilung
- Automatische Zuordnung der passenden Stimme an jedes Mitglied
- Noten-Weitergabe an Aushilfen per Link (ohne Registrierung)
- Alben für Konzerte zusammenstellen, PDF-Export
- Bewertungssystem für Stücke, Filtermöglichkeiten
- Import bestehender Archive (z.B. aus Excel)
- DSGVO-konform

**Schwächen:**
- **Kein integrierter Noten-Viewer** — verweist auf PiaScore/MobileSheets
- Keine Annotations-Features
- Keine Vereinsverwaltungs-Features (Termine, Events)
- Keine AI-basierte Erkennung
- Kein Metronom, kein Stimmgerät
- Kein Lehre-Modul

**Preise:** Demo (kostenlos, eingeschränkt), Basis (Abo, monatlich kündbar), Unlimited (Abo, unbegrenzt) — genaue Preise auf Anfrage

---

### 3.8 SoftNote Web

**Website:** https://www.softnote.de
**Zielgruppe:** Musikvereine, Musikschulen
**Plattformen:** Web (plattformunabhängig)

**Stärken:**
- Reines Notenarchiv mit professioneller Archivierung
- Benutzer- und Rechteverwaltung (Admin, Dirigent, Registerführer)
- Mandantenfähig (mehrere Gruppen/Vereine)
- Unbegrenzte Nutzer und Datensätze
- Online-Suche mit Import-Funktion
- DSGVO-konform, günstig

**Schwächen:**
- **Reine Katalogsoftware** — kein PDF-Viewer, keine Notenanzeige
- Keine mobile App
- Keine Verteilung von Noten an Musiker
- Keine Annotationen
- Keine Vereins-Features
- Keine AI-Features

**Preise:** 39,95€/Jahr (Web), Desktop-Lizenz 49,95€ (Einmalkauf)

---

### 3.9 Konzertmeister

**Website:** https://konzertmeister.app
**Zielgruppe:** Musikvereine, Blaskapellen, Chöre
**Plattformen:** iOS, Android, Web

**Stärken:**
- **Exzellente Vereinsorganisation** zum günstigen Preis
- Terminplanung mit Zu-/Absagen und Erinnerungen
- Gruppen- und Rollensystem (Register, Funktionen)
- Push-Benachrichtigungen, Nachrichten, Pinnwand
- Setlist-/Musikstückverwaltung
- Umfragen und Aufgabenverwaltung
- Kalender-Sync (Google, Apple, Outlook)
- DSGVO-konform, Basic-Version kostenlos

**Schwächen:**
- **Keine Notenanzeige** — keine PDFs, keine Annotationen
- Keine Notenverteilung an Musiker
- Keine AI-Features
- Kein Metronom, kein Stimmgerät
- Kein Lehre-Modul
- Begrenzter Online-Speicher

**Preise:** Basic (kostenlos, bis 30 Mitglieder), Pro 30 (33€/J), Pro 60 (66€/J), Pro unlimited (99€/J)

---

### 3.10 BNote (Open Source)

**Website:** https://bnote.info / https://github.com/mattimaier/bnote
**Zielgruppe:** Ensembles, Orchester, Musikschulen
**Plattformen:** Web (Self-Hosted)

**Stärken:**
- **Open Source (GPLv3)** — kostenlos, frei anpassbar
- Umfangreiche Ensembleverwaltung: Proben, Auftritte, Repertoire, Kontakte
- Aufgabenverwaltung, Umfragen, Abstimmungen
- Datei-/Notenaustausch mit Cloud-Ordnerstruktur
- Kalender-Integration (ICS), Datenexport (CSV, vCard)
- API (JSON) für eigene Erweiterungen
- Datenschutz: Mitglieder steuern eigene Daten

**Schwächen:**
- **Erfordert eigenen Webserver** — technische Hürde für Vereine
- Keine Notenanzeige, keine Annotationen
- Veraltete UI, nicht mobile-optimiert
- Keine AI-Features
- Keine automatische Stimmenverteilung
- Keine Echtzeit-Features

**Preise:** Kostenlos (Open Source)

---

### 3.11 Vereinsverwaltungs-Software (easyVerein, Vereinsplaner, ClubDesk, ComMusic)

Diese Tools sind **allgemeine Vereinsverwaltungsplattformen**, teilweise mit Musikverein-Erweiterungen.

| Merkmal | easyVerein | Vereinsplaner | ClubDesk | ComMusic |
|---------|-----------|---------------|----------|----------|
| **URL** | easyverein.com | vereinsplaner.at | clubdesk.de | commusic.de |
| **Mitgliederverwaltung** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Terminplanung** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Finanzverwaltung** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Notenmanagement** | ⭐ (Archiv) | ❌ | ❌ | ⭐⭐ (Archiv) |
| **Notenanzeige** | ❌ | ❌ | ❌ | ❌ |
| **Musik-Features** | ⭐⭐ | ⭐⭐ | ⭐ | ⭐⭐⭐ |
| **DSGVO** | ✅ | ✅ | ✅ | ✅ |
| **Plattformen** | Web | Web + App | Web | Desktop + Web |

**Gemeinsame Schwäche:** Keine dieser Lösungen bietet eine echte digitale Notenanzeige, Annotationen, AI-Features oder spezifische Musikfunktionen wie Stimmgerät oder Metronom.

---

### 3.12 Socie

**Website:** https://socie.de
**Zielgruppe:** Vereine aller Art (auch Musikvereine)
**Plattformen:** iOS, Android, Web

**Stärken:**
- Sehr flexible Vereins-App mit modularem Aufbau
- Kommunikation, Kalender, Gruppen, Umfragen, Aufgaben
- Datei-Austausch (auch Noten), Fotoalben
- Crowdfunding/Sponsoring-Modul
- White-Label-Option (eigene App im Store)
- Basis-Version kostenlos, unbegrenzte Mitglieder

**Schwächen:**
- Nicht musikspezifisch — keine Stimmenlogik, keine Noten-Features
- Keine Notenanzeige
- Plus-Paket relativ teuer (37,50€/Monat)
- Premium/White-Label sehr teuer (350€/Monat + 1.000€ Einrichtung)

**Preise:** Kostenlos (Basis), Plus 37,50€/Monat, Premium 350€/Monat

---

### 3.13 WePlayIn.Band

**Website:** https://weplayin.band
**Zielgruppe:** Orchester, Bands, Ensembles
**Plattformen:** iOS, Android, Web

**Stärken:**
- Ganzheitliches Orchester-Management mit modernem UI
- AI-Assistent für Sprach-gesteuerte Verwaltung
- Echtzeit-Anwesenheitstracking nach Sektionen
- Repertoire-Management mit Notenfreigabe
- Analytics-Dashboard mit Teilnahme- und Lückenanalyse
- Konzertprogramm-Planung mit Setlists
- PDF-Export für Berichte
- Kalender-Sync

**Schwächen:**
- Kein vollwertiger Noten-Viewer mit Annotationen
- Keine AI-basierte Noten-Erkennung
- Keine persönliche Notensammlung
- Relativ neuer Anbieter — wenig Community/Review-Daten
- Keine Echtzeit-Metronom-Synchronisation
- Kein Lehre-Modul

**Preise:** Community Edition (günstig/kostenlos), Details auf Website

---

### 3.14 Setlist- & Band-Management-Tools

| Tool | Plattformen | Besonderheiten | Schwächen für unseren Use Case |
|------|-------------|---------------|-------------------------------|
| **Bandhelper** | iOS/Android/Mac/Win | All-in-One mit MIDI, Lighting, Chat | Abo-basiert, komplex, kein Vereinsfokus |
| **OnSong** | iOS/Mac | MIDI-Steuerung, Transposition live | Nur Apple, kein Vereinsmanagement |
| **BandPlanr** | iOS/Android/Web | Modern, Annotation, Live-Modus | Noch in Early Access, kein Vereinsfokus |
| **SetlistHelper** | iOS/Android/Web | Echtzeit-Sync, Offline | Kein Notenmanagement |
| **Setflow** | Web | Echtzeit-Kollaboration, Dark Mode | Kein Notenmanagement, kein MIDI |

**Gemeinsame Schwäche:** Alle fokussieren auf Bands/Live-Performance, nicht auf Blaskapellen-Vereinsstruktur mit Stimmenverteilung.

---

### 3.15 Lehre-Plattformen

| Tool | Plattformen | Stärken | Schwächen für unseren Use Case |
|------|-------------|---------|-------------------------------|
| **Flat for Education** | Web | Kollaborative Komposition, Google Classroom Integration | Keine Vereinsintegration, keine PDF-Noten |
| **Tonara** | iOS/Android/Web | Praxistracking, AI-Feedback, Lehrer-Marktplatz | Keine Vereinsanbindung |
| **Noteflight Learn** | Web | 1M+ Partituren, Auto-Bewertung | Nur für Bildungseinrichtungen |
| **Solfeg.io** | Web | Step-by-Step Instrumentenlernen | Fokus auf Anfänger |
| **Tomplay** | Alle | Interaktive Begleitspuren, großer Katalog | Kein Lehrer-Schüler-Workflow im Vereinskontext |

**Gemeinsame Schwäche:** Keine dieser Plattformen lässt sich mit einer Vereinsstruktur verbinden. Die Lehrer-Schüler-Beziehung besteht isoliert, ohne Bezug zu einer Kapelle.

---

### 3.16 Echtzeit-Metronom & Synchronisation

| Tool | Plattformen | Funktionsweise | Einschränkungen |
|------|-------------|---------------|-----------------|
| **BeatSynQ** | iOS/Android/Desktop | Host-Room-Modell, Echtzeit-Sync, HD-Audio | Noch Beta, fehlende Integration |
| **Connect Metronome** | iOS/Android | QR-Code-Join, ms-genaue Sync | Standalone, keine Notenintegration |
| **METRO X** | iOS | Visueller Rhythmus, Patent-Sync | Nur iOS |
| **EnsembleX** | Web/Desktop/Mobile | Mikrosekunden-Sync, Sektionsmanagement | Separates Tool, keine Noten |

**Gemeinsame Schwäche:** Alle sind eigenständige Tools ohne Integration in eine Noten- oder Vereinsplattform.

---

## 4. Gap-Analyse — Marktlücken

### 4.1 Kritische Lücken (kein Anbieter deckt dies ab)

| Lücke | Beschreibung | Marktrelevanz |
|-------|-------------|:-------------:|
| **Intelligentes Stimmen-Mapping** | Automatische Zuordnung der richtigen Stimme basierend auf Instrumentenprofil mit Fallback-Logik (z.B. "2. Klarinette" → "Klarinette" → "1. Klarinette") | 🔴 Sehr hoch |
| **AI-gestützter Upload mit Labeling** | Mehrere Lieder in einem Upload erkennen, automatisch separieren, Metadaten (Titel, Komponist, Stimme) via AI/OCR extrahieren | 🔴 Sehr hoch |
| **Mehrstufige Annotations-Sichtbarkeit** | Drei Ebenen: Privat → Stimmen-Sync → Orchesterweit (Dirigenten-Anweisungen). Newzik kommt am nächsten, hat aber kein Drei-Stufen-Modell | 🟡 Hoch |
| **Vereinsleben + Noten in einer App** | Konzertplanung, Schichtplanung für Feste, Zu-/Absagen UND gleichzeitig leistungsfähige Notenanzeige mit Annotations | 🔴 Sehr hoch |
| **Multi-Kapellen-Zugehörigkeit** | Ein Musiker gehört mehreren Kapellen an, jede mit eigenen Noten und Setlists. Keine bestehende App unterstützt dies nativ | 🟡 Hoch |
| **Integriertes Lehre-Modul im Vereinskontext** | Lehrer-Schüler-Beziehung MIT Bezug zur Kapelle: Noten freischalten, Lernpfade erstellen, Fortschritt verfolgen | 🟡 Hoch |
| **Echtzeit-Klick im Notenkontext** | Synchronisiertes Metronom/Klick direkt beim Notenblatt, nicht als separates Tool | 🟡 Hoch |
| **BYOK für AI-Dienste** | Eigene AI-API-Keys pro Nutzer oder pro Kapelle hinterlegen — kein Anbieter erlaubt dies | 🟢 Mittel |

### 4.2 Teilweise gedeckte Bereiche (Verbesserungspotenzial)

| Bereich | Aktuelle Abdeckung | Verbesserungspotenzial |
|---------|-------------------|----------------------|
| **Auto-Rotation/Auto-Zoom** | forScore, MobileSheets bieten Cropping/Zoom, aber keine intelligente Erkennung von Notenlinien für automatische Drehung | AI-basierte Rotation an Notenlinien ausrichten |
| **Persönliche Notensammlung** | forScore, MobileSheets erlauben individuelle Sammlungen, aber ohne Cloud-Sync über Dienste wie OneDrive/Dropbox | Integration mit verschiedenen Cloud-Anbietern |
| **Rollenbasierte Berechtigungen** | Notabl, Konzertmeister haben Rollen, aber keine feingranulare Konfiguration (Notenwart, Registerführer als dedizierte Rollen) | Differenzierteres Rollensystem |
| **Stimmgerät/Metronom** | forScore, Newzik haben eingebaute Tools, aber ohne Ensemble-Sync | Integration mit Echtzeit-Sync |

### 4.3 Nicht adressierte Nischen

1. **Schichtplanung für Vereinsfeste:** Keine Noten-App oder Musik-Vereinsapp bietet Arbeitsdienst-/Schichtplanung.
2. **Kamera-Upload mit sofortiger AI-Verarbeitung:** Marschpat und Musicorum erlauben Upload, aber keine Echtzeit-AI-Erkennung von mehreren Liedern in einem Scan.
3. **Persönliche Notensammlung als "eigene Kapelle":** Konzeptioneller Ansatz, der die gleiche Mechanik wie Kapellen-Noten nutzt — existiert nirgendwo.

---

## 5. Chancen für unsere App

### 5.1 Strategische Positionierung

Unsere App positioniert sich als **einzige Lösung, die die Brücke schlägt zwischen**:
- **Professioneller Notenanzeige** (Niveau forScore/MobileSheets)
- **Intelligenter Vereinsverwaltung** (Niveau Konzertmeister/Notabl)
- **Blasmusik-spezifischer Stimmenverwaltung** (Niveau Marschpat, aber besser)
- **Modernen AI-Features** (kein Vergleichsprodukt am Markt)
- **Lehre-Integration** (kein Vergleichsprodukt im Vereinskontext)

### 5.2 Differenzierungsfaktoren (einzigartige Alleinstellungsmerkmale)

1. **AI-gestützter Noten-Upload mit Multi-Lied-Labeling**
   - Kein Wettbewerber bietet einen Workflow, bei dem mehrere Lieder aus einem Upload/Scan automatisch erkannt, separiert und mit Metadaten versehen werden.
   - Die BYOK-Option (eigene API-Keys) ist ein Novum im Markt.

2. **Intelligentes Stimmen-Mapping mit Fallback**
   - Die Kombination aus Instrumentenprofil, Standardstimme und automatischer Fallback-Logik existiert bei keinem Wettbewerber.

3. **Drei-Ebenen-Annotationen**
   - Während Newzik und BlackBinder Annotation-Layers unterstützen, bietet kein Wettbewerber die explizite Dreistufigkeit (Privat → Stimme → Orchester) als Kernkonzept.

4. **Vereinsleben + Noten = ein Produkt**
   - Aktuell müssen Kapellen mindestens 2-3 verschiedene Apps kombinieren (z.B. Konzertmeister + MobileSheets + WhatsApp). Unsere App ist die All-in-One-Lösung.

5. **Multi-Kapellen-Support**
   - Kein Wettbewerber erlaubt die nahtlose Zugehörigkeit zu mehreren Kapellen mit separaten Notenbeständen.

6. **Echtzeit-Metronom im Notenkontext**
   - Existierende Sync-Metronome (BeatSynQ, Connect Metronome) sind eigenständige Apps. Die Integration in die Notenanzeige ist ein starker Differenzierer.

### 5.3 Empfohlene Prioritäten (Feature-Priorisierung)

| Priorität | Feature | Begründung |
|:---------:|---------|-----------|
| **P0** | Zentrale Notenverwaltung mit Stimmenverteilung | Kernproblem jeder Kapelle, größte Marktlücke |
| **P0** | Leistungsfähiger PDF-Viewer mit Annotationen | Muss mindestens so gut sein wie MobileSheets |
| **P0** | Setlist-Verwaltung | Standardfeature, Tischeinsatz bei jedem Auftritt |
| **P1** | AI-gestützter Upload mit Labeling | Stärkstes Differenzierungsmerkmal, aber technisch komplex |
| **P1** | Konzertplanung mit Zu-/Absagen | Pain Point für jeden Vereinsvorstand |
| **P1** | Multi-Kapellen-Zugehörigkeit | Häufiges Bedürfnis, null Konkurrenz |
| **P2** | Mehrstufige Annotationen | Differenzierer, aber nicht Day-One-Feature |
| **P2** | Auto-Rotation/Auto-Zoom | Nice-to-have, kein existierendes Produkt bietet AI-basierte Version |
| **P2** | Persönliche Notensammlung | Wichtig, aber nach Kern-Features |
| **P2** | Rollen & Berechtigungen (granular) | Notwendig ab gewisser Nutzerbasis |
| **P3** | Stimmgerät & Metronom | Commodity-Feature, schnell umsetzbar |
| **P3** | Schichtplanung für Feste | Nischen-Feature, aber keine Konkurrenz |
| **P3** | Echtzeit-Klick mit Sync | Technisch anspruchsvoll, aber starker Differenzierer |
| **P3** | Lehre-Modul | Erweiterung der Zielgruppe, nach Kern-Launch |

### 5.4 Risiken und Herausforderungen

| Risiko | Beschreibung | Mitigation |
|--------|-------------|-----------|
| **Feature Creep** | Breites Featureset kann zu langer Entwicklungszeit führen | MVP fokussieren auf P0-Features |
| **Plattform-Fragmentierung** | Kapellenmitglieder nutzen iOS, Android und Web gemischt | Cross-Platform von Anfang an planen (z.B. Flutter, React Native, oder Web-first) |
| **Marschpat als Incumbent** | Stärkster Wettbewerber im deutschsprachigen Blasmusik-Segment | Durch AI-Features und bessere Vereinsintegration differenzieren |
| **Noten-Copyright** | Eigene Noten-Uploads werfen rechtliche Fragen auf | Nur eigene/gekaufte Noten erlauben, keine Verbreitung |
| **AI-Kosten** | AI-Features (OCR, Vision) verursachen laufende Kosten | BYOK-Modell transferiert Kosten an Nutzer/Verein |

---

## 6. Anhang

### 6.1 Recherche-Quellen

- https://forscore.co
- https://zubersoft.com/mobilesheets/
- https://newzik.com
- https://www.marschpat.com
- https://notabl.de
- https://glissandoo.com
- https://musicorum.de
- https://www.softnote.de
- https://konzertmeister.app
- https://bnote.info
- https://socie.de
- https://easyverein.com
- https://vereinsplaner.at
- https://www.clubdesk.de
- https://www.commusic.de
- https://weplayin.band
- https://bandhelper.com
- https://onsongapp.com
- https://bandplanr.com
- https://flat.io/edu
- https://www.tonara.com
- https://www.noteflight.com
- https://tomplay.com
- https://beatsynq.com
- https://connect-metronome.chordoncode.com
- https://metrox.app
- https://ensemble-x.net
- https://www.blackbinder.net
- https://maestroamadeus.com
- https://forte-zeitschrift.de/2025/05/digitale-hilfe-im-musikverein/
- https://www.softwareabc24.de/verein-software/software-fuer-musikvereine
- https://quaver.ch/best-sheet-music-apps/
- https://www.tablets-for-musicians.com/best-sheet-music-apps/

### 6.2 Methodik

Die Analyse basiert auf umfangreichen Webrecherchen (deutsch- und englischsprachig) in folgenden Kategorien:
1. Sheet Music Management Apps
2. Blaskapelle/Musikverein-spezifische Software
3. Allgemeine Vereinsverwaltung
4. Digitales Notenpult / Sheet Music Display
5. Annotation-Tools
6. Setlist-Management
7. Musik-Lehre-Plattformen
8. AI/OCR für Notenblatt-Erkennung
9. Echtzeit-Metronom-Synchronisation

Für jeden Wettbewerber wurden offizielle Websites, App-Store-Bewertungen, Fachmagazin-Reviews und Vergleichsportale ausgewertet.

---

*Dieses Dokument dient als Grundlage für Architektur- und Designentscheidungen des Teams.*
