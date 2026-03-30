# UX-Spec: Cloud-Sync (Persönliche Sammlung)

> **Issue:** MS3 — Cloud-Sync  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-31  
> **Meilenstein:** MS3 — Tuner + Echtzeit-Klick + Cloud-Sync  
> **Referenzen:** `docs/meilensteine.md §MS3`, `docs/ux-design.md`, `docs/ux-konfiguration.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Designprinzipien](#1-übersicht--designprinzipien)
2. [User Flow: Erste Sync nach Login](#2-user-flow-erste-sync-nach-login)
3. [User Flow: Sync auf neuem Gerät](#3-user-flow-sync-auf-neuem-gerät)
4. [Sync-Status-Anzeige](#4-sync-status-anzeige)
5. [Konflikt-Auflösung UI](#5-konflikt-auflösung-ui)
6. [Offline-Indikator](#6-offline-indikator)
7. [Sync-Einstellungen](#7-sync-einstellungen)
8. [Micro-Interactions & Animationen](#8-micro-interactions--animationen)
9. [Wireframes: Phone](#9-wireframes-phone)
10. [Wireframes: Tablet & Desktop](#10-wireframes-tablet--desktop)
11. [Accessibility](#11-accessibility)
12. [Responsiveness](#12-responsiveness)
13. [Error States & Edge Cases](#13-error-states--edge-cases)
14. [Integration mit Navigation (GoRouter)](#14-integration-mit-navigation-gorouter)
15. [Abhängigkeiten](#15-abhängigkeiten)

---

## 1. Übersicht & Designprinzipien

### 1.1 Kernsatz

> „Cloud-Sync sollte unsichtbar sein. Der Musiker denkt nicht über Sync nach — er denkt über Musik nach."

Cloud-Sync ist erfolgreich, wenn der Nutzer es **nie bemerkt**. Es läuft im Hintergrund. Nur wenn etwas schiefgeht oder der Nutzer explizit nachschaut, wird es sichtbar.

### 1.2 Was wird synchronisiert?

| Datentyp | Sync? | Richtung | Konfliktbehandlung |
|----------|-------|----------|---------------------|
| Noten (PDF-Dateien) | ✅ | Bidirektional | Last-Write-Wins |
| Stücke-Metadaten | ✅ | Bidirektional | Last-Write-Wins per Feld |
| Persönliche Annotationen | ✅ | Bidirektional | Last-Write-Wins per Annotation |
| Setlisten | ✅ | Bidirektional | Last-Write-Wins |
| Geräte-Einstellungen | ❌ | Nur lokal | — |
| Kapellen-Daten | ❌ | Server-getrieben | — |

### 1.3 Designprinzipien

| Prinzip | Auswirkung |
|---------|-----------|
| **Unsichtbar wenn OK** | Sync-Status zeigt keine "OK"-Anzeige im Hauptflow |
| **Transparent bei Problemen** | Konflikte und Fehler werden klar kommuniziert |
| **Nie blockierend** | Offline arbeiten ist immer möglich, kein Warte-Dialog |
| **Daten nie verloren** | Konflikte werden angezeigt, nie still überschrieben |

---

## 2. User Flow: Erste Sync nach Login

```
Login / Registrierung abgeschlossen
        │
        ▼
  App prüft: Gibt es Cloud-Daten für diesen Account?
        │
        ├──── Nein (neuer Account) → Bibliothek leer → Ende
        │
        └──── Ja (Daten vorhanden) → Sync-Dialog anzeigen (§2.1)
                      │
                      ▼
              Nutzer tippt [Noten laden]
                      │
                      ▼
              Download läuft (Progress-Anzeige)
                      │
                      ▼
              Bibliothek gefüllt → Sync abgeschlossen
```

### 2.1 Erster-Sync-Dialog

```
┌─────────────────────────────────────────────────┐
│  ☁ Deine Noten warten                          │
│                                                 │
│  In deiner Sheetstorm-Cloud sind               │
│  24 Stücke gespeichert.                        │
│                                                 │
│  Sollen sie auf dieses Gerät geladen werden?   │
│                                                 │
│  Speicherbedarf: ~45 MB                        │
│                                                 │
│  [Jetzt laden]    [Später]                     │
└─────────────────────────────────────────────────┘
```

- „Später" → Bibliothek bleibt leer, sync-Badge zeigt `↓ 24 ausstehend`
- „Jetzt laden" → Progress-Anzeige (§8.2)

---

## 3. User Flow: Sync auf neuem Gerät

```
Musiker hat neues Gerät, loggt sich ein
        │
        ▼
  Erster-Sync-Dialog erscheint (§2.1)
        │
        ▼
  Download: N Dateien, M MB
        │
        ▼
  ┌─────────────────────────────────────────────────┐
  │  Konflikte? (lokale Änderungen vs. Cloud)        │
  └────────────────────────────────────────────────-┘
         │ Nein (neues Gerät = keine lokalen Daten) → Fertig
         │
         └──── Ja (sehr selten bei neuem Gerät) → Konflikt-Dialog (§5)
