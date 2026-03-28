# Sheetstorm — Konfigurationskonzept

> **Version:** 2.0  
> **Autor:** Stark (Lead / Architect)  
> **Datum:** 2026-03-28  
> **Status:** Zur Abstimmung via PR  
> **Meilenstein:** MS1 (Kernfunktionalität)

---

## 1. Übersicht

Sheetstorm verwendet ein **3-Ebenen-Konfigurationssystem**, das die Anforderungen von Blaskapellen-Vereinen abbildet: Organisatorische Vorgaben, persönliche Präferenzen und geräteabhängige Einstellungen.

```
┌─────────────────────────────────────────────┐
│  System-Default (hartcodiert, nicht änderbar)│
├─────────────────────────────────────────────┤
│  Ebene 1: Kapelle (Organisation)            │
│  → Ändert: Admin, teilweise Dirigent        │
├─────────────────────────────────────────────┤
│  Ebene 2: Nutzer (Persönlich)               │
│  → Ändert: Jeder für sich selbst            │
├─────────────────────────────────────────────┤
│  Ebene 3: Gerät (Lokal)                     │
│  → Ändert: Jeder auf seinem Gerät           │
└─────────────────────────────────────────────┘

Override-Richtung: Gerät > Nutzer > Kapelle > System-Default
```

**Kernprinzip:** Die spezifischere Ebene überschreibt die allgemeinere — es sei denn, eine Policy der Kapelle verbietet das Override.

---

## 2. Ebene 1: Kapelle (Organisation)

### Zweck
Organisationsweite Einstellungen, die für alle Mitglieder einer Kapelle gelten. Setzt den Rahmen, innerhalb dessen Nutzer personalisieren können.

### Wer darf ändern
- **Admin:** Vollzugriff auf alle Kapellen-Einstellungen
- **Dirigent:** Musikalische Einstellungen (Kammerton, Standard-Metronom-BPM)

### Einstellungen

| Schlüssel | Typ | Default | Beschreibung |
|-----------|-----|---------|-------------|
| `kapelle.name` | string | — | Name der Kapelle |
| `kapelle.ort` | string | — | Standort |
| `kapelle.logo` | url | null | Logo für Branding |
| `kapelle.sprache` | locale | "de" | Standard-Sprache für neue Mitglieder |
| `kapelle.ai.provider` | enum | null | AI-Provider (azure_vision, openai_vision, google_vision) |
| `kapelle.ai.api_key` | encrypted | null | Kapellen-weiter AI-API-Key |
| `kapelle.ai.enabled` | bool | false | AI-Features für die Kapelle aktiviert |
| `kapelle.berechtigungen.noten_upload` | role[] | [admin, dirigent, notenwart] | Wer darf Noten hochladen |
| `kapelle.berechtigungen.setlist_erstellen` | role[] | [admin, dirigent, notenwart] | Wer darf Setlists erstellen |
| `kapelle.berechtigungen.termine_erstellen` | role[] | [admin, dirigent] | Wer darf Termine erstellen |
| `kapelle.berechtigungen.annotation_stimme` | role[] | [admin, dirigent, registerfuehrer] | Wer darf Stimmen-Annotationen erstellen |
| `kapelle.berechtigungen.annotation_orchester` | role[] | [admin, dirigent] | Wer darf Orchester-Annotationen erstellen |
| `kapelle.kammerton` | int | 442 | Kammerton A in Hz |
| `kapelle.metronom.default_bpm` | int | 120 | Standard-BPM für Metronom |
| `kapelle.aushilfe.default_ablauf_tage` | int | 7 | Standard-Gültigkeit für Aushilfe-Links |

### Policies (Override-Sperren)

Kapellen-Admins können bestimmte Einstellungen für alle Mitglieder erzwingen:

