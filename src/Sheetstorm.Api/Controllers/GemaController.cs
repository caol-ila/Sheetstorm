using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Gema;
using Sheetstorm.Infrastructure.Gema;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/gema-reports")]
[Authorize]
public class GemaController(IGemaService gemaService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/bands/{bandId}/gema-reports
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<GemaReportSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetReports(
        Guid bandId,
        [FromQuery] GemaReportStatus? status,
        CancellationToken ct)
    {
        var result = await gemaService.GetReportsAsync(bandId, CurrentUserId, status, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/gema-reports/{id}
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(GemaReportDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetReport(Guid bandId, Guid id, CancellationToken ct)
    {
        var result = await gemaService.GetReportAsync(bandId, id, CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/bands/{bandId}/gema-reports
    [HttpPost]
    [ProducesResponseType(typeof(GemaReportDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateReport(
        Guid bandId,
        [FromBody] CreateGemaReportRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await gemaService.CreateReportAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // POST /api/bands/{bandId}/gema-reports/from-setlist/{setlistId}
    [HttpPost("from-setlist/{setlistId:guid}")]
    [ProducesResponseType(typeof(GemaReportDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GenerateFromSetlist(
        Guid bandId,
        Guid setlistId,
        [FromBody] CreateGemaReportRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await gemaService.GenerateFromSetlistAsync(bandId, setlistId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/bands/{bandId}/gema-reports/{id}
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(GemaReportDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> UpdateReport(
        Guid bandId,
        Guid id,
        [FromBody] UpdateGemaReportRequest request,
        CancellationToken ct)
    {
        var result = await gemaService.UpdateReportAsync(bandId, id, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/bands/{bandId}/gema-reports/{id}
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> DeleteReport(Guid bandId, Guid id, CancellationToken ct)
    {
        await gemaService.DeleteReportAsync(bandId, id, CurrentUserId, ct);
        return NoContent();
    }

    // POST /api/bands/{bandId}/gema-reports/{id}/entries
    [HttpPost("{id:guid}/entries")]
    [ProducesResponseType(typeof(GemaReportEntryDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> AddEntry(
        Guid bandId,
        Guid id,
        [FromBody] AddGemaReportEntryRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await gemaService.AddEntryAsync(bandId, id, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/bands/{bandId}/gema-reports/{reportId}/entries/{entryId}
    [HttpPut("{reportId:guid}/entries/{entryId:guid}")]
    [ProducesResponseType(typeof(GemaReportEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> UpdateEntry(
        Guid bandId,
        Guid reportId,
        Guid entryId,
        [FromBody] UpdateGemaReportEntryRequest request,
        CancellationToken ct)
    {
        var result = await gemaService.UpdateEntryAsync(bandId, reportId, entryId, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/bands/{bandId}/gema-reports/{reportId}/entries/{entryId}
    [HttpDelete("{reportId:guid}/entries/{entryId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> DeleteEntry(
        Guid bandId,
        Guid reportId,
        Guid entryId,
        CancellationToken ct)
    {
        await gemaService.DeleteEntryAsync(bandId, reportId, entryId, CurrentUserId, ct);
        return NoContent();
    }

    // POST /api/bands/{bandId}/gema-reports/{id}/finalize
    [HttpPost("{id:guid}/finalize")]
    [ProducesResponseType(typeof(GemaReportDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> FinalizeReport(Guid bandId, Guid id, CancellationToken ct)
    {
        var result = await gemaService.FinalizeReportAsync(bandId, id, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/gema-reports/{id}/export?format=csv|xml
    [HttpGet("{id:guid}/export")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ExportReport(
        Guid bandId,
        Guid id,
        [FromQuery] string? format,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(format))
            return BadRequest(new ErrorResponse("INVALID_FORMAT", "Query parameter 'format' is required (csv, xml)."));

        var data = await gemaService.ExportReportAsync(bandId, id, format, CurrentUserId, ct);

        var contentType = format.ToLowerInvariant() switch
        {
            "csv" => "text/csv",
            "xml" => "application/xml",
            _ => "application/octet-stream"
        };

        return File(data, contentType, $"GEMA_Report_{id}.{format.ToLowerInvariant()}");
    }
}
