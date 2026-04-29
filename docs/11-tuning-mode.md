# 11 — Stimmen / Tuner

> **Status:** Spec, noch nicht implementiert.
> **Verwandt:** 10 (Metronom), 04 (Datenmodell — Instrument-Profile).

## 11.1 Ziel

Sheetstorm hat einen integrierten **Stimmgerät-Modus**: Mikrofon hört zu,
App zeigt Abweichung vom Soll-Ton. Drei Besonderheiten gegenüber
Standard-Tunern:

1. **Grundstimmung** (Konzertstimmung) ist konfigurierbar — pro Verein und
   pro Event. Default 442 Hz (deutscher Blasmusik-Standard), Spielraum
   435–446 Hz.
2. **Musiktheoretische Intonation**: nicht alle Töne sind gleich gestimmt
   (gleichstufig vs. rein vs. wohltemperiert). Die App gibt Tendenz-Hinweise
   für **Akkord-Intonation** (z. B. Terz im Dur-Akkord 14 Cent tiefer als
   gleichstufig).
3. **Instrumenten-Charakteristik**: jedes physische Blasinstrument hat
   bekannte Intonations-Schwächen (z. B. Tenorhorn-Ventil 1+3 ist gegenüber
   Ventil 4 schwebend zu hoch). Diese werden hinterlegt und als
   Erwartungs-Korrektur einbezogen.

## 11.2 Domänenmodell

### TuningProfile (Verein/Event)

```csharp
public class TuningProfile
{
    public Guid Id { get; set; }
    public Guid? BandId { get; set; }            // null = global / event-spezifisch
    public string Name { get; set; }             // "Probe-Stimmung", "Konzert"
    public double ReferencePitchHz { get; set; } // Default 442.0
    public TemperamentKind Temperament { get; set; } // EqualTempered | Just | Pythagorean
}
```

### InstrumentTuningProfile

Pro Instrument (oder pro physischem Exemplar) hinterlegt, welche Töne
strukturell wie weit abweichen. Cents = 1/100 Halbton.

```csharp
public class InstrumentTuningProfile
{
    public Guid Id { get; set; }
    public Guid InstrumentId { get; set; }
    public string DisplayName { get; set; }         // "Tenorhorn (mein Yamaha YEP-201)"
    public ICollection<NoteDeviation> Deviations { get; set; }
}

public class NoteDeviation
{
    public string NoteName { get; set; }   // "C4", "G4", "F#5"
    public string? Fingering { get; set; } // "1+3", "4", "T13" — optional
    public double ExpectedCents { get; set; } // z.B. +18 für Tenorhorn 1+3
    public string? Note { get; set; }      // freie Notiz
}
```

Beispiel (Tenorhorn):

| Note | Griff | Erwartung |
|---|---|---|
| F4 | 1+3 | +18 ct |
| F4 | 4   | +2 ct |
| Es4 | 2+3 | +25 ct |

Quelle: Standard-Werte aus Akustik-Tabellen + Möglichkeit pro User
einzumessen.

### Voreinstellungen

Sheetstorm liefert für jede Standard-Blasmusik-Familie ein
**Standard-Profil** mit typischen Abweichungen aus, das der User klonen und
anpassen kann ("Mein Tenorhorn").

## 11.3 Tuner-Algorithmus

### Pitch-Detection

- **Eingabe:** Mikrofon-Stream (`getUserMedia`, mono, 44.1 kHz).
- **Verfahren:** YIN-Pitch-Detection (Algorithmus von de Cheveigné/Kawahara).
  - Zuverlässig für Blasinstrumente im Bereich 60 Hz – 2 kHz.
  - Gibt Frequenz + Confidence (0–1).
- **Frame-Länge:** 2048 Samples ≈ 46 ms — ausreichend für untere Töne.
- **Glättung:** Median über 5 Frames + Confidence-Threshold (0.85).

### Soll-Ton-Bestimmung

1. User wählt zu spielenden Ton (Default: B♭ als Stimm-Ton),
   oder die App erkennt automatisch (Pitch → nächster Halbton).
2. Soll-Frequenz =
   `ReferencePitchHz × 2^((midiNote − 69 + temperamentOffset)/12)`
   - `temperamentOffset` aus TemperamentKind + Akkord-Kontext (für
     Stimm-Modus i. d. R. = 0; nur bei Akkord-Tuning relevant).
3. Davon wird die **erwartete Geräte-Abweichung**
   (`InstrumentTuningProfile.NoteDeviation.ExpectedCents`) abgezogen — wir
   wollen ja den **musikalisch klingenden Ton** treffen, nicht den
   physikalisch absolut korrekten.

