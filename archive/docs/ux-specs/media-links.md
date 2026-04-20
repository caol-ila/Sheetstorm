# UX-Spec: Media Links — Sheetstorm

> **Issue:** #TBD  
> **Version:** 1.0  
> **Status:** Entwurf  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-29  
> **Meilenstein:** M2 — Vereinsleben & Aufführung  
> **Referenzen:** `docs/feature-specs/media-links-spec.md`, `docs/ux-design.md`, `docs/ux-specs/spielmodus.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Design-Prinzipien](#1-übersicht--design-prinzipien)
2. [Navigation & Entry Points](#2-navigation--entry-points)
3. [Flow A: Link manuell hinzufügen](#3-flow-a-link-manuell-hinzufügen)
4. [Flow B: Link anhören](#4-flow-b-link-anhören)
5. [Flow C: AI-Vorschläge nutzen](#5-flow-c-ai-vorschläge-nutzen)
6. [Flow D: Link löschen](#6-flow-d-link-löschen)
7. [Edge Cases & Error States](#7-edge-cases--error-states)
8. [Wireframes: Phone](#8-wireframes-phone)
9. [Wireframes: Tablet](#9-wireframes-tablet)
10. [Accessibility](#10-accessibility)
11. [Abhängigkeiten](#11-abhängigkeiten)

---

## 1. Übersicht & Design-Prinzipien

### 1.1 Kontext

Musiker wollen **Referenzaufnahmen** für Stücke schnell finden und anhören — z.B. vor Proben, beim Üben oder zur Vorbereitung. Aktuell müssen sie selbst auf YouTube/Spotify suchen.

**Problem:** Jeder Musiker sucht einzeln, Ergebnisse sind nicht geteilt, Links gehen verloren.

**Lösung:** Sheetstorm erlaubt es, **Media Links** (YouTube, Spotify) direkt auf Stück-Ebene zu speichern. Alle Kapellen-Mitglieder sehen die Links, können sie direkt öffnen und optional AI-Vorschläge nutzen.

**Zielgruppe:**  
- **Hauptnutzer:** Musiker (Anhören), Notenwart (Hinzufügen)  
- **Sekundärnutzer:** Dirigent (Hinzufügen, Kuratieren)

### 1.2 Design-Prinzipien

1. **Minimal & Fokussiert:** Ein Link = eine URL. Keine komplexen Playlists, keine Inline-Player (MS2).
2. **Einfaches CRUD:** Hinzufügen, Anzeigen, Löschen — mehr nicht.
3. **Deep-Link-First:** Öffne in nativer App (YouTube/Spotify), falls installiert. Browser als Fallback.
4. **AI als Vorschlag, nicht Pflicht:** Vorschläge sind optional, manuelles Hinzufügen ist primärer Workflow.
5. **Keine Duplikate:** Gleiche URL pro Stück nur einmal.

---

## 2. Navigation & Entry Points

### 2.1 Entry Points

**A) Aus Stück-Detail:**  
- Haupt-Entry-Point: Button **„+ Link hinzufügen"** in Stück-Detail-Ansicht
- Sektion **„Media Links"** direkt unter Stück-Metadaten

**B) Aus Spielmodus:**  
- Overlay → Button **„Anhören"** (nur sichtbar bei vorhandenen Links)

**C) Aus Bibliothek (Tablet Split-View):**  
- Preview-Pane rechts: Media Links inline sichtbar

### 2.2 Routing

```
/kapelle/{id}/stuecke/{stueckId}                    → Stück-Detail (mit Media Links)
/kapelle/{id}/stuecke/{stueckId}/media-links/add    → Link hinzufügen (Sheet/Modal)
```

**Keine eigene Seite für Media Links** — immer im Kontext des Stücks.

---

## 3. Flow A: Link manuell hinzufügen

### 3.1 Trigger

- Nutzer: Admin, Dirigent, Notenwart, Registerführer
- Kontext: Stück-Detail-Ansicht
- Ziel: YouTube- oder Spotify-Link hinzufügen

### 3.2 Ablauf

**Schritt 1: Stück-Detail öffnen**

```
┌─────────────────────────────────────────┐
│ ← Radetzky-Marsch                 ⋮     │
├─────────────────────────────────────────┤
│                                         │
│ Johann Strauß                           │
│ Marsch · 1848                           │
│ 3 Stimmen verfügbar                     │
│                                         │
│ ─────────────────────────────────────   │
│                                         │
│ Media Links                             │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Wiener Philharmoniker (YouTube)│   │
│ │ youtube.com/watch?v=abcd1234      │   │
│ └───────────────────────────────────┘   │
│                                         │
│ [+ Link hinzufügen]                     │
│                                         │
│ ─────────────────────────────────────   │
│                                         │
│ Noten (3 Stimmen)                       │
│ ⋮                                       │
│                                         │
└─────────────────────────────────────────┘
```

**Tap auf „+ Link hinzufügen"** → Öffnet Bottom Sheet (Phone) / Modal (Tablet)

**Schritt 2: Link eingeben**

```
┌─────────────────────────────────────────┐
│ Link hinzufügen                [Schließen]│
├─────────────────────────────────────────┤
│                                         │
│ Plattform                               │
│ ┌───────────────────────────────────┐   │
│ │ ● YouTube                         │   │
│ │ ○ Spotify                         │   │
│ └───────────────────────────────────┘   │
│                                         │
│ URL                                     │
│ ┌───────────────────────────────────┐   │
│ │ youtube.com/watch?v=xyz123        │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ℹ Unterstützte Formate:                 │
│   • YouTube: youtube.com, youtu.be      │
│   • Spotify: open.spotify.com/track     │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ [AI-Vorschläge anzeigen]          │   │
│ └───────────────────────────────────┘   │
│                                         │
│              [Abbrechen]  [Hinzufügen]  │
└─────────────────────────────────────────┘
```

**Interaktion:**

- **Radio-Buttons „Plattform":** Vorauswahl YouTube (häufigster Case)
- **URL-Eingabefeld:** Paste-Funktion, Autocomplete bei wiederholten Domains
- **Hinweis:** Zeigt unterstützte URL-Formate
- **Button „AI-Vorschläge anzeigen":** Optional, öffnet Flow C (AI-Vorschläge)
- **Validation:** 
  - Nur YouTube/Spotify URLs erlaubt
  - Duplikat-Check → Fehlermeldung „Link bereits vorhanden"
  - Invalid URL → Fehlermeldung „Ungültige URL"

**Schritt 3: Metadaten laden**

```
┌─────────────────────────────────────────┐
│ Lade Metadaten…                         │
├─────────────────────────────────────────┤
│                                         │
│ ⟳ Rufe oEmbed-Daten ab…                │
│                                         │
│                 [Abbrechen]             │
└─────────────────────────────────────────┘
```

- **Dauer:** Typ. 1–2 Sekunden
- **Fallback:** Falls oEmbed fehlschlägt → Link trotzdem speichern (mit null Metadata, siehe Edge Cases)

**Schritt 4: Link hinzugefügt**

```
┌─────────────────────────────────────────┐
│ ✓ Link hinzugefügt                      │
└─────────────────────────────────────────┘
     ↓ Toast (2s)
