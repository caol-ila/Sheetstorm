using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Substitutes;
using Sheetstorm.Infrastructure.Substitutes;

namespace Sheetstorm.Tests.Substitutes;

public class SubstituteControllerTests
{
    private readonly ISubstituteService _substituteService;
    private readonly SubstituteAccessController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public SubstituteControllerTests()
    {
        _substituteService = Substitute.For<ISubstituteService>();
        _sut = new SubstituteAccessController(_substituteService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static SubstituteAccessCreatedDto MakeCreatedDto(Guid id) =>
        new(id, Guid.NewGuid(), "Name", null, null, null, "token123", "https://link.com", "qr", DateTime.UtcNow.AddDays(2), true, null, null, DateTime.UtcNow);

    private static SubstituteAccessDto MakeAccessDto(Guid id) =>
        new(id, Guid.NewGuid(), "Name", null, null, null, null, null, Guid.NewGuid(), "Granter", DateTime.UtcNow.AddDays(2), null, true, null, null, null, DateTime.UtcNow);

    // ── POST /Substitutes ─────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAccess_ValidRequest_Returns201()
    {
        var request = new CreateSubstituteAccessRequest("John Doe", "john@test.com", null, null, DateTime.UtcNow.AddDays(2), null, null);
        var dto = MakeCreatedDto(Guid.NewGuid());
        _substituteService.CreateAccessAsync(_bandId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.CreateAccess(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        Assert.IsType<SubstituteAccessCreatedDto>(created.Value);
    }

    [Fact]
    public async Task CreateAccess_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Name", "Required");
        var request = new CreateSubstituteAccessRequest("", null, null, null, null, null, null);

        var result = await _sut.CreateAccess(_bandId, request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task CreateAccess_Forbidden_PropagatesDomainException()
    {
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, null, null, null);
        _substituteService.CreateAccessAsync(Arg.Any<Guid>(), Arg.Any<CreateSubstituteAccessRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Forbidden.", 403));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAccess(_bandId, request, CancellationToken.None));
    }

    // ── GET /Substitutes ──────────────────────────────────────────────────────

    [Fact]
    public async Task GetActiveAccesses_ReturnsOkWithList()
    {
        var accesses = new List<SubstituteAccessDto> { MakeAccessDto(Guid.NewGuid()) };
        _substituteService.GetActiveAccessesAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(accesses);

        var result = await _sut.GetActiveAccesses(_bandId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<SubstituteAccessDto>>(ok.Value);
        Assert.Single(returned);
    }

    // ── DELETE /Substitutes/{id} ──────────────────────────────────────────────

    [Fact]
    public async Task RevokeAccess_ValidRequest_Returns204()
    {
        var accessId = Guid.NewGuid();
        _substituteService.RevokeAccessAsync(_bandId, accessId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.RevokeAccess(_bandId, accessId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task RevokeAccess_Conflict_PropagatesDomainException()
    {
        _substituteService.RevokeAccessAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("CONFLICT", "Already revoked.", 409));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.RevokeAccess(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── PATCH /Substitutes/{id} ───────────────────────────────────────────────

    [Fact]
    public async Task ExtendAccess_ValidRequest_ReturnsOk()
    {
        var accessId = Guid.NewGuid();
        var request = new ExtendSubstituteAccessRequest(DateTime.UtcNow.AddDays(5));
        var dto = MakeAccessDto(accessId);
        _substituteService.ExtendAccessAsync(_bandId, accessId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.ExtendAccess(_bandId, accessId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.IsType<SubstituteAccessDto>(ok.Value);
    }

    [Fact]
    public async Task ExtendAccess_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("ExpiresAt", "Required");
        var request = new ExtendSubstituteAccessRequest(default);

        var result = await _sut.ExtendAccess(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    // ── GET /substitute/{token} (Public) ──────────────────────────────────────

    [Fact]
    public async Task ValidateToken_ValidToken_ReturnsOk()
    {
        var token = "valid-token";
        var dto = new SubstituteValidationDto(Guid.NewGuid(), "Name", "Instrument", Guid.NewGuid(), "Band", null, null, null, null, null, null, DateTime.UtcNow.AddDays(2));
        _substituteService.ValidateTokenAsync(token, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.ValidateToken(token, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<SubstituteValidationDto>(ok.Value);
        Assert.Equal("Name", returned.Name);
    }

    [Fact]
    public async Task ValidateToken_InvalidToken_PropagatesDomainException()
    {
        _substituteService.ValidateTokenAsync(Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Invalid token.", 404));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.ValidateToken("invalid", CancellationToken.None));
    }
}
