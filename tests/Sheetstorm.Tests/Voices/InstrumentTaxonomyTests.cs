using Sheetstorm.Domain.Voices;

namespace Sheetstorm.Tests.Voices;

public class InstrumentTaxonomyTests
{
    // ── All families have instruments ─────────────────────────────────────────

    [Fact]
    public void AllFamilies_EachHasAtLeastOneInstrument()
    {
        foreach (var familie in InstrumentTaxonomy.AllFamilies)
        {
            var count = InstrumentTaxonomy.TypeToFamily.Values.Count(v => v.Family == familie);
            Assert.True(count > 0, $"Familie '{familie}' hat keine Instruments.");
        }
    }

    [Fact]
    public void AllFamilies_ContainsAllFourExpectedFamilies()
    {
        Assert.Contains(InstrumentTaxonomy.FamilyWoodwind, InstrumentTaxonomy.AllFamilies);
        Assert.Contains(InstrumentTaxonomy.FamilyBrass, InstrumentTaxonomy.AllFamilies);
        Assert.Contains(InstrumentTaxonomy.FamilyPercussion, InstrumentTaxonomy.AllFamilies);
        Assert.Contains(InstrumentTaxonomy.FamilyKeyboard, InstrumentTaxonomy.AllFamilies);
    }

    // ── GetFamily ────────────────────────────────────────────────────────────

