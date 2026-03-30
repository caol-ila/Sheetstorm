# UX-Spec: Song-Broadcast — Sheetstorm

> **Issue:** #TBD  
> **Version:** 1.0  
> **Status:** Entwurf  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-29  
> **Meilenstein:** M2 — Vereinsleben & Aufführung  
> **Referenzen:** `docs/feature-specs/song-broadcast-spec.md`, `docs/ux-design.md`, `docs/ux-specs/spielmodus.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Design-Prinzipien](#1-übersicht--design-prinzipien)
2. [Navigation & Entry Points](#2-navigation--entry-points)
3. [Flow A: Broadcast-Session starten (Dirigent)](#3-flow-a-broadcast-session-starten-dirigent)
4. [Flow B: Session beitreten (Musiker)](#4-flow-b-session-beitreten-musiker)
5. [Flow C: Stück senden (Dirigent)](#5-flow-c-stück-senden-dirigent)
6. [Flow D: Stück empfangen (Musiker)](#6-flow-d-stück-empfangen-musiker)
7. [Flow E: Verbindungs-Status & Reconnect](#7-flow-e-verbindungs-status--reconnect)
8. [Flow F: Session beenden](#8-flow-f-session-beenden)
9. [Edge Cases & Error States](#9-edge-cases--error-states)
10. [Wireframes: Phone (Musiker)](#10-wireframes-phone-musiker)
11. [Wireframes: Tablet (Dirigent)](#11-wireframes-tablet-dirigent)
12. [Accessibility](#12-accessibility)
13. [Abhängigkeiten](#13-abhängigkeiten)

---

## 1. Übersicht & Design-Prinzipien

### 1.1 Kontext

In Proben und Auftritten wählt der **Dirigent** das nächste Stück — alle **Musiker** müssen ihre Noten zur richtigen Stimme (Trompete 1, Klarinette 2, etc.) manuell heraussuchen.

**Problem:** Langsam, fehleranfällig, unterbricht den Proben-Flow.

**Lösung:** **Song-Broadcast** ist ein **Echtzeit-Master-Control-System**. Der Dirigent wählt ein Stück, Sheetstorm sendet es automatisch an alle verbundenen Musiker-Geräte und lädt die richtige Stimme.

**Zielgruppe:**  
- **Dirigent:** Sendet Stücke, sieht Verbindungs-Status  
- **Musiker:** Empfangen automatisch, sehen Noten-Ansicht

**Nutzungskontext:**  
- Proben (wöchentlich, 2–3h)  
- Auftritt-Vorbereitung (Soundcheck)  
- Konzerte (selten, aber kritisch)

### 1.2 Design-Prinzipien

1. **Vertrauen durch Transparenz:** Dirigent sieht live, wie viele Musiker verbunden sind und ob alle das Stück empfangen haben.
2. **Musiker-Sicht ist passiv:** Musiker müssen nichts tun — Stück-Wechsel passiert automatisch, Noten öffnen sich im Spielmodus.
3. **Keine Unterbrechung im Spielmodus:** Musiker bleiben im Vollbild-Noten-Modus, Benachrichtigungen sind subtil.
4. **Reconnect ist unsichtbar:** Bei kurzen Verbindungsabbrüchen (<3s) kein UI-Feedback — nahtlose Wiederverbindung.
5. **Fehlende Stimme = Explicit Fallback:** Wenn Stimme fehlt, wird Musiker informiert (nicht stillschweigend ersetzt).
6. **Session-Kollision = Takeover-Dialog:** Falls eine Session läuft, kann Dirigent übernehmen (mit Bestätigung).

---

## 2. Navigation & Entry Points

### 2.1 Entry Points

**A) Dirigent — Session starten:**  
- **Aus Setlist-Detail:** Button **„Broadcast starten"** in Setlist-Actions (drei-Punkt-Menü)
- **Aus Bibliothek:** Button **„Broadcast starten"** in Kapelle-Actions (nur Dirigent/Admin)

**B) Musiker — Session beitreten:**  
- **Automatisch:** App erkennt aktive Session, zeigt Banner „Broadcast-Session aktiv — Beitreten?"
- **Manuell:** In **Profil → Kapelle → Broadcast** (falls automatische Erkennung fehlschlägt)

### 2.2 Routing

```
/kapelle/{id}/broadcast           → Broadcast-Control (Dirigent)
/kapelle/{id}/broadcast/join      → Session beitreten (Musiker)
```

**Session-Status:** Persistent in App (nicht nur in einer View) — Musiker bleiben verbunden, auch wenn sie zwischen Screens wechseln.

---

## 3. Flow A: Broadcast-Session starten (Dirigent)

### 3.1 Trigger

- Nutzer: Dirigent, Admin
- Kontext: Probe/Auftritt beginnt
- Ziel: Session starten, Musiker können beitreten

### 3.2 Ablauf

**Schritt 1: Session starten (aus Setlist)**

```
┌─────────────────────────────────────────┐
│ ← Frühjahrskonzert 2026          ⋮      │
├─────────────────────────────────────────┤
│                                         │
│ 18 Stücke · 12.04.2026                  │
│ Stadthalle Musterstadt                  │
│                                         │
│ Stücke:                                 │
│ 1. Radetzky-Marsch                      │
│ 2. An der schönen blauen Donau         │
│ ⋮                                       │
│                                         │
└─────────────────────────────────────────┘
   ⋮ Tap
   ┌───────────────────┐
   │ Broadcast starten │◄── Tap
   │ Bearbeiten        │
   │ GEMA-Meldung      │
   └───────────────────┘
