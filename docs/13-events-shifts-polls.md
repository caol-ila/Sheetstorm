# 13 — Mehrtages-Events, granulare Schichten, Bring-Listen, Umfragen

> **Status:** Spec, ersetzt das einfache Schichten-Modell aus Iter-13.
> **Verwandt:** 04 (Datenmodell), 01-§3 (Termine), 09 (Annotations).

## 13.1 Ziel

Termine in einer Blasmusik-Welt sind selten "ein Termin = eine Probe". Ein
Sommerfest hat mehrere Tage, jeder Tag mehrere Schichten an mehreren Ständen,
und nebenbei bringen Mitglieder Salate mit, müssen sich auf einen Fototermin
einigen und teilen ihre Uniformgröße mit. Sheetstorm bildet das in **drei
zusammenwirkenden Modulen** ab:

1. **Multi-Day-Event** mit Tagen und Time-Slots
2. **Granulare Schichten** (Stand × Zeitfenster × Rolle × benötigte Personen)
3. **Bring-Listen** (Salate, Kuchen, Getränke …) als Sonder-Schichten
4. **Umfragen / Polls** (Datums-Findung, Abstimmungen, Bedarfs-Erhebungen)

## 13.2 Multi-Day-Event

### Datenmodell-Erweiterung

```csharp
public class Event
{
    // wie bisher: Id, BandId, Title, StartUtc, EndUtc, Location, …
    public bool IsMultiDay { get; set; }
    public ICollection<EventDay> Days { get; set; }   // nur befuellt wenn IsMultiDay
    public ICollection<EventStation> Stations { get; set; } // z.B. "Bierausschank"
    public ICollection<EventShift> Shifts { get; set; }     // konkrete Time-Slots
    public ICollection<EventContribution> Contributions { get; set; } // Salat-Liste etc.
    public ICollection<EventPoll> Polls { get; set; }
}

public class EventDay
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }
    public DateOnly Date { get; set; }
    public string? Theme { get; set; }     // "Tag der Vereine"
    public TimeOnly? OpenAt { get; set; }
    public TimeOnly? CloseAt { get; set; }
}
```

UI: Event-Detail zeigt eine Tag-Übersicht (oben Tabs `Fr | Sa | So`), darunter
für den ausgewählten Tag die Stationen + Schichten.

## 13.3 Stationen & Schichten

Eine **Station** ist ein logischer Ort/Zweck (z. B. „Rote Wurst",
„Weinausschank", „Auf-/Abbau"), eine **Schicht** ist eine konkrete Zeit-Rolle
an einer Station mit einer Anzahl benötigter Personen.

```csharp
public class EventStation
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }
    public string Name { get; set; }        // "Rote Wurst", "Bierausschank"
    public string? Description { get; set; }
    public string? IconKey { get; set; }    // optional: vorgeschlagene Emojis
}

public class EventShift
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }
    public Guid? EventDayId { get; set; }   // null wenn 1-Tages-Event
    public Guid? StationId { get; set; }    // null = generische Schicht (z.B. "Aufbau")
    public string Title { get; set; }       // "Verkauf 12-14 Uhr"
    public DateTimeOffset StartUtc { get; set; }
    public DateTimeOffset EndUtc { get; set; }
    public int SlotsNeeded { get; set; }
    public string? Notes { get; set; }
}

public class EventShiftSignup
{
    public Guid Id { get; set; }
    public Guid ShiftId { get; set; }
    public Guid UserId { get; set; }
    public DateTimeOffset SignedUpAt { get; set; }
    public bool IsTentative { get; set; }   // "vielleicht" — nicht voll zaehlbar
}
```

### UI für Mitglieder

- **Listenansicht** Schichten nach Tag/Station gruppiert.
- Kachel pro Schicht: `12–14 Uhr · Rote Wurst · 2/3 belegt`.
- **Ein-Klick-Eintragen** (Toggle), Status `tentativ` möglich.
- Unterschritten-Marker für Schichten unter Plan (rot).

### UI für Veranstalter

- Schicht-Editor mit Wiederholungs-Generator: "Erzeuge alle 2 h von Sa 10:00
  bis 22:00 unter Station ‚Bierausschank' mit 2 Slots". Der Editor erzeugt
  daraus einen Batch von `EventShift`-Einträgen — vermeidet Click-Workflows.

## 13.4 Bring-Listen (Contributions)

Spezialform "ich bringe was" — keine Time-Slots, sondern Stückzahl.

```csharp
public class EventContribution
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }
    public string Title { get; set; }            // "Salat", "Kuchen", "Brezeln"
    public string? Description { get; set; }
    public ContributionUnit Unit { get; set; }   // Item | Liter | Stueck | Sonstiges
    public int? Wanted { get; set; }             // optional: Wunsch-Menge (z.B. 8 Salate)
}

public enum ContributionUnit { Item = 0, Liter = 1, Piece = 2, Other = 3 }

public class EventContributionPledge
{
    public Guid Id { get; set; }
    public Guid ContributionId { get; set; }
    public Guid UserId { get; set; }
    public string? What { get; set; }     // "Kartoffelsalat fuer 6"
    public int Quantity { get; set; }
    public DateTimeOffset PledgedAt { get; set; }
}
```

