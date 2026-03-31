using Sheetstorm.Domain.Metronome;
using Sheetstorm.Infrastructure.Metronome;

namespace Sheetstorm.Tests.Metronome;

public class MetronomeSessionManagerTests
{
    private IMetronomeSessionManager CreateSut() => new MetronomeSessionManager();

    private readonly Guid _bandId = Guid.NewGuid();
    private readonly Guid _conductorId = Guid.NewGuid();
    private const string ConductorName = "Hans Müller";

    // ── StartSession ──────────────────────────────────────────────────────────

    [Fact]
    public void StartSession_NewBand_ReturnsSession()
    {
        var sut = CreateSut();

        var session = sut.StartSession(_bandId, 120, 4, 4, _conductorId, ConductorName);

        Assert.NotNull(session);
        Assert.Equal(_bandId, session!.BandId);
        Assert.Equal(120, session.Bpm);
        Assert.Equal(4, session.BeatsPerMeasure);
        Assert.Equal(4, session.BeatUnit);
        Assert.Equal(_conductorId, session.ConductorId);
        Assert.Equal(ConductorName, session.ConductorName);
        Assert.NotEqual(Guid.Empty, session.SessionId);
    }

    [Fact]
    public void StartSession_StartTimeUs_IsInFuture()
    {
        var sut = CreateSut();
        var beforeUs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;

        var session = sut.StartSession(_bandId, 120, 4, 4, _conductorId, ConductorName);

        Assert.NotNull(session);
        Assert.True(session!.StartTimeUs > beforeUs, "StartTimeUs should be in the future (+100ms buffer)");
    }

    [Fact]
    public void StartSession_SessionAlreadyExists_ReturnsNull()
    {
        var sut = CreateSut();
        sut.StartSession(_bandId, 120, 4, 4, _conductorId, ConductorName);

        var second = sut.StartSession(_bandId, 100, 3, 4, Guid.NewGuid(), "Other");

        Assert.Null(second);
    }

    [Fact]
    public void StartSession_DifferentBands_BothSucceed()
    {
        var sut = CreateSut();
        var band2 = Guid.NewGuid();

        var s1 = sut.StartSession(_bandId, 120, 4, 4, _conductorId, ConductorName);
        var s2 = sut.StartSession(band2, 80, 3, 4, Guid.NewGuid(), "Other");

        Assert.NotNull(s1);
        Assert.NotNull(s2);
        Assert.NotEqual(s1!.SessionId, s2!.SessionId);
    }

    // ── StopSession ───────────────────────────────────────────────────────────

    [Fact]
    public void StopSession_ExistingSession_ReturnsTrueAndSession()
    {
        var sut = CreateSut();
        var started = sut.StartSession(_bandId, 120, 4, 4, _conductorId, ConductorName)!;

        var result = sut.StopSession(_bandId, out var stopped);

        Assert.True(result);
        Assert.NotNull(stopped);
        Assert.Equal(started.SessionId, stopped!.SessionId);
    }

    [Fact]
    public void StopSession_NoSession_ReturnsFalse()
    {
        var sut = CreateSut();

        var result = sut.StopSession(_bandId, out var stopped);

        Assert.False(result);
        Assert.Null(stopped);
    }

    [Fact]
    public void StopSession_AfterStop_GetSessionReturnsNull()
    {
        var sut = CreateSut();
        sut.StartSession(_bandId, 120, 4, 4, _conductorId, ConductorName);
        sut.StopSession(_bandId, out _);

        Assert.Null(sut.GetSession(_bandId));
    }

    // ── UpdateSession ─────────────────────────────────────────────────────────

    [Fact]
    public void UpdateSession_ExistingSession_UpdatesBpmAndTimeSignature()
    {
        var sut = CreateSut();
        sut.StartSession(_bandId, 120, 4, 4, _conductorId, ConductorName);

        var updated = sut.UpdateSession(_bandId, 90, 3, 4);

        Assert.NotNull(updated);
        Assert.Equal(90, updated!.Bpm);
        Assert.Equal(3, updated.BeatsPerMeasure);
        Assert.Equal(4, updated.BeatUnit);
    }

