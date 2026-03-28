using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Infrastructure.Import;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/kapellen/{kapelleId:guid}")]
[Authorize]
public class ImportController(IImportService importService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // POST /api/kapellen/{kapelleId}/import
    [HttpPost("import")]
    [ProducesResponseType(typeof(ImportResultDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [RequestSizeLimit(50 * 1024 * 1024)] // 50 MB
    public async Task<IActionResult> Import(
        Guid kapelleId,
        IFormFile file,
        CancellationToken ct)
    {
        if (file is null || file.Length == 0)
            return BadRequest(new ErrorResponse("NO_FILE", "Keine Datei hochgeladen."));

        var allowedTypes = new[] { "application/pdf", "image/png", "image/jpeg", "image/tiff" };
        if (!allowedTypes.Contains(file.ContentType, StringComparer.OrdinalIgnoreCase))
            return BadRequest(new ErrorResponse("INVALID_FILE_TYPE", "Nur PDF, PNG, JPEG und TIFF Dateien sind erlaubt."));

        await using var stream = file.OpenReadStream();

        var result = await importService.ImportAsync(
            stream,
            file.FileName,
            file.ContentType,
            kapelleId,
            CurrentUserId,
            ct);

        return StatusCode(StatusCodes.Status201Created, result);
    }
}
