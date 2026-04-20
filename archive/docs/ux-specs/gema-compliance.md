# UX-Spec: GEMA-Compliance — Sheetstorm

> **Issue:** #TBD  
> **Version:** 1.0  
> **Status:** Entwurf  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-29  
> **Meilenstein:** M2 — Vereinsleben & Aufführung  
> **Referenzen:** `docs/feature-specs/gema-compliance-spec.md`, `docs/ux-design.md`, `docs/ux-konfiguration.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Design-Prinzipien](#1-übersicht--design-prinzipien)
2. [Navigation & Entry Points](#2-navigation--entry-points)
3. [Flow A: Meldung erstellen](#3-flow-a-meldung-erstellen)
4. [Flow B: AI-gestützte Werknummern-Suche](#4-flow-b-ai-gestützte-werknummern-suche)
5. [Flow C: Manuelle Bearbeitung](#5-flow-c-manuelle-bearbeitung)
6. [Flow D: Export](#6-flow-d-export)
7. [Flow E: Verwertungsgesellschaft konfigurieren](#7-flow-e-verwertungsgesellschaft-konfigurieren)
8. [Flow F: Meldungs-Historie](#8-flow-f-meldungs-historie)
9. [Edge Cases & Error States](#9-edge-cases--error-states)
10. [Wireframes: Phone](#10-wireframes-phone)
11. [Wireframes: Tablet](#11-wireframes-tablet)
12. [Accessibility](#12-accessibility)
13. [Abhängigkeiten](#13-abhängigkeiten)

---

## 1. Übersicht & Design-Prinzipien

### 1.1 Kontext

GEMA-Meldungen sind **gesetzliche Pflicht** für deutsche Musikvereine. Nach jedem öffentlichen Auftritt muss eine Meldung mit gespielten Werken an die zuständige Verwertungsgesellschaft (meist GEMA) übermittelt werden.

**Problem:** Aktuell ist das ein manueller, zeitaufwändiger Prozess mit hoher Fehleranfälligkeit — oft werden Werknummern falsch notiert oder vergessen.

**Lösung:** Sheetstorm generiert GEMA-Meldungen direkt aus gespielten Setlists, unterstützt bei der Werknummern-Suche per AI und exportiert in allen gängigen Formaten.

**Zielgruppe:**  
- **Hauptnutzer:** Dirigent, Notenwart (selten tech-affin)  
- **Sekundärnutzer:** Admin (technische Übersicht, Reminder-Verwaltung)

### 1.2 Design-Prinzipien

1. **Nicht-Technik-Nutzer first:** Verwaltungsgesellschaft-Auswahl, Werknummern-Suche und Export müssen ohne Backend-Wissen nutzbar sein.
2. **Draft-first, Export-locked:** Einmal exportiert ist eine Meldung read-only — historische Konsistenz hat Vorrang vor Flexibilität.
3. **AI als Assistent, nicht Entscheider:** Confidence-Scores und manuelle Korrektur sind Pflicht — keine stillen AI-Entscheidungen.
4. **Reminder = Nudge, nicht Nag:** Erinnerungen sind informativ, nicht penetrant.
5. **Multi-Format-Export:** XML (Pflicht), CSV (Backup), PDF (Papierform für Behörden).

---

## 2. Navigation & Entry Points

### 2.1 Entry Points

**A) Aus Setlist-Detail:**  
- Nach Auftritt/Probe: Button **„GEMA-Meldung erstellen"** in Setlist-Actions (drei-Punkt-Menü)
- Angezeigt nur bei Setlists mit `status: completed` oder `event_type: concert`

**B) Über Kalender-Event:**  
- In Event-Detail: Button **„GEMA-Meldung erstellen"** (nur bei Konzert-Events)

**C) Über Admin-Bereich:**  
- Navigation: `Profil → Kapelle-Verwaltung → GEMA-Meldungen`
- Zeigt Liste aller Meldungen + Button **„Neue Meldung"**

**D) Über Reminder-Notification:**  
- Push-Notification: „GEMA-Meldung für ‚Frühjahrskonzert' noch nicht exportiert"
- Tap öffnet direkt die Draft-Meldung

### 2.2 Routing

```
/kapelle/{id}/gema-meldungen              → Liste
/kapelle/{id}/gema-meldungen/new          → Setlist-Auswahl
/kapelle/{id}/gema-meldungen/{meldungId}  → Detail/Edit
/kapelle/{id}/einstellungen#gema          → Verwertungsgesellschaft-Config
```

---

## 3. Flow A: Meldung erstellen

### 3.1 Trigger

- Nutzer: Dirigent, Notenwart, Admin
- Kontext: Nach einem Konzert mit bestehender Setlist
- Ziel: Neue GEMA-Meldung mit Event-Daten vorausfüllen

### 3.2 Ablauf

**Schritt 1: Setlist auswählen**

Falls Aufruf **aus Setlist-Detail** → direkt zu Schritt 2.

Falls Aufruf **aus Admin-Bereich / Kalender ohne Kontext:**

```
┌─────────────────────────────────────────┐
│ Neue GEMA-Meldung                       │
├─────────────────────────────────────────┤
│                                         │
│ Wähle Setlist:                          │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ ○ Frühjahrskonzert 2026           │   │
│ │   12.04.2026 · 18 Stücke          │   │
│ └───────────────────────────────────┘   │
│ ┌───────────────────────────────────┐   │
│ │ ○ Weihnachtskonzert 2025          │   │
│ │   20.12.2025 · 15 Stücke (GEMA ✓) │   │
│ └───────────────────────────────────┘   │
│                                         │
│         [Abbrechen]  [Weiter]           │
└─────────────────────────────────────────┘
```

- Liste zeigt nur Setlists mit `event_type: concert` oder `performance`
- Bereits gemeldete Setlists zeigen Icon `✓` + Tooltip „Bereits gemeldet am DD.MM.YYYY"
- Auswahl mehrfach möglich → Warnung bei Duplikat

**Schritt 2: Event-Daten bestätigen**

```
┌─────────────────────────────────────────┐
│ ← GEMA-Meldung erstellen                │
├─────────────────────────────────────────┤
│                                         │
│ Event-Daten:                            │
│                                         │
│ Veranstaltung                           │
│ [Frühjahrskonzert 2026____________]     │
│                                         │
│ Datum                                   │
│ [12.04.2026_________________]  📅       │
│                                         │
│ Veranstaltungsort                       │
│ [Stadthalle Musterstadt________]        │
│                                         │
│ Veranstalter                            │
│ [Musikverein Harmonie e.V._____]        │
│                                         │
│ Art der Veranstaltung                   │
│ [Konzert (öffentlich)__________] ▼      │
│                                         │
│ ────────────────────────────────────    │
│                                         │
│ Stücke: 18                              │
│ Fehlende Werknummern: 5 ⚠               │
│                                         │
│         [Abbrechen]  [Erstellen]        │
└─────────────────────────────────────────┘
```

- **Vorausfüllen:** Alle Event-Daten aus Setlist/Kalender-Event übernehmen
- **Editierbar:** Alle Felder, falls Setlist unvollständig
- **Dropdown „Art der Veranstaltung":**
  - Konzert (öffentlich)
  - Probe (öffentlich)
  - Kirchenkonzert
  - Fest/Straßenmusik
  - Wettbewerb
- **Warnung:** Anzahl fehlender Werknummern direkt sichtbar
- **Button „Erstellen":**
  - Erstellt Meldung mit Status `draft`
  - Öffnet Detail-Ansicht

**Schritt 3: Meldung erstellt**

→ Weiter zu **Flow C: Manuelle Bearbeitung** oder **Flow B: AI-Suche**

---

## 4. Flow B: AI-gestützte Werknummern-Suche

### 4.1 Trigger

- Nutzer: Dirigent, Notenwart, Admin
- Kontext: Meldung enthält Stücke ohne GEMA-Werknummer
- Ziel: Fehlende Werknummern automatisch ergänzen

### 4.2 Ablauf

**Schritt 1: AI-Suche starten**

```
┌─────────────────────────────────────────┐
│ ← Frühjahrskonzert 2026        [Export] │
├─────────────────────────────────────────┤
│                                         │
│ Status: Entwurf                         │
│ Erstellt: 15.03.2026 · Notenwart: Max   │
│                                         │
│ ⚠ 5 Stücke ohne Werknummer              │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 🤖 AI-Suche für fehlende Nummern  │   │
│ │                                   │   │
│ │ Sheetstorm durchsucht die GEMA-   │   │
│ │ Datenbank automatisch nach        │   │
│ │ passenden Werknummern.            │   │
│ │                                   │   │
│ │ [Für alle starten]  [Einzeln]     │   │
│ └───────────────────────────────────┘   │
│                                         │
│ Stücke:                                 │
│                                         │
│ 1. Radetzky-Marsch (J. Strauß)         │
│    ✓ Werknr: 1234567                    │
│                                         │
│ 2. An der schönen blauen Donau         │
│    ⚠ Werknummer fehlt          [Suchen] │
│                                         │
│ 3. Böhmischer Traum (E. Mohr)          │
│    ⚠ Werknummer fehlt          [Suchen] │
│                                         │
└─────────────────────────────────────────┘
```

**Optionen:**

- **„Für alle starten":** Bulk-Suche für alle fehlenden Nummern (empfohlen)
- **„Einzeln":** Zeigt Liste, Nutzer wählt einzelne Stücke aus
- **Pro-Stück-Button „Suchen":** Startet Suche nur für dieses Stück

**Schritt 2: AI-Suche läuft**

```
┌─────────────────────────────────────────┐
│ AI-Suche läuft…                         │
├─────────────────────────────────────────┤
│                                         │
│ ⟳ Durchsuche GEMA-Datenbank             │
│                                         │
│ ✓ 1/5 Radetzky-Marsch                   │
│ ⟳ 2/5 An der schönen blauen Donau       │
│ ○ 3/5 Böhmischer Traum                  │
│ ○ 4/5 Slawischer Tanz Nr. 1             │
│ ○ 5/5 Jupiter-Hymne                     │
│                                         │
│                 [Abbrechen]             │
└─────────────────────────────────────────┘
```

- **Loading State:** Progress mit Stück-Namen
- **Abbrechen möglich:** Bisher gefundene Ergebnisse werden trotzdem angezeigt
- **Dauer:** Typ. 2–5 Sekunden pro Stück

**Schritt 3: Ergebnisse anzeigen**

```
┌─────────────────────────────────────────┐
│ ← AI-Suchergebnisse              [Übernehmen] │
├─────────────────────────────────────────┤
│                                         │
│ 4 von 5 Werknummern gefunden            │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ ☑ An der schönen blauen Donau     │   │
│ │   Werknr: 2234567                 │   │
│ │   Confidence: 95% (Sehr sicher) ✓ │   │
│ │   Komponist: Johann Strauß (Sohn) │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ ☑ Böhmischer Traum                │   │
│ │   Werknr: 3345678                 │   │
│ │   Confidence: 78% (Wahrscheinlich)│   │
│ │   Komponist: Ernst Mohr           │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ ☐ Slawischer Tanz Nr. 1           │   │
│ │   Werknr: 4456789                 │   │
│ │   Confidence: 42% (Unsicher) ⚠    │   │
│ │   Komponist: Antonín Dvořák       │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ⚠ Jupiter-Hymne: Keine Ergebnisse      │
│                            [Manuell]    │
│                                         │
│     [Alle abwählen]  [Übernehmen]       │
└─────────────────────────────────────────┘
```

**Confidence-Levels:**

| Confidence | Label             | Icon | Farbe   | Auto-Select |
|------------|-------------------|------|---------|-------------|
| ≥ 90%      | Sehr sicher       | ✓    | Success | Ja          |
| 70–89%     | Wahrscheinlich    | –    | Primary | Ja          |
| 50–69%     | Unsicher          | ⚠    | Warning | Nein        |
| < 50%      | Nicht verwenden   | ✗    | Error   | Nein        |

**Interaktion:**

- Standardmäßig sind alle Ergebnisse mit Confidence ≥ 70% **vorgewählt**
- Nutzer kann einzelne Ergebnisse **ab-/anwählen** (Checkbox)
- **Keine Ergebnisse:** Link „Manuell" öffnet Eingabefeld für manuelle Werknummer
- **Button „Übernehmen":** Übernimmt alle gewählten Ergebnisse, schließt Dialog

**Schritt 4: Übernommen**

→ Zurück zu Meldungs-Detail (Flow C)

```
┌─────────────────────────────────────────┐
│ 4 Werknummern übernommen ✓              │
│                                         │
│ Verbleibend: 1 Stück ohne Werknummer    │
└─────────────────────────────────────────┘
     ↓ Toast (3s)
