using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Api.Hubs;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.SongBroadcast;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/broadcast")]
[Authorize]
public class BroadcastController(AppDbContext db) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    /// <summary>
    /// Get BLE session key for an active broadcast. Requires band membership.
    /// Musicians call this before connecting via BLE to verify the conductor.
    /// </summary>
    [HttpGet("sessions/{bandId:guid}/ble-key")]
    [ProducesResponseType(typeof(BleSessionInfo), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetBleKey(Guid bandId)
    {
        var membership = await db.Set<Membership>()
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == CurrentUserId && m.IsActive);

        if (membership is null)
            return Forbid();

        var bleInfo = SongBroadcastHub.GetBleSessionInfoForBand(bandId);

        if (bleInfo is null)
            return NotFound(new { message = "No active broadcast session for this band." });

        return Ok(bleInfo);
    }
}