```

→ Zurück zu Stück-Detail, neuer Link ist sichtbar

```
┌─────────────────────────────────────────┐
│ Media Links                             │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Wiener Philharmoniker (YouTube)│   │
│ │ youtube.com/watch?v=abcd1234      │   │
│ └───────────────────────────────────┘   │
│ ┌───────────────────────────────────┐   │
│ │ 🎧 Berlin Phil Recording (Spotify)│   │
│ │ open.spotify.com/track/xyz123     │   │
│ └───────────────────────────────────┘   │
│                                         │
│ [+ Link hinzufügen]                     │
└─────────────────────────────────────────┘
```

---

## 4. Flow B: Link anhören

### 4.1 Trigger

- Nutzer: Alle Rollen
- Kontext: Stück-Detail oder Spielmodus
- Ziel: Link öffnen (Deep-Link oder Browser)

### 4.2 Ablauf

**Aus Stück-Detail:**

```
┌─────────────────────────────────────────┐
│ Media Links                             │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Wiener Philharmoniker (YouTube)│   │
│ │ youtube.com/watch?v=abcd1234      │◄── Tap
│ └───────────────────────────────────┘   │
│ ┌───────────────────────────────────┐   │
│ │ 🎧 Berlin Phil Recording (Spotify)│   │
│ │ open.spotify.com/track/xyz123     │   │
│ └───────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Tap auf Link-Karte:**

