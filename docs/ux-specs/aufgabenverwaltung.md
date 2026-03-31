# UX-Spec: Aufgabenverwaltung (To-Do)

> **Issue:** MS3 — Aufgabenverwaltung  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-31  
> **Meilenstein:** MS3 — Tuner + Echtzeit-Klick + Cloud-Sync  
> **Referenzen:** `docs/meilensteine.md §MS3`, `docs/ux-design.md`, `docs/ux-konfiguration.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Designprinzipien](#1-übersicht--designprinzipien)
2. [User Flow: Aufgabe erstellen](#2-user-flow-aufgabe-erstellen)
3. [User Flow: Aufgaben verwalten](#3-user-flow-aufgaben-verwalten)
4. [User Flow: Erinnerung empfangen](#4-user-flow-erinnerung-empfangen)
5. [Task-Liste mit Filter](#5-task-liste-mit-filter)
6. [Aufgabe erstellen](#6-aufgabe-erstellen)
7. [Task-Detail & Status-Änderung](#7-task-detail--status-änderung)
8. [Erinnerungen & Termin-Kopplung](#8-erinnerungen--termin-kopplung)
9. [Micro-Interactions & Animationen](#9-micro-interactions--animationen)
10. [Wireframes: Phone](#10-wireframes-phone)
11. [Wireframes: Tablet & Desktop](#11-wireframes-tablet--desktop)
12. [Accessibility](#12-accessibility)
13. [Responsiveness](#13-responsiveness)
14. [Error States & Edge Cases](#14-error-states--edge-cases)
15. [Integration mit Navigation (GoRouter)](#15-integration-mit-navigation-gorouter)
16. [Abhängigkeiten](#16-abhängigkeiten)

---

## 1. Übersicht & Designprinzipien

### 1.1 Kernsatz

> „Der Vorstand organisiert den Verein — Sheetstorm ist die einzige App, die er dafür braucht."

Aufgabenverwaltung bringt Vereins-To-Dos direkt in die App. Bisher nutzt der Vorstand WhatsApp-Gruppen oder Excel-Listen. Sheetstorm bietet eine strukturierte Alternative, die zum Vereinsleben passt.

### 1.2 Personas im Fokus

| Persona | Nutzung | Priorität |
|---------|---------|-----------|
| **Vorstandsmitglied** | Aufgaben erstellen, zuweisen, Status tracken | Kritisch |
| **Kapellenleiter/Admin** | Aufgaben erstellen für alle | Kritisch |
| **Musiker** | Eigene Aufgaben sehen + Status aktualisieren | Standard |

### 1.3 Scope Abgrenzung

**In Scope (MS3):**
- Aufgaben erstellen mit Titel, Beschreibung, Zuweisung, Fälligkeit
- Status-Flow: Offen → In Bearbeitung → Erledigt
- Filter nach Status
- Erinnerungen + optionale Termin-Kopplung
- Benachrichtigungen bei Fälligkeit

**Out of Scope (MS3):**
- Unteraufgaben (Sub-Tasks)
- Wiederkehrende Aufgaben
- Prioritätsstufen (Low/Medium/High)
- Kommentare / Diskussionen
- Gantt / Kalender-Ansicht

### 1.4 Designprinzipien

| Prinzip | Auswirkung |
|---------|-----------|
| **Minimal, nicht mächtig** | Kein Overkill — Vereinsvorstand braucht kein Jira |
| **Schnell erfassen** | Neue Aufgabe in < 20 Sekunden erstellt |
| **Status auf einen Blick** | Filter + Farb-Kodierung, keine Tabellen |
| **Push zur richtigen Zeit** | Erinnerungen nur wenn sinnvoll, nie Spam |

---

## 2. User Flow: Aufgabe erstellen

```
Vereinsleben → Aufgaben  (oder: direkt über FAB)
        │
        ▼
  Task-Liste öffnet
        │
        ▼
  [+ Aufgabe] FAB tippen
        │
        ▼
  Aufgabe-Erstellen-Sheet öffnet (§6)
        │
        ├──── Titel eingeben (Pflicht)
        ├──── Beschreibung (optional)
        ├──── Zuweisen (optional) — Suche unter Kapellenmitgliedern
        ├──── Fälligkeit (optional) — Datepicker
        └──── Termin verknüpfen (optional) — §8
        │
        ▼
  [Erstellen] tippen
        │
        ▼
  Aufgabe erscheint in Liste (Status: Offen)
  Zugewiesene Person erhält Push-Notification