```

**Alternativ: Aus Kapelle-Bereich:**

```
Profil → Kapelle → [Broadcast starten]
```

**Schritt 2: Setlist wählen (falls kein Kontext)**

Falls Aufruf **ohne Setlist-Kontext:**

```
┌─────────────────────────────────────────┐
│ Broadcast-Session starten               │
├─────────────────────────────────────────┤
│                                         │
│ Wähle Setlist (optional):               │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ ○ Frühjahrskonzert 2026           │   │
│ │   18 Stücke · 12.04.2026          │   │
│ └───────────────────────────────────┘   │
│ ┌───────────────────────────────────┐   │
│ │ ○ Weihnachtskonzert 2025          │   │
│ │   15 Stücke · 20.12.2025          │   │
│ └───────────────────────────────────┘   │
│ ┌───────────────────────────────────┐   │
│ │ ○ Ohne Setlist (freie Auswahl)    │   │
│ └───────────────────────────────────┘   │
│                                         │
│         [Abbrechen]  [Starten]          │
└─────────────────────────────────────────┘
```

- **Mit Setlist:** Dirigent kann aus Setlist-Reihenfolge wählen
- **Ohne Setlist:** Dirigent wählt Stücke aus Bibliothek (freier Modus)

**Schritt 3: Session-Kollision (falls aktiv)**

Falls bereits eine Session läuft:

```
┌─────────────────────────────────────────┐
│ ⚠ Aktive Session gefunden               │
├─────────────────────────────────────────┤
│                                         │
│ Eine Broadcast-Session ist bereits      │
│ aktiv:                                  │
│                                         │
│ Gestartet: 18:30 Uhr                    │
│ von Max Müller (Dirigent)               │
│ 12 Musiker verbunden                    │
│                                         │
│ Möchtest du die Session übernehmen?     │
│                                         │
│ ⚠ Max wird automatisch getrennt.        │
│                                         │
│       [Abbrechen]  [Übernehmen]         │
└─────────────────────────────────────────┘
```

- **Button „Übernehmen":** Beendet alte Session, startet neue
- **Notification an alten Dirigent:** „Deine Broadcast-Session wurde von [Name] übernommen."

**Schritt 4: Session gestartet**

```
┌─────────────────────────────────────────┐
│ ✓ Broadcast-Session gestartet           │
└─────────────────────────────────────────┘
     ↓ Toast (2s)
```

→ Öffnet **Broadcast-Control-View** (siehe Flow C)

---

## 4. Flow B: Session beitreten (Musiker)

### 4.1 Trigger

- Nutzer: Alle Rollen
- Kontext: Dirigent hat Session gestartet
- Ziel: Musiker verbinden sich automatisch

### 4.2 Ablauf

**Schritt 1: Auto-Discovery**

App erkennt aktive Session via WebSocket/SignalR:

```
┌─────────────────────────────────────────┐
│ ┌───────────────────────────────────┐   │
│ │ 📡 Broadcast-Session aktiv        │   │
│ │                                   │   │
│ │ Dirigent: Max Müller              │   │
│ │ Setlist: Frühjahrskonzert 2026    │   │
│ │                                   │   │
│ │ [Beitreten]              [Später] │   │
│ └───────────────────────────────────┘   │
│                                         │
│ Bibliothek                              │
│ [Suche…]                            🔍  │
│ ⋮                                       │
└─────────────────────────────────────────┘
```

- **Banner:** Sticky oben, bis Musiker beitritt oder ablehnt
- **Button „Beitreten":** Verbindet sofort
- **Button „Später":** Versteckt Banner für 10 Minuten (dann erneut anzeigen)

**Schritt 2: Verbindung herstellen**

```
┌─────────────────────────────────────────┐
│ ⟳ Verbinde mit Broadcast-Session…       │
└─────────────────────────────────────────┘
     ↓ Toast (1s)
