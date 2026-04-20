# UX-Spec: Annotationen (3 Ebenen)

> **Issue:** #37  
> **Version:** 1.0  
> **Status:** Review ausstehend  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-28  
> **Meilenstein:** M1 — Kern: Noten & Kapelle  
> **Referenzen:** `docs/anforderungen.md §7.3`, `docs/ux-design.md §3.7`, `docs/spezifikation.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Kontext](#1-übersicht--kontext)
2. [3 Sichtbarkeitsebenen](#2-3-sichtbarkeitsebenen)
3. [Annotationstypen](#3-annotationstypen)
4. [Interaction Patterns](#4-interaction-patterns)
5. [Integration im Spielmodus](#5-integration-im-spielmodus)
6. [Sync-Verhalten](#6-sync-verhalten)
7. [Edge Cases](#7-edge-cases)
8. [ASCII Wireframes — Phone](#8-ascii-wireframes--phone)
9. [ASCII Wireframes — Tablet](#9-ascii-wireframes--tablet)
10. [Abhängigkeiten](#10-abhängigkeiten)
11. [Offene Fragen](#11-offene-fragen)

---

## 1. Übersicht & Kontext

### 1.1 Problem

Musiker brauchen drei fundamental verschiedene Arten von Notizen in ihren Noten:

- **Persönliche Helfer** (Atemzeichen, Fingersatz, Taktzählung) — privat, nur für mich
- **Register-Absprachen** (Registerführer-Hinweise, Stimmführungsnoten) — für alle mit meiner Stimme
- **Dirigenten-Anweisungen** (Dynamik-Änderungen, Tempomarkierungen, Wiederholungshinweise) — für alle

Kein Wettbewerber bietet dieses 3-Ebenen-System. Newzik kommt mit 2 Ebenen am nächsten (Privat/Public), aber hat kein stimmen-spezifisches Layer.

### 1.2 Personas im Fokus

| Persona | Nutzung | Priorität |
|---------|---------|-----------|
| **Dirigent** | Orchester-Anweisungen eintragen, auf Tablet, während der Probe | Kritisch |
| **Registerführer/Musiker** | Private Notizen + Stimmen-Anmerkungen, in Probe und zuhause | Kritisch |
| **Musiker beim Auftritt** | Lesen, nicht schreiben — Annotationen sollen nicht stören | Kritisch |

### 1.3 Designprinzip

> „Eine Annotation ist ein Werkzeug, kein Feature. Sie muss so schnell kommen wie ein Bleistiftstrich — und genauso schnell weg sein."

Die Farbkodierung der Ebenen ist die zentrale Designentscheidung: **Farbe = Reichweite**. Das macht jede Annotation auf einen Blick verständlich.

---

## 2. 3 Sichtbarkeitsebenen

### 2.1 Ebenen-Übersicht

| Ebene | Farbe | Icon | Wer sieht es | Wer kann bearbeiten |
|-------|-------|------|--------------|---------------------|
| **Privat** | 🔵 Blau | 👤 | Nur ich | Nur ich |
| **Stimme** | 🟢 Grün | 🎵 | Alle mit gleicher Stimme | Alle mit gleicher Stimme |
| **Orchester** | 🟠 Orange | 🎼 | Alle Kapellenmitglieder | Dirigent, Admin |

> **Hinweis zu Farben:** In `docs/spezifikation.md` werden Privat=Grün / Stimme=Blau / Orchester=Orange verwendet. Dieses Spec folgt dem aktualisierten Farbschema aus dem Konfigurationssystem-Kontext: Privat=Blau (Nutzerebene), Stimme=Grün (Gruppenebene), Orchester=Orange (Kapellenebene) — konsistent mit den Konfigurationsebenen-Farben. **Entscheidung für Thomas: Soll das Annotationssystem mit den Konfigurationsfarben übereinstimmen oder ein eigenes Schema haben?**

### 2.2 Privat (Blau 🔵)

**Semantik:** „Das ist für meine Augen — mein persönliches Notizbuch im Notenblatt."

- Nur lokal gespeichert (kein Server-Sync für den Inhalt)
- Wird mit dem Konto synchronisiert (Gerät A → Gerät B desselben Nutzers)
- Für Aushilfen: privat bedeutet "nur auf diesem Gerät/Session"
- Typische Inhalte: Atemzeichen, Fingersätze, Taktzählung, persönliche Dynamikhinweise, Übe-Notizen

### 2.3 Stimme (Grün 🟢)

**Semantik:** „Das gilt für alle, die meine Stimme spielen — wir sind ein Register."

- Sync an alle Mitglieder mit exakt gleicher Stimme (z.B. alle "2. Klarinette in B♭")
- Bearbeitbar von jedem mit dieser Stimme (kein Besitzer-Konzept)
- Sichtbar aber nicht bearbeitbar für andere Stimmen? → **Entscheidung offen** (Default: nicht sichtbar für andere)
- Typische Inhalte: Registerführer-Anweisungen, gemeinsame Phrasierung, Dynamik-Absprachen innerhalb des Registers

### 2.4 Orchester (Orange 🟠)

**Semantik:** „Das hat der Dirigent gesagt — gilt für alle."

- Sync an alle aktiven Kapellenmitglieder
- Bearbeitbar nur von: Dirigent, Admin (Read-Only für Musiker)
- Musiker können Orchester-Annotationen ausblenden, aber nicht löschen
- Typische Inhalte: Dirigenten-Anweisungen, Tempoänderungen, Wiederholungshinweise, Streicher-Bogen-Markierungen

### 2.5 Visuelles System

```
  ┌─────────────────────────────────────────────────┐
  │   ANNOTATION BEISPIEL — VISUELLES ENCODING      │
  ├─────────────────────────────────────────────────┤
  │                                                 │
  │  ┌──────────────┐  ┌──────────────┐            │
  │  │█ Atemzeichen │  │░░ mf →  ff  │            │
  │  │  (Blau-Rand) │  │  (Grün-Rand) │            │
  │  │  👤 privat   │  │  🎵 Stimme   │            │
  │  └──────────────┘  └──────────────┘            │
  │                                                 │
  │  ┌──────────────────────────────────┐           │
  │  │██ Wiederholung von Takt 8 !!    │           │
  │  │   (Orange-Rand + Schraffen)     │           │
  │  │   🎼 Orchester                  │           │
  │  └──────────────────────────────────┘           │
  │                                                 │
  │  Rand (4px) + kleines Icon unten-links          │
  │  = Ebene immer auf einen Blick erkennbar        │
  └─────────────────────────────────────────────────┘
