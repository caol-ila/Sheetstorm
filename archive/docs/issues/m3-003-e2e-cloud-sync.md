# E2E: Cloud-Sync (Delta-Sync + Offline-Fähigkeit)

**Labels:** `milestone:3`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für Cloud-Sync: Delta-Sync zwischen Client und Server, Offline-Fähigkeit und Konfliktlösung (Last-Write-Wins).

## Testfälle

### Online-Sync
- [ ] Änderungen auf Gerät A werden auf Gerät B synchronisiert
- [ ] Nur geänderte Daten werden übertragen (Delta-Sync)
- [ ] Sync-Status-Indikator zeigt aktuellen Zustand
- [ ] Sync nach Noten-Import
- [ ] Sync nach Metadaten-Änderung

### Offline-Modus
- [ ] App funktioniert ohne Internetverbindung
- [ ] Noten sind offline verfügbar (lokaler Cache)
- [ ] Offline-Änderungen werden lokal gespeichert
- [ ] Sync startet automatisch bei Reconnect
- [ ] Offline-Indikator wird angezeigt

### Konfliktlösung
- [ ] Last-Write-Wins bei gleichzeitiger Bearbeitung
- [ ] Konflikt-Benachrichtigung (optional)
- [ ] Daten-Integrität nach Konfliktlösung
- [ ] Timestamps korrekt für LWW-Entscheidung

### Daten-Integrität
- [ ] Alle Datentypen werden korrekt synchronisiert (Noten, Metadaten, Annotationen, Einstellungen)
- [ ] Große Dateien (PDFs) werden effizient synchronisiert
- [ ] Sync-Fehler werden angezeigt und Retry ist möglich

## Technische Hinweise

- Offline-Simulation: Playwright `context.setOffline(true)`
- Multi-Tab als Multi-Device-Simulation
- Network-Throttling für langsame Verbindungen testen
- Storage-Inspektion: IndexedDB / SQLite-Daten prüfen
