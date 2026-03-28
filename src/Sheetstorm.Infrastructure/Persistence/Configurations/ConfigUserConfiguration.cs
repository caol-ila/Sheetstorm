using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ConfigUserConfiguration : IEntityTypeConfiguration<ConfigUser>
{
    public void Configure(EntityTypeBuilder<ConfigUser> builder)
    {
        builder.HasKey(c => c.Id);

        builder.Property(c => c.Key)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(c => c.Value)
            .IsRequired()
            .HasColumnType("jsonb");

        builder.Property(c => c.Version)
            .IsRequired()
            .HasDefaultValue(1L);

        builder.HasIndex(c => new { c.MusicianId, c.Key })
            .IsUnique();

        builder.HasOne(c => c.Musician)
            .WithMany()
            .HasForeignKey(c => c.MusicianId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