```

---

## 4. Sync-Status-Anzeige

### 4.1 Vier Zustände

| Zustand | Trigger | Anzeige-Position | Verhalten |
|---------|---------|-----------------|-----------|
| **synced** | Alle Daten aktuell | Kein UI (unsichtbar) | Nichts zeigen |
| **syncing** | Upload/Download aktiv | Subtiler Indikator in App-Bar | Auto-verschwindet |
| **conflict** | Konflikt erkannt | Badge + Banner | Bleibt bis aufgelöst |
| **offline** | Keine Verbindung | Offline-Banner | Bleibt bis online |

### 4.2 Syncing-Indikator

Kleines rotierendes Sync-Icon in der App-Bar (oben rechts, 20×20 px):
- `color-text-secondary` — dezent, nicht ablenkend
- Erscheint nur während aktivem Sync (nicht bei Idle)
- **Nie ein Fortschrittsbalken** im normalen Flow — zu aufdringlich

### 4.3 Sync-Status-Details (auf Nachfrage)

Tippen auf Sync-Icon → Bottom Sheet:

```
┌──────────────────────────────────────┐
│  ────  (Handle)                      │
│  Sync-Status                   ✕     │
│  ────────────────────────────────    │
│  ✓ Zuletzt synchronisiert            │
│    Heute, 14:32                      │
│                                      │
│  Ausstehend: 2 Dateien               │
│  ↑ annotation_bach.json  uploading   │
│  ↑ setlist_probe.json    pending     │
│                                      │
│  ────────────────────────────────    │
│  Speicher: 45 MB von 500 MB genutzt  │
│  ────────────────────────────────    │
│  [Jetzt synchronisieren]             │
└──────────────────────────────────────┘
```

---

## 5. Konflikt-Auflösung UI

### 5.1 Was ist ein Konflikt?

Ein Konflikt entsteht, wenn:
- Dieselbe Datei auf Gerät A **und** auf dem Server geändert wurde, bevor Gerät A wieder online war
- **Selten** bei normalem Gebrauch (Last-Write-Wins per Feld verhindert die meisten Konflikte)

### 5.2 Konflikt-Strategie: Last-Write-Wins, aber Transparent

Die App löst Konflikte **automatisch** (neuester Timestamp gewinnt), aber zeigt dem Nutzer was passiert ist:

**Kein aktiver Entscheidungs-Dialog** — der Nutzer muss nichts tun.

### 5.3 Konflikt-Benachrichtigung (Toast)

Nach automatischer Auflösung:
```
┌──────────────────────────────────────────────┐
│  ℹ Konflikt automatisch gelöst              │
│  "Sonate Nr. 3" — Cloud-Version übernommen  │
│  [Details]                                   │
└──────────────────────────────────────────────┘
```
- Toast erscheint unten (über Bottom-Navigation), 5 Sekunden sichtbar
- „Details" → Konflikt-Detail-Screen

### 5.4 Konflikt-Detail-Screen

```
┌─────────────────────────────────────────────────┐
│ ← Konflikt-Details                              │
│                                                 │
│  Sonate Nr. 3 — Annotationen                   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  ✓ Verwendet: Cloud-Version             │   │
│  │  Geändert: 14. März · 14:32             │   │
│  │  Gerät: iPhone von Thomas               │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  ✗ Verworfen: Lokale Version            │   │
│  │  Geändert: 14. März · 14:28             │   │
│  │  Gerät: Dieses Gerät (iPad)             │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ─────────────────────────────────────────────  │
│  [↩ Lokale Version wiederherstellen]            │
│                                                 │
│  Achtung: Die Cloud-Version geht dabei verloren │
│                                                 │
└─────────────────────────────────────────────────┘
```

- **Wiederherstellen-Option** vorhanden — für den Fall dass Last-Write-Wins falsch lag
- Wiederherstellung erfordert **explizites Bestätigen** (Destructive Action)

### 5.5 Konflikt-Indikator in der Bibliothek

Stück mit unaufgelöstem Konflikt (wenn manuelle Entscheidung benötigt wird — zukünftige Erweiterung):
```
Sonate Nr. 3    ⚠ Konflikt
```
- Kleines Warn-Icon neben dem Stücknamen
- `color-warning`

---

## 6. Offline-Indikator

### 6.1 Offline-Banner

```
┌──────────────────────────────────────────────────┐
│  ✗ Offline — Änderungen werden gespeichert       │
│  und beim nächsten Online-Gang synchronisiert.   │
└──────────────────────────────────────────────────┘
```

- Position: Oben in der App (unter der App-Bar)
- Hintergrundfarbe: `color-warning` mit 15% Opacity, Border `color-warning`
- Text: `color-warning` dunkel
- **Nie blockierend** — der Nutzer kann normal weiterarbeiten
- Verschwindet automatisch, wenn Verbindung wiederhergestellt

### 6.2 Offline-Verhalten

| Aktion | Offline-Verhalten |
|--------|------------------|
| Noten anzeigen | ✅ Funktioniert (lokal gecacht) |
| Annotationen hinzufügen | ✅ Lokal gespeichert, sync ausstehend |
| Neue Noten importieren | ✅ Lokal gespeichert |
| Setlist erstellen | ✅ Lokal gespeichert |
| Kapellen-Daten laden | ❌ Zeigt gecachte Daten |
| Sync-Status prüfen | ℹ Zeigt „Offline seit [Zeit]" |

### 6.3 Offline-seit-Anzeige

Im Sync-Status-Sheet (§4.3) wenn offline:
```
✗ Offline seit 09:45 Uhr
  23 lokale Änderungen ausstehend
