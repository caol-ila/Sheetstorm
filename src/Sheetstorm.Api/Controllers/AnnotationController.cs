using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Annotations;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Authorize]
public class AnnotationController(IAnnotationSyncService annotationService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // ── Band-scoped Annotations ──────────────────────────────────────────

    // GET /api/bands/{bandId}/annotations/{piecePageId}?level=Voice&voiceId={voiceId}
    [HttpGet("api/bands/{bandId:guid}/annotations/{piecePageId:guid}")]
    [ProducesResponseType(typeof(IReadOnlyList<AnnotationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAnnotations(
        Guid bandId, Guid piecePageId,
        [FromQuery] string level,
        [FromQuery] Guid? voiceId,
        CancellationToken ct)
    {
        var annotationLevel = Enum.Parse<AnnotationLevel>(level);
        var result = await annotationService.GetAnnotationsAsync(
            bandId, piecePageId, annotationLevel, voiceId, CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/bands/{bandId}/annotations/elements
    [HttpPost("api/bands/{bandId:guid}/annotations/elements")]
    [ProducesResponseType(typeof(AnnotationElementDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateElement(
        Guid bandId,
        [FromBody] CreateAnnotationElementRequest request,
        CancellationToken ct)
    {
        var result = await annotationService.CreateElementAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/bands/{bandId}/annotations/{annotationId}/elements/{elementId}
    [HttpPut("api/bands/{bandId:guid}/annotations/{annotationId:guid}/elements/{elementId:guid}")]
    [ProducesResponseType(typeof(AnnotationElementDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> UpdateElement(
        Guid bandId, Guid annotationId, Guid elementId,
        [FromBody] UpdateAnnotationElementRequest request,
        CancellationToken ct)
    {
        var result = await annotationService.UpdateElementAsync(
            bandId, annotationId, elementId, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/bands/{bandId}/annotations/{annotationId}/elements/{elementId}
    [HttpDelete("api/bands/{bandId:guid}/annotations/{annotationId:guid}/elements/{elementId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteElement(
        Guid bandId, Guid annotationId, Guid elementId,
        CancellationToken ct)
    {
        await annotationService.DeleteElementAsync(bandId, annotationId, elementId, CurrentUserId, ct);
        return NoContent();
    }

    // POST /api/bands/{bandId}/annotations/{piecePageId}/sync?level=Voice&voiceId={voiceId}&sinceVersion=42
    [HttpPost("api/bands/{bandId:guid}/annotations/{piecePageId:guid}/sync")]
    [ProducesResponseType(typeof(AnnotationSyncResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> SyncElements(
        Guid bandId, Guid piecePageId,
        [FromQuery] string level,
        [FromQuery] Guid? voiceId,
        [FromQuery] long sinceVersion,
        CancellationToken ct)
    {
        var annotationLevel = Enum.Parse<AnnotationLevel>(level);
        var result = await annotationService.SyncElementsAsync(
            bandId, piecePageId, annotationLevel, voiceId, sinceVersion, CurrentUserId, ct);
        return Ok(result);
    }

    // ── Personal Annotations (Private, no band scope) ────────────────────

    // GET /api/annotations/personal/{piecePageId}
    [HttpGet("api/annotations/personal/{piecePageId:guid}")]
    [ProducesResponseType(typeof(IReadOnlyList<AnnotationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPersonalAnnotations(
        Guid piecePageId, CancellationToken ct)
    {
        var result = await annotationService.GetPersonalAnnotationsAsync(piecePageId, CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/annotations/personal/{piecePageId}/elements
    [HttpPost("api/annotations/personal/{piecePageId:guid}/elements")]
    [ProducesResponseType(typeof(AnnotationElementDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreatePersonalElement(
        Guid piecePageId,
        [FromBody] CreateAnnotationElementRequest request,
        CancellationToken ct)
    {
        var result = await annotationService.CreatePersonalElementAsync(piecePageId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/annotations/personal/elements/{elementId}
    [HttpPut("api/annotations/personal/elements/{elementId:guid}")]
    [ProducesResponseType(typeof(AnnotationElementDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> UpdatePersonalElement(
        Guid elementId,
        [FromBody] UpdateAnnotationElementRequest request,
        CancellationToken ct)
    {
        var result = await annotationService.UpdatePersonalElementAsync(elementId, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/annotations/personal/elements/{elementId}
    [HttpDelete("api/annotations/personal/elements/{elementId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeletePersonalElement(
        Guid elementId, CancellationToken ct)
    {
        await annotationService.DeletePersonalElementAsync(elementId, CurrentUserId, ct);
        return NoContent();
    }
}
