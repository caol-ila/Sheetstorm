# Marktanalyse — Notenmanagement & Vereinsverwaltung für Blaskapellen

> **Erstellt:** 2026-03-28  
> **Aktualisiert:** 2026-03-28 (v2 — vollständige Neuerstellung mit erweiterter Recherche)  
> **Autor:** Fury (Business Analyst)  
> **Quelle:** 15+ Web-Recherchen, deutsch- und englischsprachig, Daten aus 2024/2025

---

## Executive Summary

Der Markt für digitale Notenverwaltung und Musikgruppen-Management ist **fragmentiert und reif für eine All-in-One-Lösung**. Kein einziges Produkt auf dem Markt kombiniert professionelle Notenanzeige, Blasmusik-spezifisches Stimmen-Mapping, AI-gestützten Upload und Vereinsverwaltung in einem Produkt.

**Die wichtigsten Erkenntnisse:**

1. **Zwei getrennte Märkte** existieren nebeneinander: Notenanzeige-Apps (forScore, MobileSheets, Newzik) und Vereinsverwaltungs-Apps (Konzertmeister, Glissandoo, BAND). Kein Produkt verbindet beides überzeugend.
2. **DACH-Markt ist unterversorgt**: Blasmusik-spezifische Apps (Marschpat, notabl) existieren, aber mit erheblichen Feature-Lücken — kein AI-Upload, keine erweiterten Annotationen, begrenzte Plattformunterstützung.
3. **AI/OCR für Notenerkennung** ist ein heißes Thema (Newzik LiveScore, PlayScore, Scan2Notes), aber noch kein Anbieter integriert das direkt in ein Blaskapellen-Verwaltungssystem.
4. **Preismodelle sind heterogen**: Einmalkauf (forScore: $24,99; MobileSheets: $15,99) vs. Abo (Konzertmeister: ab 33€/Jahr, Marschpat: 97€/Jahr Individual) — Nutzer im DACH-Raum schätzen Transparenz und günstige Vereinsmodelle.
5. **Sheetstorm-Chance**: Die Kombination aus Stimmen-Mapping, Drei-Ebenen-Annotationen, AI-Upload und Vereinsleben ist am Markt einzigartig.

---

## 1. Marktübersicht — Wettbewerber-Tabelle

### 1.1 Kategorie: Notenblatt-Reader (Einzelmusiker-Fokus)

| App | URL | Plattformen | Zielgruppe | Preis | Stärken | Schwächen |
|-----|-----|------------|-----------|-------|---------|----------|
| **forScore** | forscore.co | iOS, macOS, visionOS | Solo-Musiker, Professionals | $24,99 Einmalkauf + $9,99/Jahr Pro | Goldstandard Annotation, Apple Pencil, Reflow-Modus, Setlists, forScore 15 neu 2025 | Kein Android, kein Ensemble-Management, kein Upload-Labeling |
| **MobileSheets** | zubersoft.com | Android, Windows, iOS | Musiker aller Art, Ensembles | $15,99 Einmalkauf | Cross-Platform, Wifi-Sync zwischen Tablets, 20 Metadaten-Felder, Half-Page-Turn, MIDI | Kein eigenes Notenarchiv, UI komplex für Einsteiger |
| **Newzik** | newzik.com | iOS, Web | Ensembles, Orchester, Schulen | Freemium; Premium ~$49-179/Jahr; Ensemble: auf Anfrage | LiveScore AI (PDF→interaktiv), Echtzeit-Kollaboration, Web+App, IMSLP-Integration | Kein Android, Ensemble-Preise intransparent, kein Vereins-Management |
| **neoScores** | neoscores.com | Web, iPad, Android (teils) | Professionelle Orchester | Professionell, auf Anfrage | Orchesterfokus, zentrale Score-Verwaltung | Weniger für Laienvereine, eingeschränkte Windows-Kompatibilität |
| **OnSong** | onsongapp.com | iOS, Mac | Bands, Worship-Teams | $2,50-5,00/Monat (Abo) | Chord Charts, Transposition, Setlist-Sharing, OCR-Scanner | iOS only, eher für Chord-Chart-Musiker als klassische Noten |
| **Planning Center Music Stand** | planningcenter.com | iOS, Android | Worship-Teams, Kirchen | Ab $14/Monat + Add-on | Tighte Integration, Team-Scheduling | Erfordert Planning Center Abo, kein Key-Change live |

