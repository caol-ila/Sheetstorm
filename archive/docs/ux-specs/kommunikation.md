# UX-Spec: Kommunikation — Sheetstorm

> **Version:** 1.0  
> **Status:** Entwurf — Review durch Hill (Frontend) ausstehend  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-28  
> **Meilenstein:** M2 — Vereinsleben & Aufführung  
> **Issue:** TBD  
> **Referenzen:** `docs/feature-specs/kommunikation-spec.md`, `docs/ux-design.md`, `docs/ux-konfiguration.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Kontext](#1-übersicht--kontext)
2. [Design-Tokens (Referenz)](#2-design-tokens-referenz)
3. [Board-Feed: Posts & Navigation](#3-board-feed-posts--navigation)
4. [Post erstellen & bearbeiten](#4-post-erstellen--bearbeiten)
5. [Kommentare & Interaktion](#5-kommentare--interaktion)
6. [Reaktionen](#6-reaktionen)
7. [Pin-Funktion](#7-pin-funktion)
8. [Umfragen erstellen & Editor](#8-umfragen-erstellen--editor)
9. [Umfrage: Abstimmungs-Ansicht](#9-umfrage-abstimmungs-ansicht)
10. [Notification-Einstellungen](#10-notification-einstellungen)
11. [Navigation & Routing](#11-navigation--routing)
12. [Error States & Leerzustände](#12-error-states--leerzustände)
13. [Interaction Patterns](#13-interaction-patterns)
14. [Accessibility](#14-accessibility)
15. [Abhängigkeiten](#15-abhängigkeiten)

---

## 1. Übersicht & Kontext

### 1.1 Ziel

Das Kommunikationsmodul ist der **Social Hub der Kapelle** — ein Ort, an dem Dirigenten, Admins und Mitglieder Informationen austauschen, Meinungsbilder einholen und sich organisieren können. Anders als allgemeine Messenger-Apps ist die Kommunikation in Sheetstorm **Kapellen-kontextbezogen** und **Register-basiert** — Dirigenten können gezielt einzelne Register erreichen.

### 1.2 Nutzungskontext

**Primäre Personas:**
- **Dirigent** — Kommuniziert mit der gesamten Kapelle oder einzelnen Registern (z.B. "Alle Trompeten zu Satzprobe um 18 Uhr")
- **Admin** — Verwaltet Kommunikationskanäle, moderiert Posts, pinnt wichtige Infos
- **Registerführer** — Kommuniziert mit eigenem Register
- **Musiker** — Liest Posts, kommentiert, reagiert, nimmt an Umfragen teil

**Nutzungsszenarien:**
- **Probe-Organisation:** Schnelle Info über Probenausfall, neue Besetzung, Raum-Änderung
- **Terminfindung:** Umfragen für Satzproben, Konzerttermine
- **Vereinsleben:** Diskussion über Vereinsangelegenheiten, Schichtplanung für Feste
- **Wichtige Infos:** Gepinnte Posts mit Vereinsordnung, Willkommenstext, DSGVO-Hinweis

### 1.3 Kernmerkmale

1. **Board-Feed:** Chronologischer Feed mit Posts, Umfragen, Kommentaren
2. **Register-basierte Kommunikation:** Posts/Umfragen können an bestimmte Register gerichtet sein
3. **Pin-Funktion:** Bis zu 3 Posts können oben fixiert werden
4. **1-Ebene-Kommentare:** Antworten direkt auf Posts (keine verschachtelten Threads)
5. **Emoji-Reaktionen:** Schnelles Feedback mit vordefinierten Emojis
6. **Umfragen:** Einzel-/Mehrfachauswahl, anonym/öffentlich, Echtzeit-Ergebnisse
7. **Granulare Push-Benachrichtigungen:** Pro Kapelle, pro Typ (Posts/Umfragen/Kommentare)

### 1.4 Abgrenzung zu MS3+

**Im Scope MS2:**
- Nachrichten-Board mit Posts, 1-Ebene-Kommentare, Emoji-Reaktionen
- Umfragen (Einzel-/Mehrfachauswahl)
- Post-Anhänge (Bilder, PDFs)
- Push-Benachrichtigungen (FCM/APNs)
- Pin-Funktion (max. 3 Posts)

**Außerhalb Scope (MS3+):**
- Private Direktnachrichten
- Verschachtelte Threads (Antworten auf Kommentare)
- Custom-Emoji, GIF-Support
- Video-Uploads
- Archiv-Ansicht, Kategorien
- Matrix-Fragen, Conditional-Logic für Umfragen
- SMS- oder E-Mail-Fallback für Benachrichtigungen

---

## 2. Design-Tokens (Referenz)

Alle hier verwendeten Token stammen aus `docs/ux-design.md` § 7.

| Token | Wert | Verwendung in Kommunikation |
|-------|------|----------------------------|
| `color-primary` | `#1A56DB` | CTA-Buttons, Links, Hashtags |
| `color-success` | `#16A34A` | Umfrage-Abstimmung bestätigt |
| `color-warning` | `#D97706` | Pin-Badge |
| `color-error` | `#DC2626` | Fehler-Messages |
| `color-text-secondary` | `#6B7280` | Timestamps, Helper-Text |
| `color-border` | `#E5E7EB` | Card-Rahmen, Trennlinien |
| `color-background` | `#FFFFFF` | Screen-Hintergrund |
| `color-card` | `#F9FAFB` | Post-Card-Hintergrund |
| `font-size-base` | `16sp` | Post-Text, Kommentare |
| `font-size-sm` | `14sp` | Timestamps, Metadaten |
| `font-size-lg` | `20sp` | Post-Titel |
| `font-weight-semibold` | `600` | Autornamen, Umfrage-Fragen |
| `touch-target-min` | `44×44px` | Alle interaktiven Elemente |
| `border-radius-md` | `8px` | Post-Cards, Buttons |
| `space-sm` | `8px` | Interne Card-Abstände |
| `space-md` | `16px` | Standard-Padding |
| `space-lg` | `24px` | Abschnitte |

---

## 3. Board-Feed: Posts & Navigation

### 3.1 Board-Übersicht — Phone (Hochformat)

