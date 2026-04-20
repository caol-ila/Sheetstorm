# E2E: Konzertplanung & Kalender (Event management + RSVP)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für die Konzertplanung mit Kalender, Zu-/Absage-Flow und Ersatzmusiker-Vorschläge.

## Testfälle

### Termin erstellen
- [ ] Konzert anlegen (Titel, Datum, Ort, Beschreibung)
- [ ] Probe anlegen
- [ ] Wiederkehrende Termine erstellen
- [ ] Setlist mit Termin verknüpfen
- [ ] Validierung: Pflichtfelder, Datum in der Zukunft

### Kalender-Ansichten
- [ ] Monatsansicht: Termine als Punkte/Tags
- [ ] Wochenansicht: Termine mit Zeitblöcken
- [ ] Listenansicht: Chronologische Liste
- [ ] Navigation zwischen Monaten/Wochen

### Zu-/Absage (RSVP)
- [ ] Musiker sagt zu einem Termin zu
- [ ] Musiker sagt ab (mit optionalem Grund)
- [ ] Rückmeldungsstatus wird angezeigt (zugesagt/abgesagt/offen)
- [ ] Admin sieht Übersicht aller Rückmeldungen
- [ ] Erinnerung bei fehlender Rückmeldung

### Ersatzmusiker
- [ ] System schlägt Ersatzmusiker vor bei Absage
- [ ] Ersatzmusiker erhält Benachrichtigung
- [ ] Ersatzmusiker kann zusagen/absagen

## Technische Hinweise

- Datums-Picker: Flutter-spezifische Selektoren verwenden
- Mehrere User-Accounts für RSVP-Tests benötigt
- Kalender-Sync (iCal Export) als separater Test
