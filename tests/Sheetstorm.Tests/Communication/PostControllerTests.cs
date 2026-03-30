using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Communication;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Communication;

namespace Sheetstorm.Tests.Communication;

public class PostControllerTests
{
    private readonly IPostService _postService;
    private readonly PostController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public PostControllerTests()
    {
        _postService = Substitute.For<IPostService>();
        _sut = new PostController(_postService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static PostDto MakePostDto(Guid id, Guid bandId, string title = "Test") =>
        new(id, title, "Content", null, Guid.NewGuid(), "Author", false, null, 0,
            Array.Empty<ReactionSummaryDto>(), DateTime.UtcNow, DateTime.UtcNow);

    private static PostDetailDto MakeDetailDto(Guid id) =>
        new(id, "Title", "Content", null, Guid.NewGuid(), "Author", false, null,
            Array.Empty<PostCommentDto>(), Array.Empty<ReactionSummaryDto>(),
            DateTime.UtcNow, DateTime.UtcNow);

    // ── GET /Posts ────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetAll_ReturnsOkWithList()
    {
        var posts = new List<PostDto> { MakePostDto(Guid.NewGuid(), _bandId) };
        _postService.GetAllAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(posts);

        var result = await _sut.GetAll(_bandId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<PostDto>>(ok.Value);
        Assert.Single(returned);
    }

    [Fact]
    public async Task GetAll_DelegatesCurrentUserId()
    {
        _postService.GetAllAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(new List<PostDto>());

        await _sut.GetAll(_bandId, CancellationToken.None);

        await _postService.Received(1).GetAllAsync(_bandId, _musicianId, Arg.Any<CancellationToken>());
    }

    // ── GET /Posts/{id} ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetById_ReturnsOkWithDto()
    {
        var postId = Guid.NewGuid();
        var dto = MakeDetailDto(postId);
        _postService.GetByIdAsync(_bandId, postId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetById(_bandId, postId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<PostDetailDto>(ok.Value);
        Assert.Equal(postId, returned.Id);
    }

    [Fact]
    public async Task GetById_NotFound_PropagatesDomainException()
    {
        _postService.GetByIdAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Post not found.", 404));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetById(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── POST /Posts ───────────────────────────────────────────────────────────

    [Fact]
    public async Task Create_ValidRequest_Returns201()
    {
        var request = new CreatePostRequest("Title", "Content", null);
        var dto = MakeDetailDto(Guid.NewGuid());
        _postService.CreateAsync(_bandId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.Create(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        Assert.IsType<PostDetailDto>(created.Value);
    }

    [Fact]
    public async Task Create_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var request = new CreatePostRequest("", "Content", null);

        var result = await _sut.Create(_bandId, request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task Create_Forbidden_PropagatesDomainException()
    {
        var request = new CreatePostRequest("Title", "Content", null);
        _postService.CreateAsync(Arg.Any<Guid>(), Arg.Any<CreatePostRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Forbidden.", 403));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.Create(_bandId, request, CancellationToken.None));
    }

    // ── PUT /Posts/{id} ───────────────────────────────────────────────────────

    [Fact]
    public async Task Update_ValidRequest_ReturnsOk()
    {
        var postId = Guid.NewGuid();
        var request = new UpdatePostRequest("Updated", "Content", null);
        var dto = MakeDetailDto(postId);
        _postService.UpdateAsync(_bandId, postId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.Update(_bandId, postId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.IsType<PostDetailDto>(ok.Value);
    }

    [Fact]
    public async Task Update_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var request = new UpdatePostRequest("", "Content", null);

        var result = await _sut.Update(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    // ── DELETE /Posts/{id} ────────────────────────────────────────────────────

    [Fact]
    public async Task Delete_ValidRequest_Returns204()
    {
        var postId = Guid.NewGuid();
        _postService.DeleteAsync(_bandId, postId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.Delete(_bandId, postId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Delete_PassesCorrectIds()
    {
        var postId = Guid.NewGuid();
        _postService.DeleteAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        await _sut.Delete(_bandId, postId, CancellationToken.None);

        await _postService.Received(1).DeleteAsync(_bandId, postId, _musicianId, Arg.Any<CancellationToken>());
    }

    // ── POST /Posts/{id}/pin ──────────────────────────────────────────────────

    [Fact]
    public async Task Pin_ValidRequest_Returns204()
    {
        var postId = Guid.NewGuid();
        _postService.PinAsync(_bandId, postId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.Pin(_bandId, postId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Pin_Conflict_PropagatesDomainException()
    {
        _postService.PinAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("CONFLICT", "Max 3 pinned.", 409));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.Pin(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── DELETE /Posts/{id}/pin ────────────────────────────────────────────────

    [Fact]
    public async Task Unpin_ValidRequest_Returns204()
    {
        var postId = Guid.NewGuid();
        _postService.UnpinAsync(_bandId, postId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.Unpin(_bandId, postId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    // ── POST /Posts/{id}/comments ─────────────────────────────────────────────

    [Fact]
    public async Task AddComment_ValidRequest_Returns201()
    {
        var postId = Guid.NewGuid();
        var request = new CreatePostCommentRequest("Comment", null);
        var dto = new PostCommentDto(Guid.NewGuid(), "Comment", _musicianId, "Name", null, false, DateTime.UtcNow);
        _postService.AddCommentAsync(_bandId, postId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.AddComment(_bandId, postId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        Assert.IsType<PostCommentDto>(created.Value);
    }

    [Fact]
    public async Task AddComment_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Content", "Required");
        var request = new CreatePostCommentRequest("", null);

        var result = await _sut.AddComment(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    // ── DELETE /Posts/{id}/comments/{commentId} ──────────────────────────────

    [Fact]
    public async Task DeleteComment_ValidRequest_Returns204()
    {
        var postId = Guid.NewGuid();
        var commentId = Guid.NewGuid();
        _postService.DeleteCommentAsync(_bandId, postId, commentId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteComment(_bandId, postId, commentId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    // ── POST /Posts/{id}/reactions ────────────────────────────────────────────

    [Fact]
    public async Task AddReaction_ValidRequest_Returns204()
    {
        var postId = Guid.NewGuid();
        var request = new AddPostReactionRequest("👍");
        _postService.AddReactionAsync(_bandId, postId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.AddReaction(_bandId, postId, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task AddReaction_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("ReactionType", "Required");
        var request = new AddPostReactionRequest("");

        var result = await _sut.AddReaction(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    // ── DELETE /Posts/{id}/reactions ──────────────────────────────────────────

    [Fact]
    public async Task RemoveReaction_ValidRequest_Returns204()
    {
        var postId = Guid.NewGuid();
        _postService.RemoveReactionAsync(_bandId, postId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.RemoveReaction(_bandId, postId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }
}