```

**Barrierefreiheit:** Farbe allein ist nicht ausreichend. Jede Ebene bekommt zusätzlich:
- Ein eindeutiges Icon (👤 / 🎵 / 🎼)
- Ein visuelles Muster (einfarbig / schraffiert / gestrichelt) im Rand
- Einen Label-Text in der Annotation-Übersicht

---

## 3. Annotationstypen

### 3.1 Übersicht der Werkzeuge

| Werkzeug | Icon | Beschreibung | Ebenen-Zugang |
|----------|------|--------------|---------------|
| **Freihand-Stift** | ✏️ | Zeichnen mit Finger oder Stift | Alle 3 Ebenen |
| **Text-Notiz** | 📝 | Tipptastatur oder Handschrift | Alle 3 Ebenen |
| **Textmarker** | 🖊 | Halbtransparentes Highlight | Alle 3 Ebenen |
| **Durchstreichen** | ~~T~~ | Horizontale Linie über Noten | Alle 3 Ebenen |
| **Stempel** | 🎵 | Vordefinierte Musikzeichen | Alle 3 Ebenen |
| **Radierer** | 🧹 | Freihand-Radierer | Eigene Ebene |
| **Auswahl** | ↕️ | Selektieren, verschieben, kopieren | Eigene Ebene |

### 3.2 Freihand-Zeichnung (Stift / Finger)

**Stift-Erkennung (Stylus-First):**
- Apple Pencil, S-Pen, Wacom etc. → sofort annotieren ohne Modus-Wechsel
- Finger bleibt Standard für Scrollen — kein versehentliches Annotieren
- Konfigurierbar: "Finger auch für Annotationen aktivieren" (nützlich ohne Stylus)

**Strichparameter:**
- Dicke: 4 Voreinstellungen (fein / normal / dick / sehr dick)
- Opacity: Standard 100%, reduzierbar auf 40%
- Druck-sensitiv: Ja, wenn Hardware es unterstützt

**Pencil-Doppeltipp (iOS/iPadOS):** Wechselt zwischen letztem Werkzeug und Radierer

### 3.3 Text-Notizen

- Öffnet Tastatur (oder Handschrift-Eingabe)
- Platzierung durch Tippen auf gewünschte Position
- Maximale Länge: 200 Zeichen
- Font: Systemschrift, klein (10sp), mittel (14sp), groß (18sp)
- Textblock ist verschiebbar (Long-Press → Drag)

### 3.4 Markierungen

**Textmarker (Highlight):**
- 40% Opazität
- Farbton: entsprechend der Ebene (blau/grün/orange), keine eigene Farbwahl
- Breite: fixiert auf Notenzeilenhöhe

**Durchstreichen:**
- Horizontale Linie
- Verwendung: veraltete Passagen, gestrichene Takte

### 3.5 Stamp-Tools (Musikalische Stempel)

Vordefinierte Symbole für häufig verwendete Annotationen in Blaskapellen:

**Kategorie: Dynamik**
```
  pp  p  mp  mf  f  ff  fff  ffff
  sfz  sfp  fp  fpp  cresc.  dim.