```

---

## 5. Flow C: Manuelle Bearbeitung

### 5.1 Trigger

- Nutzer: Dirigent, Notenwart, Admin
- Kontext: Meldung im Status `draft`
- Ziel: Werknummern manuell nachtragen, Stücke bearbeiten

### 5.2 Detail-Ansicht (Draft)

```
┌─────────────────────────────────────────┐
│ ← Frühjahrskonzert 2026    ⋮  [Export]  │
├─────────────────────────────────────────┤
│                                         │
│ Status: Entwurf                         │
│ Erstellt: 15.03.2026 · Notenwart: Max   │
│                                         │
│ ⚠ 1 Stück ohne Werknummer               │
│                                         │
│ Event-Daten                             │
│ Datum: 12.04.2026                       │
│ Ort: Stadthalle Musterstadt             │
│ Veranstalter: Musikverein Harmonie e.V. │
│ Art: Konzert (öffentlich)               │
│                                   [Bearbeiten] │
│                                         │
│ ────────────────────────────────────    │
│                                         │
│ Stücke (18)           [AI-Suche] [+ Stück] │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 1. Radetzky-Marsch                │   │
│ │    J. Strauß · Werknr: 1234567 ✓  │   │
│ │                                   │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 2. An der schönen blauen Donau ✎  │   │
│ │    J. Strauß (Sohn)               │   │
│ │    Werknr: 2234567 ✓ (AI 95%)     │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ 3. Jupiter-Hymne              ⚠   │   │
│ │    Unbekannt                      │   │
│ │    Werknummer: [________] [Suchen]│   │
│ └───────────────────────────────────┘   │
│                                         │
│ ⋮                                       │
│                                         │
└─────────────────────────────────────────┘
```

**Element-Details:**

- **Status-Badge „Entwurf":** Orange Farbe, oben links
- **Warnung:** Sticky Banner bei fehlenden Werknummern
- **Drei-Punkt-Menü (⋮):**
  - Meldung löschen
  - Duplikat erstellen
  - History anzeigen
- **Event-Daten „Bearbeiten":** Öffnet Inline-Edit-Modus (wie Schritt 2, Flow A)
- **Button „AI-Suche":** Startet Flow B für alle fehlenden Nummern
- **Button „+ Stück":** Manuelles Hinzufügen eines Stücks (nicht aus Setlist)
- **Stück-Karte:**
  - Icon `✓`: Werknummer vorhanden
  - Icon `✎`: Manuell bearbeitet
  - Badge `(AI 95%)`: Von AI gefunden, Confidence angezeigt
  - Icon `⚠`: Werknummer fehlt
  - Inline-Eingabe: Direkt editierbar bei Tap auf Karte
- **Export-Button:** Oben rechts (geht zu Flow D)

### 5.3 Stück editieren

```
┌─────────────────────────────────────────┐
│ ← Stück bearbeiten              [Speichern] │
├─────────────────────────────────────────┤
│                                         │
│ Titel                                   │
│ [Jupiter-Hymne__________________]       │
│                                         │
│ Komponist                               │
│ [Gustav Holst___________________]       │
│                                         │
│ Arrangeur (optional)                    │
│ [_______________________________]       │
│                                         │
│ GEMA-Werknummer                         │
│ [5567890____________________] [Suchen]  │
│                                         │
│ ☐ Werk ist gemeinfrei (vor 1920)        │
│                                         │
│ Bemerkung (optional)                    │
│ [Arrangement für Blasorchester__]       │
│                                         │
│           [Abbrechen]  [Speichern]      │
└─────────────────────────────────────────┘
```

**Besonderheiten:**

- **Checkbox „Werk ist gemeinfrei":** Bei aktiviert wird keine Werknummer benötigt (aber Hinweis: „GEMA empfiehlt Werknummer auch für PD-Werke")
- **Button „Suchen":** Startet AI-Suche nur für dieses Stück (wie Flow B, Schritt 1)
- **Pflichtfelder:** Titel, Komponist, Werknummer (außer gemeinfrei)

---

## 6. Flow D: Export

### 6.1 Trigger

- Nutzer: Dirigent, Notenwart, Admin
- Kontext: Meldung im Status `draft`, alle Pflichtfelder ausgefüllt
- Ziel: Meldung exportieren (XML/CSV/PDF)

### 6.2 Ablauf

**Schritt 1: Export-Optionen wählen**

```
┌─────────────────────────────────────────┐
│ ← GEMA-Meldung exportieren              │
├─────────────────────────────────────────┤
│                                         │
│ Frühjahrskonzert 2026                   │
│ 18 Stücke · 12.04.2026                  │
│                                         │
│ Format wählen:                          │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ ☑ GEMA XML (Pflicht)              │   │
│ │   Zur Übermittlung an GEMA        │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ ☐ CSV                             │   │
│ │   Für Backup / Excel              │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ ☐ PDF                             │   │
│ │   Für Papierarchiv / Behörden     │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ────────────────────────────────────    │
│                                         │
│ ⚠ Nach Export ist die Meldung           │
│   nicht mehr änderbar.                  │
│                                         │
│         [Abbrechen]  [Exportieren]      │
└─────────────────────────────────────────┘
```

**Interaktion:**

- **GEMA XML:** Standard aktiviert, nicht abwählbar
- **CSV/PDF:** Optional, mehrfach wählbar
- **Warnung:** Klarer Hinweis auf Read-Only nach Export
- **Button „Exportieren":** Startet Export-Prozess

**Schritt 2: Export läuft**

```
┌─────────────────────────────────────────┐
│ Exportiere Meldung…                     │
├─────────────────────────────────────────┤
│                                         │
│ ⟳ Validiere Daten…              ✓      │
│ ⟳ Generiere GEMA XML…           ⟳      │
│ ○ Generiere CSV…                        │
│                                         │
│                 [Abbrechen]             │
└─────────────────────────────────────────┘
```

**Schritt 3: Export erfolgreich**

```
┌─────────────────────────────────────────┐
│ ✓ Export erfolgreich                    │
├─────────────────────────────────────────┤
│                                         │
│ Frühjahrskonzert_2026_GEMA.xml          │
│ Frühjahrskonzert_2026.csv               │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ [Teilen]                          │   │
│ │ E-Mail · Cloud · Dateien-App      │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ [Lokal speichern]                 │   │
│ │ Downloads-Ordner                  │   │
│ └───────────────────────────────────┘   │
│                                         │
│                 [Fertig]                │
└─────────────────────────────────────────┘
```

**Interaktion:**

- **„Teilen":** Öffnet native Share-Sheet (iOS/Android) bzw. File-Save-Dialog (Desktop)
- **„Lokal speichern":** Speichert direkt in Downloads-Ordner (Browser/Desktop)
- **Button „Fertig":** Schließt Dialog, kehrt zu Meldungs-Detail zurück

**Schritt 4: Status „Exportiert"**

```
┌─────────────────────────────────────────┐
│ ← Frühjahrskonzert 2026          ⋮      │
├─────────────────────────────────────────┤
│                                         │
│ Status: Exportiert ✓                    │
│ Exportiert: 15.03.2026 15:42            │
│ von Notenwart: Max Müller               │
│                                         │
│ Format: GEMA XML, CSV                   │
│                                         │
│ ────────────────────────────────────    │
│                                         │
│ Event-Daten (read-only)                 │
│ Datum: 12.04.2026                       │
│ Ort: Stadthalle Musterstadt             │
│ Veranstalter: Musikverein Harmonie e.V. │
│ Art: Konzert (öffentlich)               │
│                                         │
│ Stücke (18, read-only)                  │
│ 1. Radetzky-Marsch (J. Strauß)         │
│    Werknr: 1234567                      │
│ 2. An der schönen blauen Donau         │
│    Werknr: 2234567                      │
│ ⋮                                       │
│                                         │
│ [Erneut exportieren]                    │
└─────────────────────────────────────────┘
```

**Besonderheiten:**

- **Status-Badge „Exportiert":** Grün, oben
- **Timestamp:** Wer, wann exportiert hat
- **Read-Only:** Alle Felder nicht mehr editierbar
- **Button „Erneut exportieren":** Erlaubt erneuten Export in anderen Formaten (ohne Änderung der Daten)
- **Drei-Punkt-Menü (⋮):**
  - Export-History anzeigen
  - PDF erneut generieren
  - Meldung löschen (nur Admin, mit Bestätigung)

---

## 7. Flow E: Verwertungsgesellschaft konfigurieren

### 7.1 Trigger

- Nutzer: Admin
- Kontext: Kapelle-Einstellungen
- Ziel: Verwertungsgesellschaft wählen (GEMA, AKM, SUISA, keine)

### 7.2 Ablauf

**Zugriff:**  
`Profil → Kapelle-Verwaltung → Einstellungen → Abschnitt „GEMA & Meldewesen"`

