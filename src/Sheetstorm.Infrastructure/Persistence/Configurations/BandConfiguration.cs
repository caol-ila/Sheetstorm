using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class BandConfiguration : IEntityTypeConfiguration<Band>
{
    public void Configure(EntityTypeBuilder<Band> builder)
    {
        builder.HasKey(k => k.Id);

        builder.Property(k => k.Name)
            .IsRequired()
            .HasMaxLength(80);

        builder.Property(k => k.Description)
            .HasMaxLength(500);

        builder.Property(k => k.Location)
            .HasMaxLength(100);

        builder.Property(k => k.LogoUrl)
            .HasMaxLength(512);

        builder.HasMany(k => k.Members)
            .WithOne(m => m.Band)
            .HasForeignKey(m => m.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(k => k.Invitationen)
            .WithOne(e => e.Band)
            .HasForeignKey(e => e.BandId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