```

**Kategorie: Artikulation**
```
  .  (Staccato)    >  (Akzent)    ^  (Marcato)
  ~  (Tremolo)     tr (Triller)    gliss.
```

**Kategorie: Atemzeichen**
```
  '  (Einatmen)    V  (Luftdruckzeichen)    ,  (Komma-Atem)
```

**Kategorie: Navigation**
```
  D.C.  D.S.  Coda  Fine  Segno
  [1.]  [2.]  (Volta-Klammern)
```

**Kategorie: Benutzerdefiniert:**
- Musiker können eigene Text-Stempel anlegen (bis 5 Zeichen)
- Admin kann kapellenweite Stempel für Orchester-Ebene definieren

**Stempel platzieren:** Einmal tippen = Stempel an Tipp-Position. Größe anpassbar (Drag am Rand-Handle).

---

## 4. Interaction Patterns

### 4.1 Annotationsmodus aktivieren

**3 Einstiegswege:**

1. **Long-Press auf Notenblatt (primär, 600ms):**
   - Vibration-Feedback (wenn verfügbar)
   - Toolbar erscheint von unten (Phone) oder links (Tablet)
   - Aktive Ebene = zuletzt verwendete Ebene (oder Privat beim ersten Mal)

2. **Stift berührt Screen (automatisch):**
   - Sofort Annotationsmodus, kein Long-Press nötig
   - Letztes Werkzeug wird wiederhergestellt
   - Kein visuelles "Entering"-Feedback — sofort zeichnen

3. **Toolbar-Button im Spielmodus-Overlay:**
   - Annotation-Icon in der oberen Leiste
   - Öffnet Ebenen-Auswahl als ersten Schritt

**Modus verlassen:**
- `[Fertig]`-Button (oben rechts)
- 3-Finger-Tap auf das Notenblatt
- Stift weglegen (wenn Stift-Erkennung aktiv)
- Automatisch nach 3 Minuten Inaktivität (mit Toast-Warnung 10s vorher)

### 4.2 Toolbar

```
  ┌───────────────────────────────────────────────────────────┐
  │  TOOLBAR — AUFBAU (Phone: horizontal unten)               │
  ├───────────────────────────────────────────────────────────┤
  │  [Ebene: 🔵] | ✏️ | 📝 | 🖊 | 🎵 | 🧹 | ↕️ | ↩ | ↪ |   │
  └───────────────────────────────────────────────────────────┘
  
  Erste Position (ganz links):
  → Ebenen-Picker — Farbe der aktiven Ebene = Hintergrundfarbe des Buttons
  → Tippen = Ebenen-Flyout öffnen (s. §4.3)
  
  Aktives Werkzeug:
  → Blauer Unterstrich + leicht erhöhter Hintergrund
```

**Touch-Targets:** Jeder Toolbar-Button min. 44×44 dp. Auf Phone: Toolbar scrollbar (wenn mehr Werkzeuge hinzugefügt).

**Toolbar-Position (Tablet):**
- Standardmäßig linke Seite (vertikal)
- Verschiebbar per Long-Press + Drag (Position wird pro Nutzer gespeichert)
- Andockbar an: links, rechts, oben, unten

### 4.3 Ebenen-Auswahl (Flyout)

```
  ┌─────────────────────────────────┐
  │  Ebene wählen          ✕       │
  ├─────────────────────────────────┤
  │  ●  🔵 Privat (nur für mich)   │  ← aktiv = ausgefüllter Kreis
  │  ○  🟢 Stimme (2. Klarinette)  │
  │  ○  🟠 Orchester               │  ← ausgegraut wenn kein Schreibrecht
  └─────────────────────────────────┘
```

- Stimme zeigt den Stimmennamen des Nutzers an
- Orchester ausgegraut + Schloss-Icon wenn Nutzer kein Dirigent/Admin
- Auswahl schließt das Flyout sofort und aktualisiert Toolbar-Farbe

### 4.4 Farbkodierung in der Toolbar

Die Toolbar-Farbe spiegelt immer die aktive Ebene:
- Aktive Ebene **Privat** → Toolbar-Akzentfarbe Blau (`#3B82F6`)
- Aktive Ebene **Stimme** → Toolbar-Akzentfarbe Grün (`#22C55E`)
- Aktive Ebene **Orchester** → Toolbar-Akzentfarbe Orange (`#F97316`)

Kein separater „Farbpicker" — Farbe = Ebene. Das ist die zentrale Designentscheidung.

### 4.5 Undo / Redo

