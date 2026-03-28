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

public class StueckeControllerTests
{
    private readonly IImportService _importService;
    private readonly StueckeController _sut;
    private readonly Guid _musikerId = Guid.NewGuid();
    private readonly Guid _kapelleId = Guid.NewGuid();

    public StueckeControllerTests()
    {
        _importService = Substitute.For<IImportService>();
        _sut = new StueckeController(_importService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musikerId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static StueckDto MakeStueckDto(Guid id, Guid kapelleId, string titel = "Test") =>
        new(id, titel, null, null, null, null, null, null, null, kapelleId, null, null,
            ImportStatus.Completed, DateTime.UtcNow, DateTime.UtcNow);

    // ── GET /stuecke ──────────────────────────────────────────────────────────

    [Fact]
    public async Task GetStuecke_ReturnsOkWithList()
    {
        var stuecke = new List<StueckDto>
        {
            MakeStueckDto(Guid.NewGuid(), _kapelleId, "Song A"),
            MakeStueckDto(Guid.NewGuid(), _kapelleId, "Song B")
        };
        _importService.GetStueckeAsync(_kapelleId, _musikerId, Arg.Any<CancellationToken>())
            .Returns(stuecke);

        var result = await _sut.GetStuecke(_kapelleId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<StueckDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetStuecke_DelegatesCurrentUserIdToService()
    {
        _importService.GetStueckeAsync(_kapelleId, _musikerId, Arg.Any<CancellationToken>())
            .Returns(new List<StueckDto>());

        await _sut.GetStuecke(_kapelleId, CancellationToken.None);

        await _importService.Received(1).GetStueckeAsync(_kapelleId, _musikerId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetStuecke_ServiceThrowsDomainException_Propagates()
    {
        _importService.GetStueckeAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("KAPELLE_NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetStuecke(_kapelleId, CancellationToken.None));
    }

    // ── GET /stuecke/{id} ─────────────────────────────────────────────────────

    [Fact]
    public async Task GetStueck_ReturnsOkWithDto()
    {
        var stueckId = Guid.NewGuid();
        var dto = MakeStueckDto(stueckId, _kapelleId, "Serenade");
        _importService.GetStueckAsync(_kapelleId, stueckId, _musikerId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetStueck(_kapelleId, stueckId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<StueckDto>(ok.Value);
        Assert.Equal(stueckId, returned.Id);
        Assert.Equal("Serenade", returned.Titel);
    }

    [Fact]
    public async Task GetStueck_PassesStueckIdCorrectlyToService()
    {
        var stueckId = Guid.NewGuid();
        _importService.GetStueckAsync(_kapelleId, stueckId, _musikerId, Arg.Any<CancellationToken>())
            .Returns(MakeStueckDto(stueckId, _kapelleId));

        await _sut.GetStueck(_kapelleId, stueckId, CancellationToken.None);

        await _importService.Received(1).GetStueckAsync(_kapelleId, stueckId, _musikerId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetStueck_NotFound_DomainExceptionPropagates()
    {
        _importService.GetStueckAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("STUECK_NOT_FOUND", "Stück nicht gefunden.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetStueck(_kapelleId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── POST /stuecke ─────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateStueck_ValidRequest_Returns201WithDto()
    {
        var stueckId = Guid.NewGuid();
        var dto = new StueckCreateDto("Neue Polka", "Müller", null, null, null, null, null, null);
        var expected = MakeStueckDto(stueckId, _kapelleId, "Neue Polka");
        _importService.CreateStueckAsync(_kapelleId, dto, _musikerId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.CreateStueck(_kapelleId, dto, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<StueckDto>(created.Value);
        Assert.Equal("Neue Polka", returned.Titel);
    }

    [Fact]
    public async Task CreateStueck_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Titel", "Required");
        var dto = new StueckCreateDto("", null, null, null, null, null, null, null);

        var result = await _sut.CreateStueck(_kapelleId, dto, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task CreateStueck_NotMember_DomainExceptionPropagates()
    {
        var dto = new StueckCreateDto("Title", null, null, null, null, null, null, null);
        _importService.CreateStueckAsync(Arg.Any<Guid>(), Arg.Any<StueckCreateDto>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("KAPELLE_NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateStueck(_kapelleId, dto, CancellationToken.None));
    }

    // ── PUT /stuecke/{id} ─────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateStueck_ValidRequest_ReturnsOkWithUpdatedDto()
    {
        var stueckId = Guid.NewGuid();
        var dto = new StueckUpdateDto("Updated Title", null, null, null, null, null, null, null);
        var expected = MakeStueckDto(stueckId, _kapelleId, "Updated Title");
        _importService.UpdateStueckAsync(_kapelleId, stueckId, dto, _musikerId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.UpdateStueck(_kapelleId, stueckId, dto, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<StueckDto>(ok.Value);
        Assert.Equal("Updated Title", returned.Titel);
    }

    [Fact]
    public async Task UpdateStueck_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Titel", "Required");
        var dto = new StueckUpdateDto("", null, null, null, null, null, null, null);

        var result = await _sut.UpdateStueck(_kapelleId, Guid.NewGuid(), dto, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task UpdateStueck_StueckNotFound_DomainExceptionPropagates()
    {
        var dto = new StueckUpdateDto("Title", null, null, null, null, null, null, null);
        _importService.UpdateStueckAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<StueckUpdateDto>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("STUECK_NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateStueck(_kapelleId, Guid.NewGuid(), dto, CancellationToken.None));
    }

    // ── DELETE /stuecke/{id} ──────────────────────────────────────────────────

    [Fact]
    public async Task DeleteStueck_ValidRequest_Returns204NoContent()
    {
        var stueckId = Guid.NewGuid();
        _importService.DeleteStueckAsync(_kapelleId, stueckId, _musikerId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteStueck(_kapelleId, stueckId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeleteStueck_PassesCorrectIdsToService()
    {
        var stueckId = Guid.NewGuid();
        _importService.DeleteStueckAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        await _sut.DeleteStueck(_kapelleId, stueckId, CancellationToken.None);

        await _importService.Received(1).DeleteStueckAsync(_kapelleId, stueckId, _musikerId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteStueck_StueckNotFound_DomainExceptionPropagates()
    {
        _importService.DeleteStueckAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("STUECK_NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteStueck(_kapelleId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── Kapelle-scoped access (via controller → service delegation) ───────────

    [Fact]
    public async Task KapelleScopedAccess_ServiceEnforcesIsolation_ControllerPropagatesException()
    {
        // Simulate: musician tries to access a different Kapelle's resources
        var foreignKapelleId = Guid.NewGuid();
        _importService.GetStueckeAsync(foreignKapelleId, _musikerId, Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("KAPELLE_NOT_FOUND", "Kapelle nicht gefunden oder kein Zugriff.", 404));

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetStuecke(foreignKapelleId, CancellationToken.None));

        Assert.Equal("KAPELLE_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }
}
