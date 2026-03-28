# SKILL: Wertorientierte Meilensteinplanung

## Pattern

Jeder Meilenstein muss ein **vollständiges, deploybares Produkt** sein — kein Feature-Flag, kein "kommt im nächsten Release".

## Struktur pro Meilenstein

1. **Mehrwert-Statement:** Ein Satz aus Nutzersicht ("Ich kann jetzt X tun")
2. **Scope:** Feature-IDs aus der Spezifikation
3. **Deliverables:** Konkrete Artefakte (Module, APIs, Docs)
4. **Abhängigkeiten:** Was muss vorher fertig sein
5. **Testing & UX-Validierung:** Testtypen + reale Nutzer-Tests
6. **Definition of Done:** Checkliste für "fertig"

## Regeln

- Keine halben Features: Wenn ein Feature in einem Meilenstein ist, muss es komplett funktionieren
- Testing ist Teil des Meilensteins, nicht nachgelagert
- UX-Validierung mit echten Nutzern (nicht nur Entwickler-Tests)
- Parallelisierbarkeit dokumentieren (welche Meilensteine unabhängig sind)

## Anti-Patterns

- "Feature X kommt in M2, aber die UI dafür ist erst in M3 fertig" → Feature gehört komplett in M3
- "Tests schreiben wir nach M5" → Tests sind Teil jedes Meilensteins
- "Wir deployen nach dem letzten Meilenstein" → Jeder Meilenstein wird deployt
