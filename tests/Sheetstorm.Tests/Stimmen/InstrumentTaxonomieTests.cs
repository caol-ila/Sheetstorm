using Sheetstorm.Domain.Stimmen;

namespace Sheetstorm.Tests.Stimmen;

public class InstrumentTaxonomieTests
{
    // ── All families have instruments ─────────────────────────────────────────

    [Fact]
    public void AlleFamilien_EachHasAtLeastOneInstrument()
    {
        foreach (var familie in InstrumentTaxonomie.AlleFamilien)
        {
            var count = InstrumentTaxonomie.TypZuFamilie.Values.Count(v => v.Familie == familie);
            Assert.True(count > 0, $"Familie '{familie}' hat keine Instrumente.");
        }
    }

    [Fact]
    public void AlleFamilien_ContainsAllFourExpectedFamilies()
    {
        Assert.Contains(InstrumentTaxonomie.FamilieHolzblaeser, InstrumentTaxonomie.AlleFamilien);
        Assert.Contains(InstrumentTaxonomie.FamilieBlechblaeser, InstrumentTaxonomie.AlleFamilien);
        Assert.Contains(InstrumentTaxonomie.FamilieSchlagwerk, InstrumentTaxonomie.AlleFamilien);
        Assert.Contains(InstrumentTaxonomie.FamilieTasten, InstrumentTaxonomie.AlleFamilien);
    }

    // ── GetFamilie ────────────────────────────────────────────────────────────

