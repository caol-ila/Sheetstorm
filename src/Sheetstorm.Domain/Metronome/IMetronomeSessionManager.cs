namespace Sheetstorm.Domain.Metronome;

public interface IMetronomeSessionManager
{
    /// <summary>Start a new session for a band. Returns null if a session already exists.</summary>
    MetronomeSession? StartSession(
        Guid bandId, int bpm, int beatsPerMeasure, int beatUnit,
        Guid conductorId, string conductorName);

    /// <summary>Stop and remove the session for a band. Returns true if a session existed.</summary>
    bool StopSession(Guid bandId, out MetronomeSession? stopped);

    /// <summary>Update BPM/time signature during a running session. Returns null if no session.</summary>
    MetronomeSession? UpdateSession(Guid bandId, int bpm, int beatsPerMeasure, int beatUnit);

    /// <summary>Get the current session, or null if none.</summary>
    MetronomeSession? GetSession(Guid bandId);

    /// <summary>Register a connection to a band's session. Returns updated count.</summary>
    int AddClient(Guid bandId, string connectionId);

    /// <summary>Unregister a connection. Returns updated count.</summary>
    int RemoveClient(Guid bandId, string connectionId);

    /// <summary>Get the number of connected clients for a band.</summary>
    int GetClientCount(Guid bandId);
}
