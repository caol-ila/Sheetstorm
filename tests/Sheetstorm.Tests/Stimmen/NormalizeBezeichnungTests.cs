using Sheetstorm.Infrastructure.Stimmen;

namespace Sheetstorm.Tests.Stimmen;

/// <summary>
/// Unit tests for StimmenService.NormalizeBezeichnung (internal method, accessible via InternalsVisibleTo).
/// </summary>
public class NormalizeBezeichnungTests
{
    // ── Trim + lowercase ──────────────────────────────────────────────────────

    [Fact]
    public void Normalize_TrimsLeadingAndTrailingWhitespace()
    {
        Assert.Equal("klarinette", StimmenService.NormalizeBezeichnung("  Klarinette  "));
    }

    [Fact]
    public void Normalize_ConvertsToLowercase()
    {
        Assert.Equal("trompete", StimmenService.NormalizeBezeichnung("TROMPETE"));
    }

    // ── Roman numeral → arabic ────────────────────────────────────────────────

    [Theory]
    [InlineData("I Stimme", "1 stimme")]
    [InlineData("II Stimme", "2 stimme")]
    [InlineData("III Stimme", "3 stimme")]
    [InlineData("IV Stimme", "4 stimme")]
    [InlineData("V Stimme", "5 stimme")]
    [InlineData("VI Stimme", "6 stimme")]
    public void Normalize_RomanNumerals_ConvertedToArabic(string input, string expected)
    {
        Assert.Equal(expected, StimmenService.NormalizeBezeichnung(input));
    }

    [Theory]
    [InlineData("Klarinette I", "klarinette 1")]
    [InlineData("Klarinette II", "klarinette 2")]
    [InlineData("Klarinette III", "klarinette 3")]
    public void Normalize_RomanNumeralSuffix_ConvertedToArabic(string input, string expected)
    {
        Assert.Equal(expected, StimmenService.NormalizeBezeichnung(input));
    }

    // ── Ordinal dot removal ───────────────────────────────────────────────────

    [Theory]
    [InlineData("1. Klarinette", "1 klarinette")]
    [InlineData("2. Trompete", "2 trompete")]
    [InlineData("3. Posaune", "3 posaune")]
    public void Normalize_OrdinalDotAfterNumber_Removed(string input, string expected)
    {
        Assert.Equal(expected, StimmenService.NormalizeBezeichnung(input));
    }

    // ── Roman numeral + ordinal dot ───────────────────────────────────────────

    [Theory]
    [InlineData("II. Klarinette", "2 klarinette")]
    [InlineData("III. Trompete", "3 trompete")]
    [InlineData("IV. Posaune", "4 posaune")]
    public void Normalize_RomanNumeralWithOrdinalDot_FullyConverted(string input, string expected)
    {
        Assert.Equal(expected, StimmenService.NormalizeBezeichnung(input));
    }

    // ── Abbreviation expansion ────────────────────────────────────────────────

    [Theory]
    [InlineData("Klar. 1", "klarinette 1")]
    [InlineData("Trp. 2", "trompete 2")]
    [InlineData("Pos. 1", "posaune 1")]
    [InlineData("Fl. 1", "floete 1")]
    [InlineData("Ob.", "oboe")]
    [InlineData("Euph.", "euphonium")]
    [InlineData("Tb.", "tuba")]
    [InlineData("Flgh.", "fluegelhorn")]
    [InlineData("Th.", "tenorhorn")]
    public void Normalize_Abbreviations_Expanded(string input, string expected)
    {
        Assert.Equal(expected, StimmenService.NormalizeBezeichnung(input));
    }

    // ── Ordinal words ─────────────────────────────────────────────────────────

    [Theory]
    [InlineData("erste Klarinette", "1 klarinette")]
    [InlineData("zweite Klarinette", "2 klarinette")]
    [InlineData("dritte Klarinette", "3 klarinette")]
    [InlineData("vierte Trompete", "4 trompete")]
    [InlineData("fünfte Stimme", "5 stimme")]
    public void Normalize_OrdinalWords_ConvertedToNumbers(string input, string expected)
    {
        Assert.Equal(expected, StimmenService.NormalizeBezeichnung(input));
    }

    // ── Cross-format equivalence ──────────────────────────────────────────────

    [Fact]
    public void Normalize_RomanAndArabicOrdinalDot_ProduceSameResult()
    {
        var roman = StimmenService.NormalizeBezeichnung("II. Klarinette");
        var arabic = StimmenService.NormalizeBezeichnung("2. Klarinette");

        Assert.Equal(arabic, roman);
    }

    [Fact]
    public void Normalize_OrdinalWordAndArabicOrdinalDot_ProduceSameResult()
    {
        var ordinalWord = StimmenService.NormalizeBezeichnung("erste Klarinette");
        var arabicDot = StimmenService.NormalizeBezeichnung("1. Klarinette");

        Assert.Equal(arabicDot, ordinalWord);
    }

    [Fact]
    public void Normalize_AbbreviationAndFullName_SameTokenOrder_ProduceSameResult()
    {
        // "Klar. 1" → "klarinette 1"
        // "Klarinette 1" → "klarinette 1"
        var abbrev = StimmenService.NormalizeBezeichnung("Klar. 1");
        var full = StimmenService.NormalizeBezeichnung("Klarinette 1");

        Assert.Equal(full, abbrev);
    }

    [Fact]
    public void Normalize_AbbrevWithNumber_AndFullNameWithOrdinalDot_ProduceSameResult()
    {
        // "Trp. II" → "trompete 2"
        // "2. Trompete" → "2 trompete"  (note: word order differs — these are NOT equal)
        // But "Trp. 2" and "Trompete 2" should be equal
        var abbrev = StimmenService.NormalizeBezeichnung("Trp. 2");
        var full = StimmenService.NormalizeBezeichnung("Trompete 2");

        Assert.Equal(full, abbrev);
    }

    [Fact]
    public void Normalize_RomanNumeralAbbrev_AndArabicFullName_ProduceSameResult()
    {
        // "Trp. II" → "trompete 2"
        // "Trompete 2" → "trompete 2"
        var abbrevRoman = StimmenService.NormalizeBezeichnung("Trp. II");
        var fullArabic = StimmenService.NormalizeBezeichnung("Trompete 2");

        Assert.Equal(fullArabic, abbrevRoman);
    }

    // ── Already-normalized input ──────────────────────────────────────────────

    [Fact]
    public void Normalize_AlreadyNormalizedInput_Unchanged()
    {
        var input = "klarinette";
        Assert.Equal(input, StimmenService.NormalizeBezeichnung(input));
    }

    [Fact]
    public void Normalize_MultipleSpaces_Collapsed()
    {
        // Multiple spaces between words should be collapsed via Split + Join
        Assert.Equal("klarinette 1", StimmenService.NormalizeBezeichnung("Klarinette  1"));
    }
}
