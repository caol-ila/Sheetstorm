using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Sheetstorm.ServiceDefaults;

public static class Extensions
{
    public static void AddServiceDefaults(this WebApplicationBuilder builder)
    {
        // TODO: Add Aspire ServiceDefaults (OpenTelemetry, Health-Checks, ServiceDiscovery, HttpResilience)
        // This requires Aspire.Hosting SDK installation

        // Basic logging configuration
        builder.Logging.AddConsole();
        builder.Logging.AddDebug();
    }
}
