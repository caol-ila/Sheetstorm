# Konfigurationskonzept — Sheetstorm

> Version: 1.0  
> Status: Entwurf  
> Autor: Stark (Lead / Architect)  
> Datum: 2026-03-28  
> Referenz: docs/spezifikation.md, docs/anforderungen.md

---

## 1. Überblick

Sheetstorm verwendet ein **dreistufiges Konfigurationssystem** mit klarer Vererbungshierarchie:

```
┌─────────────────────────────────────────────────────────────────┐
│  Ebene 3: Gerät (Device)                                        │
│  → Display, Audio, Touch, Offline-Speicher                      │
│  → Gewinnt bei Konflikten mit Ebene 2                           │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Ebene 2: Nutzer (User)                                   │  │
│  │  → Persönliche Präferenzen, Instrumente, AI-Keys          │  │
│  │  → Gewinnt bei Konflikten mit Ebene 1                     │  │
│  │                                                            │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  Ebene 1: Kapelle (Organization)                     │  │  │
│  │  │  → Rollen, AI-Zugang, Berechtigungen, Branding      │  │  │
│  │  │  → Liefert Defaults und Policies                     │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Grundprinzip:** Kapelle definiert Defaults und Richtlinien. Nutzer personalisiert. Gerät optimiert für die lokale Hardware. Höhere Ebenen überschreiben niedrigere — **es sei denn**, die Kapelle eine Policy setzt, die Override verbietet.

---

## 2. Ebene 1: Kapelle (Organization)

### 2.1 Warum diese Ebene?

Die Kapelle ist die organisatorische Einheit. Einstellungen auf dieser Ebene betreffen **alle Mitglieder** und stellen einheitliches Verhalten sicher. Admins definieren hier den Rahmen, innerhalb dessen sich Nutzer bewegen dürfen.

### 2.2 Konfigurationsfelder

| Gruppe | Einstellung | Typ | Default | Beschreibung |
|--------|------------|-----|---------|-------------|
| **AI** | `ai.provider` | `string` | `null` | Aktiver AI-Provider (z.B. "azure-vision") |
| **AI** | `ai.apiKey` | `encrypted` | `null` | Zentraler API-Key für die Kapelle |
| **AI** | `ai.allowUserKeys` | `boolean` | `true` | Dürfen Nutzer eigene AI-Keys verwenden? |
| **AI** | `ai.maxRequestsPerDay` | `integer` | `100` | Rate-Limit pro Tag (Kapellen-Key) |
| **AI** | `ai.confidenceThreshold` | `float` | `0.7` | Mindest-Konfidenz für Auto-Accept |
| **Berechtigungen** | `permissions.uploadRoles` | `string[]` | `["admin","dirigent","notenwart"]` | Rollen, die Noten hochladen dürfen |
| **Berechtigungen** | `permissions.setlistRoles` | `string[]` | `["admin","dirigent"]` | Rollen, die Setlists erstellen dürfen |
| **Berechtigungen** | `permissions.annotationOrchestra` | `string[]` | `["admin","dirigent"]` | Wer darf orchesterweit annotieren |
| **Berechtigungen** | `permissions.annotationStimme` | `string[]` | `["admin","dirigent","registerfuehrer"]` | Wer darf stimmen-weit annotieren |
| **Sprache** | `locale.default` | `string` | `"de"` | Standard-Sprache der Kapelle |
| **Branding** | `branding.name` | `string` | — | Kapellen-Name |
| **Branding** | `branding.logo` | `url` | `null` | Kapellen-Logo |
| **Branding** | `branding.primaryColor` | `color` | `"#1976D2"` | Primärfarbe für UI-Akzente |
| **Rollen** | `roles.defaults` | `object` | Standard-Matrix | Standard-Rollenzuweisungen bei Beitritt |
| **Rollen** | `roles.defaultNewMember` | `string` | `"musiker"` | Rolle für neue Mitglieder |
| **Noten** | `upload.maxFileSize` | `integer` | `52428800` | Max. Upload-Größe in Bytes (50 MB) |
| **Noten** | `upload.allowedFormats` | `string[]` | `["pdf","jpg","png","tiff"]` | Erlaubte Dateiformate |
| **Metronom** | `metronome.networkMode` | `string` | `"auto"` | `"wifi-udp"` / `"websocket"` / `"auto"` |
| **Policies** | `policies.forceLocale` | `boolean` | `false` | Erzwingt Kapellen-Sprache für alle |
| **Policies** | `policies.requireAnnotationReview` | `boolean` | `false` | Orchester-Annotationen brauchen Freigabe |

### 2.3 Wer darf ändern?

| Einstellung | Admin | Dirigent | Andere |
|------------|:-----:|:--------:|:------:|
| AI-Konfiguration | ✅ | ❌ | ❌ |
| Berechtigungen | ✅ | ❌ | ❌ |
| Branding | ✅ | ❌ | ❌ |
| Sprache & Policies | ✅ | ❌ | ❌ |
| Upload-Einstellungen | ✅ | ✅ | ❌ |
| Metronom-Netzwerkmodus | ✅ | ✅ | ❌ |

**Begründung:** Nur Admins haben vollen Zugriff. Dirigenten dürfen musikalisch relevante Einstellungen ändern (Upload, Metronom), aber keine organisatorischen Policies. Das entspricht der realen Vereinsstruktur.

---

## 3. Ebene 2: Nutzer (User)

### 3.1 Warum diese Ebene?

Der Nutzer hat persönliche Präferenzen, die kapellen-übergreifend gelten. Ein Musiker kann in mehreren Kapellen sein — seine persönlichen Einstellungen (Theme, Sprache, Instrumente) nimmt er überall mit.

### 3.2 Konfigurationsfelder

| Gruppe | Einstellung | Typ | Default | Sync | Beschreibung |
|--------|------------|-----|---------|:----:|-------------|
| **Darstellung** | `appearance.theme` | `enum` | `"system"` | ✅ | `"light"` / `"dark"` / `"system"` |
| **Darstellung** | `appearance.accentColor` | `color?` | `null` | ✅ | Persönliche Akzentfarbe (überschreibt Kapelle) |
| **Sprache** | `locale.preferred` | `string` | `"de"` | ✅ | Bevorzugte Sprache |
| **Instrumente** | `instruments[]` | `InstrumentProfil[]` | `[]` | ✅ | Instrumente die ich spiele |
| **Instrumente** | `instruments[].default` | `boolean` | — | ✅ | Hauptinstrument markiert |
| **Kapellen-Prefs** | `kapellePrefs[kapelleId].defaultStimme` | `string` | `null` | ✅ | Standard-Stimme pro Kapelle |
| **Kapellen-Prefs** | `kapellePrefs[kapelleId].activeRole` | `string` | — | ✅ | Bevorzugte Rolle (wenn mehrere) |
| **Benachrichtigungen** | `notifications.push` | `boolean` | `true` | ✅ | Push-Benachrichtigungen aktiviert |
| **Benachrichtigungen** | `notifications.email` | `boolean` | `false` | ✅ | E-Mail-Benachrichtigungen aktiviert |
| **Benachrichtigungen** | `notifications.termine` | `boolean` | `true` | ✅ | Termin-Erinnerungen |
| **Benachrichtigungen** | `notifications.neueNoten` | `boolean` | `true` | ✅ | Benachrichtigung bei neuen Noten |
| **Benachrichtigungen** | `notifications.annotationen` | `boolean` | `true` | ✅ | Benachrichtigung bei neuen Annotationen |
| **AI** | `ai.personalKey` | `encrypted?` | `null` | ✅* | Eigener AI-API-Key |
| **AI** | `ai.personalProvider` | `string?` | `null` | ✅* | Eigener AI-Provider |
| **AI** | `ai.preferPersonalKey` | `boolean` | `false` | ✅ | Persönlichen Key bevorzugen |
| **Spielmodus** | `playMode.pageTransition` | `enum` | `"swipe"` | ✅ | `"swipe"` / `"tap"` / `"scroll"` |
| **Spielmodus** | `playMode.showPageNumber` | `boolean` | `true` | ✅ | Seitennummer anzeigen |
| **Spielmodus** | `playMode.annotationLayers` | `string[]` | `["lokal","stimme","orchester"]` | ✅ | Sichtbare Annotations-Ebenen |
| **Cloud** | `cloud.provider` | `string?` | `null` | ✅ | `"onedrive"` / `"dropbox"` / `null` |
| **Cloud** | `cloud.autoSync` | `boolean` | `true` | ✅ | Automatische Synchronisation |

\* AI-Keys werden verschlüsselt gespeichert und nur als "vorhanden/nicht vorhanden" synchronisiert. Der eigentliche Schlüssel verlässt den Server nie unverschlüsselt.

### 3.3 Sync-Verhalten

Alle Nutzer-Einstellungen synchronisieren über den Server auf alle Geräte des Nutzers — **mit Ausnahme** von gerätespezifischen Einstellungen (siehe Ebene 3). Wenn der Nutzer offline ist, werden Änderungen lokal gespeichert und beim nächsten Online-Status synchronisiert. Last-Write-Wins reicht hier, da Nutzer-Settings selten parallel von zwei Geräten geändert werden.

---

## 4. Ebene 3: Gerät (Device)

### 4.1 Warum diese Ebene?

Ein Tablet hat andere Anforderungen als ein Smartphone oder Desktop. Schriftgrößen, Touch-Zonen, Audio-Routing und Speicherlimits müssen **pro Gerät** konfigurierbar sein. Diese Einstellungen reisen nicht mit — sie bleiben auf dem Gerät.

### 4.2 Konfigurationsfelder

| Gruppe | Einstellung | Typ | Default | Sync | Beschreibung |
|--------|------------|-----|---------|:----:|-------------|
| **Display** | `display.fontSize` | `enum` | `"medium"` | ❌ | `"small"` / `"medium"` / `"large"` / `"xlarge"` |
| **Display** | `display.zoomBehavior` | `enum` | `"auto"` | ❌ | `"auto"` / `"fitWidth"` / `"fitPage"` / `"manual"` |
| **Display** | `display.autoRotation` | `boolean` | `true` | ❌ | Auto-Rotation für Notenlinien |
| **Display** | `display.keepScreenOn` | `boolean` | `true` | ❌ | Bildschirm im Spielmodus aktiv halten |
| **Display** | `display.brightness` | `enum` | `"system"` | ❌ | `"system"` / `"max"` / `"custom"` |
| **Display** | `display.orientationLock` | `enum` | `"auto"` | ❌ | `"auto"` / `"portrait"` / `"landscape"` |
| **Audio** | `audio.tunerInputSource` | `string` | `"default"` | ❌ | Mikrofon-Auswahl |
| **Audio** | `audio.tunerSensitivity` | `float` | `0.5` | ❌ | Tuner-Empfindlichkeit (0–1) |
| **Audio** | `audio.tunerReferenceHz` | `integer` | `442` | ❌ | Kammerton (430–450 Hz) |
| **Audio** | `audio.tunerTransposition` | `integer` | `0` | ❌ | Transposition in Halbtönen |
| **Audio** | `audio.metronomeVolume` | `float` | `0.8` | ❌ | Metronom-Lautstärke (0–1) |
| **Audio** | `audio.metronomeSound` | `string` | `"click"` | ❌ | Klang: `"click"` / `"wood"` / `"beep"` |
| **Audio** | `audio.metronomeVibrate` | `boolean` | `true` | ❌ | Vibration bei Beat |
| **Offline** | `offline.maxStorageMB` | `integer` | `1024` | ❌ | Maximaler Offline-Speicher in MB |
| **Offline** | `offline.autoDownload` | `enum` | `"wifi"` | ❌ | `"always"` / `"wifi"` / `"never"` |
| **Offline** | `offline.imageQuality` | `enum` | `"high"` | ❌ | `"low"` / `"medium"` / `"high"` / `"original"` |
| **Touch** | `touch.swipeSensitivity` | `float` | `0.5` | ❌ | Swipe-Schwellwert für Seitenwechsel |
| **Touch** | `touch.doubleTapZoom` | `boolean` | `true` | ❌ | Double-Tap-to-Zoom aktiviert |
| **Touch** | `touch.edgeTapZones` | `boolean` | `true` | ❌ | Seitenrand-Tipp-Zonen für Vor/Zurück |
| **Touch** | `touch.edgeTapWidth` | `float` | `0.15` | ❌ | Breite der Tipp-Zone (0–0.5, relativ) |
| **Touch** | `touch.stylusMode` | `enum` | `"auto"` | ❌ | `"auto"` / `"annotate"` / `"navigate"` |

### 4.3 Warum nicht synchronisieren?

- Ein iPad braucht andere Schriftgrößen als ein Smartphone.
- Der Tuner muss auf jedes Mikrofon individuell kalibriert werden.
- Offline-Speicher hängt vom verfügbaren Gerätespeicher ab.
- Touch-Einstellungen sind stark gerätespezifisch (Bildschirmgröße bestimmt Touch-Zonen).

---

## 5. Vererbung & Override-Regeln

### 5.1 Grundregel

```
Effektiver Wert = Gerät ?? Nutzer ?? Kapelle ?? System-Default
```

Der **erste nicht-null Wert** gewinnt, von oben (Gerät) nach unten (System-Default).

### 5.2 Policy-Override (Kapelle erzwingt)

Bestimmte Kapellen-Einstellungen können als **Policy** erzwungen werden. Eine Policy verhindert, dass Nutzer oder Gerät die Einstellung überschreiben.

| Policy | Effekt | Beispiel |
|--------|--------|---------|
| `policies.forceLocale = true` | Nutzer-Spracheinstellung wird ignoriert, Kapellen-Sprache erzwungen | Kapelle will einheitlich Deutsch |
| `ai.allowUserKeys = false` | Nutzer kann keinen eigenen AI-Key verwenden | Kapelle will AI-Nutzung kontrollieren |
| `policies.requireAnnotationReview = true` | Orchester-Annotationen brauchen Admin-Freigabe | Dirigent will Qualitätskontrolle |

### 5.3 Konfliktauflösung — Entscheidungsmatrix

| Szenario | Kapelle | Nutzer | Effekt | Begründung |
|----------|---------|--------|--------|-----------|
| AI-Key vorhanden | Hat Kapellen-Key | Hat eigenen Key | **Nutzer-Key** wird verwendet (Fallback-Kette: User → Kapelle) | Nutzer hat explizit konfiguriert |
| AI-Key + Policy | Hat Key, `allowUserKeys=false` | Hat eigenen Key | **Kapellen-Key** — Nutzer-Key wird ignoriert | Policy erzwingt zentralen Zugang |
| Kein AI-Key | Kein Key | Kein Key | **Keine AI** — Features deaktiviert, manuelle Eingabe | Graceful degradation |
| Sprache | `locale.default = "de"` | `locale.preferred = "en"` | **Englisch** — Nutzer gewinnt | Persönliche Präferenz |
| Sprache + Policy | `forceLocale = true`, `de` | `locale.preferred = "en"` | **Deutsch** — Policy erzwingt | Kapelle will Einheitlichkeit |
| Theme | — | `theme = "dark"` | **Dark** — Nutzer-Wahl | Rein persönlich, keine Kapellen-Relevanz |
| Schriftgröße | — | — | **Gerät-Einstellung** | Hardware-spezifisch |

### 5.4 Besonderheit: Multi-Kapellen

Ein Musiker kann in mehreren Kapellen sein. Kapellen-Einstellungen gelten **nur im Kontext der jeweiligen Kapelle**. Wenn der Nutzer zwischen Kapellen wechselt, wechseln auch die effektiven Kapellen-Einstellungen:

```
Aktive Kapelle: Musikverein Harmonie
  → AI via Kapellen-Key (Azure Vision)
  → Sprache: Deutsch (Policy: erzwungen)
  → Branding: Blau

