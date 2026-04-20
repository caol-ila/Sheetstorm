# E2E: Stimmen & Noten-Bibliothek (Library browsing + filtering)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für die Noten-Bibliothek: Durchsuchen, Filtern, Stimmenauswahl und Fallback-Logik.

## Testfälle

### Bibliothek durchsuchen
- [ ] Notenliste wird nach Login angezeigt
- [ ] Scrolling / Pagination funktioniert bei vielen Einträgen
- [ ] Suchfeld: Volltextsuche nach Titel, Komponist
- [ ] Ergebnisse aktualisieren sich live während Eingabe

### Filtern
- [ ] Filter nach Instrument / Stimme
- [ ] Filter nach Kapelle (bei Multi-Kapellen)
- [ ] Filter kombinieren (Instrument + Suche)
- [ ] Filter zurücksetzen
- [ ] Leerer Zustand: Hinweis wenn keine Ergebnisse

### Stimmenauswahl
- [ ] Automatische Stimmenauswahl basierend auf User-Instrument
- [ ] Manuelle Stimmenauswahl aus Dropdown
- [ ] Fallback-Logik: Nächstliegende verfügbare Stimme wird vorgeschlagen
- [ ] Hinweis wenn Original-Stimme nicht verfügbar

### Noten-Detail-Ansicht
- [ ] Stück öffnen zeigt Thumbnail-Vorschau
- [ ] Metadaten werden korrekt angezeigt
- [ ] "Im Spielmodus öffnen" navigiert korrekt
- [ ] Persönliche Sammlung vs. Kapellen-Noten korrekt getrennt

## Technische Hinweise

- Seed-Daten: Mindestens 20 Stücke mit verschiedenen Stimmen
- Stimmen-Mapping aus Konfiguration laden
- Performance-Test: Bibliothek mit >100 Einträgen testen
