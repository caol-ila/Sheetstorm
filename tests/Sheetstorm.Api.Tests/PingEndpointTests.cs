using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using Sheetstorm.Infrastructure.Data;
using Testcontainers.PostgreSql;

namespace Sheetstorm.Api.Tests;

public class PingEndpointTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgresContainer;
    private WebApplicationFactory<Program> _factory = null!;
    private HttpClient _client = null!;

    public PingEndpointTests()
    {
        _postgresContainer = new PostgreSqlBuilder()
            .WithImage("postgres:16-alpine")
            .WithDatabase("sheetstorm_test")
            .WithUsername("postgres")
            .WithPassword("postgres")
            .Build();
    }

    public async Task InitializeAsync()
    {
        await _postgresContainer.StartAsync();

        _factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    // Remove existing DbContext registration
                    services.RemoveAll<DbContextOptions<SheetstormDbContext>>();

                    // Add DbContext with Testcontainer connection string
                    services.AddDbContext<SheetstormDbContext>(options =>
                        options.UseNpgsql(_postgresContainer.GetConnectionString()));

                    // Ensure database is created
                    var sp = services.BuildServiceProvider();
                    using var scope = sp.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<SheetstormDbContext>();
                    db.Database.EnsureCreated();
                });
            });

        _client = _factory.CreateClient();
    }

    public async Task DisposeAsync()
    {
        _client?.Dispose();
        await _factory.DisposeAsync();
        await _postgresContainer.DisposeAsync();
    }

    [Fact]
    public async Task Ping_ReturnsOk_WithMessage()
    {
        // Act
        var response = await _client.GetAsync("/ping");

        // Assert
        response.Should().Be200Ok();
        var content = await response.Content.ReadAsStringAsync();
        content.Should().Contain("Hallo Blaskapelle");
    }
}
