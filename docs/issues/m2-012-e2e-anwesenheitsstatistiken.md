# E2E: Anwesenheitsstatistiken (Attendance analytics)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für Anwesenheitsstatistiken: Auswertung nach Musiker, Register, Zeitraum und Event-Typ mit Export.

## Testfälle

### Statistik-Ansichten
- [ ] Anwesenheit pro Musiker anzeigen (Prozent, Absolut)
- [ ] Anwesenheit pro Register aggregiert
- [ ] Zeitraum-Filter (Monat, Quartal, Jahr, Custom)
- [ ] Event-Typ-Filter (Konzert, Probe, Sonstiges)

### Diagramme
- [ ] Balkendiagramm: Anwesenheit nach Musiker
- [ ] Trendlinie: Anwesenheit über Zeit
- [ ] Korrekte Daten in Tooltips/Labels

### Export
- [ ] CSV-Export der Statistiken
- [ ] PDF-Export mit Diagrammen
- [ ] Download funktioniert im Browser
- [ ] Korrekte Daten im Export

### Berechtigungen
- [ ] Admin/Vorstand sieht alle Statistiken
- [ ] Musiker sieht nur eigene Statistik
- [ ] Dirigent sieht Register-Übersicht

## Technische Hinweise

- Seed-Daten: Mindestens 20 Events mit Anwesenheitsdaten
- Chart-Rendering: Canvas-basiert, Screenshot-Vergleich verwenden
- PDF-Export: Download-Event in Playwright abfangen
