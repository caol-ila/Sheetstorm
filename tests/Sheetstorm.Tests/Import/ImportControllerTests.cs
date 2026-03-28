using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Import;
using Sheetstorm.Infrastructure.Import;

namespace Sheetstorm.Tests.Import;

public class ImportControllerTests
{
    private readonly IImportService _importService;
    private readonly ImportController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public ImportControllerTests()
    {
        _importService = Substitute.For<IImportService>();
        _sut = new ImportController(_importService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static IFormFile MakeFormFile(
        string fileName, string contentType, byte[]? content = null)
    {
        var bytes = content ?? [0x25, 0x50, 0x44, 0x46]; // PDF magic bytes
        var stream = new MemoryStream(bytes);
        var file = Substitute.For<IFormFile>();
        file.FileName.Returns(fileName);
        file.ContentType.Returns(contentType);
        file.Length.Returns(bytes.Length);
        file.OpenReadStream().Returns(stream);
        return file;
    }

    private ImportResultDto MakeImportResult(Guid bandId) =>
        new(Guid.NewGuid(), "Test Stück", ImportStatus.Completed,
            new PieceMetadataDto("Test Stück", null, null, null, null));

    // ── No file ───────────────────────────────────────────────────────────────

    [Fact]
    public async Task Import_NullFile_ReturnsBadRequest()
    {
        var result = await _sut.Import(_bandId, null!, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("NO_FILE", err.Error);
    }

    [Fact]
    public async Task Import_EmptyFile_ReturnsBadRequest()
    {
        var file = Substitute.For<IFormFile>();
        file.Length.Returns(0);

        var result = await _sut.Import(_bandId, file, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("NO_FILE", err.Error);
    }

    // ── Supported file types ──────────────────────────────────────────────────

    [Theory]
    [InlineData("application/pdf", "sheet.pdf")]
    [InlineData("image/png", "sheet.png")]
    [InlineData("image/jpeg", "sheet.jpg")]
    [InlineData("image/tiff", "sheet.tiff")]
    public async Task Import_AllowedContentTypes_CallsService(string contentType, string fileName)
    {
        var file = MakeFormFile(fileName, contentType);
        _importService.ImportAsync(
                Arg.Any<Stream>(), fileName, contentType, _bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(MakeImportResult(_bandId));

        var result = await _sut.Import(_bandId, file, CancellationToken.None);

        Assert.IsType<ObjectResult>(result);
        var obj = (ObjectResult)result;
        Assert.Equal(StatusCodes.Status201Created, obj.StatusCode);
    }

    // ── Unsupported / invalid file types ─────────────────────────────────────

    [Theory]
    [InlineData("application/zip", "archive.zip")]
    [InlineData("text/plain", "notes.txt")]
    [InlineData("application/msword", "score.doc")]
    [InlineData("image/gif", "animation.gif")]
    [InlineData("audio/mpeg", "song.mp3")]
    [InlineData("application/x-executable", "malware.exe")]
    public async Task Import_UnsupportedContentType_ReturnsBadRequest(string contentType, string fileName)
    {
        var file = MakeFormFile(fileName, contentType);

        var result = await _sut.Import(_bandId, file, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("INVALID_FILE_TYPE", err.Error);
    }

    [Fact]
    public async Task Import_UnsupportedType_DoesNotCallService()
    {
        var file = MakeFormFile("malware.exe", "application/x-executable");

        await _sut.Import(_bandId, file, CancellationToken.None);

        await _importService.DidNotReceive().ImportAsync(
            Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(),
            Arg.Any<Guid?>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>());
    }

    // ── Successful import ─────────────────────────────────────────────────────

    [Fact]
    public async Task Import_ValidPdf_Returns201WithImportResult()
    {
        var file = MakeFormFile("polka.pdf", "application/pdf");
        var expected = MakeImportResult(_bandId);
        _importService.ImportAsync(
                Arg.Any<Stream>(), "polka.pdf", "application/pdf", _bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.Import(_bandId, file, CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, obj.StatusCode);
        var returned = Assert.IsType<ImportResultDto>(obj.Value);
        Assert.Equal(expected.PieceId, returned.PieceId);
        Assert.Equal(ImportStatus.Completed, returned.ImportStatus);
    }

    [Fact]
    public async Task Import_ValidFile_PassesBandIdAndMusicianIdToService()
    {
        var file = MakeFormFile("song.pdf", "application/pdf");
        _importService.ImportAsync(
                Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(),
                Arg.Any<Guid?>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(MakeImportResult(_bandId));

        await _sut.Import(_bandId, file, CancellationToken.None);

        await _importService.Received(1).ImportAsync(
            Arg.Any<Stream>(), "song.pdf", "application/pdf",
            _bandId, _musicianId, Arg.Any<CancellationToken>());
    }

    // ── Content-type case insensitivity ───────────────────────────────────────

    [Fact]
    public async Task Import_ContentTypeMixedCase_IsAccepted()
    {
        var file = MakeFormFile("Sheet.PDF", "Application/PDF");
        _importService.ImportAsync(
                Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(),
                Arg.Any<Guid?>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(MakeImportResult(_bandId));

        var result = await _sut.Import(_bandId, file, CancellationToken.None);

        // Should be 201, not 400 — content-type validation is case-insensitive
        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, obj.StatusCode);
    }
}
