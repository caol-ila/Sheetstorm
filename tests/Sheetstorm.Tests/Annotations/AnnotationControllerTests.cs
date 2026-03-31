using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Annotations;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Annotations;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Annotations;

public class AnnotationControllerTests : IDisposable
{
    private readonly AnnotationController _sut;
    private readonly IAnnotationSyncService _mockService;
    private readonly Guid _userId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();
    private readonly Guid _piecePageId = Guid.NewGuid();
    private readonly Guid _voiceId = Guid.NewGuid();

    public AnnotationControllerTests()
    {
        _mockService = Substitute.For<IAnnotationSyncService>();

        _sut = new AnnotationController(_mockService)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity([
                        new Claim(JwtRegisteredClaimNames.Sub, _userId.ToString()),
                        new Claim("name", "Test User")
                    ]))
                }
            }
        };
    }

    public void Dispose()
    {
        GC.SuppressFinalize(this);
    }

    // ── GetAnnotations ────────────────────────────────────────────────────

    [Fact]
    public async Task GetAnnotations_Returns200WithAnnotations()
    {
        var expected = new List<AnnotationDto>
        {
            new(Guid.NewGuid(), _piecePageId, AnnotationLevel.Voice, _voiceId, _bandId,
                _userId, 1, [])
        };

        _mockService.GetAnnotationsAsync(
            _bandId, _piecePageId, AnnotationLevel.Voice, _voiceId,
            _userId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.GetAnnotations(_bandId, _piecePageId, "Voice", _voiceId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var data = Assert.IsAssignableFrom<IReadOnlyList<AnnotationDto>>(ok.Value);
        Assert.Single(data);
    }

    [Fact]
    public async Task GetAnnotations_InvalidLevel_Returns400()
    {
        var result = await _sut.GetAnnotations(_bandId, _piecePageId, "InvalidLevel", _voiceId, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        Assert.NotNull(bad.Value);
    }

    [Fact]
    public async Task SyncElements_InvalidLevel_Returns400()
    {
        var result = await _sut.SyncElements(_bandId, _piecePageId, "Bogus", _voiceId, 0, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        Assert.NotNull(bad.Value);
    }

    // ── CreateElement ─────────────────────────────────────────────────────

    [Fact]
    public async Task CreateElement_Returns201()
    {
        var request = new CreateAnnotationElementRequest(
            _piecePageId, AnnotationLevel.Voice, _voiceId,
            AnnotationTool.Pencil, "[{\"x\":0.1}]",
            0.1, 0.2, 0.3, 0.4, null, null, null, 1.0, 3.0
        );

        var expected = new AnnotationElementDto(
            Guid.NewGuid(), Guid.NewGuid(), AnnotationTool.Pencil,
            "[{\"x\":0.1}]", 0.1, 0.2, 0.3, 0.4,
            null, null, null, 1.0, 3.0, 1, _userId, false,
            DateTime.UtcNow, DateTime.UtcNow
        );

        _mockService.CreateElementAsync(_bandId, request, _userId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.CreateElement(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, created.StatusCode);
    }

    // ── UpdateElement ─────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateElement_Returns200()
    {
        var annotationId = Guid.NewGuid();
        var elementId = Guid.NewGuid();
        var request = new UpdateAnnotationElementRequest(
            1, 0.5, 0.6, 0.7, 0.8, null, null, null, null, 0.8, 5.0
        );

        var expected = new AnnotationElementDto(
            elementId, annotationId, AnnotationTool.Pencil,
            "[{\"x\":0.1}]", 0.5, 0.6, 0.7, 0.8,
            null, null, null, 0.8, 5.0, 2, _userId, false,
            DateTime.UtcNow, DateTime.UtcNow
        );

        _mockService.UpdateElementAsync(_bandId, annotationId, elementId, request, _userId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.UpdateElement(_bandId, annotationId, elementId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var data = Assert.IsType<AnnotationElementDto>(ok.Value);
        Assert.Equal(2L, data.Version);
    }

    // ── DeleteElement ─────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteElement_Returns204()
    {
        var annotationId = Guid.NewGuid();
        var elementId = Guid.NewGuid();

        var result = await _sut.DeleteElement(_bandId, annotationId, elementId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
        await _mockService.Received(1).DeleteElementAsync(
            _bandId, annotationId, elementId, _userId, Arg.Any<CancellationToken>());
    }

    // ── SyncElements ──────────────────────────────────────────────────────

    [Fact]
    public async Task SyncElements_Returns200WithDelta()
    {
        var syncResponse = new AnnotationSyncResponse([], 42);

        _mockService.SyncElementsAsync(
            _bandId, _piecePageId, AnnotationLevel.Voice, _voiceId,
            10, _userId, Arg.Any<CancellationToken>())
            .Returns(syncResponse);

        var result = await _sut.SyncElements(_bandId, _piecePageId, "Voice", _voiceId, 10, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var data = Assert.IsType<AnnotationSyncResponse>(ok.Value);
        Assert.Equal(42L, data.CurrentVersion);
    }

    // ── Personal Annotations ─────────────────────────────────────────────

    [Fact]
    public async Task GetPersonalAnnotations_Returns200()
    {
        var expected = new List<AnnotationDto>
        {
            new(Guid.NewGuid(), _piecePageId, AnnotationLevel.Private, null, null,
                _userId, 1, [])
        };

        _mockService.GetPersonalAnnotationsAsync(_piecePageId, _userId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.GetPersonalAnnotations(_piecePageId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(ok.Value);
    }

    [Fact]
    public async Task CreatePersonalElement_Returns201()
    {
        var request = new CreateAnnotationElementRequest(
            _piecePageId, AnnotationLevel.Private, null,
            AnnotationTool.Text, null,
            0.1, 0.2, 0.3, 0.4, "Note", null, null, 1.0, 3.0
        );

        var expected = new AnnotationElementDto(
            Guid.NewGuid(), Guid.NewGuid(), AnnotationTool.Text,
            null, 0.1, 0.2, 0.3, 0.4,
            "Note", null, null, 1.0, 3.0, 1, _userId, false,
            DateTime.UtcNow, DateTime.UtcNow
        );

        _mockService.CreatePersonalElementAsync(_piecePageId, request, _userId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.CreatePersonalElement(_piecePageId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, created.StatusCode);
    }
}
