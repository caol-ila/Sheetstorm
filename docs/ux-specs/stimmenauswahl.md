# UX-Spec: Stimmenauswahl & Instrument-Profil — Sheetstorm

> **Issue:** #28 — [UX] Stimmenauswahl & Instrument-Profil — UX-Flows und Wireframes  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-28  
> **Meilenstein:** M1 — Kern: Noten & Kapelle  
> **Referenzen:** `docs/anforderungen.md §1.1a`, `docs/ux-design.md §4.2`, `docs/ux-konfiguration.md §4`

---

## Inhaltsverzeichnis

1. [Übersicht & Konzept](#1-übersicht--konzept)
2. [Instrument-Profil anlegen](#2-instrument-profil-anlegen)
3. [Standard-Stimme pro Kapelle](#3-standard-stimme-pro-kapelle)
4. [Vorauswahl beim Öffnen eines Stücks](#4-vorauswahl-beim-öffnen-eines-stücks)
5. [Fallback-Logik](#5-fallback-logik)
6. [Stimmen-Auswahl-Dialog](#6-stimmen-auswahl-dialog)
7. [Onboarding-Integration](#7-onboarding-integration)
8. [Wireframes: Phone](#8-wireframes-phone)
9. [Wireframes: Tablet](#9-wireframes-tablet)
10. [Edge Cases](#10-edge-cases)
11. [Abhängigkeiten](#11-abhängigkeiten)

---

## 1. Übersicht & Konzept

### 1.1 Das Kernproblem

Ein Musiker öffnet ein Stück und muss sofort die **richtige Stimme** sehen — ohne zu suchen, ohne zu scrollen, ohne nachzudenken. In einer Blaskapelle gibt es für jedes Stück oft 15–30 verschiedene Stimmen. Das System muss intelligent vorauswählen.

### 1.2 Drei-Schichten-Modell

```
SCHICHT 1: Instrument-Profil (einmalig einrichten)
    └── Welche Instrumente spiele ich?
    └── Welche Stimme spiele ich normalerweise? (pro Kapelle)

SCHICHT 2: Standardstimme (pro Kapelle konfigurierbar)
    └── „Ich spiele bei Kapelle A als 2. Klarinette"
    └── „Ich spiele bei Kapelle B als 1. Klarinette"

SCHICHT 3: Fallback-Logik (automatisch)
    └── Exakte Stimme vorhanden? → Nehmen
    └── Nicht vorhanden? → Nächstliegende Stimme
    └── Keine Stimme? → Alle Stimmen anzeigen, manuelle Auswahl
```

### 1.3 Kernregel: Vorauswahl ≠ Erzwingen

Die Standardstimme wird **vorausgewählt**, aber nie erzwungen. Der Musiker kann jederzeit eine andere Stimme wählen — für einzelne Stücke oder dauerhaft.

---

## 2. Instrument-Profil anlegen

### 2.1 Flow: Neues Instrument hinzufügen

```
Einstellungen → 👤 Nutzer → Instrumente & Stimmen
        │
        ▼
[+ Instrument hinzufügen]
        │
        ▼
Instrument-Picker (§8.1)
        │
        ▼
Standardstimme auswählen (für dieses Instrument)
        │
        ▼
Hauptinstrument? [Ja / Nein]
        │                │
        ▼                ▼
  Als Hauptinstrument   Als Nebeninstrument
  setzen                hinzufügen
        │                │
        └────────┬────────┘
                 ▼
        Instrument-Liste aktualisiert
        → Auto-Save (kein Button)
        → Toast: „Klarinette hinzugefügt"
```

### 2.2 Instrument-Picker

```
┌─────────────────────────────────┐
│  🔍 Instrument suchen…          │
├─────────────────────────────────┤
│  BLASINSTRUMENTE (HOLZ)         │
│  ─────────────────────────────  │
│  🎵 Klarinette                  │
│  🎵 Oboe                        │
│  🎵 Fagott                      │
│  🎵 Saxophon (Alt)              │
│  🎵 Saxophon (Tenor)            │
│  🎵 Saxophon (Bariton)          │
│  🎵 Querflöte                   │
│  🎵 Piccolo                     │
│                                 │
│  BLASINSTRUMENTE (BLECH)        │
│  ─────────────────────────────  │
│  🎺 Trompete                    │
│  🎺 Flügelhorn                  │
│  🎺 Tenorhorn                   │
│  🎺 Euphonium / Bariton         │
│  🎶 Tuba                        │
│  🎶 Kontrabass-Tuba             │
│  🎺 Waldhorn / Horn             │
│  🎺 Posaune                     │
│                                 │
│  SCHLAGZEUG                     │
│  ─────────────────────────────  │
│  🥁 Schlagzeug (allgemein)      │
│  🥁 Kleine Trommel              │
│  🥁 Große Trommel               │
│  🥁 Becken                      │
│  🥁 Stabspiele (Xylophon etc.)  │
│                                 │
│  🔍 Nicht gefunden? Eingeben:   │
│  [___________________________]  │  ← Freie Texteingabe
└─────────────────────────────────┘
```

### 2.3 Stimme für Instrument auswählen

Nach der Instrument-Wahl wird die Standard-Stimme ausgewählt:

```
┌─────────────────────────────────┐
│  ← Instrument   Standardstimme │
│  für Klarinette                 │
├─────────────────────────────────┤
│                                 │
│  Welche Stimme spielst du       │
│  normalerweise?                 │
│                                 │
│  ○ 1. Klarinette                │
│  ● 2. Klarinette   ← Standard  │
│  ○ 3. Klarinette                │
│  ○ Klarinette (allgemein)       │
│  ○ Klarinette in B              │
│  ○ Klarinette in Es             │
│                                 │
│  Diese Stimme kann pro Kapelle  │
│  angepasst werden (§3).         │
│                                 │
│  [← Zurück]     [Übernehmen →] │
└─────────────────────────────────┘
```

---

## 3. Standard-Stimme pro Kapelle

### 3.1 Konzept

Jeder Musiker kann **pro Kapelle** eine andere Standardstimme festlegen. Das ist wichtig weil:
- Musiker spielen in zwei Kapellen oft verschiedene Stimmlagen
- Bei Multi-Kapellen-Zugehörigkeit gibt es verschiedene Rollen

### 3.2 Flow: Standardstimme pro Kapelle einstellen

```
Einstellungen → 👤 Nutzer → Instrumente & Stimmen
        │
        ▼
Instrument auswählen (z.B. Klarinette)
        │
        ▼
STANDARDSTIMMEN PRO KAPELLE
  ┌────────────────────────────────┐
  │  Musikkapelle Beispiel (MKB)   │
  │  Stimme: [2. Klarinette    ▼] │
  ├────────────────────────────────┤
  │  Jugendkapelle Beispiel (JKB)  │
  │  Stimme: [1. Klarinette    ▼] │
  └────────────────────────────────┘
        │
        ▼
Auswahl aus Dropdown → Auto-Save
```

### 3.3 Wirkt sofort

Wenn der Musiker die Standardstimme ändert, gilt die neue Stimme ab dem nächsten Öffnen eines Stücks. Es gibt keine Bestätigungsdialoge — die Änderung ist rückgängig machbar (Auto-Save + Undo-Toast).

---

## 4. Vorauswahl beim Öffnen eines Stücks

### 4.1 Entscheidungsbaum

Beim Öffnen eines Stücks wird die Stimme automatisch bestimmt:

```
Stück öffnen
      │
      ▼
Wurde für DIESES STÜCK manuell eine Stimme gewählt?
      │ Ja                          │ Nein
      ▼                             ▼
Zuletzt gewählte Stimme        Standard-Stimme des aktiven
für dieses Stück laden         Instruments in dieser Kapelle
                                     │
                                     ▼
                               Ist diese Stimme im Stück vorhanden?
                                     │ Ja           │ Nein
                                     ▼              ▼
                               Stimme laden    Fallback-Logik (§5)
```

### 4.2 Keine Bestätigung nötig

Die Vorauswahl wird **ohne Dialog** angewendet. Der Musiker sieht die Noten sofort. Der Stimmenname ist in der Overlay-Leiste sichtbar (`🎵 2. Klarinette`).

### 4.3 Persistenz

- **Pro Stück gespeicherte Wahl:** Wenn ein Musiker bei einem Stück manuell eine andere Stimme wählt, wird diese für zukünftige Öffnungen dieses Stücks gemerkt
- **Reset:** Über „Standard wiederherstellen" im Stimmen-Dialog
- **Gilt nur für den eigenen Account** — nicht geräteübergreifend innerhalb derselben Sitzung

---

## 5. Fallback-Logik

### 5.1 Fallback-Kette (visuell kommuniziert)

Wenn die exakte Standard-Stimme nicht vorhanden ist, greift eine geordnete Fallback-Kette:

```
Gewünschte Stimme: „2. Klarinette"
        │
        ▼
Level 1: Exakte Übereinstimmung
  „2. Klarinette" vorhanden?  → Ja: Nehmen ✓
        │ Nein
        ▼
Level 2: Gleiche Nummer, anderer Name
  „2. Stimme" oder „Klarinette 2" vorhanden? → Ja: Nehmen (mit Hinweis)
        │ Nein
        ▼
Level 3: Gleicher Instrumententyp ohne Nummer
  „Klarinette" vorhanden? → Ja: Nehmen (mit Hinweis)
        │ Nein
        ▼
Level 4: Gleiches Register (z.B. Holzbläser)
  Irgendeine Holzbläser-Stimme vorhanden? → Ja: Nehmen (mit Hinweis)
        │ Nein
        ▼
Level 5: Erste verfügbare Stimme
  Beliebige Stimme nehmen (mit Hinweis)
        │ Keine Stimmen verfügbar
        ▼
Kein Fallback möglich → Fehlermeldung §10.2
```

### 5.2 Visuelle Kommunikation der Fallback-Stufe

Der Fallback wird **transparent kommuniziert** — nicht still:

```
LEVEL 2 FALLBACK (Stimmen-Overlay-Leiste im Spielmodus):
┌─────────────────────────────────────────────────────────┐
│  🎵 1. Klarinette  ⚠️                                   │
└─────────────────────────────────────────────────────────┘
  ↑ Tap öffnet Erklärung

Info-Toast beim Öffnen:
┌─────────────────────────────────────────────────────────┐
│  ℹ️ „2. Klarinette" nicht gefunden                      │
│  → 1. Klarinette wird verwendet       [Andere wählen]  │
└─────────────────────────────────────────────────────────┘
  (Toast, 5 Sekunden, schließbar)
```

### 5.3 Fallback im Stimmen-Auswahl-Dialog

Wenn der Stimmen-Dialog geöffnet wird und ein Fallback aktiv ist:

```
┌─────────────────────────────────────────┐
│  Stimme wählen                     ✕   │
├─────────────────────────────────────────┤
│  MEINE INSTRUMENTE                      │
│  ─────────────────────────────────────  │
│  ✗ 2. Klarinette  [nicht vorhanden]    │  ← Ausgegraut, ✗ statt ✓
│  → 1. Klarinette  ●──────────────────  │  ← Automatisch gewählt, Pfeil
│                                         │
│  ℹ️ Deine Standardstimme               │
│    „2. Klarinette" ist in diesem        │
│    Stück nicht verfügbar.              │
│    Automatisch: 1. Klarinette.         │
│                                         │
│  ANDERE STIMMEN                         │
│  ─────────────────────────────────────  │
│    Flöte 1                              │
│    Trompete 1                           │
│    ...                                  │
│                                         │
│  [Standard wiederherstellen]           │  ← Setzt auf Standardstimme zurück
└─────────────────────────────────────────┘
```

### 5.4 Fallback-Logik deaktivieren

Nutzer kann Fallback deaktivieren (für Puristen oder spezielle Setups):

```
Einstellungen → Instrumente & Stimmen → Fallback-Verhalten
  [■ Automatisch nächste Stimme vorschlagen]   ← Standard
  [ ] Immer nach Stimme fragen wenn nicht vorhanden
```

---

## 6. Stimmen-Auswahl-Dialog

### 6.1 Öffnen-Anlässe

| Anlass | Trigger |
|--------|---------|
| Beim Öffnen (kein Fallback) | Automatisch wenn keine Standard-Stimme matchbar |
| Manuell im Spielmodus | Overlay → `🎵 Stimme` |
| Aus Bibliotheks-Detail | Button „Stimme wählen" |
| Aus Setlist | Stück antippen → Stimme wählen |

### 6.2 Sortierung der Stimmen

Die Reihenfolge der Stimmen im Dialog folgt einer klaren Priorisierung:

```
GRUPPE 1: MEINE INSTRUMENTE (prominent, oben)
  → Eigene Instrumente aus Instrument-Profil
  → Sortiert: Hauptinstrument zuerst, dann Nebeninstrumente
  → Aktuell gewählte Stimme: Checkmark + Farbhighlight

TRENNLINIE

GRUPPE 2: ANDERE STIMMEN (kompakt, unten)
  → Alle übrigen verfügbaren Stimmen des Stücks
  → Sortiert nach Register-Reihenfolge (Flöte → Klarinette → Saxophon → ... → Schlagzeug)
  → Wenn viele Stimmen: scrollbar
```

### 6.3 Suche im Dialog

Bei Stücken mit vielen Stimmen (>10) erscheint eine Suchzeile:

```
┌─────────────────────────────────────────┐
│  Stimme wählen                     ✕   │
│  🔍 Stimme suchen…                      │  ← Erscheint ab 10+ Stimmen
├─────────────────────────────────────────┤
│  MEINE INSTRUMENTE                      │
│  ...                                    │
```

### 6.4 Nicht-verfügbare Stimmen

Stimmen des eigenen Instruments, die im aktuellen Stück nicht vorhanden sind:
- Werden ausgegraut angezeigt (Transparenz 40%)
- Haben ein `—` statt Checkmark
- Tippen → freundliche Erklärung: „Diese Stimme ist nicht in diesem Stück enthalten"

---

## 7. Onboarding-Integration

### 7.1 Schritt 3 im Onboarding: Instrument + Stimme

Das Instrument-Profil wird bereits im Onboarding-Wizard eingerichtet (Schritt 3/5):

```
Onboarding Schritt 3:
┌─────────────────────────────────┐
│  ○○○●○             3/5          │
│                                 │
│  Was spielst du?                │
│  (Mehrere Instrumente möglich)  │
│                                 │
│  🔍 [Instrument suchen…]        │
│  ─────────────────────────────  │
│  🎵 Klarinette            ✓    │  ← Ausgewählt, expandiert
│     Standardstimme:             │
│     [2. Klarinette          ▼] │  ← Sofort-Dropdown unter Instrument
│                                 │
│  🎵 Saxophon (Alt)              │
│  🎺 Trompete                    │
│  🎺 Flügelhorn                  │
│  + weitere anzeigen…            │
│                                 │
│  [← Zurück]     [Weiter →]     │
└─────────────────────────────────┘
```

### 7.2 Nachträgliche Einrichtung

Wenn Onboarding übersprungen wird, erscheint beim ersten Öffnen eines Stücks ein sanfter Hinweis:

```
Toast beim ersten Öffnen:
┌─────────────────────────────────────────────────────────┐
│  🎵 Tipp: Instrument einrichten für automatische        │
│  Stimmauswahl.                     [Jetzt einrichten]  │
└─────────────────────────────────────────────────────────┘
  (Toast, 8 Sekunden. Einmalig angezeigt.)
```

---

## 8. Wireframes: Phone

### 8.1 Phone — Instrument-Profil Übersicht

```
┌─────────────────────────────────┐
│  ← Einstellungen  Instrumente   │
├─────────────────────────────────┤
│                                 │
│  HAUPTINSTRUMENT                │
│  ─────────────────────────────  │
│  ┌─────────────────────────┐   │
│  │  🎵 Klarinette        ● │   │  ← ● = Hauptinstrument
│  │  ─────────────────────  │   │
│  │  Standardstimmen:       │   │
│  │  MKB: 2. Klarinette     │   │
│  │  JKB: 1. Klarinette     │   │
│  │  [Stimmen bearbeiten]   │   │
│  └─────────────────────────┘   │
│                                 │
│  WEITERE INSTRUMENTE            │
│  ─────────────────────────────  │
│  🎵 Saxophon (Alt)     ✏️ 🗑   │
│      Standard: Alt-Stimme 1     │
│                                 │
│  [+ Instrument hinzufügen]      │
│                                 │
│  FALLBACK-EINSTELLUNGEN         │
│  ─────────────────────────────  │
│  Wenn Stimme fehlt:             │
│  [■ Automatisch nächste wählen] │
│  Hinweis anzeigen: [■ An]       │
│                                 │
└─────────────────────────────────┘
```

### 8.2 Phone — Standardstimmen pro Kapelle (Detail)

```
┌─────────────────────────────────┐
│  ← Instrumente  Standardstimmen │
│  für Klarinette                 │
├─────────────────────────────────┤
│                                 │
│  ALLGEMEIN (übergreifend)       │
│  ─────────────────────────────  │
│  Standard-Stimme:               │
│  [2. Klarinette            ▼]  │
│  Gilt wenn keine               │
│  kapellenspezifische Einstellung│
│  vorhanden ist.                 │
│                                 │
│  PRO KAPELLE                    │
│  ─────────────────────────────  │
│  Musikkapelle Beispiel (MKB)    │
│  [2. Klarinette            ▼]  │
│                                 │
│  Jugendkapelle Beispiel (JKB)   │
│  [1. Klarinette            ▼]  │
│                                 │
│  [+ Kapellen-spezifisch]        │
│                                 │
└─────────────────────────────────┘
```

### 8.3 Phone — Instrument hinzufügen (Schritt 1: Instrument)

```
┌─────────────────────────────────┐
│  ← Instrumente  Neues Instrument│
├─────────────────────────────────┤
│                                 │
│  🔍 Instrument suchen…          │
│  ─────────────────────────────  │
│                                 │
│  BLASINSTRUMENTE                │
│  ─────────────────────────────  │
│  🎵 Klarinette                  │
│  🎵 Oboe                        │
│  🎵 Fagott                      │
│  🎵 Saxophon (Alt)              │
│  🎵 Saxophon (Tenor)            │
│  🎺 Trompete                    │
│  🎺 Flügelhorn                  │
│  🎺 Tenorhorn                   │
│  🎶 Tuba                        │
│  🥁 Schlagzeug                  │
│  ...                            │
│                                 │
│  NICHT GEFUNDEN?                │
│  [_________________________]   │
│                                 │
└─────────────────────────────────┘
```

### 8.4 Phone — Instrument hinzufügen (Schritt 2: Stimme + Rolle)

```
┌─────────────────────────────────┐
│  ← Instrument   Einrichten      │
│  Trompete                       │
├─────────────────────────────────┤
│                                 │
│  STANDARDSTIMME                 │
│  ─────────────────────────────  │
│  ○ 1. Trompete                  │
│  ● 2. Trompete   ← ausgewählt  │
│  ○ 3. Trompete                  │
│  ○ Trompete (allgemein)         │
│                                 │
│  ROLLE IN MEINEM PROFIL         │
│  ─────────────────────────────  │
│  ○ Hauptinstrument              │
│  ● Nebeninstrument ← Standard  │
│                                 │
│  ──────────────────────────     │
│  Nebeninstrumente erscheinen    │
│  in der Stimmen-Auswahl, aber   │
│  nicht als erste Priorität.     │
│                                 │
│  [← Zurück]     [Speichern ✓]  │
└─────────────────────────────────┘
```

### 8.5 Phone — Stimmen-Auswahl-Dialog (normaler Zustand)

```
┌─────────────────────────────────┐
│  Stimme wählen             ✕   │
├─────────────────────────────────┤
│                                 │
│  MEINE INSTRUMENTE              │
│  ─────────────────────────────  │
│  ✓ 2. Klarinette  ●──────────   │  ← Aktuell, blau markiert
│    1. Klarinette                │
│    Klarinette in B              │
│  — Saxophon (Alt)               │  ← — = nicht in diesem Stück
│                                 │
│  ANDERE STIMMEN                 │
│  ─────────────────────────────  │
│    Flöte 1                      │
│    Flöte 2                      │
│    Oboe                         │
│    1. Trompete                  │
│    2. Trompete                  │
│    Flügelhorn                   │
│    Tenorhorn                    │
│    Tuba                         │
│    Schlagzeug                   │
│                                 │
└─────────────────────────────────┘
```

### 8.6 Phone — Stimmen-Auswahl-Dialog (Fallback aktiv)

```
┌─────────────────────────────────┐
│  Stimme wählen             ✕   │
├─────────────────────────────────┤
│                                 │
│  MEINE INSTRUMENTE              │
│  ─────────────────────────────  │
│  ✗ 2. Klarinette  [fehlt]      │  ← Ausgegraut, ✗
│  → 1. Klarinette  ●──────────   │  ← Fallback, Pfeil-Icon
│    Klarinette in B              │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ℹ️ „2. Klarinette"       │   │
│  │ nicht vorhanden. Fallback│   │
│  │ auf 1. Klarinette.       │   │
│  └─────────────────────────┘   │
│                                 │
│  ANDERE STIMMEN                 │
│  ─────────────────────────────  │
│    Trompete 1                   │
│    Flügelhorn                   │
│    ...                          │
│                                 │
│  [Standard wiederherstellen]   │
└─────────────────────────────────┘
```

---

## 9. Wireframes: Tablet

### 9.1 Tablet — Instrument-Profil (Split-View)

```
┌──────────────────────────┬──────────────────────────────────────────┐
│  Instrumente & Stimmen   │  🎵 Klarinette — Hauptinstrument         │
│  ─────────────────────── │  ─────────────────────────────────────   │
│  🎵 Klarinette     ● ►  │  STANDARDSTIMMEN PRO KAPELLE            │
│  🎵 Saxophon (Alt)   ►   │  ─────────────────────────────────────   │
│                           │  Allgemein (Standard):                  │
│  [+ Hinzufügen]           │  [2. Klarinette                    ▼]  │
│                           │                                         │
│                           │  Musikkapelle Beispiel (MKB):          │
│                           │  [2. Klarinette                    ▼]  │
│                           │                                         │
│                           │  Jugendkapelle Beispiel (JKB):         │
│                           │  [1. Klarinette                    ▼]  │
│                           │                                         │
│                           │  [+ Kapellen-spezifisch hinzufügen]    │
│                           │                                         │
│                           │  FALLBACK                              │
│                           │  [■ Automatisch nächste wählen]        │
│                           │  [■ Hinweis anzeigen]                  │
│                           │                                         │
│                           │  [Instrument entfernen] (rot)          │
└──────────────────────────┴──────────────────────────────────────────┘
```

### 9.2 Tablet — Stimmen-Auswahl-Dialog (Zentriertes Modal)

```
┌──────────────────────────────────────────────────────────────────────┐
│  [Notenblatt / Hintergrund, gedimmt]                                │
│                                                                      │
│       ┌─────────────────────────────────────────────┐               │
│       │  Stimme wählen                        ✕    │               │
│       │  Böhmischer Traum — Musikkapelle Beispiel   │               │
│       ├─────────────────────────────────────────────┤               │
│       │                                             │               │
│       │  MEINE INSTRUMENTE                          │               │
│       │  ─────────────────────────────────────────  │               │
│       │  ✓ 2. Klarinette     ●─────────────────    │               │
│       │    1. Klarinette                            │               │
│       │    Klarinette in B                          │               │
│       │  — Saxophon (Alt)      [nicht vorhanden]   │               │
│       │                                             │               │
│       │  ANDERE STIMMEN                             │               │
│       │  ─────────────────────────────────────────  │               │
│       │  Flöte 1    Flöte 2    Oboe                 │               │
│       │  Trompete 1  Trompete 2  Flügelhorn         │               │
│       │  Tenorhorn   Tuba        Schlagzeug          │               │
│       │                                             │               │
│       └─────────────────────────────────────────────┘               │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 10. Edge Cases

### 10.1 Kein Instrument im Profil (Neuer Nutzer)

Beim ersten Öffnen ohne Instrument-Profil:

```
Stück antippen
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│  🎵 Welches Instrument spielst du?                      │
│                                                         │
│  Richte dein Instrument-Profil ein, damit Sheetstorm   │
│  automatisch die richtige Stimme für dich wählt.        │
│                                                         │
│  [Instrument einrichten]                               │
│  [Alle Stimmen anzeigen →]                             │  ← Direkt weiter
└─────────────────────────────────────────────────────────┘
```

### 10.2 Stück ohne Stimmen (technischer Defekt)

```
┌─────────────────────────────────────────────────────────┐
│  ⚠️ Keine Stimmen verfügbar                             │
│                                                         │
│  Dieses Stück enthält noch keine zugeordneten Stimmen. │
│  Wende dich an deinen Notenwart.                       │
│                                                         │
│  [Zurück zur Setlist]                                  │
└─────────────────────────────────────────────────────────┘
```

### 10.3 Multi-Kapellen: Verschiedene Stimmbezeichnungen

Zwei Kapellen haben unterschiedliche Benennungskonventionen (z.B. „Klarinette II" vs. „2. Klarinette"):

```
ALIAS-MATCHING (automatisch, via Kapellen-Register-Verwaltung):
  → Der Kapellen-Admin hinterlegt Aliases im Registerplan
  → „Klarinette II" = Alias für „2. Klarinette"
  → System matcht transparent, Nutzer sieht immer seinen bevorzugten Namen
```

### 10.4 Instrument-Profil bei Aushilfe (ohne Account)

Aushilfen (via Deep-Link `sheetstorm://aushilfe/[token]`) haben kein Profil:
- Es wird die zugewiesene Stimme angezeigt (vom Notenwart festgelegt)
- Kein Instrument-Profil nötig — Token enthält Stimmen-ID
- Kein Stimmen-Dialog — nur die eine zugewiesene Stimme ist sichtbar

### 10.5 Instrument entfernen — Auswirkungen

Wenn ein Instrument aus dem Profil entfernt wird, das noch als Standardstimme referenziert ist:

```
┌─────────────────────────────────────────────────────────┐
│  Saxophon entfernen?                                    │
│                                                         │
│  Saxophon ist als Standardstimme für 3 Kapellen         │
│  eingestellt. Diese werden zurückgesetzt.              │
│                                                         │
│  [Abbrechen]       [Entfernen]                         │
└─────────────────────────────────────────────────────────┘
```

---

## 11. Abhängigkeiten

### 11.1 Für Hill (Frontend / Flutter)

| Komponente | Spec-Verweis |
|------------|-------------|
| `InstrumentProfileScreen` | §2, §8.1 |
| `InstrumentPickerSheet` | §2.2, §8.3 |
| `VoiceStandardScreen` | §3, §8.2 |
| `VoiceSelectionDialog` | §6, §8.5/8.6 |
| `FallbackBanner` (Toast/Inline) | §5.2, §5.3 |
| `OnboardingInstrumentStep` | §7.1 |

### 11.2 Für Banner (Backend)

| Endpoint | Zweck |
|----------|-------|
| `GET /api/user/instruments` | Instrument-Profil laden |
| `POST /api/user/instruments` | Instrument hinzufügen |
| `PUT /api/user/instruments/{id}` | Standardstimme / Rolle ändern |
| `DELETE /api/user/instruments/{id}` | Instrument entfernen |
| `GET /api/pieces/{id}/voices` | Verfügbare Stimmen eines Stücks |
| `POST /api/user/voice-preferences` | Pro-Stück-Stimmwahl speichern |

### 11.3 Offene Fragen für Thomas

- [ ] Soll die Pro-Stück-Stimmwahl global synchronisiert werden (Server) oder nur lokal bleiben?
- [ ] Wie viele Instrumente kann ein Musiker maximal angeben? (Gibt es ein sinnvolles Limit?)
- [ ] Soll das Alias-System für Stimmbezeichnungen vom Kapellen-Admin gepflegt werden oder gibt es eine zentrale Mapping-Datenbank?