### 1.2 Kategorie: Blasmusik-Spezialisten (DACH-Markt)

| App | URL | Plattformen | Zielgruppe | Preis | Stärken | Schwächen |
|-----|-----|------------|-----------|-------|---------|----------|
| **Marschpat** | marschpat.com | iOS, Android, Web, E-Reader | Blaskapellen, Musikvereine | Freemium; Individual: 97€/Jahr; Gruppe ab 151€/Jahr | Blasmusik-Bibliothek (500+ Stücke), E-Reader-Integration, Offline, Dirigenten-Masterfunktion, Stimmen-Auswahl | Keine Drei-Ebenen-Annotationen, kein AI-Upload, begrenzte Vereinsverwaltung |
| **notabl** | notabl.de | iOS, Android, Web | Musikvereine, Orchester | Kostenlos für Mitglieder, Vereinsgebühr auf Anfrage | Digitale Konzertmappe, 1-Klick Notenausgabe, Konzertplanung, Mitglieder zahlen nichts | Preis intransparent, keine AI-Features, limitierte Annotationen |
| **Glissandoo** | glissandoo.com | iOS, Android, Web | Musikvereine, Ensembles | Bis 20 Mitglieder kostenlos; Größere Gruppen auf Anfrage | Terminplanung, Kommunikation, Repertoire-Sharing, Register-Kommunikation | Keine professionelle Notenanzeige, kein AI-Upload |
| **BNote** | bnote.info | Web (Self-hosted) | Tech-affine Musikvereine | Open Source (GPLv3), kostenlos | DSGVO durch Selbst-Hosting, vollständige Kontrolle, Mitgliederverwaltung | Technisches Know-how erforderlich, kein Mobile-App, veraltetes UI |

### 1.3 Kategorie: Vereinsverwaltung (Allgemein + Musikverein)

| App | URL | Plattformen | Zielgruppe | Preis | Stärken | Schwächen |
|-----|-----|------------|-----------|-------|---------|----------|
| **Konzertmeister** | konzertmeister.app | iOS, Android, Web | Musikvereine, Chöre, Blaskapellen | Gratis bis 30; Pro 33-99€/Jahr; +Speicher extra | Terminverwaltung, Zu-/Absagen, Chat, DSGVO DE/AT-Server, Register-Gruppen | Notenverwaltung begrenzt, nachträgliche Metadaten-Bearbeitung schwierig |
| **Vereinsplaner** | vereinsplaner.com | iOS, Android, Web | Vereine aller Art | Bis 25 Mitglieder kostenlos; 10-22€/Monat | Finanzverwaltung, SEPA, Inventar, Mitgliederverwaltung | Kein Notenmanagement, nicht Musik-spezifisch |
| **BAND** | band.us | iOS, Android, Web | Alle Gruppen, Bands | Kostenlos (werbefinanziert) | Kostenlos, Kalender, Datei-Sharing, unbegrenzte Gruppen, Privacy-fokus | Kein Notenmanagement, kein Stimmenzuweisung, keine Vereinsstruktur |

### 1.4 Kategorie: AI/OCR Noten-Erkennung (als potenzielle Integration)

| Tool | URL | Stärken | Integration-Potenzial für Sheetstorm |
|------|-----|---------|--------------------------------------|
| **Newzik LiveScore** | newzik.com | PDF→interaktive Noten, Transposition, MIDI-Export | Vorbild für Konvertierung, aber kein reines Upload-Tool |
| **PlayScore 2** | playscore.co | Mobile-first, Foto→Playback, MusicXML, iOS+Android | Upload-Funktion für Fotos denkbar |
| **Scan2Notes (Klangio)** | klang.io | Sehr hohe Genauigkeit, Multi-Instrument, Web-API | API-Integration für AI-Upload |
| **ScanScore** | scan-score.com | Desktop, hochpräzise, MIDI/XML/Audio Export | Desktop-Ergänzung |
| **Azure AI Vision** | microsoft.com | OCR, Bildverarbeitung, Vision API | Direktintegration über BYOK-Modell |

### 1.5 Kategorie: Setlist-Management

| App | URL | Besonderheit | Relevanz für Sheetstorm |
|-----|-----|-------------|------------------------|
| **setlist.fm** | setlist.fm | 9M+ öffentliche Setlists, Community-Wiki | Inspirationsquelle für öffentliche Repertoire-Datenbank |
| **Setlist Helper** | setlisthelper.com | Band-Setlists, Drucken, Sharing | Einfaches Vorbild |
| **GigBook** | — | Setlists + Notenverwaltung kombiniert | Relevantes Vorbild |

