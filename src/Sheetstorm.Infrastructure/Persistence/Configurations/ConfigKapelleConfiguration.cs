using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ConfigKapelleConfiguration : IEntityTypeConfiguration<ConfigKapelle>
{
    public void Configure(EntityTypeBuilder<ConfigKapelle> builder)
    {
        builder.HasKey(c => c.Id);

        builder.Property(c => c.Schluessel)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(c => c.Wert)
            .IsRequired()
            .HasColumnType("jsonb");

        builder.HasIndex(c => new { c.KapelleId, c.Schluessel })
            .IsUnique();

        builder.HasOne(c => c.Kapelle)
            .WithMany()
            .HasForeignKey(c => c.KapelleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.AktualisiertVon)
            .WithMany()
            .HasForeignKey(c => c.AktualisiertVonId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