```
┌─────────────────────────────┐
│  Board               🔍  +  │ ← Header: Board-Titel, Suche, Neu erstellen
├─────────────────────────────┤
│  [Alle]  [Pinned]  [Polls] │ ← Filter-Chips (horizontal scroll)
├─────────────────────────────┤
│  GEPINNTE POSTS (3)         │ ← Abschnitt nur wenn gepinnte Posts existieren
│  ┌─────────────────────────┐│
│  │ 📌 Willkommen bei...   ││ ← Pin-Badge in Ecke
│  │ Max Mustermann · Admin  ││
│  │ vor 2 Wochen            ││
│  │                         ││
│  │ Willkommen in der...    ││
│  │                         ││
│  │ 👍 12  ❤️ 5  💬 3       ││ ← Reaktionen, Kommentare
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ 📌 Wichtig: Vereins...  ││
│  │ Rudi Keller · Admin     ││
│  │ vor 1 Woche             ││
│  │ [PDF-Icon] vereins...pdf││
│  │ 👍 8                    ││
│  └─────────────────────────┘│
├─────────────────────────────┤
│  NEUESTE                    │
│  ┌─────────────────────────┐│
│  │ Probenausfall am 15.04. ││
│  │ Klaus Dieter · Dirigent ││
│  │ vor 5 Minuten · 🎺 Alle ││ ← Register-Badge
│  │                         ││
│  │ Aufgrund der Hallen...  ││
│  │ [Bild-Thumbnail]        ││
│  │                         ││
│  │ 👍 2  💬 1              ││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ 📊 Umfrage: Termin...   ││ ← Umfrage-Card (unterschiedliches Design)
│  │ Max · vor 10 Minuten    ││
│  │                         ││
│  │ Welcher Termin passt?   ││
│  │ ○ Montag, 15.04.   12%  ││ ← Live-Ergebnisse
│  │ ○ Mittwoch, 17.04. 34%  ││
│  │ ○ Freitag, 19.04.  54%  ││
│  │                         ││
│  │ ✓ Du hast abgestimmt    ││
│  │ 38 Teilnehmer · 2T übrig││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ Neue Besetzung: Trp. 2  ││
│  │ Klaus · vor 2 Stunden   ││
│  │ · 🎺 Trompeten          ││ ← Register-spezifisch
│  │ Anna übernimmt ab...    ││
│  │ 👏 5  ❤️ 3              ││
│  └─────────────────────────┘│
│                             │
└─────────────────────────────┘
│ [Bibliothek] [Board] [Prof.]│ ← Bottom-Navigation
```

**Design-Entscheidungen:**

1. **Card-basiertes Layout:** Jeder Post ist eine Card mit `border-radius-md`, `space-md` Padding, Schatten für Depth
2. **Zweistufige Hierarchie:** Gepinnte Posts oben (gelber Hintergrund), dann chronologischer Feed
3. **Register-Badge:** Wenn Post an bestimmte Register gerichtet ist, Badge mit 🎺 und Register-Namen
4. **Reaktionen inline:** Emoji-Reaktionen werden unter Post aggregiert angezeigt
5. **Thumbnail-Preview:** Anhänge (Bilder, PDFs) werden als kleine Thumbnails angezeigt

### 3.2 Board-Übersicht — Tablet/Desktop (600px+)

```
┌─────────────────────────────────────────────────────────────────────┐
│  Sheetstorm                          Musikkapelle Beispiel  ▼   👤  │
├──────────────┬──────────────────────────────────────────────────────┤
│              │  Board                              🔍        [+ Post]│
│  📚 Biblioth.│  ─────────────────────────────────────────────────── │
│  🎵 Setlists │  [Alle]  [Pinned]  [Umfragen]  [Register ▼]          │
│  📅 Kalender │  ─────────────────────────────────────────────────── │
│  💬 Board    │                                                       │
│  👥 Mitglied.│  GEPINNTE POSTS                                      │
│              │  ┌───────────────────────────────────────────────┐  │
│              │  │ 📌 Willkommen bei der Musikkapelle Beispiel   │  │
│              │  │ [Avatar] Max Mustermann · Admin               │  │
│              │  │ vor 2 Wochen · 🎺 Alle                        │  │
│              │  │                                               │  │
│              │  │ Hallo und willkommen! Hier findet ihr alle... │  │
│              │  │                                               │  │
│              │  │ 👍 12  👏 3  ❤️ 5  💬 3 Kommentare            │  │
│              │  └───────────────────────────────────────────────┘  │
│              │                                                       │
│              │  ┌─────────────────┬───────────────────────────────┐│
│              │  │ 📌 Vereinsordnun│ 📌 DSGVO-Hinweis für...      ││ ← 2 Spalten
│              │  │ g (PDF)         │ [Avatar] Rudi · Admin        ││
│              │  │ [Avatar] Rudi · │ vor 1 Woche                  ││
│              │  │ vor 1 Woche     │ Anhang: dsgvo.pdf            ││
│              │  │ 👍 8            │ 👍 5                         ││
│              │  └─────────────────┴───────────────────────────────┘│
│              │  ─────────────────────────────────────────────────── │
│              │  NEUESTE                                             │
│              │  ┌───────────────────────────────────────────────┐  │
│              │  │ Probenausfall am 15.04.                       │  │
│              │  │ [Avatar] Klaus Dieter · Dirigent              │  │
│              │  │ vor 5 Minuten · 🎺 Alle                       │  │
│              │  │                                               │  │
│              │  │ Aufgrund der Hallensanierung fällt die Probe  │  │
│              │  │ am 15.04. aus. Nächster Termin: 22.04.       │  │
│              │  │ [Bild: Hallenplan.jpg 480×320px]              │  │
│              │  │                                               │  │
│              │  │ 👍 2  💬 1 Kommentar                          │  │
│              │  └───────────────────────────────────────────────┘  │
│              │                                                       │
│              │  ┌───────────────────────────────────────────────┐  │
│              │  │ 📊 Welcher Termin passt für Satzprobe?        │  │
│              │  │ [Avatar] Max · Dirigent · vor 10 Minuten      │  │
│              │  │ · 🎺 Trompeten, Posaunen                      │  │
│              │  │                                               │  │
│              │  │ ○ Montag, 15.04. um 18:00    █████░░░░  12%   │  │
│              │  │ ● Mittwoch, 17.04. um 19:00  ██████░░░  34%   │  │ ← ● = abgestimmt
│              │  │ ○ Freitag, 19.04. um 18:30   ████████░  54%   │  │
│              │  │                                               │  │
│              │  │ [Stimme ändern]  38 Teilnehmer · 2 Tage übrig│  │
│              │  └───────────────────────────────────────────────┘  │
│              │                                                       │
│              │  [Weitere Posts…]                                    │
└──────────────┴──────────────────────────────────────────────────────┘
```

**Design-Entscheidungen (Tablet/Desktop):**

1. **2-Spalten-Layout für gepinnte Posts:** Wenn mehr als 1 Post gepinnt ist, Side-by-Side-Darstellung (wenn Platz vorhanden)
2. **Größere Thumbnails:** Auf Desktop/Tablet werden Bild-Anhänge größer angezeigt (max. 480×320px)
3. **Inline-Umfrage-Ansicht:** Umfragen werden direkt im Feed abstimmbar angezeigt, kein separater Screen nötig
4. **Sidebar-Navigation:** Board ist Hauptbereich, Sidebar links zeigt Navigation (siehe `docs/ux-design.md`)

### 3.3 Filter-Chips

```
┌─────────────────────────────────────────────────────┐
│  [Alle]  [Pinned]  [Umfragen]  [Register ▼]  [•••] │ ← Horizontal-Scroll
└─────────────────────────────────────────────────────┘
```

