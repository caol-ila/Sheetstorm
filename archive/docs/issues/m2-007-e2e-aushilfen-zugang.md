# E2E: Aushilfen-Zugang (Temporary access via link/QR)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für den temporären Aushilfen-Zugang: Token-basierter Zugriff ohne Account auf spezifische Stimmen für bestimmte Events.

## Testfälle

### Link/QR generieren
- [ ] Admin generiert Aushilfen-Link für spezifischen Termin + Stimme
- [ ] QR-Code wird korrekt angezeigt
- [ ] Link enthält Token mit Ablaufdatum
- [ ] Mehrere Links für verschiedene Stimmen generieren

### Aushilfen-Zugang nutzen
- [ ] Aushilfe öffnet Link im Browser (kein Login nötig)
- [ ] Nur die zugewiesene Stimme ist sichtbar
- [ ] Nur die Noten des zugewiesenen Termins sind verfügbar
- [ ] Spielmodus funktioniert für Aushilfe

### Einschränkungen & Ablauf
- [ ] Aushilfe kann keine anderen Bereiche der App nutzen
- [ ] Link läuft nach definierter Zeit ab
- [ ] Abgelaufener Link zeigt freundliche Fehlermeldung
- [ ] Admin kann Link vorzeitig deaktivieren

### Sicherheit
- [ ] Manipulierter Token wird abgelehnt
- [ ] Rate-Limiting bei Token-Validierung
- [ ] Kein Zugriff auf andere Kapellen-Daten

## Technische Hinweise

- Incognito-Browser-Kontext für Aushilfen-Session
- Token-Manipulation via URL-Parameter testen
- Ablauf-Simulation: Token mit kurzem TTL generieren
