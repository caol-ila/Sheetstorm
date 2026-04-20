# E2E: Kommunikation (Board posts + notifications)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für das Kommunikationsboard: Beiträge, Kommentare, Reaktionen, Umfragen und Benachrichtigungen.

## Testfälle

### Beiträge
- [ ] Neuen Beitrag erstellen (Text)
- [ ] Beitrag mit Bild erstellen
- [ ] Beitrag bearbeiten
- [ ] Beitrag löschen (nur Autor/Admin)
- [ ] Beiträge chronologisch anzeigen

### Kommentare & Reaktionen
- [ ] Kommentar unter Beitrag schreiben
- [ ] Reaktion auf Beitrag (Emoji)
- [ ] Kommentar löschen
- [ ] Verschachtelte Kommentare (falls unterstützt)

### Umfragen
- [ ] Umfrage erstellen (Frage + Optionen)
- [ ] An Umfrage teilnehmen
- [ ] Ergebnisse anzeigen
- [ ] Umfrage schließen (Autor/Admin)

### Benachrichtigungen
- [ ] Benachrichtigung bei neuem Beitrag
- [ ] Register-gezielte Benachrichtigungen (nur Holzbläser, etc.)
- [ ] Benachrichtigung als gelesen markieren
- [ ] Benachrichtigungs-Einstellungen respektieren

## Technische Hinweise

- Mindestens 2 User-Accounts für Interaktions-Tests
- Push-Notifications in Flutter Web: Service Worker prüfen
- Real-time Updates: WebSocket/SignalR Verbindung testen
