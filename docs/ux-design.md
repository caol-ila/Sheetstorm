# UX-Design: Sheetstorm — Notenmanagement für Blaskapellen

> **Version:** 2.0
> **Status:** Entwurf — Review ausstehend
> **Autorin:** Wanda (UX Designer)
> **Datum:** 2026-03-28
> **Meilenstein:** M1 — Kern: Noten & Kapelle
> **Referenzen:** `docs/anforderungen.md`, `docs/ux-research-konkurrenz.md`, `docs/spezifikation.md`

---

## Inhaltsverzeichnis

1. [Design-Prinzipien](#1-design-prinzipien)
2. [User Personas](#2-user-personas)
3. [Screen Flows & Wireframes](#3-screen-flows--wireframes)
   - 3.1 Spielmodus / Performance View
   - 3.2 Noten-Import
   - 3.3 Bibliothek
   - 3.4 Setlist
   - 3.5 Kapellenverwaltung
   - 3.6 Vereinsleben / Kalender
   - 3.7 Annotationen
   - 3.8 Tuner
4. [Navigation & Informationsarchitektur](#4-navigation--informationsarchitektur)
5. [Responsive Breakpoints](#5-responsive-breakpoints)
6. [Interaction Patterns](#6-interaction-patterns)
7. [Design Tokens](#7-design-tokens)

---

## 1. Design-Prinzipien

### 1.1 Focus-First — Musiker müssen sich auf die Noten konzentrieren können

> „Ein Musiker auf der Bühne hat keine Hand frei. Er hat keine Zeit für Menüs."

Der Performance-Modus ist der wichtigste Modus der App. Alles andere ist Support-Funktionalität. UI-Elemente, die nicht zum aktiven Spielen beitragen, **verschwinden** im Spielmodus. Sie treten erst wieder auf, wenn der Musiker sie aktiv anfordert — durch Tippen in die Bildschirmmitte oder durch Wischen vom Rand.

**Konsequenzen:**
- Navigation verschwindet im Spielmodus vollständig
- Bottom-Bar hat keine animierten Badges oder Pulseffekte
- Benachrichtigungen während des Spielens werden stumm gesammelt, nie als Pop-up gezeigt
- Hintergrundsynchronisation läuft ohne sichtbares Feedback

### 1.2 Touch-Native — Alles muss mit Handschuhen bedienbar sein

Blaskapellen spielen bei Festumzügen bei jedem Wetter. Einige Musiker nutzen Handschuhe. Touch-Targets sind daher **nie kleiner als 44×44 px** — im Spielmodus sogar **mindestens 64×64 px** für Seitenwechsel.

**Konsequenzen:**
- Primäre Aktionen im Spielmodus: rechte und linke Hälfte des Bildschirms als Tap-Zone
- Keine Hover-Zustände als primäre UX (Hover ist Enhancement, nicht Requirement)
- Swipe-Gesten müssen robust gegen versehentliche Eingaben sein (Threshold ≥ 40px)
- Stift (Apple Pencil / S-Pen) und Finger werden unterschiedlich behandelt

### 1.3 Responsive — Gleiche App auf allen Geräten, optimiert für den Kontext

| Gerät | Hauptkontext | Primäre Funktion |
|-------|-------------|-----------------|
| Phone (< 600px) | Unterwegs, Probe, Verwaltung | Setlist abrufen, Zu-/Absage, Noten lesen |
| Tablet (600–1024px) | Auftritt, Probe | Noten lesen, Annotieren, Spielmodus |
| Desktop/Browser (> 1024px) | Verwaltung | Import, Bibliothek, Verwaltung, Admin |

Diesel selbe App läuft auf allen Plattformen — mit kontextgerechten Layout-Anpassungen, nicht mit separaten Apps.

### 1.4 Accessibility — Bühnenbeleuchtung und Lesedistanz

Proben finden oft in schlechtem Licht statt. Auftritte unter Bühnenscheinwerfern (Blendung). Musiker lesen Noten aus 40–80 cm Abstand.

**Konsequenzen:**
- Mindestkontrast: **WCAG 2.1 AA** überall, **AAA** im Spielmodus
- Schriftgrößen: Mindestens 16sp für Texte außerhalb des Notenblatts
- **Nacht-/Bühnenmodus:** Schwarzer Hintergrund, weiße Noten, gedimmte UI — schützt die Nachtsicht des Auges
- **Sepia-Modus:** Papier-ähnlich, reduziert Augenermüdung bei langen Proben
- Farbblindheit: Annotationsebenen nie nur durch Farbe unterscheidbar — immer zusätzlich durch Icon/Muster

### 1.5 Progressive Disclosure — Komplexität erst zeigen, wenn sie gebraucht wird

Sheetstorm kann sehr komplex werden (3-Ebenen-Annotationen, AI-Import, Multi-Kapellen-Verwaltung). Diese Komplexität darf aber nicht beim ersten Start überwältigend sein.

**Konsequenzen:**
- Onboarding: Maximal 5 Fragen (→ Sektion 3.8)
- Erweiterte Einstellungen immer hinter „Mehr…" oder in einer sekundären Ebene
- Admin-Features nur für Nutzer mit entsprechender Rolle sichtbar
- AI-Features mit Fallback auf manuelle Eingabe — nie als Blocker

---

## 2. User Personas

### 2.1 Dirigent — Klaus, 54

**Kontext:** Probt zweimal wöchentlich mit 45 Musikern. Nutzt ein iPad (12,9"). Führt während der Probe auf dem Podium gleichzeitig Taktstock und will mit dem anderen Arm Annotationen eintragen.

**Ziele:**
- Annotationen (Dirigier-Anweisungen) an alle Musiker gleichzeitig übermitteln
- Setlist für das nächste Konzert in 10 Minuten zusammenstellen
- Sofortige Übersicht: Wer kommt zur Generalprobe?
- Dirigenten-Layer-Annotationen: soll sehen, ob seine Hinweise ankommen

**Frustrationen:**
- Tippen auf kleine Felder mit großen Fingern
- Synchronisation, die zu langsam ist — während die Probe läuft
- Zu viele Bestätigungsdialoge

**UX-Implikationen:**
- Dirigenten-Layer prominenter Zugang im Annotationsmodus
- Echtzeit-Anwesenheitsübersicht als Dashboard-Widget
- Setlist-Drag&Drop optimiert für große Finger

---

### 2.2 Musiker (Probe) — Anna, 28

**Kontext:** Spielt 2. Klarinette. Nutzt ein Android-Tablet (10"). Probe donnerstags abends. Hat ihren Notenstapel kürzlich digitalisiert.

**Ziele:**
- Eigene Stimme automatisch angezeigt bekommen
- Private Annotationen setzen (Atemzug, Fingersatz, Taktzählung)
- Setlist der heutigen Probe auf einen Blick sehen

**Frustrationen:**
- „Wo ist meine Stimme?" — falsche Stimme wird angezeigt
- Annotationen vom letzten Mal fehlen
- App lädt beim Start der Probe noch

**UX-Implikationen:**
- Automatische Stimmen-Vorauswahl mit visuellem Hinweis „Deine Stimme: 2. Klarinette"
- Offline-First: Noten und Annotationen müssen lokal verfügbar sein
- Schnellzugriff auf aktuelle Probe-Setlist auf dem Homescreen

---

### 2.3 Musiker (Auftritt) — Marco, 22

**Kontext:** Spielt Trompete. Nutzt ein Smartphone (6,1") am Ständer oder ein Tablet. Steht vor dem Publikum. Kein Stativ-Mikrofonständer mit Klemme → hält das Tablet in der Hand oder stellt es auf einen Notenständer.

**Ziele:**
- Noten vollständig und groß sehen
- Seiten umblättern ohne abzusetzen (Fußpedal oder Bluetooth)
- Nichts anklicken müssen — nur spielen

**Frustrationen:**
- Seitenwechsel bricht den Spielfluss (Page-Jump-Schock)
- Bildschirm wird dunkel
- Versehentliches Tippen öffnet Menüs

**UX-Implikationen:**
- Half-Page-Turn als Standard
- Bildschirm-Timeout deaktiviert im Spielmodus
- UI-Lock im Spielmodus: Nur definierte Tap-Zonen wirken

---

### 2.4 Notenwart — Brigitte, 61

**Kontext:** Verwaltet seit 15 Jahren die Noten der Kapelle. Hat 400 Stücke in Papierform, davon 120 bereits digitalisiert. Nutzt primär den Desktop-Browser.

**Ziele:**
- Neue Stücke hochladen, beschriften, Stimmen zuordnen
- Den Notenbestand durchsuchen und pflegen
- Aushilfen schnell Zugang geben ohne IT-Aufwand

**Frustrationen:**
- Stücke hochladen dauert ewig und ist fehleranfällig
- Metadaten manuell eintippen für 400 Stücke ist keine Option
- „Schreib mir eine E-Mail mit dem PDF" ist keine Lösung mehr

**UX-Implikationen:**
- AI-gestützter Import als primärer Weg (nicht als Premium-Feature)
- Bulk-Import mit Labeling-Workflow (Thumbnails durchklicken)
- Aushilfen-Link: 3 Klicks, fertig

---

### 2.5 Admin / Vorstand — Rudi, 48

**Kontext:** Geschäftsführer des Vereins. Zuständig für Mitgliederverwaltung, Rollen, Lizenzen, Datenschutz. Nutzt Desktop und Smartphone.

**Ziele:**
- Mitgliederverwaltung: einladen, Rollen vergeben, entfernen
- AI-API-Key für die gesamte Kapelle konfigurieren
- Datenschutz-konformer Betrieb sicherstellen
- Anwesenheitsstatistiken für Jahresbericht

**Frustrationen:**
- Keine klare Übersicht, wer welche Rechte hat
- Jede Einstellung an einem anderen Ort

**UX-Implikationen:**
- Kapellen-Dashboard mit Handlungsbedarf (fehlende Profile, ablaufende Lizenzen)
- Klare Berechtigungsübersicht pro Mitglied
- Admin-Bereich nur für Admins sichtbar

---

### 2.6 Lehrer — Monika, 39

**Kontext:** Gibt Klarinetten-Unterricht im Verein. Nutzt Tablet.

**Ziele:**
- Übungsblätter für Schüler freischalten
- Lernpfade erstellen (Stück 1 → Stück 2 → Stück 3)
- Fortschritt der Schüler verfolgen

**Frustrationen:**
- Noten per E-Mail schicken ist ineffizient
- Kein Überblick, was Schüler bereits geübt haben

**UX-Implikationen:**
- Lehre-Modul als eigenständige Sektion (nicht mit Kapellen-Noten vermischt)
- Einfaches Freischalten: Stück auswählen → Schüler auswählen → Freischalten

---

### 2.7 Schüler — Tim, 14

**Kontext:** Lernt Trompete seit 2 Jahren. Nutzt Smartphone oder Tablet zu Hause und beim Unterricht.

**Ziele:**
- Zugewiesene Übungsstücke finden und spielen
- Fortschritte sehen
- „Was soll ich diese Woche üben?"

**Frustrationen:**
- App zu komplex für Einsteiger
- Kapellen-Verwaltungsfeatures verwirren

**UX-Implikationen:**
- Schüler-Ansicht: vereinfachtes Interface, nur Lernpfad-relevante Inhalte
- Gamification-Potenzial: Stück abgehakt, Fortschrittsbalken

---

## 3. Screen Flows & Wireframes

### 3.1 Spielmodus / Performance View

**Trigger:** Aus Setlist oder Bibliothek auf „Spielen" tippen. Aus dem Spielmodus heraus Stücke wechseln.

**Designprinzip:** Das Notenblatt ist der Bildschirm. UI existiert nicht — bis der Musiker es braucht.

#### Vollbild-Notenansicht (Phone, Hochformat)

```
┌─────────────────────────────┐
│                             │ ← 0px Padding, 100% Höhe
│                             │
│     N  O  T  E  N  B  L  A  T  T      │
│                             │
│     (PDF-Rendering, Auto-   │
│      Zoom auf Seitenbreite) │
│                             │
│                             │
│◄──────────┤├──────────────►│
│ Tap-Zone  ││  Tap-Zone     │
│ (zurück)  ││  (weiter)     │
│           ││               │
│  ~40% B.  ││  ~60% B.     │
└─────────────────────────────┘
  Status-Bar über System-Overlay
```

**Tap-Zonen:**
- Links 40%: Vorherige Seite
- Rechts 60%: Nächste Seite (bewusst asymmetrisch — rechts häufiger)
- Mitte (Tap): Overlay ein-/ausblenden

#### Overlay bei Tap in die Mitte

```
┌─────────────────────────────┐
│ ← Zurück    Stück 3/12  ⚙  │ ← Obere Leiste (44px hoch)
├─────────────────────────────┤
│                             │
│     N  O  T  E  N  B  L  A  T  T      │
│                             │
│         [halbtransparent]   │
│                             │
├─────────────────────────────┤
│ 🎵 Stimme  🌙  🔒 Sperren  │ ← Untere Leiste (44px hoch)
└─────────────────────────────┘
```

**Obere Leiste:**
- `← Zurück` → zurück zur Setlist/Bibliothek (mit Bestätigung wenn im Auftritt-Modus)
- `Stück 3/12` → Tap öffnet Setlist-Schnellnavigation
- `⚙` → Kontextuelle Einstellungen (Helligkeit, Nachtmodus, Layer-Toggle, Half-Page-Turn)

**Untere Leiste:**
- `🎵 Stimme` → Stimme wechseln (nur eigene Instrumente + andere) — Drop-up-Sheet
- `🌙` → Nacht-/Bühnenmodus ein-/ausschalten
- `🔒 Sperren` → Spielmodus sperren: UI-Lock aktivieren, nur definierte Tap-Zonen wirken

#### Half-Page-Turn (Hochformat)

```
┌──────────────────────┐
│  SEITE 2             │ ← obere Hälfte: aktuelle Seite (zweite Hälfte)
│  (untere Hälfte)     │
│  — — — — — — — — —  │ ← subtile Trennlinie
│  SEITE 3             │ ← untere Hälfte: nächste Seite (erste Hälfte)
│  (obere Hälfte)      │
└──────────────────────┘
```

**Aktivierung:** Standard im Hochformat. Umschaltbar per Kontextmenü oder Einstellung.

#### Zwei-Seiten-Modus (Tablet, Querformat)

```
┌─────────────┬─────────────┐
│             │             │
│  SEITE 2    │   SEITE 3   │
│             │             │
│             │             │
│◄────────────┼────────────►│
│  Tap-Zone   │  Tap-Zone   │
└─────────────┴─────────────┘
```

#### Nacht-/Bühnenmodus

```
┌─────────────────────────────┐
│                             │
│  [SCHWARZER HINTERGRUND]    │
│                             │
│  ████████████████████████   │ ← Noten in Weiß/Hellgrau
│  ███     ███████    █████   │   invertiert oder direkt
│  ███ █   ███████ █  █████   │   dunkel auf schwarz
│  ████████████████████████   │
│                             │
│  [Minimale UI, gedimmt]     │
└─────────────────────────────┘
```

**Hinweis:** Nachtmodus invertiert nicht einfach die Farben — er rendert Noten auf schwarzem Grund für maximalen Kontrast ohne Blendung.

#### Stimme wechseln (Bottom Sheet)

```
┌─────────────────────────────┐
│  Stimme wechseln      ✕    │
├─────────────────────────────┤
│  MEINE INSTRUMENTE          │
│  ✓ 2. Klarinette  ●─────── │ ← Aktuell ausgewählt
│    1. Klarinette            │
│    Klarinette in B          │
├─────────────────────────────┤
│  ANDERE STIMMEN             │
│    Trompete 1               │
│    Trompete 2               │
│    Flügelhorn               │
│    ...                      │
└─────────────────────────────┘
```

#### Fußpedal-Support

Bluetooth-Fußpedal (MIDI-CC oder HID-Tastatur-Emulation) wird automatisch erkannt. Im Spielmodus:
- **Rechts-Pedal:** Nächste Seite / Half-Page-Turn vorwärts
- **Links-Pedal:** Vorherige Seite / Half-Page-Turn zurück

---

### 3.2 Noten-Import

**Trigger:** „+" in der Bibliothek → „Noten importieren"

#### Schritt 1: Quelle wählen

```
┌─────────────────────────────┐
│  ← Bibliothek               │
│  Noten importieren          │
├─────────────────────────────┤
│                             │
│  📷  Kamera-Scan            │
│      Seiten direkt         │
│      fotografieren          │
│                             │
│  📁  Dateien                │
│      PDF, Bild von Gerät   │
│                             │
│  ☁️  Cloud                  │
│      Dropbox, OneDrive,    │
│      Google Drive, iCloud   │
│                             │
│  📧  Link / E-Mail          │
│      URL oder geteilte     │
│      Datei                  │
│                             │
└─────────────────────────────┘
```

#### Schritt 2: Labeling — Thumbnails durchklicken

**Kontext:** Eine hochgeladene Datei kann mehrere Lieder enthalten.

```
┌─────────────────────────────────────────┐
│  ← Importieren      Seiten: 8/8 ✓      │
│  Stücke erkennen                        │
├─────────────────────────────────────────┤
│  Tippe "Neues Stück" um Stücke zu       │
│  trennen — oder AI erkennt automatisch  │
├──────────────┬──────────────────────────┤
│  [Seite 1]   │  [Seite 2]   [Seite 3]  │
│  ████████    │  ████████    ████████   │
│  Stück 1     │  Stück 1 ↗  Stück 1    │
│              │                          │
│  [Seite 4]   │  [Seite 5]   [Seite 6]  │
│  ████████    │  ████████    ████████   │
│ [NEU] Stück2 │  Stück 2     Stück 2   │
│              │                          │
│  [Seite 7]   │  [Seite 8]              │
│  ████████    │  ████████               │
│  [NEU] Stück3│  Stück 3               │
└──────────────┴──────────────────────────┘
│         [Weiter: Metadaten →]           │
└─────────────────────────────────────────┘
```

**Interaktion:**
- Thumbnail antippen → markiert als „Neues Stück beginnt hier"
- Erneut antippen → zurück zu vorherigem Stück
- AI-Vorschläge werden farbig hinterlegt (Konfidenz-Farbskala)
- Zoom: Pinch-to-Zoom auf Thumbnail

#### Schritt 3: Metadaten (KI-unterstützt)

```
┌─────────────────────────────┐
│  ← Labeling     Stück 1/3  │
│  Metadaten                  │
├─────────────────────────────┤
│  🤖 KI hat erkannt:         │
│                             │
│  Titel     [Böhmischer Trau │
│            m             ✏️]│
│                             │
│  Interpret [Karl Komzák    ]│
│                             │
│  Stimme    [2. Klarinette  ]│
│                             │
│  Genre     [Polka     ▼    ]│
│                             │
│  Tonart    [B♭        ▼    ]│
│                             │
│  ┌────────────────────────┐ │
│  │ + Weiteres Feld        │ │ ← Progressive Disclosure
│  └────────────────────────┘ │
├─────────────────────────────┤
│  [← Zurück]  [Weiter →]    │
└─────────────────────────────┘
```

**Hinweis:** KI-erkannte Felder sind vorausgefüllt. Konfidenz < 80%: Feld gelb markiert, Nutzer zur Bestätigung eingeladen.

#### Schritt 4: Stimmen zuordnen

```
┌─────────────────────────────┐
│  ← Metadaten    Stück 1/3  │
│  Stimmen zuordnen           │
├─────────────────────────────┤
│  Welche Stimmen enthält     │
│  dieses Stück?              │
│                             │
│  KI hat erkannt:            │
│  ┌─────────────────────┐    │
│  │ Seiten 1-2: 1. Klar.│    │
│  │ Seiten 3-4: 2. Klar.│    │
│  │ Seiten 5-6: Flöte 1 │    │
│  └─────────────────────┘    │
│                             │
│  [✓ Bestätigen]  [Bearbeit.]│
├─────────────────────────────┤
│  + Weitere Stimme hinzufügen│
└─────────────────────────────┘
```

#### Schritt 5: Review & Abschluss

```
┌─────────────────────────────┐
│  ← Stimmen     Stück 1/3   │
│  Alles korrekt?             │
├─────────────────────────────┤
│  ✅ Böhmischer Traum        │
│     Karl Komzák · Polka     │
│     3 Stimmen (6 Seiten)    │
│                             │
│  ⚠️ Märchenwalzer           │
│     Komponist: unbekannt   │
│     → Bitte ausfüllen      │ ← Warnung, kein Blocker
│                             │
│  ✅ Alte Kameraden          │
│     C. Teike · Marsch       │
│     4 Stimmen (8 Seiten)    │
├─────────────────────────────┤
│      [✓ Importieren]        │
└─────────────────────────────┘
```

---

### 3.3 Bibliothek

**Trigger:** „Bibliothek"-Tab

#### Bibliothek — Phone

```
┌─────────────────────────────┐
│  Bibliothek          🔍  + │
├─────────────────────────────┤
│  [Kapelle ▼] [Persönlich ▼]│ ← Filter-Chips
│  [Genre ▼]  [Stimme ▼]     │
├─────────────────────────────┤
│  Zuletzt gespielt           │
│  ──────────────────────     │
│  🎵 Böhmischer Traum        │
│     Polka · 2. Klarinette   │
│                        ▶   │
│  🎵 Alte Kameraden          │
│     Marsch · 2. Klarinette  │
│                        ▶   │
│                             │
│  Alle Stücke (A–Z)          │
│  ──────────────────────     │
│  🎵 Auf der Vogelwiese      │
│  🎵 Böhmischer Traum        │
│  🎵 Der Donauwalzer         │
│  🎵 Feuerwehrmarsch         │
│  🎵 ...                     │
└─────────────────────────────┘
│ [Bibliothek] [Setlists] ... │
```

#### Bibliothek — Tablet (Split-View)

```
┌─────────────────────┬───────────────────────────┐
│  Bibliothek    🔍 + │  Böhmischer Traum          │
├─────────────────────┤  Karl Komzák               │
│  [Kapelle][Pers.]   │  ─────────────────────     │
├─────────────────────┤  STIMMEN                    │
│  📂 Polka (23)      │  ✓ 2. Klarinette  [▶]     │
│  📂 Marsch (31)     │    1. Klarinette  [▶]     │
│  📂 Walzer (18)     │    Flügelhorn 1   [▶]     │
│  ─────────────────  │    ...                     │
│  🎵 Böhm. Traum  ● │  DETAILS                   │
│  🎵 Alte Kamera.    │  Genre: Polka              │
│  🎵 Auf d. Vogel.   │  Tonart: B♭               │
│  🎵 Der Donau.      │  Seiten: 4 (2. Klar.)     │
│  ...                │                            │
│                     │  [▶ Spielen]               │
│                     │  [✎ Annotieren]            │
│                     │  [⋯ Mehr…]                │
└─────────────────────┴───────────────────────────┘
```

#### Suche

```
┌─────────────────────────────┐
│  🔍 "trompete pol..."       │ ← Tippen öffnet sofort Ergebnisse
├─────────────────────────────┤
│  STÜCKE                     │
│  🎵 Böhmischer Traum Polka  │ ← Highlight: Match fett
│  🎵 Holzhackerbub Polka     │
│                             │
│  STIMMEN                    │
│  🎸 Trompete 1 (3 Stücke)  │
│  🎸 Trompete 2 (3 Stücke)  │
│                             │
│  KAPELLEN                   │
│  🏛 Musikkapelle Beispiel   │
└─────────────────────────────┘
```

---

### 3.4 Setlist

#### Setlist-Übersicht

```
┌─────────────────────────────┐
│  Setlists                +  │
├─────────────────────────────┤
│  AKTIV                      │
│  ┌─────────────────────┐    │
│  │ 🎵 Konzert 1. Mai   │    │
│  │ 12 Stücke · 47 min  │    │
│  │ [▶ Spielen starten] │    │ ← Prominenter CTA
│  └─────────────────────┘    │
│                             │
│  ALLE SETLISTS              │
│  🎵 Konzert 1. Mai    ⋯    │
│  🎵 Probe KW15        ⋯    │
│  🎵 Herbstkonzert     ⋯    │
│  🎵 Sommerfest        ⋯    │
└─────────────────────────────┘
```

#### Setlist-Detail mit Drag&Drop

```
┌─────────────────────────────┐
│  ← Setlists  Konzert 1.Mai  │
│                    [▶ Start]│
├─────────────────────────────┤
│  Dauer: 47 min  12 Stücke   │
├─────────────────────────────┤
│  ≡  1. Böhmischer Traum  3:30│← ≡ = Drag-Handle
│  ≡  2. Alte Kameraden    4:00│
│  ≡  3. [Platzhalter]     —  │← Noch nicht zugeordnet
│  ≡  4. Der Donauwalzer   5:15│
│  ≡  5. ...                  │
│                             │
│  [+ Stück hinzufügen]       │
└─────────────────────────────┘
```

#### Setlist-Schnellnavigation im Spielmodus

```
┌─────────────────────────────┐
│  Konzert 1. Mai    ✕       │
├─────────────────────────────┤
│  ▶  1. Böhmischer Traum    │ ← Aktuell gespielt
│     2. Alte Kameraden       │
│     3. Platzhalter          │
│     4. Der Donauwalzer      │
└─────────────────────────────┘
```

---

### 3.5 Kapellenverwaltung

**Zugänglich über:** Profil-Tab → Kapelle verwalten (nur für Admins/Dirigenten)

#### Kapellen-Dashboard (Desktop)

```
┌────────────────────────────────────────────────────────┐
│  SHEETSTORM              Musikkapelle Beispiel  ▼  👤  │
├──────────────┬─────────────────────────────────────────┤
│              │  🏛 Kapellen-Dashboard                  │
│  📚 Biblio.  │  ──────────────────────────────────     │
│  🎵 Setlists │  HANDLUNGSBEDARF                        │
│  📅 Kalender │  ⚠️ 3 Mitglieder ohne Instrumente       │
│  👥 Mitglieder│  ⚠️ AI-API-Key läuft in 12 Tagen ab   │
│  ⚙ Einstellg.│  ℹ️ 2 Stücke ohne Stimmen-Zuordnung    │
│              │  ──────────────────────────────────     │
│  ADMIN       │  STATISTIKEN                            │
│  👑 Kapelle  │  45 Mitglieder · 312 Stücke            │
│  🔑 Lizenzen │  82% Probe-Beteiligung (Ø 90T)         │
│  📊 Analytics│  Letzter Upload: 2026-03-28             │
│              │  ──────────────────────────────────     │
│              │  LETZTE AKTIVITÄTEN                     │
│              │  📥 Brigitte hat 3 Stücke importiert    │
│              │  👤 Neues Mitglied: Sebastian M.        │
│              │  ✅ Probe: 38 von 45 zugesagt           │
└──────────────┴─────────────────────────────────────────┘
```

#### Mitgliederverwaltung

```
┌─────────────────────────────────────────────────────────┐
│  👥 Mitglieder  [+ Einladen]  🔍                        │
├─────────────────────────────────────────────────────────┤
│  Filter: [Alle ▼]  [Register ▼]  [Rolle ▼]              │
├────────────┬──────────────┬────────────────┬────────────┤
│  Name      │  Instrumente │  Rolle         │  Aktionen  │
├────────────┼──────────────┼────────────────┼────────────┤
│  Anna M.   │  Klarinette  │  Musiker       │  ✏️  ⋯    │
│  Marco F.  │  Trompete    │  Musiker       │  ✏️  ⋯    │
│  Brigitte S│  —           │  Notenwart     │  ✏️  ⋯    │
│  Klaus D.  │  —           │  Dirigent      │  ✏️  ⋯    │
│  Rudi K.   │  Tenorhorn   │  Admin         │  ✏️  ⋯    │
└────────────┴──────────────┴────────────────┴────────────┘
```

#### Einladungsflow

```
[+ Einladen] →

┌─────────────────────────────┐
│  Mitglied einladen          │
├─────────────────────────────┤
│  E-Mail oder Telefon:       │
│  [anna@example.com        ] │
│                             │
│  Rolle:  [Musiker      ▼]  │
│                             │
│  Nachricht (optional):      │
│  [                        ] │
│                             │
│  [Einladung senden]         │
├─────────────────────────────┤
│  Oder: Einladungslink       │
│  [Link kopieren]            │
│  Gültig 7 Tage              │
└─────────────────────────────┘
```

---

### 3.6 Vereinsleben / Kalender

#### Kalender-Übersicht (Phone)

```
┌─────────────────────────────┐
│  April 2026          ◄  ►  │
├─────────────────────────────┤
│  Mo Di Mi Do Fr Sa So       │
│  30 31  1  2  3  4  5       │
│        ●        ●           │ ← ● = Termin
│   6  7  8  9 10 11 12       │
│            ●        ●       │
│  13 14 15 16 17 18 19       │
│               ●●   ●        │
│  ...                        │
├─────────────────────────────┤
│  NÄCHSTE TERMINE            │
│                             │
│  📅 Do, 9. Apr — Probe      │
│     19:30 · Probenraum      │
│     38 zugesagt · 7 offen   │
│     [✓ Zusagen] [✗ Absagen]│ ← Prominente Buttons
│                             │
│  📅 Sa, 19. Apr — Konzert   │
│     15:00 · Rathaus         │
│     ✓ Ich bin dabei         │
│                             │
└─────────────────────────────┘
```

#### Termin-Detail mit Zu-/Absage

```
┌─────────────────────────────┐
│  ← Kalender    Probe Do     │
├─────────────────────────────┤
│  📅 Donnerstag, 9. April    │
│  19:30 – 22:00 Uhr          │
│  📍 Probenraum Gemeindehalle │
├─────────────────────────────┤
│  SETLIST                    │
│  🎵 Konzertprogramm April   │
│     8 Stücke                │
├─────────────────────────────┤
│  RÜCKMELDUNG                │
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │  ✓ Ich  │ │ ✗ Kann   │  │
│  │  komme  │ │ nicht    │  │
│  └──────────┘ └──────────┘  │
│  (min. 64px Höhe je Button) │
├─────────────────────────────┤
│  ANWESENHEIT                │
│  ██████████████░░░░░░  38/45│ ← Progress-Bar
│  38 zugesagt · 7 ausstehend │
│  [Alle anzeigen ▼]          │
└─────────────────────────────┘
```

#### Schichtplanung (Fest)

```
┌─────────────────────────────┐
│  ← Kalender   Sommerfest    │
├─────────────────────────────┤
│  Sa, 14. Juni · ganztags    │
├─────────────────────────────┤
│  SCHICHTEN                  │
│                             │
│  🍺 Ausschank 10–14 Uhr     │
│     [3/4 belegt]            │
│     Anna M. · Sebastian F.  │
│     Marco K. · [offen]      │
│     [+ Schicht übernehmen]  │
│                             │
│  🍺 Ausschank 14–18 Uhr     │
│     [2/4 belegt]            │
│     [+ Schicht übernehmen]  │
│                             │
│  🧹 Aufbau 9:00 Uhr         │
│     [4/4 belegt] ✓          │
└─────────────────────────────┘
```

---

### 3.7 Annotationen

#### Annotationsmodus (Tablet)

```
┌──────────────────────────────────────┐
│ ← Spielmodus  Annotieren    [Fertig]│
├──────────────────────────────────────┤
│ EBENE: [Privat ▼]  Farbe: ████      │ ← Layer-Auswahl + Farbpicker
├──────────────────────────────────────┤
│                                      │
│     N O T E N B L A T T             │
│                                      │
│  [Hier sind existierende             │
│   Annotationen als SVG-Layer         │
│   überlagert]                        │
│                                      │
│                                      │
└──────────────────────────────────────┘
│ ✏️  📝  🔷  🎵  📏  ⬜  ✂️  ↩️  ↪️  │ ← Toolbar (verschiebbar)
└──────────────────────────────────────┘
```

**Toolbar-Tools:**
- `✏️` Freihand-Stift (Pencil/S-Pen: Direktzugang)
- `📝` Text-Notiz
- `🔷` Formen (Linie, Pfeil, Rechteck, Ellipse)
- `🎵` Musikalische Stempel (Dynamik, Vorzeichen, Artikulation)
- `📏` Lineal (für gerade Linien)
- `⬜` Textmarker (halbtransparent)
- `✂️` Auswahl (verschieben, kopieren)
- `↩️ ↪️` Undo / Redo

#### 3-Ebenen-System — Sichtbarkeit

```
  EBENE 1: PRIVAT (Grün)
  ┌─────────────────────────┐
  │  Nur ich sehe das       │
  │  Meine Atemzeichen,    │
  │  Fingersätze, Notizen  │
  └─────────────────────────┘
        ↓ (wird nicht synchronisiert)

  EBENE 2: STIMME (Blau)
  ┌─────────────────────────┐
  │  Alle 2. Klarinetten   │
  │  sehen & bearbeiten das│
  │  Registerführer-Hinw.  │
  └─────────────────────────┘
        ↓ (synchronisiert mit Stimmen-Gruppe)

  EBENE 3: ORCHESTER (Orange)
  ┌─────────────────────────┐
  │  Alle Musiker sehen das │
  │  Dirigenten-Anweisungen │
  │  NUR Dirigent kann edit.│
  └─────────────────────────┘
        ↓ (synchronisiert mit allen)
```

**Visuelles System:**
- Jede Ebene hat eine farbigen Rand (links) + kleines Icon in der Annotation
- Ebenen ein-/ausblendbar: Toggle in der oberen Leiste
- Farbblindheitssicher: Grün/Blau/Orange + Zusatzmuster

#### Layer-Toggle (Schnellzugriff)

```
┌───────────────────────┐
│  Ebenen        ✕     │
├───────────────────────┤
│  👁 ■ Privat (Grün)  │ ← ■ = sichtbar, □ = ausgeblendet
│  👁 ■ Stimme (Blau)  │
│  👁 ■ Orchester (Or.)│
└───────────────────────┘
```

#### Long-Press auf Annotation

```
┌────────────────────┐
│  Annotation        │
├────────────────────┤
│  ✏️ Bearbeiten    │
│  🗑 Löschen        │
│  📋 Kopieren       │
│  ↕️ Ebene wechseln │
└────────────────────┘
```

---

### 3.8 Tuner

**Zugang:** Über Spielmodus-Overlay (⚙) oder als eigenständiger Tab/Screen

```
┌─────────────────────────────┐
│  ← Zurück    Stimmgerät     │
├─────────────────────────────┤
│  Instrument: [Klarinette ▼] │ ← Aus Nutzerprofil vorausgewählt
├─────────────────────────────┤
│                             │
│         A4 = 440 Hz         │ ← Referenzton konfigurierbar
│                             │
│  ┌────────────────────────┐ │
│  │    ♭  ←──●──→  ♯      │ │ ← Anzeige (großes Nadel-Widget)
│  │                        │ │   Zentriert = Optimal
│  │         B              │ │ ← Erkannter Ton (groß!)
│  │        -5 Cent         │ │ ← Abweichung
│  └────────────────────────┘ │
│                             │
│  🟢  Stimmton ausgeben      │ ← Toggle: Referenzton spielen
│                             │
│  [A4] [B♭4] [F4] [C5]      │ ← Schnelltasten häufige Töne
│                             │
└─────────────────────────────┘
```

**Designprinzip Tuner:**
- Anzeige muss aus 1 Meter Abstand lesbar sein → Großes Widget, maximale Kontrastverhältnisse
- Erkannter Ton: mindestens 72sp
- Nadel/Balken: Grün wenn ±3 Cent, Gelb bis ±10 Cent, Rot darüber
- Mikrofon-Zugriff: klare Erklärung, warum die App Mikrofon braucht

---

## 4. Navigation & Informationsarchitektur

### 4.1 Bottom Navigation (Mobile, < 1024px)

```
┌─────────────────────────────┐
│                             │
│       [Inhalt]              │
│                             │
├─────────────────────────────┤
│  📚    🎵    📅    👤       │
│ Biblio Setl. Kalen. Profil  │
└─────────────────────────────┘
```

| Tab | Icon | Funktion |
|-----|------|---------|
| Bibliothek | 📚 | Alle Noten, Suche, Import |
| Setlists | 🎵 | Setlists verwalten & starten |
| Kalender | 📅 | Termine, Zu-/Absagen |
| Profil | 👤 | Eigene Einstellungen, Kapellenwechsel |

**Spielmodus:** Bottom-Navigation verschwindet vollständig. Kein „Peek" oder Partial-Overlay.

### 4.2 Sidebar Navigation (Desktop, > 1024px)

```
┌──────────────────┬─────────────────────────────────┐
│  SHEETSTORM      │                                 │
│  [Kapelle ▼]     │       [Hauptinhalt]             │
│  ─────────────── │                                 │
│  📚 Bibliothek   │                                 │
│  🎵 Setlists     │                                 │
│  📅 Kalender     │                                 │
│  ─────────────── │                                 │
│  ADMIN           │                                 │
│  👥 Mitglieder   │                                 │
│  ⚙  Kapelle      │                                 │
│  ─────────────── │                                 │
│  👤 Mein Profil  │                                 │
│  ⚙  Einstellungen│                                 │
└──────────────────┴─────────────────────────────────┘
```

**Admin-Sektion:** Nur sichtbar für Nutzer mit Admin-, Dirigenten- oder Notenwart-Rolle.

### 4.3 Multi-Kapellen-Wechsel

```
┌─────────────────────────────┐
│  [KAPELLE ▼]                │ ← Tap öffnet Kapellen-Auswahl
├─────────────────────────────┤
│  ✓ Musikkapelle Beispiel   │ ← Aktuell aktiv
│    Stadtkapelle Musterstadt │
│    Jugendorchester (Lehrer) │
│  ─────────────────────────  │
│  Meine Sammlung 🟢          │ ← Persönliche Sammlung immer dabei
│  ─────────────────────────  │
│  + Kapelle beitreten        │
│  + Neue Kapelle erstellen   │
└─────────────────────────────┘
```

### 4.4 Deep-Link-Hierarchie

```
Sheetstorm://
├── bibliothek/
│   ├── [stueckId]/                   → Stück-Detail
│   ├── [stueckId]/stimme/[stimmeId]  → Direkt in Spielmodus
│   └── import/                       → Import-Flow starten
├── setlists/
│   ├── [setlistId]/                  → Setlist-Detail
│   └── [setlistId]/spielen           → Spielmodus starten
├── kalender/
│   └── [terminId]/                   → Termin-Detail mit Zu/Absage
└── aushilfe/[token]                  → Temporärer Aushilfen-Zugang
```

---

## 5. Responsive Breakpoints

### 5.1 Breakpoint-Definitionen

| Breakpoint | Breite | Zielgerät | Layout-Modus |
|------------|--------|-----------|-------------|
| **Phone** | < 600px | Smartphone | Single Column, Bottom-Nav |
| **Tablet** | 600–1024px | Tablet (Hochformat) | Erweitertes Single-Column oder Split |
| **Tablet Quer** | 600–1024px Landscape | Tablet (Querformat) | Zwei-Seiten-Modus im Spielmodus |
| **Desktop** | > 1024px | Desktop, Laptop, Browser | Sidebar + Hauptinhalt |

### 5.2 Layout-Änderungen je Breakpoint

**Spielmodus:**
- Phone Hochformat → Half-Page-Turn Standard
- Tablet Querformat → Zwei-Seiten-Modus Standard
- Desktop → Zwei-Seiten + optionale Sidebar mit Setlist

**Bibliothek:**
- Phone → Listenansicht, full-width
- Tablet → Listenansicht + Vorschau-Pane (Split)
- Desktop → Drei-Spalten: Navigation | Liste | Detail

**Kalender:**
- Phone → Monatsgitter + Terminliste darunter
- Tablet/Desktop → Monatsgitter neben Terminliste (Side-by-Side)

### 5.3 Spielmodus — Adaptive Zoom-Strategie

```
Phone (375px):         Tablet (768px):        Desktop (1280px):
┌─────┐                ┌───────────┐          ┌─────────────────┐
│ N B │ ← Zoom auf     │  NB   NB  │ ← 2-up   │  NB    NB    NB │
│     │   Seitenbreite │           │   Quer   │  Setlist-Panel  │
└─────┘                └───────────┘          └─────────────────┘
```

Auto-Zoom-Algorithmus:
1. Seite in Originalauflösung laden
2. Seitenbreite auf verfügbare Viewport-Breite skalieren
3. Wenn Seite im Hochformat und Viewport im Querformat: ggf. auf Höhe skalieren
4. Notensystem (obere Linie bis untere Linie) soll mindestens 8px hoch sein
5. Nutzer kann mit Pinch-to-Zoom manuell anpassen (persönlicher Override)

---

## 6. Interaction Patterns

### 6.1 Seitenwechsel (Spielmodus)

| Geste | Aktion | Plattform |
|-------|--------|-----------|
| Tap rechts (>60% der Breite) | Nächste Seite | Alle |
| Tap links (< 40% der Breite) | Vorherige Seite | Alle |
| Wisch links → | Nächste Seite | Alle |
| Wisch rechts ← | Vorherige Seite | Alle |
| Fußpedal Rechts | Nächste Seite | Alle mit BT-Fußpedal |
| Fußpedal Links | Vorherige Seite | Alle mit BT-Fußpedal |
| Tastatur → / Space | Nächste Seite | Desktop/Laptop |
| Tastatur ← | Vorherige Seite | Desktop/Laptop |
| Mausrad runter | Nächste Seite | Desktop |
| Mausrad hoch | Vorherige Seite | Desktop |

### 6.2 Annotationen — Gesten

| Geste | Aktion | Kontext |
|-------|--------|---------|
| Stift berührt Screen | Sofort Annotationsmodus | Wenn Stift erkannt |
| Finger-Zeichnen | Annotationsmodus (wenn Finger-Zeichnen aktiv) | Konfigurierbar |
| Long-Press auf Annotation | Kontextmenü | Überall |
| Long-Press auf freies Feld | Stempel-Picker öffnen | Annotationsmodus |
| 3-Finger-Tap | Annotationsmodus verlassen / betreten | Spielmodus |
| Stift-Doppeltipp (Pencil 2) | Werkzeug wechseln (z.B. zum Radierer) | iOS/iPadOS |
| Pinch | Zoom auf Notenblatt | Überall |

### 6.3 Feedback-Patterns

| Aktion | Feedback | Timing |
|--------|----------|--------|
| Einstellung gespeichert | Kein sichtbares Feedback (Auto-Save) | — |
| Gefährliche Aktion rückgängig | Toast: „Rückgängig" (5 Sek.) | Sofort |
| Upload gestartet | Progressbalken in der Toolbar | Kontinuierlich |
| Sync abgeschlossen | Kurzes ✓ Icon in der Statusleiste | 2 Sek. |
| Sync-Fehler | Orange Indikator + Tap für Details | Persistent bis gelöst |
| Stimme gewechselt | Kurze Animation: altes Blatt → neues Blatt | 300ms |
| Annotation synchronisiert | Keine sichtbare Meldung | — |

### 6.4 Fußpedal-Konfiguration

**Verbindung:**
1. Bluetooth-Gerät in den Einstellungen koppeln
2. Sheetstorm erkennt gängige Fußpedale automatisch (AirTurn BT-105, PageFlip Cicada, etc.)
3. Manuelle HID-/MIDI-Zuweisung möglich

**Konfiguration im Spielmodus:**
- Beim ersten Verbinden: kurzer „Kalibrierungsschritt" (rechtes Pedal drücken → Aktion zuweisen)
- Default: Rechts = Weiter, Links = Zurück

---

## 7. Design Tokens

### 7.1 Farbpalette

#### Light Mode (Standard)

| Token | Wert | Verwendung |
|-------|------|-----------|
| `color-background` | `#FFFFFF` | Seitenhintergrund |
| `color-surface` | `#F5F5F5` | Karten, Panels |
| `color-primary` | `#1A56DB` | Primäre Aktionen, Links |
| `color-primary-dark` | `#1040A8` | Hover/Pressed States |
| `color-on-primary` | `#FFFFFF` | Text auf Primärfarbe |
| `color-secondary` | `#7C3AED` | Sekundäre Aktionen |
| `color-success` | `#16A34A` | Erfolg, Bestätigung |
| `color-warning` | `#D97706` | Warnungen, Gerät-Ebene |
| `color-error` | `#DC2626` | Fehler |
| `color-text-primary` | `#111827` | Haupttext |
| `color-text-secondary` | `#6B7280` | Sekundärtext, Labels |
| `color-border` | `#E5E7EB` | Trennlinien, Rahmen |

#### Dark Mode (Nachtmodus — Spielmodus)

| Token | Wert | Verwendung |
|-------|------|-----------|
| `color-dark-background` | `#000000` | Notenhintergrund (Spielmodus) |
| `color-dark-surface` | `#111827` | Karten, Panels (Dark) |
| `color-dark-primary` | `#60A5FA` | Aktionen (Dark) |
| `color-dark-text-primary` | `#F9FAFB` | Haupttext (Dark) |
| `color-dark-note-ink` | `#E5E7EB` | Notenfarbe auf schwarzem Hintergrund |

#### Annotationsebenen-Farben

| Ebene | Farbe | Hex | Muster-Ergänzung |
|-------|-------|-----|-----------------|
| Privat | Grün | `#16A34A` | Einfarbig |
| Stimme | Blau | `#2563EB` | Gestrichelt |
| Orchester | Orange | `#EA580C` | Durchgehend, dicker Rand |

#### Konfigurations-Ebenen-Farben (siehe `ux-konfiguration.md`)

| Ebene | Farbe | Hex |
|-------|-------|-----|
| Kapelle | Blau | `#1A56DB` |
| Nutzer/Persönlich | Grün | `#16A34A` |
| Gerät | Orange | `#D97706` |

### 7.2 Typografie

| Token | Wert | Verwendung |
|-------|------|-----------|
| `font-family-base` | `Inter, system-ui, sans-serif` | Alle UI-Texte |
| `font-size-xs` | `12sp` | Captions, Labels |
| `font-size-sm` | `14sp` | Sekundärtext |
| `font-size-base` | `16sp` | Fließtext (Minimum) |
| `font-size-lg` | `20sp` | Überschriften, Setlist-Items |
| `font-size-xl` | `28sp` | Große Headings |
| `font-size-2xl` | `48sp` | Tuner-Ton-Anzeige |
| `font-size-3xl` | `72sp` | Tuner-Hauptanzeige |
| `font-weight-normal` | `400` | Fließtext |
| `font-weight-medium` | `500` | Labels, Buttons |
| `font-weight-bold` | `700` | Headings, Aktionselemente |
| `line-height-tight` | `1.25` | Headings |
| `line-height-base` | `1.5` | Fließtext |

### 7.3 Spacing & Sizing

| Token | Wert | Verwendung |
|-------|------|-----------|
| `space-xs` | `4px` | Micro-Abstände |
| `space-sm` | `8px` | Interne Padding (dicht) |
| `space-md` | `16px` | Standard-Padding |
| `space-lg` | `24px` | Abschnitte |
| `space-xl` | `32px` | Große Abstände |
| `touch-target-min` | `44px` | Minimum Touch-Target |
| `touch-target-play` | `64px` | Touch-Target im Spielmodus |
| `touch-target-zu-absage` | `64px` | Zu/Absage Buttons |
| `border-radius-sm` | `4px` | Kleine Elemente |
| `border-radius-md` | `8px` | Karten, Buttons |
| `border-radius-lg` | `16px` | Bottom Sheets, Modals |
| `border-radius-full` | `9999px` | Chips, Badges |

### 7.4 Elevation / Shadows

| Token | Wert | Verwendung |
|-------|------|-----------|
| `shadow-sm` | `0 1px 2px rgba(0,0,0,0.05)` | Karten |
| `shadow-md` | `0 4px 6px rgba(0,0,0,0.07)` | Dropdowns, Overlays |
| `shadow-lg` | `0 10px 15px rgba(0,0,0,0.1)` | Modale, Bottom-Sheets |

### 7.5 Animation

| Token | Wert | Verwendung |
|-------|------|-----------|
| `duration-fast` | `150ms` | Hover, Focus |
| `duration-base` | `250ms` | Standard-Übergang |
| `duration-slow` | `400ms` | Modale, Sheets |
| `easing-standard` | `cubic-bezier(0.4, 0, 0.2, 1)` | Standard |
| `easing-enter` | `cubic-bezier(0, 0, 0.2, 1)` | Einblenden |
| `easing-exit` | `cubic-bezier(0.4, 0, 1, 1)` | Ausblenden |

**Spielmodus-Regel:** Keine nicht-essenziellen Animationen. Seitenwechsel-Animation: max. 200ms, einfaches Slide oder Cross-Fade. Kein Bounce, kein Spring.

### 7.6 Icon-System

- **Bibliothek:** Material Symbols (Google) — konsistent auf Android, Web, Desktop
- **Ergänzung iOS:** SF Symbols-äquivalente Icons über Material Symbols abgedeckt
- **Musikspezifisch:** Eigene Symbole (Notenzeichen, Stimmgabel, Fußpedal) als SVG im Design-System

---

> **Nächste Schritte:**
> 1. Interaktiver Figma-Prototyp für Spielmodus + Import-Flow
> 2. Usability-Test mit 3–5 Blaskapellen-Musikern (je Phone/Tablet)
> 3. Accessibility-Audit mit WCAG 2.1 AA Checkliste
> 4. Abstimmung mit Romanoff (Frontend) zu Flutter-Widget-Mapping
> 5. Design-Token-Export als Flutter ThemeData

---

*Erstellt von Wanda (UX Designer), Sheetstorm-Projekt. Überarbeitung v2.0 nach vertiefter Konkurrenzanalyse.*
