using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Infrastructure.BandManagement;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}")]
[Authorize]
public class MembersController(IBandService bandService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/bands/{bandId}/Members
    [HttpGet("members")]
    [ProducesResponseType(typeof(IReadOnlyList<MemberDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetMembers(Guid bandId)
    {
        var result = await bandService.GetMembersAsync(bandId, CurrentUserId);
        return Ok(result);
    }

    // POST /api/bands/{bandId}/Invitations  — Admin only (enforced in service)
    [HttpPost("invitations")]
    [ProducesResponseType(typeof(InvitationDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CreateInvitation(
        Guid bandId,
        [FromBody] CreateInvitationRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await bandService.CreateInvitationAsync(bandId, request, CurrentUserId);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/bands/{bandId}/Members/{userId}/Voices
    // Admin can set anyone's Voice; members can set their own
    [HttpPut("Members/{userId:guid}/Voices")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetUserVoices(
        Guid bandId,
        Guid userId,
        [FromBody] UserVoicesRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid voice input."));

        await bandService.SetUserVoicesAsync(bandId, userId, request, CurrentUserId);
        return NoContent();
    }

    // PUT /api/bands/{bandId}/Members/{userId}/rolle  — Admin only (enforced in service)
    [HttpPut("Members/{userId:guid}/rolle")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ChangeRole(
        Guid bandId,
        Guid userId,
        [FromBody] ChangeRoleRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid role."));

        await bandService.ChangeRoleAsync(bandId, userId, request, CurrentUserId);
        return NoContent();
    }

    // DELETE /api/bands/{bandId}/Members/{userId}
    // Admin can remove anyone; any member can remove themselves (leave)
    [HttpDelete("Members/{userId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveMember(Guid bandId, Guid userId)
    {
        await bandService.RemoveMemberAsync(bandId, userId, CurrentUserId);
        return NoContent();
    }
}
