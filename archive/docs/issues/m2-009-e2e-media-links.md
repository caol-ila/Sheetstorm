# E2E: Media Links (YouTube/Spotify Referenzen)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für das Verknüpfen von YouTube/Spotify-Links mit Musikstücken.

## Testfälle

### Links hinzufügen
- [ ] YouTube-Link zu einem Stück hinzufügen
- [ ] Spotify-Link zu einem Stück hinzufügen
- [ ] Mehrere Links pro Stück
- [ ] URL-Validierung (nur YouTube/Spotify akzeptiert)
- [ ] Metadaten-Vorschau (Titel, Thumbnail) wird geladen

### Links anzeigen & abspielen
- [ ] Links werden in der Stück-Detailansicht angezeigt
- [ ] Klick öffnet Player/Embedded-View (oder externen Link)
- [ ] Thumbnail und Titel korrekt dargestellt

### Links verwalten
- [ ] Link bearbeiten (URL ändern)
- [ ] Link löschen
- [ ] Reihenfolge ändern (primärer Link oben)

## Technische Hinweise

- oEmbed API für Metadaten-Vorschau (ggf. Mock im Test)
- Externe URLs nicht tatsächlich aufrufen in Tests (Network-Interception)
- Berechtigungsprüfung: Wer darf Links hinzufügen?
