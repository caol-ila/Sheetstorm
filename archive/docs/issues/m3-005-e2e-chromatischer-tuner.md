# E2E: Chromatischer Tuner (Stimmgerät)

**Labels:** `milestone:3`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für den chromatischen Tuner: Tonhöhenerkennung via Mikrofon, visuelle Anzeige und instrumentenspezifische Stimmung.

## Testfälle

### Tuner-UI
- [ ] Tuner öffnen: Mikrofon-Berechtigung wird angefragt
- [ ] Stimmungsanzeige: Note + Cent-Abweichung
- [ ] Visueller Indikator (Nadel / Farbskala)
- [ ] Ziel-Frequenz anzeigen (A4 = 440 Hz, konfigurierbar)

### Tonhöhenerkennung
- [ ] Korrekte Note wird erkannt (simulierter Audio-Input)
- [ ] Cent-Abweichung korrekt berechnet
- [ ] Reaktionszeit < 20ms (Performance-Target)
- [ ] Rauschunterdrückung: Stille → keine falsche Erkennung

### Instrumenten-Konfiguration
- [ ] Transponierendes Instrument: Anzeige in Konzert- oder transponierter Stimmung
- [ ] Kammerton-Einstellung (440 Hz, 442 Hz, custom)
- [ ] Einstellung wird aus User-Config geladen

### Berechtigungen
- [ ] Mikrofon-Berechtigung verweigert → Hinweismeldung
- [ ] Berechtigung erneut anfragen nach Ablehnung

## Technische Hinweise

- Mikrofon-Input im E2E schwierig → Audio-Injection via Web Audio API
- Platform Channels (native Audio) nicht im Web-Test testbar → Web-Fallback testen
- `getUserMedia` Mock für stabile Tests
- Performance via `performance.now()` messen