UI: Liste der Bring-Punkte mit Summen-Counter (`Salate: 4/8 zugesagt`).
Mitglieder sehen `+ ich bringe Salat (für 4)` mit Mengen-Eingabe.

## 13.5 Polls / Umfragen

Drei Poll-Typen, ein Datenmodell:

| Typ | Optionen | Antwort-Form |
|---|---|---|
| **Datum finden** | Datums-Vorschläge | pro Option: Ja / Vielleicht / Nein |
| **Abstimmung** | Frei-Text-Optionen | 1 Stimme oder mehrere zulassen |
| **Bedarf erheben** | strukturierte Felder (z. B. Größe, Anzahl) | freier Text + Auswahl |

```csharp
public class EventPoll
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }            // optional, kann auch BandPoll ohne Event sein
    public Guid? BandId { get; set; }            // wenn Event null: an ganzen Verein
    public PollKind Kind { get; set; }
    public string Title { get; set; }            // "Wann fotografieren?", "Neue Uniform"
    public string? Description { get; set; }
    public DateTimeOffset? ClosesAt { get; set; }
    public Guid CreatedByUserId { get; set; }
    public ICollection<PollOption> Options { get; set; }
    public ICollection<PollResponse> Responses { get; set; }
    public bool AllowMultiple { get; set; }
    public bool AnonymousResults { get; set; }   // anonym fuer Mitglieder, Owner sieht trotzdem
}

public enum PollKind
{
    DateFinder = 0,    // Optionen sind Datums/Time-Vorschlaege
    Vote = 1,          // Optionen sind Frei-Text
    DemandSurvey = 2,  // strukturierte Antworten (Groesse, Stueckzahl)
}

public class PollOption
{
    public Guid Id { get; set; }
    public Guid PollId { get; set; }
    public string Label { get; set; }            // "Sa 14:00", "Rot", "Größe 42"
    public DateTimeOffset? AsDateTime { get; set; } // nur DateFinder
    public int Order { get; set; }
}

public class PollResponse
{
    public Guid Id { get; set; }
    public Guid PollId { get; set; }
    public Guid UserId { get; set; }
    public Guid? OptionId { get; set; }            // bei Vote/DateFinder
    public PollAnswer Answer { get; set; }         // Yes/Maybe/No fuer DateFinder
    public string? FreeTextAnswer { get; set; }    // bei DemandSurvey
    public string? Size { get; set; }              // strukturierte Felder
    public int? Quantity { get; set; }
    public DateTimeOffset RespondedAt { get; set; }
}

public enum PollAnswer { No = 0, Maybe = 1, Yes = 2 }
```

### Use-Cases mit dem gleichen Modell

| Frage | Kind | Beispiel-Optionen |
|---|---|---|
| "Wann sollen wir den Fototermin planen?" | DateFinder | `Sa 14:00`, `So 10:00`, `So 14:00` |
| "Welche Farbe für die neue Uniform?" | Vote | `Schwarz`, `Dunkelblau`, `Burgund` |
| "Wer braucht eine neue Uniform und in welcher Größe?" | DemandSurvey | `S`, `M`, `L`, `XL`, `XXL`, freie Größe |
| "Wer kommt zum Sommerfest?" | Vote (Yes/No) | `Komme`, `Komme nicht` |

### UI

- Listenansicht aller offenen Polls auf der Event-Seite + im Verein-Dashboard.
- DateFinder zeigt eine Matrix `User × Datum` (wie Doodle), Owner sieht
  Reihen, Mitglied bearbeitet seine Reihe.
- Vote zeigt einen klassischen Balken pro Option mit Anzahl + Prozent.
- DemandSurvey zeigt Tabelle pro User mit den strukturierten Antworten,
  exportierbar als CSV.

## 13.6 Migration

Bestehende `Shift`-Tabelle aus Iter-13 wird umbenannt zu `EventShift` und
um `EventDayId`, `StationId`, `Notes` ergänzt. Ein Migration-Script verteilt
existierende Schichten auf einen Default-`EventDay` pro Event.

`ShiftAssignment` wird zu `EventShiftSignup` umbenannt (Begriffsschärfung:
es ist ein freiwilliger Eintrag, keine Zuweisung von oben).

## 13.7 Akzeptanzkriterien

- [ ] Veranstalter kann Event mit 3 Tagen und 4 Stationen anlegen.
- [ ] Schicht-Generator erzeugt Batch-Schichten in einem Schritt.
- [ ] Mitglieder sehen alle Schichten gruppiert nach Tag, können sich mit
      einem Klick eintragen.
- [ ] Bring-Liste zeigt Soll/Ist und akzeptiert Mengen.
- [ ] DateFinder mit Yes/Maybe/No zeigt klare Übersicht und „bestes Datum".
- [ ] Vote mit / ohne Mehrfach-Auswahl funktioniert.
- [ ] DemandSurvey kann als CSV exportiert werden.
- [ ] Anonyme Polls zeigen Mitgliedern nur Aggregate, Owner sieht alles.
- [ ] Schließdatum schließt automatisch (UI: read-only).
