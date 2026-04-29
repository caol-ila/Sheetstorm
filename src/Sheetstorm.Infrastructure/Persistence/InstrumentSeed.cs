using Sheetstorm.Domain.Identity;

namespace Sheetstorm.Infrastructure.Persistence;

/// <summary>
/// Stamm-Stimmen für Blasmusik. Stabile GUIDs, damit Migrations
/// idempotent sind und Tests darauf referenzieren können.
/// </summary>
public static class InstrumentSeed
{
    public static IReadOnlyList<Instrument> All { get; } = new[]
    {
        // Holz
        Instrument.CreateWithId(new("11111111-0001-0000-0000-000000000001"), InstrumentFamily.Holz, "Pikkoloflöte", "C"),
        Instrument.CreateWithId(new("11111111-0002-0000-0000-000000000001"), InstrumentFamily.Holz, "Flöte", "C"),
        Instrument.CreateWithId(new("11111111-0003-0000-0000-000000000001"), InstrumentFamily.Holz, "Oboe", "C"),
        Instrument.CreateWithId(new("11111111-0004-0000-0000-000000000001"), InstrumentFamily.Holz, "Fagott", "C"),
        Instrument.CreateWithId(new("11111111-0005-0000-0000-000000000001"), InstrumentFamily.Holz, "Klarinette in Es", "Es"),
        Instrument.CreateWithId(new("11111111-0005-0000-0000-000000000002"), InstrumentFamily.Holz, "Klarinette in B", "B"),
        Instrument.CreateWithId(new("11111111-0005-0000-0000-000000000003"), InstrumentFamily.Holz, "Bassklarinette in B", "B"),
        Instrument.CreateWithId(new("11111111-0006-0000-0000-000000000001"), InstrumentFamily.Holz, "Sopransaxophon", "B"),
        Instrument.CreateWithId(new("11111111-0006-0000-0000-000000000002"), InstrumentFamily.Holz, "Altsaxophon", "Es"),
        Instrument.CreateWithId(new("11111111-0006-0000-0000-000000000003"), InstrumentFamily.Holz, "Tenorsaxophon", "B"),
        Instrument.CreateWithId(new("11111111-0006-0000-0000-000000000004"), InstrumentFamily.Holz, "Baritonsaxophon", "Es"),

        // Blech
        Instrument.CreateWithId(new("22222222-0001-0000-0000-000000000001"), InstrumentFamily.Blech, "Trompete in B", "B"),
        Instrument.CreateWithId(new("22222222-0001-0000-0000-000000000002"), InstrumentFamily.Blech, "Flügelhorn", "B"),
        Instrument.CreateWithId(new("22222222-0002-0000-0000-000000000001"), InstrumentFamily.Blech, "Horn in F", "F"),
        Instrument.CreateWithId(new("22222222-0002-0000-0000-000000000002"), InstrumentFamily.Blech, "Horn in Es", "Es"),
        Instrument.CreateWithId(new("22222222-0003-0000-0000-000000000001"), InstrumentFamily.Blech, "Tenorhorn", "B"),
        Instrument.CreateWithId(new("22222222-0003-0000-0000-000000000002"), InstrumentFamily.Blech, "Bariton", "B"),
        Instrument.CreateWithId(new("22222222-0003-0000-0000-000000000003"), InstrumentFamily.Blech, "Euphonium", "C"),
        Instrument.CreateWithId(new("22222222-0004-0000-0000-000000000001"), InstrumentFamily.Blech, "Posaune", "C"),
        Instrument.CreateWithId(new("22222222-0005-0000-0000-000000000001"), InstrumentFamily.Blech, "Tuba in B", "B"),
        Instrument.CreateWithId(new("22222222-0005-0000-0000-000000000002"), InstrumentFamily.Blech, "Tuba in Es", "Es"),

        // Schlagwerk
        Instrument.CreateWithId(new("33333333-0001-0000-0000-000000000001"), InstrumentFamily.Schlagwerk, "Schlagzeug-Set", null),
        Instrument.CreateWithId(new("33333333-0002-0000-0000-000000000001"), InstrumentFamily.Schlagwerk, "Pauken", null),
        Instrument.CreateWithId(new("33333333-0003-0000-0000-000000000001"), InstrumentFamily.Schlagwerk, "Mallets/Stabspiel", null),
        Instrument.CreateWithId(new("33333333-0004-0000-0000-000000000001"), InstrumentFamily.Schlagwerk, "Kleines Schlagwerk", null),

        // Sonstige / Partituren
        Instrument.CreateWithId(new("44444444-0001-0000-0000-000000000001"), InstrumentFamily.Sonstige, "Partitur", "C"),
        Instrument.CreateWithId(new("44444444-0002-0000-0000-000000000001"), InstrumentFamily.Sonstige, "Direktion", "C"),
    };
}
