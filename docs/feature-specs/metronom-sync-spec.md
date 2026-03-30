# Feature-Spezifikation: Echtzeit-Metronom (Sync)

> **Meilenstein:** MS3  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-29  
> **Status:** Draft  
> **Abhängigkeiten:** MS1 (Kapellenverwaltung, Konfigurationssystem), MS1 (Backend-Infrastruktur)  
> **UX-Referenz:** `docs/ux-specs/metronom-sync.md` (TBD — Wanda)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien (Feature-Level)](#3-akzeptanzkriterien-feature-level)
4. [API-Contract & Protokoll-Spezifikation](#4-api-contract--protokoll-spezifikation)
5. [Datenmodell](#5-datenmodell)
6. [Technische Architektur](#6-technische-architektur)
7. [Edge Cases & Fehlerszenarien](#7-edge-cases--fehlerszenarien)
8. [Abhängigkeiten](#8-abhängigkeiten)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Ziel

Der Dirigent startet über Sheetstorm ein synchronisiertes Metronom, das alle Musiker gleichzeitig im selben Takt hält — mit < 5ms Latenz im LAN via UDP Multicast, und < 50ms über WebSocket als Fallback. Musiker sehen und hören den Taktschlag auf ihren Geräten synchron zum Dirigentenstab.

**Kernwert:** Eine Probe ohne Klangkörper-Synchronisation ist eine verlorene Probe. Sheetstorm macht den Dirigentenstab digital skalierbar.

### 1.2 Das Kernproblem

**Status Quo:**
- Proben-Klick läuft auf dem Dirigenten-Gerät oder einem separaten Metronom
- Musiker im hinteren Bereich oder mit Kopfhörern hören den Klick nicht synchron
- Remote-Proben (Video-Call) haben inhärente Latenz — kein gemeinsamer Klick

**Sheetstorm-Lösung:**
- Dirigent startet Metronom → alle Geräte im selben Netz erhalten Beats synchron
- Beats werden als präzise Timestamps übertragen (nicht als Echtzeit-Kommandos)
- Jedes Gerät rendert den Beat-Indikator und Audio-Klick zur exakten geplanten Zeit

### 1.3 Scope MS3

| Im Scope | Außerhalb Scope |
|----------|-----------------|
| Dirigent: Start/Stop/BPM-Wahl | Tap-Tempo-Erkennung |
| UDP Multicast im LAN (primär) | MIDI-Clock-Output |
| SignalR WebSocket (Fallback) | Dirigenten-Song-Broadcast (separate Spec) |
| Automatische Protokoll-Erkennung | Öffentliches Internet-Streaming |
| Visuelle Beat-Anzeige (Musiker) | Metronom-Aufnahme / Export |
| Optionaler Audio-Klick (Geräte-Einstellung) | Polymeter / verschachtelte Taktarten |
| Latenz-Kompensation pro Gerät | Stimmton-Generator |
| Clock-Synchronisation (NTP-ähnlich) | Dirigenten-Video |

### 1.4 Nutzungskontext

| Persona | Situation | Ziel |
|---------|-----------|------|
| Dirigent | Beginn der Probe | BPM einstellen, Metronom für alle starten |
| Musiker | Während der Probe | Synchronen Taktschlag sehen/hören |
| Musiker | Netz wechselt (LAN → Mobile) | Nahtloser Fallback auf WebSocket |
| Dirigent | Stück ändern | BPM anpassen ohne Stop/Start-Zyklus |

---

## 2. User Stories

### US-01: Metronom starten (Dirigent)

> *Als Dirigent möchte ich ein Metronom mit definierten BPM und Taktart starten, damit alle Musiker meiner Kapelle synchron mitspielen können.*

**Akzeptanzkriterien:**
1. Dirigent öffnet Metronom-Ansicht (eigener Tab oder im Probe-Modus)
2. Eingabe: **BPM** (20–300), Stepper + direkte Eingabe, Default: 120
3. Eingabe: **Taktart** (2/4, 3/4, 4/4, 6/8, 12/8), Auswahl-Liste
4. „Starten"-Button sendet Start-Signal an alle verbundenen Geräte
5. Dirigenten-Ansicht zeigt: laufendes Metronom, Anzahl verbundener Geräte, gewähltes Protokoll (UDP/WS)
6. Erster Beat wird auf einen zukunftsliegenden Timestamp gesetzt (+100ms nach Start), sodass Clients sich synchronisieren können
7. Dirigent sieht seine eigene Beat-Anzeige synchron mit den Clients

---

### US-02: Metronom stoppen und BPM ändern (Dirigent)

> *Als Dirigent möchte ich das Metronom stoppen oder die BPM ändern können, ohne dass Clients abstürzen oder in falschen Zuständen bleiben.*

**Akzeptanzkriterien:**
1. „Stoppen"-Button sendet Stop-Signal sofort, alle Clients stoppen die Anzeige innerhalb von 2 Beats
2. BPM-Änderung während laufendem Metronom: Nächster Beat startet mit neuer BPM, kein Ruckeln
3. Nach Stop: Clients zeigen „Metronom gestoppt" — kein leerer Screen
4. Dirigent kann direkt neues Metronom starten (kein Warten nötig)
5. Wenn Dirigent die App verlässt: automatisches Stop-Signal wird gesendet

---

### US-03: Synchronen Beat empfangen (Musiker)

> *Als Musiker möchte ich den Taktschlag des Dirigenten synchron auf meinem Gerät sehen und optional hören, damit ich in der Probe im Takt bleibe.*

**Akzeptanzkriterien:**
1. Musiker-Gerät empfängt Beats und zeigt visuellen Beat-Indikator (Blink, Animation)
2. Zählzeitschlag (erster Beat des Takts) wird visuell hervorgehoben (größer, andere Farbe)
3. Optionaler **Audio-Klick** pro Gerät konfigurierbar (Einstellung: Ein/Aus, Lautstärke)
4. Audio-Klick-Latenz-Kompensation: Gerät-Einstellung (-50ms bis +50ms Offset)
5. Verbindungsstatus sichtbar: „Verbunden (UDP)", „Verbunden (WebSocket)", „Nicht verbunden"
6. Bei Verbindungsverlust: letzter empfangener Beat zählt weiter (drift-freies lokales Metronom) für max. 4 Takte, dann „Verbindung verloren"-Hinweis
7. Musiker kann Metronom nicht starten/stoppen — nur passiver Empfänger

---

### US-04: Automatischer Protokoll-Wechsel

> *Als Musiker möchte ich, dass die App automatisch das beste Protokoll wählt (UDP im LAN, WebSocket als Fallback), damit ich mich nicht um Netzwerk-Details kümmern muss.*

**Akzeptanzkriterien:**
1. App erkennt automatisch: Gleiches WiFi-Netz → UDP Multicast; Anderes Netz → WebSocket
2. Wechsel von UDP zu WebSocket: max. 3 Sekunden Unterbrechung, kein manuelles Eingreifen
3. Wechsel von WebSocket zurück zu UDP: automatisch bei Erkennung des LAN
4. Aktuelles Protokoll in der UI sichtbar (kleiner Badge oder Statuszeile)
5. Manuelle Override-Möglichkeit in Einstellungen: „Immer WebSocket" (für Netzwerke ohne Multicast)

---

### US-05: Latenz-Kompensation einstellen

> *Als Musiker möchte ich die Latenz-Kompensation meines Geräts einstellen, damit der Klick exakt zum Takt passt und nicht leicht versetzt klingt.*

**Akzeptanzkriterien:**
1. Einstellung in Geräte-Konfiguration: **Audio-Offset** (-50ms bis +50ms, Schrittweite 1ms)
2. Einstellung in Geräte-Konfiguration: **Visuelle Vorlaufzeit** (0ms bis 20ms)
3. Zum Kalibrieren: Test-Beat-Funktion (kein laufendes Metronom nötig)
4. Default: 0ms (kein Offset)
5. Einstellung wird pro Gerät gespeichert (Geräte-Konfiguration)

---

## 3. Akzeptanzkriterien (Feature-Level)

| ID | Kriterium | Messbar |
|----|-----------|---------|
| AC-01 | UDP-Latenz im LAN: < 5ms (Median), < 10ms (P99) | Latenz-Test mit 2 Geräten im LAN |
| AC-02 | WebSocket-Latenz: < 50ms (Median), < 100ms (P99) | Latenz-Test über Internet |
| AC-03 | Automatischer UDP → WebSocket Fallback: ≤ 3 Sekunden | Integration-Test: Multicast blockieren |
| AC-04 | Automatischer WebSocket → UDP Upgrade: ≤ 10 Sekunden nach LAN-Beitritt | Integration-Test |
| AC-05 | Clock-Sync-Drift: < 1ms nach Kalibrierung | NTP-Protokoll-Test |
| AC-06 | Beat-Präzision: ±2ms Jitter bei 120 BPM | Messung mit Audio-Analyse-Tool |
| AC-07 | Bis zu 50 gleichzeitige Clients ohne Latenz-Degradation | Load-Test |
| AC-08 | UDP Multicast-Paket ≤ 64 Bytes (kein Overhead) | Wireshark-Messung |
| AC-09 | Stop-Signal wird von allen Clients ≤ 500ms nach Dirigenten-Stop verarbeitet | Integration-Test |
| AC-10 | Verbindungsverlust → Client läuft 4 Takte weiter, dann Hinweis | Offline-Test |

---

## 4. API-Contract & Protokoll-Spezifikation

### 4.1 UDP Multicast (Primär-Protokoll)

**Multicast-Gruppe:** `239.255.42.99` (Link-Local Multicast, RFC 4607)  
**Port:** `5001` (konfigurierbar)  
**Paketformat:** Binär (MessagePack), max 64 Bytes

```
Beat-Paket (16 Bytes):
┌──────────┬────────┬───────┬────────┬──────────┐
│ type(1B) │ bpm(2B)│ takt(1B)│beat_nr(1B)│ timestamp(8B) │ kapelle_id(3B) │
└──────────┴────────┴───────┴────────┴──────────┘

type: 0x01 = BEAT, 0x02 = START, 0x03 = STOP, 0x04 = SYNC
bpm: uint16, BPM * 10 (z.B. 1200 = 120.0 BPM)
takt: beat im Takt (0-basiert; 0 = Zählzeit)
beat_nr: fortlaufende Beat-Nummer seit Start
timestamp: int64 Microseconds seit Unix Epoch (UTC)
kapelle_id: 3 Bytes = first 3 bytes of UUID (Kollisions-Schutz genug für Multicast)
```

**SYNC-Paket (Clock-Synchronisation):**
```
type: 0x04 = SYNC
t1: Server-Timestamp (8B)
→ Client antwortet mit eigenem t2 + t3
→ Server berechnet RTT und Offset per NTP-Algorithmus
```

### 4.2 SignalR WebSocket (Fallback-Protokoll)

**Hub-URL:** `/hubs/metronom`  
**Authentifizierung:** JWT Bearer (wie alle anderen Hubs)

**Server → Client Events:**

```csharp
// Beat-Event
interface BeatEvent {
    BeatNumber: number;      // Fortlaufende Nummer
    TimestampUtcMicros: long; // UTC Microseconds
    Bpm: number;             // Aktuelles BPM
    TaktPosition: number;    // 0 = Zählzeit, 1..n = Folgschläge
    TaktArt: string;         // "4/4", "3/4", etc.
}

// Metronom-Status
interface MetronomStatusEvent {
    IsRunning: boolean;
    Bpm: number;
    TaktArt: string;
    StartedBy: string;       // Dirigent-Name
    ConnectedClients: number;
}
```

**Client → Server Commands:**

```csharp
// Nur für Dirigent (autorisiert via Rolle)
StartMetronom(bpm: number, taktArt: string)
StopMetronom()
ChangeBpm(newBpm: number)     // Während laufendem Metronom

// Für alle Clients (Clock-Sync)
SyncRequest(clientTimeMicros: long)
```

### 4.3 REST-Endpunkte (Session-Management)

```
GET  /api/v1/kapellen/{id}/metronom/status
     → { isRunning, bpm, taktArt, protokoll, connectedClients }

POST /api/v1/kapellen/{id}/metronom/start
     Body: { bpm: 120, taktArt: "4/4" }
     Auth: Dirigent oder Admin

POST /api/v1/kapellen/{id}/metronom/stop
     Auth: Dirigent oder Admin
```

---

## 5. Datenmodell

### 5.1 Keine persistente Speicherung von Beat-Daten

Metronom-Daten sind **ephemer** — kein Persistenz-Layer für einzelne Beats.

### 5.2 Session-State (Redis / In-Memory)

```
metronom:{kapelleId}:state
{
  "isRunning": true,
  "bpm": 120,
  "taktArt": "4/4",
  "startedAt": "2026-03-29T18:00:00.000000Z",
  "startedBy": "uuid",
  "nextBeatTimestamp": 1234567890000000
}
TTL: automatisch nach 4h (keine hängende Session)
```

### 5.3 Konfiguration (in Konfigurationssystem MS1)

**Kapellen-Konfiguration:**
```json
{
  "metronom": {
    "udp_port": 5001,
    "multicast_group": "239.255.42.99",
    "default_bpm": 120,
    "default_taktart": "4/4"
  }
}
```

**Geräte-Konfiguration:**
```json
{
  "metronom": {
    "audio_enabled": true,
    "audio_volume": 0.8,
    "audio_offset_ms": 0,
    "visual_advance_ms": 0,
    "force_websocket": false
  }
}
```

---

## 6. Technische Architektur

### 6.1 Clock-Synchronisation (NTP-ähnlich)

```
Client ──── SyncRequest(t1) ──────────────► Server
                                              │ verarbeitet @ t2
Client ◄─── SyncResponse(t1, t2, t3) ──────── Server @ t3

Client berechnet:
  RTT = (t4 - t1) - (t3 - t2)
  Offset = ((t2 - t1) + (t3 - t4)) / 2
  
Client korrigiert lokale Zeit um Offset.
Sync alle 30 Sekunden wiederholen.
```

### 6.2 Beat-Scheduling (Client)

```
Empfangener Beat-Timestamp: T (UTC Microseconds)
Korrigierte lokale Zeit: now_corrected
Delta = T - now_corrected

if delta > 0:
  scheduleCallback(delta)  // Flutter Timer.precise
else if delta > -20ms:
  executeImmediately()     // leicht spät, aber noch akzeptabel
else:
  dropBeat()               // zu spät, überspringen + Warning loggen
```

### 6.3 Protokoll-Auswahl-Logik (Client)

```
1. Prüfe WiFi-Verbindung aktiv?  Nein → WebSocket
2. Prüfe Multicast-Paket empfangen innerhalb 2s?  Nein → WebSocket
3. UDP verfügbar → UDP (bessere Latenz)
4. Jede 30s: Prüfe wieder auf UDP (Upgrade-Möglichkeit)
```

### 6.4 Berechtigungsmatrix

| Aktion | Admin | Dirigent | Registerführer | Notenwart | Musiker |
|--------|-------|----------|----------------|-----------|---------|
| Metronom starten | ✅ | ✅ | ❌ | ❌ | ❌ |
| Metronom stoppen | ✅ | ✅ | ❌ | ❌ | ❌ |
| BPM ändern | ✅ | ✅ | ❌ | ❌ | ❌ |
| Beat empfangen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Latenz-Offset konfigurieren | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 7. Edge Cases & Fehlerszenarien

### 7.1 Zwei Dirigenten versuchen gleichzeitig zu starten
- **Szenario:** Kapelle hat zwei Dirigenten, beide tippen gleichzeitig auf „Start".
- **Verhalten:** Erster gewinnt (DB-Lock auf Session-State), zweiter erhält Fehlermeldung „Metronom läuft bereits — gestartet von [Name]". Kein Doppel-Start.

### 7.2 UDP Multicast vom Router blockiert
- **Szenario:** Firmen-WLAN, Hotel-WLAN oder bestimmte Router blockieren Multicast.
- **Verhalten:** App erkennt innerhalb 2 Sekunden keine UDP-Antwort → automatischer Fallback auf WebSocket, ohne Nutzer-Intervention.

### 7.3 Dirigent verliert Verbindung während laufendem Metronom
- **Szenario:** Dirigent-Gerät verliert WLAN, Metronom läuft noch auf Clients.
- **Verhalten:** Server hält Session für 4 Takte aufrecht (gespeicherter State), dann automatisches Stop. Clients erhalten Stop-Event. Kein ewig laufendes Phantom-Metronom.

### 7.4 Client-Uhr extremem Drift (> 500ms)
- **Szenario:** Geräte-Uhr ist stark falsch gestellt.
- **Verhalten:** Clock-Sync-Algorithmus korrigiert bis zu 2 Sekunden Drift. Bei > 2s Abweichung: Warnung „Gerätezeit stimmt nicht — bitte Systemzeit prüfen", Metronom deaktiviert.

### 7.5 Sehr viele Clients (> 50)
- **Szenario:** Orchester mit 80 Geräten.
- **Verhalten:** UDP Multicast skaliert von Natur aus (ein Paket, alle empfangen). WebSocket-Hub begrenzt auf 100 Connections per Session via Load-Testing validiert.

### 7.6 BPM-Änderung während Beat
- **Szenario:** Dirigent ändert BPM-Slider während laufendem Metronom.
- **Verhalten:** Neue BPM wird mit dem **nächsten vollen Takt** aktiv (nicht mitten im Takt). Beat-Nummer wird nicht zurückgesetzt.

### 7.7 App in den Hintergrund
- **Szenario:** Musiker wechselt App während Metronom läuft.
- **Verhalten:** Audio-Klick läuft weiter (Background Audio erlaubt). Visueller Indikator pausiert bis Vordergrund. Keine Drift bei Rückkehr.

---

## 8. Abhängigkeiten

### 8.1 Blockierende Abhängigkeiten

| Feature | Warum | Meilenstein |
|---------|-------|-------------|
| Kapellenverwaltung + Rollen (MS1) | Dirigenten-Berechtigung für Start/Stop | MS1 |
| Konfigurationssystem (MS1) | UDP-Port, BPM-Default, Audio-Offset | MS1 |
| ASP.NET Core Backend + SignalR (MS1) | WebSocket Hub-Infrastruktur | MS1 |

### 8.2 Technische Infrastruktur-Anforderungen (Backend-Team)

- UDP-Server muss in ASP.NET Core 10 implementiert werden (eigener UDP-Socket-Listener neben HTTP)
- SignalR Hub für Metronom separiert von anderen Hubs (Performance-Isolation)
- Redis für Session-State empfohlen (kein In-Memory bei Multi-Instanz Deployment)

---

## 9. Definition of Done

### Funktional
- [ ] US-01: Dirigent kann Metronom starten (BPM + Taktart)
- [ ] US-02: Dirigent kann stoppen und BPM ändern
- [ ] US-03: Musiker empfangen synchronen Beat (visuell + audio)
- [ ] US-04: Automatischer Protokoll-Wechsel UDP ↔ WebSocket
- [ ] US-05: Latenz-Kompensation konfigurierbar
- [ ] Alle AC-01 bis AC-10 erfüllt und gemessen

### Performance
- [ ] UDP-Latenz < 5ms gemessen und dokumentiert (LAN-Test)
- [ ] WebSocket-Latenz < 50ms gemessen und dokumentiert
- [ ] 50 Clients Load-Test erfolgreich (keine Latenz-Degradation)

### Qualität
- [ ] Unit-Tests: Clock-Sync-Algorithmus (NTP-Berechnung)
- [ ] Unit-Tests: Beat-Scheduling (Timer-Präzision)
- [ ] Integration-Tests: UDP Start/Stop/BPM-Wechsel
- [ ] Integration-Tests: WebSocket Fallback
- [ ] Test: Dirigent-Verbindungsverlust → automatisches Stop
- [ ] Code Coverage ≥ 80% für Sync-Logik

### UX
- [ ] UX-Review durch Wanda abgenommen
- [ ] Beat-Animation flüssig (kein Frame-Drop)
- [ ] Protokoll-Badge klar sichtbar

### Deployment
- [ ] UDP-Port 5001 in Docker/Cloud-Firewall freigegeben (Dokumentation)
- [ ] Multicast-Gruppen-Adresse konfigurierbar (nicht hardcodiert)
- [ ] Performance-Protokoll beigefügt