**Interaktion:**
- **Tap auf Chip:** Filtert Feed nach Kategorie
- **Register ▼:** Öffnet Dropdown mit Register-Liste (Alle, Klarinetten, Trompeten, Posaunen, …)
- **[•••]:** Mehr-Optionen (Sortierung, Archivierte Posts zeigen)
- Aktiver Filter: `color-primary` Hintergrund, weißer Text

---

## 4. Post erstellen & bearbeiten

### 4.1 Post erstellen — Phone

**Trigger:** Tap auf `+` in Board-Header (nur sichtbar für Admin/Dirigent/Registerführer)

```
┌─────────────────────────────┐
│  ← Abbrechen    Post erstell│ ← Header
├─────────────────────────────┤
│  Titel *                    │ ← Pflichtfeld-Marker
│  ┌─────────────────────────┐│
│  │ Wichtig: Probenausfall  ││ ← Input: 120 Zeichen max
│  └─────────────────────────┘│
│  120 Zeichen übrig          │ ← Live-Zeichenzähler
│                             │
│  Inhalt *                   │
│  ┌─────────────────────────┐│
│  │ Aufgrund der Hallen...  ││ ← Multiline-Textarea
│  │                         ││   5.000 Zeichen max
│  │                         ││
│  │                         ││
│  └─────────────────────────┘│
│  4.987 Zeichen übrig        │
│                             │
│  An Register                │
│  [🎺 Alle              ▼]  │ ← Dropdown
│                             │
│  Anhänge (0/5)              │
│  ┌───────┐ ┌───────┐       │
│  │  📷   │ │  📁   │       │ ← Kamera, Dateien
│  │ Foto  │ │ PDF   │       │
│  └───────┘ └───────┘       │
│                             │
│  [Vorschau]                 │ ← Optional
│                             │
├─────────────────────────────┤
│  [Veröffentlichen]          │ ← CTA, disabled bis Pflichtfelder ausgefüllt
└─────────────────────────────┘
```

**Validierung (Inline):**
- **Titel:** Live-Validierung, Fehler wenn leer oder > 120 Zeichen
- **Inhalt:** Live-Validierung, Fehler wenn leer oder > 5.000 Zeichen
- **Anhänge:** Max. 5 Dateien, max. 10 MB/Bild, 5 MB/PDF — Fehler bei Überschreitung
- **Veröffentlichen-Button:** Nur aktiv wenn alle Pflichtfelder valide sind

### 4.2 Register-Auswahl (Dropdown)

```
┌─────────────────────────────┐
│  An Register          ✕    │
├─────────────────────────────┤
│  ✓ Alle (Standard)          │ ← Checkbox (Multi-Select)
│  ☐ Klarinetten              │
│  ☐ Trompeten                │
│  ☐ Posaunen                 │
│  ☐ Hörner                   │
│  ☐ Flöten                   │
│  ☐ Schlagwerk               │
│  …                          │
├─────────────────────────────┤
│  [Bestätigen]               │
└─────────────────────────────┘
```

**Verhalten:**
- **Standard:** "Alle" ist vorausgewählt
- **Multi-Select:** Mehrere Register gleichzeitig auswählbar (z.B. "Trompeten + Posaunen")
- Wenn "Alle" gewählt, werden andere deaktiviert (exklusiv)
- **Registerführer:** Sehen nur ihr eigenes Register

### 4.3 Anhang hinzufügen

**Tap auf 📷 Foto:**
```
┌─────────────────────────────┐
│  Foto hinzufügen      ✕    │
├─────────────────────────────┤
│  ┌─────────────────────────┐│
│  │  📷  Kamera             ││
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │  🖼  Galerie            ││
│  └─────────────────────────┘│
└─────────────────────────────┘
```

**Tap auf 📁 PDF:**
```
System-File-Picker → PDF auswählen → Upload + Preview-Icon
```

**Nach Upload:**
```
┌─────────────────────────────┐
│  Anhänge (2/5)              │
│  ┌─────────┬─────────┐      │
│  │ [Thumb] │ [PDF]   │      │ ← Thumbnails mit ✕-Button zum Entfernen
│  │ hallen… │ info.pdf│      │
│  │    ✕    │    ✕    │      │
│  └─────────┴─────────┘      │
│  ┌───────┐ ┌───────┐        │
│  │  📷   │ │  📁   │        │ ← Weitere hinzufügen (bis max. 5)
│  │ Foto  │ │ PDF   │        │
│  └───────┘ └───────┘        │
└─────────────────────────────┘
```

### 4.4 Post erstellen — Tablet/Desktop

