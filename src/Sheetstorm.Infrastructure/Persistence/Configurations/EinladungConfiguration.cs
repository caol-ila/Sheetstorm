using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class EinladungConfiguration : IEntityTypeConfiguration<Einladung>
{
    public void Configure(EntityTypeBuilder<Einladung> builder)
    {
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Code)
            .IsRequired()
            .HasMaxLength(20);

        builder.HasIndex(e => e.Code)
            .IsUnique();

        builder.HasOne(e => e.ErstelltVon)
            .WithMany()
            .HasForeignKey(e => e.ErstelltVonMusikerID)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(e => e.EingeloestVon)
            .WithMany()
            .HasForeignKey(e => e.EingeloestVonMusikerID)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.SetNull);

        // Kapelle side configured in KapelleConfiguration
    }
}