1. **Mobile (iOS/Android):**
   - Versuche Deep-Link zu YouTube/Spotify App
   - Falls App nicht installiert → Öffne Browser

2. **Desktop/Browser:**
   - Öffne Link in neuem Tab

**Aus Spielmodus (Overlay):**

```
┌─────────────────────────────────────────┐
│ ┌───────────────────────────────────┐   │
│ │ Radetzky-Marsch                   │   │
│ │ J. Strauß                         │   │
│ │                                   │   │
│ │ [Stimme wechseln]                 │   │
│ │ [Annotationen]                    │   │
│ │ [Anhören (2 Links)]          ▶   │   │◄── Tap
│ │                                   │   │
│ └───────────────────────────────────┘   │
└─────────────────────────────────────────┘
     ↓ Öffnet Link-Auswahl (bei mehreren Links)
```

**Falls mehrere Links vorhanden:**

```
┌─────────────────────────────────────────┐
│ Anhören                        [Schließen]│
├─────────────────────────────────────────┤
│                                         │
│ Wähle eine Aufnahme:                    │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Wiener Philharmoniker          │   │
│ │    YouTube                        │   │
│ └───────────────────────────────────┘   │
│ ┌───────────────────────────────────┐   │
│ │ 🎧 Berlin Phil Recording          │   │
│ │    Spotify                        │   │
│ └───────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Tap auf eine Aufnahme** → Öffnet Deep-Link / Browser (wie oben)

**Falls nur ein Link vorhanden:**  
→ Direkter Deep-Link (kein Dialog)

---

## 5. Flow C: AI-Vorschläge nutzen

### 5.1 Trigger

- Nutzer: Admin, Dirigent, Notenwart, Registerführer
- Kontext: Link-hinzufügen-Dialog (Flow A, Schritt 2)
- Ziel: AI-generierte Link-Vorschläge anzeigen

### 5.2 Ablauf

**Schritt 1: AI-Vorschläge anfordern**

In Flow A, Schritt 2: Tap auf **„AI-Vorschläge anzeigen"**

```
┌─────────────────────────────────────────┐
│ AI-Vorschläge werden gesucht…           │
├─────────────────────────────────────────┤
│                                         │
│ ⟳ Durchsuche YouTube & Spotify          │
│                                         │
│   Stück: Radetzky-Marsch                │
│   Komponist: Johann Strauß              │
│                                         │
│                 [Abbrechen]             │
└─────────────────────────────────────────┘
```

- **Dauer:** Typ. 3–5 Sekunden
- **Abbrechen möglich:** Zurück zu manuellem Eingabefeld

**Schritt 2: Vorschläge anzeigen**

```
┌─────────────────────────────────────────┐
│ ← AI-Vorschläge                [Schließen]│
├─────────────────────────────────────────┤
│                                         │
│ 5 Vorschläge gefunden                   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Wiener Philharmoniker          │   │
│ │    YouTube · 2.5M Aufrufe         │   │
│ │    youtube.com/watch?v=abcd1234   │   │
│ │                       [Hinzufügen]│   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Berlin Philharmonic Orchestra  │   │
│ │    YouTube · 1.2M Aufrufe         │   │
│ │    youtube.com/watch?v=efgh5678   │   │
│ │                       [Hinzufügen]│   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 🎧 Herbert von Karajan            │   │
│ │    Spotify · 345K Plays           │   │
│ │    open.spotify.com/track/ijkl90  │   │
│ │                       [Hinzufügen]│   │
│ └───────────────────────────────────┘   │
│                                         │
│ ⋮                                       │
│                                         │
│ [Manuell hinzufügen]                    │
└─────────────────────────────────────────┘
```

**Element-Details:**

- **Vorschlag-Karte:**
  - Icon: `🎵` für YouTube, `🎧` für Spotify
  - Titel: Video/Track-Titel (aus oEmbed Metadata)
  - Metadaten: Aufrufe/Plays (aus oEmbed)
  - URL: Gekürzt angezeigt (vollständig in Tooltip/Hover)
  - Button „Hinzufügen": Pro Vorschlag einzeln
- **Sortierung:** Nach Popularität (Aufrufe/Plays) absteigend
- **Limit:** Max. 10 Vorschläge (API-seitig gefiltert)
- **Button „Manuell hinzufügen":** Zurück zu manuellem Eingabefeld (Flow A, Schritt 2)

**Schritt 3: Vorschlag hinzufügen**

Tap auf **„Hinzufügen"** bei einem Vorschlag:

```
┌─────────────────────────────────────────┐
│ ✓ Link hinzugefügt                      │
└─────────────────────────────────────────┘
     ↓ Toast (2s)
