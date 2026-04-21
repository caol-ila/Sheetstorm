using FluentAssertions;
using Sheetstorm.PdfLabeling.Services;
using Xunit;

namespace Sheetstorm.PdfLabeling.Tests.Services;

public class FileNameSanitizerTests
{
    private readonly FileNameSanitizer _sut;

    public FileNameSanitizerTests()
    {
        _sut = new FileNameSanitizer();
    }

    [Fact]
    public void Sanitize_SimpleTitle_ReturnsUnchanged()
    {
        // Arrange
        var input = "Radetzky Marsch";

        // Act
        var result = _sut.Sanitize(input);

        // Assert
        result.Should().Be("Radetzky Marsch");
    }

    [Theory]
    [InlineData("<", "_")]
    [InlineData(">", "_")]
    [InlineData(":", "_")]
    [InlineData("\"", "_")]
    [InlineData("/", "_")]
    [InlineData("\\", "_")]
    [InlineData("|", "_")]
    [InlineData("?", "_")]
    [InlineData("*", "_")]
    [InlineData("Lied<>:test", "Lied___test")]
    public void Sanitize_TitleWithInvalidChars_ReplacesWithUnderscore(string input, string expected)
    {
        // Act
        var result = _sut.Sanitize(input);

        // Assert
        result.Should().Be(expected);
    }

    [Theory]
    [InlineData("Test\0File")]
    [InlineData("Test\tFile")]
    [InlineData("Test\nFile")]
    [InlineData("Test\rFile")]
    [InlineData("Test\0\t\n\rFile")]
    public void Sanitize_TitleWithControlChars_RemovesThem(string input)
    {
        // Act
        var result = _sut.Sanitize(input);

        // Assert
        result.Should().NotContain("\0");
        result.Should().NotContain("\t");
        result.Should().NotContain("\n");
        result.Should().NotContain("\r");
        result.Should().Contain("Test");
        result.Should().Contain("File");
    }

    [Fact]
    public void Sanitize_MultipleSpaces_CollapsesToSingle()
    {
        // Arrange
        var input = "Mein  Lied   hier";

        // Act
        var result = _sut.Sanitize(input);

        // Assert
        result.Should().Be("Mein Lied hier");
    }

    [Fact]
    public void Sanitize_LeadingTrailingWhitespace_Trimmed()
    {
        // Arrange
        var input = "  Hymne  ";

        // Act
        var result = _sut.Sanitize(input);

        // Assert
        result.Should().Be("Hymne");
    }

    [Fact]
    public void Sanitize_LongerThan150Chars_TruncatedTo150()
    {
        // Arrange
        var input = new string('A', 300);

        // Act
        var result = _sut.Sanitize(input);

        // Assert
        result.Should().HaveLength(150);
    }

    [Theory]
    [InlineData("CON")]
    [InlineData("PRN")]
    [InlineData("AUX")]
    [InlineData("NUL")]
    [InlineData("COM1")]
    [InlineData("COM2")]
    [InlineData("COM3")]
    [InlineData("COM4")]
    [InlineData("COM5")]
    [InlineData("COM6")]
    [InlineData("COM7")]
    [InlineData("COM8")]
    [InlineData("COM9")]
    [InlineData("LPT1")]
    [InlineData("LPT2")]
    [InlineData("LPT3")]
    [InlineData("LPT4")]
    [InlineData("LPT5")]
    [InlineData("LPT6")]
    [InlineData("LPT7")]
    [InlineData("LPT8")]
    [InlineData("LPT9")]
    public void Sanitize_ReservedWindowsName_Prefixed(string reservedName)
    {
        // Act
        var result = _sut.Sanitize(reservedName);

        // Assert
        result.Should().NotBe(reservedName, "reserved Windows names must be prefixed or modified");
        result.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public void Sanitize_EmptyInput_ReturnsFallback()
    {
        // Arrange
        var input = "";

        // Act
        var result = _sut.Sanitize(input);

        // Assert
        result.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public void Sanitize_WhitespaceOnly_ReturnsFallback()
    {
        // Arrange
        var input = "   \t\n";

        // Act
        var result = _sut.Sanitize(input);

        // Assert
        result.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public void Sanitize_NullInput_ReturnsFallback()
    {
        // Arrange
        string? input = null;

        // Act
        var result = _sut.Sanitize(input!);

        // Assert
        result.Should().NotBeNullOrWhiteSpace();
    }

    [Theory]
    [InlineData("Lied...")]
    [InlineData("Lied. . .")]
    [InlineData("Lied   ")]
    [InlineData("Lied. ")]
    public void Sanitize_DotsAndSpacesAtEnd_Trimmed(string input)
    {
        // Act
        var result = _sut.Sanitize(input);

        // Assert
        result.Should().NotEndWith(".");
        result.Should().NotEndWith(" ");
        result.Should().StartWith("Lied");
    }
}
