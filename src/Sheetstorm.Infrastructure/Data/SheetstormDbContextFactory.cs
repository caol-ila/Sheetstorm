using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Sheetstorm.Infrastructure.Data;

public class SheetstormDbContextFactory : IDesignTimeDbContextFactory<SheetstormDbContext>
{
    public SheetstormDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<SheetstormDbContext>();
        optionsBuilder.UseNpgsql("Host=localhost;Database=sheetstorm_design;Username=postgres;Password=postgres");
        return new SheetstormDbContext(optionsBuilder.Options);
    }
}
