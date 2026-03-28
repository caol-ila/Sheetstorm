using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Import;
using Sheetstorm.Infrastructure.Import;

namespace Sheetstorm.Tests.Import;

public class PiecesControllerTests
{
    private readonly IImportService _importService;
    private readonly PiecesController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public PiecesControllerTests()
    {
        _importService = Substitute.For<IImportService>();
        _sut = new PiecesController(_importService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static PieceDto MakePieceDto(Guid id, Guid bandId, string titel = "Test") =>
        new(id, titel, null, null, null, null, null, null, null, bandId, null, null,
            ImportStatus.Completed, DateTime.UtcNow, DateTime.UtcNow);

    // ── GET /Pieces ──────────────────────────────────────────────────────────

    [Fact]
    public async Task GetPieces_ReturnsOkWithList()
    {
        var Pieces = new List<PieceDto>
        {
            MakePieceDto(Guid.NewGuid(), _bandId, "Song A"),
            MakePieceDto(Guid.NewGuid(), _bandId, "Song B")
        };
        _importService.GetPiecesAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Pieces);

        var result = await _sut.GetPieces(_bandId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<PieceDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetPieces_DelegatesCurrentUserIdToService()
    {
        _importService.GetPiecesAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(new List<PieceDto>());

        await _sut.GetPieces(_bandId, CancellationToken.None);

        await _importService.Received(1).GetPiecesAsync(_bandId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetPieces_ServiceThrowsDomainException_Propagates()
    {
        _importService.GetPiecesAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("BAND_NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetPieces(_bandId, CancellationToken.None));
    }

    // ── GET /Pieces/{id} ─────────────────────────────────────────────────────

    [Fact]
    public async Task GetPiece_ReturnsOkWithDto()
    {
        var pieceId = Guid.NewGuid();
        var dto = MakePieceDto(pieceId, _bandId, "Serenade");
        _importService.GetPieceAsync(_bandId, pieceId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetPiece(_bandId, pieceId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<PieceDto>(ok.Value);
        Assert.Equal(pieceId, returned.Id);
        Assert.Equal("Serenade", returned.Title);
    }

    [Fact]
    public async Task GetPiece_PassesPieceIdCorrectlyToService()
    {
        var pieceId = Guid.NewGuid();
        _importService.GetPieceAsync(_bandId, pieceId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(MakePieceDto(pieceId, _bandId));

        await _sut.GetPiece(_bandId, pieceId, CancellationToken.None);

        await _importService.Received(1).GetPieceAsync(_bandId, pieceId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetPiece_NotFound_DomainExceptionPropagates()
    {
        _importService.GetPieceAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("PIECE_NOT_FOUND", "Piece not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetPiece(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── POST /Pieces ─────────────────────────────────────────────────────────

    [Fact]
    public async Task CreatePiece_ValidRequest_Returns201WithDto()
    {
        var pieceId = Guid.NewGuid();
        var dto = new PieceCreateDto("Neue Polka", "Müller", null, null, null, null, null, null);
        var expected = MakePieceDto(pieceId, _bandId, "Neue Polka");
        _importService.CreatePieceAsync(_bandId, dto, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.CreatePiece(_bandId, dto, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<PieceDto>(created.Value);
        Assert.Equal("Neue Polka", returned.Title);
    }

    [Fact]
    public async Task CreatePiece_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var dto = new PieceCreateDto("", null, null, null, null, null, null, null);

        var result = await _sut.CreatePiece(_bandId, dto, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task CreatePiece_NotMember_DomainExceptionPropagates()
    {
        var dto = new PieceCreateDto("Title", null, null, null, null, null, null, null);
        _importService.CreatePieceAsync(Arg.Any<Guid>(), Arg.Any<PieceCreateDto>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("BAND_NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreatePiece(_bandId, dto, CancellationToken.None));
    }

    // ── PUT /Pieces/{id} ─────────────────────────────────────────────────────

    [Fact]
    public async Task UpdatePiece_ValidRequest_ReturnsOkWithUpdatedDto()
    {
        var pieceId = Guid.NewGuid();
        var dto = new PieceUpdateDto("Updated Title", null, null, null, null, null, null, null);
        var expected = MakePieceDto(pieceId, _bandId, "Updated Title");
        _importService.UpdatePieceAsync(_bandId, pieceId, dto, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.UpdatePiece(_bandId, pieceId, dto, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<PieceDto>(ok.Value);
        Assert.Equal("Updated Title", returned.Title);
    }

    [Fact]
    public async Task UpdatePiece_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var dto = new PieceUpdateDto("", null, null, null, null, null, null, null);

        var result = await _sut.UpdatePiece(_bandId, Guid.NewGuid(), dto, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task UpdatePiece_StueckNotFound_DomainExceptionPropagates()
    {
        var dto = new PieceUpdateDto("Title", null, null, null, null, null, null, null);
        _importService.UpdatePieceAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<PieceUpdateDto>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("PIECE_NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdatePiece(_bandId, Guid.NewGuid(), dto, CancellationToken.None));
    }

    // ── DELETE /Pieces/{id} ──────────────────────────────────────────────────

    [Fact]
    public async Task DeletePiece_ValidRequest_Returns204NoContent()
    {
        var pieceId = Guid.NewGuid();
        _importService.DeletePieceAsync(_bandId, pieceId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeletePiece(_bandId, pieceId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeletePiece_PassesCorrectIdsToService()
    {
        var pieceId = Guid.NewGuid();
        _importService.DeletePieceAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        await _sut.DeletePiece(_bandId, pieceId, CancellationToken.None);

        await _importService.Received(1).DeletePieceAsync(_bandId, pieceId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeletePiece_StueckNotFound_DomainExceptionPropagates()
    {
        _importService.DeletePieceAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("PIECE_NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeletePiece(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── Band-scoped access (via controller → service delegation) ───────────

    [Fact]
    public async Task KapelleScopedAccess_ServiceEnforcesIsolation_ControllerPropagatesException()
    {
        // Simulate: musician tries to access a different Band's resources
        var foreignBandId = Guid.NewGuid();
        _importService.GetPiecesAsync(foreignBandId, _musicianId, Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("BAND_NOT_FOUND", "Band not found or no access.", 404));

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetPieces(foreignBandId, CancellationToken.None));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }
}
