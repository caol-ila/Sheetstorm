using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class KapelleConfiguration : IEntityTypeConfiguration<Kapelle>
{
    public void Configure(EntityTypeBuilder<Kapelle> builder)
    {
        builder.HasKey(k => k.Id);

        builder.Property(k => k.Name)
            .IsRequired()
            .HasMaxLength(80);

        builder.Property(k => k.Beschreibung)
            .HasMaxLength(500);

        builder.Property(k => k.Ort)
            .HasMaxLength(100);

        builder.Property(k => k.LogoUrl)
            .HasMaxLength(512);

        builder.HasMany(k => k.Mitglieder)
            .WithOne(m => m.Kapelle)
            .HasForeignKey(m => m.KapelleID)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(k => k.Einladungen)
            .WithOne(e => e.Kapelle)
            .HasForeignKey(e => e.KapelleID)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
