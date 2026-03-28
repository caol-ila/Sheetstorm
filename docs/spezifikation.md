# Sheetstorm — Funktionale Spezifikation

> **Version:** 2.0  
> **Autor:** Stark (Lead / Architect)  
> **Datum:** 2026-03-28  
> **Status:** Zur Abstimmung via PR  
> **Basis:** docs/anforderungen.md, Marktanalyse, UX-Research, Feature-Gap-Analyse

---

## 1. Produktübersicht

**Sheetstorm** ist eine Notenmanagement-App für Blaskapellen. Sie vereint zentrale Notenverwaltung, Stimmenverteilung, Setlist-Management, Vereinsorganisation und musikalische Werkzeuge in einer Plattform — optimiert für Touch-Geräte im Proben- und Konzertbetrieb.

### 1.1 Zielgruppen

| Zielgruppe | Beschreibung |
|------------|-------------|
| Blaskapellen | Vereine mit 20–80 Musikern, gemischte Altersstruktur, verschiedene Geräte |
| Musikschulen | Lehrer-Schüler-Verhältnis, Lernpfade, Notenfreischaltung |
| Einzelmusiker | Persönliche Notensammlung, kapellenunabhängig |

### 1.2 Plattformen

| Plattform | Priorität | Beschreibung |
|-----------|-----------|-------------|
| **Tablet (iOS/Android)** | P0 — Primär | Hauptgerät für Proben und Auftritte, Touch + Stylus |
| **Smartphone (iOS/Android)** | P0 | Unterwegs, Termine, schnelle Einsicht |
| **Desktop (Windows)** | P1 | Verwaltung, Upload, Notenwart-Arbeit |
| **Web (Browser)** | P1 | Admin-Tätigkeiten, kein App-Install nötig |

**Touch-Unterstützung ist Pflicht auf allen Plattformen.**

---

## 2. Features nach Domäne

### 2.1 Notenverwaltung (Kern)

#### F-NV-01: Zentrale Notenbank
**Priorität:** Must  
**User Story:** Als Notenwart möchte ich Noten zentral für meine Kapelle hochladen, damit alle Musiker Zugriff auf die aktuellen Stimmen haben.  
**Akzeptanzkriterien:**
- Noten werden pro Kapelle verwaltet (Kapelle-ID)
- Jedes Stück hat Metadaten: Titel, Komponist/Arrangeur, Genre, Schwierigkeitsgrad, Tags
- Ein Stück enthält 1..n Stimmen
- Jede Stimme enthält 1..n Notenblätter (Seiten als Bilder)
- Notenblätter werden als optimierte Bilder gespeichert (Server + CDN)
- Suche über Titel, Komponist, Tags, Stimme

#### F-NV-02: Stimmenauswahl mit Fallback
**Priorität:** Must  
**User Story:** Als Musiker möchte ich beim Öffnen eines Stücks automatisch meine Standard-Stimme sehen, damit ich sofort spielen kann.  
**Akzeptanzkriterien:**
- Musiker definiert Standard-Instrument und -Stimme pro Kapelle (z.B. "2. Klarinette")
- Beim Öffnen eines Stücks wird die Standard-Stimme vorausgewählt
- **Fallback-Logik:** Wenn "2. Klarinette" nicht existiert → "1. Klarinette" → "Klarinette" → manuelle Auswahl
- Stimmen der eigenen Instrumente erscheinen priorisiert oben in der Auswahlliste
- Andere Stimmen darunter, alphabetisch sortiert
- Musiker kann jederzeit eine andere Stimme wählen — kein Zwang
- Musiker kann mehrere Instrumente angeben (Profil)

#### F-NV-03: Noten-Upload & Labeling-Prozess
**Priorität:** Must  
**User Story:** Als Notenwart möchte ich einen Stapel Notenblätter hochladen und sie verschiedenen Stücken zuordnen können.  
**Akzeptanzkriterien:**
- Upload-Formate: PDF, JPG, PNG, TIFF, Kamera-Foto (direkt aus App)
- Multi-Seiten-PDF wird in Einzelseiten aufgeteilt
- **Labeling-Workflow:**
  1. Vorschaubilder aller hochgeladenen Seiten werden angezeigt
  2. Nutzer markiert Seitengrenzen: "noch gleiches Stück" / "neues Stück beginnt hier"
  3. Pro Stück: Zuordnung von Metadaten (Titel, Stimme, etc.)
  4. AI-gestützte Metadaten-Erkennung (optional, wenn AI konfiguriert)
- Manuelles Labeling funktioniert auch ohne AI
- Drag & Drop zum Umsortieren der Seiten
- Bulk-Import: Mehrere PDFs gleichzeitig

#### F-NV-04: AI-gestützte Metadaten-Erkennung
**Priorität:** Should  
**User Story:** Als Notenwart möchte ich, dass die App automatisch Titel, Stimme und Komponist aus dem Notenblatt erkennt.  
**Akzeptanzkriterien:**
- Vision/OCR-Analyse der hochgeladenen Bilder
- Erkennbare Felder: Titel, Komponist/Arrangeur, Stimmenbezeichnung, Tonart, Taktart
- Erkannte Werte werden als Vorschlag angezeigt — nie automatisch übernommen
- Konfidenz-Anzeige pro Feld (hoch/mittel/niedrig)
- Adapter-Pattern: Austauschbare AI-Provider (Azure AI Vision, OpenAI Vision, Google Cloud Vision)
- Funktionalität ist optional — App ist voll nutzbar ohne AI

