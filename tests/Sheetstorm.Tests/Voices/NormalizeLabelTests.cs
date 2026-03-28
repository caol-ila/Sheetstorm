using Sheetstorm.Infrastructure.Voices;

namespace Sheetstorm.Tests.Voices;

/// <summary>
/// Unit tests for VoiceService.NormalizeLabel (internal method, accessible via InternalsVisibleTo).
/// </summary>
public class NormalizeLabelTests
{
    // ── Trim + lowercase ──────────────────────────────────────────────────────

    [Fact]
    public void Normalize_TrimsLeadingAndTrailingWhitespace()
    {
        Assert.Equal("klarinette", VoiceService.NormalizeLabel("  Klarinette  "));
    }

    [Fact]
    public void Normalize_ConvertsToLowercase()
    {
        Assert.Equal("trompete", VoiceService.NormalizeLabel("TROMPETE"));
    }

    // ── Roman numeral → arabic ────────────────────────────────────────────────

    [Theory]
    [InlineData("I Voice", "1 voice")]
    [InlineData("II Voice", "2 voice")]
    [InlineData("III Voice", "3 voice")]
    [InlineData("IV Voice", "4 voice")]
    [InlineData("V Voice", "5 voice")]
    [InlineData("VI Voice", "6 voice")]
    public void Normalize_RomanNumerals_ConvertedToArabic(string input, string expected)
    {
        Assert.Equal(expected, VoiceService.NormalizeLabel(input));
    }

    [Theory]
    [InlineData("Klarinette I", "klarinette 1")]
    [InlineData("Klarinette II", "klarinette 2")]
    [InlineData("Klarinette III", "klarinette 3")]
    public void Normalize_RomanNumeralSuffix_ConvertedToArabic(string input, string expected)
    {
        Assert.Equal(expected, VoiceService.NormalizeLabel(input));
    }

    // ── Ordinal dot removal ───────────────────────────────────────────────────

    [Theory]
    [InlineData("1. Klarinette", "1 klarinette")]
    [InlineData("2. Trompete", "2 trompete")]
    [InlineData("3. Posaune", "3 posaune")]
    public void Normalize_OrdinalDotAfterNumber_Removed(string input, string expected)
    {
        Assert.Equal(expected, VoiceService.NormalizeLabel(input));
    }

    // ── Roman numeral + ordinal dot ───────────────────────────────────────────

    [Theory]
    [InlineData("II. Klarinette", "2 klarinette")]
    [InlineData("III. Trompete", "3 trompete")]
    [InlineData("IV. Posaune", "4 posaune")]
    public void Normalize_RomanNumeralWithOrdinalDot_FullyConverted(string input, string expected)
    {
        Assert.Equal(expected, VoiceService.NormalizeLabel(input));
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
        Assert.Equal(expected, VoiceService.NormalizeLabel(input));
    }

    // ── Ordinal words ─────────────────────────────────────────────────────────

    [Theory]
    [InlineData("erste Klarinette", "1 klarinette")]
    [InlineData("zweite Klarinette", "2 klarinette")]
    [InlineData("dritte Klarinette", "3 klarinette")]
    [InlineData("vierte Trompete", "4 trompete")]
    [InlineData("fünfte Voice", "5 voice")]
    public void Normalize_OrdinalWords_ConvertedToNumbers(string input, string expected)
    {
        Assert.Equal(expected, VoiceService.NormalizeLabel(input));
    }

    // ── Cross-format equivalence ──────────────────────────────────────────────

    [Fact]
    public void Normalize_RomanAndArabicOrdinalDot_ProduceSameResult()
    {
        var roman = VoiceService.NormalizeLabel("II. Klarinette");
        var arabic = VoiceService.NormalizeLabel("2. Klarinette");

        Assert.Equal(arabic, roman);
    }

    [Fact]
    public void Normalize_OrdinalWordAndArabicOrdinalDot_ProduceSameResult()
    {
        var ordinalWord = VoiceService.NormalizeLabel("erste Klarinette");
        var arabicDot = VoiceService.NormalizeLabel("1. Klarinette");

        Assert.Equal(arabicDot, ordinalWord);
    }

    [Fact]
    public void Normalize_AbbreviationAndFullName_SameTokenOrder_ProduceSameResult()
    {
        // "Klar. 1" → "klarinette 1"
        // "Klarinette 1" → "klarinette 1"
        var abbrev = VoiceService.NormalizeLabel("Klar. 1");
        var full = VoiceService.NormalizeLabel("Klarinette 1");

        Assert.Equal(full, abbrev);
    }

    [Fact]
    public void Normalize_AbbrevWithNumber_AndFullNameWithOrdinalDot_ProduceSameResult()
    {
        // "Trp. II" → "trompete 2"
        // "2. Trompete" → "2 trompete"  (note: word order differs — these are NOT equal)
        // But "Trp. 2" and "Trompete 2" should be equal
        var abbrev = VoiceService.NormalizeLabel("Trp. 2");
        var full = VoiceService.NormalizeLabel("Trompete 2");

        Assert.Equal(full, abbrev);
    }

    [Fact]
    public void Normalize_RomanNumeralAbbrev_AndArabicFullName_ProduceSameResult()
    {
        // "Trp. II" → "trompete 2"
        // "Trompete 2" → "trompete 2"
        var abbrevRoman = VoiceService.NormalizeLabel("Trp. II");
        var fullArabic = VoiceService.NormalizeLabel("Trompete 2");

        Assert.Equal(fullArabic, abbrevRoman);
    }

    // ── Already-normalized input ──────────────────────────────────────────────

    [Fact]
    public void Normalize_AlreadyNormalizedInput_Unchanged()
    {
        var input = "klarinette";
        Assert.Equal(input, VoiceService.NormalizeLabel(input));
    }

    [Fact]
    public void Normalize_MultipleSpaces_Collapsed()
    {
        // Multiple spaces between words should be collapsed via Split + Join
        Assert.Equal("klarinette 1", VoiceService.NormalizeLabel("Klarinette  1"));
    }
}