```
┌─────────────────────────────────────────────────────────────┐
│  ← Zurück zum Board          Neuen Post erstellen            │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────┬───────────────────────────┐│
│  │  INHALT                      │  VORSCHAU                 ││ ← Split-View
│  │  ────────────────            │  ───────────────          ││
│  │  Titel *                     │  Probenausfall am 15.04.  ││
│  │  [Wichtig: Probenausfall…]   │  Klaus Dieter · Dirigent  ││
│  │  120 Zeichen übrig           │  Gerade eben · 🎺 Alle    ││
│  │                              │                           ││
│  │  Inhalt *                    │  Aufgrund der Hallen...   ││
│  │  [Aufgrund der Hallen…]      │  [Bild-Preview]           ││
│  │  4.987 Zeichen übrig         │                           ││
│  │                              │  👍 👏 ❤️ 😊 🎺           ││
│  │  An Register                 │                           ││
│  │  [🎺 Alle              ▼]    │                           ││
│  │                              │                           ││
│  │  Anhänge (1/5)               │                           ││
│  │  [Thumbnail] [+ Hinzufügen]  │                           ││
│  │                              │                           ││
│  │  [Veröffentlichen]           │                           ││
│  └──────────────────────────────┴───────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

**Design-Entscheidung (Desktop):** Split-View mit Live-Vorschau rechts — Nutzer sieht sofort, wie der Post aussehen wird.

---

## 5. Kommentare & Interaktion

### 5.1 Post mit Kommentaren — Phone

**Trigger:** Tap auf Post-Card im Feed → Post-Detail-Screen

```
┌─────────────────────────────┐
│  ← Board                    │
├─────────────────────────────┤
│  Probenausfall am 15.04.    │ ← Post-Titel (font-size-lg)
│  [Avatar] Klaus · Dirigent  │
│  vor 5 Minuten · 🎺 Alle    │
├─────────────────────────────┤
│  Aufgrund der Hallensanierun│ ← Post-Inhalt (Volltext)
│  g fällt die Probe am 15.04.│
│  aus. Nächster Termin ist   │
│  der 22.04. wie gewohnt.    │
│                             │
│  [Bild: Hallenplan.jpg]     │ ← Anhang (Tap zum Vollbild)
│                             │
│  👍 12  👏 3  ❤️ 5  💬 8    │ ← Reaktionen + Kommentar-Count
├─────────────────────────────┤
│  KOMMENTARE (8)             │
│                             │
│  [Avatar] Anna · vor 2 Min  │
│  Schade, aber verständlich. │
│  Danke für die Info!        │
│  👍 2                       │ ← Reaktionen auf Kommentar (optional MS3+)
│                             │
│  [Avatar] Marco · vor 5 Min │
│  Gut zu wissen. Können wir  │
│  den Termin vielleicht...   │
│  [Bild-Anhang]              │
│                             │
│  [Avatar] Sebastian · 10 Min│
│  👍                         │ ← Kurzer Kommentar (nur Emoji)
│                             │
│  […Weitere Kommentare…]     │
│                             │
├─────────────────────────────┤
│  [Avatar] Dein Kommentar... │ ← Input-Feld (Bottom-Fixed)
│  ┌─────────────────────┬─┐ │
│  │ Schreibe einen Kom… │📷│ │ ← Input + Foto-Button
│  └─────────────────────┴─┘ │
└─────────────────────────────┘
```

**Design-Entscheidungen:**

1. **Chronologische Sortierung:** Älteste Kommentare zuerst (typisch für Diskussionen)
2. **Bottom-Fixed Input:** Kommentar-Eingabe bleibt beim Scrollen am unteren Rand sichtbar
3. **1-Ebene-Kommentare:** Keine verschachtelten Threads — alle Kommentare auf gleicher Ebene
4. **Optional: Bild-Anhang:** Kommentare können 1 Bild enthalten (max. 5 MB)
5. **Autor-Kontext:** Avatar, Name, Rolle, Zeitstempel

### 5.2 Kommentar schreiben — Expanded

```
┌─────────────────────────────┐
│  [Avatar] Dein Kommentar    │
├─────────────────────────────┤
│  ┌─────────────────────────┐│
│  │ Schade, aber verstän…   ││ ← Multiline-Textarea
│  │                         ││   1.000 Zeichen max
│  │                         ││
│  └─────────────────────────┘│
│  987 Zeichen übrig          │
│                             │
│  [📷 Bild hinzufügen]       │
│                             │
│  [Abbrechen]  [Absenden]    │ ← Absenden nur aktiv wenn Text ≥ 1 Zeichen
└─────────────────────────────┘
```

**Interaction:**
- **Tap auf Eingabefeld:** Erweitert zu Multiline-Textarea + Buttons
- **Keyboard öffnet sich automatisch**
- **Absenden:** Kommentar wird sofort im Thread angezeigt (optimistisches Update)
- **Fehlerfall:** Netzwerkfehler → Kommentar mit Retry-Button + Fehlermeldung

### 5.3 Kommentar löschen

**Long-Press auf eigenen Kommentar:**
```
┌─────────────────────────────┐
│  ✏️  Bearbeiten (MS3+)      │ ← Nicht in MS2
│  🗑  Löschen                │
│  🚩  Melden (Admin)         │ ← Nur für Admins
│  ✕  Abbrechen              │
└─────────────────────────────┘
```

**Nach Löschen:**
```
│  [Avatar] Anna · vor 2 Min  │
│  [Kommentar gelöscht]       │ ← Soft-Delete, Platzhalter bleibt
│                             │
```

---

## 6. Reaktionen

### 6.1 Reaktions-Leiste (unter jedem Post)

```
┌─────────────────────────────┐
│  👍 12  👏 3  ❤️ 5  😊 1  🎺 2│ ← Aggregierte Reaktionen
│  [+]                        │ ← + zum Hinzufügen
└─────────────────────────────┘
```

**Interaction:**
- **Tap auf Emoji:** Eigene Reaktion hinzufügen (Toggle) — wenn bereits reagiert, Reaktion entfernen
- **Tap auf [+]:** Reaktions-Picker öffnen

### 6.2 Reaktions-Picker (Bottom Sheet)

```
┌─────────────────────────────┐
│  Reaktion wählen      ✕    │
├─────────────────────────────┤
│  ┌───┬───┬───┬───┬───┐     │
│  │👍 │👏 │❤️ │😊 │🎺 │     │ ← 5 vordefinierte Emoji
│  └───┴───┴───┴───┴───┘     │
│  Daumen Klatschen Herz      │ ← Label unter Emoji
│  hoch                       │
└─────────────────────────────┘
```

**Design-Entscheidungen:**
1. **Nur 5 Emoji:** Begrenzte Auswahl für Konsistenz (👍 👏 ❤️ 😊 🎺)
2. **Toggle-Verhalten:** Erneuter Tap auf gewähltes Emoji entfernt Reaktion
3. **Nur 1 Reaktion pro Nutzer:** Wenn anderes Emoji gewählt, vorherige wird ersetzt
4. **Kein Push für Reaktionen:** Zu viel Rauschen — nur für Kommentare

### 6.3 Reaktions-Detail (Wer hat reagiert?)

**Tap auf Reaktionszahl (z.B. "👍 12"):**
```
┌─────────────────────────────┐
│  👍 Daumen hoch (12)   ✕   │
├─────────────────────────────┤
│  [Avatar] Anna Müller       │
│  [Avatar] Marco Franzen     │
│  [Avatar] Sebastian Koch    │
│  [Avatar] Lisa Weber        │
│  [Avatar] Tom Schneider     │
│  […und 7 weitere]           │
└─────────────────────────────┘
```

**Hinweis:** Bei mehr als 5 Nutzern: Erste 5 anzeigen + "…und X weitere"

---

## 7. Pin-Funktion

### 7.1 Post pinnen (Admin/Dirigent)

**Post-Menü (3-Dot-Icon):**
```
┌─────────────────────────────┐
│  📌 Pinnen                  │ ← Nur wenn nicht gepinnt
│  🔗 Link teilen             │
│  ✏️  Bearbeiten             │ ← Nur eigener Post
│  🗑  Löschen                │ ← Nur eigener Post/Admin
└─────────────────────────────┘
```

**Nach Pinnen:**
```
│  ┌─────────────────────────┐│
│  │ 📌 Wichtig: Vereins…    ││ ← Pin-Badge in Ecke
│  │ [Avatar] Rudi · Admin   ││
│  │ vor 1 Woche             ││
│  │ [Gelber Hintergrund]    ││ ← Visueller Unterschied
│  └─────────────────────────┘│
```

### 7.2 Pin-Limit (Max. 3 Posts)

**Versuch, 4. Post zu pinnen:**
```
┌─────────────────────────────┐
│  ⚠️  Maximum erreicht       │
├─────────────────────────────┤
│  Du kannst maximal 3 Posts  │
│  gleichzeitig pinnen.       │
│                             │
│  Möchtest du einen anderen  │
│  Post entpinnen?            │
│                             │
│  ┌─────────────────────────┐│
│  │ 📌 Willkommen bei...    ││ ← Liste der gepinnten Posts
│  │ Max · vor 2 Wochen      ││
│  │ [Entpinnen]             ││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ 📌 Vereinsordnung…      ││
│  │ Rudi · vor 1 Woche      ││
│  │ [Entpinnen]             ││
│  └─────────────────────────┘│
│                             │
│  [Abbrechen]                │
└─────────────────────────────┘
```

### 7.3 Post entpinnen

**Post-Menü (gepinnter Post):**
```
┌─────────────────────────────┐
│  📌 Entpinnen               │ ← Statt "Pinnen"
│  🔗 Link teilen             │
│  ✏️  Bearbeiten             │
│  🗑  Löschen                │
└─────────────────────────────┘
```

**Nach Entpinnen:** Post kehrt an seine chronologische Position im Feed zurück.

---

## 8. Umfragen erstellen & Editor

### 8.1 Umfrage erstellen — Phone

**Trigger:** Tap auf `+` in Board-Header → "Umfrage erstellen"

```
┌─────────────────────────────┐
│  ← Abbrechen  Umfrage erstel│
├─────────────────────────────┤
│  Frage *                    │
│  ┌─────────────────────────┐│
│  │ Welcher Termin passt?   ││ ← Input: 200 Zeichen max
│  └─────────────────────────┘│
│  200 Zeichen übrig          │
│                             │
│  OPTIONEN (min. 2, max. 10) │
│  ┌─────────────────────┬─┐ │
│  │ 1. Montag, 15.04.   │✕│ │ ← Optionen mit ✕-Button
│  └─────────────────────┴─┘ │
│  ┌─────────────────────┬─┐ │
│  │ 2. Mittwoch, 17.04. │✕│ │
│  └─────────────────────┴─┘ │
│  ┌─────────────────────┬─┐ │
│  │ 3. Freitag, 19.04.  │✕│ │
│  └─────────────────────┴─┘ │
│  [+ Option hinzufügen]      │ ← Disabled wenn 10 erreicht
│                             │
│  EINSTELLUNGEN              │
│  Auswahltyp                 │
│  ○ Einzelauswahl (Standard) │
│  ○ Mehrfachauswahl          │
│                             │
│  Ablaufdatum                │
│  [7 Tage              ▼]   │ ← Dropdown: 1, 3, 7, 14, 30 Tage, kein Ablauf
│                             │
│  Anonymität                 │
│  ☑ Anonym abstimmen         │ ← Checkbox (Standard: An)
│                             │
│  Ergebnisse                 │
│  ○ Sofort sichtbar (Std.)   │
│  ○ Nach Ablauf sichtbar     │
│                             │
│  An Register                │
│  [🎺 Alle              ▼]  │
│                             │
├─────────────────────────────┤
│  [Erstellen]                │ ← Disabled bis min. 2 Optionen + Frage
└─────────────────────────────┘
```

**Validierung:**
- **Frage:** Pflichtfeld, 1-200 Zeichen
- **Optionen:** Mindestens 2, maximal 10, jeweils 1-100 Zeichen
- **Ablaufdatum:** Muss in der Zukunft liegen (Validierung bei Submit)
- **Erstellen-Button:** Nur aktiv wenn alle Pflichtfelder valide

### 8.2 Option hinzufügen

**Tap auf [+ Option hinzufügen]:**
```
│  ┌─────────────────────┬─┐ │
│  │ 4. [Cursor]         │✕│ │ ← Neue Option mit Autofokus
│  └─────────────────────┴─┘ │
```

**Auto-Nummerierung:** Optionen werden automatisch nummeriert (1., 2., 3., …)

### 8.3 Umfrage erstellen — Tablet/Desktop

```
┌─────────────────────────────────────────────────────────────┐
│  ← Zurück zum Board          Neue Umfrage erstellen          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────┬───────────────────────────┐│
│  │  INHALT                      │  VORSCHAU                 ││
│  │  ────────────────            │  ───────────────          ││
│  │  Frage *                     │  📊 Welcher Termin passt? ││
│  │  [Welcher Termin…]           │  Max · Dirigent           ││
│  │  200 Zeichen übrig           │  Gerade eben · 🎺 Alle    ││
│  │                              │                           ││
│  │  OPTIONEN (2/10)             │  ○ Montag, 15.04.    0%   ││
│  │  [1. Montag, 15.04.    ✕]    │  ○ Mittwoch, 17.04.  0%   ││
│  │  [2. Mittwoch, 17.04.  ✕]    │  ○ Freitag, 19.04.   0%   ││
│  │  [+ Option hinzufügen]       │                           ││
│  │                              │  0 Teilnehmer · 7T übrig  ││
│  │  EINSTELLUNGEN               │                           ││
│  │  Auswahltyp: ○ Einzel ○ Mehr│                           ││
│  │  Ablauf: [7 Tage ▼]          │                           ││
│  │  ☑ Anonym  ○ Sofort sichtbar│                           ││
│  │  An Register: [Alle ▼]       │                           ││
│  │                              │                           ││
│  │  [Erstellen]                 │                           ││
│  └──────────────────────────────┴───────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## 9. Umfrage: Abstimmungs-Ansicht

