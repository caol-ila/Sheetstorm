using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain;

namespace Sheetstorm.Infrastructure.Data;

public class SheetstormDbContext : DbContext
{
    public SheetstormDbContext(DbContextOptions<SheetstormDbContext> options) : base(options)
    {
    }

    public DbSet<Band> Bands => Set<Band>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
    }

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        base.ConfigureConventions(configurationBuilder);
    }
}