```

**Schritt 3: Verbunden**

```
┌─────────────────────────────────────────┐
│ ✓ Verbunden mit Broadcast-Session       │
└─────────────────────────────────────────┘
     ↓ Toast (2s)
```

→ **Status-Indicator** in App-Header (persistent):

```
┌─────────────────────────────────────────┐
│ 📡 Broadcast · 12 Musiker      ←  ⋮     │
├─────────────────────────────────────────┤
│ Bibliothek                              │
│ ⋮                                       │
└─────────────────────────────────────────┘
```

- **Icon `📡`:** Zeigt aktive Verbindung
- **Tap auf Indicator:** Öffnet Verbindungs-Info (siehe Flow E)

---

## 5. Flow C: Stück senden (Dirigent)

### 5.1 Trigger

- Nutzer: Dirigent
- Kontext: Session läuft, Musiker verbunden
- Ziel: Stück auswählen und an alle senden

### 5.2 Broadcast-Control-View

```
┌─────────────────────────────────────────┐
│ ← Broadcast-Session             [Beenden]│
├─────────────────────────────────────────┤
│                                         │
│ 📡 12 Musiker verbunden                 │
│ Setlist: Frühjahrskonzert 2026          │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ Verbindungs-Status                │   │
│ │                                   │   │
│ │ ✓ Alle bereit (12/12)             │   │
│ │ Latenz: 120ms (Gut)               │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ────────────────────────────────────    │
│                                         │
│ Aktuelles Stück:                        │
│ ┌───────────────────────────────────┐   │
│ │ Radetzky-Marsch                   │   │
│ │ Johann Strauß                     │   │
│ │                                   │   │
│ │ ✓ 12/12 Musiker empfangen         │   │
│ │ ✓ 12/12 Noten geladen             │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ────────────────────────────────────    │
│                                         │
│ Setlist:                                │
│                                         │
│ ┌───────────────────────────────────┐   │▒
│ │ ● 1. Radetzky-Marsch         (12) │   │▒
│ └───────────────────────────────────┘   │▒
│ ┌───────────────────────────────────┐   │▒
│ │ ○ 2. An der schönen blauen Donau  │   │▒
│ └───────────────────────────────────┘   │▒
│ ┌───────────────────────────────────┐   │▒
│ │ ○ 3. Böhmischer Traum             │   │▒
│ └───────────────────────────────────┘   │▒
│ ⋮                                       │▒
│                                         │
└─────────────────────────────────────────┘
```

**Element-Details:**

- **Verbindungs-Status-Panel:**
  - `✓ Alle bereit (12/12)`: Alle Musiker verbunden + bestätigt
  - `Latenz: 120ms`: Durchschnittliche Roundtrip-Zeit
  - Farbe: Grün bei <500ms, Orange bei 500–1000ms, Rot bei >1000ms
- **Aktuelles Stück:**
  - Zeigt zuletzt gesendetes Stück
  - `✓ 12/12 Musiker empfangen`: Alle haben Broadcast erhalten
  - `✓ 12/12 Noten geladen`: Alle haben ihre Stimme geladen
- **Setlist:**
  - `●` = Aktuell gesendet
  - `○` = Nicht gesendet
  - `(12)` = Anzahl Musiker, die dieses Stück empfangen haben (nur bei aktuellem Stück)
  - **Tap auf Stück:** Sendet an alle Musiker

### 5.3 Stück auswählen & senden

**Tap auf Stück in Setlist:**

```
┌───────────────────────────────────┐
│ ○ 2. An der schönen blauen Donau  │◄── Tap
└───────────────────────────────────┘
     ↓
┌───────────────────────────────────┐
│ ⟳ Sende Stück an 12 Musiker…      │
└───────────────────────────────────┘
     ↓ (< 500ms)
┌───────────────────────────────────┐
│ ✓ Stück gesendet                  │
└───────────────────────────────────┘
     ↓ Toast (2s)