### 9.1 Umfrage im Feed (noch nicht abgestimmt) — Phone

```
┌─────────────────────────────┐
│  📊 Umfrage                 │ ← Icon + Label
│  [Avatar] Max · Dirigent    │
│  vor 10 Minuten · 🎺 Alle   │
├─────────────────────────────┤
│  Welcher Termin passt für   │ ← Frage (font-weight-semibold)
│  die Satzprobe?             │
│                             │
│  ○ Montag, 15.04. um 18:00  │ ← Radio-Buttons (Einzelauswahl)
│  ○ Mittwoch, 17.04. um 19:00│
│  ○ Freitag, 19.04. um 18:30 │
│                             │
│  [Abstimmen]                │ ← Disabled bis Option gewählt
│                             │
│  0 Teilnehmer · 7 Tage übrig│ ← Metadaten
└─────────────────────────────┘
```

### 9.2 Umfrage (Mehrfachauswahl)

```
│  ☐ Montag, 15.04. um 18:00  │ ← Checkboxen (Mehrfachauswahl)
│  ☐ Mittwoch, 17.04. um 19:00│
│  ☐ Freitag, 19.04. um 18:30 │
```

### 9.3 Umfrage (nach Abstimmung, Ergebnisse sofort sichtbar)

```
┌─────────────────────────────┐
│  📊 Umfrage                 │
│  [Avatar] Max · Dirigent    │
│  vor 10 Minuten · 🎺 Alle   │
├─────────────────────────────┤
│  Welcher Termin passt für   │
│  die Satzprobe?             │
│                             │
│  ○ Montag, 15.04.           │
│  ██████░░░░░░░░░  12%  (5)  │ ← Progress-Bar + Prozent + Anzahl
│                             │
│  ● Mittwoch, 17.04.         │ ← ● = eigene Stimme
│  ███████████░░░░  34% (14)  │
│                             │
│  ○ Freitag, 19.04.          │
│  ████████████░░  54% (22)   │
│                             │
│  [Stimme ändern]            │ ← Button nur wenn Umfrage nicht abgelaufen
│                             │
│  ✓ Du hast abgestimmt       │ ← Bestätigungs-Badge
│  41 Teilnehmer · 6T 23h übrig│
└─────────────────────────────┘
```

