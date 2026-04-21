using FluentAssertions;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.PdfLabeling.Abstractions;
using Sheetstorm.PdfLabeling.Domain;
using Sheetstorm.PdfLabeling.Services;
using Xunit;

namespace Sheetstorm.PdfLabeling.Tests.Services;

public class PdfLabelingOrchestratorTests : IDisposable
{
    private readonly string _sourceDirectory;
    private readonly string _targetDirectory;
    private readonly IPdfFirstPageRenderer _renderer;
    private readonly ITitleRecognizer _recognizer;
    private readonly IFileNameSanitizer _sanitizer;
    private readonly IFileTargetResolver _resolver;
    private readonly PdfLabelingOrchestrator _sut;

    public PdfLabelingOrchestratorTests()
    {
        _sourceDirectory = Path.Combine(Path.GetTempPath(), $"PdfLabelingTests_Source_{Guid.NewGuid():N}");
        _targetDirectory = Path.Combine(Path.GetTempPath(), $"PdfLabelingTests_Target_{Guid.NewGuid():N}");
        Directory.CreateDirectory(_sourceDirectory);

        _renderer = Substitute.For<IPdfFirstPageRenderer>();
        _recognizer = Substitute.For<ITitleRecognizer>();
        _sanitizer = Substitute.For<IFileNameSanitizer>();
        _resolver = Substitute.For<IFileTargetResolver>();

        _sut = new PdfLabelingOrchestrator(_renderer, _recognizer, _sanitizer, _resolver);
    }

    public void Dispose()
    {
        if (Directory.Exists(_sourceDirectory))
        {
            Directory.Delete(_sourceDirectory, recursive: true);
        }
        if (Directory.Exists(_targetDirectory))
        {
            Directory.Delete(_targetDirectory, recursive: true);
        }
    }

    [Fact]
    public async Task LabelBatch_EmptyDirectory_ReturnsEmpty()
    {
        // Arrange
        var job = new LabelingJob(_sourceDirectory, _targetDirectory);
        var progress = Substitute.For<IProgress<ProgressUpdate>>();

        // Act
        var results = await _sut.LabelBatchAsync(job, progress);

        // Assert
        results.Should().BeEmpty();
        progress.Received(1).Report(Arg.Is<ProgressUpdate>(p => 
            p.ProcessedCount == 0 && p.TotalCount == 0));
    }