- **Undo:** ↩ in der Toolbar, oder Zwei-Finger-Wischen nach links
- **Redo:** ↪ in der Toolbar, oder Zwei-Finger-Wischen nach rechts
- **Undo-Stack:** Unbegrenzt (Session), nach App-Restart: letzter persistierter Zustand
- **Toast:** „Rückgängig gemacht" erscheint 2 Sekunden nach Undo (nicht blockierend)
- **Sync-konsequenz:** Undo einer Stimmen- oder Orchester-Annotation sendet Delete-Event an andere Nutzer

### 4.6 Einzelne Annotation löschen

**Long-Press auf Annotation (500ms):**

```
  ┌────────────────────────────────┐
  │  📐 Annotation                 │
  ├────────────────────────────────┤
  │  ✏️  Bearbeiten               │
  │  📋  Kopieren                  │
  │  ↕️  Ebene wechseln           │
  │  🗑   Löschen                   │  ← Rot hervorgehoben
  └────────────────────────────────┘
```

- **Löschen** — keine Bestätigung für eigene Annotation
- **Löschen** — Bestätigung bei Stimmen- oder Orchester-Annotation (destructive für andere)
- Orchester-Annotation löschen: Nur Dirigent/Admin, Bestätigung: „Diese Anweisung für alle löschen?"
- „Ebene wechseln" öffnet Ebenen-Flyout (§4.3) — verschiebt die Annotation

---

## 5. Integration im Spielmodus

### 5.1 Annotations-Layer als Overlay

Der Annotations-Layer liegt immer **über** dem PDF-Rendering-Layer, aber **unter** dem UI-Overlay:

```
  Z-ORDER (von oben nach unten):
  ┌────────────────────────────────────┐
  │  4. UI-Overlay (Toolbar, etc.)    │
  ├────────────────────────────────────┤
  │  3. Annotations-Layer (SVG)       │  ← dieser Layer
  ├────────────────────────────────────┤
  │  2. PDF-Render-Layer              │
  ├────────────────────────────────────┤
  │  1. Hintergrund                   │
  └────────────────────────────────────┘
```

**SVG-Layer:** Annotationen werden als SVG mit relativen Koordinaten gespeichert (% der Seitengröße), nicht als absolute Pixel. Das macht sie zoom- und rotationsunabhängig.

### 5.2 Layer-Toggle (Schnellzugriff im Spielmodus)

Der Dirigent möchte vor dem Konzert alle Annotations-Layer ausblenden, ohne sie zu löschen:

```
  ┌────────────────────────────────┐
  │  Ebenen          ✕            │
  ├────────────────────────────────┤
  │  👁 ■  🔵 Privat             │  ← ■ = sichtbar
  │  👁 □  🟢 Stimme             │  ← □ = ausgeblendet
  │  👁 ■  🟠 Orchester          │
  └────────────────────────────────┘
```

- **Toggle-Position:** Im Spielmodus-Overlay, untere Leiste, zweitletztes Icon
- **Pro-Stück-Erinnerung:** Der Zustand (an/aus pro Ebene) wird pro Stück gespeichert
- **Nicht-destruktiv:** Ausblenden ≠ Löschen

### 5.3 Fokus-Schutz

Annotationen dürfen den Performance-Fokus nicht brechen:

- **Im Spielmodus (kein Annotationsmodus aktiv):** Tippen löst Seitenwechsel aus — **keine Annotation**
- **Kein versehentliches Annotieren:** Ohne expliziten Einstieg (Long-Press / Stift / Button) passiert nichts
- **Sync im Hintergrund:** Eingehende Annotationen von anderen werden angezeigt, aber kein Pop-up, kein Toast, kein Sound
- **Neue Orchester-Annotation:** Subtile Pulsierung des Annotations-Layer-Icons in der Leiste (1x, 500ms) — kein Ton

### 5.4 Nachtmodus & Annotationen

- Annotations-Farben werden im Nachtmodus leicht gesättigt angezeigt (nicht verändert, nur Hintergrund-Contrast)
- Farben müssen auch auf warmem Sepia-Hintergrund erkennbar sein → getestete Werte in Design Tokens

---

## 6. Sync-Verhalten

### 6.1 Übersicht

| Ebene | Speicherung | Sync-Zeitpunkt | Empfänger |
|-------|------------|----------------|-----------|
| **Privat** | Lokal + eigenes Cloud-Konto | Bei Verbindung, per Gerät | Nur eigene Geräte |
| **Stimme** | Server + lokaler Cache | Real-time (SignalR) | Alle mit gleicher Stimme |
| **Orchester** | Server + lokaler Cache | Real-time (SignalR) | Alle Kapellenmitglieder |

### 6.2 Privat — Sync-Verhalten

- Annotationen werden lokal (SQLite via Drift) gespeichert
- Sync zum Server: Im Hintergrund, bei aktiver Verbindung
- Server dient als Backup und Multi-Gerät-Bridge — nicht als Live-Collaboration
- Offline: Annotationen funktionieren vollständig, Sync bei nächster Verbindung

### 6.3 Stimme — Real-time Sync

