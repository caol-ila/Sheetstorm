# 01 — Funktionale Spezifikation

Beschreibt **was** Sheetstorm können soll. Implementierungs­details
siehe Spec 03 (Architektur).

## 1. Identität & Mitgliedschaft

### 1.1 Benutzer­konten
* Self-Service Registrierung mit E-Mail + Passwort, E-Mail-Verifikation
  via Confirmation-Link.
* Optional: Login mit Apple/Google/Microsoft (Phase 2).
* Profil: Anzeige­name, optional Klarname, Avatar, primäres
  Instrument(e), bevorzugte Stimme(n) pro Instrument, Sprache.
* Passwort-Reset über E-Mail-Token.
* Konto­löschung: DSGVO-konform, asynchroner Job.

### 1.2 Rollen­modell
Zwei Achsen: **System-Rollen** (global) und **Verein-Rollen**
(pro Mitgliedschaft).

System-Rollen:
* `User` — normaler Nutzer (Default).
* `SystemAdmin` — Plattform­betrieb (nicht für Endkunden sichtbar).

Verein-Rollen (pro `Membership`):
* `Mitglied` — sieht Bibliothek, lädt Stimmen runter, sieht Termine,
  meldet Anwesenheit.
* `Dirigent` — zusätzlich: Setlist erstellen, Live-Sync starten,
  Probe leiten.
* `Lehrer` — wie Dirigent, plus eigene Schüler-Gruppen verwalten.
* `Admin` — alles + Mitglieder einladen/entfernen, Rollen vergeben,
  Verein konfigurieren, Bibliothek strukturell ändern.
* `Owner` — wie Admin + Verein löschen, Eigentümer­schaft übertragen.

Mehrere Rollen gleichzeitig sind erlaubt (z.B. Admin + Dirigent).

### 1.3 Vereine
* Ein Nutzer kann Mitglied in mehreren Vereinen sein.
* Verein-Stammdaten: Name, kurzer Slug, Logo, Beschreibung,
  Standort (PLZ/Ort, optional Adresse), Verbands­zugehörigkeit
  (Freitext + optional ID).
* Sub-Ensembles (Phase 2): Hauptkapelle, Jugend, Bigband — gleicher
  Verein, getrennte Setlists/Termine.

### 1.4 Beitritt zu einem Verein
Drei Wege:
1. **Direkt-Einladung per E-Mail.** Admin gibt E-Mail an. System
   schickt Einladungs-Link mit Token (24h gültig). Empfänger
   registriert sich oder loggt ein und akzeptiert.
2. **Beitritts­code.** Admin generiert 6–8-stelligen Code mit
   optionalem Ablaufdatum und Max-Verwendungen. Mitglied gibt Code in
   App ein → Beitritt landet als „Pending" beim Admin → Approve/Reject.
3. **Suchen + Anfragen** (Phase 2). Verein als „suchbar" markiert,
   Nutzer findet ihn und stellt Beitritts­anfrage.

Bei Beitritt MUSS Admin Stimme(n) und Rolle zuweisen, bevor
Mitglied volle Bibliotheks­zugriff bekommt. Default-Rolle: `Mitglied`.

### 1.5 Eigene Bibliothek (ohne Verein)
* Jeder Nutzer hat eine **persönliche** Bibliothek. Inhalte dort
  sind privat, nicht teilbar mit Verein.
* Persönliche Bibliothek bleibt erhalten, wenn Verein gewechselt
  wird.

## 2. Notenmanagement

### 2.1 Werk (`Piece`) als zentrale Entität
Ein Werk = ein Musikstück mit Metadaten:
* Titel (Pflicht), Untertitel
* Komponist, Arrangeur, Verlag, Verlagsnummer
* Genre/Stil (Tags), Schwierigkeitsgrad (1–6)
* Tonart, Taktart (mehrere Sätze möglich), Tempo-Hinweise
* Spieldauer
* Frei­text-Notizen
* Cover (auto aus PDF oder Upload)