```

**Broadcast-Control-View aktualisiert sich:**

```
│ Aktuelles Stück:                        │
│ ┌───────────────────────────────────┐   │
│ │ An der schönen blauen Donau       │   │
│ │ Johann Strauß (Sohn)              │   │
│ │                                   │   │
│ │ ⟳ 8/12 Musiker empfangen          │   │ ← Live-Update
│ │ ⟳ 6/12 Noten geladen              │   │
│ └───────────────────────────────────┘   │
```

**Nach 2–3 Sekunden:**

```
│ │ ✓ 12/12 Musiker empfangen         │   │
│ │ ✓ 12/12 Noten geladen             │   │
```

### 5.4 Fehlende Stimmen (Warnung)

Falls Musiker keine passende Stimme haben:

```
│ Aktuelles Stück:                        │
│ ┌───────────────────────────────────┐   │
│ │ An der schönen blauen Donau       │   │
│ │                                   │   │
│ │ ✓ 10/12 Musiker empfangen         │   │
│ │ ⚠ 2 Musiker: Stimme fehlt         │   │
│ │                     [Details]     │   │
│ └───────────────────────────────────┘   │
```

**Tap auf „Details":**

```
┌─────────────────────────────────────────┐
│ Fehlende Stimmen                  [×]   │
├─────────────────────────────────────────┤
│                                         │
│ 2 Musiker haben keine passende Stimme:  │
│                                         │
│ • Anna Schmidt (Flöte 1)                │
│   → Stimme fehlt                        │
│                                         │
│ • Tom Weber (Posaune 3)                 │
│   → Stimme fehlt                        │
│                                         │
│                    [OK]                 │
└─────────────────────────────────────────┘
```

---

## 6. Flow D: Stück empfangen (Musiker)

### 6.1 Trigger

- Nutzer: Musiker (alle verbundenen)
- Kontext: Dirigent sendet Stück
- Ziel: Noten automatisch öffnen

### 6.2 Ablauf

**Schritt 1: Broadcast empfangen**

Musiker ist in beliebigem Screen (Bibliothek, Setlist, etc.):

```
┌─────────────────────────────────────────┐
│ 📡 Broadcast · 12 Musiker      ←  ⋮     │
├─────────────────────────────────────────┤
│                                         │
│ Bibliothek                              │
│ [Suche…]                            🔍  │
│ ⋮                                       │
└─────────────────────────────────────────┘
     ↓ Dirigent sendet Stück
┌─────────────────────────────────────────┐
│ ┌───────────────────────────────────┐   │
│ │ 🎵 Neues Stück empfangen          │   │
│ │                                   │   │
│ │ An der schönen blauen Donau       │   │
│ │ Johann Strauß (Sohn)              │   │
│ │                                   │   │
│ │ Lädt deine Stimme (Trompete 1)…   │   │
│ └───────────────────────────────────┘   │
└─────────────────────────────────────────┘
     ↓ (1–2s)
```

**Schritt 2: Noten öffnen (automatisch)**

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                                         │
│         ╔═══════════════════╗           │
│         ║                   ║           │
│         ║   Noten-Ansicht   ║           │
│         ║   Trompete 1      ║           │
│         ║                   ║           │
│         ║   An der schönen  ║           │
│         ║   blauen Donau    ║           │
│         ║                   ║           │
│         ╚═══════════════════╝           │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

- **Automatischer Spielmodus:** Noten öffnen sich im Vollbild
- **Stimme:** Automatisch geladen basierend auf Nutzer-Profil (Instrument/Stimme)
- **Keine Bestätigung nötig:** Nahtloser Übergang

**Falls Musiker bereits im Spielmodus ist:**  
→ Noten wechseln automatisch (mit subtiler Animation, 200ms)

### 6.3 Fehlende Stimme (Fallback)

Falls Stimme nicht verfügbar:

```
┌─────────────────────────────────────────┐
│ ┌───────────────────────────────────┐   │
│ │ ⚠ Stimme fehlt                    │   │
│ │                                   │   │
│ │ Für „An der schönen blauen Donau" │   │
│ │ ist keine Trompete-1-Stimme       │   │
│ │ verfügbar.                        │   │
│ │                                   │   │
│ │ [Andere Stimme wählen]  [Schließen]│   │
│ └───────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Button „Andere Stimme wählen":**  
→ Öffnet Stimmen-Auswahl (wie in Spielmodus-Spec)

**Button „Schließen":**  
→ Bleibt im vorherigen Screen (Noten öffnen sich nicht)

---

## 7. Flow E: Verbindungs-Status & Reconnect

### 7.1 Verbindungs-Status anzeigen

**Tap auf Broadcast-Indicator (Musiker):**