**Happy Path:**
1. Musiker A zeichnet Annotation auf Stimme-Ebene
2. Annotation wird lokal gespeichert (sofort sichtbar)
3. Patch-Event wird via SignalR an Server gesendet: `{type: "annotation_added", layer: "voice", voiceId: "...", data: [SVG-path]}`
4. Server broadcastet an alle Nutzer mit gleicher `voiceId`
5. Empfänger erhalten das Event und rendern die neue Annotation (kein Toast, kein Ton)

**Latenz-Ziel:** < 500ms End-to-End in LAN-Umgebung (Probe)

### 6.4 Orchester — Broadcast

- Identisch wie Stimme, aber Empfänger = alle Mitglieder der Kapelle
- Zusätzliche Berechtigungsprüfung auf Server-Seite (nur Dirigent/Admin darf senden)
- Musiker ohne Schreibrecht erhalten Updates, können aber nicht antworten

### 6.5 Delta-Sync (kein Full-State-Sync)

- Nur Änderungen werden übertragen (Patches), nicht der gesamte Annotations-Zustand
- Format: JSON-Patches per Annotation (add / modify / delete)
- Vorteil: Effizient bei vielen gleichzeitigen Annotierenden

---

## 7. Edge Cases

### 7.1 Offline-Annotationen → Sync bei Verbindung

**Szenario:** Musiker annotiert während der Probe ohne WLAN (häufig in Proberäumen).

**Verhalten:**
1. Privat-Annotationen: vollständig funktional — kein Unterschied
2. Stimmen/Orchester-Annotationen: werden lokal gespeichert mit Status `pending_sync`
3. UI-Indikator: kleines Offline-Icon (☁️✗) in der Toolbar (nicht blockierend)
4. Bei Verbindungswiederherstellung: automatischer Background-Sync, kein User-Action nötig
5. Toast: „X Annotationen synchronisiert" (nur wenn User die App aktiv nutzt)

**Conflict-Prüfung:** Beim Sync prüft der Server auf Konflikte (s. §7.2)

### 7.2 Konflikte bei gleichzeitiger Bearbeitung

**Szenario:** Zwei Registerführer bearbeiten gleichzeitig die Stimmen-Ebene derselben Seite ohne Netz.

**Strategie: Last-Write-Wins pro Annotation**
- Jede Annotation hat einen Timestamp und eine UUID
- Beim Sync: Neuere Annotation gewinnt bei gleichem `annotationId`
- Neue Annotationen (andere UUID) werden zusammengeführt (kein Konflikt)

**Sonderfall: Orchester-Ebene**
- Zwei Dirigenten gleichzeitig (Multi-Dirigenten-Setup, selten): Last-Write-Wins
- Kein Merge-Dialog — zu komplex für Probe-Kontext

**User-Feedback:**
- Nach Sync: Toast „Neuere Version einer Annotation wurde übernommen" (wenn eigene Annotation überschrieben)
- Keine detaillierte Diff-Anzeige (zu komplex)

### 7.3 Annotation auf gelöschter Seite

**Szenario:** Notenwart löscht eine Seite aus dem Notenblatt, auf der Annotationen existieren.

**Verhalten:**
1. Warnung beim Löschen der Seite: „X Annotation(en) auf dieser Seite vorhanden. Löschen?" [Fortfahren] [Abbrechen]
2. Wenn fortgefahren: Annotationen werden mitgelöscht (Soft-Delete mit 30 Tagen Recovery)
3. Recovery: In den Admin-Einstellungen → Gelöschte Annotationen wiederherstellen (innerhalb 30 Tage)

**Sonderfall: Seite wird durch neue Version ersetzt (gleiche Position):**
- Annotationen bleiben erhalten (relative Koordinaten beibehalten)
- Warnung: „Seite wurde aktualisiert — prüfen Sie Ihre Annotationen"

### 7.4 Orchester-Annotation als Musiker

**Szenario:** Musiker versucht Orchester-Annotation zu erstellen oder zu bearbeiten.

**Verhalten:**
- Orchester-Ebene in der Ebenen-Auswahl ausgegraut + Schloss-Icon + Tooltip: „Nur Dirigent"
- Bestehende Orchester-Annotationen: sichtbar, Long-Press zeigt Kontextmenü ohne „Bearbeiten"
- Tap auf Orchester-Annotation: Info-Bubble zeigt Ersteller + Datum

### 7.5 Aushilfe ohne Account

**Szenario:** Aushilfe nutzt Token-Link (`sheetstorm://aushilfe/[token]`) ohne Account.

