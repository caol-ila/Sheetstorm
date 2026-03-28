using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Configuration;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Helpers;

/// <summary>
/// WebApplicationFactory that replaces PostgreSQL with an in-memory database
/// and provides valid JWT configuration for integration testing.
/// </summary>
public class SheetstormWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = TestJwtConfig.Key,
                ["Jwt:Issuer"] = TestJwtConfig.Issuer,
                ["Jwt:Audience"] = TestJwtConfig.Audience,
                // Satisfy the null-guard in DependencyInjection.cs; actual connection unused
                ["ConnectionStrings:DefaultConnection"] = "Host=test;Database=test;Username=test;Password=test"
            });
        });

        builder.ConfigureServices(services =>
        {
            // Remove the Npgsql DbContextOptions registered by AddInfrastructure
            services.RemoveAll<DbContextOptions<AppDbContext>>();
            services.RemoveAll<AppDbContext>();

            // Re-register with an isolated in-memory database
            services.AddDbContext<AppDbContext>(options =>
                options.UseInMemoryDatabase("IntegrationTestDb-" + Guid.NewGuid()));
        });
    }
}
