namespace Sheetstorm.Domain.Metronome;

// ── Session State (ephemeral, in-memory) ─────────────────────────────────────

public record MetronomeSession(
    Guid SessionId,
    Guid BandId,
    int Bpm,
    int BeatsPerMeasure,
    int BeatUnit,
    long StartTimeUs,
    Guid ConductorId,
    string ConductorName,
    DateTime StartedAt
);

// ── REST DTOs ─────────────────────────────────────────────────────────────────

public record StartMetronomeRequest(int Bpm, int BeatsPerMeasure, int BeatUnit);

public record UpdateMetronomeRequest(int Bpm, int BeatsPerMeasure, int BeatUnit);

public record MetronomeStatusResponse(
    bool IsRunning,
    Guid? SessionId,
    int Bpm,
    int BeatsPerMeasure,
    int BeatUnit,
    string? ConductorName,
    int ConnectedClients,
    long StartTimeUs
);

public record ClockSyncRequest(long ClientSendTimeUs);

public record ClockSyncResponse(long ClientSendTimeUs, long ServerRecvTimeUs, long ServerSendTimeUs);

// ── SignalR Hub Messages (Server → Client) ────────────────────────────────────

public record SessionStartedMessage(
    Guid SessionId,
    Guid BandId,
    int Bpm,
    int BeatsPerMeasure,
    int BeatUnit,
    long StartTimeUs,
    Guid ConductorId,
    string ConductorName
);

public record SessionStoppedMessage(Guid SessionId, Guid BandId);

public record SessionUpdatedMessage(
    Guid SessionId,
    Guid BandId,
    int Bpm,
    int BeatsPerMeasure,
    int BeatUnit,
    long ChangeAtBeatNumber,
    long NewStartTimeUs
);

public record MetronomeClockSyncResponseMessage(
    long ClientSendTimeUs,
    long ServerRecvTimeUs,
    long ServerSendTimeUs
);

public record MetronomeParticipantCountChangedMessage(Guid BandId, int Count);
