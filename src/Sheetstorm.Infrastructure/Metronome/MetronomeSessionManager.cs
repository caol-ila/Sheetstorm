using System.Collections.Concurrent;
using Sheetstorm.Domain.Metronome;

namespace Sheetstorm.Infrastructure.Metronome;

/// <summary>
/// Thread-safe, ephemeral in-memory session store for metronome sessions.
/// Registered as Singleton so all hub connections share the same state.
/// </summary>
public class MetronomeSessionManager : IMetronomeSessionManager
{
    private readonly ConcurrentDictionary<Guid, MetronomeSession> _sessions = new();
    private readonly ConcurrentDictionary<Guid, ConcurrentDictionary<string, string>> _connections = new();

    public MetronomeSession? StartSession(
        Guid bandId, int bpm, int beatsPerMeasure, int beatUnit,
        Guid conductorId, string conductorName)
    {
        if (_sessions.ContainsKey(bandId))
            return null;

        // First beat is +100ms in the future so all clients can sync before it fires
        var startTimeUs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L + 100_000L;

        var session = new MetronomeSession(
            SessionId: Guid.NewGuid(),
            BandId: bandId,
            Bpm: bpm,
            BeatsPerMeasure: beatsPerMeasure,
            BeatUnit: beatUnit,
            StartTimeUs: startTimeUs,
            ConductorId: conductorId,
            ConductorName: conductorName,
            StartedAt: DateTime.UtcNow
        );

        return _sessions.TryAdd(bandId, session) ? session : null;
    }

    public bool StopSession(Guid bandId, out MetronomeSession? stopped)
    {
        if (_sessions.TryRemove(bandId, out stopped))
        {
            _connections.TryRemove(bandId, out _);
            return true;
        }

        stopped = null;
        return false;
    }

    public MetronomeSession? UpdateSession(Guid bandId, int bpm, int beatsPerMeasure, int beatUnit)
    {
        if (!_sessions.TryGetValue(bandId, out var existing))
            return null;

        // Recalculate start time relative to new BPM — clients use the start time + BPM to compute beats
        var updated = existing with
        {
            Bpm = bpm,
            BeatsPerMeasure = beatsPerMeasure,
            BeatUnit = beatUnit
        };

        _sessions[bandId] = updated;
        return updated;
    }

    public MetronomeSession? GetSession(Guid bandId) =>
        _sessions.TryGetValue(bandId, out var session) ? session : null;

    public int AddClient(Guid bandId, string connectionId)
    {
        var conns = _connections.GetOrAdd(bandId, _ => new ConcurrentDictionary<string, string>());
        conns[connectionId] = connectionId;
        return conns.Count;
    }

    public int RemoveClient(Guid bandId, string connectionId)
    {
        if (!_connections.TryGetValue(bandId, out var conns))
            return 0;

        conns.TryRemove(connectionId, out _);
        return conns.Count;
    }

    public int GetClientCount(Guid bandId) =>
        _connections.TryGetValue(bandId, out var conns) ? conns.Count : 0;
}
