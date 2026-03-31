using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace Sheetstorm.Tests;

/// <summary>
/// Default integration test factory — Development environment.
/// The app auto-selects InMemory DB when the connection string contains "CHANGE_ME".
/// </summary>
public class SheetstormWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Prevent HTTPS redirect so test HTTP requests go straight to the endpoint
        builder.UseSetting("HTTPS_PORT", "");
    }
}

/// <summary>
/// Integration test factory simulating a Production environment with explicit CORS origins.
/// </summary>
public class ProductionCorsWebApplicationFactory : WebApplicationFactory<Program>
{
    private readonly string[] _allowedOrigins;

    public ProductionCorsWebApplicationFactory(params string[] allowedOrigins)
    {
        _allowedOrigins = allowedOrigins;
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Production");
        builder.UseSetting("HTTPS_PORT", "");
        for (int i = 0; i < _allowedOrigins.Length; i++)
            builder.UseSetting($"Cors:AllowedOrigins:{i}", _allowedOrigins[i]);
    }
}