**Design-Entscheidungen:**
1. **Live-Ergebnisse:** Sofort nach Abstimmung sichtbar (wenn "Sofort sichtbar" gewählt)
2. **Eigene Stimme markiert:** ● statt ○ bei gewählter Option
3. **Progress-Bars:** Visuell dominantes Element für schnelle Orientierung
4. **Stimme ändern:** Immer möglich bis Ablauf — dann wird vorherige Stimme ersetzt

### 9.4 Umfrage (Ergebnisse nach Ablauf sichtbar, vor Abstimmung)

```
│  ○ Montag, 15.04. um 18:00  │
│  ○ Mittwoch, 17.04. um 19:00│
│  ○ Freitag, 19.04. um 18:30 │
│                             │
│  [Abstimmen]                │
│                             │
│  ℹ️ Ergebnisse werden nach  │ ← Hinweis
│  Ablauf der Umfrage angezeig│
│  41 Teilnehmer · 6T 23h übrig│
```

**Nach Abstimmung (vor Ablauf):**
```
│  ● Mittwoch, 17.04.         │ ← Eigene Stimme sichtbar
│  [Stimme ändern]            │
│                             │
│  ✓ Du hast abgestimmt       │
│  ℹ️ Ergebnisse werden nach  │
│  Ablauf angezeigt           │
│  41 Teilnehmer · 6T 23h übrig│
```

### 9.5 Umfrage (abgelaufen)

```
┌─────────────────────────────┐
│  📊 Umfrage · ⏰ Abgelaufen │ ← Badge
│  [Avatar] Max · Dirigent    │
│  vor 1 Woche · 🎺 Alle      │
├─────────────────────────────┤
│  Welcher Termin passt für   │
│  die Satzprobe?             │
│                             │
│  ○ Montag, 15.04.           │
│  ██████░░░░░░░░░  12%  (5)  │
│                             │
│  ● Mittwoch, 17.04.         │
│  ███████████░░░░  34% (14)  │
│                             │
│  ○ Freitag, 19.04.          │
│  ████████████░░  54% (22)   │
│                             │
│  ⏰ Umfrage abgelaufen      │ ← Hinweis
│  41 Teilnehmer              │
└─────────────────────────────┘
```

### 9.6 Umfrage-Detail (Wer hat wie abgestimmt?) — Öffentliche Umfrage

**Tap auf Umfrage-Card → Detail-Screen:**
```
┌─────────────────────────────┐
│  ← Board                    │
├─────────────────────────────┤
│  📊 Welcher Termin passt?   │
│  [Avatar] Max · Dirigent    │
│  vor 10 Minuten · 🎺 Alle   │
├─────────────────────────────┤
│  ○ Montag, 15.04.           │
│  ████████░░░  34% (14)      │
│  [14 Personen anzeigen ▼]   │ ← Collapsible
│                             │
│  ● Mittwoch, 17.04.         │
│  ████████████  54% (22)     │
│  [22 Personen anzeigen ▼]   │
│                             │
│  ○ Freitag, 19.04.          │
│  ██████░░░░░░  12% (5)      │
│  [5 Personen anzeigen ▼]    │
│                             │
│  [Stimme ändern]            │
│                             │
│  41 Teilnehmer · 6T 23h übrig│
└─────────────────────────────┘
```

**Expanded (Tap auf "14 Personen anzeigen"):**
```
│  ○ Montag, 15.04.           │
│  ████████░░░  34% (14)      │
│  [14 Personen ausblenden ▲] │
│  ┌─────────────────────────┐│
│  │ [Avatar] Anna Müller    ││
│  │ [Avatar] Marco Franzen  ││
│  │ [Avatar] Sebastian Koch ││
│  │ […und 11 weitere]       ││
│  └─────────────────────────┘│
```

**Anonyme Umfrage:** Keine "Personen anzeigen"-Option, nur aggregierte Ergebnisse.

---

## 10. Notification-Einstellungen

### 10.1 Benachrichtigungs-Einstellungen — Phone

**Zugangspunkt:** Profil → Einstellungen → Benachrichtigungen

```
┌─────────────────────────────┐
│  ← Einstellungen            │
│  Benachrichtigungen         │
├─────────────────────────────┤
│  GLOBAL                     │
│  ☑ Push-Benachrichtigungen  │ ← Master-Switch
│     aktiviert               │
│                             │
│  ☐ Sound                    │
│  ☐ Vibration                │
│                             │
├─────────────────────────────┤
│  PRO KAPELLE                │
│                             │
│  🏛 Musikkapelle Beispiel   │
│  [Einstellungen ▼]          │ ← Collapsible
│                             │
│  🏛 Blaskapelle Nachbarort  │
│  [Einstellungen ▼]          │
│                             │
└─────────────────────────────┘
```

### 10.2 Kapellen-spezifische Einstellungen (Expanded)

```
│  🏛 Musikkapelle Beispiel   │
│  [Einstellungen ▲]          │ ← Expanded
│  ┌─────────────────────────┐│
│  │ ☑ Alle Benachrichtigung.││ ← Master-Switch (Kapelle)
│  │                         ││
│  │ KATEGORIEN              ││
│  │ ☑ Neue Posts            ││
│  │ ☑ Neue Umfragen         ││
│  │ ☑ Kommentare auf meine  ││
│  │   Posts                 ││
│  │ ☐ Umfrage-Ergebnisse    ││
│  │ ☐ Reaktionen auf meine  ││
│  │   Posts (MS3+)          ││
│  │                         ││
│  │ REGISTER-FILTER         ││
│  │ ☑ Benachrichtigungen nur││
│  │   für meine Register    ││ ← Wenn aktiviert: Nur Posts/Umfragen für eigene Register
│  └─────────────────────────┘│
```

**Design-Entscheidungen:**
1. **3-Ebenen-Hierarchie:** Global → Pro Kapelle → Pro Kategorie
2. **Master-Switches:** Global deaktiviert → alle Kapellen aus; Kapelle deaktiviert → alle Kategorien aus
3. **Register-Filter:** Optional — nur Benachrichtigungen für Posts/Umfragen erhalten, die an eigene Register gerichtet sind
4. **Granularität:** Jede Kategorie einzeln aktivierbar/deaktivierbar

### 10.3 Benachrichtigungs-Einstellungen — Tablet/Desktop