### 2.2 Stimmen (`Part`) pro Werk
* Pro Werk: Beliebig viele Stimmen (Partitur, Klarinette 1 in B,
  Trompete 2 in B, Posaune 1 in C, Schlagzeug, ...).
* Standardisierte **Stimm-Taxonomie** (Drop-down + Suche), z.B.:
  * Familie: Holz / Blech / Schlagwerk / Sonstige
  * Instrument: Klarinette, Flöte, Saxophon, ...
  * Transposition: B, Es, F, C, ...
  * Register/Lage: 1, 2, 3, Bass, ...
* Eine Stimme hat ein oder mehrere **Files** (PDF Pflicht; optional
  MusicXML, MP3-Demo, MIDI).
* Stimme kann „retired" markiert werden statt gelöscht.

### 2.3 Stimm-Zuordnung zu Musikern
* Pro Mitgliedschaft: bevorzugte Stimme(n) (1..n) pro Instrument.
* Default beim Öffnen eines Werks: bevorzugte Stimme.
* UX: Stimm-Wahl-Dropdown sortiert in dieser Reihenfolge:
  1. Bevorzugte Stimme (markiert)
  2. Alternative Stimmen des Musikers
  3. Andere Stimmen, gruppiert nach Familie

### 2.4 Bibliothek-Sicht
* **Liste/Grid** mit Cover, Titel, Komponist, Tags, Stimmen-Counter.
* **Filter**: Genre, Schwierigkeit, Tonart, Komponist, „Hat meine
  Stimme", „Offline verfügbar".
* **Volltext­suche** (Titel/Komponist/Tags/Notizen).
* **Sortierung**: Titel, Komponist, zuletzt geöffnet, neueste.
* **Sammlungen** (`Collection`): manuell zusammengestellte Listen
  (z.B. „Standard-Repertoire", „Frühschoppen"). Werk kann in
  mehreren Sammlungen sein.

### 2.5 Sets & Playlists
* **Set** = geordnete Liste von Werken für ein konkretes Konzert
  oder eine Probe. Genau ein Stück pro Position; pro Position
  optional Übergangs-Notiz, Tonart-Wechsel-Hinweis.
