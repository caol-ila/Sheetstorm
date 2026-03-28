using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class MitgliedschaftConfiguration : IEntityTypeConfiguration<Mitgliedschaft>
{
    public void Configure(EntityTypeBuilder<Mitgliedschaft> builder)
    {
        builder.HasKey(m => m.Id);

        // A Musiker can be member of a Kapelle only once
        builder.HasIndex(m => new { m.MusikerID, m.KapelleID })
            .IsUnique();

        builder.HasOne(m => m.Musiker)
            .WithMany(mu => mu.Mitgliedschaften)
            .HasForeignKey(m => m.MusikerID)
            .OnDelete(DeleteBehavior.Cascade);

        // Kapelle side configured in KapelleConfiguration
    }
}
