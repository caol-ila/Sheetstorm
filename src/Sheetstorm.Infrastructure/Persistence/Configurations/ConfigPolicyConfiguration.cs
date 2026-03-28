using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ConfigPolicyConfiguration : IEntityTypeConfiguration<ConfigPolicy>
{
    public void Configure(EntityTypeBuilder<ConfigPolicy> builder)
    {
        builder.HasKey(p => p.Id);

        builder.Property(p => p.Key)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(p => p.Value)
            .IsRequired()
            .HasColumnType("jsonb");

        builder.HasIndex(p => new { p.BandId, p.Key })
            .IsUnique();

        builder.HasOne(p => p.Band)
            .WithMany()
            .HasForeignKey(p => p.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(p => p.UpdatedBy)
            .WithMany()
            .HasForeignKey(p => p.UpdatedById)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
