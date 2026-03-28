# E2E: GEMA & Compliance (Reports + Export)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für GEMA-Compliance: Setlist-basierte Reports, Werknummer-Suche, Export-Formate und Erinnerungen.

## Testfälle

### Report generieren
- [ ] GEMA-Report für eine Setlist/Konzert erstellen
- [ ] Report enthält alle erforderlichen Felder (Titel, Komponist, Verlag, Werknummer)
- [ ] Automatische Befüllung aus Stück-Metadaten
- [ ] Fehlende Felder werden markiert

### Werknummer-Suche
- [ ] GEMA-Werknummer für ein Stück suchen
- [ ] Ergebnis in Metadaten übernehmen
- [ ] Handling bei keinem Ergebnis

### Export
- [ ] Export als CSV
- [ ] Export als PDF
- [ ] GEMA-konformes Format (offizielle Vorlage)
- [ ] Download funktioniert im Browser

### Erinnerungen
- [ ] Erinnerung vor Konzert: GEMA-Meldung ausfüllen
- [ ] Hinweis bei Stücken ohne GEMA-Werknummer
- [ ] Dashboard-Widget: Offene GEMA-Meldungen

## Technische Hinweise

- GEMA-API Mock für Werknummer-Suche
- PDF-Download: Playwright `download` Event abfangen
- CSV-Inhalt validieren (korrekte Spalten, Encoding)
