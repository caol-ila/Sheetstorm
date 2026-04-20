# E2E: Song-Broadcast / Dirigenten-Mastersteuerung

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für die Dirigenten-Mastersteuerung: Der Dirigent wählt ein Stück, und alle verbundenen Musiker-Geräte erhalten die korrekte Stimme in Echtzeit.

## Testfälle

### Broadcast starten
- [ ] Dirigent wählt Stück aus Setlist/Bibliothek
- [ ] "An alle senden" löst Broadcast aus
- [ ] Bestätigungsdialog vor Broadcast

### Empfang auf Musiker-Geräten
- [ ] Musiker erhält Push/Notification mit Stück-Info
- [ ] Korrekte Stimme wird automatisch geladen (basierend auf Instrument)
- [ ] Spielmodus öffnet sich automatisch (oder Hinweis erscheint)
- [ ] Fallback-Stimme wenn zugewiesene Stimme nicht verfügbar

### Multi-Device
- [ ] Mehrere Musiker erhalten gleichzeitig den Broadcast
- [ ] Verschiedene Stimmen für verschiedene Instrumente
- [ ] Verbindungsabbruch: Musiker erhält Broadcast nach Reconnect

### Dirigenten-Steuerung
- [ ] Nur Dirigent/Admin kann Broadcast senden
- [ ] Aktuelles Stück im Dirigenten-Dashboard anzeigen
- [ ] Broadcast-Historie

## Technische Hinweise

- Multi-Tab-Simulation: 1 Tab Dirigent, 2+ Tabs Musiker
- SignalR/WebSocket-Verbindung in Playwright testen
- Latenz-Messung: Broadcast → Empfang < definiertes Limit
- Offline-Szenario: Was passiert wenn Musiker offline ist?
