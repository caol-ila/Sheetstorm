using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Infrastructure.BandManagement;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands")]
[Authorize]
public class BandController(IBandService bandService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/bands
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<BandDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyBands()
    {
        var result = await bandService.GetMyBandsAsync(CurrentUserId);
        return Ok(result);
    }

    // POST /api/bands
    [HttpPost]
    [ProducesResponseType(typeof(BandDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateBand([FromBody] CreateBandRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await bandService.CreateBandAsync(request, CurrentUserId);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // GET /api/bands/{id}
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(BandDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetBand(Guid id)
    {
        var result = await bandService.GetBandAsync(id, CurrentUserId);
        return Ok(result);
    }

    // PUT /api/bands/{id}  — Admin only (enforced in service)
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(BandDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateBand(Guid id, [FromBody] UpdateBandRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await bandService.UpdateBandAsync(id, request, CurrentUserId);
        return Ok(result);
    }

    // DELETE /api/bands/{id}  — Admin only (enforced in service)
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteBand(Guid id)
    {
        await bandService.DeleteBandAsync(id, CurrentUserId);
        return NoContent();
    }

    // GET /api/bands/{id}/Voices-mapping — any member
    [HttpGet("{id:guid}/Voices-mapping")]
    [ProducesResponseType(typeof(VoiceMappingResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetVoiceMapping(Guid id)
    {
        var result = await bandService.GetVoiceMappingAsync(id, CurrentUserId);
        return Ok(result);
    }

    // PUT /api/bands/{id}/Voices-mapping — Admin only
    [HttpPut("{id:guid}/Voices-mapping")]
    [ProducesResponseType(typeof(VoiceMappingResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetVoiceMapping(Guid id, [FromBody] SetVoiceMappingRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid voice mapping data."));

        var result = await bandService.SetVoiceMappingAsync(id, request, CurrentUserId);
        return Ok(result);
    }

    // POST /api/bands/beitreten
    [HttpPost("join")]
    [ProducesResponseType(typeof(BandDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Join([FromBody] JoinRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid invitation code."));

        var result = await bandService.JoinAsync(request, CurrentUserId);
        return Ok(result);
    }
}