```
┌─────────────────────────────────────────┐
│ 📡 Broadcast · 12 Musiker      ←  ⋮     │◄── Tap
└─────────────────────────────────────────┘
     ↓
┌─────────────────────────────────────────┐
│ Broadcast-Session                 [×]   │
├─────────────────────────────────────────┤
│                                         │
│ Status: Verbunden ✓                     │
│                                         │
│ Dirigent: Max Müller                    │
│ Setlist: Frühjahrskonzert 2026          │
│ Musiker: 12 verbunden                   │
│ Latenz: 120ms (Gut)                     │
│                                         │
│ Aktuelles Stück:                        │
│ An der schönen blauen Donau             │
│ Stimme: Trompete 1                      │
│                                         │
│ [Session verlassen]                     │
└─────────────────────────────────────────┘
```

### 7.2 Verbindungsabbruch (Musiker)

**Szenario:** WLAN-Verbindung kurz unterbrochen.

**< 3 Sekunden:**  
→ Kein UI-Feedback, automatischer Reconnect im Hintergrund

**> 3 Sekunden:**

```
┌─────────────────────────────────────────┐
│ ⚠ Broadcast · Verbindung…       ←  ⋮    │◄── Orange Icon
└─────────────────────────────────────────┘
```

- **Icon:** Orange `⚠` (statt grün `📡`)
- **Keine Unterbrechung im Spielmodus:** Noten bleiben sichtbar

**Verbindung wiederhergestellt:**

```
┌─────────────────────────────────────────┐
│ ✓ Broadcast-Verbindung wiederhergestellt │
└─────────────────────────────────────────┘
     ↓ Toast (2s)
```

→ Indicator wird wieder grün `📡`

**> 30 Sekunden offline:**

```
┌─────────────────────────────────────────┐
│ ⚠ Broadcast-Verbindung getrennt         │
├─────────────────────────────────────────┤
│                                         │
│ Die Verbindung zur Broadcast-Session    │
│ wurde getrennt.                         │
│                                         │
│ Möchtest du erneut beitreten?           │
│                                         │
│         [Später]  [Erneut beitreten]    │
└─────────────────────────────────────────┘
```

### 7.3 Verbindungsabbruch (Dirigent)

**Dirigent verliert Verbindung:**

```
┌─────────────────────────────────────────┐
│ ⚠ Verbindung verloren                   │
├─────────────────────────────────────────┤
│                                         │
│ Die Broadcast-Session wurde             │
│ unterbrochen.                           │
│                                         │
│ Musiker bleiben verbunden und           │
│ behalten das aktuelle Stück.            │
│                                         │
│ [Erneut verbinden]                      │
└─────────────────────────────────────────┘
```

**Wichtig:** Session läuft auf Server weiter, Musiker bleiben verbunden (Server-Side-Session).

### 7.4 Latenz-Warnung (Dirigent)

**Szenario:** Netzwerk-Latenz >1000ms.

```
│ ┌───────────────────────────────────┐   │
│ │ Verbindungs-Status                │   │
│ │                                   │   │
│ │ ✓ Alle bereit (12/12)             │   │
│ │ ⚠ Latenz: 1.2s (Langsam)          │   │◄── Rot
│ └───────────────────────────────────┘   │
```

**Keine automatische Aktion** — nur Warnung. Dirigent kann entscheiden, ob er weitermacht.

---

## 8. Flow F: Session beenden

### 8.1 Trigger

- Nutzer: Dirigent
- Kontext: Probe/Auftritt endet
- Ziel: Session beenden, alle trennen

### 8.2 Ablauf

**Schritt 1: Session beenden (Dirigent)**

```
┌─────────────────────────────────────────┐
│ ← Broadcast-Session             [Beenden]│◄── Tap
└─────────────────────────────────────────┘
     ↓
┌─────────────────────────────────────────┐
│ Session beenden?                        │
├─────────────────────────────────────────┤
│                                         │
│ Die Broadcast-Session wird für alle     │
│ 12 Musiker beendet.                     │
│                                         │
│         [Abbrechen]  [Beenden]          │
└─────────────────────────────────────────┘
```

**Schritt 2: Session beendet**

```
┌─────────────────────────────────────────┐
│ ✓ Broadcast-Session beendet             │
└─────────────────────────────────────────┘
     ↓ Toast (2s)
```

→ Dirigent wird zu Setlist-Detail zurückgeleitet

**Schritt 3: Musiker werden informiert**

```
┌─────────────────────────────────────────┐
│ ✓ Broadcast-Session beendet             │
└─────────────────────────────────────────┘
     ↓ Toast (2s)
```

- **Broadcast-Indicator verschwindet** aus Header
- **Keine Unterbrechung im Spielmodus:** Musiker bleiben in aktueller Noten-Ansicht (können weiter üben)

### 8.3 Auto-Timeout

**Szenario:** Keine Aktivität für 4 Stunden.

**Server beendet Session automatisch:**

