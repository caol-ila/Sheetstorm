using System.Globalization;
using System.Text;
using Sheetstorm.Domain.Events;

namespace Sheetstorm.Web.Application;

/// <summary>
/// Erzeugt ein iCalendar (RFC 5545) für die kommenden Termine eines Vereins.
/// Bewusst minimal — kein TZID, alle Zeiten in UTC ausgegeben.
/// </summary>
public static class ICalExporter
{
    public static string Build(string bandName, IEnumerable<Event> events)
    {
        var sb = new StringBuilder();
        sb.Append("BEGIN:VCALENDAR\r\n");
        sb.Append("VERSION:2.0\r\n");
        sb.Append($"PRODID:-//Sheetstorm//{Escape(bandName)}//DE\r\n");
        sb.Append("CALSCALE:GREGORIAN\r\n");
        sb.Append("METHOD:PUBLISH\r\n");
        foreach (var ev in events)
        {
            if (ev.Cancelled) continue;
            sb.Append("BEGIN:VEVENT\r\n");
            sb.Append($"UID:{ev.Id}@sheetstorm\r\n");
            sb.Append($"DTSTAMP:{Format(ev.CreatedAt)}\r\n");
            sb.Append($"DTSTART:{Format(ev.StartUtc)}\r\n");
            sb.Append($"DTEND:{Format(ev.EndUtc)}\r\n");
            sb.Append($"SUMMARY:{Escape($"{ev.Type}: {ev.Title}")}\r\n");
            if (!string.IsNullOrEmpty(ev.Location))
                sb.Append($"LOCATION:{Escape(ev.Location)}\r\n");
            if (!string.IsNullOrEmpty(ev.Description))
                sb.Append($"DESCRIPTION:{Escape(ev.Description)}\r\n");
            sb.Append("END:VEVENT\r\n");
        }
        sb.Append("END:VCALENDAR\r\n");
        return sb.ToString();
    }

    private static string Format(DateTimeOffset dt) => dt.UtcDateTime.ToString("yyyyMMdd'T'HHmmss'Z'", CultureInfo.InvariantCulture);

    private static string Escape(string s) => s
        .Replace("\\", "\\\\")
        .Replace(";", "\\;")
        .Replace(",", "\\,")
        .Replace("\r\n", "\\n")
        .Replace("\n", "\\n");
}