```

→ Dialog schließt, zurück zu Stück-Detail mit neuem Link

**Mehrfach-Hinzufügen:**  
- Nutzer kann mehrere Vorschläge einzeln hinzufügen
- Nach jedem Hinzufügen: Toast, Dialog bleibt offen
- Button „Schließen" oben rechts: Beendet Flow

---

## 6. Flow D: Link löschen

### 6.1 Trigger

- Nutzer: Admin, Dirigent, Notenwart, Registerführer
- Kontext: Stück-Detail
- Ziel: Veraltete/falsche Links entfernen

### 6.2 Ablauf

**Schritt 1: Link-Karte long-press / Swipe**

**Mobile:**
- **Long-Press** auf Link-Karte → Kontext-Menü

```
┌─────────────────────────────────────────┐
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Wiener Philharmoniker (YouTube)│   │
│ │ youtube.com/watch?v=abcd1234      │   │
│ └───────────────────────────────────┘   │
│       ┌─────────────┐                   │
│       │ Öffnen      │                   │
│       │ Löschen     │                   │
│       └─────────────┘                   │
└─────────────────────────────────────────┘
```

**Alternativ: Swipe-to-Delete (iOS/Android):**

```
┌─────────────────────────────────────────┐
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Wiener Philharmoniker     [×]  │◄── Swipe left
│ └───────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Tablet/Desktop:**
- Hover → Drei-Punkt-Menü erscheint

```
┌─────────────────────────────────────────┐
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Wiener Philharmoniker (YouTube) ⋮│◄── Hover
│ │ youtube.com/watch?v=abcd1234      │   │
│ └───────────────────────────────────┘   │
│       ┌─────────────┐                   │
│       │ Öffnen      │                   │
│       │ Löschen     │                   │
│       └─────────────┘                   │
└─────────────────────────────────────────┘
```

**Schritt 2: Bestätigung**

```
┌─────────────────────────────────────────┐
│ Link löschen?                           │
├─────────────────────────────────────────┤
│                                         │
│ Wiener Philharmoniker (YouTube)         │
│ youtube.com/watch?v=abcd1234            │
│                                         │
│ Dieser Vorgang kann nicht rückgängig    │
│ gemacht werden.                         │
│                                         │
│         [Abbrechen]  [Löschen]          │
└─────────────────────────────────────────┘
```

**Schritt 3: Link gelöscht**

