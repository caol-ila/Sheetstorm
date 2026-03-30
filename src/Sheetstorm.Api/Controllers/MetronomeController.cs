using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Metronome;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/v1/bands/{bandId}/metronome")]
[Authorize]
public class MetronomeController(AppDbContext db, IMetronomeSessionManager sessions) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    private string CurrentUserName =>
        User.FindFirstValue("name") ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? "Unknown";

    private async Task<Membership?> GetMembershipAsync(Guid bandId, Guid userId, CancellationToken ct) =>
        await db.Memberships.FirstOrDefaultAsync(
            m => m.BandId == bandId && m.MusicianId == userId && m.IsActive, ct);

    // ── GET /api/v1/bands/{bandId}/metronome/status ────────────────────────

    [HttpGet("status")]
    [ProducesResponseType(typeof(MetronomeStatusResponse), StatusCodes.Status200OK)]
    public Task<IActionResult> GetStatus(Guid bandId, CancellationToken ct)
    {
        var session = sessions.GetSession(bandId);
        var clientCount = sessions.GetClientCount(bandId);

        var response = session is null
            ? new MetronomeStatusResponse(false, null, 0, 0, 0, null, 0, 0)
            : new MetronomeStatusResponse(
                true, session.SessionId, session.Bpm,
                session.BeatsPerMeasure, session.BeatUnit,
                session.ConductorName, clientCount, session.StartTimeUs);

        return Task.FromResult<IActionResult>(Ok(response));
    }

    // ── POST /api/v1/bands/{bandId}/metronome/start ────────────────────────

    [HttpPost("start")]
    [ProducesResponseType(typeof(MetronomeStatusResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Start(Guid bandId, [FromBody] StartMetronomeRequest request, CancellationToken ct)
    {
        if (request.Bpm is < 20 or > 300)
            return BadRequest(new { error = "INVALID_BPM", message = "BPM must be between 20 and 300." });

        var membership = await GetMembershipAsync(bandId, CurrentUserId, ct);
        if (membership is null)
            return Forbid();

        if (membership.Role is not (MemberRole.Administrator or MemberRole.Conductor))
            return Forbid();

        var session = sessions.StartSession(
            bandId, request.Bpm, request.BeatsPerMeasure, request.BeatUnit,
            CurrentUserId, CurrentUserName);

        if (session is null)
            return Conflict(new { error = "SESSION_ACTIVE", message = "A metronome session is already active for this band." });

        return Ok(new MetronomeStatusResponse(
            true, session.SessionId, session.Bpm, session.BeatsPerMeasure,
            session.BeatUnit, session.ConductorName, 0, session.StartTimeUs));
    }

    // ── POST /api/v1/bands/{bandId}/metronome/stop ────────────────────────

    [HttpPost("stop")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Stop(Guid bandId, CancellationToken ct)
    {
        var membership = await GetMembershipAsync(bandId, CurrentUserId, ct);
        if (membership is null)
            return Forbid();

        if (membership.Role is not (MemberRole.Administrator or MemberRole.Conductor))
            return Forbid();

        if (!sessions.StopSession(bandId, out _))
            return NotFound(new { error = "NO_SESSION", message = "No active metronome session for this band." });

        return NoContent();
    }

    // ── POST /api/v1/bands/{bandId}/metronome/sync ────────────────────────

    [HttpPost("sync")]
    [ProducesResponseType(typeof(ClockSyncResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Sync(Guid bandId, [FromBody] ClockSyncRequest request, CancellationToken ct)
    {
        var membership = await GetMembershipAsync(bandId, CurrentUserId, ct);
        if (membership is null)
            return Forbid();

        var serverRecvTimeUs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;
        var serverSendTimeUs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;

        return Ok(new ClockSyncResponse(request.ClientSendTimeUs, serverRecvTimeUs, serverSendTimeUs));
    }
}