**Verhalten:**
- Private Annotationen: funktionieren, werden lokal gespeichert (gehen verloren nach Session-Ende)
- Stimmen-Annotationen: funktionieren (Token enthält voiceId), werden synchronisiert
- Orchester-Annotationen: nur lesen (kein Dirigenten-Status)
- Kein Persistenz-Versprechen für private Annotationen (Toast beim ersten Annotieren: „Private Notizen werden nach der Session gelöscht — erstelle einen Account zum Speichern")

### 7.6 Sehr viele Annotationen (Performance)

**Szenario:** Dirigent hat über 3 Jahre viele Orchester-Annotationen auf einem Stück angesammelt.

**Verhalten:**
- Annotations-Layer wird lazy geladen (nicht alle Seiten gleichzeitig)
- Seiten-Cache: aktuelle ± 2 Seiten im Speicher
- Ab 500 Annotationen auf einer Seite: Warnung im Admin-Dashboard
- Archivierung möglich: Annotationen als „archiviert" markieren (nicht sichtbar by default)

---

## 8. ASCII Wireframes — Phone

### 8.1 Spielmodus — Annotation Layer INAKTIV

```
┌──────────────────────────────┐
│ ↑ AUTO-HIDE LEISTE           │
│ ← Bibliothek  [Stück Titel]  │  ← sichtbar nur bei Tap
│ [🔇][🌙][📐][👁 Ebenen][⚙]  │
└──────────────────────────────┘
│                              │
│                              │
│   N O T E N B L A T T        │
│                              │
│  ~~~~ Annotationen ~~~~~     │  ← SVG-Layer (Blau/Grün/Orange)
│  (sichtbar, nicht editierbar)│
│                              │
│                              │
│  [←40%][       ][→60%]       │  ← Tap-Zonen
└──────────────────────────────┘
│ ↓ AUTO-HIDE LEISTE           │
│ [◀ 1/8 ▶]  [📐 Annotieren]  │  ← "Annotieren" = Einstieg
└──────────────────────────────┘
```

### 8.2 Phone — Einstieg per Long-Press

```
┌──────────────────────────────┐
│ ← Spielmodus    [Fertig]     │
├──────────────────────────────┤
│                              │
│   N O T E N B L A T T        │
│                              │
│  [Hier erscheint ein         │
│   Ripple-Effekt am           │
│   Long-Press-Punkt]          │
│                              │
│                              │
├──────────────────────────────┤
│ [🔵▼][✏️][📝][🖊][🎵][🧹] ↩ ↪ │  ← Toolbar erscheint von unten
└──────────────────────────────┘
```

### 8.3 Phone — Annotationsmodus AKTIV (Freihand)

```
┌──────────────────────────────┐
│ ← Spielmodus  [Fertig]       │
├──────────────────────────────┤
│ 🔵 PRIVAT                    │  ← Ebenen-Badge (von Toolbar-Auswahl)
├──────────────────────────────┤
│                              │
│   N O T E N B L A T T        │
│                              │
│  ~~~ bestehende Annot. ~~~   │
│                              │
│      ✏️ (Cursor/Stift)        │
│       /  ← aktuelle Spur     │
│      /                       │
└──────────────────────────────┘
│ [🔵▼] [✏️*][📝][🖊][🎵][🧹][↩][↪]│  ← ✏️* = aktiv (hervorgehoben)
└──────────────────────────────┘
```

### 8.4 Phone — Ebenen-Flyout

```
┌──────────────────────────────┐
│ ← Spielmodus  [Fertig]       │
├──────────────────────────────┤
│                              │
│   [gedimmt]                  │
│                              │
│  ┌──────────────────────┐    │
│  │  Ebene wählen    ✕  │    │
│  ├──────────────────────┤    │
│  │ ● 🔵 Privat         │    │  ← aktiv
│  │   (nur für mich)    │    │
│  ├──────────────────────┤    │
│  │ ○ 🟢 Stimme         │    │
│  │   (2. Klarinette)   │    │
│  ├──────────────────────┤    │
│  │ 🔒 🟠 Orchester      │    │  ← gesperrt (kein Dirigent)
│  │   (nur Dirigent)    │    │
│  └──────────────────────┘    │
│                              │
└──────────────────────────────┘
│ [🔵▼] [✏️][📝][🖊][🎵][🧹][↩][↪]│
└──────────────────────────────┘
```

### 8.5 Phone — Long-Press auf Annotation (Kontextmenü)

```
┌──────────────────────────────┐
│ ← Spielmodus  [Fertig]       │
├──────────────────────────────┤
│                              │
│   N O T E N B L A T T        │
│                              │
│  ┌────────────────────────┐  │
│  │  🔵 Annotation         │  │  ← ausgewählt (Blau-Rand)
│  │  "Atemzeichen"         │  │
│  └────────────────────────┘  │
│        ↑                     │
│  ┌─────────────────────┐     │
│  │ ✏️  Bearbeiten      │     │
│  │ 📋  Kopieren         │     │
│  │ ↕️  Ebene wechseln  │     │
│  │ 🗑   Löschen          │     │  ← rot
│  └─────────────────────┘     │
└──────────────────────────────┘
│ [🔵▼] [✏️][📝][🖊][🎵][🧹][↩][↪]│
└──────────────────────────────┘
```

### 8.6 Phone — Layer-Toggle Panel

```
┌──────────────────────────────┐
│ ← Bibliothek  Stück Titel    │
│ [🔇][🌙][📐][👁*Ebenen][⚙]  │  ← 👁* = aktiv
├──────────────────────────────┤
│                              │
│   N O T E N B L A T T        │
│                              │
│  ┌──────────────────────┐    │
│  │  Ebenen         ✕   │    │
│  ├──────────────────────┤    │
│  │  👁 ■  🔵 Privat    │    │  ← ■ = sichtbar
│  │  👁 □  🟢 Stimme    │    │  ← □ = ausgeblendet
│  │  👁 ■  🟠 Orchester │    │
│  └──────────────────────┘    │
│                              │
└──────────────────────────────┘
```

---

## 9. ASCII Wireframes — Tablet

### 9.1 Tablet — Spielmodus mit Annotations-Layer AKTIV

```
┌────────────────────────────────────────────────────────────┐
│ ←  Bibliothek          Stück Titel              [Fertig]   │
├────────────────────────────────────────────────────────────┤
│ 🔵 PRIVAT  [🔵▼Ebene]                        [👁Ebenen][⚙]│
├──────────┬─────────────────────────────────────────────────┤
│          │                                                  │
│ [✏️]*    │                                                  │
│ [📝]     │          N O T E N B L A T T                    │
│ [🖊]     │                                                  │
│ [🎵]     │    ~~~ bestehende Annotationen ~~~               │
│ [🧹]     │          (Blau/Grün/Orange Ränder)               │
│ ──────   │                                                  │
│ [↩]      │    ✏️ (Stift-Cursor)                             │
│ [↪]      │      \  aktuelle Spur (Blau)                    │
│          │                                                  │
│          │                                                  │
└──────────┴─────────────────────────────────────────────────┘
  ← Toolbar (vertikal, links, verschiebbar)
  ✏️* = aktives Werkzeug
```

### 9.2 Tablet — Split-View mit Stempel-Picker

```
┌────────────────────────────────────────────────────────────┐
│ ←  Spielmodus           Stück Titel              [Fertig]  │
├──────────┬─────────────────────────────────────────────────┤
│          │                                                  │
│ [✏️]     │          N O T E N B L A T T                    │
│ [📝]     │                                                  │
│ [🖊]     ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│ [🎵]*    │  STEMPEL-PICKER (erscheint über Notenblatt)     │
│ [🧹]     │  ┌──────────────────────────────────────────┐   │
│ ──────   │  │ 🎵 Dynamik   Artikulation   Atem   Nav. │   │
│ [↩]      │  ├──────────────────────────────────────────┤   │
│ [↪]      │  │  pp   p   mp   mf   f   ff   fff        │   │
│          │  │  sfz  sfp  fp  cresc.  dim.              │   │
│          │  │                                          │   │
│          │  │  .  >  ^  ~  tr  gliss.                  │   │
│          │  │                                          │   │
│          │  │  '  V  ,   (Atemzeichen)                 │   │
│          │  └──────────────────────────────────────────┘   │
└──────────┴─────────────────────────────────────────────────┘
```

### 9.3 Tablet — Dirigent (Orchester-Ebene aktiv)

```
┌────────────────────────────────────────────────────────────┐
│ ←  Spielmodus           Stück Titel              [Fertig]  │
├────────────────────────────────────────────────────────────┤
│ 🟠 ORCHESTER  [🟠▼ Ebene]                    [Senden: alle]│
├──────────┬─────────────────────────────────────────────────┤
│          │                                                  │
│ [✏️]     │          N O T E N B L A T T                    │
│ [📝]     │                                                  │
│ [🖊]     │    🟠┌─────────────────────────────┐            │
│ [🎵]     │      │  "ff ab Takt 12 !!"         │            │
│ [🧹]     │      │  🎼 Dirigent · gerade eben  │            │
│ ──────   │      └─────────────────────────────┘            │
│ [↩]      │                                                  │
│ [↪]      │    🔵┌──────────────┐                           │
│          │      │ ' Atemzeichen│  (privat, anderer Nutzer  │
│          │      │  👤 nicht    │   sieht das nicht)        │
│          │      │  sichtbar f. │                           │
│          │      └──────────────┘                           │
└──────────┴─────────────────────────────────────────────────┘
  Orange Toolbar-Akzent = Orchester-Ebene aktiv
  "Senden: alle" = Bestätigung vor Broadcast (nur Dirigent)
```

### 9.4 Tablet — Offline-Zustand (Stimmen-Annotation pending)

```
┌────────────────────────────────────────────────────────────┐
│ ←  Spielmodus           Stück Titel              [Fertig]  │
├────────────────────────────────────────────────────────────┤
│ 🟢 STIMME  [🟢▼Ebene]              ☁️✗ Offline (3 pending) │
├──────────┬─────────────────────────────────────────────────┤
│          │                                                  │
│ [✏️]*    │          N O T E N B L A T T                    │
│ [📝]     │                                                  │
│ [🖊]     │  🟢 ┌─────────────────────────────────────┐     │
│ [🎵]     │     │  mf (pending sync)           ☁️✗  │     │  ← pending indicator
│ [🧹]     │     └─────────────────────────────────────┘     │
│ ──────   │                                                  │
│ [↩]      │                                                  │
│ [↪]      │                                                  │
└──────────┴─────────────────────────────────────────────────┘
  ☁️✗ = Offline-Indikator in Statuszeile
  Annotationen funktionieren — werden lokal gespeichert
```

---

## 10. Abhängigkeiten

### 10.1 Für Hill (Frontend — Flutter)

| # | Komponente | Beschreibung |
|---|-----------|--------------|
| F1 | `AnnotationLayer` Widget | SVG-Layer über `pdfrx`-Widget, Z-Order korrekt |
| F2 | `AnnotationToolbar` | Horizontal (Phone) + Vertikal (Tablet), verschiebbar |
| F3 | `LayerPicker` Flyout | Ebenen-Auswahl Bottom Sheet (Phone) / Popover (Tablet) |
| F4 | `StampPicker` Sheet | Grid mit musikalischen Symbolen, kategorisiert |
| F5 | `AnnotationContextMenu` | Long-Press Menü auf Annotation |
| F6 | `LayerTogglePanel` | Ein-/Ausblenden pro Ebene |
| F7 | Stylus-Erkennung | `PointerDeviceKind.stylus` → sofort annotieren |
| F8 | Undo/Redo Stack | Session-lokal, unbegrenzt |
| F9 | Offline-Indikator | `☁️✗` in Toolbar wenn `pending_sync > 0` |
| F10 | Relative SVG-Koordinaten | Normiert auf 0-1 der Seitengröße |

### 10.2 Für Banner (Backend — ASP.NET Core)

| # | Endpoint | Beschreibung |
|---|----------|--------------|
| B1 | `POST /api/annotations` | Annotation erstellen (mit Layer-Check) |
| B2 | `PATCH /api/annotations/{id}` | Annotation bearbeiten |
| B3 | `DELETE /api/annotations/{id}` | Annotation löschen (mit Soft-Delete) |
| B4 | `GET /api/scores/{id}/annotations` | Alle Annotationen für ein Stück laden |
| B5 | SignalR Hub: `AnnotationHub` | Real-time Push für Stimmen/Orchester-Layer |
| B6 | `annotation_added` Event | Broadcast neuer Annotation |
| B7 | `annotation_modified` Event | Broadcast Änderung |
| B8 | `annotation_deleted` Event | Broadcast Löschen |
| B9 | Berechtigungsprüfung | Orchester-Layer: nur Dirigent/Admin-Rolle |
| B10 | `GET /api/annotations/deleted` | Recovery-Endpoint für Soft-Delete (30 Tage) |

---

## 11. Offene Fragen

| # | Frage | Für | Priorität |
|---|-------|-----|-----------|
| Q1 | **Farb-Schema:** Annotations-Ebenen-Farben = Konfigurations-Ebenen-Farben? Oder eigenes Schema? Derzeit werden in `spezifikation.md` Privat=Grün/Stimme=Blau/Orchester=Orange verwendet, was vom Konfig-Schema (Privat=Blau/Grün/Orange) abweicht. | Thomas | Hoch |
| Q2 | **Stimmen-Annotations-Sichtbarkeit:** Können Musiker anderer Stimmen die Stimmen-Annotationen anderer Register sehen? (Default: nein) | Thomas | Mittel |
| Q3 | **Orchester-Annotation bestätigen:** Soll der Dirigent einen „Senden"-Button tippen müssen, bevor eine Orchester-Annotation synchronisiert wird? Oder sofort? | Thomas | Mittel |
| Q4 | **Offline für Stimmen/Orchester:** Wie lang dürfen Annotationen im `pending_sync`-Zustand bleiben? Timeout? | Banner | Niedrig |
| Q5 | **Eigene Stempel pro Kapelle:** Admin kann kapellenweite Stamp-Sets definieren? Umfang für M1? | Thomas | Niedrig |
| Q6 | **Stimmen-Annotationen bei Fallback-Stimme:** Wenn ein Musiker Fallback-Stimme spielt (§ stimmenauswahl.md), sieht er die Stimmen-Annotationen der Fallback-Stimme oder seiner eigentlichen Stimme? | Stark/Banner | Mittel |
