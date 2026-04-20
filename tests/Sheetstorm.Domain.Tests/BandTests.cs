using FluentAssertions;
using Sheetstorm.Domain;

namespace Sheetstorm.Domain.Tests;

public class BandTests
{
    [Fact]
    public void Band_CanBeCreated_WithNameAndId()
    {
        // Arrange & Act
        var band = new Band { Id = Guid.NewGuid(), Name = "Testkapelle" };

        // Assert
        band.Should().NotBeNull();
        band.Id.Should().NotBeEmpty();
        band.Name.Should().Be("Testkapelle");
    }
}
