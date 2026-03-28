# E2E: Kapellenverwaltung (Band management workflow)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für die komplette Kapellenverwaltung: Erstellen, Mitglieder einladen, Rollen verwalten, Multi-Kapellen-Wechsel.

## Testfälle

### Kapelle erstellen
- [ ] Neue Kapelle anlegen (Name, Beschreibung, Branding)
- [ ] Validierung: Pflichtfelder, Namens-Duplikate
- [ ] Ersteller erhält automatisch Admin-Rolle

### Mitglieder verwalten
- [ ] Einladungslink generieren und teilen
- [ ] Neues Mitglied tritt über Einladungslink bei
- [ ] Mitglied Instrument/Stimme zuweisen
- [ ] Rollen zuweisen (Admin, Dirigent, Musiker, Vorstand)
- [ ] Mitglied entfernen
- [ ] Berechtigungsprüfung: Nur Admin darf Rollen ändern

### Multi-Kapellen
- [ ] Zwischen Kapellen wechseln
- [ ] Korrekter Kontext nach Wechsel (Noten, Einstellungen)
- [ ] Kapellen-spezifische Konfiguration wird geladen

### Registerverwaltung
- [ ] Register anlegen (z.B. Holzbläser, Blechbläser)
- [ ] Instrumente den Registern zuordnen
- [ ] Musiker den Registern zuordnen über Instrumente

## Technische Hinweise

- Auth-State aus Fixture laden (Login nicht in jedem Test wiederholen)
- Seed-Daten für existierende Kapelle mit Mitgliedern
- Parallele Tests mit isolierten Kapellen (keine Konflikte)
