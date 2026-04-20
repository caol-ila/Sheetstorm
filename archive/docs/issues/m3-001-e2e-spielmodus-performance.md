# E2E: Spielmodus / Performance Mode (Sheet display + navigation)

**Labels:** `milestone:3`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für den erweiterten Spielmodus (MS3): Notenblatt-Anzeige, Seitennavigation, Half-Page-Turn, BLE-Fußpedal-Simulation, Nachtmodus und Performance-Optimierungen.

## Testfälle

### Notenblatt-Anzeige
- [ ] Stück öffnen → Noten werden korrekt gerendert
- [ ] Zoom: Pinch-to-Zoom (Touch-Simulation) und Button-Zoom
- [ ] Verschiedene Seitenformate korrekt dargestellt
- [ ] Hochformat / Querformat Wechsel

### Seitennavigation
- [ ] Weiterblättern per Swipe
- [ ] Weiterblättern per Tap (rechter/linker Bildschirmrand)
- [ ] Half-Page-Turn: Halber Seitenumbruch für nahtloses Lesen
- [ ] Seitenindikator zeigt aktuelle Position
- [ ] Zur Seite springen (Seitenauswahl)

### BLE Fußpedal (Simulation)
- [ ] Fußpedal-Eingabe simulieren (Keyboard-Shortcut als Proxy)
- [ ] Vor/Zurück-Blättern per Pedal
- [ ] Pedal-Konfiguration in Einstellungen

### Darstellungsmodi
- [ ] Nachtmodus (invertierte Farben)
- [ ] Auto-Scroll Modus
- [ ] Vollbildmodus (ablenkungsfrei)
- [ ] Helligkeitsanpassung innerhalb der App

### Performance
- [ ] Seitenübergang < 100ms (keine sichtbare Verzögerung)
- [ ] Vorlade-Logik: Nächste Seiten werden im Hintergrund geladen
- [ ] Speicherverbrauch bleibt stabil bei langen Stücken (>50 Seiten)

## Technische Hinweise

- Touch-Gesten: Playwright `touchscreen` API
- Performance-Messung: `performance.mark()` / `performance.measure()`
- Fußpedal: Keyboard-Event als Proxy (kein echtes BLE im E2E)
- Fullscreen-API Handling in verschiedenen Browsern
