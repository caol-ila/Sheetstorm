using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Musiker> Musiker => Set<Musiker>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Kapelle> Kapellen => Set<Kapelle>();
    public DbSet<Mitgliedschaft> Mitgliedschaften => Set<Mitgliedschaft>();
    public DbSet<Einladung> Einladungen => Set<Einladung>();
    public DbSet<Stueck> Stuecke => Set<Stueck>();
    public DbSet<Stimme> Stimmen => Set<Stimme>();
    public DbSet<Notenblatt> Notenblaetter => Set<Notenblatt>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        UpdateAuditFields();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void UpdateAuditFields()
    {
        var now = DateTime.UtcNow;
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            if (entry.State == EntityState.Added)
                entry.Entity.CreatedAt = now;
            if (entry.State is EntityState.Added or EntityState.Modified)
                entry.Entity.UpdatedAt = now;
        }
    }
}
