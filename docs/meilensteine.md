# Sheetstorm — Meilensteinplanung

> **Version:** 2.0  
> **Autor:** Stark (Lead / Architect)  
> **Datum:** 2026-03-28  
> **Status:** Zur Abstimmung via PR

---

## Übersicht

```
MS1 ──► MS2 ──► MS3 ──► MS5
  │              │
  └──────► MS4 ──┘
           (parallel möglich)
```

| Meilenstein | Titel | Abhängigkeit | Kernwert |
|:-----------:|-------|:------------:|----------|
| **MS1** | Import + Play Mode + Kapelle + Config | — | Noten hochladen, ansehen, spielen |
| **MS2** | Setlist + Konzertplanung + Vereinsleben | MS1 | Proben- und Konzertbetrieb organisieren |
| **MS3** | Tuner + Echtzeit-Klick + Cloud-Sync | MS1 | Musikalische Werkzeuge für die Probe |
| **MS4** | Lehre-Modul | MS1 | Musikunterricht digital unterstützen |
| **MS5** | Polish, Multi-Language, Advanced AI | MS2, MS3 | Feinschliff und Internationalisierung |

---

## MS1 — Import + Play Mode + Kapellenverwaltung + Konfiguration

### Scope

Das Fundament von Sheetstorm. Nach MS1 kann eine Kapelle gegründet, Noten hochgeladen, Stimmen zugewiesen und am Tablet gespielt werden. Die Konfiguration auf allen drei Ebenen (Kapelle/Nutzer/Gerät) ist funktional und hat eine erstklassige UX.

### Deliverables

#### Authentifizierung & Onboarding
- Registrierung (E-Mail + Passwort)
- Login / Logout / Refresh Token (JWT)
- Onboarding-Flow: Name, Instrumente, Kapelle beitreten/erstellen, Theme (max. 5 Fragen)
- Passwort-Reset

#### Kapellenverwaltung
- Kapelle erstellen (Name, Ort, Logo)
- Einladungslink/-code zum Beitreten
- Mitglieder-Übersicht mit Rollen und Instrumenten
- Rollenzuweisung (Admin, Dirigent, Notenwart, Registerführer, Musiker)
- Multi-Kapellen-Support: Kapellen-Wechsel in der Navigation
- Mitglieder-Profil: Instrumente, Standard-Stimme pro Kapelle

#### Noten-Upload & Labeling
- Upload: PDF, JPG, PNG, TIFF, Kamera-Foto
- PDF-Aufspaltung in Einzelseiten
- Labeling-Workflow: Seitengrenzen markieren, Stücken zuordnen
- Metadaten manuell eingeben (Titel, Komponist, Stimme, etc.)
- AI-Metadaten-Erkennung (optional, wenn AI-Keys konfiguriert)
- AI-Lizenzierung: Kapellen-Key + User-Key mit Fallback-Kette
- Drag & Drop Umsortierung

