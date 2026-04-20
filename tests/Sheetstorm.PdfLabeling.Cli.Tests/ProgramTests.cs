using FluentAssertions;
using NSubstitute;
using Sheetstorm.PdfLabeling.Abstractions;
using Sheetstorm.PdfLabeling.Domain;

namespace Sheetstorm.PdfLabeling.Cli.Tests;

public class ProgramTests
{
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
        output.Should().Contain("pdflabeler");
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
        stdout.ToString().Should().MatchRegex(@"pdflabeler \d+\.\d+\.\d+");
        stderr.ToString().Should().BeEmpty();
    }

    [Fact]
    public async Task InvalidArgs_MissingRequired_ExitsOneWithError()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        // Act
        var exitCode = await Program.MainAsync(["--source", "C:\\temp"], stdout, stderr, CancellationToken.None);

        // Assert
        exitCode.Should().Be(1);
        stderr.ToString().Should().NotBeEmpty();
        stderr.ToString().Should().Contain("--target");
        stdout.ToString().Should().NotContain("{"); // No JSON on stdout
    }

    [Fact]
    public async Task ValidArgs_WithFakeOrchestrator_EmitsNdjsonEvents()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        
        var sourceDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        var targetDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        Directory.CreateDirectory(sourceDir);
        Directory.CreateDirectory(targetDir);

        try
        {
            // Create two dummy PDF files
            File.WriteAllText(Path.Combine(sourceDir, "file1.pdf"), "dummy");
            File.WriteAllText(Path.Combine(sourceDir, "file2.pdf"), "dummy");

            // TODO: Inject fake orchestrator that emits 2 files
            // For now this test will fail - RED state

            var args = new[] { "--source", sourceDir, "--target", targetDir };

            // Act
            var exitCode = await Program.MainAsync(args, stdout, stderr, CancellationToken.None);

            // Assert
            exitCode.Should().Be(0);
            
            var output = stdout.ToString();
            var lines = output.Split('\n', StringSplitOptions.RemoveEmptyEntries);
            
            // Should have: 2× progress, 2× result, 1× done = 5 lines minimum
            lines.Length.Should().BeGreaterThanOrEqualTo(5);
            
            // Each line should be valid JSON
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (string.IsNullOrEmpty(trimmed)) continue;
                
                trimmed.Should().StartWith("{");
                trimmed.Should().EndWith("}");
            }

            // Check for event types
            output.Should().Contain("\"type\":\"progress\"");
            output.Should().Contain("\"type\":\"result\"");
            output.Should().Contain("\"type\":\"done\"");
        }
        finally
        {
            Directory.Delete(sourceDir, true);
            Directory.Delete(targetDir, true);
        }
    }

    [Fact]
    public async Task OrchestratorError_EmitsErrorEvent()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        
        var sourceDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        var targetDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        Directory.CreateDirectory(sourceDir);
        Directory.CreateDirectory(targetDir);

        try
        {
            File.WriteAllText(Path.Combine(sourceDir, "broken.pdf"), "dummy");

            // TODO: Inject orchestrator that returns Failed status
            var args = new[] { "--source", sourceDir, "--target", targetDir };

            // Act
            var exitCode = await Program.MainAsync(args, stdout, stderr, CancellationToken.None);

            // Assert
            exitCode.Should().Be(0); // Errors are per-file, not fatal
            var output = stdout.ToString();
            output.Should().Contain("\"type\":\"error\"");
            output.Should().Contain("\"file\":\"broken.pdf\"");
        }
        finally
        {
            Directory.Delete(sourceDir, true);
            Directory.Delete(targetDir, true);
        }
    }

    [Fact]
    public async Task Cancellation_ExitsTwoAndEmitsPartialResults()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        
        var sourceDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        var targetDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        Directory.CreateDirectory(sourceDir);
        Directory.CreateDirectory(targetDir);

        var cts = new CancellationTokenSource();
        cts.CancelAfter(TimeSpan.FromMilliseconds(100)); // Cancel quickly

        try
        {
            for (int i = 0; i < 10; i++)
            {
                File.WriteAllText(Path.Combine(sourceDir, $"file{i}.pdf"), "dummy");
            }

            var args = new[] { "--source", sourceDir, "--target", targetDir };

            // Act
            var exitCode = await Program.MainAsync(args, stdout, stderr, cts.Token);

            // Assert
            exitCode.Should().Be(2); // Cancelled exit code
            
            var output = stdout.ToString();
            // Should have at least partial output - done event should reflect cancellation
            output.Should().Contain("\"type\":\"done\"");
        }
        finally
        {
            Directory.Delete(sourceDir, true);
            Directory.Delete(targetDir, true);
        }
    }

    [Fact]
    public async Task NdjsonFormat_EachLineIsValidJson()
    {
        // Arrange
        var stdout = new StringWriter();
        var stderr = new StringWriter();
        
        var sourceDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        var targetDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        Directory.CreateDirectory(sourceDir);
        Directory.CreateDirectory(targetDir);

        try
        {
            File.WriteAllText(Path.Combine(sourceDir, "test.pdf"), "dummy");

            var args = new[] { "--source", sourceDir, "--target", targetDir };

            // Act
            var exitCode = await Program.MainAsync(args, stdout, stderr, CancellationToken.None);

            // Assert
            var output = stdout.ToString();
            var lines = output.Split('\n', StringSplitOptions.RemoveEmptyEntries);
            
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (string.IsNullOrEmpty(trimmed)) continue;
                
                // Each line must be a complete JSON object
                System.Text.Json.JsonDocument.Parse(trimmed).Should().NotBeNull();
            }
        }
        finally
        {
            Directory.Delete(sourceDir, true);
            Directory.Delete(targetDir, true);
        }
    }
}
