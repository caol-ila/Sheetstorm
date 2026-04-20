# E2E: Echtzeit-Metronom (Sync + Latenz)

**Labels:** `milestone:3`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für das Echtzeit-Metronom: UDP-basierter Sync mit <5ms Latenz im LAN, WebSocket-Fallback und Clock-Synchronisation.

## Testfälle

### Metronom starten
- [ ] Dirigent startet Metronom mit BPM-Einstellung
- [ ] Tempo-Änderung in Echtzeit
- [ ] Metronom stoppen
- [ ] Taktart einstellen (4/4, 3/4, 6/8, etc.)

### Sync über Geräte
- [ ] Alle verbundenen Musiker hören/sehen den gleichen Beat
- [ ] Clock-Sync: NTP-ähnliches Protokoll kalibriert Zeitdifferenz
- [ ] Beats als Timestamps (nicht "jetzt spielen"-Kommandos)
- [ ] WebSocket-Fallback wenn UDP nicht verfügbar

### Audio-Ausgabe
- [ ] Metronom-Click wird korrekt abgespielt
- [ ] Lautstärke-Einstellung
- [ ] Betonung auf dem ersten Schlag
- [ ] Verschiedene Click-Sounds (wenn konfigurierbar)

### Visueller Beat-Indikator
- [ ] Visueller Puls synchron zum Audio
- [ ] Beat-Counter Anzeige
- [ ] Aktueller Beat hervorgehoben

## Technische Hinweise

- UDP nicht in Browser-E2E testbar → WebSocket-Fallback testen
- Audio-Ausgabe: Web Audio API, Timing über `performance.now()`
- Latenz-Messung: Timestamps in Multi-Tab-Setup vergleichen
- Browser-Autoplay-Policy: User-Interaktion vor Audio nötig
