# Feature-Spezifikation: Konfigurationssystem (3 Ebenen)

> **Issue:** #33  
> **Meilenstein:** MS1  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Draft — UX-Spec (#32) abgenommen  
> **Depends on:** #32 (UX Konfiguration), #7 (Backend), #8 (Flutter Scaffolding), #22 (Kapellenverwaltung)  
> **Blocked by:** —  
> **UX-Referenz:** `docs/ux-specs/konfiguration.md`

---

## 1. Feature-Überblick

### Beschreibung

Das Konfigurationssystem ist die **Grundlage für Personalisierung in Sheetstorm**. Es ermöglicht es Kapellen-Admins, Richtlinien zu setzen (Organisationsebene), Musikern, ihre Präferenzen zu definieren (Persönliche Ebene), und Nutzern, ihre Geräte optimal einzurichten (Geräteebene).

Das System folgt einem **3-Ebenen-Modell:**
- 🔵 **Kapelle (Organisation):** Admin-Einstellungen, Policies, Berechtigungen, zentrale AI-Keys
- 🟢 **Nutzer (Persönlich):** Theme, Sprache, Instrumente, Benachrichtigungen — über alle Geräte synchronisiert
- 🟠 **Gerät (Lokal):** Display, Touch, Audio — nur auf diesem Gerät, nicht synchronisiert

**Override-Regel:** Gerät > Nutzer > Kapelle > System-Default (mit optionaler Policy-Blockierung durch Kapelle)

**Kernprinzip:** Auto-Save ohne Speichern-Button, Undo-Toast für 5 Sekunden, Transparente Vererbungshierarchie, Farbkodierung für Barrierefreiheit.

### Scope MS1 (In-Scope)

- ✅ Kapelle-Ebene: Organisationsweite Konfiguration (Admin-Zugang)
- ✅ Nutzer-Ebene: Persönliche Präferenzen (synchronisiert über alle Geräte)
- ✅ Gerät-Ebene: Lokale Hardware-Einstellungen
- ✅ Policy-System: Kapelle-Admin kann Overrides sperren
- ✅ Config-Screens mit Farbkodierung (Blau/Grün/Orange)
- ✅ Vererbung transparent: "Standard von Kapelle" mit "Eigenen Wert festlegen"
- ✅ Erzwungene Einstellungen mit Schloss-Icon
- ✅ Kontextuelle Einstellungen im Spielmodus (Overlay, max. 5 Optionen)
- ✅ Auto-Save mit Undo-Toast (5 Sekunden)
- ✅ Intelligente Defaults pro Gerätetyp (Phone vs. Tablet)
- ✅ Onboarding: max. 5 Fragen
- ✅ Keine Einstellung erfordert App-Neustart
- ✅ Server-Persistierung: PostgreSQL mit JSONB
- ✅ Client-Caching: SQLite/Drift mit Delta-Sync
- ✅ Audit-Logging für Kapellen-Config-Änderungen

### Out-of-Scope MS1 (Später)

- ❌ Kalender-Sync (MS2)
- ❌ GEMA-Compliance-Einstellungen (MS2)
- ❌ Advanced AI-Provider-Integration (MS5)
- ❌ Multi-Language-Unterstützung (MS5)
- ❌ Export/Backup von Config-Profilen (MS5)

---

## 2. User Stories

### US-01: Kapelle-Admin setzt organisationsweite Einstellungen

**Als** Kapelle-Administrator  
**möchte ich** organisationsweite Einstellungen konfigurieren (AI-Keys, Berechtigungen, Policies)  
**damit** alle Mitglieder meiner Kapelle konsistent unter denselben Vorgaben arbeiten.

**Akzeptanzkriterien:**
- [ ] AC-01: Admin öffnet "Kapelle-Einstellungen" und sieht alle 3 Bereiche: Branding, AI-Konfiguration, Berechtigungen, Policies
- [ ] AC-02: AI-Keys (Provider + API-Key) können zentral gespeichert werden — verschlüsselt in PostgreSQL
- [ ] AC-03: Berechtigungen (wer darf Noten hochladen, Setlists erstellen, etc.) sind nach Rollen konfig-urierbar
- [ ] AC-04: Kammerton und Standard-BPM sind einstellbar und wirken sich auf alle Mitglieder aus
- [ ] AC-05: Policies können aktiviert werden: `force_dark_mode`, `force_locale`, `allow_user_ai_keys`, `force_kammerton`, `min_annotation_layer`
- [ ] AC-06: Erzwungene Einstellungen zeigen ein 🔒 Schloss-Icon in der Nutzer-UI mit Text "Von deiner Kapelle festgelegt"
- [ ] AC-07: Alle Änderungen werden Auto-Saved und erscheinen sofort für andere Mitglieder (sofern geladene Config gecacht ist)
- [ ] AC-08: Audit-Log protokolliert: Wer hat was wann geändert (für alle Kapellen-Config-Änderungen)

### US-02: Musiker personalisiert seine Präferenzen

**Als** Musiker  
**möchte ich** meine persönlichen Einstellungen (Theme, Sprache, Instrumente, Benachrichtigungen) auf allen meinen Geräten synchronisiert haben  
**damit** meine Präferenzen überall gleich sind.

**Akzeptanzkriterien:**
- [ ] AC-09: Nutzer öffnet "Meine Einstellungen" und sieht nur die Nutzer-Ebene-Optionen
- [ ] AC-10: Theme (Dark/Light/System) kann geändert werden und wirkt sich sofort auf die gesamte App aus — kein Neustart nötig
- [ ] AC-11: Sprache kann geändert werden (falls nicht per Policy erzwungen) — sofort wirksam, alle Strings neu geladen
- [ ] AC-12: Instrumente können hinzugefügt werden (z.B. "1. Klarinette", "2. Trompete") — die Standard-Stimme pro Kapelle wird eingegeben
- [ ] AC-13: Bei mehreren Kapellen zeigt der Dialog eine Eingabe pro Kapelle für die Standard-Stimme
- [ ] AC-14: Benachrichtigungen können pro Kategorie ein-/ausgeschaltet werden (Termine, Noten-Upload, Annotationen)
- [ ] AC-15: Persönliche AI-Keys können eingetragen werden — oder deaktiviert, wenn Policy `allow_user_ai_keys=false`
- [ ] AC-16: Alle Änderungen werden Auto-Saved mit Undo-Toast für 5 Sekunden
- [ ] AC-17: Änderungen werden in der Cloud synchronisiert — Last-Write-Wins per Feld mit Versionierung
- [ ] AC-18: Nutzer kann auf einem Gerät A ändern, auf Gerät B wird die Änderung nach der nächsten Synchronisierung sichtbar (spätestens beim nächsten Öffnen der App)

### US-03: Nutzer passen Gerät-Einstellungen an

**Als** Musiker auf meinem Tablet  
**möchte ich** Gerät-spezifische Einstellungen konfigurieren (Schriftgröße, Helligkeit, Touch-Zonen, Fußpedal)  
**damit** mein Tablet optimal für die Notenansicht eingestellt ist.

**Akzeptanzkriterien:**
- [ ] AC-19: Nutzer öffnet "Gerät-Einstellungen" und sieht die orangefarbenen (Gerät-Ebene) Optionen
- [ ] AC-20: Schriftgröße (Klein/Mittel/Groß/Sehr Groß) kann geändert werden und wirkt sofort auf alle Notenansichten
- [ ] AC-21: Helligkeit kann mit einem Slider von 0.5 bis 1.5 (relativ zur System-Helligkeit) angepasst werden
- [ ] AC-22: Touch-Zonen können konfiguriert werden: Prozentsatz Links/Rechts für Seitenwechsel (z.B. 40/60, 50/50 default)
- [ ] AC-23: Fußpedal-Belegung: Tasten für Vorwärts/Rückwärts können angepasst werden
- [ ] AC-24: Audio-Ein-/Ausgang für Tuner und Metronom können aus verfügbaren Geräten ausgewählt werden
- [ ] AC-25: Kammerton kann lokal überschrieben werden (falls nicht per Policy erzwungen)
- [ ] AC-26: Offline-Speicher-Limit kann festgelegt werden (Default: 500 MB)
- [ ] AC-27: Alle Änderungen sind **nicht synchronisiert** — nur auf diesem Gerät gespeichert
- [ ] AC-28: Gerät-Einstellungen werden in SQLite lokal gespeichert (nicht im Server)

### US-04: Kontextuelle Einstellungen im Spielmodus

**Als** Musiker im Spielmodus  
**möchte ich** schnell Einstellungen anpassen, ohne den Spielmodus zu verlassen  
**damit** ich flexibel reagieren kann ohne abzusetzen.

**Akzeptanzkriterien:**
- [ ] AC-29: Tap in die Mitte des Bildschirms zeigt ein Kontextmenü mit max. 5 Optionen
- [ ] AC-30: Optionen: Helligkeit, Schriftgröße, Half-Page-Turn An/Aus, Annotation-Layer, Dark Mode Toggle
- [ ] AC-31: Das Overlay ist halbtransparent — Notenblatt bleibt sichtbar und lesbar
- [ ] AC-32: Jede Option kann mit einem Ein/Aus-Toggle oder Slider angepasst werden
- [ ] AC-33: Änderungen wirken **sofort** auf die aktuell angezeigte Seite
- [ ] AC-34: Overlay verschwindet nach 5 Sekunden Inaktivität oder durch erneuten Tap in die Mitte
- [ ] AC-35: Diese Änderungen speichern in die Gerät-Ebene (nicht Nutzer-Ebene)

### US-05: Transparente Vererbung und Policy-Blockierung verstehen

**Als** Musiker  
**möchte ich** verstehen, wo eine Einstellung herkommt und ob ich sie ändern darf  
**damit** ich nicht verwirrt bin, warum eine Einstellung "grau" oder "gesperrt" ist.

**Akzeptanzkriterien:**
- [ ] AC-36: Bei jeder Einstellung ist sichtbar, auf welcher Ebene sie aktuell aktiv ist: (🔵 Kapelle / 🟢 Nutzer / 🟠 Gerät)
- [ ] AC-37: Wenn ein Wert von der Kapelle übernommen wird, steht: "Standard von Kapelle" mit grauer Schriftfarbe
- [ ] AC-38: Nutzer kann auf "Eigenen Wert festlegen" klicken → Input wird aktiviert, Ebene wechselt zu 🟢 Nutzer
- [ ] AC-39: Erzwungene Einstellungen zeigen ein 🔒 Schloss-Icon und sind nicht editierbar
- [ ] AC-40: Kontakt-Hinweis bei Policies: "Diese Einstellung wurde von deiner Kapelle festgelegt. Kontaktiere [admin@kapelle.de] um Änderungen anzufragen."
- [ ] AC-41: Linker Rand jeder Einstellung zeigt die Ebenenfarbe (Blau/Grün/Orange) und Icon
- [ ] AC-42: Tooltip bei Hover auf Icon erklärt: "Kapelle-Einstellung", "Deine persönliche Einstellung", "Geräte-spezifische Einstellung"

### US-06: Config-Resolution bei Multi-Kapellen-Zugehörigkeit

**Als** Musiker in mehreren Kapellen  
**möchte ich**, dass Kapellen-Einstellungen unabhängig sind  
**damit** die Einstellungen von Kapelle A nicht die Einstellungen von Kapelle B beeinflussen.

**Akzeptanzkriterien:**
- [ ] AC-43: Kapelle A hat `kammerton=442`, Kapelle B hat `kammerton=440` — beim Wechsel wird der korrekte Wert geladen
- [ ] AC-44: Standard-Stimme wird pro Kapelle gespeichert und angewendet (Nutzer-Ebene ist eine Map: `kapelle_id → stimme`)
- [ ] AC-45: Admin-Config-Screen zeigt nur Kapellen-Einstellungen der aktuellen Kapelle
- [ ] AC-46: Nutzer-Einstellungen sind unabhängig von der Kapelle (Theme, Sprache, persönliche Instrumente sind global)
- [ ] AC-47: Beim Kapellenwechsel werden Kapellen-Policies neu geladen (z.B. falls Kapelle B Dark Mode erzwingt)

### US-07: Onboarding mit Config-Fragen

**Als** neuer Nutzer  
**möchte ich** mit maximal 5 Fragen meine Basiseinstellungen definieren  
**damit** ich schnell fertig bin und die App nutzen kann.

**Akzeptanzkriterien:**
- [ ] AC-48: Onboarding umfasst genau 5 Schritte (oder weniger, wenn manche skippbar sind):
  1. Name
  2. Instrumente (mit Fachliche Standard-Stimme pro Instrument vorschlagen)
  3. Kapelle (beitreten oder erstellen)
  4. Theme (Dark/Light/System)
  5. Evtl. Benachrichtigungen (optional)
- [ ] AC-49: Jeder Schritt kann mit "Überspringen" ignoriert werden
- [ ] AC-50: Nach Onboarding sind intelligente Defaults gesetzt
- [ ] AC-51: Alle Onboarding-Antworten werden in der Nutzer-Ebene gespeichert
- [ ] AC-52: Onboarding kann später unter "Meine Einstellungen" erneut durchlaufen werden ("Setup neu starten")

---

## 3. Akzeptanzkriterien (Technisch)

### API-Endpunkte

```
=== KAPELLE-KONFIGURATION ===

GET    /api/v1/config/kapelle/{id}
       → Alle Kapellen-Einstellungen
       Response: { schluessel → wert, ... }
       Auth: Jeder Mitglied der Kapelle

GET    /api/v1/config/kapelle/{id}/policies
       → Alle Policies der Kapelle
       Response: { schluessel → { value, enforced }, ... }
       Auth: Nur Admin

PUT    /api/v1/config/kapelle/{id}/{key}
       → Einzelne Einstellung ändern
       Body: { wert: any }
       Response: { success: bool, alte_wert: any, neue_wert: any, zeitstempel: iso }
       Auth: Only Admin
       Audit: Logged mit alter/neuer Wert, user_id, zeitstempel

PUT    /api/v1/config/kapelle/{id}/policies/{key}
       → Policy ändern
       Body: { wert: any }
       Response: wie PUT /config/kapelle/
       Auth: Only Admin
       Audit: Logged

DELETE /api/v1/config/kapelle/{id}/{key}
       → Einstellung zurücksetzen auf System-Default
       Response: { success: bool, neuer_wert: any }
       Auth: Only Admin

=== NUTZER-KONFIGURATION ===

GET    /api/v1/config/nutzer
       → Alle Nutzer-Einstellungen (des aktuellen Users)
       Response: { schluessel → { wert, version }, ... }
       Auth: Authenticated

PUT    /api/v1/config/nutzer/{key}
       → Einzelne Einstellung ändern
       Body: { wert: any }
       Response: { success: bool, neue_wert: any, neue_version: int }
       Auth: Authenticated

POST   /api/v1/config/nutzer/sync
       → Delta-Sync (bidirektional für Offline-Support)
       Body: { changes: [{ key, wert, version, timestamp }, ...] }
       Response: { applied: [...], server_changes: [...], conflicts: [...] }
       Auth: Authenticated

DELETE /api/v1/config/nutzer/{key}
       → Einstellung zurücksetzen auf System-Default
       Response: { success: bool }
       Auth: Authenticated

=== RESOLVED CONFIG (Merged Ebenen) ===

GET    /api/v1/config/resolved?kapelle_id={id}
       → Aufgelöste Config: Alle Ebenen gemerged unter Berücksichtigung von Policies
       Response: { schluessel → { wert, ebene, policy_enforced } }
       Auth: User der Kapelle
       Hinweis: Dies ist ein **Read-Only**-Endpunkt zur Auflösung — keine Änderungen hier

=== GERÄTE-KONFIGURATION ===

Keine API-Endpunkte — Geräte-Config ist lokal nur!
(Optional: Backup-Endpunkt für spätere Umzüge, nicht MS1)
```

### Datenmodell (PostgreSQL)

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
CREATE INDEX idx_config_kapelle_lookup ON config_kapelle(kapelle_id, schluessel);

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
CREATE INDEX idx_config_nutzer_lookup ON config_nutzer(musiker_id, schluessel);

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
CREATE INDEX idx_config_policies_lookup ON config_policies(kapelle_id, schluessel);

-- Audit-Log für Kapellen-Config-Änderungen
CREATE TABLE config_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id UUID REFERENCES kapellen(id),
    musiker_id UUID REFERENCES musiker(id),
    ebene TEXT NOT NULL CHECK (ebene IN ('kapelle', 'nutzer', 'policy')),
    schluessel TEXT NOT NULL,
    alter_wert JSONB,
    neuer_wert JSONB,
    zeitstempel TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (musiker_id) REFERENCES musiker(id)
);
CREATE INDEX idx_config_audit_kapelle ON config_audit(kapelle_id, zeitstempel DESC);
CREATE INDEX idx_config_audit_musiker ON config_audit(musiker_id, zeitstempel DESC);
```

### Datenmodell (SQLite / Drift)

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

-- Offline-Queue für Nutzer-Config-Änderungen (unsynced)
CREATE TABLE config_pending_sync (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    schluessel TEXT NOT NULL,
    wert TEXT NOT NULL,
    version INTEGER NOT NULL,
    timestamp INTEGER NOT NULL,
    synced BOOLEAN DEFAULT 0
);
```