```
┌─────────────────────────────────────────┐
│ ← Kapelle-Einstellungen                 │
├─────────────────────────────────────────┤
│                                         │
│ KAPELLE (Admin only)                    │
│                                         │
│ ⋮                                       │
│                                         │
│ ═══ GEMA & Meldewesen ═══               │
│                                         │
│ Verwertungsgesellschaft                 │
│ ┌───────────────────────────────────┐   │
│ │ ● GEMA (Deutschland)              │   │
│ │ ○ AKM (Österreich)                │   │
│ │ ○ SUISA (Schweiz)                 │   │
│ │ ○ Keine                           │   │
│ └───────────────────────────────────┘   │
│                                         │
│ GEMA-Reminder                           │
│ ☑ Erinnerung senden, wenn Meldung       │
│   nach 7 Tagen noch nicht exportiert    │
│                                         │
│ Reminder-Empfänger                      │
│ ☑ Dirigent                              │
│ ☑ Notenwart                             │
│ ☐ Admin                                 │
│                                         │
│ ⋮                                       │
│                                         │
└─────────────────────────────────────────┘
```

**Interaktion:**

- **Radio-Buttons:** Nur eine Gesellschaft aktiv
- **„Keine":** Deaktiviert GEMA-Features komplett (Export-Button nicht sichtbar)
- **Auto-Save:** Änderung wird sofort übernommen (Toast: „Verwertungsgesellschaft geändert: GEMA")
- **Reminder-Settings:** Optional, Standard 7 Tage nach Event-Datum

**Hinweis:**  
Bei Wechsel der Gesellschaft **nach** bereits existierenden Meldungen → Warnung:

```
┌─────────────────────────────────────────┐
│ ⚠ Verwertungsgesellschaft ändern?       │
├─────────────────────────────────────────┤
│                                         │
│ Du hast bereits 3 GEMA-Meldungen        │
│ erstellt.                               │
│                                         │
│ Bei Wechsel zu AKM werden diese         │
│ Meldungen nicht gelöscht, aber neue     │
│ Meldungen verwenden das AKM-Format.     │
│                                         │
│       [Abbrechen]  [Trotzdem ändern]    │
└─────────────────────────────────────────┘
```

---

## 8. Flow F: Meldungs-Historie

### 8.1 Trigger

- Nutzer: Alle Rollen (Sichtbarkeit nach Permission)
- Kontext: Übersicht aller GEMA-Meldungen
- Ziel: Audit-Trail, Re-Export, Suche

### 8.2 Liste

**Zugriff:**  
`Profil → Kapelle-Verwaltung → GEMA-Meldungen`

```
┌─────────────────────────────────────────┐
│ ← GEMA-Meldungen              [+ Neu]   │
├─────────────────────────────────────────┤
│                                         │
│ [Suche: Veranstaltung, Datum…]  🔍      │
│                                         │
│ Filter: [Alle ▼] [Jahr: 2026 ▼]        │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ Frühjahrskonzert 2026         ✓   │   │
│ │ 12.04.2026 · 18 Stücke            │   │
│ │ Exportiert: 15.03.2026            │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ Weihnachtskonzert 2025        ✓   │   │
│ │ 20.12.2025 · 15 Stücke            │   │
│ │ Exportiert: 18.12.2025            │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ Sommerkonzert 2025       Entwurf  │   │
│ │ 22.06.2025 · 20 Stücke            │   │
│ │ ⚠ Reminder: 7 Tage überfällig     │   │
│ └───────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Element-Details:**

- **Icon ✓:** Exportiert
- **Badge „Entwurf":** Orange
- **Warnung „Reminder überfällig":** Rot, wenn Reminder-Deadline überschritten
- **Filter „Alle":** Alle / Nur Entwürfe / Nur Exportiert
- **Filter „Jahr":** Dropdown mit Jahren (automatisch aus bestehenden Meldungen)

**Tap auf Karte:** Öffnet Meldungs-Detail (Flow C oder Schritt 4 Flow D, je nach Status)

---

## 9. Edge Cases & Error States

### 9.1 Keine Setlist verfügbar

```
┌─────────────────────────────────────────┐
│ Neue GEMA-Meldung                       │
├─────────────────────────────────────────┤
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ Keine Setlists gefunden           │   │
│ │                                   │   │
│ │ Erstelle zuerst ein Konzert       │   │
│ │ mit Setlist.                      │   │
│ │                                   │   │
│ │ [Zu Setlists]                     │   │
│ └───────────────────────────────────┘   │
│                                         │
│                 [Abbrechen]             │
└─────────────────────────────────────────┘
```

### 9.2 AI-Suche fehlgeschlagen

```
┌─────────────────────────────────────────┐
│ ⚠ AI-Suche fehlgeschlagen               │
├─────────────────────────────────────────┤
│                                         │
│ Die Verbindung zur GEMA-Datenbank       │
│ konnte nicht hergestellt werden.        │
│                                         │
│ Mögliche Ursachen:                      │
│ • Netzwerkfehler                        │
│ • GEMA-API nicht erreichbar             │
│ • Rate-Limit überschritten              │
│                                         │
│       [Abbrechen]  [Erneut versuchen]   │
└─────────────────────────────────────────┘
```

**Nach Retry:** Falls erneut fehlgeschlagen → Hinweis „Bitte trage Werknummern manuell ein."

### 9.3 Verwertungsgesellschaft nicht konfiguriert

Falls keine Gesellschaft gewählt:

```
┌─────────────────────────────────────────┐
│ ⚠ GEMA nicht aktiviert                  │
├─────────────────────────────────────────┤
│                                         │
│ Die Verwertungsgesellschaft ist         │
│ noch nicht konfiguriert.                │
│                                         │
│ Bitte wähle in den Kapelle-             │
│ Einstellungen eine Gesellschaft         │
│ (GEMA, AKM, SUISA).                     │
│                                         │
│       [Abbrechen]  [Einstellungen]      │
└─────────────────────────────────────────┘
```

**Button „Einstellungen":** Öffnet direkt Flow E

### 9.4 Export-Fehler (Validation Failed)

```
┌─────────────────────────────────────────┐
│ ⚠ Export fehlgeschlagen                 │
├─────────────────────────────────────────┤
│                                         │
│ 3 Stücke ohne Werknummer:               │
│ • Jupiter-Hymne                         │
│ • Slawischer Tanz Nr. 1                 │
│ • Ungarischer Tanz Nr. 5                │
│                                         │
│ Bitte vervollständige alle Pflicht-     │
│ felder vor dem Export.                  │
│                                         │
│       [Abbrechen]  [Bearbeiten]         │
└─────────────────────────────────────────┘
```

**Button „Bearbeiten":** Schließt Dialog, scrollt zu erstem fehlendem Stück

### 9.5 Setlist geändert nach Meldungserstellung

```
┌─────────────────────────────────────────┐
│ ⚠ Setlist wurde geändert                │
├─────────────────────────────────────────┤
│                                         │
│ Die Setlist „Frühjahrskonzert 2026"     │
│ wurde nach Erstellung der Meldung       │
│ geändert.                               │
│                                         │
│ Änderungen:                             │
│ + 2 Stücke hinzugefügt                  │
│ - 1 Stück entfernt                      │
│                                         │
│ Möchtest du die Meldung aktualisieren?  │
│                                         │
│ ⚠ Bei Status „Exportiert" ist eine      │
│   Änderung nicht möglich.               │
│                                         │
│       [Abbrechen]  [Aktualisieren]      │
└─────────────────────────────────────────┘
```

**Button „Aktualisieren":**
- Nur bei Status `draft`
- Fügt neue Stücke hinzu, markiert gelöschte Stücke (aber löscht sie nicht aus Meldung)

### 9.6 Gemeinfreies Werk ohne Werknummer

```
┌───────────────────────────────────┐
│ Werk ist gemeinfrei               │
│                                   │
│ ☑ Werk ist gemeinfrei (vor 1920)  │
│                                   │
│ ℹ GEMA empfiehlt die Angabe einer │
│   Werknummer auch für gemeinfreie │
│   Werke (z.B. für Arrangements).  │
│                                   │
│ [Trotzdem ohne Werknummer]        │
│ [Werknummer hinzufügen]           │
└───────────────────────────────────┘
```

---

## 10. Wireframes: Phone

### 10.1 Meldungs-Liste (Portrait)

```
┌─────────────────────┐
│ ← GEMA-Meldungen    │▒
├─────────────────────┤▒
│ [Suche…]        🔍  │▒
│                     │▒
│ Filter: [Alle ▼]    │▒
│                     │▒
│ ┌─────────────────┐ │▒
│ │ Frühjahrskonzert│ │▒
│ │ 12.04.26 · 18   │ │▒
│ │ Exportiert ✓    │ │▒
│ └─────────────────┘ │▒
│ ┌─────────────────┐ │▒
│ │ Weihnachtskonz. │ │▒
│ │ 20.12.25 · 15   │ │▒
│ │ Exportiert ✓    │ │▒
│ └─────────────────┘ │▒
│ ┌─────────────────┐ │▒
│ │ Sommerkonzert   │ │▒
│ │ 22.06.25 · 20   │ │▒
│ │ Entwurf ⚠       │ │▒
│ └─────────────────┘ │▒
│                     │▒
│                     │▒
│                     │▒
├─────────────────────┤
│ ┌─────────────────┐ │
│ │   [+ Neu]       │ │
│ └─────────────────┘ │
└─────────────────────┘
   ← 44px Button
```

- **Liste:** Scrollable
- **Button „+ Neu":** Sticky Bottom Button (44px hoch, 16px Abstand unten)

### 10.2 Meldungs-Detail (Draft, Portrait)

```
┌─────────────────────┐
│ ← Frühjahrskonz. ⋮ │▒
├─────────────────────┤▒
│ Status: Entwurf     │▒
│ 15.03.26 · Max      │▒
│                     │▒
│ ⚠ 1 Stück ohne WNr  │▒
│                     │▒
│ Event-Daten         │▒
│ 12.04.2026          │▒
│ Stadthalle Muster…  │▒
│           [Edit]    │▒
│ ────────────────    │▒
│ Stücke (18)         │▒
│ [AI] [+ Stück]      │▒
│                     │▒
│ ┌─────────────────┐ │▒
│ │ 1. Radetzky-M.  │ │▒
│ │ J. Strauß       │ │▒
│ │ WNr: 1234567 ✓  │ │▒
│ └─────────────────┘ │▒
│ ┌─────────────────┐ │▒
│ │ 2. Donau   ✎    │ │▒
│ │ J. Strauß       │ │▒
│ │ WNr: 2234567 ✓  │ │▒
│ │ (AI 95%)        │ │▒
│ └─────────────────┘ │▒
│ ┌─────────────────┐ │▒
│ │ 3. Jupiter ⚠    │ │▒
│ │ Unbekannt       │ │▒
│ │ [WNr eingeben]  │ │▒
│ └─────────────────┘ │▒
│                     │▒
│ ⋮                   │▒
├─────────────────────┤
│ ┌─────────────────┐ │
│ │  [Exportieren]  │ │
│ └─────────────────┘ │
└─────────────────────┘
```

- **Button „AI":** Startet AI-Suche für alle fehlenden
- **Button „+ Stück":** Manuelles Hinzufügen
- **Button „Export":** Sticky Bottom

### 10.3 AI-Suchergebnisse (Portrait)

```
┌─────────────────────┐
│ ← AI-Ergebnisse     │▒
├─────────────────────┤▒
│ 4 von 5 gefunden    │▒
│                     │▒
│ ┌─────────────────┐ │▒
│ │☑ Donau          │ │▒
│ │  WNr: 2234567   │ │▒
│ │  Conf: 95% ✓    │ │▒
│ │  Strauß (Sohn)  │ │▒
│ └─────────────────┘ │▒
│ ┌─────────────────┐ │▒
│ │☑ Böhmischer T.  │ │▒
│ │  WNr: 3345678   │ │▒
│ │  Conf: 78%      │ │▒
│ │  Ernst Mohr     │ │▒
│ └─────────────────┘ │▒
│ ┌─────────────────┐ │▒
│ │☐ Slawischer T.  │ │▒
│ │  WNr: 4456789   │ │▒
│ │  Conf: 42% ⚠    │ │▒
│ │  Dvořák         │ │▒
│ └─────────────────┘ │▒
│                     │▒
│ ⚠ Jupiter-Hymne:    │▒
│   Keine Ergebnisse  │▒
│         [Manuell]   │▒
│                     │▒
├─────────────────────┤
│ [Alle ab]  [Übern.] │
└─────────────────────┘
```

### 10.4 Export-Dialog (Portrait)

```
┌─────────────────────┐
│ ← Export            │
├─────────────────────┤
│ Frühjahrskonz. 2026 │
│ 18 Stücke · 12.04.26│
│                     │
│ Format:             │
│ ┌─────────────────┐ │
│ │☑ GEMA XML       │ │
│ │  (Pflicht)      │ │
│ └─────────────────┘ │
│ ┌─────────────────┐ │
│ │☐ CSV            │ │
│ │  Backup/Excel   │ │
│ └─────────────────┘ │
│ ┌─────────────────┐ │
│ │☐ PDF            │ │
│ │  Papierarchiv   │ │
│ └─────────────────┘ │
│                     │
│ ⚠ Nach Export nicht │
│   änderbar.         │
│                     │
├─────────────────────┤
│ [Abbr.] [Exportier.]│
└─────────────────────┘
```

---

## 11. Wireframes: Tablet

### 11.1 Meldungs-Liste (Landscape, Split-View)

```
┌─────────────────────────────────────────────────────────────────┐
│ ← GEMA-Meldungen                                  [+ Neue Meldung]│
├───────────────────────┬─────────────────────────────────────────┤
│ [Suche…]          🔍  │ Frühjahrskonzert 2026            ⋮      │
│ Filter: [Alle ▼]      │ ─────────────────────────────────────── │
│                       │ Status: Exportiert ✓                    │
│ ┌───────────────────┐ │ Exportiert: 15.03.2026 15:42            │
│ │ Frühjahrskonzert  │◄│ von Notenwart: Max Müller               │
│ │ 12.04.26 · 18     │ │                                         │
│ │ Exportiert ✓      │ │ Event-Daten                             │
│ └───────────────────┘ │ Datum: 12.04.2026                       │
│ ┌───────────────────┐ │ Ort: Stadthalle Musterstadt             │
│ │ Weihnachtskonzert │ │ Veranstalter: Musikverein Harmonie e.V. │
│ │ 20.12.25 · 15     │ │ Art: Konzert (öffentlich)               │
│ │ Exportiert ✓      │ │                                         │
│ └───────────────────┘ │ ─────────────────────────────────────── │
│ ┌───────────────────┐ │                                         │
│ │ Sommerkonzert     │ │ Stücke (18, read-only)                  │
│ │ 22.06.25 · 20     │ │                                         │▒
│ │ Entwurf ⚠         │ │ 1. Radetzky-Marsch (J. Strauß)         │▒
│ └───────────────────┘ │    Werknr: 1234567                      │▒
│                       │                                         │▒
│                       │ 2. An der schönen blauen Donau         │▒
│                       │    Werknr: 2234567                      │▒
│                       │                                         │▒
│                       │ ⋮                                       │▒
│                       │                                         │▒
│                       │ [Erneut exportieren]                    │
└───────────────────────┴─────────────────────────────────────────┘
   ← 320px List         ← Detail View
```

- **Split-View:** Liste links (320px), Detail rechts
- **Selection:** Aktive Karte hervorgehoben (`◄`)
- **Detail:** Direkt neben Liste, read-only bei Status „Exportiert"

### 11.2 Meldungs-Detail (Draft, Landscape)

```
┌─────────────────────────────────────────────────────────────────┐
│ ← Frühjahrskonzert 2026                     ⋮        [Export]   │
├───────────────────────┬─────────────────────────────────────────┤
│ Status: Entwurf       │ Stücke (18)          [AI-Suche] [+ Stück]│
│ 15.03.2026 · Max      │                                         │
│                       │ ┌─────────────────────────────────────┐ │
│ ⚠ 1 Stück ohne WNr    │ │ 1. Radetzky-Marsch                  │ │▒
│                       │ │    J. Strauß · Werknr: 1234567 ✓    │ │▒
│ Event-Daten           │ └─────────────────────────────────────┘ │▒
│ Datum: 12.04.2026     │ ┌─────────────────────────────────────┐ │▒
│ Ort: Stadthalle       │ │ 2. An der schönen blauen Donau   ✎  │ │▒
│      Musterstadt      │ │    J. Strauß (Sohn)                 │ │▒
│ Veranstalter:         │ │    Werknr: 2234567 ✓ (AI 95%)       │ │▒
│   Musikverein         │ └─────────────────────────────────────┘ │▒
│   Harmonie e.V.       │ ┌─────────────────────────────────────┐ │▒
│ Art: Konzert          │ │ 3. Jupiter-Hymne                ⚠   │ │▒
│      (öffentlich)     │ │    Unbekannt                        │ │▒
│                       │ │    Werknummer: [_______] [Suchen]   │ │▒
│ [Event bearbeiten]    │ └─────────────────────────────────────┘ │▒
│                       │                                         │▒
│                       │ ⋮                                       │▒
│                       │                                         │
└───────────────────────┴─────────────────────────────────────────┘
   ← 280px Sidebar      ← Stück-Liste (scrollable)
```

- **Sidebar:** Event-Daten + Warnung (sticky)
- **Hauptbereich:** Stück-Liste mit Inline-Edit
- **Buttons:** Top-right Toolbar

---

## 12. Accessibility

### 12.1 Touch Targets

- **Minimum:** 44×44px (alle interaktiven Elemente)
- **Stück-Karten:** Mind. 56px hoch (für präzises Tapping)
- **Checkboxen:** 24×24px Icon + 44×44px Tap-Area

### 12.2 Kontrast & Farben

- **Status-Badges:**
  - Entwurf: Orange `#D97706` + Icon ●
  - Exportiert: Green `#16A34A` + Icon ✓
- **Confidence-Levels:**
  - Sehr sicher: Green + ✓
  - Wahrscheinlich: Blue + –
  - Unsicher: Orange + ⚠
  - Nicht verwenden: Red + ✗
- **Keine Farbe als einzige Signalquelle:** Immer mit Icon kombiniert

### 12.3 Keyboard Navigation (Desktop)

- **Tab-Reihenfolge:** Logisch von oben nach unten
- **Enter:** Bestätigen / Öffnen
- **Escape:** Dialog schließen
- **Arrow Keys:** In Stück-Liste navigieren
- **Shortcuts:**
  - `Cmd/Ctrl + N`: Neue Meldung
  - `Cmd/Ctrl + E`: Export
  - `Cmd/Ctrl + F`: Suche

### 12.4 Screen Reader

- **Aria-Labels:**
  - Stück-Karten: „Radetzky-Marsch, Johann Strauß, Werknummer vorhanden"
  - Confidence: „Confidence 95%, sehr sicher"
  - Status-Badge: „Status: Entwurf"
- **Live Regions:**
  - AI-Suche-Progress: „Suche läuft, 2 von 5 Stücke durchsucht"
  - Export-Status: „Export erfolgreich, 2 Dateien erstellt"

---

## 13. Abhängigkeiten

### 13.1 Backend-API

- **Endpoints:** `/api/v1/kapellen/{kapelleId}/gema-meldungen/*`
- **AI-Service:** Azure OpenAI (MS2), später GEMA-API (MS3+)
- **Export-Formate:** XML-Generator, CSV-Generator, PDF-Generator
- **Reminder-Service:** Background-Job für Notifications

### 13.2 Frontend-Komponenten

- **Neu:**
  - `GemaMeldungListView`
  - `GemaMeldungDetailView`
  - `GemaMeldungExportDialog`
  - `AiSearchResultDialog`
  - `StueckEditSheet` (Bottom Sheet Phone, Modal Tablet)
- **Bestehend (reuse):**
  - `SetlistPicker`
  - `DatePicker`
  - `FormField` (aus `ux-konfiguration`)
  - `ConfidenceBadge` (neu, aber ähnlich wie `StatusBadge`)
  - `ToastNotification`

### 13.3 Permissions

- **Admin:** Full CRUD, Config ändern, History löschen
- **Dirigent:** CRUD eigene Meldungen, AI-Suche, Export
- **Notenwart:** CRUD eigene Meldungen, AI-Suche, Export
- **Registerführer:** Read-only History
- **Musiker:** Read-only History (optional, per Kapelle-Policy)

### 13.4 Offline-Verhalten

- **Draft-Meldungen:** Offline erstellbar, später sync
- **AI-Suche:** Nur online (Fehlermeldung + Retry)
- **Export:** Nur online (XML-Validation benötigt Backend)
- **History:** Cached, offline lesbar

---

**Ende UX-Spec GEMA-Compliance**
