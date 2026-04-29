using System.Diagnostics;
using System.Diagnostics.Metrics;

namespace Sheetstorm.Web.Application;

/// <summary>
/// Zentrale ActivitySource + Meter für Sheetstorm-spezifisches Tracing in OTel.
/// Wird in ServiceDefaults via `tracing.AddSource("Sheetstorm.*")` aufgenommen
/// → alle Spans landen im Aspire-Dashboard.
/// </summary>
public static class SheetstormTelemetry
{
    public const string SourceName = "Sheetstorm.App";
    public const string MeterName = "Sheetstorm.App";

    public static readonly ActivitySource Activity = new(SourceName, "1.0.0");
    public static readonly Meter Meter = new(MeterName, "1.0.0");

    // Counters für Audiveris
    public static readonly Counter<long> AudiverisStarted =
        Meter.CreateCounter<long>("sheetstorm.audiveris.started", description: "Anzahl gestarteter Audiveris-Erkennungs-Jobs");
    public static readonly Counter<long> AudiverisCompleted =
        Meter.CreateCounter<long>("sheetstorm.audiveris.completed", description: "Anzahl erfolgreicher Audiveris-Erkennungen");
    public static readonly Counter<long> AudiverisFailed =
        Meter.CreateCounter<long>("sheetstorm.audiveris.failed", description: "Anzahl fehlgeschlagener Audiveris-Erkennungen");
    public static readonly Histogram<double> AudiverisDurationSeconds =
        Meter.CreateHistogram<double>("sheetstorm.audiveris.duration_seconds", unit: "s", description: "Audiveris-Erkennungsdauer pro Job");
}
