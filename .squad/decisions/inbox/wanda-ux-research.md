# UX-Entscheidungsvorschlag: Kernpatterns aus Konkurrenzanalyse

> **Von:** Wanda (UX Designer)
> **Datum:** 2026-03-28
> **Typ:** UX-Designentscheidung
> **Priorität:** Hoch
> **Basiert auf:** `docs/ux-research-konkurrenz.md`

---

## Kontext

Nach intensiver Analyse von 14 Konkurrenz-Apps habe ich die UX-Patterns identifiziert, die Sheetstorm übernehmen MUSS, um am Markt zu bestehen. Jedes Pattern wurde bei mindestens einer erfolgreichen App validiert.

## Vorgeschlagene Entscheidungen

### 1. Performance-Modus = Vollbild mit Lock (MUST HAVE)
**Gesehen bei:** forScore, MobileSheets
**Begründung:** Beide Marktführer verstecken im Performance-Modus ALLE UI-Elemente. Nur Seitenwechsel ist möglich. Versehentliche Touches werden ignoriert. Das ist der Goldstandard für Live-Auftritte.
**Empfehlung:** Sheetstorm braucht einen dedizierten "Auftritt"-Button, der alles sperrt.

### 2. Half-Page-Turn ist Pflicht (MUST HAVE)
**Gesehen bei:** forScore, Newzik
**Begründung:** Der "Page-Jump-Schock" (plötzlich komplett neue Seite, man verliert die Stelle) ist das #1 Problem bei digitalen Noten. Half-Page-Turn zeigt die untere Hälfte der nächsten Seite an, während die obere Hälfte der aktuellen Seite noch sichtbar ist.
**Empfehlung:** Day-1-Feature. Fußpedal-kompatibel.

### 3. Drei-Ebenen-Annotationen als Differenzierer (MUST HAVE)
**Gesehen bei:** Newzik (2 Ebenen: Privat/Projekt), forScore (lokale Layers)
**Begründung:** Newzik kommt am nächsten mit Privat/Public/Shared, aber hat kein explizites "Stimmen-Layer". Kein Wettbewerber bietet unser Drei-Stufen-Modell: Privat → Stimme → Orchester. Das ist unser stärkster UX-Differenzierer.
**Empfehlung:** Umsetzen wie geplant. Dirigenten-Annotationen als "Orchester"-Layer, Registerführer auf "Stimme"-Layer, Musiker auf "Privat"-Layer.

### 4. Stylus-First Annotation (MUST HAVE)
**Gesehen bei:** forScore (Apple Pencil)
**Begründung:** forScore setzt den Standard: Stift berührt Screen = sofort annotieren. Kein Menü-Umweg. Für Probe-Situationen essentiell.
**Empfehlung:** Auch auf Android mit S-Pen/Stylus so umsetzen. Finger ≠ Stift in der Erkennung.

### 5. 1-Klick Stimmenneuverteilung (MUST HAVE)
**Gesehen bei:** Notabl
**Begründung:** Wenn ein Musiker absagt, muss die Stimme sofort an einen Ersatz übertragen werden können. Notabl löst das mit einem Klick. Wir sollten das mit unserem Fallback-System kombinieren.
**Empfehlung:** Bei Absage automatisch Ersatzmusiker vorschlagen (basierend auf Instrumentenprofil + Fallback-Logik).

### 6. Aushilfen-Link ohne Registrierung (SHOULD HAVE)
**Gesehen bei:** Musicorum
**Begründung:** Aushilfen bei Blaskapellen brauchen schnellen Zugang zu ihren Noten. Musicorum löst das mit einem temporären Download-Link ohne Account-Zwang. Brillant pragmatisch.
**Empfehlung:** Temporärer Link mit Ablaufdatum, nur die zugewiesene Stimme.

### 7. Web = Admin, App = Performance (SHOULD HAVE)
**Gesehen bei:** Newzik
**Begründung:** Newzik trennt klar: Web-Interface für Bibliotheksverwaltung, Metadaten, Projekte. iPad/App für Lesen, Annotieren, Aufführen. Das passt zum Blaskapellen-Workflow: Notenwart verwaltet am PC, Musiker spielt am Tablet.
**Empfehlung:** Admin-Features (Upload, Stimmenzuordnung, Archiv) prioritär als Web. Performance-Features (Viewer, Annotation, Setlist) prioritär als App.

## Offene Fragen

1. Sollen wir einen Feed à la BAND App für Vereinskommunikation bauen, oder reicht ein Chat?
2. Kalender-Sync (Google/Apple/Outlook): Ab welcher Phase?
3. Analytics-Dashboard (Anwesenheit, Trends): P1 oder P2?
