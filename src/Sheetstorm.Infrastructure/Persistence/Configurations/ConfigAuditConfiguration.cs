using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ConfigAuditConfiguration : IEntityTypeConfiguration<ConfigAudit>
{
    public void Configure(EntityTypeBuilder<ConfigAudit> builder)
    {
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Level)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(a => a.Key)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(a => a.OldValue)
            .HasColumnType("jsonb");

        builder.Property(a => a.NewValue)
            .HasColumnType("jsonb");

        builder.Property(a => a.Timestamp)
            .IsRequired();

        builder.HasIndex(a => new { a.BandId, a.Timestamp })
            .IsDescending(false, true);

        builder.HasIndex(a => new { a.MusicianId, a.Timestamp })
            .IsDescending(false, true);

        // No navigation properties — audit is append-only, no cascade deletes
    }
}
