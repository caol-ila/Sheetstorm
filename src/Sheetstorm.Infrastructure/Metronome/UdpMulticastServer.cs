using System.Net;
using System.Net.Sockets;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Sheetstorm.Domain.Metronome;

namespace Sheetstorm.Infrastructure.Metronome;

/// <summary>
/// UDP Multicast server for real-time beat synchronization.
///
/// Protocol (Little-Endian binary, per 2026-03-30-metronome-protocol.md):
///   0x00 = Heartbeat   (9 bytes):  type(1) + timestamp_us(8)
///   0x01 = ClockSync   (9/25 bytes): see protocol spec
///   0x02 = SessionStart (61 bytes): type(1)+sessionId(16)+bandId(16)+bpm(2)+bpm(1)+beatUnit(1)+startUs(8)+conductorId(16)
///   0x03 = SessionStop  (17 bytes): type(1)+sessionId(16)
///   0x04 = SessionUpdate(37 bytes): type(1)+sessionId(16)+bpm(2)+bpm(1)+beatUnit(1)+changeAtBeat(8)+newStartUs(8)
///
/// Multicast group and port are configurable via appsettings.json Metronome:Udp section.
/// ClockSync requests arrive via unicast on ClockSyncPort and are answered point-to-point.
/// </summary>
public class UdpMulticastServer(
    IOptions<MetronomeUdpOptions> options,
    IMetronomeSessionManager sessions,
    ILogger<UdpMulticastServer> logger) : BackgroundService
{
    private readonly MetronomeUdpOptions _opts = options.Value;
    private UdpClient? _multicastClient;
    private UdpClient? _syncClient;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var multicastGroup = IPAddress.Parse(_opts.MulticastGroup);
        var multicastEndpoint = new IPEndPoint(multicastGroup, _opts.Port);

        try
        {
            _multicastClient = new UdpClient();
            _multicastClient.JoinMulticastGroup(multicastGroup);

            _syncClient = new UdpClient(_opts.ClockSyncPort);

            logger.LogInformation(
                "UDP Metronome server started. Multicast: {Group}:{Port}, ClockSync: :{SyncPort}",
                _opts.MulticastGroup, _opts.Port, _opts.ClockSyncPort);

            // Start clock sync listener in background
            _ = ListenForClockSyncAsync(stoppingToken);

            // Heartbeat loop (transport detection probe)
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    var heartbeat = BuildHeartbeatPacket();
                    await _multicastClient.SendAsync(heartbeat, heartbeat.Length, multicastEndpoint);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    logger.LogWarning(ex, "Error sending UDP heartbeat.");
                }

                await Task.Delay(_opts.HeartbeatIntervalMs, stoppingToken);
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogError(ex, "UDP Multicast server fatal error.");
        }
        finally
        {
            _multicastClient?.Close();
            _syncClient?.Close();
        }
    }

    /// <summary>Send a SessionStart packet to the multicast group.</summary>
    public async Task SendSessionStartAsync(MetronomeSession session)
    {
        if (_multicastClient is null) return;

        var packet = BuildSessionStartPacket(session);
        var endpoint = new IPEndPoint(IPAddress.Parse(_opts.MulticastGroup), _opts.Port);
        await _multicastClient.SendAsync(packet, packet.Length, endpoint);

        logger.LogDebug("UDP SessionStart sent for band {BandId}, BPM={Bpm}", session.BandId, session.Bpm);
    }

    /// <summary>Send a SessionStop packet to the multicast group.</summary>
    public async Task SendSessionStopAsync(MetronomeSession session)
    {
        if (_multicastClient is null) return;

        var packet = BuildSessionStopPacket(session);
        var endpoint = new IPEndPoint(IPAddress.Parse(_opts.MulticastGroup), _opts.Port);
        await _multicastClient.SendAsync(packet, packet.Length, endpoint);

        logger.LogDebug("UDP SessionStop sent for session {SessionId}", session.SessionId);
    }

    /// <summary>Send a SessionUpdate packet to the multicast group.</summary>
    public async Task SendSessionUpdateAsync(MetronomeSession session, long changeAtBeatNumber)
    {
        if (_multicastClient is null) return;

        var packet = BuildSessionUpdatePacket(session, changeAtBeatNumber);
        var endpoint = new IPEndPoint(IPAddress.Parse(_opts.MulticastGroup), _opts.Port);
        await _multicastClient.SendAsync(packet, packet.Length, endpoint);

        logger.LogDebug("UDP SessionUpdate sent for band {BandId}, new BPM={Bpm}", session.BandId, session.Bpm);
    }

    // ── Packet builders ───────────────────────────────────────────────────────

    /// <summary>Heartbeat: type(0x00) + timestamp_us(int64) = 9 bytes</summary>
    private static byte[] BuildHeartbeatPacket()
    {
        var buf = new byte[9];
        buf[0] = 0x00;
        var ts = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;
        WriteInt64LE(buf, 1, ts);
        return buf;
    }

    /// <summary>SessionStart: type(0x02)+sessionId(16)+bandId(16)+bpm(2)+bpm(1)+beatUnit(1)+startUs(8)+conductorId(16) = 61 bytes</summary>
    private static byte[] BuildSessionStartPacket(MetronomeSession session)
    {
        var buf = new byte[61];
        buf[0] = 0x02;
        WriteGuidLE(buf, 1, session.SessionId);
        WriteGuidLE(buf, 17, session.BandId);
        WriteUInt16LE(buf, 33, (ushort)session.Bpm);
        buf[35] = (byte)session.BeatsPerMeasure;
        buf[36] = (byte)session.BeatUnit;
        WriteInt64LE(buf, 37, session.StartTimeUs);
        WriteGuidLE(buf, 45, session.ConductorId);
        return buf;
    }

    /// <summary>SessionStop: type(0x03) + sessionId(16) = 17 bytes</summary>
    private static byte[] BuildSessionStopPacket(MetronomeSession session)
    {
        var buf = new byte[17];
        buf[0] = 0x03;
        WriteGuidLE(buf, 1, session.SessionId);
        return buf;
    }

    /// <summary>SessionUpdate: type(0x04)+sessionId(16)+bpm(2)+bpm(1)+beatUnit(1)+changeAtBeat(8)+newStartUs(8) = 37 bytes</summary>
    private static byte[] BuildSessionUpdatePacket(MetronomeSession session, long changeAtBeatNumber)
    {
        var buf = new byte[37];
        buf[0] = 0x04;
        WriteGuidLE(buf, 1, session.SessionId);
        WriteUInt16LE(buf, 17, (ushort)session.Bpm);
        buf[19] = (byte)session.BeatsPerMeasure;
        buf[20] = (byte)session.BeatUnit;
        WriteInt64LE(buf, 21, changeAtBeatNumber);
        WriteInt64LE(buf, 29, session.StartTimeUs);
        return buf;
    }

    // ── Clock sync listener ───────────────────────────────────────────────────

    private async Task ListenForClockSyncAsync(CancellationToken ct)
    {
        if (_syncClient is null) return;

        while (!ct.IsCancellationRequested)
        {
            try
            {
                var received = await _syncClient.ReceiveAsync(ct);
                var data = received.Buffer;
                var clientEndpoint = received.RemoteEndPoint;

                if (data.Length < 9 || data[0] != 0x01) continue;

                var serverRecvTimeUs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;
                var clientSendTimeUs = ReadInt64LE(data, 1);

                // Build response: type(0x01)+clientSendUs(8)+serverRecvUs(8)+serverSendUs(8) = 25 bytes
                var response = new byte[25];
                response[0] = 0x01;
                WriteInt64LE(response, 1, clientSendTimeUs);
                WriteInt64LE(response, 9, serverRecvTimeUs);
                var serverSendTimeUs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;
                WriteInt64LE(response, 17, serverSendTimeUs);

                await _syncClient.SendAsync(response, response.Length, clientEndpoint);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Error in ClockSync listener.");
            }
        }
    }

    // ── Binary helpers ────────────────────────────────────────────────────────

    private static void WriteInt64LE(byte[] buf, int offset, long value)
    {
        var bytes = BitConverter.GetBytes(value);
        if (!BitConverter.IsLittleEndian) Array.Reverse(bytes);
        Array.Copy(bytes, 0, buf, offset, 8);
    }

    private static long ReadInt64LE(byte[] buf, int offset)
    {
        var bytes = buf[offset..(offset + 8)];
        if (!BitConverter.IsLittleEndian) Array.Reverse(bytes);
        return BitConverter.ToInt64(bytes);
    }

    private static void WriteUInt16LE(byte[] buf, int offset, ushort value)
    {
        var bytes = BitConverter.GetBytes(value);
        if (!BitConverter.IsLittleEndian) Array.Reverse(bytes);
        Array.Copy(bytes, 0, buf, offset, 2);
    }

    private static void WriteGuidLE(byte[] buf, int offset, Guid guid)
    {
        var bytes = guid.ToByteArray(); // already in mixed-endian per .NET convention
        Array.Copy(bytes, 0, buf, offset, 16);
    }

    public override void Dispose()
    {
        _multicastClient?.Dispose();
        _syncClient?.Dispose();
        base.Dispose();
        GC.SuppressFinalize(this);
    }
}