```
┌─────────────────────────────────────────┐
│ ✓ Link entfernt                         │
└─────────────────────────────────────────┘
     ↓ Toast (2s)
```

→ Link verschwindet aus Stück-Detail

---

## 7. Edge Cases & Error States

### 7.1 Keine Media Links vorhanden

```
┌─────────────────────────────────────────┐
│ ← Radetzky-Marsch                 ⋮     │
├─────────────────────────────────────────┤
│                                         │
│ Johann Strauß                           │
│ Marsch · 1848                           │
│                                         │
│ ─────────────────────────────────────   │
│                                         │
│ Media Links                             │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ Noch keine Links vorhanden        │   │
│ │                                   │   │
│ │ Füge Referenzaufnahmen von        │   │
│ │ YouTube oder Spotify hinzu.       │   │
│ │                                   │   │
│ │ [+ Link hinzufügen]               │   │
│ └───────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Spielmodus-Overlay:**  
→ Button „Anhören" ist **nicht sichtbar** (kein Leerzustand im Overlay)

### 7.2 oEmbed-Metadaten nicht verfügbar

**Szenario:** oEmbed API gibt 404 oder Timeout zurück.

**Verhalten:**
- Link wird **trotzdem gespeichert** (mit `null` Metadata)
- Anzeige: Nur URL, kein Titel

```
┌───────────────────────────────────┐
│ 🎵 YouTube-Link                   │
│ youtube.com/watch?v=abcd1234      │
│ ⚠ Metadaten nicht verfügbar       │
└───────────────────────────────────┘
```

**Tap auf Link:** Funktioniert normal (Deep-Link / Browser)

### 7.3 Duplikat-URL

**Szenario:** Nutzer versucht, gleiche URL erneut hinzuzufügen.

```
┌─────────────────────────────────────────┐
│ ⚠ Link bereits vorhanden                │
├─────────────────────────────────────────┤
│                                         │
│ Dieser Link wurde bereits zu diesem     │
│ Stück hinzugefügt:                      │
│                                         │
│ youtube.com/watch?v=abcd1234            │
│                                         │
│                    [OK]                 │
└─────────────────────────────────────────┘
```

→ Dialog schließt, kein Link wird hinzugefügt

### 7.4 Ungültige URL

**Szenario:** URL ist nicht YouTube oder Spotify.

```
┌─────────────────────────────────────────┐
│ ⚠ Ungültige URL                         │
├─────────────────────────────────────────┤
│                                         │
│ Nur YouTube- und Spotify-Links werden   │
│ unterstützt.                            │
│                                         │
│ Erlaubte Formate:                       │
│ • youtube.com/watch?v=...               │
│ • youtu.be/...                          │
│ • open.spotify.com/track/...            │
│                                         │
│                    [OK]                 │
└─────────────────────────────────────────┘
```

### 7.5 AI-Vorschläge: Keine Ergebnisse

```
┌─────────────────────────────────────────┐
│ ← AI-Vorschläge                [Schließen]│
├─────────────────────────────────────────┤
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ Keine Vorschläge gefunden         │   │
│ │                                   │   │
│ │ Versuche es mit manuellem         │   │
│ │ Hinzufügen.                       │   │
│ │                                   │   │
│ │ [Manuell hinzufügen]              │   │
│ └───────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Button „Manuell hinzufügen":** Zurück zu Flow A, Schritt 2

### 7.6 AI-Vorschläge: Rate-Limit erreicht

```
┌─────────────────────────────────────────┐
│ ⚠ Zu viele Anfragen                     │
├─────────────────────────────────────────┤
│                                         │
│ Du hast das Limit für AI-Vorschläge     │
│ erreicht.                               │
│                                         │
│ Bitte warte 10 Minuten oder füge        │
│ Links manuell hinzu.                    │
│                                         │
│       [OK]  [Manuell hinzufügen]        │
└─────────────────────────────────────────┘
```

### 7.7 Video/Track gelöscht

