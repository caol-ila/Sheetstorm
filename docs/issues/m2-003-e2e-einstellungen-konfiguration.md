# E2E: Einstellungen & Konfiguration (Settings screens)

**Labels:** `milestone:2`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für das 3-Ebenen-Konfigurationssystem: Kapelle, Nutzer, Gerät.

## Testfälle

### Nutzer-Einstellungen (Ebene 2)
- [ ] Theme wechseln (Hell/Dunkel)
- [ ] Sprache ändern (wenn i18n aktiviert)
- [ ] Standard-Instrument setzen
- [ ] Standard-Stimme pro Kapelle festlegen
- [ ] Benachrichtigungen konfigurieren
- [ ] Persönlicher AI-Key eintragen (wenn erlaubt)
- [ ] Einstellungen werden nach Page-Reload beibehalten

### Geräte-Einstellungen (Ebene 3)
- [ ] Display-Einstellungen (Helligkeit, Schriftgröße)
- [ ] Audio/Tuner-Einstellungen
- [ ] Touch-Einstellungen
- [ ] Offline-Speicher-Management
- [ ] Einstellungen sind geräte-lokal (nicht synchronisiert)

### Kapellen-Einstellungen (Ebene 1) — nur Admin
- [ ] AI-Keys verwalten
- [ ] Berechtigungen konfigurieren
- [ ] Branding anpassen
- [ ] Policies setzen (forceLocale, allowUserKeys)
- [ ] Nicht-Admins sehen keine Kapellen-Einstellungen

### Override-Logik
- [ ] Gerät > Nutzer > Kapelle > System-Default
- [ ] Policy-Lock: Kapelle kann Override verbieten
- [ ] Korrekte Anzeige des effektiven Werts + Herkunft

## Technische Hinweise

- 3 Rollen testen: Admin, Dirigent, Musiker
- Override-Kaskade mit verschiedenen Kombinationen testen
- Storage-State zwischen Tests isolieren