    [Theory]
    [InlineData("floete", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("piccolo", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("oboe", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("klarinette", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("bassklarinette", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("fagott", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("saxophon_sopran", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("saxophon_alt", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("saxophon_tenor", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("saxophon_bariton", InstrumentTaxonomy.FamilyWoodwind)]
    [InlineData("trompete", InstrumentTaxonomy.FamilyBrass)]
    [InlineData("fluegelhorn", InstrumentTaxonomy.FamilyBrass)]
    [InlineData("horn", InstrumentTaxonomy.FamilyBrass)]
    [InlineData("tenorhorn", InstrumentTaxonomy.FamilyBrass)]
    [InlineData("posaune", InstrumentTaxonomy.FamilyBrass)]
    [InlineData("bassposaune", InstrumentTaxonomy.FamilyBrass)]
    [InlineData("euphonium", InstrumentTaxonomy.FamilyBrass)]
    [InlineData("tuba", InstrumentTaxonomy.FamilyBrass)]
    [InlineData("kontrabass_tuba", InstrumentTaxonomy.FamilyBrass)]
    [InlineData("kleine_trommel", InstrumentTaxonomy.FamilyPercussion)]
    [InlineData("grosse_trommel", InstrumentTaxonomy.FamilyPercussion)]
    [InlineData("schlagzeug", InstrumentTaxonomy.FamilyPercussion)]
    [InlineData("pauken", InstrumentTaxonomy.FamilyPercussion)]
    [InlineData("klavier", InstrumentTaxonomy.FamilyKeyboard)]
    [InlineData("orgel", InstrumentTaxonomy.FamilyKeyboard)]
    [InlineData("akkordeon", InstrumentTaxonomy.FamilyKeyboard)]
    [InlineData("harfe", InstrumentTaxonomy.FamilyKeyboard)]
    public void GetFamily_KnownType_ReturnsCorrectFamily(string typ, string expectedFamilie)
    {
        Assert.Equal(expectedFamilie, InstrumentTaxonomy.GetFamily(typ));
    }

    [Theory]
    [InlineData("gitarre")]
    [InlineData("dudelsack")]
    [InlineData("unbekannt")]
    [InlineData("")]
    public void GetFamily_UnknownType_ReturnsSonstige(string typ)
    {
        Assert.Equal(InstrumentTaxonomy.FamilyOther, InstrumentTaxonomy.GetFamily(typ));
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
        var familieA = InstrumentTaxonomy.GetFamily(typA);
        var familieB = InstrumentTaxonomy.GetFamily(typB);

        Assert.Equal(familieA, familieB);

        // Verify neither is sonstige (i.e., actual family membership confirmed)
        Assert.NotEqual(InstrumentTaxonomy.FamilyOther, familieA);
    }

    [Theory]
    [InlineData("klarinette", "trompete")]   // holzblaeser vs blechblaeser
    [InlineData("floete", "pauken")]         // holzblaeser vs schlagwerk
    [InlineData("tuba", "klavier")]          // blechblaeser vs tasten
    public void InstrumentsFromDifferentFamilies_HaveDifferentFamilien(string typA, string typB)
    {
        Assert.NotEqual(
            InstrumentTaxonomy.GetFamily(typA),
            InstrumentTaxonomy.GetFamily(typB));
    }

    // ── GetPriority ─────────────────────────────────────────────────────────

    [Fact]
    public void GetPriority_FloeteBeforeKlarinetteInHolzblaeser()
    {
        var floetePrio = InstrumentTaxonomy.GetPriority("floete");
        var klarPrio = InstrumentTaxonomy.GetPriority("klarinette");

        Assert.True(floetePrio < klarPrio, "Flöte should have higher priority (lower number) than Klarinette");
    }

    [Fact]
    public void GetPriority_TrompeteBeforeTubaInBlechblaeser()
    {
        var trpPrio = InstrumentTaxonomy.GetPriority("trompete");
        var tubaPrio = InstrumentTaxonomy.GetPriority("tuba");

        Assert.True(trpPrio < tubaPrio, "Trompete should have higher priority than Tuba");
    }

    [Fact]
    public void GetPriority_UnknownType_ReturnsMaxValue()
    {
        Assert.Equal(int.MaxValue, InstrumentTaxonomy.GetPriority("unbekannt"));
        Assert.Equal(int.MaxValue, InstrumentTaxonomy.GetPriority("gitarre"));
    }

    // ── IsKnownType ───────────────────────────────────────────────────────

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
    public void IsKnownType_ReturnsExpected(string typ, bool expected)
    {
        Assert.Equal(expected, InstrumentTaxonomy.IsKnownType(typ));
    }

    // ── TypeLabel ────────────────────────────────────────────────────────

    [Fact]
    public void TypeLabel_AllKnownTypes_HaveDisplayName()
    {
        foreach (var typ in InstrumentTaxonomy.AllTypes)
        {
            Assert.True(
                InstrumentTaxonomy.TypeLabel.ContainsKey(typ),
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
    public void TypeLabel_ReturnsCorrectDisplayName(string typ, string expectedName)
    {
        Assert.Equal(expectedName, InstrumentTaxonomy.TypeLabel[typ]);
    }

    // ── Abbreviations ──────────────────────────────────────────────────────────

    [Fact]
    public void Abbreviations_IsNotEmpty()
    {
        Assert.NotEmpty(InstrumentTaxonomy.Abbreviations);
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
    public void Abbreviations_ContainsExpectedMappings(string kuerzel, string vollName)
    {
        Assert.True(InstrumentTaxonomy.Abbreviations.TryGetValue(kuerzel, out var result));
        Assert.Equal(vollName, result);
    }

    [Fact]
    public void AllTypes_ContainsExpectedInstrumentsFromAllFamilies()
    {
        // Spot-check representative instruments from each family
        // Use IsKnownType to avoid FrozenSet<T> overload ambiguity
        Assert.True(InstrumentTaxonomy.IsKnownType("floete"));
        Assert.True(InstrumentTaxonomy.IsKnownType("klarinette"));
        Assert.True(InstrumentTaxonomy.IsKnownType("trompete"));
        Assert.True(InstrumentTaxonomy.IsKnownType("posaune"));
        Assert.True(InstrumentTaxonomy.IsKnownType("schlagzeug"));
        Assert.True(InstrumentTaxonomy.IsKnownType("klavier"));
    }
}
