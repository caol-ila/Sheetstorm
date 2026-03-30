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

// ── BLE Security ─────────────────────────────────────────────────────────────

/// <summary>BLE session key info for HMAC-SHA256 message signing.</summary>
public record BleSessionInfo(
    string SessionKey,      // Base64-encoded 256-bit key
    string LeaderDeviceId,  // Device ID of the conductor
    DateTime ExpiresAt      // Key expiration (max 4 hours)
);

/// <summary>Extended broadcast state with BLE security info.</summary>
public record BroadcastStateWithBle(
    Guid BandId,
    Guid ConductorId,
    string ConductorName,
    bool IsActive,
    CurrentSongInfo? CurrentSong,
    int ParticipantCount,
    DateTime StartedAt,
    BleSessionInfo? BleSession
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