---

## 2. Detailanalyse: Die wichtigsten Wettbewerber

### 2.1 forScore (Goldstandard Notenanzeige)

**Steckbrief:** forScore ist die meistgenutzte Noten-App im Apple-Ökosystem. Version 15 (2025) brachte Grid-View, überarbeitete Navigation, erweitertes MIDI und Tempo-Editing direkt in Metadaten. Apple Pencil-Integration gilt als Industriestandard.

**Kernstärken:**
- Performance-Modus: UI verschwindet vollständig, nur Seitenwechsel aktiv
- Annotation-Layer: Multiple Ebenen, individuell ein-/ausblendbar
- Half-Page-Turn: untere Hälfte der nächsten Seite vorblenden
- Setlists mit nahtlosem Übergang zwischen Stücken
- iCloud-Sync + lokale Speicherung

**Schwächen (Chancen für Sheetstorm):**
- ❌ Kein Android
- ❌ Kein Ensemble-/Vereinsmanagement
- ❌ Kein Stimmen-Mapping für Gruppen
- ❌ Kein AI-gestützter Multi-Seiten-Upload mit Labeling
- ❌ Keine Drei-Ebenen-Annotationen (Privat/Stimme/Orchester)
- ❌ Kein Echtzeit-Metronom-Sync

**Preis:** $24,99 Einmalkauf + optional $9,99/Jahr Pro  
**Plattformen:** iOS, macOS, visionOS

---

### 2.2 MobileSheets (Cross-Platform Veteran)

**Steckbrief:** MobileSheets ist der forScore-Konkurrent für Android und Windows. Breite Gerätekompatiblität, tiefe Konfigurierbarkeit, keine Abo-Pflicht.

**Kernstärken:**
- Android + Windows (+ neuerdings iOS)
- WiFi/Bluetooth-Sync zwischen Tablets (Ensemble-Nutzung)
- Half-Page-Turn, Horizontal-/Vertikal-Scroll, Side-by-Side
- 20 Metadaten-Felder, CSV-Batch-Import
- Bluetooth-Pedal-Support, Facial Gesture Page Turn (Android)
- MIDI-Unterstützung

**Schwächen:**
- ❌ Kein Vereins-/Ensemble-Management
- ❌ Kein AI-Upload oder Labeling-Prozess
- ❌ Keine Stimmen-Verteilung für Kapellen
- ❌ UI-Komplexität: Steile Lernkurve
- ❌ Keine Echtzeit-Synchronisation (nur Gerät-zu-Gerät Sync)

**Preis:** $15,99 Einmalkauf (Android + Windows separat)  
**Plattformen:** Android, Windows, iOS

---

### 2.3 Newzik (Ensemble-Kollaboration)

**Steckbrief:** Newzik ist die ausgefeilteste Ensemble-Lösung. LiveScore AI konvertiert PDFs in interaktive, transponierbare Noten. Fokus auf professionelle Orchester und Schulen.

**Kernstärken:**
- LiveScore AI: PDF → interaktiv spielbar, transponierbar, MIDI-Export
- Echtzeit-Annotation-Sync im Ensemble
- Web-Interface für Bibliotheksverwaltung, App für Performance
- IMSLP-Integration (public domain Noten direkt importieren)
- Projekte & Setlists mit Berechtigungssystem

**Schwächen:**
- ❌ Kein Android (iOS + Web only)
- ❌ Ensemble-Preise intransparent, auf Anfrage
- ❌ Kein dediziertes Blaskapellen-Stimmen-Mapping
- ❌ Kein Vereinsleben-Modul (Konzertplanung, Schichtplanung)
- ❌ Keine Multi-Kapellen-Zugehörigkeit
- ❌ Kein Echtzeit-Metronom

**Preis:** Freemium; Premium $49-179/Jahr; Ensemble auf Anfrage  
**Plattformen:** iOS, Web

---

### 2.4 Konzertmeister (Vereins-Champion DACH)

**Steckbrief:** Die beliebteste App für Musikvereine und Blaskapellen im DACH-Raum. Speziell für Proben-, Termin- und Mitgliederverwaltung.

