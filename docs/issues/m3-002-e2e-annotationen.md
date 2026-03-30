# E2E: Annotation system (Draw, Text, Layer visibility)

**Labels:** `milestone:3`, `testing`, `e2e`

## Beschreibung

End-to-End-Tests für das erweiterte Annotationssystem (MS3): Freihand-Zeichnen, Text-Annotationen, Symbol-Stempel, Sichtbarkeitsebenen und Echtzeit-Sync.

## Testfälle

### Freihand-Zeichnen
- [ ] Stift-Tool auswählen und auf Notenblatt zeichnen
- [ ] Farbe wechseln
- [ ] Strichstärke anpassen
- [ ] Radierer-Tool zum Löschen einzelner Striche

### Text-Annotationen
- [ ] Text-Tool: Klick auf Position → Textfeld erscheint
- [ ] Text eingeben und bestätigen
- [ ] Text verschieben (Drag)
- [ ] Text bearbeiten (Doppelklick)
- [ ] Text löschen

### Symbol-Stempel
- [ ] Musik-Symbole aus Palette wählen (Dynamik, Tempo, etc.)
- [ ] Symbol auf Notenblatt platzieren
- [ ] Symbol verschieben
- [ ] Symbol löschen

### Sichtbarkeitsebenen
- [ ] Privat (Grün): Nur für den eigenen User sichtbar
- [ ] Stimme (Blau): Für alle mit gleicher Stimme sichtbar
- [ ] Orchester (Orange): Für alle in der Kapelle sichtbar
- [ ] Ebenen-Sichtbarkeit ein-/ausschalten (Toggle)
- [ ] Korrekte Farbcodierung der Annotationen

### Undo/Redo
- [ ] Undo: Letzte Aktion rückgängig machen
- [ ] Redo: Rückgängig gemachte Aktion wiederherstellen
- [ ] Mehrfaches Undo/Redo
- [ ] Undo-Historie wird bei neuer Aktion abgeschnitten

### Echtzeit-Sync (MS3-Erweiterung)
- [ ] Orchester-Annotation erscheint in Echtzeit bei anderen Musikern
- [ ] Stimmen-Annotation erscheint bei Musikern gleicher Stimme
- [ ] Konflikt-Handling bei gleichzeitiger Bearbeitung
- [ ] Offline-Annotationen werden nach Reconnect synchronisiert

## Technische Hinweise

- Canvas-Interaktion: Playwright `mouse.move()` + `mouse.down()` + `mouse.up()` für Zeichnen
- SVG-Layer: DOM-Inspektion der SVG-Elemente für Validierung
- Multi-Tab für Sync-Tests (Tab 1 zeichnet, Tab 2 sieht)
- SignalR-Verbindung für Echtzeit-Sync testen
- Relative Positionen (%) prüfen: Annotation-Position muss zoom-unabhängig sein