| Policy | Typ | Default | Effekt |
|--------|-----|---------|--------|
| `policy.force_locale` | bool | false | Sprache kann nicht pro Nutzer überschrieben werden |
| `policy.force_dark_mode` | bool\|null | null | null=frei, true=dark erzwungen, false=light erzwungen |
| `policy.allow_user_ai_keys` | bool | true | Ob Nutzer eigene AI-Keys verwenden dürfen |
| `policy.force_kammerton` | bool | false | Kammerton kann nicht pro Gerät überschrieben werden |
| `policy.min_annotation_layer` | enum | "privat" | Mindest-Sichtbarkeit erzwingen (z.B. nur "stimme" erlaubt) |

**Anzeige bei erzwungener Einstellung:** Schloss-Icon + Erklärungstext "Von deiner Kapelle festgelegt" + Kontakt-Hinweis auf Admin.

### Warum auf Kapellen-Ebene

- **AI-Keys:** Zentrale Lizenzierung spart Kosten, Admin behält Kontrolle über Verbrauch
- **Berechtigungen:** Organisatorische Entscheidung, nicht individuell
- **Branding:** Einheitliche Darstellung der Kapelle
- **Kammerton:** Musikalische Einheitlichkeit bei gemeinsamer Probe
- **Policies:** Konzert-Situationen (z.B. erzwungener Dark Mode) sind organisatorische Entscheidungen

---

## 3. Ebene 2: Nutzer (Persönlich)

### Zweck
Persönliche Präferenzen, die über alle Geräte synchronisiert werden. Definiert, wie der einzelne Musiker Sheetstorm nutzt.

### Wer darf ändern
- Jeder Nutzer für sich selbst

### Einstellungen

| Schlüssel | Typ | Default | Beschreibung |
|-----------|-----|---------|-------------|
| `nutzer.sprache` | locale | → kapelle.sprache | Bevorzugte Sprache (override Kapelle) |
| `nutzer.theme` | enum | "system" | Dark/Light/System |
| `nutzer.instrumente` | string[] | [] | Gespielte Instrumente |
| `nutzer.std_stimme` | map<kapelle_id, string> | {} | Standard-Stimme pro Kapelle |
| `nutzer.ai.provider` | enum | null | Persönlicher AI-Provider |
| `nutzer.ai.api_key` | encrypted | null | Persönlicher AI-API-Key |
| `nutzer.benachrichtigungen.termine` | bool | true | Push für Termine |
| `nutzer.benachrichtigungen.noten_neu` | bool | true | Push für neue Noten |
| `nutzer.benachrichtigungen.annotation_update` | bool | true | Push für Orchester-Annotationen |
| `nutzer.spielmodus.half_page_turn` | bool | true | Half-Page-Turn aktiviert |
| `nutzer.spielmodus.half_page_ratio` | float | 0.5 | Teilungsverhältnis (0.3 – 0.7) |
| `nutzer.spielmodus.swipe_richtung` | enum | "horizontal" | Horizontal/Vertikal |
| `nutzer.annotation.default_farbe` | color | "#FF0000" | Standard-Stiftfarbe |
| `nutzer.annotation.default_dicke` | int | 3 | Standard-Stiftstärke (px) |
| `nutzer.cloud_sync.aktiv` | bool | false | Persönliche Sammlung synchronisieren |

### Warum auf Nutzer-Ebene

- **Theme/Sprache:** Persönliche Präferenz, gleich auf allen Geräten
- **Instrumente/Standard-Stimme:** Definiert die Person, nicht das Gerät
- **AI-Key:** Persönliche Lizenz, nutzergebunden
- **Benachrichtigungen:** Persönliche Störungstoleranz
- **Spielmodus-Präferenzen:** Gewohnheiten des Musikers, geräteunabhängig

---

## 4. Ebene 3: Gerät (Lokal)

### Zweck
Hardware-abhängige Einstellungen, die nur auf diesem Gerät Sinn machen. Werden **nicht** synchronisiert (Ausnahme: optionales Server-Backup).