**Kernstärken:**
- Zu-/Absage-System mit Live-Übersicht
- Register-/Gruppen-Management
- Chat, Pinnwand, Umfragen, Aufgaben-Verteilung
- DSGVO-konform (Server DE/AT)
- Kalender-Integration (ICS)
- Statistiken und Anwesenheits-Tracking

**Schwächen:**
- ❌ Keine professionelle Notenanzeige (PDF-Viewer rudimentär)
- ❌ Kein Stimmen-Mapping mit Fallback-Logik
- ❌ Keine Annotationen in Noten
- ❌ Kein AI-Upload
- ❌ Externer Speicher kostet extra (100MB free, dann 10-40€/Jahr)
- ❌ Kein Bluetooth-Pedal-Support, kein Performance-Modus

**Preis:** Gratis bis 30 Mitglieder; Pro: 33-99€/Jahr; Speicher extra  
**Plattformen:** iOS, Android, Web

---

### 2.5 Marschpat (Blasmusik-Spezialist DACH)

**Steckbrief:** Der direkteste Konkurrent im Blasmusik-Segment. Fokus auf digitale Marschnotenmappe mit E-Reader-Integration für den Außeneinsatz.

**Kernstärken:**
- Verlagsnoten-Bibliothek (500+ Blasmusikstücke, mit Stimmen)
- E-Reader-Integration (PocketBook) für Sonnenschein/Outdoor
- Offline-Funktionalität
- Dirigenten-Masterfunktion (zentrales Umblättern)
- Stimmenauswahl pro Instrument
- Web-Portal + Mobile Apps

**Schwächen:**
- ❌ Kein AI-Upload / Labeling-Prozess
- ❌ Keine Drei-Ebenen-Annotationen
- ❌ Vereinsverwaltung nur rudimentär
- ❌ Kein Echtzeit-Metronom
- ❌ Keine automatische Fallback-Logik bei fehlenden Stimmen
- ❌ Preismodell komplex (Stimmen-Pools, Hardware separat)

**Preis:** Individual: 97€/Jahr; Gruppe: ab 151€/Jahr; Hardware extra  
**Plattformen:** iOS, Android, Web, E-Reader (PocketBook)

---

### 2.6 notabl (Aufsteiger Vereinsmanagement + Noten)

**Steckbrief:** notabl.de positioniert sich als All-in-One für Musikvereine — Notenverwaltung + Konzertplanung. Kein Abo für Mitglieder.

**Kernstärken:**
- Digitale Konzertmappe mit Stimmenzuweisung
- 1-Klick Notenausgabe an Musiker
- Konzert- und Probenplanung integriert
- Mitglieder nutzen App kostenlos
- Notenpool zentral verwaltbar

**Schwächen:**
- ❌ Preis für Verein intransparent (auf Anfrage)
- ❌ Keine erweiterten Annotationen
- ❌ Kein AI-Upload
- ❌ Begrenzte Cross-Platform-Infos
- ❌ Kleineres Produkt, weniger ausgereift

**Preis:** Mitglieder kostenlos; Vereinslizenz auf Anfrage  
**Plattformen:** iOS, Android, Web

---

### 2.7 BAND App (Kommunikations-Allrounder)

**Steckbrief:** BAND ist eine kostenlose Gruppen-Kommunikationsplattform. Beliebt bei Bands, aber ohne Notenmanagement.

**Kernstärken:**
- Völlig kostenlos (werbefinanziert)
- Kalender, RSVP, Datei-Sharing, Chat, Live-Streaming
- Bis 200 Gruppen pro Nutzer, unbegrenzte Mitglieder
- Privacy-Fokus (keine Datenverkäufe)

**Schwächen:**
- ❌ Kein Notenmanagement
- ❌ Kein Stimmenzuweisung
- ❌ Keine Vereinsstruktur (Rollen, Berechtigungen)
- ❌ Navigation komplex bei großen Gruppen
- ❌ Keine DSGVO-Konformität nach EU-Standard

**Preis:** Kostenlos  
**Plattformen:** iOS, Android, Web

---

### 2.8 Glissandoo (Musikgruppen-Kommunikation)

**Steckbrief:** Glissandoo fokussiert auf Kommunikation und Terminplanung für Musikgruppen — einfacher als Konzertmeister, mit Repertoire-Sharing.

**Kernstärken:**
- Terminplanung mit Anwesenheitsvorschau
- Kommunikation nach Instrument/Stimme
- Repertoire-Verwaltung (Noten, Audio, Video)
- Bis 20 Mitglieder kostenlos

