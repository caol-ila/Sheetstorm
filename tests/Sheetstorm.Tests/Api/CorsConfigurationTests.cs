using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Sheetstorm.Tests.Api;

public class CorsConfigurationTests
{
    // ── Development: AllowAnyOrigin ───────────────────────────────────────────

    [Fact]
    public async Task CorsPolicy_Development_AllowsAnyOrigin()
    {
        using var factory = new SheetstormWebApplicationFactory();
        using var client = factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });

        using var request = new HttpRequestMessage(HttpMethod.Get, "/health");
        request.Headers.Add("Origin", "https://example.com");

        var response = await client.SendAsync(request);

        Assert.True(
            response.Headers.Contains("Access-Control-Allow-Origin"),
            "Development CORS policy should allow any origin");
    }

    // ── Production: configured origins only ──────────────────────────────────

    [Fact]
    public async Task CorsPolicy_Production_AllowsConfiguredOrigin()
    {
        const string allowedOrigin = "https://sheetstorm.app";
        using var factory = new ProductionCorsWebApplicationFactory(allowedOrigin);
        using var client = factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });

        using var request = new HttpRequestMessage(HttpMethod.Get, "/health");
        request.Headers.Add("Origin", allowedOrigin);

        var response = await client.SendAsync(request);

        Assert.True(
            response.Headers.Contains("Access-Control-Allow-Origin"),
            "Production CORS policy should allow the configured origin");
    }

    [Fact]
    public async Task CorsPolicy_Production_BlocksUnknownOrigin()
    {
        using var factory = new ProductionCorsWebApplicationFactory("https://sheetstorm.app");
        using var client = factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });

        using var request = new HttpRequestMessage(HttpMethod.Get, "/health");
        request.Headers.Add("Origin", "https://attacker.com");

        var response = await client.SendAsync(request);

        Assert.False(
            response.Headers.Contains("Access-Control-Allow-Origin"),
            "Production CORS policy should block origins that are not configured");
    }
}