```

---

## 3. User Flow: Aufgaben verwalten

```
Task-Liste
        │
        ├──── Filter wechseln [Offen | In Bearbeitung | Erledigt | Alle]
        │
        ├──── Aufgabe antippen → Task-Detail (§7)
        │             │
        │             ├──── Status ändern
        │             ├──── Beschreibung lesen
        │             └──── Aufgabe löschen (nur Ersteller / Admin)
        │
        └──── Swipe auf Aufgabe → Schnell-Aktionen
                      ├──── Swipe rechts: Als erledigt markieren ✓
                      └──── Swipe links: Löschen (mit Bestätigung)
```

---

## 4. User Flow: Erinnerung empfangen

```
Fälligkeitsdatum ist heute (oder morgen, je nach Einstellung)
        │
        ▼
  Push-Notification erscheint
  „Aufgabe fällig: Notensätze kopieren · Heute"
        │
        ▼
  Nutzer tippt auf Notification
        │
        ▼
  App öffnet Task-Detail der Aufgabe
        │
        ├──── Status auf „In Bearbeitung" setzen
        └──── Status auf „Erledigt" setzen
```

---

## 5. Task-Liste mit Filter

### 5.1 Layout

```
┌─────────────────────────────────────────────────────┐
│  Aufgaben                              [+ Erstellen] │
├─────────────────────────────────────────────────────┤
│  [Offen (8)] [In Bearbeitung (3)] [Erledigt (12)]   │
├─────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────┐    │
│  │  ○  Notensätze kopieren                    │    │
│  │     📅 Morgen · Zugewiesen: Thomas          │    │
│  └─────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────┐    │
│  │  ○  Uniform-Reinigung organisieren          │    │
│  │     📅 15. April · Zugewiesen: Alle          │    │
│  └─────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────┐    │  ← Überfällig
│  │  ⚠  GEMA-Meldung einreichen                │    │
│  │     📅 Gestern · Zugewiesen: Admin           │    │
│  └─────────────────────────────────────────────┘    │
│                                                     │
│              (+ mehr laden)                         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 5.2 Filter-Tabs