#### F-NV-05: AI-Lizenzierung (Dual-Key)
**Priorität:** Must (wenn AI aktiv)  
**User Story:** Als Admin möchte ich AI-Keys zentral für die Kapelle hinterlegen, damit nicht jeder Musiker eigene Keys braucht.  
**Akzeptanzkriterien:**
- **Kapellen-Key:** Admin hinterlegt API-Key für die gesamte Kapelle
- **User-Key:** Jeder Nutzer kann eigenen API-Key hinterlegen
- **Fallback-Kette:** User-Key → Kapellen-Key → keine AI
- Key-Validierung bei Eingabe (Test-Request)
- Optional: Verbrauchsanzeige / Quota-Hinweis
- Verschlüsselte Speicherung der Keys (serverseitig AES-256, clientseitig Secure Storage)

#### F-NV-06: Persönliche Notensammlung
**Priorität:** Must  
**User Story:** Als Musiker möchte ich eigene Noten unabhängig von einer Kapelle verwalten.  
**Akzeptanzkriterien:**
- Gleiche Mechanismen wie Kapellen-Noten (Stück-Entität mit Musiker-ID statt Kapelle-ID)
- Noten liegen primär lokal auf dem Gerät
- Optional: Cloud-Sync über Sheetstorm-Backend
- Zukunft: Integration externer Cloud-Anbieter (OneDrive, Dropbox) — Could

#### F-NV-07: Berechtigungen für Noteneinpflege
**Priorität:** Must  
**User Story:** Als Admin möchte ich steuern, wer Noten zur Kapellen-Bibliothek hinzufügen darf.  
**Akzeptanzkriterien:**
- Konfigurierbar pro Kapelle: Welche Rollen dürfen Noten hochladen
- Default: Admin, Dirigent, Notenwart
- Jeder Musiker kann immer zur eigenen persönlichen Sammlung hinzufügen
- Bearbeiten/Löschen von Kapellen-Noten: Nur Upload-Berechtigte + Admin

#### F-NV-08: Media Links (YouTube/Spotify)
**Priorität:** Should (MS2)  
**User Story:** Als Musiker möchte ich pro Stück YouTube- und Spotify-Referenzlinks hinterlegen können, damit ich Stücke vor der Probe anhören kann, ohne selbst suchen zu müssen.  
**Akzeptanzkriterien:**
- Pro Stück können 0..n Media-Links gespeichert werden (YouTube, Spotify, weitere URLs)
- Typ-Erkennung: YouTube- und Spotify-Links werden automatisch erkannt und mit Icon dargestellt
- "Anhören"-Button auf Stück-Detail und Setlist-Einträgen → öffnet Link in externer App oder eingebettete Vorschau
- AI-gestützte Vorschläge: Optionale Suche nach passenden YouTube/Spotify-Links basierend auf Titel und Komponist
- Jeder Musiker mit Stück-Zugriff kann Links sehen
- Hinzufügen/Bearbeiten: Admin, Dirigent, Notenwart (konfigurierbar)
- Deep-Link-Support: Öffnet YouTube/Spotify-App wenn installiert, sonst Browser

### 2.2 Spielmodus (Performance Mode)

#### F-SM-01: Notenansicht (Play Mode)
**Priorität:** Must  
**User Story:** Als Musiker möchte ich meine Noten ablenkungsfrei auf dem Bildschirm sehen und durch Seiten blättern können.  
**Akzeptanzkriterien:**
- Vollbild-Anzeige ohne UI-Elemente ("Auftritt"-Modus)
- Seitenwechsel < 100ms (wahrnehmbar instantan)
- Touch-Gesten: Tap links/rechts, Swipe, Tap oben (zurück)
- Versehentliche Touches im Auftritt-Modus ignorieren (Lock)
- Aktivierung über dedizierten "Auftritt"-Button

#### F-SM-02: Half-Page-Turn
**Priorität:** Must  
**User Story:** Als Musiker möchte ich beim Seitenwechsel die untere Hälfte der nächsten Seite sehen, während die obere Hälfte der aktuellen noch sichtbar ist.  
**Akzeptanzkriterien:**
- Obere Hälfte: Aktuelle Seite (unterer Bereich)
- Untere Hälfte: Nächste Seite (oberer Bereich)
- Übergangsanimation: Sanft, kein "Sprung-Schock"
- Konfigurierbar: An/Aus, Teilungsverhältnis (50/50 default)
- Kompatibel mit Fußpedal-Auslösung

#### F-SM-03: Bluetooth-Fußpedal-Support
**Priorität:** Must  
**User Story:** Als Blasmusiker möchte ich mit einem Fußpedal durch die Noten blättern, da ich beide Hände am Instrument habe.  
**Akzeptanzkriterien:**
- Bluetooth HID-Geräte (Fußpedale, Page Turner) werden erkannt
- Konfigurierbare Tasten-Zuordnung (vorwärts/rückwärts)
- Funktioniert im Spielmodus und Setlist-Modus
- Kompatibel mit gängigen BLE Page-Turner-Geräten (PageFlip, AirTurn, iRig)
- Pairing-Anleitung in den Geräte-Einstellungen

#### F-SM-04: Auto-Rotation & Auto-Zoom
**Priorität:** Must  
**User Story:** Als Musiker möchte ich, dass schief gescannte Noten automatisch gerade angezeigt werden.  
**Akzeptanzkriterien:**
- Automatische Erkennung der Notenlinien-Ausrichtung
- Drehung, sodass Notenlinien horizontal sind
- Auto-Zoom: Maximale Noten-Sichtbarkeit ohne Abschnitt
- Anpassung an verschiedene Bildschirmgrößen/-formate
- Manuelles Override möglich (Pinch-to-Zoom, Rotation)