```
┌──────────────────────────────────────────────────────────────┐
│  Sheetstorm                             Max Mustermann  ▼  👤│
├──────────────┬───────────────────────────────────────────────┤
│              │  Benachrichtigungen                            │
│  📚 Biblioth.│  ───────────────────────────────────────────── │
│  🎵 Setlists │                                                │
│  📅 Kalender │  GLOBAL                                        │
│  💬 Board    │  ☑ Push-Benachrichtigungen aktiviert          │
│  👥 Mitglied.│  ☐ Sound  ☐ Vibration                         │
│              │  ───────────────────────────────────────────── │
│  PROFIL      │  PRO KAPELLE                                   │
│  👤 Profil   │                                                │
│  ⚙ Einstellg.│  ┌────────────────────────────────────────────┐│
│  🔔 Benach.  │  │ 🏛 Musikkapelle Beispiel                  ││
│              │  │ ☑ Alle Benachrichtigungen                 ││
│              │  │                                           ││
│              │  │ KATEGORIEN                                ││
│              │  │ ☑ Neue Posts                              ││
│              │  │ ☑ Neue Umfragen                           ││
│              │  │ ☑ Kommentare auf meine Posts              ││
│              │  │ ☐ Umfrage-Ergebnisse                      ││
│              │  │                                           ││
│              │  │ REGISTER-FILTER                           ││
│              │  │ ☑ Nur für meine Register (Klarinetten)    ││
│              │  └────────────────────────────────────────────┘│
│              │                                                │
│              │  ┌────────────────────────────────────────────┐│
│              │  │ 🏛 Blaskapelle Nachbarort                 ││
│              │  │ ☐ Alle Benachrichtigungen (deaktiviert)   ││
│              │  └────────────────────────────────────────────┘│
└──────────────┴───────────────────────────────────────────────┘
```

### 10.4 Push-Benachrichtigung (Notification-Sample)

**iOS/Android System-Notification:**
```
┌─────────────────────────────────────┐
│  🎵 Sheetstorm — Musikkapelle Bsp.  │
│  ────────────────────────────────   │
│  Neuer Post: Probenausfall am 15.04.│ ← Titel
│  Klaus Dieter: Aufgrund der...      │ ← Body (erste 100 Zeichen)
│  vor 2 Minuten                      │
└─────────────────────────────────────┘
```

**Tap auf Notification:** Öffnet App → Navigiert direkt zum Post-Detail

---

## 11. Navigation & Routing

### 11.1 Navigation in der App-Hierarchie

```
Bottom-Navigation (Phone/Tablet)
├── 📚 Bibliothek
├── 🎵 Setlists
├── 📅 Kalender
├── 💬 Board (Kommunikation)  ← Neuer Tab in MS2
└── 👤 Profil

Board-Tab:
├── Board-Feed (Übersicht)
├── Post-Detail
│   ├── Kommentare
│   └── Post-Menü (Pinnen, Löschen, etc.)
├── Umfrage-Detail (optional, meist inline im Feed)
├── Post erstellen
└── Umfrage erstellen
```

### 11.2 Deep-Links

**Unterstützte Deep-Links (MS2):**
- `sheetstorm://kapelle/{id}/board` — Board-Feed einer Kapelle
- `sheetstorm://kapelle/{id}/posts/{post_id}` — Direkter Link zu Post-Detail
- `sheetstorm://kapelle/{id}/umfragen/{umfrage_id}` — Direkter Link zu Umfrage-Detail
- `sheetstorm://benachrichtigungen/einstellungen` — Benachrichtigungs-Einstellungen

**Verwendung:** Push-Benachrichtigungen nutzen Deep-Links zur Navigation.

### 11.3 Breadcrumb-Navigation (Desktop)

```
┌─────────────────────────────────────┐
│  Sheetstorm > Musikkapelle Beispiel │ ← Breadcrumb
│  > Board > Probenausfall am 15.04.  │
└─────────────────────────────────────┘
```

---

## 12. Error States & Leerzustände

### 12.1 Leerzustand: Noch keine Posts

**Neues Board (keine Posts vorhanden):**
```
┌─────────────────────────────┐
│  Board                  +   │
├─────────────────────────────┤
│                             │
│          💬                 │
│                             │
│  Noch keine Posts           │
│                             │
│  Das Board ist leer.        │
│  Schreibe den ersten Post!  │
│                             │
│  [+ Ersten Post erstellen]  │
│                             │
│                             │
└─────────────────────────────┘
```

### 12.2 Leerzustand: Keine Kommentare

```
│  KOMMENTARE (0)             │
│                             │
│  Noch keine Kommentare.     │
│  Sei der Erste!             │
│                             │
│  [Kommentar schreiben...]   │
```

### 12.3 Error State: Post erstellen fehlgeschlagen

```
┌─────────────────────────────┐
│  ⚠️ Fehler                  │
├─────────────────────────────┤
│  Dein Post konnte nicht     │
│  veröffentlicht werden.     │
│                             │
│  • Überprüfe deine Verbin-  │
│    dung                     │
│  • Stelle sicher, dass alle │
│    Felder ausgefüllt sind   │
│                             │
│  [Erneut versuchen]         │
│  [Entwurf speichern]        │ ← Entwurf lokal speichern (MS3+)
└─────────────────────────────┘
```

### 12.4 Error State: Anhang zu groß

```
│  Anhänge (1/5)              │
│  ┌─────────────────────────┐│
│  │ ⚠️ bild_groß.jpg        ││ ← Fehler-Icon
│  │ 15 MB · Zu groß         ││ ← Fehlermeldung
│  │ (Max. 10 MB)            ││
│  │    ✕                    ││
│  └─────────────────────────┘│
```

### 12.5 Error State: Umfrage abgelaufen

**Versuch, nach Ablauf abzustimmen:**
```
┌─────────────────────────────┐
│  ⚠️ Umfrage abgelaufen      │
├─────────────────────────────┤
│  Diese Umfrage ist bereits  │
│  abgelaufen. Du kannst nicht│
│  mehr abstimmen.            │
│                             │
│  [Zurück]                   │
└─────────────────────────────┘
```

### 12.6 Error State: Netzwerkfehler (Offline)

**Toast-Benachrichtigung:**
```
┌─────────────────────────────┐
│  ⚠️ Keine Verbindung        │
│  Einige Inhalte sind evtl.  │
│  nicht aktuell.             │
│  [Erneut laden]        ✕   │
└─────────────────────────────┘
```

**Feed:** Posts werden grau hinterlegt + "Offline"-Badge angezeigt.

### 12.7 Error State: Berechtigung fehlt

**Musiker versucht, Post zu erstellen:**
```
┌─────────────────────────────┐
│  ⚠️ Keine Berechtigung      │
├─────────────────────────────┤
│  Du hast keine Berechtigung │
│  Posts zu erstellen.        │
│                             │
│  Nur Admins, Dirigenten und │
│  Registerführer können Posts│
│  erstellen.                 │
│                             │
│  [Verstanden]               │
└─────────────────────────────┘
```

---

## 13. Interaction Patterns

### 13.1 Pull-to-Refresh

**Swipe-down im Board-Feed:**
```
┌─────────────────────────────┐
│           ↓                 │ ← Refresh-Indicator
│  Loslassen zum Aktualisieren│
│                             │
│  [Feed-Inhalt]              │
└─────────────────────────────┘
```