### Konfigurationsschlüssel (Reference)

#### Kapelle-Ebene
```
kapelle.name                          string
kapelle.ort                           string
kapelle.logo                          url
kapelle.sprache                       locale ("de", "en", etc.)
kapelle.ai.provider                   enum ("azure_vision", "openai_vision", "google_vision", null)
kapelle.ai.api_key                    encrypted string
kapelle.ai.enabled                    bool
kapelle.berechtigungen.noten_upload   role[] ([admin, dirigent, notenwart])
kapelle.berechtigungen.setlist_erstellen role[] ([admin, dirigent, notenwart])
kapelle.berechtigungen.termine_erstellen role[] ([admin, dirigent])
kapelle.berechtigungen.annotation_stimme role[] ([admin, dirigent, registerfuehrer])
kapelle.berechtigungen.annotation_orchester role[] ([admin, dirigent])
kapelle.kammerton                     int (Hz, default: 442)
kapelle.metronom.default_bpm          int (default: 120)
kapelle.aushilfe.default_ablauf_tage  int (default: 7)
```

#### Policy-Ebene
```
policy.force_locale                   bool (default: false) — Sprache erzwungen
policy.force_dark_mode                bool|null (default: null) — null=frei, true=erzwungen, false=erzwungen
policy.allow_user_ai_keys             bool (default: true) — Nutzer darf eigene AI-Keys verwenden
policy.force_kammerton                bool (default: false) — Kammerton kann nicht überschrieben werden
policy.min_annotation_layer           enum ("privat"|"stimme"|"orchester", default: "privat")
```