#### F-SM-05: Annotationen & Markierungen
**Priorität:** Must  
**User Story:** Als Musiker möchte ich Notizen und Markierungen in meine Noten einfügen, die je nach Bedarf privat oder geteilt sind.  
**Akzeptanzkriterien:**
- **SVG-Layer** über den Notenbildern mit relativen Positionen (%)
- Werkzeuge: Freihand-Stift, Textbox, Hervorhebung, Symbole (Atemzeichen, Dynamik)
- **Drei Sichtbarkeitsebenen:**
  1. **Privat:** Nur für den Musiker sichtbar (lokal + User-Sync)
  2. **Stimme:** Für alle Musiker derselben Stimme synchronisiert
  3. **Orchester:** Für alle Musiker sichtbar (Dirigenten-Anweisungen)
- **Stylus-First:** Stift berührt Screen → sofort annotieren, kein Menü-Umweg
- Finger ≠ Stift in der Erkennung (Palm Rejection)
- Layer ein-/ausblendbar
- Undo/Redo mit History

#### F-SM-06: Aushilfen-Zugang ohne Registrierung
**Priorität:** Should  
**User Story:** Als Dirigent möchte ich einem Aushilfsmusiker schnell Zugang zu seinen Noten geben, ohne dass er sich registrieren muss.  
**Akzeptanzkriterien:**
- Temporärer Zugangslink mit Ablaufdatum (konfigurierbar, Default 7 Tage)
- Nur die zugewiesene Stimme für den jeweiligen Termin/Setlist sichtbar
- Kein Account erforderlich — Link öffnet Web-Ansicht
- Optional: Link per QR-Code teilbar
- Admin/Dirigent kann Link jederzeit widerrufen
- Kein Zugriff auf Kapellen-Verwaltung oder andere Stücke