### Wer darf ändern
- Jeder Nutzer auf seinem Gerät

### Einstellungen

| Schlüssel | Typ | Default | Beschreibung |
|-----------|-----|---------|-------------|
| `geraet.display.helligkeit` | float | system | App-interne Helligkeitsanpassung (0.0–1.0) |
| `geraet.display.schriftgroesse` | enum | "mittel" | Klein/Mittel/Groß/Sehr Groß |
| `geraet.display.auto_rotation` | bool | true | Auto-Rotation für Notenblätter |
| `geraet.display.auto_zoom` | bool | true | Auto-Zoom für Notenblätter |
| `geraet.touch.zonen` | map | plattform-default | Touch-Zonen für Seitenwechsel (L/R/Oben) |
| `geraet.touch.empfindlichkeit` | enum | "mittel" | Gering/Mittel/Hoch |
| `geraet.audio.eingang` | string | "default" | Mikrofon-Auswahl für Tuner |
| `geraet.audio.ausgang` | string | "default" | Lautsprecher für Metronom-Click |
| `geraet.tuner.kammerton` | int | → kapelle.kammerton | Lokale Kammerton-Überschreibung |
| `geraet.metronom.latenz_kompensation` | int | 0 | Latenz-Offset in ms |
| `geraet.metronom.audio_click` | bool | false | Audio-Click aktiviert |
| `geraet.fusspedal.aktiv` | bool | false | Fußpedal-Support aktiviert |
| `geraet.fusspedal.vorwaerts` | string | "PageDown" | Taste für Vorwärts |
| `geraet.fusspedal.rueckwaerts` | string | "PageUp" | Taste für Rückwärts |
| `geraet.offline.max_speicher_mb` | int | 500 | Maximaler Offline-Cache |
| `geraet.offline.auto_download` | bool | true | Noten automatisch herunterladen |
| `geraet.offline.nur_wifi` | bool | true | Downloads nur über WiFi |

### Warum auf Geräte-Ebene

- **Display-Einstellungen:** Phone und Tablet brauchen verschiedene Werte
- **Touch-Zonen:** Hängen von Bildschirmgröße und Haltung ab
- **Audio-Ein-/Ausgang:** Hardware-gebunden
- **Latenz-Kompensation:** Hängt von Geräte-Hardware und Netzwerk-Position ab
- **Fußpedal:** Nur relevant, wenn physisch verbunden
- **Offline-Speicher:** Abhängig von verfügbarem Speicherplatz

---

## 5. Override-Regeln im Detail

### Auflösungsreihenfolge

```
Effektiver Wert = 
  Gerät-Wert  ?? Nutzer-Wert  ?? Kapelle-Wert  ?? System-Default
  (falls keine Policy das verhindert)
```

### Policy-Blockierung

```
WENN policy.force_locale = true:
  → nutzer.sprache wird ignoriert
  → kapelle.sprache gilt für alle
  → UI zeigt: 🔒 "Von deiner Kapelle festgelegt"

WENN policy.allow_user_ai_keys = false:
  → nutzer.ai.api_key wird ignoriert
  → Nur kapelle.ai.api_key wird verwendet
  → UI zeigt: 🔒 "Deine Kapelle stellt die AI-Zugänge zentral bereit"
```

### Multi-Kapellen-Verhalten

- **Kapellen-Config** gilt nur im aktiven Kapellen-Kontext
- Beispiel: Kapelle A hat `kammerton=442`, Kapelle B hat `kammerton=440`
  - Nutzer öffnet Stück von Kapelle A → Tuner zeigt 442 Hz
  - Nutzer wechselt zu Kapelle B → Tuner zeigt 440 Hz
- **Nutzer-Config** ist kapellenunabhängig (Theme, Sprache etc.)
- **Geräte-Config** ist kapellenunabhängig
- **Ausnahme:** `nutzer.std_stimme` ist eine Map pro Kapelle

