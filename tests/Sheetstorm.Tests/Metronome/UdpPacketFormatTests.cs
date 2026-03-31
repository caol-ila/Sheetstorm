using System.Net;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using NSubstitute;
using Sheetstorm.Domain.Metronome;
using Sheetstorm.Infrastructure.Metronome;

namespace Sheetstorm.Tests.Metronome;

public class UdpPacketFormatTests
{
    // Access packet-building via reflection since they're private static helpers.
    // We verify packet sizes and content structure per the protocol spec.

    private static byte[] InvokePacketBuilder(string methodName, params object[] args)
    {
        var method = typeof(UdpMulticastServer).GetMethod(
            methodName,
            System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);

        Assert.NotNull(method);
        if (method is null) throw new InvalidOperationException($"Method {methodName} not found on UdpMulticastServer.");
        var result = method!.Invoke(null, args);
        Assert.NotNull(result);
        return (byte[])result!;
    }

    private static MetronomeSession CreateTestSession(int bpm = 120, int beatsPerMeasure = 4, int beatUnit = 4)
    {
        return new MetronomeSession(
            SessionId: Guid.NewGuid(),
            BandId: Guid.NewGuid(),
            Bpm: bpm,
            BeatsPerMeasure: beatsPerMeasure,
            BeatUnit: beatUnit,
            StartTimeUs: DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L,
            ConductorId: Guid.NewGuid(),
            ConductorName: "Test",
            StartedAt: DateTime.UtcNow
        );
    }

    // ── Heartbeat Packet ──────────────────────────────────────────────────────

    [Fact]
    public void HeartbeatPacket_Is9Bytes()
    {
        var packet = InvokePacketBuilder("BuildHeartbeatPacket");

        Assert.Equal(9, packet.Length);
    }

    [Fact]
    public void HeartbeatPacket_HasCorrectType()
    {
        var packet = InvokePacketBuilder("BuildHeartbeatPacket");

        Assert.Equal(0x00, packet[0]);
    }

    [Fact]
    public void HeartbeatPacket_TimestampIsNonZero()
    {
        var packet = InvokePacketBuilder("BuildHeartbeatPacket");

        // bytes 1-8 = int64 timestamp
        var ts = BitConverter.ToInt64(packet, 1);
        if (!BitConverter.IsLittleEndian) ts = System.Net.IPAddress.NetworkToHostOrder(ts);
        Assert.True(ts > 0);
    }

    // ── SessionStart Packet ───────────────────────────────────────────────────

    [Fact]
    public void SessionStartPacket_Is61Bytes()
    {
        var session = CreateTestSession();
        var packet = InvokePacketBuilder("BuildSessionStartPacket", session);

        Assert.Equal(61, packet.Length);
    }

    [Fact]
    public void SessionStartPacket_HasCorrectType()
    {
        var session = CreateTestSession();
        var packet = InvokePacketBuilder("BuildSessionStartPacket", session);

        Assert.Equal(0x02, packet[0]);
    }

    [Fact]
    public void SessionStartPacket_BpmEncodedAtOffset33()
    {
        var session = CreateTestSession(bpm: 150);
        var packet = InvokePacketBuilder("BuildSessionStartPacket", session);

        // BPM at offset 33, uint16 LE
        var encodedBpm = BitConverter.ToUInt16(packet, 33);
        if (!BitConverter.IsLittleEndian) encodedBpm = (ushort)System.Net.IPAddress.NetworkToHostOrder((short)encodedBpm);
        Assert.Equal((ushort)150, encodedBpm);
    }

    [Fact]
    public void SessionStartPacket_BeatsPerMeasureAtOffset35()
    {
        var session = CreateTestSession(beatsPerMeasure: 3);
        var packet = InvokePacketBuilder("BuildSessionStartPacket", session);

        Assert.Equal(3, packet[35]);
    }

    [Fact]
    public void SessionStartPacket_BeatUnitAtOffset36()
    {
        var session = CreateTestSession(beatUnit: 8);
        var packet = InvokePacketBuilder("BuildSessionStartPacket", session);

        Assert.Equal(8, packet[36]);
    }

    // ── SessionStop Packet ────────────────────────────────────────────────────

    [Fact]
    public void SessionStopPacket_Is17Bytes()
    {
        var session = CreateTestSession();
        var packet = InvokePacketBuilder("BuildSessionStopPacket", session);

        Assert.Equal(17, packet.Length);
    }

    [Fact]
    public void SessionStopPacket_HasCorrectType()
    {
        var session = CreateTestSession();
        var packet = InvokePacketBuilder("BuildSessionStopPacket", session);

        Assert.Equal(0x03, packet[0]);
    }

    // ── SessionUpdate Packet ──────────────────────────────────────────────────

    [Fact]
    public void SessionUpdatePacket_Is37Bytes()
    {
        var session = CreateTestSession();
        var packet = InvokePacketBuilder("BuildSessionUpdatePacket", session, 42L);

        Assert.Equal(37, packet.Length);
    }

    [Fact]
    public void SessionUpdatePacket_HasCorrectType()
    {
        var session = CreateTestSession();
        var packet = InvokePacketBuilder("BuildSessionUpdatePacket", session, 0L);

        Assert.Equal(0x04, packet[0]);
    }

    [Fact]
    public void SessionUpdatePacket_NewBpmAtOffset17()
    {
        var session = CreateTestSession(bpm: 90);
        var packet = InvokePacketBuilder("BuildSessionUpdatePacket", session, 0L);

        var encodedBpm = BitConverter.ToUInt16(packet, 17);
        if (!BitConverter.IsLittleEndian) encodedBpm = (ushort)System.Net.IPAddress.NetworkToHostOrder((short)encodedBpm);
        Assert.Equal((ushort)90, encodedBpm);
    }

    // ── NTP Clock Sync Algorithm ──────────────────────────────────────────────

    [Fact]
    public void NtpOffset_WhenServerAheadByExactlyNetworkDelay_OffsetIsHalfRoundTrip()
    {
        // Scenario: symmetric latency of 10ms each way, server is 0ms ahead
        // T1=0, T2=10 (server recv), T3=10 (server send), T4=20 (client recv)
        long t1 = 0, t2 = 10, t3 = 10, t4 = 20;

        var roundTrip = (t4 - t1) - (t3 - t2);
        var offset = ((t2 - t1) + (t3 - t4)) / 2;

        Assert.Equal(20L, roundTrip); // 20ms total, 0ms processing time
        Assert.Equal(0L, offset);    // server is in sync with client
    }

    [Fact]
    public void NtpOffset_WhenServerIs10MsAhead_OffsetIsPositive10()
    {
        // Server is 10ms ahead of client. Symmetric 5ms latency.
        // Client sends at T1=0 (client time), Server receives at T2=15 (server time = client_time + 10 + 5)
        // Server sends at T3=15 (server time), Client receives at T4=10 (client time = server_time - 10 + 5)
        long t1 = 0, t2 = 15, t3 = 15, t4 = 10;

        var offset = ((t2 - t1) + (t3 - t4)) / 2;

        Assert.Equal(10L, offset); // server is 10ms ahead
    }
}