#### F-SM-07: Zweiseitenansicht (Two-Up-Modus)
**Priorität:** Should (MS1)  
**User Story:** Als Musiker möchte ich auf meinem Tablet zwei Seiten gleichzeitig sehen können, damit ich seltener blättern muss.  
**Akzeptanzkriterien:**
- Im Querformat: Zwei Notenblätter nebeneinander anzeigen
- Konfigurierbar: An/Aus in den Geräte-Einstellungen
- Nur aktiv wenn Bildschirm groß genug (min. 10" diagonal)
- Kompatibel mit Half-Page-Turn (dann 4 halbe Seiten sichtbar)
- Stimmenauswahl gilt für beide Seiten gleichzeitig
- Bei zu kleinem Bildschirm: Option automatisch ausgeblendet mit Hinweis

#### F-SM-08: Link Points für Wiederholungen (D.S., D.C., Coda)
**Priorität:** Should (MS1)  
**User Story:** Als Musiker möchte ich Sprungmarken für Wiederholungen (D.S., D.C., Coda) auf meinen Noten setzen können, damit ich im Spielmodus automatisch zur richtigen Stelle springe.  
**Akzeptanzkriterien:**
- Musiker kann Sprungmarken auf dem Notenblatt platzieren (Start + Ziel)
- Unterstützte Typen: D.S. (Dal Segno), D.C. (Da Capo), Coda, Fine, Segno
- Im Spielmodus: Beim Erreichen einer Marke erscheint ein Sprung-Button oder automatischer Sprung (konfigurierbar)
- Visuelle Darstellung der Marken als Overlay-Symbole
- Marken können bearbeitet und gelöscht werden
- Kompatibel mit Annotationen-Layer (eigene Ebene)
- Privat pro Musiker (Sichtbarkeitsebene: Privat)

#### F-SM-09: Dark Mode / Nachtmodus / Sepia
**Priorität:** Should (MS1)  
**User Story:** Als Musiker möchte ich zwischen verschiedenen Farbschemata für die Notenansicht wählen können, damit ich bei dunklen Auftritten oder langen Proben augenschonend lesen kann.  
**Akzeptanzkriterien:**
- Drei Modi: Standard (weißer Hintergrund), Nachtmodus (dunkler Hintergrund, invertierte Noten), Sepia (warmer Ton)
- Umschaltbar über Spielmodus-Overlay (schneller Zugriff)
- Konfigurierbar als Standard in Nutzer- und Geräte-Einstellungen
- Invertierung der Notenbilder für Nachtmodus (schwarze Noten → weiße Noten auf dunklem Grund)
- Helligkeit der Noten im Nachtmodus einstellbar
- Kompatibel mit Annotationen (Farben werden angepasst)

#### F-SM-10: Auto-Scroll / Reflow
**Priorität:** Could (MS3)  
**User Story:** Als Musiker möchte ich, dass meine Noten automatisch in einstellbarer Geschwindigkeit scrollen, damit ich bei linearen Stücken nicht manuell blättern muss.  
**Akzeptanzkriterien:**
- Automatisches vertikales Scrollen der Notenansicht
- Geschwindigkeit stufenlos einstellbar (BPM-basiert oder manuell)
- Start/Stop über Tap oder Fußpedal
- Pause-Funktion mit Fortsetzen an gleicher Stelle
- Scroll-Position manuell korrigierbar (Touch/Swipe unterbricht Auto-Scroll temporär)
- Konfigurierbar: Default-Geschwindigkeit pro Stück speicherbar
- Hinweis: Für Stücke mit Wiederholungen weniger geeignet — Link Points bevorzugen

#### F-SM-11: Face-Gesten für Seitenwechsel
**Priorität:** Could (MS5)  
**User Story:** Als Musiker möchte ich per Gesichtsbewegung (z.B. Kopfnicken) durch die Noten blättern können, wenn weder Hände noch Fußpedal verfügbar sind.  
**Akzeptanzkriterien:**
- Seitenwechsel durch konfigurierbare Gesten (Kopfnicken, Lächeln, Augenbrauen heben)
- Erkennung über Frontkamera (Computer Vision)
- Konfigurierbar: Gesten-Typ, Empfindlichkeit, An/Aus
- Feedback bei erkannter Geste (kurze visuelle Bestätigung)
- Datenschutz: Kein Kamerabild wird gespeichert oder übertragen
- Plattform-Support: iOS (ARKit), Android (ML Kit)
- Hinweis: Für Blasmusiker eingeschränkt nutzbar (Mund am Instrument) — Fußpedal bevorzugen

### 2.3 Setlist-Verwaltung

#### F-SL-01: Setlist erstellen & verwalten
**Priorität:** Must  
**User Story:** Als Dirigent möchte ich Setlists für Konzerte und Proben zusammenstellen.  
**Akzeptanzkriterien:**
- Erstellen benannter Setlists aus dem Kapellen-Notenbestand
- Stücke per Drag & Drop umsortieren
- Metadaten pro Setlist: Name, Datum, Typ (Konzert/Probe/Marschmusik)
- Stücke können in mehreren Setlists vorkommen
- Setlist-Ansicht im Spielmodus: Nahtloser Übergang zwischen Stücken
- Berechtigungen: Dirigent, Admin, Notenwart können Setlists erstellen

#### F-SL-02: Platzhalter in Setlists
**Priorität:** Could (MS2)  
**User Story:** Als Dirigent möchte ich Platzhalter-Einträge in eine Setlist einfügen können für Stücke, die noch nicht digitalisiert sind, damit ich das Konzertprogramm frühzeitig planen kann.  
**Akzeptanzkriterien:**
- Setlist-Eintrag ohne Stück-Referenz erlauben (nur Name + optionale Notizen)
- Visuell als Platzhalter erkennbar (z.B. gestrichelter Rahmen, Icon)
- Platzhalter kann nachträglich mit einem existierenden Stück verknüpft werden
- Position bleibt bei Verknüpfung erhalten
- Platzhalter werden im Spielmodus übersprungen (mit Hinweis)
- Metadaten: Name, geschätzte Dauer, Notizen

#### F-SL-03: Konzertprogramm mit exaktem Timing
**Priorität:** Could (MS2)  
**User Story:** Als Dirigent möchte ich für jedes Stück im Konzertprogramm eine geschätzte Dauer hinterlegen, damit ich die Gesamtdauer und Start-/Endzeiten auf einen Blick sehe.  
**Akzeptanzkriterien:**
- Pro Setlist-Eintrag: Geschätzte Dauer in Minuten (optional)
- Automatische Berechnung der Gesamtdauer
- Anzeige der kumulierten Start-/Endzeit pro Stück (basierend auf Konzertbeginn)
- Konzertbeginn-Zeit konfigurierbar pro Setlist
- Pausen-Einträge möglich (z.B. "Pause — 15 Min")
- Warnung wenn Gesamtdauer einen konfigurierbaren Rahmen überschreitet
- Druckbare Übersicht (PDF-Export des Programms mit Zeiten)

### 2.4 Kapellenverwaltung

#### F-KV-01: Kapelle erstellen & verwalten
**Priorität:** Must  
**User Story:** Als Vorstand möchte ich eine Kapelle in der App anlegen und Mitglieder einladen.  
**Akzeptanzkriterien:**
- Kapelle erstellen mit Name, Ort, Logo/Branding
- Einladungslink / Einladungscode zum Beitreten
- Mitglieder-Übersicht mit Rollen, Instrumenten, Status
- Multi-Kapellen: Ein Musiker kann mehreren Kapellen angehören
- Kapellen-Wechsel über Dropdown/Selector in der Navigation
- Kapellen-spezifische Einstellungen (siehe Konfigurationskonzept)

#### F-KV-02: Rollenverwaltung
**Priorität:** Must  
**User Story:** Als Admin möchte ich Mitgliedern Rollen zuweisen, die ihre Berechtigungen bestimmen.  
**Akzeptanzkriterien:**
- Rollen pro Kapelle (nicht global): Ein Musiker kann in Kapelle A Admin sein und in Kapelle B nur Musiker
- Mehrere Rollen pro Mitglied möglich
- Rollenzuweisung nur durch Admin

### 2.5 Vereinsleben & Organisation

#### F-VL-01: Konzertplanung mit Zu-/Absage
**Priorität:** Should  
**User Story:** Als Dirigent möchte ich Auftritte planen und sehen, wer teilnimmt.  
**Akzeptanzkriterien:**
- Termin erstellen: Datum, Uhrzeit, Ort, Typ (Konzert/Probe/Fest/Sonstiges)
- Musiker können zu-/absagen mit optionaler Begründung
- Übersicht: Wer hat zugesagt, wer noch offen, wer abgesagt
- Bei Absage: Vorschlag für Ersatzmusiker basierend auf Instrumentenprofil + Fallback-Logik
- Erinnerungen/Push-Benachrichtigungen vor Terminen
- Verknüpfung mit Setlist (welche Noten werden gespielt)

#### F-VL-02: Schichtplanung für Feste
**Priorität:** Could  
**User Story:** Als Vereinsvorstand möchte ich Arbeitsschichten für Vereinsfeste verwalten.  
**Akzeptanzkriterien:**
- Schichten definieren: Zeitraum, Aufgabe, benötigte Personen
- Zuweisung und Selbsteintragung
- Übersicht offener/besetzter Schichten

#### F-VL-03: Kalender & Termine (inkl. bidirektionaler Sync)
**Priorität:** Should (MS2)  
**User Story:** Als Musiker möchte ich alle Kapellen-Termine im Überblick sehen und automatisch mit meinem privaten Kalender synchronisieren, damit ich keine Probe vergesse.  
**Akzeptanzkriterien:**
- Kalenderansicht (Monats-/Wochen-/Listenansicht)
- Filterbar nach Kapelle (bei Multi-Kapellen)
- Kalender-Export als iCal-Datei (Einmal-Download)
- **Bidirektionale Kalender-Sync:** Automatische Synchronisation mit Google Calendar, Apple Calendar und Outlook
- CalDAV-Subscription-URL für automatische Updates
- Änderungen in Sheetstorm werden in Echtzeit im externen Kalender reflektiert
- Sync-Status pro Nutzer sichtbar (verbunden/nicht verbunden)
- OAuth2-basierte Autorisierung für Google/Outlook, native Integration für Apple Calendar
- Konfigurierbar: Welche Kapellen-Termine synchronisiert werden (alle/nur zugesagte)

#### F-VL-04: GEMA-/Verwertungsgesellschaft-Meldung
**Priorität:** Must (MS2)  
**User Story:** Als Vereinsvorstand möchte ich Konzertberichte (Musikfolge) für die GEMA/SUISA/AKM direkt aus der Setlist generieren können, damit ich die gesetzliche Meldepflicht einfach und fehlerfrei erfülle.  
**Akzeptanzkriterien:**
- Automatische Generierung der Musikfolge (Konzertbericht) aus einer Setlist
- Export-Formate: GEMA-XML, CSV, PDF
- Felder pro Stück: Titel, Komponist, Arrangeur, Verlag, Werknummer, Dauer
- AI-gestützte Suche nach GEMA-Werknummern (optional, basierend auf Titel/Komponist)
- Verwertungsgesellschaft konfigurierbar pro Kapelle (GEMA, SUISA, AKM)
- Erinnerung an ausstehende Meldungen nach Konzerten (Push-Benachrichtigung)
- Historie: Alle generierten Meldungen werden archiviert
- Berechtigungen: Admin, Dirigent, Vorstand

#### F-VL-05: Dirigenten-Mastersteuerung (Song-Broadcast)
**Priorität:** Should (MS2)  
**User Story:** Als Dirigent möchte ich zentral ein Stück aus der Setlist auswählen und automatisch auf allen verbundenen Geräten anzeigen lassen, damit bei Programmwechseln niemand suchen muss.  
**Akzeptanzkriterien:**
- Dirigenten-Modus: Setlist aktivieren → alle verbundenen Geräte synchronisieren
- Dirigent tippt Stück an → alle Tablets wechseln automatisch zur richtigen Stimme
- Echtzeit-Übertragung via SignalR (WebSocket)
- Verbundene-Musiker-Zähler für den Dirigenten sichtbar
- Auto-Reconnect bei Verbindungsabbruch
- Musiker kann lokale Steuerung temporär übernehmen (Opt-out)
- Kompatibel mit Setlist-Modus und Spielmodus
- Nur Dirigent/Admin kann Broadcast starten

#### F-VL-06: Anwesenheitsstatistiken
**Priorität:** Should (MS2)  
**User Story:** Als Dirigent möchte ich Statistiken über die Anwesenheit bei Proben und Auftritten sehen, damit ich Trends erkennen und die Probenbeteiligung verbessern kann.  
**Akzeptanzkriterien:**
- Visualisierung der Anwesenheit pro Musiker, Register und Zeitraum
- Filterbar nach Zeitraum (Monat, Quartal, Jahr, benutzerdefiniert)
- Darstellung als Diagramm (Balken/Linie) und Tabelle
- Trends: Teilnahme-Entwicklung über Zeit
- Register-Analyse: Welches Register ist chronisch unterbesetzt?
- Export der Statistiken (CSV, PDF)
- Berechtigungen: Admin, Dirigent, Vorstand sehen alle; Musiker sieht eigene Statistik
- Basiert auf Zu-/Absage-Daten (F-VL-01)

#### F-VL-07: Register-basierte Benachrichtigungen
**Priorität:** Should (MS2)  
**User Story:** Als Dirigent möchte ich Benachrichtigungen gezielt an bestimmte Register oder Gruppen senden können, damit nicht immer die gesamte Kapelle benachrichtigt wird.  
**Akzeptanzkriterien:**
- Empfänger-Auswahl: Gesamte Kapelle, einzelne Register, benutzerdefinierte Gruppen, einzelne Musiker
- Register werden automatisch aus den Instrumentenprofilen gebildet
- Benutzerdefinierte Gruppen erstellbar (z.B. "Vorstand", "Jugendorchester")
- Benachrichtigungs-Typ: Push-Notification + In-App-Nachricht
- Musiker kann eigene Benachrichtigungs-Präferenzen konfigurieren (welche Gruppen)
- Berechtigungen: Admin, Dirigent, Registerführer (für eigenes Register)

#### F-VL-08: Nachrichten-Board / Pinnwand
**Priorität:** Should (MS2)  
**User Story:** Als Vorstand möchte ich Ankündigungen und Neuigkeiten auf einem zentralen Board veröffentlichen, damit wichtige Informationen nicht in Chat-Nachrichten untergehen.  
**Akzeptanzkriterien:**
- Social-Media-ähnlicher Feed mit Posts (Text, Bilder, Links)
- Kommentar-Funktion unter Posts
- Reaktionen (Emoji-Reaktionen oder Daumen hoch)
- Pin-Funktion: Wichtige Posts oben fixieren
- Empfänger-Auswahl pro Post: Gesamte Kapelle oder bestimmte Register/Gruppen
- Push-Benachrichtigung bei neuen Posts (konfigurierbar)
- Berechtigungen: Admin, Dirigent, Vorstand können Posts erstellen; alle können kommentieren
- Chronologische Sortierung mit gepinnten Posts oben

#### F-VL-09: Umfragen / Abstimmungen
**Priorität:** Should (MS2)  
**User Story:** Als Dirigent möchte ich Umfragen innerhalb der Kapelle erstellen können, damit Entscheidungen (z.B. Repertoire-Auswahl, Terminwahl) demokratisch getroffen werden.  
**Akzeptanzkriterien:**
- Umfrage erstellen mit Frage + 2..n Antwortmöglichkeiten
- Optionen: Einfachauswahl oder Mehrfachauswahl
- Anonyme oder öffentliche Abstimmung (konfigurierbar pro Umfrage)
- Ablaufdatum für Umfragen (optional)
- Live-Auswertung: Ergebnisse als Balkendiagramm sichtbar
- Benachrichtigung bei neuer Umfrage (Push + In-App)
- Berechtigungen: Admin, Dirigent, Vorstand können Umfragen erstellen
- Abgeschlossene Umfragen bleiben als Archiv sichtbar

#### F-VL-10: Aufgabenverwaltung / To-Do-Listen
**Priorität:** Could (MS3)  
**User Story:** Als Vereinsvorstand möchte ich Aufgaben erstellen und Mitgliedern zuweisen können, damit die Organisation von Vereinsaktivitäten (z.B. Festaufbau) koordiniert abläuft.  
**Akzeptanzkriterien:**
- Aufgabe erstellen: Titel, Beschreibung, Fälligkeitsdatum, Priorität
- Zuweisung an ein oder mehrere Mitglieder
- Status-Tracking: Offen → In Bearbeitung → Erledigt
- Aufgabenliste pro Kapelle mit Filter (meine/alle, offen/erledigt)
- Erinnerungen bei anstehenden Fälligkeiten (Push-Benachrichtigung)
- Optional: Aufgaben an Termine koppeln (z.B. "Vor dem Konzert: Bühne aufbauen")
- Berechtigungen: Admin, Dirigent, Vorstand können Aufgaben erstellen und zuweisen

#### F-VL-11: Inventarverwaltung (Instrumente, Equipment)
**Priorität:** Could (MS5)  
**User Story:** Als Vereinsvorstand möchte ich vereinseigene Instrumente und Equipment verwalten können, damit ich den Überblick über Leihinstrumente und Wartungstermine behalte.  
**Akzeptanzkriterien:**
- Inventar-Katalog: Instrument/Equipment mit Bezeichnung, Typ, Seriennummer, Kaufdatum, Zustand
- Zuweisung an Mitglieder (Leihinstrumente)
- Zustandsberichte: Gut / Wartung nötig / In Reparatur / Ausgemustert
- Wartungstermine mit Erinnerung
- Übersicht: Wer hat welches Leihinstrument
- Historie: Alle Zuweisungen und Zustandsänderungen dokumentiert
- Berechtigungen: Admin, Vorstand können Inventar verwalten; Musiker sieht zugewiesene Instrumente

### 2.6 Musikwerkzeuge

#### F-MW-01: Stimmgerät (Tuner)
**Priorität:** Should  
**User Story:** Als Musiker möchte ich mein Instrument mit der App stimmen können.  
**Akzeptanzkriterien:**
- Chromatischer Tuner mit Mikrofon-Eingang
- Frequenz-Erkennung via FFT (Platform Channels zu CoreAudio/Oboe)
- Anzeige: Ton, Cent-Abweichung, Frequenz
- Ziel-Latenz: < 20ms Audio-zu-Anzeige
- Kalibrierung: Kammerton A (Default 442 Hz, konfigurierbar)
- Transposition für Bb/Eb-Instrumente

#### F-MW-02: Echtzeit-Metronom (Sync)
**Priorität:** Should  
**User Story:** Als Dirigent möchte ich einen Taktschlag in Echtzeit an alle Musiker senden.  
**Akzeptanzkriterien:**
- Dirigent startet Metronom mit BPM + Taktart
- Alle Musiker im gleichen Netzwerk sehen den Taktschlag synchron
- **Architektur:** Timestamps statt "jetzt spielen"-Kommandos
- **Clock-Sync:** NTP-ähnliches Protokoll für Geräte-Synchronisation
- **Primär:** WiFi UDP Multicast (< 5ms LAN-Latenz)
- **Fallback:** SignalR WebSocket (für Remote / Internet)
- Visuelle Anzeige: Taktschlag-Indikator, aktuelle BPM
- Audio-Click optional (konfigurierbar pro Gerät)
- Latenz-Kompensation pro Gerät einstellbar

### 2.7 Lehre-Modul

#### F-LM-01: Lehrer-Schüler-Verwaltung
**Priorität:** Could (MS4)  
**User Story:** Als Musiklehrer möchte ich Schülern Noten freischalten und ihren Fortschritt verfolgen.  
**Akzeptanzkriterien:**
- Lehrer erstellt Schüler-Accounts oder lädt bestehende Nutzer ein
- Lehrer schaltet Stücke/Stimmen für Schüler frei
- Schüler sieht nur freigeschaltete Noten
- Fortschritts-Tracking: Welche Stücke geübt/abgeschlossen

#### F-LM-02: Lernpfade
**Priorität:** Could (MS4)  
**User Story:** Als Lehrer möchte ich geführte Abfolgen von Übungen erstellen.  
**Akzeptanzkriterien:**
- Geordnete Sequenz von Stücken/Übungen
- Freischaltung des nächsten Stücks nach Abschluss (oder manuell)
- Optionale Notizen/Anweisungen pro Schritt
- Details: Ausstehend — weitere Eingaben von Thomas

---

## 3. Datenmodell

### 3.1 Kern-Entitäten

```
┌──────────────┐     N:M      ┌──────────────┐
│   Musiker    │◄────────────►│   Kapelle    │
│              │ Mitgliedschaft│              │
│ - id (UUID)  │              │ - id (UUID)  │
│ - name       │              │ - name       │
│ - email      │              │ - ort        │
│ - avatar     │              │ - logo       │
│ - locale     │              │ - config     │
└──────────────┘              └──────────────┘
       │                             │
       │                             │
       ▼                             ▼
┌──────────────┐              ┌──────────────┐
│ Mitgliedschaft│              │    Stück     │
│              │              │              │
│ - musiker_id │              │ - id (UUID)  │
│ - kapelle_id │              │ - titel      │
│ - rollen[]   │              │ - komponist  │
│ - instrumente│              │ - arrangeur  │
│ - std_stimme │              │ - genre      │
│ - aktiv      │              │ - tags[]     │
│ - beigetreten│              │ - kapelle_id │
└──────────────┘              │ - musiker_id │
                              │   (persönl.) │
                              └──────────────┘
                                     │
                                     ▼
                              ┌──────────────┐
                              │   Stimme     │
                              │              │
                              │ - id (UUID)  │
                              │ - stueck_id  │
                              │ - bezeichnung│
                              │ - instrument │
                              │ - sortierung │
                              └──────────────┘
                                     │
                                     ▼
                              ┌──────────────┐
                              │ Notenblatt   │
                              │              │
                              │ - id (UUID)  │
                              │ - stimme_id  │
                              │ - seite_nr   │
                              │ - bild_url   │
                              │ - thumbnail  │
                              │ - rotation   │
                              │ - breite     │
                              │ - hoehe      │
                              └──────────────┘
```

### 3.2 Weitere Entitäten

| Entität | Felder | Beziehungen |
|---------|--------|-------------|
| **Annotation** | id, notenblatt_id, musiker_id, stimme_id, typ (freihand/text/symbol), daten (SVG/JSON), sichtbarkeit (privat/stimme/orchester), erstellt_am | N:1 Notenblatt, N:1 Musiker |
| **Setlist** | id, kapelle_id, name, datum, typ, erstellt_von | N:1 Kapelle |
| **SetlistEintrag** | id, setlist_id, stueck_id, position, notizen | N:1 Setlist, N:1 Stück |
| **Termin** | id, kapelle_id, titel, datum, uhrzeit, ort, typ, setlist_id, beschreibung | N:1 Kapelle, 0..1 Setlist |
| **Teilnahme** | id, termin_id, musiker_id, status (offen/zugesagt/abgesagt), kommentar | N:1 Termin, N:1 Musiker |
| **Schicht** | id, termin_id, bezeichnung, von, bis, bedarf, zugewiesen[] | N:1 Termin |
| **AushilfeLink** | id, kapelle_id, termin_id, stimme_id, token, ablauf_datum, erstellt_von, widerrufen | N:1 Kapelle |
| **Lernpfad** | id, lehrer_id, name, beschreibung, schritte[] | N:1 Musiker (Lehrer) |
| **LernpfadSchritt** | id, lernpfad_id, stueck_id, position, anweisungen, status | N:1 Lernpfad, N:1 Stück |
| **Config** | id, ebene (kapelle/nutzer/geraet), referenz_id, schluessel, wert (JSONB), aktualisiert_am | Polymorphe Referenz |
| **AuditLog** | id, kapelle_id, musiker_id, aktion, entitaet, details, zeitstempel | N:1 Kapelle |

### 3.3 Persönliche Sammlung

Persönliche Noten verwenden die gleichen Entitäten (Stück, Stimme, Notenblatt). Unterscheidung:
- `stueck.kapelle_id = NULL` UND `stueck.musiker_id = {user-id}` → Persönlich
- `stueck.kapelle_id = {kapelle-id}` UND `stueck.musiker_id = NULL` → Kapelle

---

## 4. Rollen & Berechtigungsmatrix

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker | Lehrer | Schüler |
|--------|:-----:|:--------:|:---------:|:--------------:|:-------:|:------:|:-------:|
| Kapelle verwalten | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Mitglieder einladen/entfernen | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Rollen zuweisen | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| AI-Keys verwalten (Kapelle) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Kapellen-Config ändern | ✅ | Teilw. | ❌ | ❌ | ❌ | ❌ | ❌ |
| Noten hochladen (Kapelle) | ✅ | ✅ | ✅ | ❌ | ❌* | ❌ | ❌ |
| Noten bearbeiten/löschen (Kapelle) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Stücke ansehen | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Nur freigesch. |
| Setlist erstellen | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Setlist ansehen | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Annotation (Privat) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Annotation (Stimme) | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ |
| Annotation (Orchester) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Termine erstellen | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Termine zu-/absagen | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Metronom steuern | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Metronom empfangen | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Persönliche Sammlung | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Aushilfe-Link erstellen | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Schüler verwalten | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Lernpfade erstellen | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |

*\* Konfigurierbar: Admin kann Upload-Recht für Musiker freischalten*

---

## 5. API-Architektur

### 5.1 Grundlagen

- **Protokoll:** REST über HTTPS
- **Auth:** JWT (Access + Refresh Token), OAuth2-kompatibel
- **Versionierung:** /api/v1/
- **Pagination:** Cursor-basiert (nicht Offset)
- **Rate Limiting:** Pro User + Pro Kapelle
- **Dateiformat:** JSON (API), multipart/form-data (Uploads)

### 5.2 Endpunkt-Gruppen

| Gruppe | Basis-Pfad | Beschreibung |
|--------|-----------|-------------|
| Auth | `/api/v1/auth` | Login, Register, Refresh, Passwort-Reset |
| Musiker | `/api/v1/musiker` | Profil, Instrumente, Einstellungen |
| Kapellen | `/api/v1/kapellen` | CRUD, Mitglieder, Einladungen |
| Stücke | `/api/v1/kapellen/{id}/stuecke` | CRUD, Stimmen, Notenblätter |
| Setlists | `/api/v1/kapellen/{id}/setlists` | CRUD, Einträge |
| Termine | `/api/v1/kapellen/{id}/termine` | CRUD, Teilnahme |
| Annotationen | `/api/v1/annotationen` | CRUD, Sync |
| Config | `/api/v1/config` | Lesen/Schreiben per Ebene |
| AI | `/api/v1/ai/analyse` | Bild-Analyse, Metadaten-Extraktion |
| Sync | `/api/v1/sync` | Delta-Sync für Offline-Clients |
| Persönlich | `/api/v1/sammlung` | Persönliche Noten-CRUD |

---

## 6. Offline-Strategie

| Daten | Offline-Verfügbar | Sync-Richtung |
|-------|:-----------------:|:-------------:|
| Stücke/Stimmen (heruntergeladen) | ✅ | Server → Client |
| Persönliche Sammlung | ✅ | Bidirektional |
| Annotationen (Privat) | ✅ | Bidirektional (Last-Write-Wins per Feld) |
| Annotationen (Stimme/Orchester) | ✅ (Cache) | Server → Client |
| Setlists | ✅ (Cache) | Server → Client |
| Konfiguration | ✅ (Cache) | Siehe Konfigurationskonzept |
| Termine | ✅ (Cache) | Server → Client, Teilnahme bidirektional |

**Sync-Mechanismus:** Delta-Sync mit Versionszähler pro Entität. Client sendet lokale Änderungen, Server antwortet mit Delta seit letztem Sync.

---

## 7. Sicherheitskonzept

- **Auth:** JWT mit kurzer Laufzeit (15 Min Access, 7 Tage Refresh)
- **Passwort:** bcrypt (min. Cost 12)
- **API-Keys (AI):** AES-256 serverseitig, Platform Secure Storage clientseitig
- **Transport:** TLS 1.3 überall
- **RBAC:** Rollenbasiert pro Kapelle, Server-side Enforcement
- **Aushilfe-Links:** Kryptographisch sichere Token (256-bit), Ablaufdatum, widerrufbar
- **Audit-Log:** Alle sicherheitsrelevanten Aktionen (Login, Rollenwechsel, Config-Änderungen)
- **DSGVO:** Datenexport pro Nutzer, Löschrecht, Consent-Management

---

## 8. Internationalisierung (i18n)

- **Tag 1:** Alle Strings externalisiert — kein Hardcoding
- **Primärsprache:** Deutsch
- **Architektur:** ARB-Dateien (Flutter Standard) + Server-seitige Resource-Bundles
- **Zukunft:** Englisch (MS5), weitere Sprachen community-driven
- **Fallback:** Deutsch als Fallback für fehlende Übersetzungen
- **Konfigurierbar:** Pro Nutzer (Nutzer-Ebene Config), Pro Kapelle (Kapelle-Ebene Default)

---

## 9. Nicht-funktionale Anforderungen

| Anforderung | Zielwert |
|-------------|----------|
| Seitenwechsel im Spielmodus | < 100ms |
| Stift-Latenz (Annotation) | < 50ms |
| App-Start (Cold Start) | < 3s |
| Metronom-Sync (LAN, UDP) | < 5ms |
| Metronom-Sync (Internet, WebSocket) | < 50ms |
| Tuner Audio-zu-Anzeige | < 20ms |
| Upload-Verarbeitung (1 Seite) | < 5s |
| API-Response (95. Perzentil) | < 200ms |
| Offline-Verfügbarkeit | Kern-Funktionen (Spielen, Annotieren) |
| Gleichzeitige Nutzer pro Kapelle | 80+ |
| Barrierefreiheit | WCAG 2.1 AA (Farbe nie alleiniger Indikator) |

---

*Dieses Dokument wird via PR zur Abstimmung vorgelegt. Änderungen erfordern Thomas' Freigabe.*