---

## 6. Datenmodell

### Server (PostgreSQL)

```sql
-- Kapellen-Konfiguration
CREATE TABLE config_kapelle (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id UUID NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    schluessel TEXT NOT NULL,
    wert JSONB NOT NULL,
    aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    aktualisiert_von UUID REFERENCES musiker(id),
    UNIQUE(kapelle_id, schluessel)
);

-- Nutzer-Konfiguration
CREATE TABLE config_nutzer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    musiker_id UUID NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
    schluessel TEXT NOT NULL,
    wert JSONB NOT NULL,
    aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version BIGINT NOT NULL DEFAULT 1,
    UNIQUE(musiker_id, schluessel)
);

-- Kapellen-Policies
CREATE TABLE config_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id UUID NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    schluessel TEXT NOT NULL,
    wert JSONB NOT NULL,
    aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    aktualisiert_von UUID REFERENCES musiker(id),
    UNIQUE(kapelle_id, schluessel)
);

-- Audit-Log für Kapellen-Config-Änderungen
CREATE TABLE config_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id UUID REFERENCES kapellen(id),
    musiker_id UUID REFERENCES musiker(id),
    ebene TEXT NOT NULL CHECK (ebene IN ('kapelle', 'nutzer', 'policy')),
    schluessel TEXT NOT NULL,
    alter_wert JSONB,
    neuer_wert JSONB,
    zeitstempel TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indizes für Performance
CREATE INDEX idx_config_kapelle_lookup ON config_kapelle(kapelle_id, schluessel);
CREATE INDEX idx_config_nutzer_lookup ON config_nutzer(musiker_id, schluessel);
CREATE INDEX idx_config_audit_kapelle ON config_audit(kapelle_id, zeitstempel DESC);
```

### Client (SQLite / Drift)

```sql
-- Lokaler Config-Cache (alle Ebenen)
CREATE TABLE config_cache (
    schluessel TEXT NOT NULL,
    ebene TEXT NOT NULL CHECK (ebene IN ('kapelle', 'nutzer', 'geraet', 'policy')),
    referenz_id TEXT, -- kapelle_id oder musiker_id, NULL für geraet
    wert TEXT NOT NULL, -- JSON als Text
    aktualisiert_am INTEGER NOT NULL, -- Unix-Timestamp
    version INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (schluessel, ebene, COALESCE(referenz_id, ''))
);

-- Geräte-Konfiguration (nur lokal)
CREATE TABLE config_geraet (
    schluessel TEXT PRIMARY KEY,
    wert TEXT NOT NULL, -- JSON als Text
    aktualisiert_am INTEGER NOT NULL
);
```

---

## 7. Sync-Strategie

| Ebene | Speicherort | Sync-Richtung | Strategie |
|-------|-------------|:-------------:|-----------|
| **Kapelle** | Server (PostgreSQL) → Client (SQLite Cache) | Server → Client | Server ist Source of Truth. Client cacht. Bei Änderung: Push-Event an alle Mitglieder. |
| **Nutzer** | Server (PostgreSQL) ↔ Client (SQLite Cache) | Bidirektional | Last-Write-Wins **per Feld** (nicht per Datensatz). Versionszähler pro Feld. |
| **Gerät** | Client (SQLite) nur | Lokal | Kein Sync. Optional: Backup zum Server (verschlüsselt, nur auf Anfrage). |
| **Policies** | Server (PostgreSQL) → Client (SQLite Cache) | Server → Client | Wie Kapelle. Policies werden beim App-Start und bei Kapellenwechsel geladen. |

### Sync-Ablauf (Nutzer-Config)

```
Client                          Server
  │                               │
  ├── Ändert Theme auf "dark" ──► │
  │   {schluessel: "nutzer.theme",│
  │    wert: "dark",              │
  │    version: 5}                │
  │                               │
  │ ◄── Bestätigung + ggf.      ─┤
  │     Server-Overrides          │
  │     (falls andere Geräte      │
  │      neuere Version haben)    │
  │                               │
```