**Schwächen:**
- ❌ Kein professioneller PDF-Viewer
- ❌ Kein AI-Upload
- ❌ Keine erweiterten Annotationen
- ❌ Preise für größere Gruppen unklar

**Preis:** Bis 20 Mitglieder kostenlos; größere Gruppen auf Anfrage  
**Plattformen:** iOS, Android, Web

---

### 2.9 BNote (Open Source Alternative)

**Steckbrief:** BNote ist eine selbst gehostete Open-Source-Lösung (GPLv3) für Musikgruppen — kostenlos, aber technisches Know-how erforderlich.

**Kernstärken:**
- Kostenlos, DSGVO by design (Self-Hosting)
- Vollständige Mitglieder-, Noten- und Terminverwaltung
- GitHub-Community, aktive Entwicklung (Version 4.0.4, 2025)

**Schwächen:**
- ❌ Kein Mobile App
- ❌ Veraltetes UI
- ❌ Installation auf eigenem Server erforderlich
- ❌ Kein AI-Feature, kein moderner PDF-Viewer

**Preis:** Kostenlos (Open Source)  
**Plattformen:** Web (Self-Hosted)

---

### 2.10 Musicnotes (Noten-Marktplatz)

**Steckbrief:** Musicnotes ist ein Noten-Marktplatz mit 500.000+ lizenzierten Arrangements. Kein Ensemble-Tool, aber relevanter Wettbewerber für Noten-Beschaffung.

**Kernstärken:**
- Riesige Bibliothek (500.000+ Arrangements)
- Transposition, Annotation, Playback
- Interaktive App, Cross-Device-Sync

**Schwächen:**
- ❌ Pay-per-Song Modell ($2,99-$14,99)
- ❌ Kein Ensemble-Management
- ❌ Kein Upload eigener Noten als Kern-Feature
- ❌ Nicht für Blaskapellen optimiert

**Preis:** Pro Standard $14,99/Jahr; Pro Premium $49,99/Jahr  
**Plattformen:** iOS, Android, Web

---

## 3. Gap-Analyse: Was fehlt am Markt

### 3.1 Kritische Marktlücken (Sheetstorm-Chancen)

| Gap-Nr. | Beschreibung | Welcher Wettbewerber kommt am nächsten | Sheetstorm-Vorteil |
|---------|-------------|----------------------------------------|-------------------|
| **G1** | Professionelle Notenanzeige + Vereinsverwaltung in einer App | Kein einziges Produkt | Einzigartiges USP |
| **G2** | AI-gestützter Multi-Lied-Upload mit Labeling (Seiten zuordnen) | Newzik LiveScore (aber nur Konvertierung, kein Labeling) | Neues UX-Paradigma |
| **G3** | Intelligentes Stimmen-Mapping mit automatischer Fallback-Logik | Marschpat (rudimentär, kein Fallback) | Blasmusik-spezifisch |
| **G4** | Drei-Ebenen-Annotationen (Privat / Stimme / Orchester) | Newzik (2 Ebenen), forScore (1 Ebene) | Echter Differenzierer |
| **G5** | Multi-Kapellen-Zugehörigkeit für einzelne Musiker | Keiner | Aushilfen-Szenario gelöst |
| **G6** | Echtzeit-Metronom-Sync im musikalischen Kontext | Keiner | Innovativ, technisch anspruchsvoll |
| **G7** | BYOK (Bring Your Own Key) für AI-Dienste | Keiner | Datenschutz + Kostenkontrolle |
| **G8** | Lehre-Modul im Vereinskontext (Lehrer/Schüler + Lernpfade) | Keiner | Bildungs-Segment erschließen |
| **G9** | Schicht-/Festverwaltung im Musikverein | Keiner | Vereinsleben komplett abgedeckt |
| **G10** | Aushilfen-Zugang ohne Registrierung | Musicorum (rudimentär) | Pragmatisch, virales Potenzial |

### 3.2 Gut gelöste Features (Best-Practice übernehmen)

| Feature | Wer macht es am besten | Empfehlung für Sheetstorm |
|---------|----------------------|--------------------------|
| Performance-Modus (UI-Lockdown) | forScore | 1:1 übernehmen |
| Half-Page-Turn | forScore, Newzik | Day-1-Feature |
| Bluetooth-Pedal-Support | forScore, MobileSheets | Pflicht für Musiker |
| Zu-/Absage-System | Konzertmeister | Übernehmen + erweitern |
| Register-/Gruppen-Management | Konzertmeister | Übernehmen |
| Dirigenten-Masterfunktion | Marschpat | Übernehmen + Metronom-Sync hinzufügen |
| Web = Admin / App = Performance | Newzik | Architektur-Prinzip übernehmen |