```

---

## 7. Sync-Einstellungen

### 7.1 Zugang

Einstellungen → Meine Musik → Sync

### 7.2 Sync-Einstellungs-Screen

```
┌─────────────────────────────────────────┐
│ ←  Sync-Einstellungen                   │
│                                         │
│  ● Automatischer Sync         EIN       │
│  Immer im Hintergrund aktiv             │
│                                         │
│  ─────────────────────────────────────  │
│  ● Nur über WLAN              EIN       │
│  Kein Mobile-Daten-Verbrauch            │
│                                         │
│  ─────────────────────────────────────  │
│  Speicher                               │
│  Genutzt: 45 MB von 500 MB             │
│  ████░░░░░░░░░░░░░  9%                 │
│                                         │
│  ─────────────────────────────────────  │
│  [Jetzt synchronisieren]               │
│  [Lokalen Cache leeren]                │  ← Destructive
│                                         │
│  ─────────────────────────────────────  │
│  Zuletzt synchronisiert:               │
│  Heute, 14:32 Uhr                      │
└─────────────────────────────────────────┘
```

---

## 8. Micro-Interactions & Animationen

### 8.1 Sync-Icon

- **Syncing:** Rotation-Animation, 1 Umdrehung/Sekunde, `AppCurves.linear`
- **Sync abgeschlossen:** Icon stoppt + kurz grüner Checkmark-Flash (300ms), dann verschwindet
- **Fehler:** Icon wechselt zu Warn-Icon (250ms, `AppCurves.easeOut`)

### 8.2 Erster-Download Progress

```
┌────────────────────────────────────────┐
│  Noten werden geladen...               │
│  ████████████░░░░░░░░  14 / 24 Stücke  │
│                                        │
│  "Sonate Nr. 3.pdf" · 2,1 MB          │  ← Aktuell geladene Datei
└────────────────────────────────────────┘
```

- Fortschrittsbalken: `AppColors.primary` Hintergrund, animiert
- Zähler: `N / M Stücke`
- Dateiname: aktuell downloadende Datei
- Keine Abbrechen-Option während erstem Sync (zu komplex, zu selten benötigt)

### 8.3 Bibliothek: Stück erscheint nach Download

- Neue Stücke werden in der Bibliothek mit `fade-in + slide-up` eingeblendet
- `AppDurations.base` (250ms), `AppCurves.easeOut`
- Nicht als Batch (alle 24 auf einmal) sondern einzeln, sobald verfügbar

### 8.4 Offline → Online Transition

- Banner verschwindet mit `fade-out`, 300ms
- Sync-Icon erscheint kurz (Background-Sync startet)
- Toast: `✓ Wieder online · 23 Änderungen werden synchronisiert`

---

## 9. Wireframes: Phone

### 9.1 Bibliothek mit Sync-Status (normal)

```
┌───────────────────────────┐
│ ●●●●●●●●●●●●●●●●●●●●●●● │
├───────────────────────────┤
│ Meine Musik         ↺     │  ← Sync-Icon (nur während Sync sichtbar)
├───────────────────────────┤
│ ┌─────────────────────┐   │
│ │ 🔍 Suchen...        │   │
│ └─────────────────────┘   │
├───────────────────────────┤
│ ┌───────────────────────┐ │
│ │ Sonate Nr. 1          │ │
│ │ Bach · PDF · 3 Seiten │ │
│ └───────────────────────┘ │
│ ┌───────────────────────┐ │
│ │ Sonate Nr. 2          │ │
│ └───────────────────────┘ │
│ ...                       │
├───────────────────────────┤
│ 🎵  📚  🔧  👤            │
└───────────────────────────┘
```

### 9.2 Bibliothek Offline

```
┌───────────────────────────┐
│ ●●●●●●●●●●●●●●●●●●●●●●● │
├───────────────────────────┤
│ ✗ Offline                 │  ← Banner
├───────────────────────────┤
│ Meine Musik               │
├───────────────────────────┤
│ (normaler Inhalt)         │
└───────────────────────────┘
```

### 9.3 Erster Sync (Phone)

```
┌───────────────────────────┐
│ ●●●●●●●●●●●●●●●●●●●●●●● │
├───────────────────────────┤
│ Meine Musik               │
├───────────────────────────┤
│                           │
│   ┌─────────────────────┐ │
│   │  Noten werden       │ │
│   │  geladen...         │ │
│   │                     │ │
│   │  ████████░░░  14/24 │ │
│   │                     │ │
│   │  Sonate Nr.3.pdf    │ │
│   └─────────────────────┘ │
│                           │
│ ┌───────────────────────┐ │  ← Bereits geladene Stücke erscheinen
│ │ Sonate Nr. 1          │ │    während Download läuft
│ └───────────────────────┘ │
└───────────────────────────┘
```

---

## 10. Wireframes: Tablet & Desktop

### 10.1 Tablet: Bibliothek mit Sync-Details (Sidebar)

```
┌────────────────────────────────────────────────────┐
│  Meine Musik                              ↺ 14:32  │
├───────────────────────────┬────────────────────────┤
│  🔍 Suchen...             │  Sync-Status           │
├───────────────────────────┤  ✓ Synchronisiert      │
│ ● Sonate Nr. 1            │  14:32 Uhr             │
│ ● Sonate Nr. 2            │                        │
│ ● Sonate Nr. 3  ⚠        │  Speicher: 45/500 MB   │
│ ...                       │  ████░░░ 9%            │
│                           │                        │
│                           │  [Sync-Einstellungen]  │
└───────────────────────────┴────────────────────────┘
```

### 10.2 Desktop: Vollständiges Sync-Dashboard

```
┌────────────────────────────────────────────────────────────┐
│  Sheetstorm · Meine Musik            ↺ Synchronisiert      │
├────────────────────────────────────────────────────────────┤
│  Bibliothek                   │  Sync-Status               │
│                               │  ─────────────────────     │
│  🔍 Suchen...                 │  ✓ Alle Daten aktuell      │
│                               │  Letzte Sync: 14:32        │
│  📁 Alle Stücke (24)          │                            │
│  📁 Favoriten (8)             │  Speicher                  │
│  📁 Letzte Bearbeitung        │  45 MB / 500 MB            │
│                               │  ███░░░░░░░░░░  9%         │
│  ─────────────────────────    │                            │
│  ● Sonate Nr. 1               │  ─────────────────────     │
│  ● Sonate Nr. 2               │  [Jetzt synchronisieren]  │
│  ● Sonate Nr. 3  ⚠ Konflikt  │  [Einstellungen]          │
│  ...                          │                            │
└───────────────────────────────┴────────────────────────────┘
```

---

## 11. Accessibility

### 11.1 Touch-Targets

| Element | Mindestgröße |
|---------|-------------|
| Sync-Icon (App-Bar) | 44×44 px |
| „Jetzt laden"-Button | 44×44 px |
| Konflikt-Details-Button | 44×44 px |
| Offline-Banner (Info) | — (kein Touch nötig) |

### 11.2 Screen-Reader

- **Sync-Icon:** `Semantics(label: "Synchronisierung läuft")` / `"Synchronisiert"` / `"Sync-Fehler"`
- **Offline-Banner:** `Semantics(liveRegion: true, label: "Offline. Änderungen werden gespeichert.")` — automatische Ankündigung bei Statuswechsel
- **Konflikt-Toast:** `Semantics(liveRegion: true)` — angekündigt sobald erscheint

### 11.3 Status-Änderungen ankündigen

- Online → Offline: Screen-Reader kündigt an: „Verbindung unterbrochen. App funktioniert weiter."
- Offline → Online: „Verbindung wiederhergestellt. Synchronisierung läuft."

---

## 12. Responsiveness

| Breakpoint | Sync-Status-Position |
|------------|---------------------|
| Phone | Sync-Icon in App-Bar; Details als Bottom Sheet |
| Tablet | Sync-Icon in App-Bar; Details als Sidebar-Panel |
| Desktop | Permanente Sync-Status-Sidebar im Bibliothek-Screen |

---

## 13. Error States & Edge Cases

### 13.1 Sync-Fehler (Netzwerk)

```
┌──────────────────────────────────────────────┐
│  ✗ Sync fehlgeschlagen                       │
│  Verbindungsproblem · 14:45 Uhr             │
│  [Erneut versuchen]                          │
└──────────────────────────────────────────────┘
```

- Toast + Badge auf Sync-Icon
- Auto-Retry: alle 30 Sekunden (unsichtbar)
- Manuelle Retry-Option immer verfügbar

### 13.2 Speicher voll (Cloud)

```
┌─────────────────────────────────────────────────┐
│  ⚠ Cloud-Speicher fast voll                    │
│  480 MB von 500 MB genutzt.                    │
│  Ältere Noten können gelöscht werden.           │
│  [Speicher verwalten]                           │
└─────────────────────────────────────────────────┘
```

- Erscheint beim nächsten Sync-Status-Check
- Kein Blocking — der Nutzer kann weiterarbeiten

### 13.3 Speicher voll (lokal)

- Selten auf modernen Geräten
- Toast: `⚠ Gerätespeicher voll · PDF kann nicht gespeichert werden`

### 13.4 Datei-Korruption

- Wenn SHA-Prüfung fehlschlägt: Datei erneut herunterladen (automatisch, silent)
- Falls zweiter Versuch auch fehlschlägt: Nutzer informieren

### 13.5 Differenz zwischen Geräten sehr groß (100+ Dateien)

- Statt einzelner Dateinamen: `"124 Stücke werden synchronisiert..."`
- Kein Einzeldatei-Listing bei großen Mengen

### 13.6 Account-Wechsel

- Beim Abmelden: Nutzer fragt: „Lokale Noten entfernen?"
- Default: Lokale Noten bleiben (kein versehentlicher Datenverlust)

---

## 14. Integration mit Navigation (GoRouter)

### 14.1 Routen

```
/library                       → Bibliothek (Sync-Icon in App-Bar)
/settings/sync                 → Sync-Einstellungen
/library/conflict/:id          → Konflikt-Detail-Screen
```

### 14.2 Sync-Icon Platzierung

- **Alle Screens mit App-Bar:** Sync-Icon erscheint als drittes Icon rechts (nach Suche, Filter)
- **Spielmodus:** Kein Sync-Icon (Focus-First — kein Sync-Status im Performance-Mode)

---

## 15. Abhängigkeiten

### 15.1 Für Implementierung (Hill / Banner)

- **Delta-Sync mit Versionierung:** Backend muss Versionsnummern pro Datei speichern
- **Last-Write-Wins per Feld:** Metadaten-Felder haben eigene Timestamps
- **Offline-Queue:** Lokale Änderungen werden in SQLite/Drift Queue gespeichert
- **Conflict-Log:** Backend speichert aufgelöste Konflikte für 30 Tage (für "Details"-View)

### 15.2 Offene Entscheidungen für Thomas

- **Speicherlimit pro Account:** 500 MB vorgeschlagen — realistisch für Blaskapellen-Repertoire?
- **Konflikt-Benachrichtigung:** Toast ist minimal-invasiv. Soll es auch eine Push-Notification geben?
