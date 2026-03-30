using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Communication;
using Sheetstorm.Infrastructure.Communication;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/posts")]
[Authorize]
public class PostController(IPostService service) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<PostDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(Guid bandId, CancellationToken ct)
    {
        var result = await service.GetAllAsync(bandId, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpGet("{postId:guid}")]
    [ProducesResponseType(typeof(PostDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid bandId, Guid postId, CancellationToken ct)
    {
        var result = await service.GetByIdAsync(bandId, postId, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpPost]
    [ProducesResponseType(typeof(PostDetailDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Create(Guid bandId, [FromBody] CreatePostRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.CreateAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpPut("{postId:guid}")]
    [ProducesResponseType(typeof(PostDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid bandId, Guid postId, [FromBody] UpdatePostRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.UpdateAsync(bandId, postId, request, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpDelete("{postId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid bandId, Guid postId, CancellationToken ct)
    {
        await service.DeleteAsync(bandId, postId, CurrentUserId, ct);
        return NoContent();
    }

    [HttpPost("{postId:guid}/pin")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Pin(Guid bandId, Guid postId, CancellationToken ct)
    {
        await service.PinAsync(bandId, postId, CurrentUserId, ct);
        return NoContent();
    }

    [HttpDelete("{postId:guid}/pin")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Unpin(Guid bandId, Guid postId, CancellationToken ct)
    {
        await service.UnpinAsync(bandId, postId, CurrentUserId, ct);
        return NoContent();
    }

    [HttpPost("{postId:guid}/comments")]
    [ProducesResponseType(typeof(PostCommentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AddComment(Guid bandId, Guid postId, [FromBody] CreatePostCommentRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.AddCommentAsync(bandId, postId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpDelete("{postId:guid}/comments/{commentId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteComment(Guid bandId, Guid postId, Guid commentId, CancellationToken ct)
    {
        await service.DeleteCommentAsync(bandId, postId, commentId, CurrentUserId, ct);
        return NoContent();
    }

    [HttpPost("{postId:guid}/reactions")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AddReaction(Guid bandId, Guid postId, [FromBody] AddPostReactionRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        await service.AddReactionAsync(bandId, postId, request, CurrentUserId, ct);
        return NoContent();
    }

    [HttpDelete("{postId:guid}/reactions")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveReaction(Guid bandId, Guid postId, CancellationToken ct)
    {
        await service.RemoveReactionAsync(bandId, postId, CurrentUserId, ct);
        return NoContent();
    }
}