---

## 4. Marktchancen & Positionierungsempfehlung

### 4.1 Primäre Zielgruppe

**Blaskapellen im DACH-Raum** (ca. 25.000 aktive Vereine in DACH, davon ~10.000 Blaskapellen):
- Derzeit zersplittert zwischen 2-3 verschiedenen Tools
- Bereit für eine dedizierte Lösung, wenn Preis-Leistung stimmt
- DSGVO-Konformität ist Pflicht

**Sekundäre Zielgruppe:** Andere Musikvereine (Chöre, Orchester, Big Bands)

### 4.2 Preismodell-Empfehlung

Basierend auf Marktanalyse empfehle ich folgendes Modell:

| Stufe | Beschreibung | Empfohlener Preis |
|-------|-------------|-----------------|
| **Free** | 1 Kapelle, bis 15 Mitglieder, begrenzte KI-Uploads | 0€ |
| **Starter** | 1 Kapelle, bis 40 Mitglieder, volle Features ohne AI | ~39€/Jahr/Kapelle |
| **Pro** | Unbegrenzte Mitglieder, AI-Upload inklusive, Priorität-Support | ~99€/Jahr/Kapelle |
| **Pro + AI** | Wie Pro + zentraler AI-Key für gesamte Kapelle | ~149€/Jahr/Kapelle |

**Begründung:** Konzertmeister (33-99€/Jahr) und Marschpat (97€+/Jahr) zeigen die Zahlungsbereitschaft. Sheetstorm kann durch mehr Wert (Notenanzeige + Verwaltung + AI) am oberen Ende positionieren.

### 4.3 Differenzierungsstrategie

**Sheetstorm positioniert sich als:**
> *Die erste App, die professionelle Notenanzeige, Blasmusik-spezifisches Stimmen-Management, AI-gestützten Upload und vollständiges Vereinsleben in einem Produkt vereint — DSGVO-konform, Cross-Platform, für DACH optimiert.*

**Hauptargument gegen jeden Wettbewerber:**

| Wettbewerber | Argument |
|-------------|---------|
| forScore | "Schön, aber nur Apple und kein Ensemble-Management" |
| Konzertmeister | "Gut für Organisation, aber die Noten zeigt es kaum vernünftig an" |
| Marschpat | "Blasmusik-Fokus gut, aber kein AI, keine Annotationen, keine Vereinsverwaltung" |
| notabl | "Richtiger Ansatz, aber Feature-Armut und intransparente Preise" |
| Glissandoo | "Kommunikation okay, aber kein Noten-Viewer" |
| BAND | "Kostenlos, aber auch entsprechend limitiert für Musikvereine" |

---

## 5. Fazit und Handlungsempfehlungen

### Sofort-Empfehlungen

1. **MVP priorisieren**: Zentrale Notenverwaltung + PDF-Viewer + Stimmen-Mapping ist das Kernversprechen. Ohne erstklassige Notenanzeige wird Sheetstorm nicht akzeptiert.
2. **DSGVO-Konformität von Tag 1**: Server in EU, DSGVO-Dokumentation. Kein Wettbewerbsvorteil, aber Pflicht.
3. **Cross-Platform von Tag 1**: Web + iOS + Android. forScore-Only-Nutzer kaufen kein Gerät, aber gemischte Kapellen brauchen alle Plattformen.
4. **AI-Upload als Leuchtturm-Feature**: Kein Konkurrent im Blasmusik-Segment bietet das. Starkes Marketing-Argument.
5. **Preismodell Vereins-orientiert**: Musiker zahlen nicht, Verein zahlt einmal — wie notabl. Adoption wird einfacher.

### Mittelfristig (nach MVP)

6. **Lehre-Modul**: Erschließt neues Segment (Musikschulen, Jugend-Orchester)
7. **Öffentliche Noten-Bibliothek**: IMSLP-Integration wie Newzik, oder eigene Blasmusik-Bibliothek
8. **Echtzeit-Metronom**: Technischer Differenzierer, gut für Marketing-Demos

---

*Nächste Schritte: UX-Benchmark gegen forScore und Konzertmeister (→ `docs/ux-research-konkurrenz.md`)*