```
┌─────────────────────────────────────────┐
│ ℹ Broadcast-Session abgelaufen          │
├─────────────────────────────────────────┤
│                                         │
│ Die Session wurde automatisch nach      │
│ 4 Stunden Inaktivität beendet.          │
│                                         │
│                    [OK]                 │
└─────────────────────────────────────────┘
```

---

## 9. Edge Cases & Error States

### 9.1 Musiker beitritt ohne Instrument/Stimme

**Szenario:** Nutzer hat kein Instrument im Profil.

```
┌─────────────────────────────────────────┐
│ ⚠ Instrument fehlt                      │
├─────────────────────────────────────────┤
│                                         │
│ Um Broadcast-Stücke zu empfangen,       │
│ musst du dein Instrument im Profil      │
│ angeben.                                │
│                                         │
│       [Abbrechen]  [Profil öffnen]      │
└─────────────────────────────────────────┘
```

**Button „Profil öffnen":** Öffnet User-Settings → Instrument wählen

### 9.2 Dirigent sendet Stück ohne Noten

**Szenario:** Stück hat keine Noten hochgeladen.

```
┌─────────────────────────────────────────┐
│ ⚠ Noten fehlen                          │
├─────────────────────────────────────────┤
│                                         │
│ „Böhmischer Traum" hat keine Noten.     │
│                                         │
│ Musiker können das Stück nicht öffnen.  │
│                                         │
│ Trotzdem senden?                        │
│                                         │
│         [Abbrechen]  [Trotzdem senden]  │
└─────────────────────────────────────────┘
```

**Button „Trotzdem senden":**  
→ Sendet Broadcast, Musiker erhalten Meldung „Noten fehlen"

### 9.3 Mehrere Geräte pro Musiker

**Szenario:** Musiker ist mit Tablet + Phone verbunden.

**Verhalten:**
- **Beide Geräte empfangen Broadcast**
- **Dirigent sieht:** 12 Musiker, aber 14 Verbindungen (in Details)
- **Zählung:** Pro User, nicht pro Device

```
│ 📡 12 Musiker verbunden (14 Geräte)     │
```

### 9.4 Session-Kollision (zweiter Dirigent startet Session)

**Szenario:** Siehe Flow A, Schritt 3 (Takeover-Dialog).

### 9.5 Musiker verlässt Session manuell

**Tap auf Broadcast-Indicator → „Session verlassen":**

```
┌─────────────────────────────────────────┐
│ Session verlassen?                      │
├─────────────────────────────────────────┤
│                                         │
│ Du erhältst keine weiteren Stück-       │
│ Updates vom Dirigenten.                 │
│                                         │
│         [Abbrechen]  [Verlassen]        │
└─────────────────────────────────────────┘
```

**Button „Verlassen":**

```
┌─────────────────────────────────────────┐
│ ✓ Session verlassen                     │
└─────────────────────────────────────────┘
     ↓ Toast (2s)
```

→ Broadcast-Indicator verschwindet, Musiker ist offline

### 9.6 Dirigent-Gerät crashed

**Szenario:** Dirigent-App stürzt ab, Session läuft auf Server weiter.

**Verhalten:**
- **Session bleibt aktiv** (Server-Side)
- **Musiker bleiben verbunden**, können aktuelles Stück weiter nutzen
- **Dirigent öffnet App erneut:**

```
┌─────────────────────────────────────────┐
│ ℹ Aktive Session gefunden               │
├─────────────────────────────────────────┤
│                                         │
│ Deine Broadcast-Session läuft noch:     │
│                                         │
│ Gestartet: 18:30 Uhr                    │
│ 12 Musiker verbunden                    │
│                                         │
│ Möchtest du die Session fortsetzen?     │
│                                         │
│         [Beenden]  [Fortsetzen]         │
└─────────────────────────────────────────┘
```

**Button „Fortsetzen":** Reconnect zu Session

### 9.7 Broadcast während Auftritt (andere Setlist)

**Szenario:** Dirigent startet Broadcast mit Setlist A, wechselt dann zu Setlist B.

**Verhalten:**
- **Broadcast ist Setlist-unabhängig** (nach Start)
- **Dirigent kann aus beliebiger Setlist/Bibliothek senden**
- **Broadcast-Control zeigt:** „Freie Auswahl" (statt Setlist-Name)

---

## 10. Wireframes: Phone (Musiker)

### 10.1 Beitritt-Banner

```
┌─────────────────────┐
│┌───────────────────┐│
││ 📡 Broadcast aktiv││
││                   ││
││ Dirigent: Max M.  ││
││                   ││
││[Beitreten][Später]││
│└───────────────────┘│
│                     │
│ Bibliothek          │
│ [Suche…]        🔍  │
│                     │
│ ⋮                   │
└─────────────────────┘
```

