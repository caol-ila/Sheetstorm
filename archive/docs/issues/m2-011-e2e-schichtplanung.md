# E2E: Schichtplanung (Shift management)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für die Schichtplanung: Schichten für Events erstellen, Zuordnung durch Admin oder Selbstzuordnung.

## Testfälle

### Schichten erstellen
- [ ] Schicht für einen Termin anlegen (Name, Zeitraum, benötigte Personen)
- [ ] Mehrere Schichten pro Termin
- [ ] Schicht bearbeiten
- [ ] Schicht löschen

### Zuordnung
- [ ] Admin weist Musiker einer Schicht zu
- [ ] Musiker meldet sich selbst für offene Schicht an
- [ ] Maximale Teilnehmer pro Schicht wird respektiert
- [ ] Musiker von Schicht abmelden

### Übersicht
- [ ] Schichtplan-Übersicht für einen Termin
- [ ] Offene Schichten hervorgehoben
- [ ] Eigene Schichten in persönlicher Ansicht

## Technische Hinweise

- Mehrere User-Accounts für Zuordnungs-Tests
- Berechtigungen: Admin vs. Musiker-Selbstzuordnung