#### Nutzer-Ebene
```
nutzer.sprache                        locale
nutzer.theme                          enum ("dark", "light", "system")
nutzer.instrumente                    string[]
nutzer.std_stimme                     map<kapelle_id, string>
nutzer.ai.provider                    enum (null|"azure_vision"|"openai_vision"|"google_vision")
nutzer.ai.api_key                     encrypted string
nutzer.benachrichtigungen.termine     bool
nutzer.benachrichtigungen.noten_neu   bool
nutzer.benachrichtigungen.annotation_update bool
nutzer.spielmodus.half_page_turn      bool
nutzer.spielmodus.half_page_ratio     float (0.3–0.7)
nutzer.spielmodus.swipe_richtung      enum ("horizontal", "vertikal")
nutzer.annotation.default_farbe       color ("#FF0000")
nutzer.annotation.default_dicke       int (3)
nutzer.cloud_sync.aktiv               bool
```

#### Gerät-Ebene
```
geraet.display.helligkeit             float (0.5–1.5, relativ zur System-Helligkeit)
geraet.display.schriftgroesse         enum ("klein", "mittel", "gross", "sehr_gross")
geraet.display.auto_rotation          bool
geraet.display.auto_zoom              bool
geraet.touch.zonen                    map {left: 0.4, right: 0.6}
geraet.touch.empfindlichkeit          enum ("gering", "mittel", "hoch")
geraet.audio.eingang                  string ("default" oder device-id)
geraet.audio.ausgang                  string ("default" oder device-id)
geraet.tuner.kammerton                int (Hz, null → inherit from kapelle)
geraet.metronom.latenz_kompensation   int (ms, default: 0)
geraet.metronom.audio_click           bool
geraet.fusspedal.aktiv                bool
geraet.fusspedal.vorwaerts            string ("PageDown")
geraet.fusspedal.rueckwaerts          string ("PageUp")
geraet.offline.max_speicher_mb        int (500)
geraet.offline.auto_download          bool
geraet.offline.nur_wifi               bool
```