    [Fact]
    public void UpdateSession_ExistingSession_PreservesSessionId()
    {
        var sut = CreateSut();
        var original = sut.StartSession(_bandId, 120, 4, 4, _conductorId, ConductorName)!;

        var updated = sut.UpdateSession(_bandId, 90, 3, 4);

        Assert.Equal(original.SessionId, updated!.SessionId);
    }

    [Fact]
    public void UpdateSession_NoSession_ReturnsNull()
    {
        var sut = CreateSut();

        var result = sut.UpdateSession(_bandId, 90, 3, 4);

        Assert.Null(result);
    }

    // ── GetSession ────────────────────────────────────────────────────────────

    [Fact]
    public void GetSession_ExistingSession_ReturnsIt()
    {
        var sut = CreateSut();
        sut.StartSession(_bandId, 120, 4, 4, _conductorId, ConductorName);

        var session = sut.GetSession(_bandId);

        Assert.NotNull(session);
        Assert.Equal(_bandId, session!.BandId);
    }

    [Fact]
    public void GetSession_NoSession_ReturnsNull()
    {
        var sut = CreateSut();

        Assert.Null(sut.GetSession(Guid.NewGuid()));
    }

    // ── Client tracking ───────────────────────────────────────────────────────

    [Fact]
    public void AddClient_SingleClient_ReturnsOne()
    {
        var sut = CreateSut();

        var count = sut.AddClient(_bandId, "conn-1");

        Assert.Equal(1, count);
    }

    [Fact]
    public void AddClient_MultipleClients_ReturnsCorrectCount()
    {
        var sut = CreateSut();

        sut.AddClient(_bandId, "conn-1");
        var count = sut.AddClient(_bandId, "conn-2");

        Assert.Equal(2, count);
    }

    [Fact]
    public void RemoveClient_ExistingClient_DecreasesCount()
    {
        var sut = CreateSut();
        sut.AddClient(_bandId, "conn-1");
        sut.AddClient(_bandId, "conn-2");

        var count = sut.RemoveClient(_bandId, "conn-1");

        Assert.Equal(1, count);
    }

    [Fact]
    public void RemoveClient_NonExistentClient_ReturnsZero()
    {
        var sut = CreateSut();

        var count = sut.RemoveClient(_bandId, "non-existent");

        Assert.Equal(0, count);
    }

    [Fact]
    public void GetClientCount_NoClients_ReturnsZero()
    {
        var sut = CreateSut();

        Assert.Equal(0, sut.GetClientCount(_bandId));
    }

    [Fact]
    public void GetClientCount_AfterAddAndRemove_ReturnsCorrect()
    {
        var sut = CreateSut();
        sut.AddClient(_bandId, "conn-1");
        sut.AddClient(_bandId, "conn-2");
        sut.RemoveClient(_bandId, "conn-1");

        Assert.Equal(1, sut.GetClientCount(_bandId));
    }

    // ── Clock Sync calculation ────────────────────────────────────────────────

    [Fact]
    public void ClockSyncOffset_NtpCalculation_IsCorrect()
    {
        // NTP offset formula: offset = ((T2 - T1) + (T3 - T4)) / 2
        long t1 = 1000L; // client send
        long t2 = 1010L; // server recv
        long t3 = 1015L; // server send
        long t4 = 1030L; // client recv

        // roundTrip = (T4 - T1) - (T3 - T2) = (1030 - 1000) - (1015 - 1010) = 30 - 5 = 25
        // offset = ((T2 - T1) + (T3 - T4)) / 2 = ((1010 - 1000) + (1015 - 1030)) / 2 = (10 + -15) / 2 = -2 (approx -3 rounded)
        var roundTrip = (t4 - t1) - (t3 - t2);
        var offset = ((t2 - t1) + (t3 - t4)) / 2;

        Assert.Equal(25L, roundTrip);
        Assert.Equal(-2L, offset); // server is slightly behind client
    }

    [Fact]
    public void ClockSyncOffset_SymmetricLatency_OffsetIsZero()
    {
        // With perfectly symmetric latency, offset should be 0
        long t1 = 1000L;
        long t2 = 1010L; // server recv: +10ms
        long t3 = 1010L; // server send: instant
        long t4 = 1020L; // client recv: +10ms

        var offset = ((t2 - t1) + (t3 - t4)) / 2;

        Assert.Equal(0L, offset);
    }
}
