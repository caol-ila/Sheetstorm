# Feature-Spezifikation: Stimmenauswahl & Fallback-Logik

> **Issue:** #29  
> **Meilenstein:** MS1  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Draft — Wanda UX (#28) in Arbeit  
> **Depends on:** #28 (UX Stimmenauswahl), #7 (Backend), #8 (Flutter Scaffolding), #25 (Spielmodus-Spec)  
> **Blocked by:** —  
> **UX-Referenz:** `docs/ux-design.md` §3.1 (Stimme wechseln Bottom Sheet), `docs/anforderungen.md` §1.1a

---

## 1. Feature-Überblick

### Beschreibung

Stimmenauswahl ist das Fundament des Spielmodus: Die App weiß, welche Stimme ein Musiker spielt, und zeigt beim Öffnen eines Stücks automatisch die richtige Stimme. Wenn die exakte Stimme nicht vorhanden ist, findet die App die nächstliegende.

**Kernprinzip:** Der Musiker muss **nichts** konfigurieren müssen. Die App wählt intelligent vor — er kann übersteuern, muss aber nicht.

### Scope MS1 (In-Scope)

- ✅ Nutzer definiert Standard-Instrument(e) und Standard-Stimme pro Kapelle
- ✅ Automatische Vorauswahl beim Öffnen eines Stücks
- ✅ Fallback-Algorithmus: exakte Stimme → nächstliegende → erste verfügbare
- ✅ Stimme wechseln im Spielmodus (Bottom Sheet)
- ✅ Stimmen-Sortierung: eigene Instrumente oben, andere darunter
- ✅ Mehrere Instrumente pro Musiker
- ✅ API: GET Stimmen-Liste, PUT Nutzer-Instrumente
- ✅ Kapellen-spezifische Instrument-Zuordnung

### Out-of-Scope MS1 (Später)

- ❌ 1-Klick-Stimmenneuverteilung (MS2 — Dirigenten-Feature)
- ❌ AI-gestützte Stimmen-Vorschläge beim Import (Teil Import-Spec #20)
- ❌ Stimmgruppen-Verwaltung (MS2)
- ❌ Aushilfen-Stimmen-Zuordnung (Teil #6 Aushilfen-Spec)

---

## 2. User Stories

### US-01: Standard-Stimme festlegen

**Als** Musiker  
**möchte ich** für jede Kapelle meine Standard-Stimme festlegen  
**damit** beim Öffnen eines Stücks automatisch meine Stimme angezeigt wird.

**Akzeptanzkriterien:**
- [ ] AC-01: Im Nutzerprofil kann ein Musiker **pro Kapelle** eine Standard-Stimme festlegen (z.B. „Kapelle Beispiel: 2. Klarinette")
- [ ] AC-02: Die Standard-Stimme ist an ein Instrument gebunden (z.B. Instrument = Klarinette, Standard-Stimme = 2. Klarinette)
- [ ] AC-03: Ein Musiker kann **mehrere Instrumente** angeben — pro Instrument eine Standard-Stimme
- [ ] AC-04: Standard-Stimme kann jederzeit im Profil geändert werden — sofortige Wirkung (kein App-Neustart)
- [ ] AC-05: Beim Onboarding: Instrument-Auswahl ist **Schritt 1** — max. 5 Fragen gesamt (decisions.md)
- [ ] AC-06: Standard-Stimme wird **nicht** überschrieben, wenn der Musiker im Spielmodus eine andere Stimme wählt (temporäres Override, keine persistente Änderung)

---

### US-02: Automatische Vorauswahl beim Öffnen eines Stücks

**Als** Musiker  
**möchte ich** beim Öffnen eines Stücks sofort meine Standard-Stimme sehen  
**damit** ich ohne Konfiguration sofort spielen kann.

**Akzeptanzkriterien:**
- [ ] AC-07: Beim Öffnen eines Stücks wird die Standard-Stimme des Nutzers **automatisch vorausgewählt** — kein zusätzlicher Tap erforderlich
- [ ] AC-08: Visueller Hinweis bei Vorauswahl: kurzer Toast oder Chip: **„Deine Stimme: 2. Klarinette"** — verschwindet nach 3 Sekunden
- [ ] AC-09: Wenn die exakte Standard-Stimme vorhanden ist: direkt laden, **kein** Auswahl-Dialog
- [ ] AC-10: Wenn die Standard-Stimme **nicht** vorhanden ist: Fallback-Algorithmus greift (→ US-03) — der Musiker sieht einen Hinweis welche Stimme stattdessen gewählt wurde
- [ ] AC-11: Fallback-Hinweis: **„Deine Stimme (2. Klarinette) nicht gefunden — 1. Klarinette angezeigt [Stimme wechseln]"**
- [ ] AC-12: Wenn **gar keine** Stimme zugeordnet werden kann: der Musiker sieht eine neutrale Übersicht aller verfügbaren Stimmen zur manuellen Auswahl
- [ ] AC-13: Vorauswahl-Logik läuft **synchron** — keine Verzögerung vor dem ersten Rendering

---

### US-03: Fallback-Logik

**Als** Musiker  
**möchte ich**, dass die App automatisch eine passende Ersatz-Stimme findet wenn meine Standard-Stimme nicht vorhanden ist  
**damit** ich auch in Kapellen mit anderen Stimm-Bezeichnungen spielen kann.

**Akzeptanzkriterien:**
- [ ] AC-14: Fallback-Algorithmus wird in Abschnitt 4 vollständig spezifiziert und ist **testbar** (Unit Test für jeden Schritt)
- [ ] AC-15: Fallback läuft **automatisch** — der Musiker muss nicht eingreifen
- [ ] AC-16: Fallback-Ergebnis ist **immer transparent** — der Musiker sieht welche Stimme gewählt wurde und warum
- [ ] AC-17: Wenn kein Fallback möglich ist (leeres Stück, keine Stimmen): klare Fehlermeldung statt leerem Bildschirm

---

### US-04: Stimme wechseln (im Spielmodus)

**Als** Musiker  
**möchte ich** jederzeit aus dem Spielmodus heraus die Stimme wechseln  
**damit** ich spontan als Einspringer eine andere Stimme übernehmen kann.

**Akzeptanzkriterien:**
- [ ] AC-18: „Stimme wechseln" ist über den `🎵 Stimme`-Button in der Spielmodus-Overlay-Leiste erreichbar
- [ ] AC-19: Das Bottom-Sheet zeigt zwei Sektionen: **„Meine Instrumente"** (oben, hervorgehoben) und **„Andere Stimmen"** (unten, alphabetisch)
- [ ] AC-20: Aktuell gewählte Stimme ist mit einem Checkmark (`✓`) markiert
- [ ] AC-21: Stimme wechseln beginnt auf Seite 1 der neuen Stimme
- [ ] AC-22: Cross-Fade-Animation 300ms beim Stimme-Wechsel (aus Spielmodus-Spec #25 — AC-41)
- [ ] AC-23: Das Wechseln der Stimme ändert **nicht** die gespeicherte Standard-Stimme des Nutzers

---

### US-05: Mehrere Instrumente

**Als** Musiker der mehrere Instrumente spielt  
**möchte ich** alle meine Instrumente in meinem Profil hinterlegen können  
**damit** die App bei verschiedenen Kapellen oder Stücken die passende Stimme vorauswählt.

**Akzeptanzkriterien:**
- [ ] AC-24: Ein Musiker kann **1..n Instrumente** in seinem Profil angeben
- [ ] AC-25: Für jedes Instrument kann eine bevorzugte Standard-Stimme **pro Kapelle** gesetzt werden
- [ ] AC-26: Bei Stücken mit Stimmen für mehrere Instrumente des Musikers: Das Instrument mit der **spezifischeren Übereinstimmung** gewinnt (z.B. „2. Klarinette" vor generisch „Klarinette")
- [ ] AC-27: Stimmen-Liste sortiert nach: (1) Exakte Übereinstimmung mit Standard-Stimme, (2) Andere Stimmen des eigenen Instruments, (3) Stimmen anderer eigener Instrumente, (4) Alle übrigen Stimmen alphabetisch
- [ ] AC-28: Instrument-Auswahl im Profil: Freitext-Suche + Auswahl aus vordefinierten Instrument-Typen (Liste in Abschnitt 6)

---

## 3. Stimmen-Sortierung in der Auswahlliste

Die Reihenfolge in der Stimmen-Auswahlliste (Spielmodus Bottom-Sheet und Stück-Detail):

```
┌─────────────────────────────┐
│  Stimme wechseln      ✕    │
├─────────────────────────────┤
│  MEINE INSTRUMENTE          │  ← Sektion 1
│  ✓ 2. Klarinette  ●───── ← Aktuell gewählt (Standard-Stimme)
│    1. Klarinette            │  ← Selbe Instrument-Familie
│    Klarinette in B          │  ← Selbe Instrument-Familie
│    Bassklarinette           │  ← Nahes Instrument (wenn im Profil)
├─────────────────────────────┤
│  ANDERE STIMMEN             │  ← Sektion 2
│    Flöte 1                  │  ← Alphabetisch
│    Flöte 2                  │
│    Oboe                     │
│    Trompete 1               │
│    ...                      │
└─────────────────────────────┘
```

**Sortier-Algorithmus Sektion 1 (Meine Instrumente):**
1. Exakte Standard-Stimme des Nutzers für dieses Stück (markiert mit ✓)
2. Andere Stimmen desselben Instruments (z.B. alle Klarinetten-Stimmen), alphabetisch
3. Stimmen anderer Instrumente des Nutzers, alphabetisch

**Sortier-Algorithmus Sektion 2 (Andere Stimmen):**
- Alle verbleibenden Stimmen, alphabetisch nach Stimmen-Bezeichnung

---

## 4. Fallback-Algorithmus

### 4.1 Vollständige Fallback-Kette

**Input:** Nutzer-Standard-Stimme (z.B. `"2. Klarinette"`) + verfügbare Stimmen des Stücks

```
Schritt 1: Exakte Übereinstimmung
  → Suche: stimme.bezeichnung == nutzer.standard_stimme (case-insensitive, trim)
  → Gefunden? → Fertig ✓

Schritt 2: Gleiche Stimmen-Familie + niedrigste Nummer
  → Suche: stimme.instrument_typ == nutzer.instrument_typ
           ORDER BY stimmen_nummer ASC
  → Beispiel: „2. Klarinette" → „1. Klarinette" (gleiche Familie, niedrigste Nr.)
  → Gefunden? → Fertig ✓ (mit Hinweis: „Fallback: 1. Klarinette")

Schritt 3: Generische Stimme desselben Instruments
  → Suche: stimme.bezeichnung == nutzer.instrument_typ (ohne Nummer)
  → Beispiel: „Klarinette" (ohne Zahl)
  → Gefunden? → Fertig ✓ (mit Hinweis)

Schritt 4: Verwandte Instrument-Familie
  → Suche: stimme.instrument_familie == nutzer.instrument_familie
           ORDER BY prioritaet_in_familie ASC
  → Beispiel: Klarinette → Bassklarinette, Oboe (Holzbläser-Familie)
  → Gefunden? → Fertig ✓ (mit Hinweis: „Nächstliegende Stimme: Bassklarinette")

Schritt 5: Erste verfügbare Stimme
  → Erste Stimme der Stückliste (Index 0)
  → Gefunden? → Fertig ✓ (mit Hinweis: „Keine passende Stimme — [Stimmname] angezeigt")

Schritt 6: Kein Fallback möglich
  → Stück hat keine Stimmen (leeres Stück / noch nicht gela beled)
  → Zeige Übersicht mit Meldung: „Für dieses Stück sind noch keine Stimmen verfügbar."
  → [Stimmen-Zuweisung starten] (nur für berechtigte Rollen)
```

### 4.2 Fallback-Beispiele

| Nutzer-Standard | Verfügbare Stimmen | Fallback-Ergebnis | Schritt |
|----------------|-------------------|-------------------|---------|
| 2. Klarinette | 1. Klar., 2. Klar., 3. Klar. | **2. Klarinette** | 1 (exakt) |
| 2. Klarinette | 1. Klar., 3. Klar. | **1. Klarinette** | 2 (gleiche Familie, niedrigste Nr.) |
| 2. Klarinette | Klarinette | **Klarinette** | 3 (generisch) |
| 2. Klarinette | Flöte 1, Oboe | **Flöte 1** | 4 (Holzbläser-Familie) |
| 2. Klarinette | Trompete 1, Trompete 2 | **Trompete 1** | 5 (erste verfügbar) |
| 2. Klarinette | *(keine Stimmen)* | **Fehler-UI** | 6 |

### 4.3 Instrument-Familien (MS1)

Vordefinierte Zuordnung für Fallback-Schritt 4:

| Familie | Instrumente |
|---------|-------------|
| Holzbläser | Flöte, Oboe, Klarinette (alle), Fagott, Saxophon (alle) |
| Blechbläser | Trompete, Flügelhorn, Horn, Tenorhorn, Posaune (alle), Tuba, Euphonium |
| Schlagwerk | Kleine Trommel, Große Trommel, Becken, Pauken, Schlagzeug, Marimba |
| Keyboards | Klavier, Orgel, Akkordeon |

**Priorität innerhalb Familie:** Instrument-Familien-Prioritätsliste wird initial vom Admin pro Kapelle konfiguriert; Default aus Standardliste.

### 4.4 Stimmen-Matching: Normalisierung

Für Schritt 1 und 2 wird die Stimmen-Bezeichnung normalisiert:

```
Normalisierung:
  - Trim (führende/nachfolgende Leerzeichen entfernen)
  - Case-insensitive Vergleich
  - Numero-Normalisierung: „2." = „II" = „zweite" = „2"
  - Abkürzungs-Mapping: „Klar." = „Klarinette", „Trp." = „Trompete"
```

---

## 5. API-Contract

### 5.1 GET /api/v1/stuecke/{id}/stimmen

Liefert alle verfügbaren Stimmen für ein Stück, mit Fallback-Ergebnis für den aktuellen Nutzer.

**Request:**
```http
GET /api/v1/stuecke/{stueck_id}/stimmen
Authorization: Bearer {jwt}
Accept: application/json
```

**Response:**
```json
{
  "stueck_id": "550e8400-e29b-41d4-a716-446655440000",
  "stimmen": [
    {
      "id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
      "bezeichnung": "2. Klarinette",
      "instrument_typ": "klarinette",
      "instrument_familie": "holzblaes er",
      "stimmen_nummer": 2,
      "seiten_anzahl": 4
    },
    {
      "id": "6ba7b811-9dad-11d1-80b4-00c04fd430c8",
      "bezeichnung": "1. Klarinette",
      "instrument_typ": "klarinette",
      "instrument_familie": "holzblaes er",
      "stimmen_nummer": 1,
      "seiten_anzahl": 4
    }
  ],
  "vorausgewaehlt": {
    "stimme_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
    "bezeichnung": "2. Klarinette",
    "fallback_schritt": 1,
    "fallback_grund": null
  }
}
```

**Fallback im Response:**

| `fallback_schritt` | `fallback_grund` | Bedeutung |
|-------------------|-----------------|-----------|
| `1` | `null` | Exakte Übereinstimmung |
| `2` | `"gleiche_familie_niedrigste_nr"` | Nächstniedrigere Stimme |
| `3` | `"generisch_selbes_instrument"` | Generische Stimme |
| `4` | `"verwandte_familie"` | Verwandte Instrument-Familie |
| `5` | `"erste_verfuegbare"` | Erste verfügbare Stimme |
| `null` | `"keine_stimmen"` | Kein Fallback möglich |

---

### 5.2 GET /api/v1/nutzer/instrumente

Liefert die Instrumente und Standard-Stimmen des aktuellen Nutzers.

**Request:**
```http
GET /api/v1/nutzer/instrumente
Authorization: Bearer {jwt}
Accept: application/json
```

**Response:**
```json
{
  "nutzer_id": "770e8400-e29b-41d4-a716-446655440001",
  "instrumente": [
    {
      "id": "inst-001",
      "instrument_typ": "klarinette",
      "instrument_bezeichnung": "Klarinette",
      "standard_stimmen": [
        {
          "kapelle_id": "kap-001",
          "kapelle_name": "Musikkapelle Beispiel",
          "stimme_bezeichnung": "2. Klarinette"
        }
      ]
    },
    {
      "id": "inst-002",
      "instrument_typ": "saxophon_alt",
      "instrument_bezeichnung": "Altsaxophon",
      "standard_stimmen": []
    }
  ]
}
```

---

### 5.3 PUT /api/v1/nutzer/instrumente

Aktualisiert Instrumente und Standard-Stimmen des Nutzers.

**Request:**
```http
PUT /api/v1/nutzer/instrumente
Authorization: Bearer {jwt}
Content-Type: application/json

{
  "instrumente": [
    {
      "instrument_typ": "klarinette",
      "instrument_bezeichnung": "Klarinette",
      "standard_stimmen": [
        {
          "kapelle_id": "kap-001",
          "stimme_bezeichnung": "2. Klarinette"
        }
      ]
    }
  ]
}
```

**Response:** `200 OK` mit aktualisiertem Instrumente-Objekt (gleiche Struktur wie GET)

**Validierung:**
- `instrument_typ`: muss aus der vordefinierten Liste stammen (oder `custom` für unbekannte Instrumente)
- `stimme_bezeichnung`: Freitext, max. 100 Zeichen
- `kapelle_id`: muss eine Kapelle sein, in der der Nutzer Mitglied ist

---

### 5.4 GET /api/v1/stuecke/{id}/stimmen/{stimme_id}/seiten

Liefert Seiten-Metadaten für eine Stimme (für Spielmodus — Spec #25).

```http
GET /api/v1/stuecke/{stueck_id}/stimmen/{stimme_id}/seiten
Authorization: Bearer {jwt}
```

```json
{
  "stimme_id": "6ba7b810-...",
  "seiten": [
    {
      "seiten_nummer": 1,
      "download_url": "https://cdn.sheetstorm.app/...",
      "breite_px": 2480,
      "hoehe_px": 3508,
      "format": "webp",
      "datei_groesse": 245678
    }
  ]
}
```

---

## 6. Datenmodell

### 6.1 NutzerInstrument

```sql
CREATE TABLE nutzer_instrumente (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nutzer_id     UUID NOT NULL REFERENCES nutzer(id) ON DELETE CASCADE,
  instrument_typ VARCHAR(50) NOT NULL,           -- 'klarinette', 'trompete', etc.
  instrument_bezeichnung VARCHAR(100) NOT NULL,  -- Freitext-Anzeigename
  sortierung    INT NOT NULL DEFAULT 0,          -- Reihenfolge im Profil
  erstellt_am   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(nutzer_id, instrument_typ)              -- Jeder Typ nur einmal pro Nutzer
);

CREATE INDEX idx_nutzer_instrumente_nutzer ON nutzer_instrumente(nutzer_id);
```

### 6.2 StimmeVorauswahl

```sql
CREATE TABLE stimme_vorauswahl (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nutzer_id         UUID NOT NULL REFERENCES nutzer(id) ON DELETE CASCADE,
  kapelle_id        UUID NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
  instrument_id     UUID NOT NULL REFERENCES nutzer_instrumente(id) ON DELETE CASCADE,
  stimme_bezeichnung VARCHAR(100) NOT NULL,  -- z.B. "2. Klarinette"
  aktualisiert_am   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(nutzer_id, kapelle_id, instrument_id)  -- Eine Standard-Stimme pro Instrument+Kapelle
);

CREATE INDEX idx_stimme_vorauswahl_nutzer_kapelle ON stimme_vorauswahl(nutzer_id, kapelle_id);
```

### 6.3 Stimme (Teil des Stück-Modells)

```sql
CREATE TABLE stimmen (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stueck_id         UUID NOT NULL REFERENCES stuecke(id) ON DELETE CASCADE,
  bezeichnung       VARCHAR(100) NOT NULL,      -- z.B. "2. Klarinette"
  instrument_typ    VARCHAR(50),                -- normalisierter Typ für Fallback
  instrument_familie VARCHAR(50),               -- für Fallback Schritt 4
  stimmen_nummer    INT,                        -- für Sortierung/Fallback (NULL = keine Nummer)
  seiten_anzahl     INT NOT NULL DEFAULT 0,
  erstellt_am       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(stueck_id, bezeichnung)
);

CREATE INDEX idx_stimmen_stueck ON stimmen(stueck_id);
CREATE INDEX idx_stimmen_instrument ON stimmen(stueck_id, instrument_typ, stimmen_nummer);
```

### 6.4 Instrument-Typen (Enum / Referenz-Tabelle)

Vordefinierte Instrument-Typen für MS1 (erweiterbar):

```
Holzbläser:
  floete, piccolo, oboe, klarinette, bassklarinette, fagott, kontrafagott,
  saxophon_sopran, saxophon_alt, saxophon_tenor, saxophon_bariton

Blechbläser:
  trompete, fluegelhorn, horn, tenorhorn, posaune, bassposaune, 
  euphonium, tuba, kontrabass_tuba

Schlagwerk:
  kleine_trommel, grosse_trommel, becken, pauken, xylophon, 
  marimba, vibraphon, schlagzeug

Tasten / Sonstige:
  klavier, orgel, akkordeon, harfe
  
Sonstige:
  custom  (Freitext-Bezeichnung)
```

---

## 7. Edge Cases

### 7.1 Keine passende Stimme gefunden (Schritt 6)

**Szenario:** Das Stück hat Stimmen, aber keine liegt in der Instrument-Familie des Nutzers.

**Verhalten:**
- Fallback-Schritt 5 greift: erste verfügbare Stimme wird gewählt
- Toast/Hinweis: „Keine passende Stimme für [Instrument] — [Stimmname] angezeigt [Stimme wechseln]"
- Der Musiker kann manuell eine andere Stimme wählen

**Akzeptanzkriterium:**
- [ ] AC-29: Selbst wenn keine Stimme zur Instrument-Familie passt, zeigt die App immer **irgendetwas** (Schritt 5) — **kein** leerer Bildschirm, **kein** Crash

---

### 7.2 Stück hat keine Stimmen

**Szenario:** Stück wurde importiert aber noch nicht gelabeled / Stimmen noch nicht zugeordnet.

**Verhalten:**
- Spielmodus zeigt: „Für dieses Stück sind noch keine Stimmen verfügbar."
- Button: „Stimmen zuordnen" (nur für Notenwart/Admin/Dirigent sichtbar)
- Musiker ohne Berechtigung: nur die Meldung, kein Button

**Akzeptanzkriterium:**
- [ ] AC-30: Bei leerem `stimmen`-Array zeigt die App eine aussagekräftige Meldung, **nicht** einen leeren Bildschirm

---

### 7.3 Musiker wechselt Kapelle

**Szenario:** Nutzer ist in Kapelle A mit Standard-Stimme „2. Klarinette", wechselt zu Kapelle B wo er noch keine Standard-Stimme gesetzt hat.

**Verhalten:**
- Beim Kapellenwechsel: Standard-Stimme aus `stimme_vorauswahl` für die neue Kapelle suchen
- Wenn keine Vorauswahl für neue Kapelle: Fallback-Kette mit dem **Instrument-Typ** (ohne kapellen-spezifische Stimme) — Schritt 2 aufwärts
- Einmaliger Hinweis: „Du hast noch keine Standard-Stimme für [Kapellenname] festgelegt. [Jetzt festlegen]"

**Akzeptanzkriterium:**
- [ ] AC-31: Kapellenwechsel ohne explizite Standard-Stimme führt zu Fallback, **nicht** zu einer Fehlermeldung

---

### 7.4 Instrument wechseln (Musiker wird Einspringer)

**Szenario:** Musiker spielt normalerweise Klarinette, springt heute für einen Trompeter ein.

**Verhalten:**
- Im Spielmodus: Stimme-Wechseln-Button → Bottom-Sheet → „Andere Stimmen" → Trompete 1 wählen
- Dies ist **kein** Profil-Update — nur temporäres Override für diese Session
- Optional: Toast nach Stimme-Wechsel: „Möchtest du Trompete zu deinen Instrumenten hinzufügen?" (einmalig)

**Akzeptanzkriterium:**
- [ ] AC-32: Temporäres Stimme-Override (Spielmodus) persistiert **nicht** als neue Standard-Stimme — explizite Bestätigung durch Nutzer notwendig

---

### 7.5 Stimmen-Bezeichnung aus Import vs. Nutzer-Profil stimmt nicht überein

**Szenario:** Notenwart hat die Stimme als „Klarinette 2" importiert, Nutzer hat „2. Klarinette" als Standard.

**Verhalten:**
- Normalisierungs-Algorithmus (Abschnitt 4.4) gleicht Schreibweisen ab
- Wenn Normalisierung nicht hilft: Fallback Schritt 2 (gleiche Familie)
- Admin/Notenwart kann Stimmen-Bezeichnungen nachträglich korrigieren

**Akzeptanzkriterium:**
- [ ] AC-33: Normalisierungs-Algorithmus erkennt mindestens die gängigen Varianten (Klarinette 2 = 2. Klarinette = Klar. II = Klarinette II)

---

### 7.6 Mehrdeutige Fallback-Ergebnisse (zwei gleich gute Kandidaten)

**Szenario:** Zwei Stimmen in Schritt 2 (z.B. „1. Klarinette" und „Klarinette in B") — beide gleich nah.

**Verhalten:**
- Tie-Breaking: Alphabetisch sortiert, erste Stimme gewinnt
- Keine Abfrage an den Nutzer — automatische Entscheidung, mit transparentem Hinweis

**Akzeptanzkriterium:**
- [ ] AC-34: Tie-Breaking ist deterministisch — gleicher Input → immer gleicher Output

---

## 8. Performance-Anforderungen

| Operation | Ziel |
|-----------|------|
| Fallback-Algorithmus (Client-seitig) | < 5ms (rein lokale Berechnung) |
| API GET /stimmen (gecacht) | < 50ms |
| API GET /stimmen (nicht gecacht, Server) | < 200ms |
| Standard-Stimme PUT | < 500ms (optimistische UI-Aktualisierung sofort) |

**Offline-Verhalten:**
- Instrument-Profil und Standard-Stimmen werden lokal in SQLite gecacht
- Fallback-Algorithmus läuft **vollständig client-seitig** — kein Server-Request nötig
- Stimmen-Metadaten (Bezeichnungen, Instrument-Typ) werden beim Download gecacht

---

## 9. Abhängigkeiten

| Abhängigkeit | Typ | Status |
|-------------|-----|--------|
| #28 — UX Stimmenauswahl (Wanda) | Informiert | 🟡 In Arbeit |
| #7 — Backend Scaffolding (Banner) | Blockierend | ✅ Done |
| #8 — Flutter Scaffolding (Romanoff) | Blockierend | ✅ Done |
| #25 — Spielmodus-Spec (Hill) | Eng gekoppelt | ✅ Diese Session |
| #20 — Noten-Import-Spec (Hill) | Informiert | ✅ Done |
| Nutzer-Profil (Onboarding) | Voraussetzung | Teil #10 Auth-Spec |

---

## 10. Definition of Done

### Funktional
- [ ] Alle 34 Akzeptanzkriterien aus Abschnitt 2 bestanden
- [ ] Fallback-Algorithmus (alle 6 Schritte) durch Unit Tests verifiziert
- [ ] Standard-Stimme korrekt gespeichert und beim nächsten Start übernommen
- [ ] Stimme wechseln im Spielmodus ohne App-Neustart
- [ ] Bottom-Sheet zeigt korrekte Sortierung (Meine Instrumente oben)

### Korrektheit Fallback
- [ ] Alle 6 Beispiel-Szenarien aus Tabelle 4.2 produzieren erwartetes Ergebnis
- [ ] Normalisierungs-Algorithmus erkennt mindestens 10 Schreibvarianten
- [ ] Tie-Breaking ist deterministisch (gleicher Input → gleicher Output)

### API
- [ ] GET /api/v1/stuecke/{id}/stimmen gibt korrektes `vorausgewaehlt`-Feld zurück
- [ ] PUT /api/v1/nutzer/instrumente idempotent (zweimal PUT → gleicher State)
- [ ] API-Fehler: 404 wenn Stück nicht gefunden, 403 wenn keine Berechtigung

### UX / Accessibility
- [ ] Fallback-Hinweis ist sichtbar und verständlich (Nutzer-Test)
- [ ] Bottom-Sheet Touch-Targets ≥ 44px Höhe
- [ ] UI-Review durch Wanda (#28) abgenommen

### Tests (Parker — Issue #30)
- [ ] Unit Tests: Fallback-Algorithmus (alle Schritte), Normalisierung, Sortierung
- [ ] Widget Tests: Bottom-Sheet, Stimmen-Liste, Hinweis-Toast
- [ ] Integration Tests: Standard-Stimme setzen → Stück öffnen → Vorauswahl korrekt

---

*Erstellt von Hill (Product Manager) — Issue #29*  
*Wanda's UX-Spec (#28) fließt ein sobald verfügbar — AC werden ggf. aktualisiert*