---

## 4. Interaction Patterns & UX-Details

### 4.1 Auto-Save & Undo-Toast

Jede Änderung wird **sofort** in den lokalen Client-Cache geschrieben und dann zum Server synchronisiert. Ein Toast mit "Rückgängig" erscheint für 5 Sekunden:

```
Nutzer: Theme zu "dark" gewechselt
→ [Client] Sofort in SQLite gespeichert
→ [UI] Toast: "Theme geändert" mit "Rückgängig"-Button für 5s
→ [Server] Im Hintergrund sync via PUT /api/v1/config/nutzer/nutzer.theme
→ [Andere Geräte] Änderung nach nächster Sync sichtbar
```

### 4.2 Farbkodierung & Barrierefreiheit

Jede Einstellung wird mit **Farbe + Icon + Text** gekennzeichnet:

```
🔵 Kapelle-Einstellung (Blau #1A56DB)
├─ Linker Rand: Farbige Linie 4px
├─ Icon: 🏛 (oder Gebäude-Symbol)
└─ Label: "Kapelle-Einstellung" in grauer Schrift

🟢 Nutzer-Einstellung (Grün #16A34A)
├─ Linker Rand: Farbige Linie 4px
├─ Icon: 👤 (oder Person-Symbol)
└─ Label: "Deine Einstellung" in grauer Schrift

🟠 Gerät-Einstellung (Orange #D97706)
├─ Linker Rand: Farbige Linie 4px
├─ Icon: 📱 (oder Smartphone-Symbol)
└─ Label: "Geräte-spezifisch" in grauer Schrift

🔒 Erzwungene Einstellung (Policy)
├─ Icon: 🔒 (Schloss, rot oder orange)
└─ Label: "Von deiner Kapelle festgelegt" mit Kontakt-Hinweis
```