* **Playlist** = lose, persönliche Liste (z.B. „Üben diese Woche").
  Nicht öffentlich.
* Setlist kann an Termin gekoppelt werden.
* Reihen­folge per Drag & Drop änderbar; Schnell-Sprung im
  Konzert-Modus.

### 2.6 Annotationen
* Pro Stimme + Musiker: persönliche Annotationen (Striche,
  Fingersätze, Notizen).
* Synchronisiert über Geräte des Musikers.
* Optional **„geteilte Annotation"** (Phase 2): Dirigent kann seine
  Striche an alle pushen → bei Musiker als Layer einblendbar.
* Annotation-Daten als Vector-Layer (Pen-Strokes mit Farbe/Stärke,
  Text-Boxen, Stempel).

### 2.7 Digitalisierung / Import
* **Upload-Quellen**: lokal (PDF/Bild/MusicXML), Foto vom Handy,
  IMSLP-Link (Phase 2).
* **OMR-Pipeline** (Audiveris im Backend):
  1. PDF wird in Seiten gesplittet, ggf. entzerrt.
  2. Audiveris erkennt Stimmen-Trennung und Notentext.
  3. Vorgeschlagene Metadaten (Titel, Komponist) per
     Heuristik/LLM aus erster Seite.
  4. UI zeigt Vorschau: Welche Seiten = welche Stimme. User kann
     korrigieren / zusammenführen / splitten.
  5. Speicherung: Original-PDF immer behalten + ggf. MusicXML.
* **Bulk-Import**: Ein PDF mit allen Stimmen → Auto-Split nach
  Stimm-Erkennung, User bestätigt Zuordnung.
* **AI-Tagging**: Genre-Vorschlag, Schwierigkeit, ähnliche Werke.

## 3. Termine

### 3.1 Termin­typen
* **Konzert** — Auftritt, ggf. mit Setlist, Treffpunkt, Outfit-Note.
* **Probe** — regelmäßig wiederholbar, mit Probe-Setlist, Probe-Ort.
* **Arbeitseinsatz** — z.B. „Festle aufbauen", mit Schicht-Slots.
* **Sonstiges** — Ausflug, Versammlung.

### 3.2 Felder
* Titel, Typ, Beschreibung, Ort (mit Karten-Link), Start, Ende,
  Treffpunkt-Zeit (Konzerte: vor Konzertbeginn), Dresscode,
  Verantwortliche, Anhänge (PDFs), gekoppelte Setlist (bei
  Konzert/Probe).
* Wieder­holung (täglich/wöchentlich/Datum-Liste).

### 3.3 Anwesenheit
* Pro Mitglied: Zusage / Absage / Vielleicht / keine Antwort.
* Optional Pflicht-Begründung bei Absage.
* Erinnerungen via Push (X Tage / Stunden vorher konfigurierbar).
* Statistik pro Mitglied (Anwesenheits­quote) für Admin/Dirigent.

### 3.4 Arbeitseinsatz-Schichten
* Pro Termin mehrere Schichten (Auf-/Abbau, Theke, Küche).
* Mitglieder tragen sich in Slots ein. Admin sieht Auslastung,
  kann Einteilungen festlegen.

### 3.5 Kalender-Integration
* iCal-Feed pro Mitgliedschaft (mit Token-URL).
* Jedes Mitglied kann Termine eines Vereins exportieren.

## 4. Live-Conductor-Sync

Detaillierte Sicherheits- und Protokoll-Spec siehe **05**.

### 4.1 Anwendungsfall
1. Dirigent öffnet Sheetstorm im Probe/Konzert-Modus, wählt Set.
2. Dirigent öffnet ein Stück. Sheetstorm broadcastet Event über
   BLE.
3. Musiker-Geräte in Reichweite empfangen. Bei Übereinstimmung mit
   konfiguriertem Dirigenten-Schlüssel:
   * Pop-up: „Dirigent öffnet *Marsch der Bayrischen Volkspartei*.
     [Stimme öffnen ▾]" mit vor-ausgewählter bevorzugter Stimme.
   * Optional Auto-Open ohne Bestätigung (Konfiguration je Musiker).
4. Auto-Page-Turn (Phase 2): Dirigent blättert → Musiker werden
   nicht zwangs­geblättert (zu invasiv), aber bekommen Indikator.

### 4.2 Sicherheit
* Pro **Event** generiert Dirigent ein Schlüssel­paar (siehe Spec 05).
* Public Key wird vorab über Sheetstorm-Backend an Mitglieder
  verteilt (vor Beginn des Events).
* BLE-Broadcasts werden mit Private Key signiert; Empfänger
  verwirft alle Broadcasts ohne gültige Signatur → kein Stören
  durch Fremde im Festzelt.

### 4.3 Plattform-Realität
* **Android, Windows, macOS, ChromeOS**: Web Bluetooth in
  Chromium-PWA → funktioniert.
* **iOS/iPadOS**: Kein Web Bluetooth. Lösung:
  * Phase 1: Polling-Fallback über Backend (WiFi/Mobilfunk
    nötig). Latenz 1–3s, akzeptabel im Konzertkontext.
  * Phase 2: Native iOS-Companion-App (oder Capacitor-Wrapper)
    nur für BLE-Empfang.

## 5. Hardware-Pedal

### 5.1 Funktion
Foot-Pedal (AirTurn PED, PageFlip Cicada, BT-500, generische
HID-Pedale) als Eingabe für:
* Vor-/Zurück-Blättern in Stimme
* Nächstes/voriges Stück in Setlist
* Performance-Mode an/aus

### 5.2 Anbindung
* **Bevorzugt**: Pedal im Bluetooth-HID-Keyboard-Modus → Browser
  empfängt Tasten­anschlag wie normale Tastatur. Funktioniert auf
  allen Plattformen inkl. iOS Safari.
* **Erweitert**: Web HID API direkt, wenn verfügbar (Chrome/Edge
  Desktop+Android), für Custom-Modes und Feedback.
* Pedal-Bindings konfigurierbar pro Nutzer.

## 6. Offline-Fähigkeit

### 6.1 Was offline funktioniert
* Alle als „offline verfügbar" markierten Werke + Stimmen + PDFs.
* Aktuelle Setlist + nächste 14 Tage Termine.
* Eigene Annotationen.

### 6.2 Was online braucht
* Bibliotheks-Discovery / Suche neuer Werke.
* OMR-Import.
* Live-Conductor-Sync.
* Termin-Anwesenheits­änderungen (queued, sync später).

### 6.3 Sync-Strategie
* Offline-Änderungen (Annotationen, Anwesenheit, Notizen) lokal
  versioniert (Last-Write-Wins per Element-ID + Timestamp).
* Bei Reconnect: Server hat letzte Wahrheit, Konflikte über UI
  zeigen.

## 7. Such- und Notification-System

### 7.1 Suche
* Volltext über Werke, Komponisten, Tags, Termine.
* Pro Verein gescoped, plus persönliche Bibliothek.

### 7.2 Push-Benachrichtigungen
* Web-Push (PWA) und ggf. native APN/FCM in Phase 2.
* Trigger: Termin-Erinnerung, Beitritts-Approval-Antwort,
  Dirigent fragt Anwesenheit ab, neues Werk im Set, Mention im
  Kommentar.

## 8. Mehrsprachigkeit
* Default DE.
* i18n via ICU-Message-Format vorbereitet.
* Phase 2: EN, FR, IT.

## 9. Barrierefreiheit
* WCAG 2.2 AA als Ziel.
* Bedienbar mit Tastatur, Screen-Reader-Labels, ausreichende
  Kontraste, kein „nur Farbe" für Status.
* Notenanzeige: Zoom + invertierter Modus für Bühnenbeleuchtung.

## 10. Metronom & Sync-Click
* Jeder Musiker hat ein eigenes Metronom; der Dirigent kann einen
  synchronen Click an alle verbundenen Geräte schicken (max. 50 ms Drift).
* Tempo + Taktart werden aus dem aktuell geöffneten Stück übernommen,
  manuelle Eingabe + Tap-Tempo bleiben möglich.
* Schnell-Buttons: 100 % / −10 % / −20 %.
* Akzent auf Schlag 1 + optionale Subdivision (8tel/16tel).
* Übertragung primär WLAN-Multicast + signed Schedule (HMAC), Fallback
  BLE-Advertising. Zeitbasis via NTP-light beim Pairing.
* Spec: [10-metronom-and-sync-click.md](10-metronom-and-sync-click.md).

## 11. Stimmen / Tuner
* Mikrofon-Tuner mit konfigurierbarer Grundstimmung (Default 442 Hz,
  per Verein und per Event überschreibbar).
* Berücksichtigt Temperierung (gleichstufig / rein / pythagoreisch) und
  Instrumenten-Profile mit Griff-spezifischen Cent-Abweichungen
  (z. B. Tenorhorn Ventil 1+3 vs. 4).
* UI ohne Wackel-Zeiger: diskrete Zonen `−− / − / (−) / ✓ / (+) / + / ++`,
  Hysterese ≥ 300 ms, sachliche Klartext-Hinweise ("etwas weiter rein").
* Spec: [11-tuning-mode.md](11-tuning-mode.md).

## 12. Visualisierung & Datei-Strategie
* Default-Anzeige ist die **MusicXML-Version** (OSMD-SVG).
* Alternativ pro Lied/Stimme **Bild-Modus** mit aus dem PDF extrahierten
  PNGs (1 pro Seite, ~150 dpi).
* Das **Original-PDF wird nie in der App angezeigt**, sondern nur
  archiviert und (genehmigungspflichtig) zum Download angeboten.
* Annotationen werden pro Seite gespeichert und liegen sowohl über dem
  Score-SVG als auch über dem Image stabil, weil die Koordinaten in
  0..1 normiert sind.
* Pro Verein konfigurierbar, ob Mitglieder PDFs herunterladen dürfen
  (Default: nein).
* Spec: [12-visualization-and-file-strategy.md](12-visualization-and-file-strategy.md).
