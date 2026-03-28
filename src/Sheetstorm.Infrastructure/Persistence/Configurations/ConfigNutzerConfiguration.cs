using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ConfigNutzerConfiguration : IEntityTypeConfiguration<ConfigNutzer>
{
    public void Configure(EntityTypeBuilder<ConfigNutzer> builder)
    {
        builder.HasKey(c => c.Id);

        builder.Property(c => c.Schluessel)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(c => c.Wert)
            .IsRequired()
            .HasColumnType("jsonb");

        builder.Property(c => c.Version)
            .IsRequired()
            .HasDefaultValue(1L);

        builder.HasIndex(c => new { c.MusikerId, c.Schluessel })
            .IsUnique();

        builder.HasOne(c => c.Musiker)
            .WithMany()
            .HasForeignKey(c => c.MusikerId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