**Szenario:** YouTube-Video oder Spotify-Track wurde gelöscht (404 bei Deep-Link).

**Verhalten:**
- Link bleibt in Sheetstorm gespeichert
- Tap öffnet 404-Seite im Browser/App (natives Verhalten, kein Custom-Error)

**Optional (Future):**  
- Background-Job prüft regelmäßig, ob Links noch erreichbar sind
- Zeigt Icon `⚠` bei toten Links
- Tooltip: „Dieses Video ist nicht mehr verfügbar"

### 7.8 Mehrere Links: Sortierung

**Standard-Sortierung:** Hinzufügen-Reihenfolge (neueste zuerst).

**Keine manuelle Sortierung** in MS2 (Feature-Request für MS3).

---

## 8. Wireframes: Phone

### 8.1 Stück-Detail (mit Links)

```
┌─────────────────────┐
│ ← Radetzky-Marsch  ⋮│▒
├─────────────────────┤▒
│                     │▒
│ Johann Strauß       │▒
│ Marsch · 1848       │▒
│ 3 Stimmen verfügbar │▒
│                     │▒
│ ──────────────────  │▒
│                     │▒
│ Media Links         │▒
│                     │▒
│ ┌─────────────────┐ │▒
│ │ 🎵 Wiener Phil. │ │▒
│ │ YouTube         │ │▒
│ │ youtu.be/abc123 │ │▒
│ └─────────────────┘ │▒
│ ┌─────────────────┐ │▒
│ │ 🎧 Berlin Phil. │ │▒
│ │ Spotify         │ │▒
│ │ spotify.../xyz  │ │▒
│ └─────────────────┘ │▒
│                     │▒
│ [+ Link hinzufügen] │▒
│                     │▒
│ ──────────────────  │▒
│                     │▒
│ Noten (3 Stimmen)   │▒
│ ⋮                   │▒
│                     │▒
└─────────────────────┘▒
```

### 8.2 Link hinzufügen (Bottom Sheet)

```
┌─────────────────────┐
│ Link hinzufügen  [×]│
├─────────────────────┤
│                     │
│ Plattform           │
│ ┌─────────────────┐ │
│ │ ● YouTube       │ │
│ │ ○ Spotify       │ │
│ └─────────────────┘ │
│                     │
│ URL                 │
│ ┌─────────────────┐ │
│ │youtube.com/…    │ │
│ └─────────────────┘ │
│                     │
│ ℹ YouTube/Spotify   │
│   URLs erlaubt      │
│                     │
│ ┌─────────────────┐ │
│ │ AI-Vorschläge   │ │
│ └─────────────────┘ │
│                     │
│ [Abbr.] [Hinzufügen]│
└─────────────────────┘
```

### 8.3 AI-Vorschläge (Bottom Sheet)

```
┌─────────────────────┐
│ ← AI-Vorschläge  [×]│▒
├─────────────────────┤▒
│                     │▒
│ 5 Vorschläge        │▒
│                     │▒
│ ┌─────────────────┐ │▒
│ │ 🎵 Wiener Phil. │ │▒
│ │ YouTube · 2.5M  │ │▒
│ │ youtu.be/abc123 │ │▒
│ │    [Hinzufügen] │ │▒
│ └─────────────────┘ │▒
│ ┌─────────────────┐ │▒
│ │ 🎵 Berlin Phil. │ │▒
│ │ YouTube · 1.2M  │ │▒
│ │ youtu.be/efg456 │ │▒
│ │    [Hinzufügen] │ │▒
│ └─────────────────┘ │▒
│ ┌─────────────────┐ │▒
│ │ 🎧 H. v. Karajan│ │▒
│ │ Spotify · 345K  │ │▒
│ │ spotify.../ijk  │ │▒
│ │    [Hinzufügen] │ │▒
│ └─────────────────┘ │▒
│                     │▒
│ ⋮                   │▒
│                     │▒
│ [Manuell hinzufügen]│
└─────────────────────┘
```

