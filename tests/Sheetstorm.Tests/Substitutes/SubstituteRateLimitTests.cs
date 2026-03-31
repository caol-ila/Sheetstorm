using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Sheetstorm.Tests.Substitutes;

/// <summary>
/// Integration tests for substitute-token-validation rate limiting.
/// Each test class instance creates its own factory so rate-limiter state is isolated.
/// xUnit instantiates a new class per test, giving every test a fresh counter.
/// </summary>
public class SubstituteRateLimitTests : IDisposable
{
    private readonly SheetstormWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public SubstituteRateLimitTests()
    {
        _factory = new SheetstormWebApplicationFactory();
        _client = _factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
        GC.SuppressFinalize(this);
    }

    [Fact]
    public async Task ValidateToken_WithinLimit_Returns200()
    {
        // First 10 requests should not be blocked by the rate limiter.
        // The service returns 404 (unknown token), but never 429.
        for (int i = 0; i < 10; i++)
        {
            var response = await _client.GetAsync("/api/substitute/test-token");
            Assert.NotEqual(HttpStatusCode.TooManyRequests, response.StatusCode);
        }
    }

    [Fact]
    public async Task ValidateToken_ExceedsRateLimit_Returns429()
    {
        // Exhaust the per-minute quota (10 requests)
        for (int i = 0; i < 10; i++)
            await _client.GetAsync("/api/substitute/test-token");

        // 11th request must be rate-limited
        var response = await _client.GetAsync("/api/substitute/test-token");
        Assert.Equal(HttpStatusCode.TooManyRequests, response.StatusCode);
    }
}