Niemals Farbe allein — immer Icon + Text (WCAG 2.1 AA).

### 4.3 Vererbung Transparent

Wenn eine Einstellung **nicht** auf der aktuellen Ebene gespeichert ist, wird sichtbar gemacht, woher der Wert kommt:

```
🔵 Kammerton
├─ Wert: 442 Hz
├─ Status: "Standard von Kapelle"
├─ Eingabe: [Deaktiviert / Grau]
└─ Button: "Eigenen Wert festlegen"

[Nutzer klickt auf Button]

🟢 Kammerton (jetzt Nutzer-Ebene)
├─ Wert: [Input-Feld aktiviert, 442 Hz]
├─ Status: "Deine Einstellung"
└─ Button: "Auf Kapelle-Default zurücksetzen"
```

### 4.4 Kontextuelle Einstellungen im Spielmodus

Overlay mit max. 5 häufigsten Einstellungen:

```
┌──────────────────────────────┐
│  [x]  Tap zum Schließen      │
├──────────────────────────────┤
│ ☀️ Helligkeit  |—————●——————| │  (Slider, 0.5–1.5)
│ 🔤 Schriftgr.  [Mittel ▼]    │  (Dropdown)
│ ◀──│──►  Half-Page [An/Aus] │  (Toggle)
│ 🎨 Annotationen [Alle ▼]     │  (Ebenen-Auswahl)
│ 🌙 Dark Mode   [An]          │  (Toggle)
└──────────────────────────────┘
```