    [Fact]
    public async Task LabelBatch_HighConfidence_CopiesWithSanitizedName()
    {
        // Arrange
        var sourcePdf = Path.Combine(_sourceDirectory, "original.pdf");
        File.WriteAllText(sourcePdf, "dummy pdf content");
        Directory.CreateDirectory(_targetDirectory);

        var job = new LabelingJob(_sourceDirectory, _targetDirectory);
        var pngBytes = new byte[] { 1, 2, 3 };

        _renderer.RenderFirstPageAsPngAsync(sourcePdf, Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(pngBytes);
        _recognizer.RecognizeTitleAsync(pngBytes, Arg.Any<CancellationToken>())
            .Returns(new TitleRecognition("Radetzky Marsch", 0.95));
        _sanitizer.Sanitize("Radetzky Marsch").Returns("Radetzky Marsch");

        var targetPath = Path.Combine(_targetDirectory, "Radetzky Marsch.pdf");
        _resolver.Resolve(_targetDirectory, "Radetzky Marsch", "pdf").Returns(targetPath);

        // Act
        var results = await _sut.LabelBatchAsync(job);

        // Assert
        results.Should().HaveCount(1);
        results[0].SourcePath.Should().Be(sourcePdf);
        results[0].TargetPath.Should().Be(targetPath);
        results[0].RecognizedTitle.Should().Be("Radetzky Marsch");
        results[0].Confidence.Should().Be(0.95);
        results[0].Status.Should().Be(LabelingStatus.Labeled);
        results[0].Message.Should().BeNull();

        File.Exists(targetPath).Should().BeTrue();
        File.ReadAllText(targetPath).Should().Be("dummy pdf content");
    }

    [Fact]
    public async Task LabelBatch_LowConfidence_RoutesToUnerkannt()
    {
        // Arrange
        var sourcePdf = Path.Combine(_sourceDirectory, "original.pdf");
        File.WriteAllText(sourcePdf, "dummy pdf content");
        Directory.CreateDirectory(_targetDirectory);

        var job = new LabelingJob(_sourceDirectory, _targetDirectory);
        var pngBytes = new byte[] { 1, 2, 3 };

        _renderer.RenderFirstPageAsPngAsync(sourcePdf, Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(pngBytes);
        _recognizer.RecognizeTitleAsync(pngBytes, Arg.Any<CancellationToken>())
            .Returns(new TitleRecognition("Unclear", 0.4));

        // Act
        var results = await _sut.LabelBatchAsync(job);

        // Assert
        results.Should().HaveCount(1);
        var unerkanntDir = Path.Combine(_targetDirectory, "_unerkannt");
        var targetPath = Path.Combine(unerkanntDir, "original.pdf");

        results[0].SourcePath.Should().Be(sourcePdf);
        results[0].TargetPath.Should().Be(targetPath);
        results[0].RecognizedTitle.Should().Be("Unclear");
        results[0].Confidence.Should().Be(0.4);
        results[0].Status.Should().Be(LabelingStatus.Unrecognized);

        Directory.Exists(unerkanntDir).Should().BeTrue();
        File.Exists(targetPath).Should().BeTrue();
        File.ReadAllText(targetPath).Should().Be("dummy pdf content");
    }

    [Fact]
    public async Task LabelBatch_ExactConfidenceThreshold_0_6_IsAccepted()
    {
        // Arrange
        var sourcePdf = Path.Combine(_sourceDirectory, "test.pdf");
        File.WriteAllText(sourcePdf, "dummy pdf content");
        Directory.CreateDirectory(_targetDirectory);

        var job = new LabelingJob(_sourceDirectory, _targetDirectory);
        var pngBytes = new byte[] { 1, 2, 3 };

        _renderer.RenderFirstPageAsPngAsync(sourcePdf, Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(pngBytes);
        _recognizer.RecognizeTitleAsync(pngBytes, Arg.Any<CancellationToken>())
            .Returns(new TitleRecognition("Edge Case", 0.6));
        _sanitizer.Sanitize("Edge Case").Returns("Edge Case");

        var targetPath = Path.Combine(_targetDirectory, "Edge Case.pdf");
        _resolver.Resolve(_targetDirectory, "Edge Case", "pdf").Returns(targetPath);

        // Act
        var results = await _sut.LabelBatchAsync(job);

        // Assert
        results.Should().HaveCount(1);
        results[0].Status.Should().Be(LabelingStatus.Labeled);
        File.Exists(targetPath).Should().BeTrue();
    }

    [Fact]
    public async Task LabelBatch_Duplicate_UsesResolverSuffix()
    {
        // Arrange
        var sourcePdf = Path.Combine(_sourceDirectory, "test.pdf");
        File.WriteAllText(sourcePdf, "dummy pdf content");
        Directory.CreateDirectory(_targetDirectory);

        var job = new LabelingJob(_sourceDirectory, _targetDirectory);
        var pngBytes = new byte[] { 1, 2, 3 };

        _renderer.RenderFirstPageAsPngAsync(sourcePdf, Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(pngBytes);
        _recognizer.RecognizeTitleAsync(pngBytes, Arg.Any<CancellationToken>())
            .Returns(new TitleRecognition("Duplicate", 0.9));
        _sanitizer.Sanitize("Duplicate").Returns("Duplicate");

        var targetPathWithSuffix = Path.Combine(_targetDirectory, "Duplicate (2).pdf");
        _resolver.Resolve(_targetDirectory, "Duplicate", "pdf").Returns(targetPathWithSuffix);

        // Act
        var results = await _sut.LabelBatchAsync(job);

        // Assert
        results.Should().HaveCount(1);
        results[0].Status.Should().Be(LabelingStatus.DuplicateResolved);
        results[0].TargetPath.Should().Be(targetPathWithSuffix);
        File.Exists(targetPathWithSuffix).Should().BeTrue();
    }

    [Fact]
    public async Task LabelBatch_RendererThrows_ResultIsFailed()
    {
        // Arrange
        var pdf1 = Path.Combine(_sourceDirectory, "failing.pdf");
        var pdf2 = Path.Combine(_sourceDirectory, "succeeding.pdf");
        File.WriteAllText(pdf1, "dummy pdf content 1");
        File.WriteAllText(pdf2, "dummy pdf content 2");
        Directory.CreateDirectory(_targetDirectory);

        var job = new LabelingJob(_sourceDirectory, _targetDirectory);

        _renderer.RenderFirstPageAsPngAsync(pdf1, Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Throws(new IOException("Corrupted PDF"));
        
        var pngBytes = new byte[] { 1, 2, 3 };
        _renderer.RenderFirstPageAsPngAsync(pdf2, Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(pngBytes);
        _recognizer.RecognizeTitleAsync(pngBytes, Arg.Any<CancellationToken>())
            .Returns(new TitleRecognition("Success", 0.9));
        _sanitizer.Sanitize("Success").Returns("Success");
        var targetPath = Path.Combine(_targetDirectory, "Success.pdf");
        _resolver.Resolve(_targetDirectory, "Success", "pdf").Returns(targetPath);

        // Act
        var results = await _sut.LabelBatchAsync(job);

        // Assert
        results.Should().HaveCount(2);
        results[0].SourcePath.Should().Be(pdf1);
        results[0].Status.Should().Be(LabelingStatus.Failed);
        results[0].Message.Should().Contain("Corrupted PDF");
        results[0].TargetPath.Should().BeNull();

        results[1].SourcePath.Should().Be(pdf2);
        results[1].Status.Should().Be(LabelingStatus.Labeled);
        File.Exists(targetPath).Should().BeTrue();
    }

    [Fact]
    public async Task LabelBatch_ReportsProgress_ForEachFile()
    {
        // Arrange
        var pdf1 = Path.Combine(_sourceDirectory, "a.pdf");
        var pdf2 = Path.Combine(_sourceDirectory, "b.pdf");
        var pdf3 = Path.Combine(_sourceDirectory, "c.pdf");
        File.WriteAllText(pdf1, "content 1");
        File.WriteAllText(pdf2, "content 2");
        File.WriteAllText(pdf3, "content 3");
        Directory.CreateDirectory(_targetDirectory);

        var job = new LabelingJob(_sourceDirectory, _targetDirectory);
        var progress = Substitute.For<IProgress<ProgressUpdate>>();
        var pngBytes = new byte[] { 1, 2, 3 };

        _renderer.RenderFirstPageAsPngAsync(Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(pngBytes);
        _recognizer.RecognizeTitleAsync(pngBytes, Arg.Any<CancellationToken>())
            .Returns(new TitleRecognition("Title", 0.9));
        _sanitizer.Sanitize("Title").Returns("Title");
        _resolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
            .Returns(x => Path.Combine(_targetDirectory, $"Title_{Guid.NewGuid()}.pdf"));

        // Act
        await _sut.LabelBatchAsync(job, progress);

        // Assert
        progress.ReceivedCalls().Count().Should().BeGreaterThanOrEqualTo(3);
        
        progress.Received().Report(Arg.Is<ProgressUpdate>(p => 
            p.ProcessedCount == 3 && p.TotalCount == 3));
    }

    [Fact]
    public async Task LabelBatch_Cancellation_MarksRemainingCancelled()
    {
        // Arrange
        var pdf1 = Path.Combine(_sourceDirectory, "a.pdf");
        var pdf2 = Path.Combine(_sourceDirectory, "b.pdf");
        var pdf3 = Path.Combine(_sourceDirectory, "c.pdf");
        File.WriteAllText(pdf1, "content 1");
        File.WriteAllText(pdf2, "content 2");
        File.WriteAllText(pdf3, "content 3");
        Directory.CreateDirectory(_targetDirectory);

        var job = new LabelingJob(_sourceDirectory, _targetDirectory);
        var cts = new CancellationTokenSource();
        var pngBytes = new byte[] { 1, 2, 3 };

        var callCount = 0;
        _renderer.RenderFirstPageAsPngAsync(Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(pngBytes);
        
        _recognizer.RecognizeTitleAsync(pngBytes, Arg.Any<CancellationToken>())
            .Returns(callInfo =>
            {
                callCount++;
                if (callCount == 1)
                {
                    return new TitleRecognition("First", 0.9);
                }
                else
                {
                    cts.Cancel();
                    throw new OperationCanceledException();
                }
            });

        _sanitizer.Sanitize("First").Returns("First");
        _resolver.Resolve(_targetDirectory, "First", "pdf")
            .Returns(Path.Combine(_targetDirectory, "First.pdf"));

        // Act
        var results = await _sut.LabelBatchAsync(job, null, cts.Token);

        // Assert
        results.Should().HaveCount(3);
        results[0].Status.Should().Be(LabelingStatus.Labeled);
        results[1].Status.Should().Be(LabelingStatus.Cancelled);
        results[2].Status.Should().Be(LabelingStatus.Cancelled);
        results[1].TargetPath.Should().BeNull();
        results[2].TargetPath.Should().BeNull();
    }

    [Fact]
    public async Task LabelBatch_CreatesTargetDirectoryIfMissing()
    {
        // Arrange
        var sourcePdf = Path.Combine(_sourceDirectory, "test.pdf");
        File.WriteAllText(sourcePdf, "dummy pdf content");

        var nonExistentTarget = Path.Combine(Path.GetTempPath(), $"NonExistent_{Guid.NewGuid():N}");
        var job = new LabelingJob(_sourceDirectory, nonExistentTarget);

        try
        {
            var pngBytes = new byte[] { 1, 2, 3 };
            _renderer.RenderFirstPageAsPngAsync(sourcePdf, Arg.Any<int>(), Arg.Any<CancellationToken>())
                .Returns(pngBytes);
            _recognizer.RecognizeTitleAsync(pngBytes, Arg.Any<CancellationToken>())
                .Returns(new TitleRecognition("Test", 0.9));
            _sanitizer.Sanitize("Test").Returns("Test");
            var targetPath = Path.Combine(nonExistentTarget, "Test.pdf");
            _resolver.Resolve(nonExistentTarget, "Test", "pdf").Returns(targetPath);

            // Act
            var results = await _sut.LabelBatchAsync(job);

            // Assert
            Directory.Exists(nonExistentTarget).Should().BeTrue();
            results.Should().HaveCount(1);
            results[0].Status.Should().Be(LabelingStatus.Labeled);
            File.Exists(targetPath).Should().BeTrue();
        }
        finally
        {
            if (Directory.Exists(nonExistentTarget))
            {
                Directory.Delete(nonExistentTarget, recursive: true);
            }
        }
    }

    [Fact]
    public async Task LabelBatch_AlphabeticalOrder()
    {
        // Arrange
        var pdfB = Path.Combine(_sourceDirectory, "b.pdf");
        var pdfA = Path.Combine(_sourceDirectory, "a.pdf");
        var pdfC = Path.Combine(_sourceDirectory, "c.pdf");
        
        File.WriteAllText(pdfB, "content B");
        File.WriteAllText(pdfA, "content A");
        File.WriteAllText(pdfC, "content C");
        Directory.CreateDirectory(_targetDirectory);

        var job = new LabelingJob(_sourceDirectory, _targetDirectory);
        var pngBytes = new byte[] { 1, 2, 3 };

        _renderer.RenderFirstPageAsPngAsync(Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(pngBytes);
        _recognizer.RecognizeTitleAsync(pngBytes, Arg.Any<CancellationToken>())
            .Returns(new TitleRecognition("Title", 0.9));
        _sanitizer.Sanitize("Title").Returns("Title");
        _resolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
            .Returns(x => Path.Combine(_targetDirectory, $"Title_{Guid.NewGuid()}.pdf"));

        // Act
        var results = await _sut.LabelBatchAsync(job);

        // Assert
        results.Should().HaveCount(3);
        results[0].SourcePath.Should().EndWith("a.pdf");
        results[1].SourcePath.Should().EndWith("b.pdf");
        results[2].SourcePath.Should().EndWith("c.pdf");
    }

    [Fact]
    public async Task LabelBatch_TokenLeakScrub()
    {
        // Arrange
        var sourcePdf = Path.Combine(_sourceDirectory, "test.pdf");
        File.WriteAllText(sourcePdf, "dummy pdf content");
        Directory.CreateDirectory(_targetDirectory);

        var job = new LabelingJob(_sourceDirectory, _targetDirectory);

        _renderer.RenderFirstPageAsPngAsync(sourcePdf, Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Throws(new HttpRequestException("Authentication failed with token ghp_secrettoken123 at endpoint"));

        // Act
        var results = await _sut.LabelBatchAsync(job);

        // Assert
        results.Should().HaveCount(1);
        results[0].Status.Should().Be(LabelingStatus.Failed);
        results[0].Message.Should().NotContain("ghp_secrettoken123");
        results[0].Message.Should().NotBeNullOrEmpty();
    }
}