### 10.2 Verbindungs-Indicator (Header)

```
┌─────────────────────┐
│ 📡 Broadcast · 12  ←│◄── Tap für Details
├─────────────────────┤
│ Bibliothek          │
│ [Suche…]        🔍  │
│ ⋮                   │
└─────────────────────┘
```

### 10.3 Stück-Empfang (Notification)

```
┌─────────────────────┐
│┌───────────────────┐│
││ 🎵 Neues Stück    ││
││                   ││
││ An der schönen    ││
││ blauen Donau      ││
││                   ││
││ Lädt Trompete 1…  ││
│└───────────────────┘│
│                     │
│ Bibliothek          │
│ ⋮                   │
└─────────────────────┘
```

### 10.4 Fehlende Stimme

```
┌─────────────────────┐
│┌───────────────────┐│
││ ⚠ Stimme fehlt    ││
││                   ││
││ „Donau" hat keine ││
││ Trompete-1-Stimme ││
││                   ││
││ [Andere Stimme]   ││
││ [Schließen]       ││
│└───────────────────┘│
└─────────────────────┘
```

### 10.5 Verbindungs-Status (Modal)

```
┌─────────────────────┐
│ Broadcast-Session [×]│
├─────────────────────┤
│                     │
│ Status: Verbunden ✓ │
│                     │
│ Dirigent: Max M.    │
│ Setlist: Frühj…     │
│ Musiker: 12         │
│ Latenz: 120ms (Gut) │
│                     │
│ Aktuelles Stück:    │
│ An der schönen      │
│ blauen Donau        │
│ Stimme: Trompete 1  │
│                     │
│ [Session verlassen] │
└─────────────────────┘
```

---

## 11. Wireframes: Tablet (Dirigent)

### 11.1 Broadcast-Control (Landscape)

```
┌─────────────────────────────────────────────────────────────────┐
│ ← Broadcast-Session                               [Beenden]     │
├───────────────────────┬─────────────────────────────────────────┤
│ Verbindungs-Status    │ Aktuelles Stück                         │
│                       │                                         │
│ 📡 12 Musiker         │ ┌─────────────────────────────────────┐ │
│ Latenz: 120ms (Gut) ✓ │ │ An der schönen blauen Donau         │ │
│                       │ │ Johann Strauß (Sohn)                │ │
│ ──────────────────    │ │                                     │ │
│                       │ │ ✓ 12/12 Musiker empfangen           │ │
│ Musiker-Liste:        │ │ ✓ 12/12 Noten geladen               │ │
│                       │ └─────────────────────────────────────┘ │
│ ✓ Max M. (Trompete 1) │                                         │
│ ✓ Anna S. (Flöte 1)   │ ═══ Setlist: Frühjahrskonzert ═══       │
│ ✓ Tom W. (Posaune 3)  │                                         │
│ ⋮                     │ ┌─────────────────────────────────────┐ │▒
│                       │ │ ● 1. Radetzky-Marsch           (12) │ │▒
│ [Details anzeigen]    │ └─────────────────────────────────────┘ │▒
│                       │ ┌─────────────────────────────────────┐ │▒
│                       │ │ ○ 2. An der schönen blauen Donau    │ │▒
│                       │ └─────────────────────────────────────┘ │▒
│                       │ ┌─────────────────────────────────────┐ │▒
│                       │ │ ○ 3. Böhmischer Traum               │ │▒
│                       │ └─────────────────────────────────────┘ │▒
│                       │ ┌─────────────────────────────────────┐ │▒
│                       │ │ ○ 4. Slawischer Tanz Nr. 1          │ │▒
│                       │ └─────────────────────────────────────┘ │▒
│                       │                                         │▒
│                       │ ⋮                                       │▒
└───────────────────────┴─────────────────────────────────────────┘
   ← 280px Sidebar      ← Stück-Auswahl (tappable list)
```

- **Sidebar:** Verbindungs-Status + Musiker-Liste (mit Expand-Button für Details)
- **Hauptbereich:** Aktuelles Stück + Setlist zum Auswählen

### 11.2 Musiker-Details (Expandiert)

