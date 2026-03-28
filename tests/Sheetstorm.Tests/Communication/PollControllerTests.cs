using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Polls;
using Sheetstorm.Infrastructure.Polls;

namespace Sheetstorm.Tests.Communication;

public class PollControllerTests
{
    private readonly IPollService _pollService;
    private readonly PollController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public PollControllerTests()
    {
        _pollService = Substitute.For<IPollService>();
        _sut = new PollController(_pollService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static PollDto MakePollDto(Guid id) =>
        new(id, "Question?", false, false, null, false, Guid.NewGuid(), "Creator", 0, false, DateTime.UtcNow);

    private static PollDetailDto MakeDetailDto(Guid id) =>
        new(id, "Question?", false, false, null, false, Guid.NewGuid(), "Creator",
            Array.Empty<PollOptionDto>(), 0, false, DateTime.UtcNow);

    // ── GET /Polls ────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetAll_ReturnsOkWithList()
    {
        var polls = new List<PollDto> { MakePollDto(Guid.NewGuid()) };
        _pollService.GetAllAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(polls);

        var result = await _sut.GetAll(_bandId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<PollDto>>(ok.Value);
        Assert.Single(returned);
    }

    [Fact]
    public async Task GetAll_DelegatesCurrentUserId()
    {
        _pollService.GetAllAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(new List<PollDto>());

        await _sut.GetAll(_bandId, CancellationToken.None);

        await _pollService.Received(1).GetAllAsync(_bandId, _musicianId, Arg.Any<CancellationToken>());
    }

    // ── GET /Polls/{id} ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetById_ReturnsOkWithDto()
    {
        var pollId = Guid.NewGuid();
        var dto = MakeDetailDto(pollId);
        _pollService.GetByIdAsync(_bandId, pollId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetById(_bandId, pollId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<PollDetailDto>(ok.Value);
        Assert.Equal(pollId, returned.Id);
    }

    [Fact]
    public async Task GetById_NotFound_PropagatesDomainException()
    {
        _pollService.GetByIdAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Poll not found.", 404));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetById(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── POST /Polls ───────────────────────────────────────────────────────────

    [Fact]
    public async Task Create_ValidRequest_Returns201()
    {
        var request = new CreatePollRequest("Question?", new[] { "A", "B" }, false, false, null);
        var dto = MakeDetailDto(Guid.NewGuid());
        _pollService.CreateAsync(_bandId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.Create(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        Assert.IsType<PollDetailDto>(created.Value);
    }

    [Fact]
    public async Task Create_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Question", "Required");
        var request = new CreatePollRequest("", new[] { "A", "B" }, false, false, null);

        var result = await _sut.Create(_bandId, request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task Create_Forbidden_PropagatesDomainException()
    {
        var request = new CreatePollRequest("Question?", new[] { "A", "B" }, false, false, null);
        _pollService.CreateAsync(Arg.Any<Guid>(), Arg.Any<CreatePollRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Forbidden.", 403));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.Create(_bandId, request, CancellationToken.None));
    }

    // ── DELETE /Polls/{id} ────────────────────────────────────────────────────

    [Fact]
    public async Task Delete_ValidRequest_Returns204()
    {
        var pollId = Guid.NewGuid();
        _pollService.DeleteAsync(_bandId, pollId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.Delete(_bandId, pollId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Delete_PassesCorrectIds()
    {
        var pollId = Guid.NewGuid();
        _pollService.DeleteAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        await _sut.Delete(_bandId, pollId, CancellationToken.None);

        await _pollService.Received(1).DeleteAsync(_bandId, pollId, _musicianId, Arg.Any<CancellationToken>());
    }

    // ── POST /Polls/{id}/vote ─────────────────────────────────────────────────

    [Fact]
    public async Task Vote_ValidRequest_Returns204()
    {
        var pollId = Guid.NewGuid();
        var request = new VotePollRequest(new[] { Guid.NewGuid() });
        _pollService.VoteAsync(_bandId, pollId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.Vote(_bandId, pollId, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Vote_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("OptionIds", "Required");
        var request = new VotePollRequest(Array.Empty<Guid>());

        var result = await _sut.Vote(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task Vote_Conflict_PropagatesDomainException()
    {
        var request = new VotePollRequest(new[] { Guid.NewGuid() });
        _pollService.VoteAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<VotePollRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("CONFLICT", "Poll closed.", 409));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.Vote(_bandId, Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── POST /Polls/{id}/close ────────────────────────────────────────────────

    [Fact]
    public async Task Close_ValidRequest_Returns204()
    {
        var pollId = Guid.NewGuid();
        _pollService.CloseAsync(_bandId, pollId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.Close(_bandId, pollId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Close_Forbidden_PropagatesDomainException()
    {
        _pollService.CloseAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Forbidden.", 403));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.Close(_bandId, Guid.NewGuid(), CancellationToken.None));
    }
}