### 8.4 Spielmodus-Overlay (mit Anhören-Button)

```
┌─────────────────────┐
│                     │
│ ┌─────────────────┐ │
│ │ Radetzky-Marsch │ │
│ │ J. Strauß       │ │
│ │                 │ │
│ │ [Stimme wechseln]│ │
│ │ [Annotationen]  │ │
│ │ [Anhören (2)]  ▶│ │◄── Tap
│ │                 │ │
│ └─────────────────┘ │
│                     │
│   [Noten im Vollbild]│
└─────────────────────┘
```

**Tap auf „Anhören"** → Öffnet Link-Auswahl (siehe Flow B)

---

## 9. Wireframes: Tablet

### 9.1 Stück-Detail (Split-View, Landscape)

```
┌─────────────────────────────────────────────────────────────────┐
│ ← Bibliothek                                              ⋮     │
├───────────────────────┬─────────────────────────────────────────┤
│ [Suche…]          🔍  │ Radetzky-Marsch                   ⋮     │
│                       │ ─────────────────────────────────────── │
│ ┌───────────────────┐ │ Johann Strauß · Marsch · 1848           │
│ │ Radetzky-Marsch   │◄│ 3 Stimmen verfügbar                     │
│ │ J. Strauß         │ │                                         │
│ └───────────────────┘ │ ═══ Media Links ═══                     │
│ ┌───────────────────┐ │                                         │
│ │ An der schönen…   │ │ ┌─────────────────────────────────────┐ │
│ │ J. Strauß         │ │ │ 🎵 Wiener Philharmoniker            │ │
│ └───────────────────┘ │ │    YouTube · 2.5M Aufrufe           │ │
│ ┌───────────────────┐ │ │    youtube.com/watch?v=abcd1234     │ │
│ │ Böhmischer Traum  │ │ │                            ⋮  [Öffnen]│ │
│ │ E. Mohr           │ │ └─────────────────────────────────────┘ │
│ └───────────────────┘ │ ┌─────────────────────────────────────┐ │
│                       │ │ 🎧 Berlin Phil Recording            │ │
│ ⋮                     │ │    Spotify · 345K Plays             │ │
│                       │ │    open.spotify.com/track/xyz123    │ │
│                       │ │                            ⋮  [Öffnen]│ │
│                       │ └─────────────────────────────────────┘ │
│                       │                                         │
│                       │ [+ Link hinzufügen]                     │
│                       │                                         │
│                       │ ═══ Noten (3 Stimmen) ═══               │
│                       │ ⋮                                       │
└───────────────────────┴─────────────────────────────────────────┘
   ← 280px List         ← Detail Pane
```

- **Split-View:** Liste links, Detail rechts
- **Link-Karten:** Vollständige Metadaten sichtbar
- **Hover:** Drei-Punkt-Menü `⋮` + Button „Öffnen" erscheint

### 9.2 Link hinzufügen (Modal)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   ┌───────────────────────────────────────────────────────┐     │
│   │ Link hinzufügen                          [×]          │     │
│   ├───────────────────────────────────────────────────────┤     │
│   │                                                       │     │
│   │ Plattform                                             │     │
│   │ ┌───────────────────────────────────────────────┐     │     │
│   │ │ ● YouTube          ○ Spotify                  │     │     │
│   │ └───────────────────────────────────────────────┘     │     │
│   │                                                       │     │
│   │ URL                                                   │     │
│   │ ┌───────────────────────────────────────────────┐     │     │
│   │ │ youtube.com/watch?v=xyz123                    │     │     │
│   │ └───────────────────────────────────────────────┘     │     │
│   │                                                       │     │
│   │ ℹ Unterstützte Formate:                               │     │
│   │   • YouTube: youtube.com, youtu.be                    │     │
│   │   • Spotify: open.spotify.com/track                   │     │
│   │                                                       │     │
│   │ ┌───────────────────────────────────────────────┐     │     │
│   │ │ [AI-Vorschläge anzeigen]                      │     │     │
│   │ └───────────────────────────────────────────────┘     │     │
│   │                                                       │     │
│   │                        [Abbrechen]  [Hinzufügen]      │     │
│   └───────────────────────────────────────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
   ← Centered Modal (520px breit)