Aktive Kapelle: Jugendorchester Klangwerk  
  → AI via persönlicher Key (OpenAI)
  → Sprache: Englisch (keine Policy, Nutzer-Wahl)
  → Branding: Grün
```

Nutzer- und Geräte-Einstellungen bleiben kapellen-unabhängig stabil.

---

## 6. Datenmodell

### 6.1 Kapellen-Konfiguration

```json
{
  "kapelleId": "uuid",
  "config": {
    "ai": {
      "provider": "azure-vision",
      "apiKey": "[encrypted]",
      "allowUserKeys": true,
      "maxRequestsPerDay": 100,
      "confidenceThreshold": 0.7
    },
    "permissions": {
      "uploadRoles": ["admin", "dirigent", "notenwart"],
      "setlistRoles": ["admin", "dirigent"],
      "annotationOrchestra": ["admin", "dirigent"],
      "annotationStimme": ["admin", "dirigent", "registerfuehrer"]
    },
    "locale": { "default": "de" },
    "branding": {
      "name": "Musikverein Harmonie",
      "logo": "https://storage.../logo.png",
      "primaryColor": "#1976D2"
    },
    "roles": {
      "defaultNewMember": "musiker"
    },
    "upload": {
      "maxFileSize": 52428800,
      "allowedFormats": ["pdf", "jpg", "png", "tiff"]
    },
    "metronome": { "networkMode": "auto" },
    "policies": {
      "forceLocale": false,
      "requireAnnotationReview": false
    }
  },
  "updatedAt": "ISO-8601",
  "updatedBy": "uuid"
}
```

### 6.2 Nutzer-Konfiguration

```json
{
  "musikerId": "uuid",
  "config": {
    "appearance": {
      "theme": "dark",
      "accentColor": null
    },
    "locale": { "preferred": "de" },
    "instruments": [
      {
        "instrumentId": "uuid-klarinette",
        "name": "Klarinette",
        "default": true
      },
      {
        "instrumentId": "uuid-saxophon",
        "name": "Altsaxophon",
        "default": false
      }
    ],
    "kapellePrefs": {
      "uuid-kapelle-1": {
        "defaultStimme": "2. Klarinette",
        "activeRole": "musiker"
      },
      "uuid-kapelle-2": {
        "defaultStimme": "1. Altsaxophon",
        "activeRole": "notenwart"
      }
    },
    "notifications": {
      "push": true,
      "email": false,
      "termine": true,
      "neueNoten": true,
      "annotationen": true
    },
    "ai": {
      "personalProvider": "openai-gpt4v",
      "personalKeySet": true,
      "preferPersonalKey": false
    },
    "playMode": {
      "pageTransition": "swipe",
      "showPageNumber": true,
      "annotationLayers": ["lokal", "stimme", "orchester"]
    },
    "cloud": {
      "provider": "onedrive",
      "autoSync": true
    }
  },
  "updatedAt": "ISO-8601"
}
```

### 6.3 Geräte-Konfiguration

```json
{
  "deviceId": "uuid",
  "musikerId": "uuid",
  "deviceInfo": {
    "platform": "ios",
    "model": "iPad Pro 12.9",
    "osVersion": "18.2",
    "appVersion": "1.2.0"
  },
  "config": {
    "display": {
      "fontSize": "large",
      "zoomBehavior": "auto",
      "autoRotation": true,
      "keepScreenOn": true,
      "brightness": "system",
      "orientationLock": "landscape"
    },
    "audio": {
      "tunerInputSource": "default",
      "tunerSensitivity": 0.6,
      "tunerReferenceHz": 442,
      "tunerTransposition": 0,
      "metronomeVolume": 0.8,
      "metronomeSound": "click",
      "metronomeVibrate": true
    },
    "offline": {
      "maxStorageMB": 2048,
      "autoDownload": "wifi",
      "imageQuality": "high"
    },
    "touch": {
      "swipeSensitivity": 0.5,
      "doubleTapZoom": true,
      "edgeTapZones": true,
      "edgeTapWidth": 0.15,
      "stylusMode": "auto"
    }
  },
  "updatedAt": "ISO-8601"
}
```

### 6.4 Datenbank-Schema

```sql
-- Kapellen-Konfiguration (1:1 zu Kapelle)
CREATE TABLE kapelle_config (
    kapelle_id UUID PRIMARY KEY REFERENCES kapelle(id),
    config JSONB NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES musiker(id)
);