Auto-Schließen nach 5s oder Tap außerhalb/in die Mitte erneut.

### 4.5 Intelligente Defaults

Beim ersten Starten erkennt die App die Geräte-Klasse und setzt sinnvolle Defaults:

```
iPhone (5-7"):
├─ touch.zonen: {left: 0.35, right: 0.65}
├─ display.schriftgroesse: "mittel"
└─ display.helligkeit: 1.0

iPad (9-12"):
├─ touch.zonen: {left: 0.40, right: 0.60}
├─ display.schriftgroesse: "gross"
└─ display.helligkeit: 1.0

iPad Pro (13"+) / Desktop:
├─ Aktiviert Zwei-Seiten-Modus
├─ touch.zonen: {left: 0.45, right: 0.55}
├─ display.schriftgroesse: "sehr_gross"
└─ display.helligkeit: 1.0
```

---

## 5. Sync-Strategie (Nutzer-Ebene)

### 5.1 Bidirektionales Sync mit Versionierung

Nutzer-Config wird pro **Feld** mit Versionszähler synchronisiert (Last-Write-Wins):

```
Client (Gerät A)            Server              Client (Gerät B)
   │                           │                      │
   ├─ Ändert Theme zu dark ─►  │                      │
   │  (version: 5)              │                      │
   │                           ├─ Push-Event ────────►│
   │                           │                      │
   │                           │◄─ Geräte B synced ──┤
   │                           │   (version: 5)       │
   │◄─ Bestätigung ────────────┤                      │
   │  (version: 5)              │                      │
```

### 5.2 Offline & Konflikt-Auflösung

Bei Offline-Änderungen werden diese lokal gepuffert und beim nächsten Sync übermittelt:

```
1. Client ist offline
   ├─ Änderung lokal in SQLite + version increment
   └─ config_pending_sync: {schluessel, wert, version, synced=0}

2. Client kommt online
   ├─ POST /api/v1/config/nutzer/sync mit pending changes
   └─ Server antwortet mit Server-State für jedes Feld

3. Konflikt-Auflösung (per Feld, nicht global):
   ├─ Wenn client_version > server_version → Client gewinnt (Write)
   ├─ Wenn server_version > client_version → Server gewinnt (Overwrite)
   └─ Wenn gleich → Last-Write-Wins basierend auf Timestamp
```

### 5.3 Kapellen-Config Broadcast

Wenn Admin Kapellen-Config ändert, erhalten alle Mitglieder eine Push-Notification:

```
Admin ändert policy.force_dark_mode = true
   │
   ├─ Server speichert in config_policies
   ├─ Server sendet SignalR-Event an Kapelle
   │
   ├─ Alle Geräte dieser Kapelle erhalten Event
   ├─ Local Cache wird invalidiert
   └─ Nächste Anfrage lädt frische Config vom Server
```

---

## 6. Edge Cases & Fehlerszenarien

### EC-01: User ist Admin in einer Kapelle, Mitglied in einer anderen

**Szenario:** User A ist Admin in Kapelle X (kann Config ändern), aber Musiker in Kapelle Y (kann Config nicht ändern).

**Lösung:**
- In Kapelle X: Config-Screen zeigt Admin-Bereich mit vollen Berechtigungen
- In Kapelle Y: Config-Screen zeigt Nutzer-Bereich, Kapellen-Bereich ist deaktiviert / nicht sichtbar

### EC-02: Policy wird aktiviert, während Nutzer die App verwendet

**Szenario:** Admin aktiviert `policy.force_dark_mode=true` während Nutzer gerade die App nutzt.

**Lösung:**
- Server sendet Push-Event
- Client invalidiert Cache
- Nächste Config-Abfrage lädt neue Policy
- If Dark Mode nicht bereits aktiv: Auto-Switch mit Toast "Dark Mode wurde von deiner Kapelle aktiviert"

### EC-03: Nutzer aktiviert Dark Mode, Admin erzwingt Light Mode

**Szenario:** Nutzer hat `nutzer.theme="dark"` gespeichert. Admin aktiviert `policy.force_dark_mode=false` (Light erzwungen).

**Lösung:**
- Nutzer-Config wird ignoriert (Policy gewinnt)
- UI zeigt: 🔒 "Light Mode ist von deiner Kapelle erzwungen"
- Input ist deaktiviert

### EC-04: Offline-Sync hat Konflikte

**Szenario:** Offline ändert Nutzer Theme zu "dark", Server hat inzwischen Theme zu "light" aktualisiert (von anderem Gerät).