```
┌───────────────────────┐
│ Musiker-Details    [×]│
├───────────────────────┤
│                       │▒
│ ✓ Max Müller          │▒
│   Trompete 1          │▒
│   Latenz: 110ms       │▒
│   Noten geladen ✓     │▒
│                       │▒
│ ✓ Anna Schmidt        │▒
│   Flöte 1             │▒
│   Latenz: 130ms       │▒
│   Noten geladen ✓     │▒
│                       │▒
│ ⚠ Tom Weber           │▒
│   Posaune 3           │▒
│   Latenz: 890ms       │▒
│   Stimme fehlt ⚠      │▒
│                       │▒
│ ⋮                     │▒
└───────────────────────┘
```

---

## 12. Accessibility

### 12.1 Touch Targets

- **Setlist-Stücke (Dirigent):** Mind. 56px hoch (gesamte Zeile tappable)
- **Button „Beitreten":** 44×44px
- **Broadcast-Indicator:** 44px hoch (tappable für Details)

### 12.2 Kontrast & Farben

- **Verbindungs-Status:**
  - Verbunden: Grün `#16A34A` + Icon `📡`
  - Reconnecting: Orange `#D97706` + Icon `⚠`
  - Getrennt: Rot `#DC2626` + Icon `✗`
- **Latenz:**
  - Gut (<500ms): Grün
  - Mittel (500–1000ms): Orange
  - Schlecht (>1000ms): Rot

### 12.3 Keyboard Navigation (Desktop)

- **Tab-Reihenfolge:** Setlist-Stücke von oben nach unten
- **Enter:** Sendet Stück
- **Escape:** Schließt Modals
- **Shortcuts:**
  - `Cmd/Ctrl + B`: Broadcast starten/beenden
  - `Arrow Up/Down`: Navigiere in Setlist
  - `Space`: Sende ausgewähltes Stück

### 12.4 Screen Reader

- **Broadcast-Indicator:**
  - Aria-Label: „Broadcast-Session aktiv, 12 Musiker verbunden, Latenz 120 Millisekunden"
- **Stück-Karten:**
  - Aria-Label: „Radetzky-Marsch, aktuell gesendet, 12 Musiker empfangen"
- **Live Regions:**
  - Verbindungs-Status: „12 von 12 Musiker haben Noten geladen"

### 12.5 Reconnect-Feedback

- **< 3s:** Kein Audio-Feedback
- **> 3s:** Optional: Subtle Vibration (Mobile) bei Reconnect
- **Keine lauten Sounds:** Proben-Umgebung ist laut, Audio-Feedback wäre nicht hörbar

---

## 13. Abhängigkeiten

### 13.1 Backend-API

- **REST-Endpoints:** `/api/v1/broadcast/*`
- **SignalR Hub:** `/hubs/broadcast`
- **WebSocket-Fallback:** SSE / Long-Polling
- **Performance-Ziele:**
  - Latenz <500ms
  - 120 Concurrent Connections
  - Reconnect <3s

### 13.2 Frontend-Komponenten

- **Neu:**
  - `BroadcastControlView` (Dirigent)
  - `BroadcastJoinBanner` (Musiker)
  - `BroadcastStatusIndicator` (Header)
  - `BroadcastConnectionModal` (Status-Details)
  - `MusikersListPanel` (Dirigent-Sidebar)
- **Bestehend (reuse):**
  - `Spielmodus` (Auto-Open für Musiker)
  - `StimmenAuswahl` (Fallback bei fehlender Stimme)
  - `ToastNotification`
  - `ConfirmDialog`

### 13.3 Permissions

- **Admin, Dirigent:** Broadcast starten, kontrollieren, beenden
- **Alle Rollen:** Session beitreten als Musiker
- **Notenwart, Registerführer, Musiker:** Nur Empfangen, nicht Senden

### 13.4 Offline-Verhalten

- **Broadcast-Start:** Nur online
- **Stück-Empfang:** Nur online (aber Noten werden lokal gecacht)
- **Reconnect:** Automatisch bei Verbindungsverlust
- **Spielmodus:** Funktioniert offline (bereits geladene Noten)

### 13.5 Responsive Breakpoints

| Breakpoint       | Dirigent-View           | Musiker-View          |
|------------------|-------------------------|-----------------------|
| Phone (<600px)   | Scrollable List         | Banner + Indicator    |
| Tablet (600–1024)| Split-View (Sidebar)    | Banner + Indicator    |
| Desktop (>1024)  | Split-View + Details    | Banner + Indicator    |

### 13.6 Performance-Monitoring

- **Latenz-Tracking:** Dirigent sieht Durchschnitts-Latenz + Pro-Musiker-Details
- **Fehler-Logging:** Reconnect-Attempts, Failed Broadcasts, Missing Voices
- **Analytics:** Session-Dauer, Stück-Wechsel-Häufigkeit, Musiker-Anzahl

---

**Ende UX-Spec Song-Broadcast**