#### Spielmodus (Play Mode)
- Notenansicht: Vollbild, ablenkungsfrei
- Seitenwechsel < 100ms (Touch-Gesten: Tap, Swipe)
- **Half-Page-Turn** (konfigurierbar)
- **Bluetooth-Fußpedal-Support** (BLE HID)
- Auto-Rotation & Auto-Zoom
- Auftritt-Modus mit Touch-Lock
- Stimmenauswahl mit Fallback-Logik
- **Zweiseitenansicht (Two-Up-Modus):** Zwei Seiten nebeneinander im Querformat (min. 10")
- **Link Points für Wiederholungen:** Sprungmarken für D.S., D.C., Coda im Spielmodus
- **Dark Mode / Nachtmodus / Sepia:** Drei Farbschemata für die Notenansicht (Standard, Nacht, Sepia)

#### Annotationen
- SVG-Layer: Freihand-Stift, Text, Symbole
- Drei Sichtbarkeitsebenen (Privat, Stimme, Orchester)
- Stylus-First mit Palm Rejection
- Undo/Redo
- Layer ein-/ausblendbar

#### Persönliche Sammlung
- Noten zur eigenen Sammlung hinzufügen (gleiche Mechanismen wie Kapelle)
- Lokal auf dem Gerät gespeichert

#### Konfigurationssystem (3 Ebenen)
- **Kapelle:** AI-Keys, Berechtigungen, Branding, Policies, Standard-Sprache
- **Nutzer:** Theme (Dark/Light), Sprache, Instrumente, Standard-Stimme, Benachrichtigungen, persönliche AI-Keys
- **Gerät:** Display-Helligkeit, Touch-Zonen, Schriftgröße, Audio-Eingang, Offline-Speicher
- Override-Regel: Gerät > Nutzer > Kapelle > System-Default
- Policy-System: Kapelle kann bestimmte Overrides sperren
- Auto-Save mit Undo-Toast
- Farbkodierung: Blau (Kapelle) / Grün (Nutzer) / Orange (Gerät)
- Kontextuelle Einstellungen im Spielmodus (Overlay, max 5 Optionen)
- Vererbung transparent: "Standard von Kapelle" mit "Eigenen Wert festlegen"
- Keine Einstellung erfordert App-Neustart

#### Backend & Infrastruktur
- ASP.NET Core 10 API (REST, JWT, Cursor-Pagination)
- PostgreSQL 18 Datenbank (JSONB für Config)
- Azure Blob Storage + CDN für Notenbilder
- SQLite/Drift Client-DB (Offline-Cache)
- CI/CD Pipeline (GitHub Actions)
- Basis-Monitoring (Application Insights + OpenTelemetry)

### Abhängigkeiten
- Keine — MS1 ist der Startpunkt.

### Testing-Anforderungen
- Unit-Tests: ≥ 80% Coverage für Business-Logik (Backend + Frontend State)
- Widget-Tests: Alle kritischen UI-Flows (Onboarding, Upload, Spielmodus)
- Integration-Tests: API-Endpunkte, Auth-Flow, Datei-Upload
- E2E-Tests: Kern-Szenarien (Kapelle erstellen → Noten hochladen → Spielen)
- Performance-Test: Seitenwechsel < 100ms, Stift-Latenz < 50ms
- **3-Reviewer Code Review:** Sonnet 4.6, Opus 4.6, GPT 5.4 — Stark reviewed Reviews
- **UX-Review** für alle Frontend-Änderungen

### Definition of Done
- [ ] Kapelle erstellen und Mitglieder einladen funktioniert
- [ ] Noten-Upload mit Labeling-Prozess funktioniert (mit und ohne AI)
- [ ] Spielmodus: Half-Page-Turn, Fußpedal, Auto-Rotation, Touch-Lock
- [ ] Zweiseitenansicht (Two-Up) funktioniert im Querformat auf großen Tablets
- [ ] Link Points für Wiederholungen (D.S., D.C., Coda) im Spielmodus
- [ ] Dark Mode / Nachtmodus / Sepia umschaltbar
- [ ] Annotationen auf allen drei Sichtbarkeitsebenen funktionieren
- [ ] Konfiguration auf drei Ebenen mit Policy-System
- [ ] Persönliche Sammlung funktioniert (lokal)
- [ ] Stimmenauswahl mit Fallback-Logik
- [ ] i18n-Architektur: Alle Strings externalisiert (Deutsch)
- [ ] Alle Tests grün, Performance-Ziele erreicht
- [ ] Deployed und testbar auf iOS, Android, Windows, Web
- [ ] UX-Review bestanden

---

## MS2 — Setlist + Konzertplanung + Vereinsleben

### Scope

Organisation des Musikbetriebs. Nach MS2 können Kapellen ihren Proben- und Konzertbetrieb vollständig über Sheetstorm abwickeln — von der Setlist-Erstellung bis zur Anwesenheitsplanung.

### Deliverables

#### Setlist-Verwaltung
- Setlists erstellen, benennen, Stücke hinzufügen/umsortieren (Drag & Drop)
- Metadaten: Name, Datum, Typ (Konzert/Probe/Marschmusik)
- Setlist-Modus im Player: Nahtloser Übergang zwischen Stücken
- Stücke in mehreren Setlists
- **Platzhalter in Setlists:** Einträge ohne Stück-Referenz für noch nicht digitalisierte Stücke
- **Konzertprogramm mit Timing:** Geschätzte Dauer pro Stück, Gesamtdauer, Start-/Endzeiten

#### Konzertplanung
- Termine erstellen: Datum, Uhrzeit, Ort, Typ, Setlist-Verknüpfung
- Zu-/Absage-System mit optionaler Begründung
- Übersicht: Zugesagt / Offen / Abgesagt
- Ersatzmusiker-Vorschlag bei Absage (basierend auf Instrumentenprofil + Fallback)
- Push-Benachrichtigungen / Erinnerungen

#### Kalender
- Monats-/Wochen-/Listenansicht
- Filter nach Kapelle
- Termin-Details mit verknüpfter Setlist
- **Bidirektionale Kalender-Sync:** Automatische Synchronisation mit Google Calendar, Apple Calendar und Outlook (CalDAV, OAuth2)

#### GEMA & Compliance
- GEMA-/Verwertungsgesellschaft-Meldung: Automatische Generierung der Musikfolge aus Setlists
- Export-Formate: GEMA-XML, CSV, PDF
- AI-gestützte GEMA-Werknummern-Suche
- Verwertungsgesellschaft konfigurierbar (GEMA, SUISA, AKM)
- Erinnerung an ausstehende Meldungen

#### Media Links
- Pro Stück: YouTube-/Spotify-Referenzlinks hinterlegen
- "Anhören"-Button auf Stück-Detail und Setlist-Einträgen
- AI-gestützte Link-Vorschläge (optional)

#### Dirigenten-Mastersteuerung (Song-Broadcast)
- Dirigent wählt Stück → alle verbundenen Tablets zeigen automatisch die richtige Stimme
- Echtzeit-Übertragung via SignalR (WebSocket)
- Verbundene-Musiker-Zähler, Auto-Reconnect

#### Kommunikation
- **Nachrichten-Board / Pinnwand:** Feed mit Posts, Kommentaren, Reaktionen, Pin-Funktion
- **Umfragen / Abstimmungen:** Umfrage-Editor mit Einzel-/Mehrfachauswahl, anonyme/öffentliche Abstimmung
- **Register-basierte Benachrichtigungen:** Push-Notifications gezielt an Register, Gruppen oder einzelne Musiker

#### Anwesenheitsstatistiken
- Visualisierte Anwesenheit pro Musiker, Register und Zeitraum
- Trends, Register-Analyse, Export (CSV, PDF)

#### Aushilfen-Zugang
- Temporärer Zugangslink (konfigurierbare Gültigkeitsdauer)
- Nur zugewiesene Stimme für den Termin sichtbar
- Web-Ansicht ohne App-Installation
- QR-Code-Sharing
- Admin/Dirigent kann widerrufen

#### Schichtplanung (Basic)
- Schichten für Vereinsfeste definieren
- Selbsteintragung und Zuweisung
- Übersicht offener/besetzter Schichten

### Abhängigkeiten
- MS1 (Kapellenverwaltung, Notenbank, Spielmodus)

### Testing-Anforderungen
- Unit-Tests: Setlist-Logik, Termin-Management, Berechtigungen
- Widget-Tests: Setlist-Builder, Kalender, Zu-/Absage-Flow
- Integration-Tests: Setlist → Spielmodus Übergang, Push-Benachrichtigungen
- E2E: Konzert planen → Musiker laden → Absage → Ersatz-Vorschlag → Setlist spielen
- **UX-Review** + **3-Reviewer Code Review**

### Definition of Done
- [ ] Setlists erstellen und im Spielmodus nahtlos durchspielen
- [ ] Platzhalter in Setlists und Konzertprogramm mit Timing
- [ ] Konzertplanung mit Zu-/Absage und Ersatzmusiker-Vorschlag
- [ ] Kalenderansicht mit Kapellen-Filter und bidirektionaler Sync (Google/Apple/Outlook)
- [ ] GEMA-Meldung aus Setlist generierbar (XML, CSV, PDF)
- [ ] Media Links (YouTube/Spotify) pro Stück hinterlegen und öffnen
- [ ] Dirigenten-Mastersteuerung: Song-Broadcast an verbundene Geräte
- [ ] Nachrichten-Board mit Posts, Kommentaren und Pin-Funktion
- [ ] Umfragen erstellen und auswerten
- [ ] Register-basierte Benachrichtigungen funktionieren
- [ ] Anwesenheitsstatistiken mit Visualisierung
- [ ] Aushilfen-Zugang via Link funktioniert
- [ ] Schichtplanung (Basic) für Feste
- [ ] Push-Benachrichtigungen für Termine
- [ ] Alle Tests grün, UX-Review bestanden

---

## MS3 — Tuner + Echtzeit-Klick + Cloud-Sync

### Scope

Musikalische Werkzeuge für den Probenbetrieb. Nach MS3 können Musiker ihr Instrument stimmen, der Dirigent kann einen synchronen Taktschlag an alle senden, und die persönliche Sammlung wird über die Cloud synchronisiert.

### Deliverables

#### Stimmgerät (Tuner)
- Chromatischer Tuner via Mikrofon (Platform Channels zu CoreAudio/Oboe)
- FFT-basierte Frequenz-Erkennung
- Anzeige: Ton, Cent-Abweichung, Frequenz (Hz)
- Kammerton-Kalibrierung (Default 442 Hz, konfigurierbar in Geräte-Config)
- Transpositions-Support (Bb, Eb, F — basierend auf Instrumentenprofil)
- Ziel: < 20ms Audio-zu-Anzeige Latenz

#### Echtzeit-Metronom (Sync)
- Dirigent startet/stoppt Metronom (BPM + Taktart)
- **Clock-Synchronisation:** NTP-ähnliches Protokoll zwischen Server und Clients
- **Primär:** WiFi UDP Multicast (ASP.NET Core UDP-Server)
  - Ziel: < 5ms Latenz im LAN
  - Beats als Timestamps, nicht als Live-Kommandos
- **Fallback:** SignalR WebSocket (Remote/Internet)
  - Ziel: < 50ms Latenz
- Visuelle Anzeige: Taktschlag-Indikator mit Animation
- Optionaler Audio-Click (konfigurierbar pro Gerät)
- Latenz-Kompensation pro Gerät einstellbar
- Automatische Erkennung: WiFi-Netz → UDP, sonst → WebSocket

#### Cloud-Sync (Persönliche Sammlung)
- Synchronisation persönlicher Noten über Sheetstorm-Backend
- Delta-Sync mit Versionierung
- Konflikt-Auflösung: Last-Write-Wins per Feld
- Offline-Fähigkeit erhalten

#### Annotationen-Sync (Erweitert)
- Stimmen-Annotationen: Echtzeit-Sync für alle Musiker derselben Stimme
- Orchester-Annotationen: Echtzeit-Sync für alle Musiker
- Konflikt-Behandlung bei gleichzeitiger Bearbeitung

#### Spielmodus-Erweiterungen
- **Auto-Scroll / Reflow:** Automatisches Scrollen der Notenansicht mit einstellbarer Geschwindigkeit (BPM-basiert oder manuell)

#### Aufgabenverwaltung / To-Do-Listen
- Aufgaben erstellen und Mitgliedern zuweisen
- Status-Tracking: Offen → In Bearbeitung → Erledigt
- Erinnerungen bei Fälligkeiten, optional an Termine koppeln

### Abhängigkeiten
- MS1 (Spielmodus, Annotationen, Config-System)

### Testing-Anforderungen
- Unit-Tests: FFT-Algorithmus, Clock-Sync-Logik, Delta-Sync
- Integration-Tests: UDP Multicast Latenz, WebSocket Fallback, Sync-Szenarien
- Performance-Tests: Tuner < 20ms, UDP < 5ms, WebSocket < 50ms
- Geräte-Tests: Verschiedene Mikrofone, BLE-Geräte, Netzwerk-Konfigurationen
- **UX-Review** + **3-Reviewer Code Review**

### Definition of Done
- [ ] Tuner funktioniert auf iOS, Android, Windows mit < 20ms Latenz
- [ ] Metronom: UDP-Sync < 5ms im LAN
- [ ] Metronom: WebSocket-Fallback < 50ms
- [ ] Automatischer Wechsel UDP ↔ WebSocket
- [ ] Cloud-Sync für persönliche Sammlung
- [ ] Annotationen-Sync (Stimme + Orchester) in Echtzeit
- [ ] Auto-Scroll / Reflow im Spielmodus funktioniert
- [ ] Aufgabenverwaltung: Erstellen, zuweisen, Status tracken
- [ ] Alle Tests grün, Performance-Ziele gemessen und dokumentiert

---

## MS4 — Lehre-Modul

### Scope

Digitaler Musikunterricht. Lehrer können Schülern Noten freischalten und strukturierte Lernpfade anbieten. Kann parallel zu MS2/MS3 gestartet werden (nur MS1-Abhängigkeit).

### Deliverables

#### Lehrer-Schüler-Verwaltung
- Zusätzliche Rollen: Lehrer und Schüler
- Lehrer erstellt Schüler-Accounts oder lädt bestehende Nutzer ein
- Schüler-Dashboard mit freigeschalteten Noten
- Lehrer-Dashboard: Schüler-Übersicht mit Status

#### Notenfreischaltung
- Lehrer schaltet einzelne Stücke/Stimmen für Schüler frei
- Schüler sieht nur freigeschaltete Noten
- Freischaltung mit optionaler Notiz/Anweisung
- Bulk-Freischaltung für mehrere Schüler

#### Lernpfade
- Geordnete Sequenz von Stücken/Übungen
- Fortschritts-Tracking: Markierung als "geübt" / "abgeschlossen"
- Optional: Automatische Freischaltung des nächsten Stücks
- Lehrer sieht Fortschritt aller Schüler

#### Schüler-Spielmodus
- Identisch mit normalem Spielmodus (inkl. Annotationen, Half-Page-Turn)
- Zusätzlich: Lernpfad-Navigation (Vorheriges/Nächstes Stück im Pfad)

#### Advanced AI (Annotations)
- **AI-Annotations-Analyse (Cross-Part):** Dirigenten-Annotationen werden AI-gestützt über alle Stimmen hinweg analysiert und konsistente Markierungen vorgeschlagen
- Erkennung von Inkonsistenzen zwischen Stimmen (z.B. fehlende Dynamik-Markierungen)
- Vorschläge für registerübergreifende Annotationen

### Abhängigkeiten
- MS1 (Spielmodus, Annotationen, Rollen-System)
- **NICHT** abhängig von MS2 oder MS3 → kann parallel gestartet werden

### Testing-Anforderungen
- Unit-Tests: Freischaltungs-Logik, Lernpfad-Progression
- Widget-Tests: Lehrer- und Schüler-Dashboards
- Integration-Tests: Freischaltung → Schüler sieht Noten
- **UX-Review** + **3-Reviewer Code Review**

### Definition of Done
- [ ] Lehrer kann Schüler verwalten und Noten freischalten
- [ ] Lernpfade erstellen und Fortschritt tracken
- [ ] Schüler sieht nur freigeschaltete Noten
- [ ] Spielmodus mit Lernpfad-Navigation
- [ ] AI-Annotations-Analyse (Cross-Part): Konsistenzprüfung über Stimmen hinweg
- [ ] Detailspezifikation von Thomas abgenommen (offener Punkt)
- [ ] Alle Tests grün, UX-Review bestanden

---

## MS5 — Polish, Multi-Language, Advanced AI

### Scope

Feinschliff, Internationalisierung und erweiterte AI-Funktionen. Sheetstorm wird mehrsprachig und die AI-Integration wird vertieft.

### Deliverables

#### Internationalisierung
- Englisch als zweite Sprache (vollständige Übersetzung aller Strings)
- Sprachauswahl: Nutzer-Ebene Config
- Fallback-Kette: Nutzer-Sprache → Kapelle-Default → Deutsch
- Community-Beitrag-Infrastruktur für weitere Sprachen

#### Advanced AI
- Erweiterte OCR: Taktart, Tonart, Wiederholungszeichen erkennen
- AI-gestützte Stimmen-Zuordnung (Vorschlag basierend auf Notenblatt-Inhalt)
- Batch-Verarbeitung: Ganzer Noten-Ordner → automatische Zuordnung
- Weitere AI-Provider evaluieren und integrieren

#### Kalender-Integration
- Export als iCal
- Sync mit Google Calendar / Apple Calendar / Outlook
- Bidirektionale Sync (Read/Write)

#### Analytics & Dashboard
- Anwesenheits-Statistiken
- Proben-Trends
- Noten-Nutzungsstatistiken

#### Performance & Polish
- Animations-Feinschliff (Spielmodus, Seitenwechsel)
- Accessibility-Audit (WCAG 2.1 AA)
- Performance-Optimierung basierend auf Real-World-Daten
- Dokumentation & Hilfe-System in der App
- **Face-Gesten für Seitenwechsel:** Seitenwechsel per Gesichtsbewegung (Kopfnicken, Lächeln) über Frontkamera (iOS ARKit, Android ML Kit)

#### Inventarverwaltung
- Vereinseigene Instrumente und Equipment verwalten (Bezeichnung, Typ, Seriennummer, Zustand)
- Zuweisung an Mitglieder (Leihinstrumente)
- Wartungstermine mit Erinnerung
- Zustandsberichte und Historie

### Abhängigkeiten
- MS2, MS3 (Setlists, Termine, Metronom müssen stehen)

### Testing-Anforderungen
- Vollständiger Regressions-Test aller Features
- i18n-Tests: Alle Screens in Deutsch und Englisch
- Accessibility-Tests mit Screen Reader
- Performance-Benchmarks: Alle NFAs erfüllt
- **UX-Review** + **3-Reviewer Code Review**

### Definition of Done
- [ ] App vollständig auf Deutsch und Englisch nutzbar
- [ ] Kalender-Integration funktioniert (iCal Export, Google/Apple/Outlook Sync)
- [ ] Advanced AI: Batch-Upload, verbesserte Erkennung
- [ ] Analytics-Dashboard für Admins/Dirigenten
- [ ] Face-Gesten für Seitenwechsel funktionieren (iOS + Android)
- [ ] Inventarverwaltung: Instrumente/Equipment verwalten und zuweisen
- [ ] WCAG 2.1 AA Accessibility bestanden
- [ ] Performance-Ziele in Produktion gemessen und erfüllt
- [ ] Alle Tests grün, Regressions-Suite vollständig

---

## Zusammenfassung: Wertversprechen pro Meilenstein

| MS | Was der Nutzer damit tun kann |
|----|-------------------------------|
| **MS1** | Kapelle gründen, Noten hochladen, am Tablet spielen, Einstellungen personalisieren |
| **MS2** | Proben und Konzerte organisieren, Setlists durchspielen, Aushilfen einladen |
| **MS3** | Instrument stimmen, synchron zum Dirigenten-Klick spielen, Noten überall dabeiahaben |
| **MS4** | Musikunterricht digital gestalten, Schüler-Fortschritt verfolgen |
| **MS5** | App auf Englisch nutzen, erweiterte AI-Erkennung, Kalender-Sync, Statistiken |

---

*Dieses Dokument wird via PR zur Abstimmung vorgelegt. Änderungen erfordern Thomas' Freigabe.*
