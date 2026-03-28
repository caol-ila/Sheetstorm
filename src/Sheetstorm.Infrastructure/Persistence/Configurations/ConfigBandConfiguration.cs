using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ConfigBandConfiguration : IEntityTypeConfiguration<ConfigBand>
{
    public void Configure(EntityTypeBuilder<ConfigBand> builder)
    {
        builder.HasKey(c => c.Id);

        builder.Property(c => c.Key)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(c => c.Value)
            .IsRequired()
            .HasColumnType("jsonb");

        builder.HasIndex(c => new { c.BandId, c.Key })
            .IsUnique();

        builder.HasOne(c => c.Band)
            .WithMany()
            .HasForeignKey(c => c.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.UpdatedBy)
            .WithMany()
            .HasForeignKey(c => c.UpdatedById)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
