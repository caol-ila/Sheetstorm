namespace Sheetstorm.Domain.SongBroadcast;

// ── Broadcast State ───────────────────────────────────────────────────────────

public record CurrentSongInfo(
    Guid PieceId,
    string Title,
    DateTime ChangedAt
);

public record BroadcastState(
    Guid BandId,
    Guid ConductorId,
    string ConductorName,
    bool IsActive,
    CurrentSongInfo? CurrentSong,
    int ParticipantCount,
    DateTime StartedAt
);

// ── Hub Messages (Server → Client) ───────────────────────────────────────────

public record BroadcastStartedMessage(
    Guid BandId,
    Guid ConductorId,
    string ConductorName,
    DateTime StartedAt
);

public record SongChangedMessage(
    Guid BandId,
    Guid PieceId,
    string Title,
    DateTime ChangedAt
);

public record BroadcastStoppedMessage(
    Guid BandId,
    Guid StoppedById,
    string StoppedByName,
    DateTime StoppedAt
);

public record ParticipantCountChangedMessage(
    Guid BandId,
    int Count
);

// ── Hub Messages (Client → Server) ───────────────────────────────────────────

public record JoinBroadcastRequest(
    Guid BandId
);

public record SetCurrentSongRequest(
    Guid BandId,
    Guid PieceId
);

public record StopBroadcastRequest(
    Guid BandId
);
