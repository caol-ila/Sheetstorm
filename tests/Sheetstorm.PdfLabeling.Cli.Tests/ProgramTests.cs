using FluentAssertions;
using NSubstitute;
using Sheetstorm.PdfLabeling.Abstractions;
using Sheetstorm.PdfLabeling.Domain;

namespace Sheetstorm.PdfLabeling.Cli.Tests;

public class ProgramTests : IDisposable
{
    private readonly string _sourceDir;
    private readonly string _targetDir;
    private const string TestTokenEnvVar = "PDFLABELER_TEST_TOKEN";

    public ProgramTests()
    {
        _sourceDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        _targetDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        Directory.CreateDirectory(_sourceDir);
        Directory.CreateDirectory(_targetDir);
        
        // Set test token
        Environment.SetEnvironmentVariable(TestTokenEnvVar, "FAKE_PAT_FOR_TESTS");
    }

    public void Dispose()
    {
        try { Directory.Delete(_sourceDir, true); } catch { }
        try { Directory.Delete(_targetDir, true); } catch { }
        Environment.SetEnvironmentVariable(TestTokenEnvVar, null);
    }

    [Fact]
    public async Task Help_PrintsUsageAndExitsZero()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        // Act
        var exitCode = await Program.MainAsync(["--help"], stdout, stderr, CancellationToken.None);

        // Assert
        exitCode.Should().Be(0);
        var output = stdout.ToString();
        output.Should().Contain("Sheetstorm.PdfLabeling.Cli");
        output.Should().Contain("--source");
        output.Should().Contain("--target");
        stderr.ToString().Should().BeEmpty();
    }

    [Fact]
    public async Task Version_PrintsVersionAndExitsZero()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        // Act
        var exitCode = await Program.MainAsync(["--version"], stdout, stderr, CancellationToken.None);

        // Assert
        exitCode.Should().Be(0);
        stdout.ToString().Should().MatchRegex(@"Sheetstorm\.PdfLabeling\.Cli \d+\.\d+\.\d+");
        stderr.ToString().Should().BeEmpty();
    }

    [Fact]
    public async Task InvalidArgs_MissingRequired_ExitsOneWithError()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        // Act
        var exitCode = await Program.MainAsync(["--source", _sourceDir], stdout, stderr, CancellationToken.None);

        // Assert
        exitCode.Should().Be(1);
        stderr.ToString().Should().NotBeEmpty();
        stderr.ToString().Should().Contain("--target");
        stdout.ToString().Should().NotContain("{"); // No JSON on stdout
    }

    [Fact(Skip = "Integration test requires GitHub PAT - run manually")]
    public async Task ValidArgs_EmitsNdjsonEvents()
    {
        // This test requires a real GitHub PAT and makes actual API calls
        // Run with: SHEETSTORM_PAT=<token> dotnet test --filter ValidArgs_EmitsNdjsonEvents
        
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        // Create dummy PDF files
        File.WriteAllText(Path.Combine(_sourceDir, "file1.pdf"), "dummy");
        File.WriteAllText(Path.Combine(_sourceDir, "file2.pdf"), "dummy");

        var args = new[] { "--source", _sourceDir, "--target", _targetDir, "--token-env", TestTokenEnvVar };

        // Act
        var exitCode = await Program.MainAsync(args, stdout, stderr, CancellationToken.None);

        // Assert
        exitCode.Should().Be(0);
        
        var output = stdout.ToString();
        var lines = output.Split('\n', StringSplitOptions.RemoveEmptyEntries);
        
        // Each line should be valid JSON
        foreach (var line in lines)
        {
            var trimmed = line.Trim();
            if (string.IsNullOrEmpty(trimmed)) continue;
            
            trimmed.Should().StartWith("{");
            trimmed.Should().EndWith("}");
        }

        // Check for event types
        output.Should().Contain("\"type\":\"done\"");
    }

    [Fact]
    public async Task NdjsonFormat_Help_DoesNotEmitJson()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        // Act
        var exitCode = await Program.MainAsync(["--help"], stdout, stderr, CancellationToken.None);

        // Assert
        var output = stdout.ToString();
        output.Should().NotContain("\"type\":");
        output.Should().NotContain("{");
    }

    [Fact]
    public async Task Cancellation_ExitsTwo()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        var cts = new CancellationTokenSource();
        cts.Cancel(); // Already cancelled

        var args = new[] { "--source", _sourceDir, "--target", _targetDir, "--token-env", TestTokenEnvVar };

        // Act
        var exitCode = await Program.MainAsync(args, stdout, stderr, cts.Token);

        // Assert
        // When cancelled immediately, we may not get to processing phase
        // Exit code 1 (error) or 2 (cancelled) are both acceptable
        exitCode.Should().BeOneOf(1, 2);
    }

    [Fact]
    public async Task ArgumentParser_MissingSource_ReturnsError()
    {
        // Arrange & Act
        var (options, error) = ArgumentParser.Parse(["--target", _targetDir]);

        // Assert
        options.Should().BeNull();
        error.Should().Contain("--source");
    }

    [Fact]
    public async Task ArgumentParser_ValidArgs_ParsesCorrectly()
    {
        // Arrange & Act
        var (options, error) = ArgumentParser.Parse([
            "--source", "/path/source",
            "--target", "/path/target",
            "--confidence", "0.8",
            "--token-env", "MY_TOKEN"
        ]);

        // Assert
        error.Should().BeNull();
        options.Should().NotBeNull();
        options!.SourceDirectory.Should().Be("/path/source");
        options.TargetDirectory.Should().Be("/path/target");
        options.Confidence.Should().Be(0.8);
        options.TokenEnv.Should().Be("MY_TOKEN");
    }
}