**Nach Loslassen:** Feed aktualisiert sich, neues Posts werden oben eingefügt.

### 13.2 Infinite Scroll (Pagination)

**Scroll bis zum Ende des Feeds:**
```
│  [Letzter Post]             │
│                             │
│  ⏳ Weitere Posts laden...  │ ← Loading-Indicator
│                             │
```

**Nach Laden:** Nächste 20 Posts werden an Feed angehängt (Cursor-basierte Pagination).

### 13.3 Optimistic Update (Kommentar absenden)

1. **User tippt "Absenden"**
2. **Sofort:** Kommentar wird im Thread angezeigt (grauer Hintergrund, "Wird gesendet…")
3. **Nach Erfolg:** Grauer Hintergrund verschwindet, Kommentar normal angezeigt
4. **Bei Fehler:** Kommentar wird rot markiert + Retry-Button

```
│  [Avatar] Max · Gerade eben │
│  Mein Kommentar...          │ ← Grauer Hintergrund
│  ⏳ Wird gesendet…          │
```

**Nach Erfolg:**
```
│  [Avatar] Max · Gerade eben │
│  Mein Kommentar...          │ ← Normaler Hintergrund
│  👍                         │
```

### 13.4 Auto-Save (Post-Entwurf)

**Wenn Nutzer Post erstellt und abbricht:**
```
┌─────────────────────────────┐
│  ⚠️ Entwurf speichern?      │
├─────────────────────────────┤
│  Du hast ungespeicherte     │
│  Änderungen.                │
│                             │
│  [Verwerfen]  [Speichern]   │
└─────────────────────────────┘
```

**Nach Speichern:** Entwurf lokal gespeichert (IndexedDB/Local Storage), beim nächsten Öffnen des Post-Editors wiederhergestellt.

### 13.5 Swipe-Gesten (Optional, MS3+)

**Nicht in MS2 implementiert**, aber geplant für MS3:
- **Swipe-Right auf Post:** Reaktion hinzufügen (Schnellzugriff)
- **Swipe-Left auf Post:** Post-Menü öffnen (Pinnen, Löschen, etc.)

### 13.6 Keyboard-Shortcuts (Desktop)

**Nicht in MS2 implementiert**, aber geplant für MS3:
- `N` — Neuer Post
- `R` — Kommentar schreiben (wenn Post offen)
- `Esc` — Dialog schließen

---

## 14. Accessibility

### 14.1 Screen Reader Support

**Alle interaktiven Elemente haben Labels:**
- Post-Card: "Post von Klaus Dieter, Dirigent. Titel: Probenausfall am 15.04. Inhalt: Aufgrund der…"
- Reaktions-Button: "Daumen hoch. 12 Personen haben reagiert."
- Kommentar-Button: "8 Kommentare. Tippen zum Anzeigen."
- Pin-Badge: "Gepinnter Post"

### 14.2 Kontrast & Farben

**WCAG 2.1 AA-konform:**
- Text auf Hintergrund: Mindestkontrast 4.5:1
- Reaktions-Emoji: Mindestgröße 24×24px, Touch-Target 44×44px
- Pin-Badge: Gelber Hintergrund `#FEF3C7` + Text `#92400E` (Kontrast 7.2:1)

### 14.3 Touch-Targets

**Mindestgröße 44×44px:**
- Alle Buttons, Links, Reaktions-Emoji, Kommentar-Buttons
- Filter-Chips: 48px Höhe (größer für bessere Trefferquote)
- Post-Card: Vollflächig tappable → öffnet Post-Detail

### 14.4 Focus-Indikatoren

**Keyboard-Navigation (Desktop):**
- Fokus-Rahmen: 2px solid `color-primary`
- Tab-Reihenfolge: Header → Filter → Posts (chronologisch) → Bottom-Navigation

### 14.5 Reduktion von Animationen

**Respektiert System-Einstellung `prefers-reduced-motion`:**
- Keine automatischen Übergänge bei Post-Card-Erscheinen
- Infinite-Scroll ohne Fade-In-Effekt
- Umfrage-Balken ohne Animation

### 14.6 Textgröße

**Respektiert System-Font-Size:**
- Alle Texte in relativen Einheiten (`sp`, `rem`) statt festen Pixeln
- Layout bricht nicht bei 200% Vergrößerung

---

## 15. Abhängigkeiten

### 15.1 Backend (Banner)

- **Posts-API:** CRUD für Posts, Kommentare, Reaktionen (siehe `docs/feature-specs/kommunikation-spec.md` § 4.1–4.3)
- **Umfragen-API:** CRUD für Umfragen, Stimmen (siehe `docs/feature-specs/kommunikation-spec.md` § 4.4)
- **Push-API:** Device-Registrierung, Benachrichtigungen senden (siehe `docs/feature-specs/kommunikation-spec.md` § 4.5–4.6)
- **Register-Daten:** Zugriff auf Kapelle-Register (aus MS1)

### 15.2 Frontend (Hill/Romanoff)

- **Flutter Widgets:** Card, List, BottomSheet, Dialog, Toast
- **State Management:** Reaktive Updates bei neuen Posts/Kommentaren (WebSocket oder Polling)
- **Image Picker:** Kamera/Galerie-Zugriff (Flutter-Plugin)
- **PDF Preview:** PDF-Rendering für Anhang-Thumbnails
- **Push-Permissions:** FCM (Android), APNs (iOS)

### 15.3 MS1-Features

- **Authentifizierung:** JWT-Token für API-Zugriff
- **Kapellenverwaltung:** Rollenmodell (Admin/Dirigent/Registerführer/Musiker)
- **Register:** Register-Liste für Filter und Benachrichtigungen
- **Profil:** Avatar, Name, Rolle für Post-Autor-Anzeige

### 15.4 Design System (aus ux-design.md)

- **Design Tokens:** Farben, Typografie, Spacing (siehe § 2)
- **Bottom-Navigation:** Board-Tab wird hinzugefügt (4. oder 5. Tab)
- **Card-Component:** Wiederverwendbar für Posts, Umfragen, Kommentare

---

## Ende der UX-Spezifikation

**Nächste Schritte:**
1. **Review:** Hill (Frontend), Banner (Backend), Stark (Architecture)
2. **Prototyping:** Figma-Prototyp für User-Testing (optional)
3. **Implementierung:** MS2 Sprint-Planning mit Feature-Priorisierung
4. **Testing:** E2E-Tests für kritische User Flows (Post erstellen, Umfrage abstimmen, Push empfangen)

**Offene Fragen:**
- Soll es eine Desktop-Benachrichtigungs-Integration geben (Browser-Notifications)?
- Umfrage-Export (CSV/PDF) für Admins — MS2 oder MS3?
- Sollen Posts editierbar sein nach Veröffentlichung? (derzeit nur Löschen möglich)

**Version History:**
- v1.0 (2026-03-28): Initiale UX-Spec für MS2-Review