### Cent-Differenz

```
deltaCents = 1200 × log2(measuredHz / expectedHz)
```

## 11.4 UI: Stimmungs-Anzeige

### Anti-Flacker-Regeln

Standard-Tuner-Apps wackeln nervös. Sheetstorm bewusst **nicht**:

1. **Diskrete Zonen** statt freier Skala:
   - `--`  : sehr stark zu tief (> 25 ct)
   - `-`   : stark zu tief (10–25 ct)
   - `(-)` : leicht zu tief (3–10 ct)
   - `✓`   : sauber (≤ 3 ct, hold ≥ 1 s)
   - `(+)` : leicht zu hoch (3–10 ct)
   - `+`   : stark zu hoch (10–25 ct)
   - `++`  : sehr stark zu hoch (> 25 ct)
2. **Hysterese**: Zonenwechsel erst wenn der gemessene Cent-Wert für
   ≥ 300 ms in der neuen Zone bleibt. Verhindert Springen an Zonengrenzen.
3. **Sachliche Sprache**: kein animierter Zeiger. Statt Feedback-Loops
   einfache Klartext-Botschaften:
   - "Etwas weiter rein" (zu tief)
   - "Etwas weiter raus" (zu hoch)
   - "Sauber" (in der ✓-Zone)
4. **Confidence-Gating**: bei Confidence < 0.85 zeigt die App neutral
   `… höre zu`, kein Zucken.

### Visuelles Layout

```
┌──────────────────────────────────────┐
│  Stimm-Modus     442 Hz   B♭         │
├──────────────────────────────────────┤
│                                       │
│   −−    −    (−)    ✓    (+)    +    ++│
│                     ▔                  │
│                                       │
│   "Etwas weiter raus"                 │
│   gemessen 232.4 Hz · +6 ct           │
│                                       │
│   Erwartete Abweichung: 1+3 → +18 ct  │
└──────────────────────────────────────┘
```

- Aktive Zone fett unterstrichen, Nachbarzonen grau.
- Hauptbotschaft groß und ruhig.
- Diagnostik (gemessen Hz, Cent, Profil-Korrektur) klein darunter — für
  Power-User und Lehrer.

### Mobile-Optimierung

- Großer ✓-Indikator wenn sauber → grüne Vollfläche, kein Augen-Stress.
- Haptik: kurzes Vibrieren wenn ✓-Zone erreicht (Native Wrapper).
- Kein Sound-Output während Stimm-Modus, sonst Mic-Feedback.

## 11.5 Akkord-Intonation (Phase 2)

Optional: in Probe mit Click + Akkord-Kontext zeigt die App, wie der
**individuelle Spieler** im Akkord intonieren sollte:

- Dirigent gibt Akkord vor (z. B. F-Dur).
- Jeder Spieler sieht **seinen** Soll-Ton mit Cent-Korrektur:
  - Grundton: 0 ct
  - Terz: −14 ct (rein)
  - Quinte: +2 ct (rein)
- Genau dieselbe Anzeige wie 11.4, nur mit angepasstem Erwartungswert.

## 11.6 Datenmodell-Erweiterungen

```csharp
public enum TemperamentKind { EqualTempered = 0, Just = 1, Pythagorean = 2 }

// Verein-Setting
band.DefaultReferencePitchHz = 442.0;

// Pro User:
user.PreferredInstrumentTuningProfileId = ...;
```

## 11.7 Datenschutz

- Mikrofon-Stream wird **nie** an den Server geschickt.
- Erkannter Ton + Cent-Abweichung kann optional anonymisiert für Statistik
  geloggt werden (Opt-In, Default aus).

## 11.8 Akzeptanzkriterien

- [ ] Stimm-Modus erkennt B♭3 (233 Hz) auf ±2 ct genau bei sauberem
      Mikrofon-Eingang.
- [ ] Anzeige bleibt mindestens 300 ms in einer Zone (keine Mikro-Flacker).
- [ ] Beim Wechsel zu Tenorhorn-Profil 1+3-Griff wird die erwartete
      Abweichung +18 ct in der UI angezeigt und im Vergleich verwendet.
- [ ] Reference-Pitch-Slider 435–446 Hz pro Event speicherbar.
- [ ] Bei keiner Stimme (Stille / Sprache): UI zeigt `… höre zu`, nicht 0
      Hz / wackeln.
- [ ] Mikrofon-Stream verlässt nie den Browser (nur Pitch + Cent über API,
      und auch das nur opt-in).
