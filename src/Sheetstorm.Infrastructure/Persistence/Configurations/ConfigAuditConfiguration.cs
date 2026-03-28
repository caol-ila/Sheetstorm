using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ConfigAuditConfiguration : IEntityTypeConfiguration<ConfigAudit>
{
    public void Configure(EntityTypeBuilder<ConfigAudit> builder)
    {
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Ebene)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(a => a.Schluessel)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(a => a.AlterWert)
            .HasColumnType("jsonb");

        builder.Property(a => a.NeuerWert)
            .HasColumnType("jsonb");

        builder.Property(a => a.Zeitstempel)
            .IsRequired();

        builder.HasIndex(a => new { a.KapelleId, a.Zeitstempel })
            .IsDescending(false, true);

        builder.HasIndex(a => new { a.MusikerId, a.Zeitstempel })
            .IsDescending(false, true);

        // No navigation properties — audit is append-only, no cascade deletes
    }
}