-- Nutzer-Konfiguration (1:1 zu Musiker, synced)
CREATE TABLE user_config (
    musiker_id UUID PRIMARY KEY REFERENCES musiker(id),
    config JSONB NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    config_version INTEGER NOT NULL DEFAULT 1
);

-- Geräte-Konfiguration (N:1 zu Musiker, lokal + Server-Backup)
CREATE TABLE device_config (
    device_id UUID PRIMARY KEY,
    musiker_id UUID NOT NULL REFERENCES musiker(id),
    device_info JSONB NOT NULL DEFAULT '{}',
    config JSONB NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_device_config_musiker ON device_config(musiker_id);
```

**Warum JSONB?** Konfigurationen sind semi-strukturiert und ändern sich häufig in der Schema-Definition (neue Einstellungen). JSONB in PostgreSQL erlaubt flexible Erweiterung ohne Migrationen, mit voller Query-Fähigkeit und Indexierung auf einzelne JSON-Pfade.

---

## 7. Sync-Strategie

### 7.1 Was synchronisiert wohin?

```
┌─────────────┐     sync      ┌─────────────┐     sync      ┌─────────────┐
│  Gerät A    │◄─────────────▶│   Server     │◄─────────────▶│  Gerät B    │
│             │               │              │               │             │
│ ► Device-   │               │ ► Kapelle-   │               │ ► Device-   │
│   Config    │               │   Config     │               │   Config    │
│   (lokal)   │               │ ► User-      │               │   (lokal)   │
│             │               │   Config     │               │             │
│ ► User-     │               │ ► Device-    │               │ ► User-     │
│   Config    │               │   Config     │               │   Config    │
│   (cached)  │               │   (Backup)   │               │   (cached)  │
└─────────────┘               └─────────────┘               └─────────────┘
```

| Konfiguration | Primärspeicher | Sync-Richtung | Strategie |
|--------------|----------------|---------------|-----------|
| **Kapelle** | Server | Server → Client (readonly für die meisten) | Pull bei Kapellen-Wechsel / App-Start |
| **Nutzer** | Server | Bidirektional (Client ↔ Server) | Optimistic Update, Last-Write-Wins per Feld |
| **Gerät** | Lokal (SQLite/SharedPreferences) | Client → Server (Backup only) | Gerät ist Source of Truth, Server speichert Backup |

### 7.2 Sync-Protokoll

1. **App-Start:** Client holt aktuelle Kapellen- und Nutzer-Config vom Server. Wenn offline, werden gecachte Versionen verwendet.
2. **Nutzer ändert Setting:** Sofort lokal angewendet (optimistic), dann an Server gesendet. Server antwortet mit `config_version`. Bei Konflikt (Version-Mismatch): Last-Write-Wins per Feld (nicht per ganzes Config-Objekt).
3. **Kapelle ändert Setting:** Admin ändert auf Server. Push-Notification an alle Mitglieder. Clients refreshen bei nächster Aktivität.
4. **Geräte-Config:** Wird primär lokal gespeichert. Optional Server-Backup für Gerätewechsel / Neuinstallation.

### 7.3 Offline-Verhalten

- Alle Config-Werte sind lokal gecacht und sofort verfügbar.
- Änderungen werden in eine lokale Queue geschrieben.
- Bei Reconnect: Queue wird abgearbeitet, Konflikte per Feld-Level-Merge aufgelöst.
- Kapellen-Policies werden beim letzten bekannten Stand angewendet (fail-safe: im Zweifel restriktiver).

---

## 8. Admin-/Berechtigungsmodell

### 8.1 Wer darf was konfigurieren?

```
                          ┌──────────────────┐
                          │  Kapellen-Config  │
                          │  (Ebene 1)       │
                          └────────┬─────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼
              ┌──────────┐  ┌──────────┐  ┌──────────┐
              │  Admin    │  │ Dirigent │  │  Andere  │
              │ Alles     │  │ Musik-   │  │ Nichts   │
              │           │  │ relevant │  │          │
              └──────────┘  └──────────┘  └──────────┘

                          ┌──────────────────┐
                          │  Nutzer-Config    │
                          │  (Ebene 2)       │
                          └────────┬─────────┘
                                   │
                              ┌────▼────┐
                              │ Nutzer  │
                              │ selbst  │
                              └─────────┘

                          ┌──────────────────┐
                          │  Geräte-Config    │
                          │  (Ebene 3)       │
                          └────────┬─────────┘
                                   │
                              ┌────▼────┐
                              │ Nutzer  │
                              │ auf dem │
                              │ Gerät   │
                              └─────────┘
```

### 8.2 Audit-Trail

Änderungen an Kapellen-Konfigurationen werden protokolliert:

```json
{
  "kapelleId": "uuid",
  "changedBy": "uuid",
  "changedAt": "ISO-8601",
  "path": "ai.allowUserKeys",
  "oldValue": true,
  "newValue": false,
  "reason": "Zentrale AI-Verwaltung eingeführt"
}
```

Nutzer- und Geräte-Konfigurationen werden **nicht** auditiert (Datensparsamkeit, DSGVO).

---

## 9. Konfigurationsbaum — Vollständige Übersicht

```
sheetstorm-config/
│
├── kapelle/                          ← Ebene 1: Organisation
│   ├── ai/
│   │   ├── provider                  Aktiver AI-Provider
│   │   ├── apiKey                    Zentraler API-Key [encrypted]
│   │   ├── allowUserKeys             Dürfen Nutzer eigene Keys nutzen?
│   │   ├── maxRequestsPerDay         Rate-Limit pro Tag
│   │   └── confidenceThreshold       Auto-Accept-Schwellwert
│   ├── permissions/
│   │   ├── uploadRoles               Wer darf Noten hochladen
│   │   ├── setlistRoles              Wer darf Setlists erstellen
│   │   ├── annotationOrchestra       Wer darf orchesterweit annotieren
│   │   └── annotationStimme          Wer darf stimmenweit annotieren
│   ├── locale/
│   │   └── default                   Standard-Sprache
│   ├── branding/
│   │   ├── name                      Kapellen-Name
│   │   ├── logo                      Logo-URL
│   │   └── primaryColor              Primärfarbe
│   ├── roles/
│   │   └── defaultNewMember          Standardrolle bei Beitritt
│   ├── upload/
│   │   ├── maxFileSize               Max. Dateigröße
│   │   └── allowedFormats            Erlaubte Formate
│   ├── metronome/
│   │   └── networkMode               Netzwerkmodus
│   └── policies/
│       ├── forceLocale               Sprache erzwingen
│       └── requireAnnotationReview   Annotationen brauchen Freigabe
│
├── nutzer/                           ← Ebene 2: User
│   ├── appearance/
│   │   ├── theme                     Light/Dark/System
│   │   └── accentColor               Persönliche Akzentfarbe
│   ├── locale/
│   │   └── preferred                 Bevorzugte Sprache
│   ├── instruments[]/
│   │   ├── instrumentId              Instrument-Referenz
│   │   ├── name                      Anzeigename
│   │   └── default                   Hauptinstrument?
│   ├── kapellePrefs{kapelleId}/
│   │   ├── defaultStimme             Standard-Stimme in dieser Kapelle
│   │   └── activeRole                Bevorzugte Rolle
│   ├── notifications/
│   │   ├── push                      Push aktiviert
│   │   ├── email                     E-Mail aktiviert
│   │   ├── termine                   Termin-Erinnerungen
│   │   ├── neueNoten                 Neue-Noten-Benachrichtigung
│   │   └── annotationen              Annotations-Benachrichtigung
│   ├── ai/
│   │   ├── personalProvider          Eigener AI-Provider
│   │   ├── personalKeySet            Hat eigenen Key? (bool)
│   │   └── preferPersonalKey         Eigenen Key bevorzugen?
│   ├── playMode/
│   │   ├── pageTransition            Seitenwechsel-Modus
│   │   ├── showPageNumber            Seitennummer anzeigen
│   │   └── annotationLayers          Sichtbare Annotations-Ebenen
│   └── cloud/
│       ├── provider                  Cloud-Provider
│       └── autoSync                  Auto-Sync aktiviert
│
└── geraet/                           ← Ebene 3: Device
    ├── display/
    │   ├── fontSize                  Schriftgröße
    │   ├── zoomBehavior              Zoom-Verhalten
    │   ├── autoRotation              Auto-Rotation
    │   ├── keepScreenOn              Bildschirm aktiv halten
    │   ├── brightness                Helligkeit
    │   └── orientationLock           Orientierungssperre
    ├── audio/
    │   ├── tunerInputSource          Mikrofon-Auswahl
    │   ├── tunerSensitivity          Tuner-Empfindlichkeit
    │   ├── tunerReferenceHz          Kammerton
    │   ├── tunerTransposition        Transposition
    │   ├── metronomeVolume           Metronom-Lautstärke
    │   ├── metronomeSound            Metronom-Klang
    │   └── metronomeVibrate          Vibration bei Beat
    ├── offline/
    │   ├── maxStorageMB              Max. Offline-Speicher
    │   ├── autoDownload              Auto-Download-Modus
    │   └── imageQuality              Bild-Qualität
    └── touch/
        ├── swipeSensitivity          Swipe-Empfindlichkeit
        ├── doubleTapZoom             Double-Tap-Zoom
        ├── edgeTapZones              Rand-Tipp-Zonen
        ├── edgeTapWidth              Breite der Tipp-Zonen
        └── stylusMode                Stift-Modus
```

---

## 10. API-Endpunkte für Konfiguration

```
/api/v1/
├── config/
│   ├── GET    /kapelle/:kapelleId           Kapellen-Config lesen
│   ├── PATCH  /kapelle/:kapelleId           Kapellen-Config ändern (Admin/Dirigent)
│   ├── GET    /kapelle/:kapelleId/audit     Audit-Trail abrufen (Admin)
│   │
│   ├── GET    /user                          Eigene Nutzer-Config lesen
│   ├── PATCH  /user                          Eigene Nutzer-Config ändern
│   │
│   ├── GET    /device/:deviceId              Geräte-Config lesen
│   ├── PATCH  /device/:deviceId              Geräte-Config ändern
│   ├── GET    /devices                       Alle Geräte des Nutzers
│   └── DELETE /device/:deviceId              Gerät entfernen
│
│   └── GET    /effective/:kapelleId          Effektive Config (alle Ebenen gemerged)
```

Der `/effective/:kapelleId`-Endpunkt liefert die **aufgelöste** Konfiguration für den aktuellen Nutzer im Kontext einer Kapelle — alle Override-Regeln bereits angewendet. Das ist der Endpunkt, den der Client primär nutzt.

---

## 11. Implementierungshinweise

### 11.1 Config-Resolution im Client

```typescript
function resolveConfig(
  kapelleConfig: KapelleConfig,
  userConfig: UserConfig,
  deviceConfig: DeviceConfig
): EffectiveConfig {
  return {
    // Sprache: Policy prüfen, dann User, dann Kapelle
    locale: kapelleConfig.policies.forceLocale
      ? kapelleConfig.locale.default
      : userConfig.locale.preferred ?? kapelleConfig.locale.default,
    
    // Theme: Rein User-Sache
    theme: userConfig.appearance.theme,
    
    // Schriftgröße: Rein Gerät-Sache
    fontSize: deviceConfig.display.fontSize,
    
    // AI-Provider: Policy prüfen, dann Fallback-Kette
    aiProvider: resolveAiProvider(kapelleConfig, userConfig),
    
    // ... weitere Felder
  };
}

function resolveAiProvider(
  kapelle: KapelleConfig,
  user: UserConfig
): AiConfig | null {
  // Policy: Kapelle verbietet User-Keys
  if (!kapelle.ai.allowUserKeys) {
    return kapelle.ai.provider ? kapelle.ai : null;
  }
  // User bevorzugt eigenen Key und hat einen
  if (user.ai.preferPersonalKey && user.ai.personalKeySet) {
    return user.ai;
  }
  // Fallback: Kapelle → User → null
  return kapelle.ai.provider ? kapelle.ai
       : user.ai.personalKeySet ? user.ai
       : null;
}
```

### 11.2 Migration & Versionierung

- Config-Schema hat eine Version pro Ebene
- Migrations-Funktionen transformieren alte Formate in neue
- Neue Einstellungen bekommen immer Defaults → kein Breaking Change
- Client und Server müssen kompatible Config-Versionen sprechen (API-Versionierung)

---

*Dieses Dokument definiert das verbindliche Konfigurationskonzept für Sheetstorm. Erweiterungen werden als neue Version dokumentiert.*