**Lösung:**
- Client sendet beide Versionen
- Server-Version gewinnt (höhere Versionsnummer), zeigt Toast "Deine Theme-Änderung wurde von einem anderen Gerät überschrieben"

### EC-05: Geräte-Config beim Device-Wechsel

**Szenario:** Nutzer kauft sich ein neues iPad und installiert Sheetstorm.

**Lösung:**
- Geräte-Config wird **nicht** vom alten iPad synchronisiert
- Intelligente Defaults werden neu angewendet (iPad-Defaults)
- Nutzer kann manuell erneut konfigurieren

### EC-06: Kammerton-Override-Sperre

**Szenario:** Admin sperrt Kammerton mit `policy.force_kammerton=true`. Nutzer hatte lokal 440 Hz eingestellt.

**Lösung:**
- Lokale Geräte-Einstellung wird ignoriert
- Kapellen-Wert (z.B. 442) wird verwendet
- UI zeigt: 🔒 "Kammerton ist durch deine Kapelle festgelegt"

### EC-07: Multi-Kapellen — welche Config bei Spielmodus?

**Szenario:** Nutzer wechselt zwischen Kapelle A (Kammerton 442) und Kapelle B (Kammerton 440) im Spielmodus.

**Lösung:**
- Beim Laden eines Stücks wird die zugehörige Kapelle erkannt
- Config wird für diese Kapelle aufgelöst
- Spielmodus zeigt Kammerton der aktuellen Kapelle im Tuner

### EC-08: Config-Key existiert nicht

**Szenario:** Frontend fordert `kapelle.unbekannter_schluessel` an.

**Lösung:**
- Server gibt `null` zurück oder `{ error: "unknown_key" }`
- Client fällt auf System-Default zurück
- Keine Fehler-UI, silent fallback

### EC-09: Versionszähler läuft über

**Szenario:** Nutzer ändert Theme 2^63 mal.

**Lösung:**
- PostgreSQL BIGINT reicht für praktische Szenarien (max. 9 * 10^18)
- Sollte nie vorkommen — kein expliziter Handling nötig
- Monitoring: Alert bei version > 10.000 pro Feld

---

## 7. Dependency & Integration

### 7.1 Abhängigkeiten