```

---

## 10. Accessibility

### 10.1 Touch Targets

- **Link-Karten:** Mind. 56px hoch (gesamte Karte tappable)
- **Button „Hinzufügen":** 44×44px (in Vorschlägen inline)
- **Drei-Punkt-Menü:** 44×44px Tap-Area

### 10.2 Kontrast & Farben

- **Icons:**
  - YouTube: `🎵` (oder Custom-Icon in Brand-Rot `#FF0000`)
  - Spotify: `🎧` (oder Custom-Icon in Brand-Grün `#1DB954`)
- **Warnung „Metadaten fehlen":** Orange `#D97706` + Icon `⚠`

### 10.3 Keyboard Navigation (Desktop)

- **Tab-Reihenfolge:** Link-Karten, dann „+ Link hinzufügen"
- **Enter:** Öffnet Link (Deep-Link / Browser)
- **Delete:** Löscht Link (mit Bestätigung)
- **Shortcuts:**
  - `Cmd/Ctrl + L`: Fokussiert URL-Eingabefeld (im Link-hinzufügen-Dialog)

### 10.4 Screen Reader

- **Link-Karten:**
  - Aria-Label: „Wiener Philharmoniker, YouTube, 2.5 Millionen Aufrufe"
  - Role: `link`
- **Button „Anhören":**
  - Aria-Label: „Anhören, 2 Aufnahmen verfügbar"
- **Leerzustand:**
  - Aria-Label: „Noch keine Links vorhanden. Link hinzufügen."

### 10.5 Deep-Link Fallback

- **Native App nicht installiert:** Browser öffnet automatisch (natives OS-Verhalten)
- **Kein Custom-Error:** OS übernimmt Fallback

---

## 11. Abhängigkeiten

### 11.1 Backend-API

- **Endpoints:** `/api/v1/kapellen/{kapelle_id}/stuecke/{stueck_id}/media-links`
- **oEmbed-Service:** YouTube & Spotify oEmbed APIs
- **AI-Suggestion-Service:** Azure OpenAI (MS2) für Link-Vorschläge

### 11.2 Frontend-Komponenten

- **Neu:**
  - `MediaLinkCard` (Link-Karte mit Icon, Titel, URL)
  - `MediaLinkAddSheet` (Bottom Sheet / Modal)
  - `AiSuggestionList` (Vorschlag-Liste)
  - `PlaybackLinkPicker` (Auswahl-Dialog bei mehreren Links)
- **Bestehend (reuse):**
  - `BottomSheet` (Phone)
  - `Modal` (Tablet)
  - `ContextMenu` (Drei-Punkt-Menü)
  - `ToastNotification`

### 11.3 Permissions

- **Admin, Dirigent, Notenwart, Registerführer:** Hinzufügen, Löschen, AI-Vorschläge
- **Musiker:** Nur Anhören (Read-Only)

### 11.4 Offline-Verhalten

- **Anhören:** Nur online (Deep-Link benötigt Netzwerk)
- **Hinzufügen:** Offline möglich (mit Queue), Sync beim Reconnect
- **AI-Vorschläge:** Nur online (Fehlermeldung + Retry)
- **Anzeige:** Cached Links offline lesbar

### 11.5 Responsive Breakpoints

| Breakpoint       | Link-Karten-Layout  | Link-hinzufügen-Dialog |
|------------------|---------------------|------------------------|
| Phone (<600px)   | Stacked, 100% breit | Bottom Sheet           |
| Tablet (600–1024)| 2-Spalten Grid      | Centered Modal         |
| Desktop (>1024)  | 3-Spalten Grid      | Centered Modal         |

---

**Ende UX-Spec Media Links**
