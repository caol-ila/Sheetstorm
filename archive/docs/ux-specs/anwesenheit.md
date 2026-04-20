# UX-Spec: Anwesenheits-Statistiken — Sheetstorm

> **Version:** 1.0  
> **Status:** Entwurf — Review durch Hill (Frontend) und Banner (Backend) ausstehend  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-04-15  
> **Meilenstein:** M2 — Vereinsleben & Aufführung  
> **Issue:** TBD  
> **Referenzen:** `docs/feature-specs/anwesenheit-spec.md`, `docs/ux-design.md`, `docs/ux-konfiguration.md`

---

## Inhaltsverzeichnis

1. [Überblick & Konzept](#1-überblick--konzept)
2. [Design-Tokens (Referenz)](#2-design-tokens-referenz)
3. [Navigations-Integration](#3-navigations-integration)
4. [Flow 1: Anwesenheit pro Musiker](#4-flow-1-anwesenheit-pro-musiker)
5. [Flow 2: Register-Analyse](#5-flow-2-register-analyse)
6. [Flow 3: Trend-Ansicht](#6-flow-3-trend-ansicht)
7. [Flow 4: Export (CSV/PDF)](#7-flow-4-export-csvpdf)
8. [Interaction Patterns](#8-interaction-patterns)
9. [Error States & Leerzustände](#9-error-states--leerzustände)
10. [Accessibility](#10-accessibility)
11. [Responsive Breakpoints](#11-responsive-breakpoints)
12. [Abhängigkeiten](#12-abhängigkeiten)

---

## 1. Überblick & Konzept

### 1.1 Ziel

Dirigenten, Vorstände und Registerführer brauchen **übersichtliche Statistiken** zur Anwesenheit ihrer Mitglieder. Die Ansichten müssen schnell das Wesentliche zeigen und bei Bedarf Details ermöglichen — ohne den Nutzer mit Daten zu überfrachten.

**Kernproblem:**
- Wer fehlt häufig?
- Welche Register sind schlecht besetzt?
- Wo ist ein Trend (Verbesserung/Verschlechterung)?
- Welche Daten brauche ich für den Vereinsbericht?

### 1.2 Nutzungskontext

- **Dirigent/Vorstand:** Überblick vor Probe/Konzert → gezielte Ansprache bei Problemen
- **Registerführer:** Nur eigenes Register, Besetzungsplanung
- **Musiker:** Nur eigene Statistik → Selbstreflexion

### 1.3 Zugriffsberechtigung (RBAC)

| Rolle            | Musiker-Liste | Register-Liste | Trends | Export | Zeitraum-Filter |
|------------------|---------------|----------------|--------|--------|-----------------|
| **Musiker**      | Nur ich       | —              | Nur ich| —      | ✓               |
| **Registerführer** | Nur Register | Nur Register   | Nur Register | ✓     | ✓               |
| **Dirigent**     | Alle          | Alle           | Alle   | ✓      | ✓               |
| **Admin**        | Alle          | Alle           | Alle   | ✓      | ✓               |

### 1.4 Grundprinzipien

- **Kein Zahlen-Overkill:** Nur relevante KPIs zeigen (Quote, Teilnahmen, Trend)
- **Farb-Kodierung:** Grün >80%, Gelb 60–80%, Rot <60% — immer mit Label/Icon
- **Drill-Down:** Von Übersicht zu Details (Register → Musiker → Detail)
- **Kontext-Sensitive Defaults:** Registerführer sehen automatisch ihr Register
- **Export als separater Flow:** Nicht inline mit Statistik-Ansicht vermischen

---

## 2. Design-Tokens (Referenz)

Alle hier verwendeten Token stammen aus `docs/ux-design.md` § 7.

| Token                     | Wert       | Verwendung in Anwesenheits-Statistik         |
|---------------------------|------------|----------------------------------------------|
| `color-success`           | `#16A34A`  | Quote >80% (Grün)                            |
| `color-warning`           | `#D97706`  | Quote 60–80% (Gelb/Orange)                   |
| `color-error`             | `#DC2626`  | Quote <60% (Rot)                             |
| `color-text-secondary`    | `#6B7280`  | Sekundäre Labels, Zeitraum-Hinweise          |
| `color-border`            | `#E5E7EB`  | Tabellen-Rahmen, Segmente                    |
| `color-primary`           | `#1A56DB`  | Tab-Underline, Export-Button                 |
| `font-size-base`          | `16sp`     | Tabellen-Text, Labels                        |
| `font-size-lg`            | `20sp`     | Screen-Titel, KPI-Werte                      |
| `font-size-sm`            | `14sp`     | Sekundär-Text, Zeitraum-Filter               |
| `space-md`                | `16px`     | Padding zwischen Karten                      |
| `space-lg`                | `24px`     | Padding zwischen Abschnitten                 |
| `border-radius-md`        | `8px`      | Karten, Filter-Chips                         |
| `touch-target-min`        | `44×44px`  | Alle interaktiven Elemente                   |

---

## 3. Navigations-Integration

### 3.1 Entry Points

**Primär:**
- **Profil-Tab** → „Meine Anwesenheit" (für Musiker)
- **Kalender-Tab** → „Statistiken" (obere rechte Ecke, Icon: 📊)
- **Admin/Kapellen-Verwaltung** → „Anwesenheit & Reports"

**Sekundär:**
- Nach Termin-Teilnahme-Eintrag → „Übersicht Anwesenheit ansehen"

### 3.2 Deep Link

```
sheetstorm://kapelle/{kapelleId}/statistiken/anwesenheit
sheetstorm://kapelle/{kapelleId}/statistiken/anwesenheit?tab=musiker
sheetstorm://kapelle/{kapelleId}/statistiken/anwesenheit?tab=register
sheetstorm://kapelle/{kapelleId}/statistiken/anwesenheit?tab=trends
```

### 3.3 Navigation-Hierarchie

```
Kalender (Haupttab)
  └── Statistiken (Seite)
        ├── Tab: Musiker
        ├── Tab: Register
        └── Tab: Trends
```

---

## 4. Flow 1: Anwesenheit pro Musiker

### 4.1 Konzept

Zeigt eine **sortierbare Tabelle** aller Musiker mit:
- Name
- Teilnahmen (absolut)
- Abwesenheiten (absolut)
- Quote (%)
- Farb-Badge

### 4.2 Entry Point

1. Nutzer öffnet „Statistiken" vom Kalender-Tab
2. Standard-Tab: „Musiker"
3. Zeitraum-Filter ist standardmäßig „Letzte 3 Monate"

### 4.3 Interaktion

- **Sortierung:** Tap auf Spalten-Header → sortiert aufsteigend/absteigend
- **Filter:** Termintyp (Probe/Konzert/Marschmusik) — Multi-Select-Chips
- **Drill-Down:** Tap auf Musiker-Zeile → Detail-Ansicht (Phase 2)
- **Zeitraum:** Date-Range-Picker (Von/Bis)

### 4.4 Wireframe — Phone

```
┌─────────────────────────────────┐
│ ← Statistiken             📤    │ ← Header, Export-Icon rechts
├─────────────────────────────────┤
│ [Musiker] Register  Trends      │ ← Tab-Bar
├─────────────────────────────────┤
│ Zeitraum: [01.01.–31.03. ▼]    │ ← Zeitraum-Filter, expandable
│                                 │
│ Termintyp:                      │
│ [✓ Probe] [✓ Konzert] [Marsch] │ ← Filter-Chips, Multi-Select
│                                 │
├─────────────────────────────────┤
│ Name        Teil  Abs  Quote  │ ← Tabellen-Header (44px)
├─────────────────────────────────┤
│ Müller, A.   12   2   86% 🟢  │ ← Grün: >80%
│ Schmidt, B.   9   5   64% 🟡  │ ← Gelb: 60–80%
│ Weber, C.     6   8   43% 🔴  │ ← Rot: <60%
│ Fischer, D.  14   0  100% 🟢  │
│ ...                            │
│                                 │
│ [Sortierung: Quote absteigend]  │ ← Info, welche Sortierung aktiv
│                                 │
├─────────────────────────────────┤
│ ℹ️ Basis: 14 Termine im Zeitraum│ ← Kontext-Info
└─────────────────────────────────┘
```

**Hinweise:**
- Quote-Farbe ist auch als Text-Label dabei (nicht nur Farbe)
- Spalten-Header haben ↑/↓-Pfeile je nach Sortierung
- Bei < 5 Terminen im Zeitraum: Warnung „Zu wenig Daten für aussagekräftige Statistik"

### 4.5 Wireframe — Tablet/Desktop (Split-View)

```
┌──────────────────────────────────────────────────────────────┐
│ ← Kalender                                            📤      │
├──────────────────────────────────────────────────────────────┤
│ Statistiken: Anwesenheit                                     │
├──────────────────────────────────────────────────────────────┤
│ [Musiker]  [Register]  [Trends]          Zeitraum: [▼]      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Termintyp: [✓ Probe] [✓ Konzert] [Marschmusik]            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Name            Teilnahmen  Abwesenheiten  Quote       ││
│  ├────────────────────────────────────────────────────────┤ │
│  │ Müller, Anna        12          2         86% 🟢       ││
│  │ Schmidt, Bernd       9          5         64% 🟡       ││
│  │ Weber, Clara         6          8         43% 🔴       ││
│  │ Fischer, Daniel     14          0        100% 🟢       ││
│  │ ...                                                    ││
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ℹ️ Basis: 14 Termine im Zeitraum 01.01.–31.03.2026         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Desktop-Vorteile:**
- Mehr Spalten möglich: Name, Vorname, Register, Teilnahmen, Abwesenheiten, Quote
- Hover-Tooltip auf Quote-Badge: „12 von 14 Terminen"
- Inline-Sortierung durch Klick auf Header

---

## 5. Flow 2: Register-Analyse

### 5.1 Konzept

Zeigt eine **aggregierte Übersicht nach Registern**:
- Register-Name
- Ø Quote (Durchschnitt aller Mitglieder im Register)
- Anzahl Mitglieder
- Farb-Badge

**Drill-Down:**
- Tap auf Register → zeigt Musiker-Liste des Registers (siehe Flow 1, gefiltert)

### 5.2 Entry Point

1. Nutzer wählt Tab „Register"
2. Standardmäßig gleicher Zeitraum wie Tab „Musiker"

### 5.3 Interaktion

- **Sortierung:** Nach Ø Quote oder Register-Name
- **Filter:** Gleiche Termintyp-Chips wie Flow 1
- **Drill-Down:** Tap auf Register → öffnet Musiker-Liste gefiltert auf dieses Register

### 5.4 Wireframe — Phone

```
┌─────────────────────────────────┐
│ ← Statistiken             📤    │
├─────────────────────────────────┤
│ Musiker [Register] Trends       │ ← Tab-Bar
├─────────────────────────────────┤
│ Zeitraum: [01.01.–31.03. ▼]    │
│                                 │
│ Termintyp:                      │
│ [✓ Probe] [✓ Konzert] [Marsch] │
│                                 │
├─────────────────────────────────┤
│ Register        Ø Quote  (n)   │ ← Header
├─────────────────────────────────┤
│ Flöten/Klarinetten  89% 🟢  (7)│
│ Saxophone           71% 🟡  (5)│
│ Trompeten           58% 🔴  (6)│
│ Hörner              92% 🟢  (4)│
│ Posaunen            67% 🟡  (5)│
│ Tuba/Bass           81% 🟢  (3)│
│ Schlagwerk          74% 🟡  (4)│
│                                 │
├─────────────────────────────────┤
│ ℹ️ Basis: 14 Termine im Zeitraum│
└─────────────────────────────────┘
```

**Hinweise:**
- (n) = Anzahl Mitglieder im Register
- Farb-Badge auch hier mit Text-Label
- Tap auf Zeile → Drill-Down zu Musiker-Liste (gefiltert auf Register)

### 5.5 Drill-Down: Register → Musiker

```
┌─────────────────────────────────┐
│ ← Trompeten                      │ ← Breadcrumb zurück zu Register
├─────────────────────────────────┤
│ Musiker im Register: Trompeten  │
│ Zeitraum: 01.01.–31.03.         │
│                                 │
│ Name        Teil  Abs  Quote  │
├─────────────────────────────────┤
│ Müller, A.   12   2   86% 🟢  │
│ Schmidt, B.   9   5   64% 🟡  │
│ Weber, C.     6   8   43% 🔴  │
│ ...                            │
│                                 │
└─────────────────────────────────┘
```

### 5.6 Wireframe — Tablet/Desktop

```
┌──────────────────────────────────────────────────────────────┐
│ ← Kalender                                            📤      │
├──────────────────────────────────────────────────────────────┤
│ Statistiken: Anwesenheit                                     │
├──────────────────────────────────────────────────────────────┤
│ [Musiker]  [Register]  [Trends]          Zeitraum: [▼]      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Termintyp: [✓ Probe] [✓ Konzert] [Marschmusik]            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Register                  Ø Quote      Mitglieder       ││
│  ├────────────────────────────────────────────────────────┤ │
│  │ Flöten/Klarinetten          89% 🟢         7           ││
│  │ Saxophone                   71% 🟡         5           ││
│  │ Trompeten                   58% 🔴         6           ││
│  │ Hörner                      92% 🟢         4           ││
│  │ Posaunen                    67% 🟡         5           ││
│  │ Tuba/Bass                   81% 🟢         3           ││
│  │ Schlagwerk                  74% 🟡         4           ││
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ℹ️ Basis: 14 Termine im Zeitraum 01.01.–31.03.2026         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Desktop-Vorteile:**
- Hover auf Register → Tooltip mit Liste der Top-3-Fehlzeiten im Register
- Click auf Register → öffnet Split-View mit Musiker-Liste rechts

---

## 6. Flow 3: Trend-Ansicht

### 6.1 Konzept

Zeigt einen **Line-Chart** mit monatlicher Entwicklung der Anwesenheit.

**Varianten:**
- **Gesamt-Trend:** Durchschnittliche Quote aller Musiker pro Monat
- **Register-Trends:** Mehrere Linien, eine pro Register
- **Personen-Trends (Admin/Dirigent only):** Auswählbare Musiker

### 6.2 Entry Point

1. Nutzer wählt Tab „Trends"
2. Standardmäßig „Gesamt-Trend" der letzten 12 Monate

### 6.3 Interaktion

- **Zeitraum:** 3 / 6 / 12 Monate (Segmented Control)
- **Ansicht:** Gesamt / Register / Personen (Segmented Control, gestapelt)
- **Drill-Down:** Tap auf Datenpunkt → Tooltip mit Details (Monat, Quote, n Termine)

### 6.4 Wireframe — Phone

```
┌─────────────────────────────────┐
│ ← Statistiken             📤    │
├─────────────────────────────────┤
│ Musiker Register [Trends]       │ ← Tab-Bar
├─────────────────────────────────┤
│ Zeitraum: [3M] [6M] [12M]      │ ← Segmented Control
│ Ansicht:  [Gesamt] Register     │
│                                 │
├─────────────────────────────────┤
│                                 │
│   100% ┤                    ╱─  │
│        │                 ╱─     │
│    80% ┤             ╱─         │
│        │         ╱─             │
│    60% ┤     ╱─                 │
│        │ ╱─                     │
│    40% ┤                        │
│        └────────────────────    │
│        Jan Feb Mär Apr Mai Jun  │
│                                 │
│  ── Durchschnittliche Quote     │ ← Legende
│                                 │
├─────────────────────────────────┤
│ ℹ️ Trend: +8% in 6 Monaten       │ ← Insight
└─────────────────────────────────┘
```

**Hinweise:**
- Y-Achse: 0–100% (Quote)
- X-Achse: Monate
- Farbe: `color-primary` für Gesamt-Linie
- Datenpunkte sind tappable → Tooltip mit Details

### 6.5 Wireframe — Phone (Register-Ansicht)

```
┌─────────────────────────────────┐
│ ← Statistiken             📤    │
├─────────────────────────────────┤
│ Musiker Register [Trends]       │
├─────────────────────────────────┤
│ Zeitraum: [3M] [6M] [12M]      │
│ Ansicht:  Gesamt [Register]     │
│                                 │
├─────────────────────────────────┤
│                                 │
│   100% ┤    ────────────────    │ ← Hörner (🟢)
│        │        ─────────        │ ← Flöten (🔵)
│    80% ┤    ─────               │
│        │   ────                 │ ← Posaunen (🟡)
│    60% ┤  ────                  │
│        │ ────                   │ ← Trompeten (🔴)
│    40% ┤                        │
│        └────────────────────    │
│        Jan Feb Mär Apr Mai Jun  │
│                                 │
│  ── Hörner  ── Flöten           │ ← Legende
│  ── Posaunen ── Trompeten       │
│                                 │
├─────────────────────────────────┤
│ ℹ️ Stärkster Rückgang: Trompeten│
└─────────────────────────────────┘
```

**Hinweise:**
- Mehrere Linien in unterschiedlichen Farben (aus Design-System)
- Legende ist tappable → Toggle Sichtbarkeit der Linie
- Bei >5 Registern: nur Top-5 nach Quote anzeigen

### 6.6 Wireframe — Tablet/Desktop

```
┌──────────────────────────────────────────────────────────────┐
│ ← Kalender                                            📤      │
├──────────────────────────────────────────────────────────────┤
│ Statistiken: Anwesenheit                                     │
├──────────────────────────────────────────────────────────────┤
│ [Musiker]  [Register]  [Trends]          Zeitraum: [▼]      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Ansicht: [Gesamt] [Register] [Personen]                    │
│  Zeitraum: [3 Monate] [6 Monate] [12 Monate]               │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                                                        │ │
│  │   100% ┤                                     ╱────     │ │
│  │        │                                 ╱───          │ │
│  │    80% ┤                             ╱───              │ │
│  │        │                         ╱───                  │ │
│  │    60% ┤                     ╱───                      │ │
│  │        │                 ╱───                          │ │
│  │    40% ┤             ╱───                              │ │
│  │        │         ╱───                                  │ │
│  │    20% ┤     ╱───                                      │ │
│  │        └───────────────────────────────────────────    │ │
│  │        Jan Feb Mär Apr Mai Jun Jul Aug Sep Okt Nov Dez│ │
│  │                                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ── Durchschnittliche Quote                                 │
│                                                              │
│  ℹ️ Trend: +8% in 12 Monaten (von 68% auf 76%)              │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Desktop-Vorteile:**
- Größerer Chart → mehr Details sichtbar
- Hover auf Datenpunkt → Tooltip mit genauer Quote und n Termine
- Export-Button öffnet Modal mit Chart als PNG

---

## 7. Flow 4: Export (CSV/PDF)

### 7.1 Konzept

Export ist ein **asynchroner Job**:
1. Nutzer wählt Format (CSV/PDF) und Tab (Musiker/Register/Trends)
2. Backend generiert Datei
3. Download-Link wird nach Fertigstellung angezeigt (Push-Notification optional)
4. Link ist 24h gültig

### 7.2 Entry Point

1. Nutzer tappt auf Export-Icon (📤) in Header
2. Modal öffnet sich mit Optionen

### 7.3 Interaktion

- **Format-Auswahl:** CSV / PDF (Radio-Buttons)
- **Inhalt-Auswahl:** Aktueller Tab (Musiker/Register/Trends) vorausgewählt
- **Zeitraum:** Übernommen aus aktuellem Filter
- **Bestätigung:** „Export starten"

### 7.4 Wireframe — Phone (Export-Modal)

```
┌─────────────────────────────────┐
│ Export Anwesenheit         ✕   │ ← Modal-Header
├─────────────────────────────────┤
│                                 │
│ Daten exportieren:              │
│                                 │
│ ○ Musiker-Liste                 │ ← Radio-Button
│ ● Register-Übersicht            │ ← Ausgewählt (aktueller Tab)
│ ○ Trend-Chart                   │
│                                 │
│ Format:                         │
│ ● CSV (Excel-kompatibel)        │ ← Radio-Button, vorausgewählt
│ ○ PDF (Druckbar)                │
│                                 │
│ Zeitraum: 01.01.–31.03.2026     │ ← Info, nicht änderbar hier
│                                 │
├─────────────────────────────────┤
│ ┌───────────────────────────┐   │
│ │   Export starten          │   │ ← Primär-Button
│ └───────────────────────────┘   │
│                                 │
│ [Abbrechen]                     │ ← Sekundär-Button (Text)
│                                 │
└─────────────────────────────────┘
```

### 7.5 Wireframe — Export-Progress

```
┌─────────────────────────────────┐
│ Export wird erstellt...         │
├─────────────────────────────────┤
│                                 │
│         ⏳                      │
│                                 │
│  Deine Datei wird generiert.    │
│  Du erhältst eine Benachrichtigung│
│  wenn der Download bereit ist.  │
│                                 │
│  [Im Hintergrund fortfahren]    │ ← Schließt Modal, Export läuft
│                                 │
└─────────────────────────────────┘
```

### 7.6 Wireframe — Export-Fertig (Toast/Notification)

```
┌─────────────────────────────────┐
│ ✓ Export bereit                 │
│                                 │
│ Anwesenheit_Register_2026-03.csv│
│                                 │
│ [Herunterladen]  [Verwerfen]    │
└─────────────────────────────────┘
```

**Hinweise:**
- Toast erscheint oben (Phone) oder unten rechts (Desktop)
- Nach Download: Toast verschwindet automatisch nach 5s
- Link ist 24h gültig, danach zeigt Download „Abgelaufen"

### 7.7 Export-Fehlerfälle

**Timeout/Fehler:**
```
┌─────────────────────────────────┐
│ ⚠️ Export fehlgeschlagen         │
│                                 │
│ Die Datei konnte nicht erstellt │
│ werden. Versuche es mit CSV.    │
│                                 │
│ [CSV exportieren] [Abbrechen]   │
└─────────────────────────────────┘
```

---

## 8. Interaction Patterns

### 8.1 Zeitraum-Filter

- **Standard:** Letzte 3 Monate
- **Picker:** Von/Bis Date-Picker (Material Design Date Range Picker)
- **Presets:** 3M / 6M / 12M / Ganzes Jahr / Benutzerdefiniert
- **Persistenz:** Pro Kapelle gespeichert (Nutzer-Ebene)

### 8.2 Termintyp-Filter

- **Multi-Select-Chips:** Probe / Konzert / Marschmusik
- **Standard:** Alle ausgewählt
- **Persistenz:** Pro Session (nicht gespeichert)
- **Visuelle Rückmeldung:** Ausgewählte Chips haben `color-primary` Hintergrund

### 8.3 Sortierung

- **Phone:** Explizite Sortierungs-Auswahl via Bottom-Sheet
  - Quote aufsteigend
  - Quote absteigend
  - Name A–Z
  - Name Z–A
- **Tablet/Desktop:** Klick auf Tabellen-Header → Toggle asc/desc

### 8.4 Drill-Down

- **Register → Musiker:** Tap auf Register-Zeile → öffnet Musiker-Liste (gefiltert auf Register)
- **Zurück-Navigation:** „← Zurück zu Register-Übersicht" (Breadcrumb)

### 8.5 Auto-Refresh

- **Zeitpunkt:** Nach Änderung an Termin-Teilnahme
- **Mechanismus:** Polling alle 30s oder Push-Notification
- **Feedback:** Subtile Animation (Fade) bei Daten-Update

---

## 9. Error States & Leerzustände

### 9.1 Keine Termine im Zeitraum

```
┌─────────────────────────────────┐
│ 📊 Keine Daten                  │
│                                 │
│ Im gewählten Zeitraum gibt es   │
│ keine Termine.                  │
│                                 │
│ [Zeitraum ändern]               │
└─────────────────────────────────┘
```

### 9.2 Zu wenig Termine (<5)

```
┌─────────────────────────────────┐
│ ⚠️ Wenige Daten                  │
│                                 │
│ Nur 3 Termine im Zeitraum.      │
│ Statistik ist wenig aussagekräftig.│
│                                 │
│ [Zeitraum erweitern]            │
└─────────────────────────────────┘
```

### 9.3 Keine Rückmeldungen

```
┌─────────────────────────────────┐
│ Name        Teil  Abs  Quote  │
├─────────────────────────────────┤
│ Müller, A.   0    0    —      │ ← Quote = null (keine Rückmeldung)
│ Schmidt, B.  12   2   86% 🟢  │
│ ...                            │
└─────────────────────────────────┘
```

**Hinweis:** Quote wird als „—" dargestellt, wenn keine Rückmeldung vorliegt.

### 9.4 Export fehlgeschlagen

```
┌─────────────────────────────────┐
│ ⚠️ Export fehlgeschlagen         │
│                                 │
│ PDF konnte nicht erstellt werden.│
│ Versuche es mit CSV.            │
│                                 │
│ [CSV exportieren] [Abbrechen]   │
└─────────────────────────────────┘
```

### 9.5 Ungültiger Zeitraum

```
┌─────────────────────────────────┐
│ ⚠️ Ungültiger Zeitraum           │
│                                 │
│ „Von" muss vor „Bis" liegen.    │
│                                 │
│ [OK]                            │
└─────────────────────────────────┘
```

---

## 10. Accessibility

### 10.1 Screen Reader

- **Tabellen:** `<table role="table">` mit `<th scope="col">`
- **Chart:** Alt-Text mit Trend-Zusammenfassung (z.B. „Anwesenheit stieg von 68% auf 76% in 12 Monaten")
- **Farb-Badges:** Immer mit Text-Label (nicht nur Farbe)
  - Grün: „86% (Gut)"
  - Gelb: „64% (Mittel)"
  - Rot: „43% (Niedrig)"

### 10.2 Keyboard-Navigation

- **Tab-Order:** Header → Filter → Tabelle → Export-Button
- **Enter/Space:** Aktiviert Sortierung, öffnet Drill-Down
- **Arrow-Keys:** Navigation in Tabelle (Zeile für Zeile)

### 10.3 Kontrast

- **Farb-Badges:** Alle Farben erfüllen WCAG AA (mindestens 4.5:1 Kontrast)
- **Chart-Linien:** Mindestens 3:1 Kontrast zum Hintergrund

### 10.4 Touch-Targets

- **Minimum:** 44×44px für alle interaktiven Elemente
- **Tabellen-Zeilen:** 48px Höhe (mehr als Minimum für bessere Tappability)

---

## 11. Responsive Breakpoints

### 11.1 Phone (<600px)

- **Layout:** Single-Column
- **Tabelle:** Horizontal scrollbar bei >4 Spalten
- **Chart:** Volle Breite, 250px Höhe
- **Export-Modal:** Fullscreen (Bottom-Sheet-Style)

### 11.2 Tablet (600–1024px)

- **Layout:** Two-Column (Split-View möglich)
- **Tabelle:** Volle Breite, mehr Spalten sichtbar
- **Chart:** 400px Höhe
- **Export-Modal:** Zentriert, 480px Breite

### 11.3 Desktop (>1024px)

- **Layout:** Three-Column (Sidebar + Content + Detail-Panel optional)
- **Tabelle:** Volle Breite, alle Spalten sichtbar
- **Chart:** 500px Höhe
- **Export-Modal:** Zentriert, 600px Breite
- **Hover-States:** Tooltip auf Quote-Badge, Datenpunkten, Tabellen-Zeilen

---

## 12. Abhängigkeiten

### 12.1 Backend-APIs

- `GET /api/v1/kapellen/{kapelleId}/statistiken/musiker`
- `GET /api/v1/kapellen/{kapelleId}/statistiken/register`
- `GET /api/v1/kapellen/{kapelleId}/statistiken/trends`
- `POST /api/v1/kapellen/{kapelleId}/statistiken/export`
- `GET /api/v1/kapellen/{kapelleId}/statistiken/export/{jobId}/status`
- `GET /api/v1/kapellen/{kapelleId}/statistiken/export/{jobId}/download`

### 12.2 Frontend-Komponenten

- **Chart-Library:** `fl_chart` oder Syncfusion (Flutter)
- **Date-Range-Picker:** Material Design Date Range Picker
- **Tabelle:** Custom Flutter `DataTable` mit Sortierung
- **Export-Job-Tracker:** Background-Service mit Push-Notification

### 12.3 Bestehende UX-Specs

- `docs/ux-design.md` — Design-Tokens, Farben, Typografie
- `docs/ux-konfiguration.md` — 3-Ebenen-Modell (falls Export-Optionen konfigurierbar)

### 12.4 Feature-Specs

- `docs/feature-specs/anwesenheit-spec.md` — Datenmodell, API-Kontrakte

---

**Ende der UX-Spec: Anwesenheits-Statistiken**
