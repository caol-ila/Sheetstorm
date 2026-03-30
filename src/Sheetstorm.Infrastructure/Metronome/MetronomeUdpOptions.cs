namespace Sheetstorm.Infrastructure.Metronome;

public class MetronomeUdpOptions
{
    public string MulticastGroup { get; set; } = "239.255.77.77";
    public int Port { get; set; } = 5100;
    public int ClockSyncPort { get; set; } = 5101;
    public int HeartbeatIntervalMs { get; set; } = 500;
}
