using Microsoft.EntityFrameworkCore;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Helpers;

public static class TestDbContextFactory
{
    /// <summary>Creates an isolated in-memory AppDbContext for each test run.</summary>
    public static AppDbContext Create()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }
}