| Tab | Inhalt |
|-----|--------|
| **Offen** | Status = Offen (Default) |
| **In Bearbeitung** | Status = In Bearbeitung |
| **Erledigt** | Status = Erledigt (letzte 30 Tage) |
| *(kein „Alle"-Tab)* | Zu unübersichtlich für Vereinskontext |

- Filter-Tab zeigt Anzahl in Klammern: `Offen (8)`
- Tab-Selektion: Animated-Underline, `color-primary`
- **Mein Filter (Schnellzugriff):** Oben: `[Mir zugewiesen (5)]` als Chip — zeigt nur eigene Aufgaben

### 5.3 Task-Karte

```
┌────────────────────────────────────────────────────┐
│  ○  [Titel, 1-2 Zeilen]                           │
│     📅 [Datum]  ·  👤 [Name] oder "Alle"           │
└────────────────────────────────────────────────────┘
```

- **Checkbox-Icon:** `○` = Offen, `◐` = In Bearbeitung, `●` = Erledigt
- **Farb-Kodierung Status:**
  - Offen: `color-text-primary`
  - In Bearbeitung: `color-primary`
  - Erledigt: `color-text-secondary` + Durchstrich auf Titel
  - Überfällig: `color-error` auf Datum

- **Karten-Höhe:** min. 64px (Touch-Target)
- **Swipe-Geste:** aktivierbar nach 40px horizontaler Bewegung

### 5.4 Überfällige Aufgaben

Überfällige Aufgaben erscheinen **oben in ihrem Status-Tab** (pinned), mit rotem Datum.

---

## 6. Aufgabe erstellen

### 6.1 Erstellen-Modal / Bottom Sheet

```
┌───────────────────────────────────────────────┐
│  ────  (Drag-Handle)                          │
│  Neue Aufgabe                          [Abbrechen] │
│  ─────────────────────────────────────────    │
│                                               │
│  ┌────────────────────────────────────────┐  │
│  │  Titel *                               │  │
│  │  Was muss erledigt werden?             │  │
│  └────────────────────────────────────────┘  │
│                                               │
│  ┌────────────────────────────────────────┐  │
│  │  Beschreibung (optional)               │  │
│  │  Details, Links, Notizen...            │  │
│  └────────────────────────────────────────┘  │
│                                               │
│  ┌────────────────────────────────────────┐  │
│  │  👤 Zuweisen (optional)                │  │
│  │  [Suche Mitglied...]                   │  │
│  └────────────────────────────────────────┘  │
│                                               │
│  ┌────────────────────────────────────────┐  │
│  │  📅 Fällig bis (optional)              │  │
│  │  [Datum wählen...]                     │  │
│  └────────────────────────────────────────┘  │
│                                               │
│  ┌────────────────────────────────────────┐  │
│  │  📆 An Termin koppeln (optional)       │  │
│  │  [Termin wählen...]                    │  │
│  └────────────────────────────────────────┘  │
│                                               │
│  ─────────────────────────────────────────   │
│  [────────────── Aufgabe erstellen ──────────────] │
└───────────────────────────────────────────────┘
```

### 6.2 Feld-Details

**Titel:**
- Pflichtfeld, max. 100 Zeichen
- Validierung: onBlur, bei leerem Feld nicht speicherbar
- Keyboard öffnet bei Sheet-Öffnung automatisch

**Beschreibung:**
- Optional, mehrzeilig
- Max. 500 Zeichen
- Zähler ab 400 Zeichen

**Zuweisen:**
- Suche unter aktuellen Kapellenmitgliedern
- `"Alle"` als Option (Aufgabe für alle sichtbar/zugewiesen)
- Eigener Name als Vorschlag ganz oben
- Max. 1 Person zugewiesen (MS3) — keine Multi-Assign

**Fälligkeit:**
- Nativer Datepicker
- Shortcuts: `[Heute]` `[Morgen]` `[Nächste Woche]`
- Kein Zeitpunkt — nur Datum (vereinfacht)

**Termin-Kopplung:**
- Auswahl aus bevorstehenden Terminen der Kapelle
- Zeigt Termin-Datum + Name
- Wenn Termin gewählt: Fälligkeit wird automatisch auf Termin-Datum gesetzt

### 6.3 Erstellen-Button

- Aktiv nur wenn Titel nicht leer
- `color-primary` Background, `color-on-primary` Text
- Label: „Aufgabe erstellen"

---

## 7. Task-Detail & Status-Änderung

### 7.1 Task-Detail-Screen

```
┌─────────────────────────────────────────────────┐
│ ← Aufgaben             [Bearbeiten]  [⋮ Mehr]   │
├─────────────────────────────────────────────────┤
│                                                 │
│  ○  Notensätze für Frühjahrskonzert kopieren   │  ← Titel (large)
│                                                 │
│  ─────────────────────────────────────────────  │
│  Status:                                        │
│  [ Offen ]  →  [ In Bearbeitung ]  →  [ Erledigt ] │
│       ●              ○                    ○     │
│                                                 │
│  ─────────────────────────────────────────────  │
│  📅 Fällig bis: Morgen, 15. April               │
│  👤 Zugewiesen: Thomas Maier                    │
│  📆 Termin: Frühjahrskonzert, 20. April         │
│  👤 Erstellt von: Klaus Bauer · 14. März        │
│                                                 │
│  ─────────────────────────────────────────────  │
│  Beschreibung:                                  │
│  Die Notensätze für das Frühjahrskonzert        │
│  müssen bis Montag kopiert werden.             │
│  PDF liegt im Ordner...                         │
│                                                 │
│  ─────────────────────────────────────────────  │
│  [✓ Als erledigt markieren]                    │  ← Primäre CTA
└─────────────────────────────────────────────────┘
```

### 7.2 Status-Änderung

**Methode 1: Status-Stepper im Detail**

```
[ Offen ] → [ In Bearbeitung ] → [ Erledigt ]
     ●              ○                  ○
```

- Tippen auf nächsten Status → wechselt sofort
- Rückwärts: Tippen auf vorherigen Schritt möglich
- Confirmation nur bei „Erledigt" (optional, §9.2)

**Methode 2: Primäre CTA-Button**

- `[✓ Als erledigt markieren]` — wenn Status Offen oder In Bearbeitung
- `[↺ Erneut öffnen]` — wenn Status Erledigt

**Methode 3: Swipe in der Liste (§3)**

### 7.3 Bearbeiten

- Button oben rechts: `[Bearbeiten]`
- Öffnet dasselbe Sheet wie Erstellen, vorausgefüllt
- Alle Felder editierbar

### 7.4 Löschen

- Im `[⋮ Mehr]`-Menü: `[Aufgabe löschen]`
- Destructive Action → Bestätigungs-Dialog:
  ```
  Aufgabe löschen?
  "Notensätze kopieren" wird permanent gelöscht.
  [Abbrechen]  [Löschen]
  ```
- Nur verfügbar für: Ersteller der Aufgabe + Admin/Kapellenleiter

---

## 8. Erinnerungen & Termin-Kopplung

### 8.1 Erinnerungs-Logik

| Fälligkeits-Zeitpunkt | Automatische Erinnerung |
|----------------------|------------------------|
| Heute | Morgens um 08:00 Uhr |
| Morgen | Heute Abend um 18:00 Uhr |
| Diese Woche | 2 Tage vorher |
| Weiter in der Zukunft | 1 Woche vorher |

Erinnerungen sind **standardmäßig aktiviert**. Ausschalten pro Aufgabe oder global in Einstellungen.

### 8.2 Termin-Kopplung

Eine Aufgabe kann an einen Kapellen-Termin (Probe, Auftritt, Meeting) gekoppelt werden.

**Logik:**
- Fälligkeit = Termin-Datum (automatisch gesetzt)
- Erinnerung = 3 Tage vor Termin (zusätzlich zur normalen Erinnerung)

**Anzeige in Task-Detail:**
```
📆 Frühjahrskonzert · 20. April
```
Tippen → springt zum Termin-Detail (falls vorhanden)

### 8.3 Benachrichtigungs-Inhalt

```
🔔 Aufgabe fällig
Notensätze kopieren · Heute
Tippen zum Öffnen
```

- **Silent Notifications** während aktiver Probe (wenn Spielmodus geöffnet): Erinnerung in Notification-Center, kein Banner

---

## 9. Micro-Interactions & Animationen

### 9.1 Neue Aufgabe erstellt

- Task erscheint in Liste mit `slide-in + fade-in` von oben
- `AppDurations.base` (250ms), `AppCurves.easeOut`
- Badge im Filter-Tab (`Offen (N+1)`) aktualisiert sich

### 9.2 Status auf „Erledigt" ändern

| Schritt | Animation |
|---------|-----------|
| Tippen auf „Erledigt" | Checkbox: ○ → ● mit Checkmark-Animation (Scale 0.5 → 1.2 → 1.0) |
| Titel | Durchstrich-Animation (Linie von links nach rechts, 300ms) |
| Karte | Fades in sekundäre Farbe (300ms) |
| Filter-Update | `Offen (N-1)` — Zahl animiert (flip-counter) |

### 9.3 Swipe auf Aufgabe

| Swipe | Reveal | Action |
|-------|--------|--------|
| Swipe rechts | Grünes Häkchen-Panel | Erledigt markieren |
| Swipe links | Rotes Papierkorb-Panel | Löschen (Confirmation) |

- Reveal-Animation: `AppDurations.fast` (150ms)
- Nach Aktion: Karte slides-out (400ms)

### 9.4 Filter wechseln

- Liste: `crossfade` zwischen Listen (neue Liste fades in)
- Tab-Indicator: Animated underline bewegt sich horizontal

---

## 10. Wireframes: Phone

### 10.1 Task-Liste (Offen)

```
┌───────────────────────────┐
│ ●●●●●●●●●●●●●●●●●●●●●●● │
├───────────────────────────┤
│ Aufgaben           [+ ✎] │
├───────────────────────────┤
│ [Mir (5)]                 │  ← Schnellfilter-Chip
├───────────────────────────┤
│[Offen(8)][Bearb.(3)][Erl.]│  ← Filter-Tabs
├───────────────────────────┤
│ ┌─────────────────────┐   │  ← Überfällig (oben gepinnt)
│ │⚠ GEMA-Meldung       │   │
│ │  📅 Gestern · Admin  │   │
│ └─────────────────────┘   │
│ ┌─────────────────────┐   │
│ │○ Notensätze kopieren│   │
│ │  📅 Morgen · Thomas  │   │
│ └─────────────────────┘   │
│ ┌─────────────────────┐   │
│ │○ Uniform-Reinigung  │   │
│ │  📅 15. April · Alle │   │
│ └─────────────────────┘   │
├───────────────────────────┤
│ 🎵  📚  🔧  👤            │
└───────────────────────────┘
         [+]                  ← FAB (Aufgabe erstellen)
```

### 10.2 Aufgabe-Erstellen-Sheet (Phone)

```
┌───────────────────────────┐
│ ────                      │
│ Neue Aufgabe   [Abbrechen]│
│ ─────────────────────────-│
│ ┌─────────────────────┐   │
│ │ Titel *             │   │  ← Fokus
│ └─────────────────────┘   │
│ ┌─────────────────────┐   │
│ │ Beschreibung...     │   │
│ └─────────────────────┘   │
│                           │
│ 👤 [Zuweisen an...]       │
│ 📅 [Fälligkeit...]        │
│ 📆 [Termin koppeln...]    │
│                           │
│[──── Aufgabe erstellen ──]│
└───────────────────────────┘
```

---

## 11. Wireframes: Tablet & Desktop

### 11.1 Tablet (Landscape) — Split View

```
┌───────────────────────────────────────────────────────────┐
│  Aufgaben                                    [+ Erstellen] │
├──────────────────────┬────────────────────────────────────┤
│ [Mir (5)]            │  Notensätze kopieren                │
│ ─────────────────    │  ─────────────────────────────────  │
│ [Offen(8)][Bearb.][E]│  Status: ● Offen → ○ Bearb. → ○ E  │
│ ─────────────────    │                                     │
│ ⚠ GEMA-Meldung      │  📅 Morgen, 15. April               │
│   Gestern · Admin    │  👤 Thomas Maier                    │
│ ○ Notensätze kop.    │  📆 Frühjahrskonzert                │
│   Morgen · Thomas    │                                     │
│ ○ Uniform-Reinigung  │  Beschreibung:                      │
│   15. April · Alle   │  Die Notensätze für das             │
│ ...                  │  Frühjahrskonzert...                │
│                      │                                     │
│                      │  [✓ Als erledigt markieren]        │
└──────────────────────┴────────────────────────────────────┘
```

### 11.2 Desktop

```
┌──────────────────────────────────────────────────────────────────────┐
│  Sheetstorm · Vereinsleben · Aufgaben              [+ Neue Aufgabe]  │
├──────────────────────────────────────────────────────────────────────┤
│  [Mir zugewiesen (5)]  [Alle]                     🔍 Suchen...       │
├─────────────────────────────┬────────────────────────────────────────┤
│  [Offen(8)][Bearb.(3)][Erl.]│                                       │
│  ─────────────────────────  │  DETAIL                                │
│  ⚠ GEMA-Meldung (gestern)  │  Notensätze kopieren                   │
│  ○ Notensätze kopieren      │  Status: [Offen ●] →[In Bearb.] →[Erl]│
│  ○ Uniform-Reinigung        │  ...                                   │
│  ○ Fahrzeug reservieren     │  [Als erledigt markieren]              │
│  ...                        │  [Bearbeiten]  [Löschen]               │
└─────────────────────────────┴────────────────────────────────────────┘
```

---

## 12. Accessibility

### 12.1 Touch-Targets

| Element | Mindestgröße |
|---------|-------------|
| Task-Karte | 64px Höhe |
| Status-Stepper (Punkte) | 44×44 px |
| FAB [+] | 56×56 px |
| Filter-Tabs | 44px Höhe |
| Swipe-Aktions-Buttons | 80px Breite × 64px Höhe |
| CTA „Als erledigt" | 44px Höhe, 100% Breite |

### 12.2 Screen-Reader

- **Task-Karte:** `Semantics(label: "Notensätze kopieren, fällig morgen, zugewiesen an Thomas, Status: Offen")`
- **Status-Stepper:** `Semantics(label: "Status: Offen", button: true, onTap: "Status ändern")`
- **FAB:** `Semantics(label: "Neue Aufgabe erstellen")`
- **Filter-Tab:** `Semantics(label: "Offene Aufgaben, 8 Einträge", selected: true/false)`
- **Swipe-Aktion:** `Semantics(customAction: "Als erledigt markieren")` / `"Löschen"`

### 12.3 Fokus-Management

- Nach Erstellen: Fokus auf neue Aufgabe in der Liste
- Nach Löschen: Fokus auf nächste Aufgabe in der Liste
- Modal schließt → Fokus zurück zum auslösenden Element

---

## 13. Responsiveness

| Breakpoint | Layout |
|------------|--------|
| Phone Portrait | Einspaltiges Scroll-Layout, Detail als neuer Screen |
| Phone Landscape | Einspaltiges Scroll-Layout |
| Tablet Portrait | Einspaltiges Scroll-Layout, Detail als Modal |
| Tablet Landscape | Split-View: Liste links, Detail rechts |
| Desktop | Split-View mit breiterer Sidebar |

---

## 14. Error States & Edge Cases

### 14.1 Keine Aufgaben (Leerer State)

```
┌─────────────────────────────────────────────────┐
│                                                 │
│              ✓                                  │
│                                                 │
│    Keine offenen Aufgaben                       │
│    Alles erledigt — oder noch nichts            │
│    erstellt.                                    │
│                                                 │
│    [+ Erste Aufgabe erstellen]                  │
└─────────────────────────────────────────────────┘
```

- Friendly Empty State mit CTA
- Verschiedene Texte je nach Filter: „Alle Aufgaben erledigt! 🎉" (Erledigt-Tab leer)

### 14.2 Fälligkeitsdatum in der Vergangenheit (Erstellung)

- Warnung unter Datepicker: `⚠ Dieses Datum liegt in der Vergangenheit`
- Kein Blocking — Nutzer kann trotzdem speichern (rückwirkende Aufgaben sind valide)

### 14.3 Zuweisung an nicht-aktives Mitglied

- Beim Zuweisen: Inaktive Mitglieder werden ausgegraut angezeigt (nicht auswählbar in MS3)
- Hinweis: `Nur aktive Mitglieder können Aufgaben erhalten`

### 14.4 Termin wurde gelöscht, Aufgabe noch aktiv

- Task-Detail zeigt: `📆 Termin nicht mehr vorhanden`
- Kein Fehler — Aufgabe bleibt bestehen, Termin-Verknüpfung wird entfernt

### 14.5 Sehr langer Titel (100 Zeichen)

- In der Karten-Ansicht: 2-zeilig abgeschnitten mit `…`
- Im Detail: vollständig angezeigt

### 14.6 Offline — Aufgabe erstellen

- Aufgabe wird lokal erstellt und in Sync-Queue
- Zuweisung-Notification wird verzögert gesendet (wenn online)
- UI zeigt keine spezielle Offline-Warnung beim Erstellen

### 14.7 Viele Aufgaben (100+)

- Pagination: 20 Aufgaben pro Seite
- `(+ 80 weitere laden)` am Ende der Liste
- Suche-Funktion (§11.2) für Desktop-Breakpoint

---

## 15. Integration mit Navigation (GoRouter)

### 15.1 Routen

```
/association/tasks             → Task-Liste
/association/tasks/new         → Aufgabe erstellen (als Modal)
/association/tasks/:id         → Task-Detail
/association/tasks/:id/edit    → Aufgabe bearbeiten (als Modal)
```

### 15.2 Navigation in Vereinsleben-Tab

```
Bottom-Tab: 🎵 Kapelle
         └── Vereinsleben
                   └── Aufgaben  ← Dieser Screen
```

Alternativ-Platzierung: Eigener Tab oder unter „Verwaltung". → **Entscheidung offen für Thomas** — Empfehlung Wanda: Unter „Vereinsleben" als Sub-Sektion, da es zum Vereinsalltag gehört.

### 15.3 Notification Deep-Link

```
sheetstorm://association/tasks/:id
```

Öffnet direkt das Task-Detail wenn von Push-Notification getippt.

---

## 16. Abhängigkeiten

### 16.1 Für Implementierung (Hill / Romanoff / Banner)

- **Datenmodell:** Task (id, kapellen_id, titel, beschreibung, status, zugewiesen_an, erstellt_von, fällig_bis, termin_id, erstellt_am, aktualisiert_am)
- **Status-Enum:** `offen | in_bearbeitung | erledigt`
- **Push-Notifications:** Firebase Cloud Messaging (FCM) für Android/iOS; Web Push für Browser
- **Termin-Verknüpfung:** Foreign Key auf `termine`-Tabelle

### 16.2 Offene Entscheidungen für Thomas

- **Sichtbarkeit von Aufgaben:** Sehen alle Kapellenmitglieder alle Aufgaben, oder nur Admins/Vorstand? → Empfehlung Wanda: Alle sehen alle (Transparenz fördert Engagement), aber nur Admin/Kapellenleiter können löschen.
- **Multi-Assign:** Eine Aufgabe mehreren Personen zuweisen? → MS3: Nur eine Person. Erweiterung für später.
- **Navigation-Platzierung:** Vereinsleben Sub-Tab oder eigener Tab?
