using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class SyncChangelogConfiguration : IEntityTypeConfiguration<SyncChangelog>
{
    public void Configure(EntityTypeBuilder<SyncChangelog> builder)
    {
        builder.HasKey(c => c.Id);

        builder.Property(c => c.EntityType)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(c => c.Operation)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(c => c.FieldName)
            .HasMaxLength(100);

        builder.HasOne(c => c.Musician)
            .WithMany()
            .HasForeignKey(c => c.MusicianId)
            .OnDelete(DeleteBehavior.Cascade);

        // Efficient index for pull queries: WHERE musician_id = ? AND version > ?
        builder.HasIndex(c => new { c.MusicianId, c.Version });

        // Efficient index for LWW conflict detection: WHERE musician_id = ? AND entity_id = ? AND field_name = ?
        builder.HasIndex(c => new { c.MusicianId, c.EntityId, c.FieldName });
    }
}