- **Kapellenverwaltung (#22):** Config-System braucht Kapellen-IDs und Rollen-System (Admin, Dirigent, etc.)
- **UX-Spec (#32):** Wireframes und Interaction Patterns sind Vorlage
- **Backend API (#7):** REST-Endpunkte müssen implementiert sein
- **Flutter Scaffolding (#8):** Riverpod State Management für Config-Provider

### 7.2 Abhängige Features

- **Spielmodus (#25):** Nutzt Geräte-Config (Schriftgröße, Helligkeit, Touch-Zonen)
- **Noten-Import (#11):** Nutzt Kapellen-Config (Berechtigungen, AI-Keys)
- **Tuner/Metronom (MS3):** Nutzen Geräte-Config (Kammerton, Audio-Geräte)

---

## 8. Testing-Anforderungen

### 8.1 Unit-Tests

**Backend (.NET):**
- [ ] Config-Resolution mit allen Ebenen und Policies
- [ ] Policy-Blockierung: force_locale, force_dark_mode, allow_user_ai_keys
- [ ] Multi-Kapellen-Config bleibt isoliert
- [ ] Audit-Logging: Alle Änderungen werden protokolliert
- [ ] Permission-Checks: Nur Admins können Kapellen-Config ändern

**Frontend (Dart):**
- [ ] ConfigProvider löst Werte korrekt auf (Gerät > Nutzer > Kapelle > Default)
- [ ] Auto-Save und Undo-Toast Timing
- [ ] Offline-Queue: config_pending_sync wird bei Sync abgearbeitet
- [ ] Last-Write-Wins für bidirektionales Sync
- [ ] Versionierung pro Feld

### 8.2 Widget-Tests

- [ ] Kapelle-Einstellungen Screen: Admin sieht alle Felder, Nicht-Admin sieht sie nicht
- [ ] Nutzer-Einstellungen Screen: Alle Nutzer-Optionen änderbar
- [ ] Gerät-Einstellungen Screen: Nur Geräte-Ebenen-Felder
- [ ] Farbkodierung: Icons + Farbe + Label sind sichtbar
- [ ] Erzwungene Einstellungen: 🔒 Icon, deaktiviertes Input, Erklärtext
- [ ] Vererbung: "Standard von Kapelle" Button funktioniert
- [ ] Kontextuelle Overlay im Spielmodus: 5 Optionen, Auto-Close nach 5s
- [ ] Onboarding: Genau 5 Fragen, alle mit Skip-Button

### 8.3 Integration-Tests

- [ ] E2E: Admin ändert Kapellen-Config → andere Nutzer sehen Änderung
- [ ] E2E: Nutzer ändert Theme offline → wird synchronisiert
- [ ] E2E: Multi-Kapellen Config bleibt isoliert
- [ ] E2E: Policy-Aktivierung wirkt sich sofort auf UI aus
- [ ] E2E: Geräte-Config wird nicht synchronisiert (bleibt lokal)

### 8.4 Performance-Tests

- [ ] Config-Resolution < 10ms
- [ ] Sync POST /api/v1/config/nutzer/sync bei 100+ Feldern < 500ms
- [ ] UI-Update nach Theme-Änderung < 300ms
- [ ] Offline-Sync komplette Config in < 1s

### 8.5 Code Review

- **3-Reviewer-Process:** Sonnet 4.6, Opus 4.6, GPT 5.4
- **UX-Review:** Wanda (UX Designer) bestätigt alle UI-Screens
- **Lead-Review:** Stark entscheidet über Review-Ergebnisse

---

## 9. UX-Referenz

**Vollständige UX-Spezifikation:** `docs/ux-specs/konfiguration.md`

Abgedeckt:
- Navigation & Discovery (wie Nutzer zu Einstellungen gelangen)
- Wireframes: Phone & Tablet/Desktop
- Interaction Patterns (Auto-Save, Undo, Vererbung)
- Spielmodus-Overlay (Kontextuelle Einstellungen)
- Onboarding-Integration
- Edge Cases

---

## 10. Nicht im Scope (MS1)

❌ **Kalender-Sync:** Termin-Synchronisation mit Google Calendar, Apple Calendar, Outlook (MS2)

❌ **GEMA-Meldung:** Verwertungsgesellschaft-Konfiguration, Werknummern-Verwaltung (MS2)

❌ **Advanced AI:** Multi-Provider-Management, Batch-OCR mit Stimmen-Vorschlag (MS5)

❌ **Multi-Language:** Config wird nur auf Deutsch angeboten. i18n-Infrastruktur ist vorhanden, weitere Sprachen in MS5

❌ **Config-Profile/Export:** Speicherung und Wiederherstellung kompletter Config-Sets als Datei (MS5)

❌ **Config-Sharing:** Admin kann Config-Profil als Template an andere Kapellen weitergeben (MS5+)

❌ **Geräte-Backup:** Verschlüsseltes Backup von Geräte-Config zum Server (spätere Version, optional)

---

## 11. Definition of Done

- [ ] Backend: API-Endpunkte implementiert und getestet (Kapelle, Nutzer, Resolved, Policies)
- [ ] Backend: PostgreSQL Schema mit Audit-Log
- [ ] Frontend: SQLite/Drift lokale Config-Datenbank
- [ ] Frontend: ConfigProvider mit Riverpod für Zustandsverwaltung
- [ ] Frontend: Kapelle-Einstellungen Screen (Admin-Zugang)
- [ ] Frontend: Nutzer-Einstellungen Screen
- [ ] Frontend: Gerät-Einstellungen Screen
- [ ] Frontend: Spielmodus-Overlay mit 5 Optionen
- [ ] Frontend: Farbkodierung (Blau/Grün/Orange) mit Icons
- [ ] Frontend: Vererbung transparent — "Standard von X" mit "Eigenen Wert festlegen"
- [ ] Frontend: Erzwungene Einstellungen mit 🔒 Icon
- [ ] Frontend: Auto-Save + Undo-Toast (5 Sekunden)
- [ ] Frontend: Kontextuelle Einstellungen im Spielmodus funktionieren
- [ ] Frontend: Onboarding mit max. 5 Fragen
- [ ] Frontend: Keine Einstellung erfordert App-Neustart
- [ ] Frontend: Multi-Kapellen-Config korrekt isoliert
- [ ] Sync: Bidirektionales Sync für Nutzer-Ebene mit Versionierung
- [ ] Sync: Offline-Support mit Delta-Sync
- [ ] Sync: Kapellen-Config-Broadcast bei Änderungen
- [ ] Unit-Tests: ≥ 80% Coverage (Business-Logik)
- [ ] Widget-Tests: Alle kritischen UI-Flows
- [ ] Integration-Tests: API-Endpunkte, Sync-Szenarien
- [ ] E2E: Kapelle-Admin ändert Config → wird sichtbar für Nutzer
- [ ] E2E: Nutzer offline ändern → wird synchronisiert
- [ ] Performance: Config-Resolution < 10ms
- [ ] Performance: Sync < 500ms für 100+ Felder
- [ ] UX-Review: Wanda genehmigt alle Screens
- [ ] Code-Review: 3 unabhängige Reviews (Sonnet, Opus, GPT)
- [ ] Deployed und testbar auf iOS, Android, Windows, Web

---

**Status:** Draft — Wartet auf Thomas' Freigabe via PR-Review  
**Nächste Schritte:** Implementation starten nach PR-Merge

*Dieses Dokument ist ein definierendes Artefakt für Issue #33 und wird bei Änderungen aktualisiert.*
