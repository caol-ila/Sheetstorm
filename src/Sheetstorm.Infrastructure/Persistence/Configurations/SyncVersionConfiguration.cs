using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class SyncVersionConfiguration : IEntityTypeConfiguration<SyncVersion>
{
    public void Configure(EntityTypeBuilder<SyncVersion> builder)
    {
        builder.HasKey(s => s.MusicianId);

        builder.Property(s => s.CurrentVersion)
            .IsRequired();

        builder.HasOne(s => s.Musician)
            .WithOne()
            .HasForeignKey<SyncVersion>(s => s.MusicianId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
