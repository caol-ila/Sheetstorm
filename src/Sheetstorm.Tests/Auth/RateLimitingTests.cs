using System.Net;
using System.Net.Http.Json;
using Sheetstorm.Tests.Helpers;
using Xunit;

namespace Sheetstorm.Tests.Auth;

/// <summary>
/// Integration tests that verify the "auth" rate limiting policy:
/// 10 requests per 15-minute window per IP are permitted; the 11th is rejected with 429.
/// </summary>
public class RateLimitingTests
{
    [Fact]
    public async Task AuthEndpoint_First10Requests_AreNotRateLimited()
    {
        await using var factory = new SheetstormWebApplicationFactory();
        var client = factory.CreateClient();

        for (var i = 0; i < 10; i++)
        {
            var response = await client.PostAsJsonAsync(
                "/api/auth/login",
                new { email = "test@example.com", password = "whatever" });

            Assert.NotEqual(HttpStatusCode.TooManyRequests, response.StatusCode);
        }
    }

    [Fact]
    public async Task AuthEndpoint_EleventhRequest_IsRateLimitedWith429()
    {
        await using var factory = new SheetstormWebApplicationFactory();
        var client = factory.CreateClient();

        // Exhaust the 10-request allowance
        for (var i = 0; i < 10; i++)
        {
            await client.PostAsJsonAsync(
                "/api/auth/login",
                new { email = "test@example.com", password = "whatever" });
        }

        // 11th request must be rejected
        var eleventh = await client.PostAsJsonAsync(
            "/api/auth/login",
            new { email = "test@example.com", password = "whatever" });

        Assert.Equal(HttpStatusCode.TooManyRequests, (HttpStatusCode)eleventh.StatusCode);
    }

    [Fact]
    public async Task AuthEndpoint_RateLimitAppliesAcrossMultipleEndpoints()
    {
        // The "auth" policy covers /register, /login, /refresh, /forgot-password, /reset-password.
        // Mixed calls to different endpoints within the same window all count toward the limit.
        await using var factory = new SheetstormWebApplicationFactory();
        var client = factory.CreateClient();

        // Use different endpoints to exhaust 10 slots
        for (var i = 0; i < 5; i++)
        {
            await client.PostAsJsonAsync("/api/auth/login",
                new { email = "a@b.com", password = "x" });
            await client.PostAsJsonAsync("/api/auth/register",
                new { email = "a@b.com", password = "x", displayName = "x" });
        }

        // 11th call (any auth endpoint) must be rate limited
        var eleventh = await client.PostAsJsonAsync(
            "/api/auth/forgot-password",
            new { email = "a@b.com" });

        Assert.Equal(HttpStatusCode.TooManyRequests, (HttpStatusCode)eleventh.StatusCode);
    }
}
