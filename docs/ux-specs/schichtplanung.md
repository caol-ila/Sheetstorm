# UX-Spec: Schichtplanung — Sheetstorm

> **Version:** 1.0  
> **Status:** Entwurf — Review durch Hill (Frontend) und Banner (Backend) ausstehend  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-04-15  
> **Meilenstein:** M2 — Vereinsleben & Aufführung  
> **Issue:** TBD  
> **Referenzen:** `docs/feature-specs/schichtplanung-spec.md`, `docs/ux-design.md`

---

## Inhaltsverzeichnis

1. [Überblick & Konzept](#1-überblick--konzept)
2. [Design-Tokens (Referenz)](#2-design-tokens-referenz)
3. [Navigations-Integration](#3-navigations-integration)
4. [Flow 1: Schichtplan erstellen (Admin)](#4-flow-1-schichtplan-erstellen-admin)
5. [Flow 2: Schichten definieren (Admin)](#5-flow-2-schichten-definieren-admin)
6. [Flow 3: Selbsteintragung (Musiker)](#6-flow-3-selbsteintragung-musiker)
7. [Flow 4: Admin-Zuweisung](#7-flow-4-admin-zuweisung)
8. [Flow 5: Übersicht & "Meine Schichten"](#8-flow-5-übersicht--meine-schichten)
9. [Interaction Patterns](#9-interaction-patterns)
10. [Error States & Leerzustände](#10-error-states--leerzustände)
11. [Accessibility](#11-accessibility)
12. [Responsive Breakpoints](#12-responsive-breakpoints)
13. [Abhängigkeiten](#13-abhängigkeiten)

---

## 1. Überblick & Konzept

### 1.1 Ziel

Vereine brauchen eine **einfache Möglichkeit, Schichten für Veranstaltungen zu planen**. Mitglieder sollen sich selbstständig eintragen können (First-Come-First-Served), während Admins/Dirigenten auch direkt zuweisen können.

**Kernproblem:**
- Wer hilft beim Bühnenaufbau?
- Wer übernimmt den Getränkeverkauf beim Konzert?
- Wie vermeide ich Doppel-Buchungen oder vergessene Schichten?

**MS2-Scope (Basic-Version):**
- Schichtpläne für Veranstaltungen (z.B. Konzerte, Festivals)
- Schichten mit Start/Ende/Kapazität
- Selbsteintragung + Admin-Zuweisung
- Übersicht: „Meine Schichten" + „Offene Schichten"

**Nicht in MS2:**
- Automatische Konflikt-Erkennung mit Proben/Konzerten (nur Warnung)
- Schicht-Templates oder wiederkehrende Schichten
- Export/Druck von Schichtplänen

### 1.2 Nutzungskontext

**Szenarien:**
1. **Fest-Vorbereitung:** Vorstand erstellt Schichtplan 4 Wochen vorher, Mitglieder tragen sich ein
2. **Spontane Veranstaltung:** Admin erstellt Plan 1 Woche vorher, weist einige Mitglieder direkt zu
3. **Mitglied sucht Aufgaben:** Musiker öffnet „Meine Schichten", sieht offene Schichten, trägt sich ein
4. **Übersicht vor Event:** Admin prüft am Tag vorher, ob alle Schichten besetzt sind

### 1.3 Zugriffsberechtigung (RBAC)

| Rolle        | Pläne erstellen | Schichten definieren | Selbsteintragung | Admin-Zuweisung | Löschen |
|--------------|-----------------|----------------------|------------------|-----------------|---------|
| **Musiker**  | —               | —                    | ✓                | —               | Nur eigene |
| **Dirigent** | ✓               | ✓                    | ✓                | ✓               | ✓       |
| **Admin**    | ✓               | ✓                    | ✓                | ✓               | ✓       |

### 1.4 Grundprinzipien

- **Self-Service First:** Mitglieder sollen sich selbst eintragen (weniger Admin-Aufwand)
- **Transparenz:** Jeder sieht, welche Schichten noch offen sind
- **Einfachheit:** Keine komplexen Regeln, keine Prioritäten, keine Wartelisten (First-Come-First-Served)
- **Kontext-Sensitivität:** Schichtpläne sind oft mit Terminen verknüpft (optional)
- **Push-Benachrichtigungen:** Neue Pläne/Schichten/Zuweisungen → Notification

---

## 2. Design-Tokens (Referenz)

Alle hier verwendeten Token stammen aus `docs/ux-design.md` § 7.

| Token                     | Wert       | Verwendung in Schichtplanung                 |
|---------------------------|------------|----------------------------------------------|
| `color-primary`           | `#1A56DB`  | Buttons, aktive Schichten                    |
| `color-success`           | `#16A34A`  | Voll besetzte Schichten (grün)               |
| `color-warning`           | `#D97706`  | Teilweise besetzte Schichten (gelb/orange)   |
| `color-error`             | `#DC2626`  | Leere Schichten (rot), Konflikt-Warnung      |
| `color-text-secondary`    | `#6B7280`  | Sekundär-Text, Zeitangaben                   |
| `color-border`            | `#E5E7EB`  | Karten-Rahmen, Schicht-Boxen                 |
| `color-background`        | `#FFFFFF`  | Screen-Hintergrund                           |
| `font-size-base`          | `16sp`     | Schicht-Namen, Texte                         |
| `font-size-lg`            | `20sp`     | Plan-Titel, Überschriften                    |
| `font-size-sm`            | `14sp`     | Sekundär-Text, Zeitangaben                   |
| `space-md`                | `16px`     | Padding zwischen Karten                      |
| `space-lg`                | `24px`     | Padding zwischen Abschnitten                 |
| `border-radius-md`        | `8px`      | Karten, Buttons, Schicht-Boxen               |
| `touch-target-min`        | `44×44px`  | Alle interaktiven Elemente                   |

---

## 3. Navigations-Integration

### 3.1 Entry Points

**Primär:**
- **Kalender-Tab** → „Schichten" (neben Statistiken, Icon: 📅)
- **Profil-Tab** → „Meine Schichten"

**Sekundär:**
- **Termin-Detail-Ansicht** → „Schichtplan erstellen" (Button, nur für Admin/Dirigent)

### 3.2 Deep Link

```
sheetstorm://kapelle/{kapelleId}/schichten
sheetstorm://kapelle/{kapelleId}/schichten/{planId}
sheetstorm://kapelle/{kapelleId}/schichten/meine
```

### 3.3 Navigation-Hierarchie

```
Kalender (Haupttab)
  └── Schichten (Seite)
        ├── Alle Pläne (Liste)
        ├── Plan-Detail (mit Schichten)
        └── Meine Schichten (Übersicht)
```

---

## 4. Flow 1: Schichtplan erstellen (Admin)

### 4.1 Entry Point

1. Admin/Dirigent öffnet Kalender-Tab → „Schichten"
2. Tappt auf „+ Neuer Schichtplan"
3. Modal/Bottom-Sheet öffnet sich

### 4.2 Interaktion

1. Felder ausfüllen:
   - Name (Pflichtfeld, z.B. „Sommerfest 2026")
   - Datum (Pflichtfeld, Date-Picker)
   - Beschreibung (Optional, Textarea)
   - Mit Termin verknüpfen (Optional, Dropdown — falls Termin am selben Datum existiert)
2. „Erstellen" → Backend erstellt Plan
3. Weiterleitung zu Plan-Detail → Schichten definieren (Flow 2)

### 4.3 Wireframe — Phone (Erstellung)

```
┌─────────────────────────────────┐
│ Neuer Schichtplan          ✕   │ ← Modal-Header
├─────────────────────────────────┤
│                                 │
│ Name *                          │
│ ┌───────────────────────────┐   │
│ │ Sommerfest 2026           │   │ ← Text-Input, Pflicht
│ └───────────────────────────┘   │
│                                 │
│ Datum *                         │
│ ┌───────────────────────────┐   │
│ │ 15.06.2026            📅 │   │ ← Date-Picker
│ └───────────────────────────┘   │
│                                 │
│ Beschreibung (optional)         │
│ ┌───────────────────────────┐   │
│ │ Aufbau, Getränke, Abbau   │   │ ← Textarea
│ └───────────────────────────┘   │
│                                 │
│ Mit Termin verknüpfen (optional)│
│ ┌───────────────────────────┐   │
│ │ Konzert 15.06.        ▼  │   │ ← Dropdown, optional
│ └───────────────────────────┘   │
│                                 │
│ ℹ️ Wenn verknüpft, wird das Datum│
│   vom Termin übernommen.        │
│                                 │
├─────────────────────────────────┤
│ ┌───────────────────────────┐   │
│ │   Erstellen               │   │ ← Primär-Button, 48px
│ └───────────────────────────┘   │
│                                 │
│ [Abbrechen]                     │ ← Sekundär-Button (Text)
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- Wenn mit Termin verknüpft: Datum wird automatisch vom Termin übernommen (nicht editierbar)
- Wenn nicht verknüpft: Datum manuell eingeben
- Name ist Pflichtfeld, max 100 Zeichen

### 4.4 Wireframe — Tablet/Desktop

```
┌──────────────────────────────────────────────────────────────┐
│ ← Schichten                                                  │
├──────────────────────────────────────────────────────────────┤
│ Neuer Schichtplan                                            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Name *                            Datum *                   │
│  ┌─────────────────────────────┐  ┌────────────────────┐    │
│  │ Sommerfest 2026             │  │ 15.06.2026     📅 │    │
│  └─────────────────────────────┘  └────────────────────┘    │
│                                                              │
│  Beschreibung (optional)                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Aufbau ab 08:00, Getränkeverkauf, Abbau ab 22:00     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  Mit Termin verknüpfen (optional)                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Konzert 15.06.2026                               ▼  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ℹ️ Wenn verknüpft, wird das Datum vom Termin übernommen.    │
│                                                              │
│  [Abbrechen]  [Erstellen]                                    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 5. Flow 2: Schichten definieren (Admin)

### 5.1 Entry Point

1. Nach Erstellung (Flow 1) → automatisch zu Plan-Detail
2. Oder: Plan aus Liste öffnen → Tab „Schichten"

### 5.2 Interaktion

1. Admin sieht Plan-Detail mit leerer Schichten-Liste
2. Tappt auf „+ Schicht hinzufügen"
3. Modal öffnet sich:
   - Name (z.B. „Bühnenaufbau")
   - Start (Time-Picker, z.B. 08:00)
   - Ende (Time-Picker, z.B. 11:00)
   - Anzahl Personen (Stepper, z.B. 5)
   - Beschreibung (Optional)
4. „Hinzufügen" → Schicht wird erstellt
5. Wiederholen für weitere Schichten

### 5.3 Wireframe — Phone (Schicht hinzufügen)

```
┌─────────────────────────────────┐
│ Schicht hinzufügen         ✕   │ ← Modal-Header
├─────────────────────────────────┤
│                                 │
│ Name *                          │
│ ┌───────────────────────────┐   │
│ │ Bühnenaufbau              │   │ ← Text-Input, Pflicht
│ └───────────────────────────┘   │
│                                 │
│ Von *                  Bis *    │
│ ┌──────────┐  ┌──────────┐     │
│ │ 08:00 🕐│  │ 11:00 🕐│     │ ← Time-Picker
│ └──────────┘  └──────────┘     │
│                                 │
│ Anzahl Personen *               │
│ ┌───────────────────────────┐   │
│ │  −     5     +            │   │ ← Stepper
│ └───────────────────────────┘   │
│                                 │
│ Beschreibung (optional)         │
│ ┌───────────────────────────┐   │
│ │ Instrumente transportieren│   │ ← Textarea
│ └───────────────────────────┘   │
│                                 │
├─────────────────────────────────┤
│ ┌───────────────────────────┐   │
│ │   Hinzufügen              │   │ ← Primär-Button, 48px
│ └───────────────────────────┘   │
│                                 │
│ [Abbrechen]                     │
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- Von/Bis: Zeit-Picker (Material Design Time Picker)
- Anzahl Personen: Stepper, Min = 1, Max = 50 (sinnvoll für Vereine)
- Überlappungen sind erlaubt (z.B. Aufbau 08-11, Getränke 10-14)

### 5.4 Wireframe — Phone (Plan-Detail mit Schichten)

```
┌─────────────────────────────────┐
│ ← Sommerfest 2026          ⋯   │ ← 3-Dot-Menü: Plan bearbeiten/löschen
├─────────────────────────────────┤
│ 15.06.2026                      │
│ Aufbau, Getränke, Abbau         │ ← Beschreibung
│                                 │
├─────────────────────────────────┤
│                                 │
│ Schichten (3)                   │ ← Sektion-Header
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🔨 Bühnenaufbau           │   │ ← Schicht-Karte
│ │ 08:00 – 11:00             │   │
│ │                           │   │
│ │ ●●●○○  3/5                │   │ ← Fortschritts-Dots + Zahl
│ │ Müller, Schmidt, Weber    │   │ ← Namen der Zugewiesenen
│ │                           │   │
│ │ [Ich bin dabei]           │   │ ← Self-Signup-Button
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🍻 Getränkeverkauf        │   │
│ │ 10:00 – 22:00             │   │
│ │                           │   │
│ │ ●●○○  2/4                 │   │
│ │ Fischer, Bauer            │   │
│ │                           │   │
│ │ [Ich bin dabei]           │   │
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🧹 Abbau                   │   │
│ │ 22:00 – 24:00             │   │
│ │                           │   │
│ │ ○○○○○○  0/6               │   │ ← Leer, rot markiert
│ │                           │   │
│ │ [Ich bin dabei]           │   │
│ └───────────────────────────┘   │
│                                 │
├─────────────────────────────────┤
│ ┌───────────────────────────┐   │
│ │   + Schicht hinzufügen    │   │ ← FAB (nur für Admin)
│ └───────────────────────────┘   │
└─────────────────────────────────┘
```

**Hinweise:**
- Fortschritts-Dots: ● = besetzt, ○ = offen
- Farb-Kodierung:
  - Grün (`color-success`): Voll besetzt (5/5)
  - Gelb (`color-warning`): Teilweise besetzt (2–4/5)
  - Rot (`color-error`): Leer (0/5)
- Namen der Zugewiesenen: Nur Nachname, max 3 Namen anzeigen, Rest „+2 weitere"
- „Ich bin dabei"-Button: Nur sichtbar, wenn Kapazität nicht voll

### 5.5 Wireframe — Tablet/Desktop

```
┌──────────────────────────────────────────────────────────────┐
│ ← Schichten                                              ⋯   │
├──────────────────────────────────────────────────────────────┤
│ Sommerfest 2026 · 15.06.2026                                 │
│ Aufbau, Getränke, Abbau                                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Schichten (3)                                               │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 🔨 Bühnenaufbau                 08:00 – 11:00          │  │
│  │                                                        │  │
│  │ ●●●○○  3/5 Personen                                    │  │
│  │ Müller, Schmidt, Weber                                 │  │
│  │                                                        │  │
│  │ [Ich bin dabei]  [Person zuweisen]  [Bearbeiten]      │  │ ← Admin-Aktionen
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 🍻 Getränkeverkauf              10:00 – 22:00          │  │
│  │                                                        │  │
│  │ ●●○○  2/4 Personen                                     │  │
│  │ Fischer, Bauer                                         │  │
│  │                                                        │  │
│  │ [Ich bin dabei]  [Person zuweisen]  [Bearbeiten]      │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 🧹 Abbau                        22:00 – 24:00          │  │
│  │                                                        │  │
│  │ ○○○○○○  0/6 Personen                                   │  │
│  │ —                                                      │  │
│  │                                                        │  │
│  │ [Ich bin dabei]  [Person zuweisen]  [Bearbeiten]      │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  [+ Schicht hinzufügen]                                      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Desktop-Vorteile:**
- Inline-Aktionen (keine Bottom-Sheet nötig)
- Hover auf Schicht-Karte → zeigt Beschreibung im Tooltip
- Mehr Platz für Namen (alle Namen sichtbar, nicht nur 3)

---

## 6. Flow 3: Selbsteintragung (Musiker)

### 6.1 Entry Point

**Variante A: Aus Plan-Detail**
1. Musiker öffnet Plan-Detail (Flow 5.3)
2. Sieht offene Schichten
3. Tappt auf „Ich bin dabei"

**Variante B: Aus „Meine Schichten"**
1. Musiker öffnet „Meine Schichten" (Flow 5)
2. Wählt „Verfügbare Schichten" (Tab)
3. Tappt auf Schicht → „Ich bin dabei"

### 6.2 Interaktion

1. Musiker tappt auf „Ich bin dabei"
2. **Validation:**
   - Kapazität prüfen (noch Platz?)
   - Doppel-Eintragung prüfen (schon eingetragen?)
   - Zeitkonflikt prüfen (andere Schicht zur gleichen Zeit?) → nur Warnung, nicht blockierend
3. **Success:** Eintragung erfolgt sofort → Button wird „Du bist dabei ✓" (grün)
4. **Error:** Fehlermeldung (z.B. „Schicht ist voll")

### 6.3 Wireframe — Phone (Vor Eintragung)

```
┌─────────────────────────────────┐
│ ← Sommerfest 2026               │
├─────────────────────────────────┤
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🔨 Bühnenaufbau           │   │
│ │ 08:00 – 11:00             │   │
│ │                           │   │
│ │ ●●●○○  3/5                │   │
│ │ Müller, Schmidt, Weber    │   │
│ │                           │   │
│ │ [Ich bin dabei]           │   │ ← Primär-Button
│ └───────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

### 6.4 Wireframe — Phone (Nach Eintragung)

```
┌─────────────────────────────────┐
│ ← Sommerfest 2026               │
├─────────────────────────────────┤
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🔨 Bühnenaufbau           │   │
│ │ 08:00 – 11:00             │   │
│ │                           │   │
│ │ ●●●●○  4/5                │   │ ← Ein Dot mehr
│ │ Müller, Schmidt, Weber,   │   │
│ │ Du                        │   │ ← „Du" als Badge
│ │                           │   │
│ │ [✓ Du bist dabei]         │   │ ← Success-State, grün
│ └───────────────────────────┘   │
│                                 │
└─────────────────────────────────┘

  ┌───────────────────────────┐
  │ ✓ Eintragung erfolgreich   │ ← Toast (5s Anzeige)
  └───────────────────────────┘
```

**Hinweise:**
- „Du" wird als Badge/Chip angezeigt (fett, `color-primary`)
- Toast erscheint kurz, verschwindet automatisch
- Button wird zu „✓ Du bist dabei" (grün, `color-success`)

### 6.5 Wireframe — Phone (Austragung)

```
┌─────────────────────────────────┐
│ ← Sommerfest 2026               │
├─────────────────────────────────┤
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🔨 Bühnenaufbau           │   │
│ │ 08:00 – 11:00             │   │
│ │                           │   │
│ │ ●●●●○  4/5                │   │
│ │ Müller, Schmidt, Weber, Du│   │
│ │                           │   │
│ │ [✓ Du bist dabei]      ✕ │   │ ← Austragung-Button (X)
│ └───────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- Nutzer kann sich selbst austragen via „✕"-Button
- Confirmation-Dialog: „Möchtest du dich aus der Schicht austragen?"
- Nach Austragung: Button wird wieder „Ich bin dabei"

### 6.6 Wireframe — Zeitkonflikt-Warnung

```
┌─────────────────────────────────┐
│ ⚠️ Zeitkonflikt                  │ ← Dialog
├─────────────────────────────────┤
│                                 │
│ Du bist bereits für die Schicht │
│ „Getränkeverkauf" (10:00–22:00) │
│ eingetragen.                    │
│                                 │
│ Diese Schicht überschneidet sich│
│ teilweise. Trotzdem eintragen?  │
│                                 │
├─────────────────────────────────┤
│ [Abbrechen] [Trotzdem eintragen]│
└─────────────────────────────────┘
```

**Hinweise:**
- Konflikte werden nur als Warnung angezeigt, nicht blockiert
- Nutzer kann Entscheidung selbst treffen (z.B. kurze Überschneidung akzeptabel)

---

## 7. Flow 4: Admin-Zuweisung

### 7.1 Entry Point

1. Admin öffnet Plan-Detail
2. Tappt auf „Person zuweisen" (neben „Ich bin dabei")
3. Modal öffnet sich mit Mitglieder-Liste

### 7.2 Interaktion

1. Admin sieht Liste aller Kapellen-Mitglieder
2. Such-Feld: Filter nach Name
3. Tap auf Person → Zuweisung erfolgt
4. **Validation:**
   - Kapazität prüfen
   - Zeitkonflikt prüfen → Warnung, aber nicht blockierend
5. **Success:** Person wird zugewiesen, Modal schließt

### 7.3 Wireframe — Phone (Person zuweisen)

```
┌─────────────────────────────────┐
│ Person zuweisen            ✕   │ ← Modal-Header
├─────────────────────────────────┤
│                                 │
│ Schicht: Bühnenaufbau           │ ← Kontext-Info
│ 08:00 – 11:00 · 3/5 besetzt     │
│                                 │
├─────────────────────────────────┤
│ 🔍 Suchen...                    │ ← Such-Feld
├─────────────────────────────────┤
│                                 │
│ Verfügbar (12)                  │ ← Sektion: Nicht zugewiesen
│                                 │
│ ○ Bauer, Eva                    │ ← Tap → Zuweisung
│ ○ Fischer, Daniel               │
│ ○ Hoffmann, Lisa                │
│ ○ Klein, Markus                 │
│ ...                             │
│                                 │
│ Bereits zugewiesen (3)          │ ← Sektion: Schon dabei
│                                 │
│ ● Müller, Anna                  │ ← Nicht auswählbar (grau)
│ ● Schmidt, Bernd                │
│ ● Weber, Clara                  │
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- Liste ist alphabetisch sortiert
- Such-Feld filtert in Echtzeit
- Bereits zugewiesene Mitglieder sind grau und nicht auswählbar
- Tap auf Person → sofortige Zuweisung (kein extra „Bestätigen"-Button)

### 7.4 Wireframe — Phone (Zuweisung erfolgreich)

```
┌─────────────────────────────────┐
│ ← Sommerfest 2026               │
├─────────────────────────────────┤
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🔨 Bühnenaufbau           │   │
│ │ 08:00 – 11:00             │   │
│ │                           │   │
│ │ ●●●●○  4/5                │   │ ← Ein Dot mehr
│ │ Müller, Schmidt, Weber,   │   │
│ │ Bauer                     │   │ ← Neu zugewiesen
│ │                           │   │
│ │ [Ich bin dabei]           │   │
│ └───────────────────────────┘   │
│                                 │
└─────────────────────────────────┘

  ┌───────────────────────────┐
  │ ✓ Bauer zugewiesen         │ ← Toast (5s Anzeige)
  └───────────────────────────┘
```

### 7.5 Wireframe — Tablet/Desktop (Inline-Zuweisung)

```
┌──────────────────────────────────────────────────────────────┐
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 🔨 Bühnenaufbau                 08:00 – 11:00          │  │
│  │                                                        │  │
│  │ ●●●●○  4/5 Personen                                    │  │
│  │ Müller, Schmidt, Weber, Bauer                          │  │
│  │                                                        │  │
│  │ [Person zuweisen ▼]  [Bearbeiten]                     │  │ ← Dropdown statt Modal
│  │                                                        │  │
│  │ ┌──────────────────────────┐                          │  │
│  │ │ 🔍 Suchen...             │                          │  │
│  │ ├──────────────────────────┤                          │  │
│  │ │ ○ Fischer, Daniel        │ ← Dropdown-Liste         │  │
│  │ │ ○ Hoffmann, Lisa         │                          │  │
│  │ │ ○ Klein, Markus          │                          │  │
│  │ └──────────────────────────┘                          │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

**Desktop-Vorteile:**
- Inline-Dropdown statt Modal (schneller Workflow)
- Autocomplete-Suche im Dropdown
- Hover auf Namen → zeigt Instrument/Register

---

## 8. Flow 5: Übersicht & "Meine Schichten"

### 8.1 Entry Point

**Primär:**
- **Profil-Tab** → „Meine Schichten"
- **Kalender-Tab** → „Schichten" → Tab „Meine Schichten"

### 8.2 Interaktion

1. Nutzer öffnet „Meine Schichten"
2. Sieht zwei Tabs:
   - **Meine Schichten:** Schichten, für die ich zugewiesen bin
   - **Verfügbar:** Offene Schichten (mit Kapazität)
3. Kann direkt aus Liste eintragen/austragen

### 8.3 Wireframe — Phone (Meine Schichten)

```
┌─────────────────────────────────┐
│ ← Meine Schichten               │
├─────────────────────────────────┤
│ [Meine Schichten] Verfügbar     │ ← Tab-Bar
├─────────────────────────────────┤
│                                 │
│ Demnächst (2)                   │ ← Sektion: Nächste 7 Tage
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🔨 Bühnenaufbau           │   │
│ │ Sommerfest 2026           │   │ ← Plan-Name
│ │ 15.06., 08:00 – 11:00     │   │
│ │                           │   │
│ │ [✓ Du bist dabei]      ✕ │   │ ← Austragung möglich
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🍻 Getränkeverkauf        │   │
│ │ Sommerfest 2026           │   │
│ │ 15.06., 10:00 – 22:00     │   │
│ │                           │   │
│ │ [✓ Du bist dabei]      ✕ │   │
│ └───────────────────────────┘   │
│                                 │
│ Später (0)                      │ ← Sektion: >7 Tage
│                                 │
│ [Keine Schichten]               │
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- Sortierung: Chronologisch (nächste zuerst)
- Sektionen: „Demnächst" (< 7 Tage), „Später" (> 7 Tage)
- Austragung: ✕-Button öffnet Confirmation-Dialog

### 8.4 Wireframe — Phone (Verfügbare Schichten)

```
┌─────────────────────────────────┐
│ ← Meine Schichten               │
├─────────────────────────────────┤
│ Meine Schichten [Verfügbar]     │ ← Tab-Bar
├─────────────────────────────────┤
│                                 │
│ Offen (5)                       │ ← Sektion: Nicht voll besetzt
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🧹 Abbau                   │   │
│ │ Sommerfest 2026           │   │
│ │ 15.06., 22:00 – 24:00     │   │
│ │                           │   │
│ │ ○○○○○○  0/6               │   │ ← Leer, dringend
│ │ [Ich bin dabei]           │   │
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │ 🎤 Moderation             │   │
│ │ Herbstkonzert 2026        │   │
│ │ 20.09., 18:00 – 21:00     │   │
│ │                           │   │
│ │ ●○○  1/3                  │   │
│ │ [Ich bin dabei]           │   │
│ └───────────────────────────┘   │
│                                 │
│ ...                             │
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- Sortierung: Dringlichkeit (leere Schichten zuerst), dann Datum
- Filter: Nur Schichten mit < 100% Besetzung
- Tap auf Schicht → Plan-Detail öffnen (optional) oder direkt eintragen

### 8.5 Wireframe — Tablet/Desktop

```
┌──────────────────────────────────────────────────────────────┐
│ ← Kalender                                                   │
├──────────────────────────────────────────────────────────────┤
│ Schichten                                                    │
├──────────────────────────────────────────────────────────────┤
│ [Alle Pläne]  [Meine Schichten]  [Verfügbar]                 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Demnächst (2)                                               │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 🔨 Bühnenaufbau · Sommerfest 2026                      │  │
│  │ 15.06.2026, 08:00 – 11:00                              │  │
│  │                                                        │  │
│  │ [✓ Du bist dabei]  [Austragen]                        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 🍻 Getränkeverkauf · Sommerfest 2026                   │  │
│  │ 15.06.2026, 10:00 – 22:00                              │  │
│  │                                                        │  │
│  │ [✓ Du bist dabei]  [Austragen]                        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 9. Interaction Patterns

### 9.1 Kapazitäts-Anzeige

**Fortschritts-Dots:**
- ● = besetzt
- ○ = offen
- Max 8 Dots, bei >8 Personen: Zahl anzeigen (z.B. „12/15")

**Farb-Kodierung:**
- **Grün (`color-success`):** 100% besetzt (z.B. 5/5)
- **Gelb (`color-warning`):** 50–99% besetzt (z.B. 3/5)
- **Rot (`color-error`):** 0–49% besetzt (z.B. 1/5 oder 0/5)

### 9.2 Zeitformat

- **Zeit:** 24h-Format (08:00, nicht 8:00 AM)
- **Datum:** DD.MM.YYYY (15.06.2026)
- **Kombiniert:** „15.06., 08:00 – 11:00" (Kompakt für Mobile)

### 9.3 Selbsteintragung

- **Ohne Confirmation:** Tap → sofortige Eintragung (schnell)
- **Mit Toast:** „✓ Eintragung erfolgreich" (5s Anzeige)
- **Undo:** Austragung nur via ✕-Button mit Confirmation

### 9.4 Admin-Zuweisung

- **Phone:** Modal mit Liste
- **Desktop:** Inline-Dropdown mit Autocomplete
- **Multi-Select:** Nicht in MS2 (nur eine Person pro Zuweisung)

### 9.5 Push-Benachrichtigungen

**Trigger:**
1. **Neuer Plan erstellt:** „Neuer Schichtplan: Sommerfest 2026"
2. **Neue Schicht hinzugefügt:** „Neue Schicht: Abbau (15.06., 22–24 Uhr)"
3. **Admin-Zuweisung:** „Du wurdest für „Bühnenaufbau" eingeteilt"

**Einstellung:**
- Pro Kapelle deaktivierbar (Kapellen-Konfiguration)
- Pro Nutzer deaktivierbar (Nutzer-Einstellungen)

---

## 10. Error States & Leerzustände

### 10.1 Keine Schichtpläne

```
┌─────────────────────────────────┐
│ ← Schichten                     │
├─────────────────────────────────┤
│                                 │
│         📅                      │
│                                 │
│   Noch keine Schichtpläne       │
│                                 │
│   Erstelle einen Schichtplan für│
│   Veranstaltungen wie Feste,    │
│   Konzerte oder Aufbau.         │
│                                 │
│   [+ Neuer Schichtplan]         │ ← Nur für Admin/Dirigent
│                                 │
└─────────────────────────────────┘
```

### 10.2 Keine Schichten im Plan

```
┌─────────────────────────────────┐
│ ← Sommerfest 2026               │
├─────────────────────────────────┤
│ 15.06.2026                      │
│                                 │
├─────────────────────────────────┤
│                                 │
│         📝                      │
│                                 │
│   Noch keine Schichten          │
│                                 │
│   Füge Schichten wie Aufbau,    │
│   Getränkeverkauf oder Abbau    │
│   hinzu.                        │
│                                 │
│   [+ Schicht hinzufügen]        │
│                                 │
└─────────────────────────────────┘
```

### 10.3 Schicht voll

```
┌─────────────────────────────────┐
│ ⚠️ Schicht voll                  │ ← Dialog
├─────────────────────────────────┤
│                                 │
│ Die Schicht „Bühnenaufbau" ist  │
│ bereits vollständig besetzt.    │
│                                 │
│ [OK]                            │
└─────────────────────────────────┘
```

### 10.4 Bereits eingetragen

```
┌─────────────────────────────────┐
│ ℹ️ Bereits eingetragen           │
├─────────────────────────────────┤
│                                 │
│ Du bist bereits für diese Schicht│
│ eingetragen.                    │
│                                 │
│ [OK]                            │
└─────────────────────────────────┘
```

### 10.5 Zeitkonflikt (Warnung)

```
┌─────────────────────────────────┐
│ ⚠️ Zeitkonflikt                  │
├─────────────────────────────────┤
│                                 │
│ Du bist bereits für die Schicht │
│ „Getränkeverkauf" (10:00–22:00) │
│ eingetragen.                    │
│                                 │
│ Diese Schicht überschneidet sich│
│ teilweise. Trotzdem eintragen?  │
│                                 │
├─────────────────────────────────┤
│ [Abbrechen] [Trotzdem eintragen]│
└─────────────────────────────────┘
```

**Hinweis:** Konflikte blockieren nicht, nur Warnung.

### 10.6 Keine verfügbaren Schichten

```
┌─────────────────────────────────┐
│ ← Meine Schichten               │
├─────────────────────────────────┤
│ Meine Schichten [Verfügbar]     │
├─────────────────────────────────┤
│                                 │
│         ✓                       │
│                                 │
│   Alle Schichten besetzt        │
│                                 │
│   Aktuell sind alle Schichten   │
│   vollständig besetzt. Schau    │
│   später nochmal vorbei!        │
│                                 │
└─────────────────────────────────┘
```

---

## 11. Accessibility

### 11.1 Screen Reader

- **Fortschritts-Dots:** Alt-Text „3 von 5 Personen zugewiesen"
- **Status-Badges:** „Voll besetzt", „Teilweise besetzt", „Leer" (nicht nur Farbe)
- **Zeitangaben:** „15. Juni 2026, 8 bis 11 Uhr" (vollständig ausgeschrieben)

### 11.2 Keyboard-Navigation

- **Tab-Order:** Plan-Titel → Schicht-Karten → „Ich bin dabei"-Button → Nächste Schicht
- **Enter/Space:** Aktiviert „Ich bin dabei" oder öffnet Detail
- **Escape:** Schließt Modal/Dialog

### 11.3 Kontrast

- **Farb-Badges:** Grün/Gelb/Rot erfüllen WCAG AA (4.5:1)
- **Text auf Buttons:** Mindestens 4.5:1 Kontrast
- **Fortschritts-Dots:** ● (gefüllt) vs ○ (leer) deutlich unterscheidbar

### 11.4 Touch-Targets

- **Minimum:** 44×44px (alle interaktiven Elemente)
- **Schicht-Karten:** Mindestens 60px Höhe (tappable)
- **„Ich bin dabei"-Button:** 48px Höhe

---

## 12. Responsive Breakpoints

### 12.1 Phone (<600px)

- **Layout:** Single-Column, Karten gestapelt
- **Modal:** Fullscreen (Bottom-Sheet-Style)
- **Schicht-Karten:** Volle Breite
- **Namen:** Max 3 Namen + „+2 weitere"

### 12.2 Tablet (600–1024px)

- **Layout:** Two-Column (optional Split-View)
- **Modal:** Zentriert, 600px Breite
- **Schicht-Karten:** Grid (2 Spalten)
- **Namen:** Alle Namen sichtbar

### 12.3 Desktop (>1024px)

- **Layout:** Three-Column (Sidebar + Content + Detail-Panel)
- **Modal:** Zentriert, 800px Breite (oder Inline-Dropdown)
- **Schicht-Karten:** Liste oder Grid (3 Spalten)
- **Hover-States:** Tooltip auf Schicht-Karte mit Beschreibung
- **Inline-Aktionen:** Keine Modals nötig (Dropdown für Zuweisung)

---

## 13. Abhängigkeiten

### 13.1 Backend-APIs

- `POST /api/v1/kapellen/{kapelleId}/schichtplaene` — Plan erstellen
- `GET /api/v1/kapellen/{kapelleId}/schichtplaene` — Liste aller Pläne
- `GET /api/v1/kapellen/{kapelleId}/schichtplaene/{planId}` — Plan-Detail
- `POST /api/v1/kapellen/{kapelleId}/schichtplaene/{planId}/schichten` — Schicht hinzufügen
- `POST /api/v1/kapellen/{kapelleId}/schichtplaene/{planId}/schichten/{schichtId}/zuweisungen` — Zuweisung (Admin oder Self-Signup)
- `DELETE /api/v1/kapellen/{kapelleId}/schichtplaene/{planId}/schichten/{schichtId}/zuweisungen/{zuweisungId}` — Austragung
- `GET /api/v1/kapellen/{kapelleId}/schichtplaene/meine-schichten` — Persönliche Übersicht

### 13.2 Frontend-Komponenten

- **Date-Picker:** Material Design Date Picker
- **Time-Picker:** Material Design Time Picker
- **Stepper:** Custom Component für Anzahl-Auswahl
- **Toast:** Snackbar für Erfolgs-Feedback
- **Modal/Bottom-Sheet:** Platform-spezifisch (iOS/Android/Desktop)

### 13.3 Bestehende UX-Specs

- `docs/ux-design.md` — Design-Tokens, Farben, Typografie
- `docs/ux-konfiguration.md` — Push-Benachrichtigungs-Einstellungen (Kapellen-Ebene)

### 13.4 Feature-Specs

- `docs/feature-specs/schichtplanung-spec.md` — Datenmodell, API-Kontrakte, RBAC

---

**Ende der UX-Spec: Schichtplanung**