### Offline-Verhalten

1. Änderungen werden lokal in SQLite gespeichert
2. Versionszähler wird lokal inkrementiert
3. Bei nächster Verbindung: Delta-Sync zum Server
4. Konflikte: Höhere Version gewinnt (per Feld)

---

## 8. UX-Prinzipien (von Wanda übernommen)

1. **Auto-Save mit Undo-Toast:** Jede Änderung sofort übernommen. Toast mit "Rückgängig" für 5 Sekunden. Gefährliche Aktionen (Cache leeren, Mitglied entfernen) mit Bestätigungs-Dialog.

2. **Farbkodierung der Ebenen:**
   - 🔵 Blau = Kapelle (Organisation)
   - 🟢 Grün = Nutzer (Persönlich)
   - 🟠 Orange = Gerät (Lokal)
   - Subtiler linker Rand + Badge + Icon. Nie Farbe allein (Barrierefreiheit).

3. **Vererbung transparent:** Bei jeder Einstellung sichtbar, woher der aktuelle Wert kommt. "Standard von Kapelle" mit Option "Eigenen Wert festlegen". Erzwungene Einstellungen: Schloss-Icon + Erklärung.

4. **Kontextuelle Einstellungen im Spielmodus:** Overlay mit max. 5 Optionen (Helligkeit, Schriftgröße, Half-Page-Turn, Annotation-Layer, Dark Mode Toggle). Notenblatt bleibt sichtbar.

5. **Intelligente Defaults pro Gerätetyp:** Phone bekommt andere Touch-Zonen als Tablet. Erste Nutzung setzt sinnvolle Werte basierend auf Geräteklasse.

6. **Keine Einstellung erfordert Neustart.** Dark Mode, Sprache, AI-Provider — alles wirkt sofort.

7. **Onboarding: Maximal 5 Fragen.** Name, Instrumente, Kapelle, Theme. Rest hat sinnvolle Defaults.

---

## 9. Config-Resolution (Pseudocode)

```dart
/// Löst einen Config-Wert auf unter Berücksichtigung von Policies
T resolveConfig<T>(String key, {required KapelleId? kapelleId}) {
  // 1. Policy prüfen
  if (kapelleId != null) {
    final policy = getPolicy(kapelleId, key);
    if (policy != null && policy.enforced) {
      return getKapelleConfig(kapelleId, key) ?? systemDefault(key);
    }
  }
  
  // 2. Override-Kette: Gerät > Nutzer > Kapelle > Default
  return getGeraetConfig(key)
      ?? getNutzerConfig(key)
      ?? (kapelleId != null ? getKapelleConfig(kapelleId, key) : null)
      ?? systemDefault(key);
}
```

---

## 10. API-Endpunkte

```
GET    /api/v1/config/kapelle/{id}          → Alle Kapellen-Einstellungen
PUT    /api/v1/config/kapelle/{id}/{key}    → Einzelne Einstellung ändern
GET    /api/v1/config/kapelle/{id}/policies → Alle Policies
PUT    /api/v1/config/kapelle/{id}/policies/{key} → Policy ändern

GET    /api/v1/config/nutzer                → Alle Nutzer-Einstellungen
PUT    /api/v1/config/nutzer/{key}          → Einzelne Einstellung ändern
POST   /api/v1/config/nutzer/sync           → Delta-Sync (bidirektional)

GET    /api/v1/config/resolved/{kapelle_id} → Aufgelöste Config (alle Ebenen merged)
```

Geräte-Config hat **keine** API-Endpunkte — sie lebt nur lokal.

---

*Dieses Dokument wird via PR zur Abstimmung vorgelegt. Änderungen erfordern Thomas' Freigabe.*
