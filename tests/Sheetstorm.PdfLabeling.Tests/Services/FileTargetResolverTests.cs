using FluentAssertions;
using Sheetstorm.PdfLabeling.Services;
using Xunit;

namespace Sheetstorm.PdfLabeling.Tests.Services;

public class FileTargetResolverTests : IDisposable
{
    private readonly string _testDirectory;
    private readonly FileTargetResolver _sut;

    public FileTargetResolverTests()
    {
        _testDirectory = Path.Combine(Path.GetTempPath(), $"PdfLabelingTests_{Guid.NewGuid():N}");
        Directory.CreateDirectory(_testDirectory);
        _sut = new FileTargetResolver();
    }

    public void Dispose()
    {
        if (Directory.Exists(_testDirectory))
        {
            Directory.Delete(_testDirectory, recursive: true);
        }
    }

    [Fact]
    public void Resolve_EmptyDirectory_ReturnsRequestedName()
    {
        // Arrange
        var fileName = "Hymne";
        var extension = "pdf";

        // Act
        var result = _sut.Resolve(_testDirectory, fileName, extension);

        // Assert
        var expectedPath = Path.Combine(_testDirectory, "Hymne.pdf");
        result.Should().Be(expectedPath);
    }

    [Fact]
    public void Resolve_FileExists_AppendsSuffix2()
    {
        // Arrange
        var existingFile = Path.Combine(_testDirectory, "Hymne.pdf");
        File.WriteAllText(existingFile, "dummy content");

        // Act
        var result = _sut.Resolve(_testDirectory, "Hymne", "pdf");

        // Assert
        var expectedPath = Path.Combine(_testDirectory, "Hymne (2).pdf");
        result.Should().Be(expectedPath);
    }

    [Fact]
    public void Resolve_FilesExist_AppendsNextFreeSuffix()
    {
        // Arrange
        File.WriteAllText(Path.Combine(_testDirectory, "Hymne.pdf"), "dummy");
        File.WriteAllText(Path.Combine(_testDirectory, "Hymne (2).pdf"), "dummy");

        // Act
        var result = _sut.Resolve(_testDirectory, "Hymne", "pdf");

        // Assert
        var expectedPath = Path.Combine(_testDirectory, "Hymne (3).pdf");
        result.Should().Be(expectedPath);
    }

    [Fact]
    public void Resolve_FilesExistWithGaps_AppendsFirstFree()
    {
        // Arrange
        File.WriteAllText(Path.Combine(_testDirectory, "Hymne.pdf"), "dummy");
        File.WriteAllText(Path.Combine(_testDirectory, "Hymne (3).pdf"), "dummy");
        // Gap at (2)

        // Act
        var result = _sut.Resolve(_testDirectory, "Hymne", "pdf");

        // Assert
        var expectedPath = Path.Combine(_testDirectory, "Hymne (2).pdf");
        result.Should().Be(expectedPath);
    }

    [Fact]
    public void Resolve_PreservesExtensionCasing()
    {
        // Arrange
        var fileName = "Hymne";
        var extension = "PDF";

        // Act
        var result = _sut.Resolve(_testDirectory, fileName, extension);

        // Assert
        result.Should().EndWith(".PDF");
    }

    [Fact]
    public void Resolve_CaseInsensitive_OnWindows()
    {
        // This test only makes sense on Windows
        if (!OperatingSystem.IsWindows())
        {
            return; // Skip on non-Windows
        }

        // Arrange
        var existingFile = Path.Combine(_testDirectory, "hymne.pdf");
        File.WriteAllText(existingFile, "dummy content");

        // Act - request with different casing
        var result = _sut.Resolve(_testDirectory, "Hymne", "pdf");

        // Assert - should detect collision and append suffix
        var expectedPath = Path.Combine(_testDirectory, "Hymne (2).pdf");
        result.Should().Be(expectedPath);
    }

    [Fact]
    public void Resolve_TargetDirectoryMissing_Throws()
    {
        // Arrange
        var nonExistentDir = Path.Combine(_testDirectory, "nonexistent");

        // Act
        var act = () => _sut.Resolve(nonExistentDir, "Hymne", "pdf");

        // Assert
        act.Should().Throw<DirectoryNotFoundException>();
    }

    [Fact]
    public void Resolve_ExtensionWithoutDot_StillWorks()
    {
        // Arrange
        var fileName = "Hymne";
        var extension = "pdf"; // without dot

        // Act
        var result = _sut.Resolve(_testDirectory, fileName, extension);

        // Assert
        result.Should().EndWith(".pdf");
        result.Should().Contain("Hymne");
    }
}
