using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ConfigPolicyConfiguration : IEntityTypeConfiguration<ConfigPolicy>
{
    public void Configure(EntityTypeBuilder<ConfigPolicy> builder)
    {
        builder.HasKey(p => p.Id);

        builder.Property(p => p.Schluessel)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(p => p.Wert)
            .IsRequired()
            .HasColumnType("jsonb");

        builder.HasIndex(p => new { p.KapelleId, p.Schluessel })
            .IsUnique();

        builder.HasOne(p => p.Kapelle)
            .WithMany()
            .HasForeignKey(p => p.KapelleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(p => p.AktualisiertVon)
            .WithMany()
            .HasForeignKey(p => p.AktualisiertVonId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
