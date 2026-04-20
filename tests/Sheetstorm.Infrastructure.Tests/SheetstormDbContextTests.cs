using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Infrastructure.Data;

namespace Sheetstorm.Infrastructure.Tests;

public class SheetstormDbContextTests
{
    [Fact]
    public void SheetstormDbContext_CanBeCreated()
    {
        // Arrange
        var options = new DbContextOptionsBuilder<SheetstormDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        // Act
        using var context = new SheetstormDbContext(options);

        // Assert
        context.Should().NotBeNull();
        context.Bands.Should().NotBeNull();
    }
}