    [Theory]
    [InlineData("floete", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("piccolo", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("oboe", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("klarinette", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("bassklarinette", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("fagott", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("saxophon_sopran", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("saxophon_alt", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("saxophon_tenor", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("saxophon_bariton", InstrumentTaxonomie.FamilieHolzblaeser)]
    [InlineData("trompete", InstrumentTaxonomie.FamilieBlechblaeser)]
    [InlineData("fluegelhorn", InstrumentTaxonomie.FamilieBlechblaeser)]
    [InlineData("horn", InstrumentTaxonomie.FamilieBlechblaeser)]
    [InlineData("tenorhorn", InstrumentTaxonomie.FamilieBlechblaeser)]
    [InlineData("posaune", InstrumentTaxonomie.FamilieBlechblaeser)]
    [InlineData("bassposaune", InstrumentTaxonomie.FamilieBlechblaeser)]
    [InlineData("euphonium", InstrumentTaxonomie.FamilieBlechblaeser)]
    [InlineData("tuba", InstrumentTaxonomie.FamilieBlechblaeser)]
    [InlineData("kontrabass_tuba", InstrumentTaxonomie.FamilieBlechblaeser)]
    [InlineData("kleine_trommel", InstrumentTaxonomie.FamilieSchlagwerk)]
    [InlineData("grosse_trommel", InstrumentTaxonomie.FamilieSchlagwerk)]
    [InlineData("schlagzeug", InstrumentTaxonomie.FamilieSchlagwerk)]
    [InlineData("pauken", InstrumentTaxonomie.FamilieSchlagwerk)]
    [InlineData("klavier", InstrumentTaxonomie.FamilieTasten)]
    [InlineData("orgel", InstrumentTaxonomie.FamilieTasten)]
    [InlineData("akkordeon", InstrumentTaxonomie.FamilieTasten)]
    [InlineData("harfe", InstrumentTaxonomie.FamilieTasten)]
    public void GetFamilie_KnownType_ReturnsCorrectFamily(string typ, string expectedFamilie)
    {
        Assert.Equal(expectedFamilie, InstrumentTaxonomie.GetFamilie(typ));
    }

    [Theory]
    [InlineData("gitarre")]
    [InlineData("dudelsack")]
    [InlineData("unbekannt")]
    [InlineData("")]
    public void GetFamilie_UnknownType_ReturnsSonstige(string typ)
    {
        Assert.Equal(InstrumentTaxonomie.FamilieSonstige, InstrumentTaxonomie.GetFamilie(typ));
    }

    // ── Bidirectional relatedness (same family) ────────────────────────────────

    [Theory]
    [InlineData("klarinette", "oboe")]         // both holzblaeser
    [InlineData("floete", "saxophon_alt")]      // both holzblaeser
    [InlineData("klarinette", "bassklarinette")] // both holzblaeser
    [InlineData("oboe", "fagott")]              // both holzblaeser
    [InlineData("trompete", "posaune")]         // both blechblaeser
    [InlineData("horn", "tuba")]                // both blechblaeser
    [InlineData("fluegelhorn", "euphonium")]    // both blechblaeser
    [InlineData("kleine_trommel", "schlagzeug")] // both schlagwerk
    [InlineData("klavier", "akkordeon")]        // both tasten
    public void RelatedInstruments_AreBidirectional_ShareSameFamily(string typA, string typB)
    {
        var familieA = InstrumentTaxonomie.GetFamilie(typA);
        var familieB = InstrumentTaxonomie.GetFamilie(typB);

        Assert.Equal(familieA, familieB);

        // Verify neither is sonstige (i.e., actual family membership confirmed)
        Assert.NotEqual(InstrumentTaxonomie.FamilieSonstige, familieA);
    }

    [Theory]
    [InlineData("klarinette", "trompete")]   // holzblaeser vs blechblaeser
    [InlineData("floete", "pauken")]         // holzblaeser vs schlagwerk
    [InlineData("tuba", "klavier")]          // blechblaeser vs tasten
    public void InstrumentsFromDifferentFamilies_HaveDifferentFamilien(string typA, string typB)
    {
        Assert.NotEqual(
            InstrumentTaxonomie.GetFamilie(typA),
            InstrumentTaxonomie.GetFamilie(typB));
    }

    // ── GetPrioritaet ─────────────────────────────────────────────────────────

    [Fact]
    public void GetPrioritaet_FloeteBeforeKlarinetteInHolzblaeser()
    {
        var floetePrio = InstrumentTaxonomie.GetPrioritaet("floete");
        var klarPrio = InstrumentTaxonomie.GetPrioritaet("klarinette");

        Assert.True(floetePrio < klarPrio, "Flöte should have higher priority (lower number) than Klarinette");
    }

    [Fact]
    public void GetPrioritaet_TrompeteBeforeTubaInBlechblaeser()
    {
        var trpPrio = InstrumentTaxonomie.GetPrioritaet("trompete");
        var tubaPrio = InstrumentTaxonomie.GetPrioritaet("tuba");

        Assert.True(trpPrio < tubaPrio, "Trompete should have higher priority than Tuba");
    }

    [Fact]
    public void GetPrioritaet_UnknownType_ReturnsMaxValue()
    {
        Assert.Equal(int.MaxValue, InstrumentTaxonomie.GetPrioritaet("unbekannt"));
        Assert.Equal(int.MaxValue, InstrumentTaxonomie.GetPrioritaet("gitarre"));
    }

    // ── IstBekannterTyp ───────────────────────────────────────────────────────

    [Theory]
    [InlineData("klarinette", true)]
    [InlineData("trompete", true)]
    [InlineData("schlagzeug", true)]
    [InlineData("klavier", true)]
    [InlineData("saxophon_alt", true)]
    [InlineData("kontrabass_tuba", true)]
    [InlineData("gitarre", false)]
    [InlineData("dudelsack", false)]
    [InlineData("", false)]
    public void IstBekannterTyp_ReturnsExpected(string typ, bool expected)
    {
        Assert.Equal(expected, InstrumentTaxonomie.IstBekannterTyp(typ));
    }

    // ── TypBezeichnung ────────────────────────────────────────────────────────

    [Fact]
    public void TypBezeichnung_AllKnownTypes_HaveDisplayName()
    {
        foreach (var typ in InstrumentTaxonomie.AlleTypen)
        {
            Assert.True(
                InstrumentTaxonomie.TypBezeichnung.ContainsKey(typ),
                $"Kein Anzeigename für Typ '{typ}'.");
        }
    }

    [Theory]
    [InlineData("klarinette", "Klarinette")]
    [InlineData("trompete", "Trompete")]
    [InlineData("floete", "Flöte")]
    [InlineData("saxophon_alt", "Altsaxophon")]
    [InlineData("kleine_trommel", "Kleine Trommel")]
    [InlineData("klavier", "Klavier")]
    public void TypBezeichnung_ReturnsCorrectDisplayName(string typ, string expectedName)
    {
        Assert.Equal(expectedName, InstrumentTaxonomie.TypBezeichnung[typ]);
    }

    // ── Abkuerzungen ──────────────────────────────────────────────────────────

    [Fact]
    public void Abkuerzungen_IsNotEmpty()
    {
        Assert.NotEmpty(InstrumentTaxonomie.Abkuerzungen);
    }

    [Theory]
    [InlineData("klar.", "klarinette")]
    [InlineData("klar", "klarinette")]
    [InlineData("trp.", "trompete")]
    [InlineData("trp", "trompete")]
    [InlineData("pos.", "posaune")]
    [InlineData("pos", "posaune")]
    [InlineData("fl.", "floete")]
    [InlineData("fl", "floete")]
    [InlineData("ob.", "oboe")]
    [InlineData("ob", "oboe")]
    [InlineData("euph.", "euphonium")]
    [InlineData("tb.", "tuba")]
    [InlineData("flgh.", "fluegelhorn")]
    [InlineData("th.", "tenorhorn")]
    public void Abkuerzungen_ContainsExpectedMappings(string kuerzel, string vollName)
    {
        Assert.True(InstrumentTaxonomie.Abkuerzungen.TryGetValue(kuerzel, out var result));
        Assert.Equal(vollName, result);
    }

    [Fact]
    public void AlleTypen_ContainsExpectedInstrumentsFromAllFamilies()
    {
        // Spot-check representative instruments from each family
        // Use IstBekannterTyp to avoid FrozenSet<T> overload ambiguity
        Assert.True(InstrumentTaxonomie.IstBekannterTyp("floete"));
        Assert.True(InstrumentTaxonomie.IstBekannterTyp("klarinette"));
        Assert.True(InstrumentTaxonomie.IstBekannterTyp("trompete"));
        Assert.True(InstrumentTaxonomie.IstBekannterTyp("posaune"));
        Assert.True(InstrumentTaxonomie.IstBekannterTyp("schlagzeug"));
        Assert.True(InstrumentTaxonomie.IstBekannterTyp("klavier"));
    }
}
