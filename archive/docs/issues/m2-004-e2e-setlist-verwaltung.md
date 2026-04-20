# E2E: Setlist-Verwaltung (Setlist creation + player integration)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für die Setlist-Verwaltung: Erstellen, Bearbeiten, Sortieren und Integration mit dem Spielmodus.

## Testfälle

### Setlist erstellen
- [ ] Neue Setlist anlegen (Name, Anlass, Datum)
- [ ] Stücke aus Bibliothek zur Setlist hinzufügen
- [ ] Reihenfolge per Drag & Drop ändern
- [ ] Stücke aus Setlist entfernen
- [ ] Leere Setlist: Hinweismeldung

### Setlist-Typen
- [ ] Konzert-Setlist erstellen
- [ ] Proben-Setlist erstellen
- [ ] Marsch-Setlist erstellen (spezielle Anforderungen)

### Player-Integration
- [ ] "Setlist spielen" öffnet Spielmodus mit erstem Stück
- [ ] Navigation zum nächsten/vorherigen Stück in der Setlist
- [ ] Setlist-Fortschritt wird angezeigt
- [ ] Alle Stücke haben korrekte Stimme basierend auf User-Instrument

### Verwaltung
- [ ] Setlist bearbeiten (Name, Stücke)
- [ ] Setlist duplizieren
- [ ] Setlist löschen (mit Bestätigung)
- [ ] Setlist-Liste mit Suche und Filter

## Technische Hinweise

- Seed-Daten: Bibliothek mit Stücken die verschiedene Stimmen haben
- Drag & Drop in Flutter Web: Playwright `dragTo()` verwenden
- Player-Integration erfordert vollständig geladene Noten
