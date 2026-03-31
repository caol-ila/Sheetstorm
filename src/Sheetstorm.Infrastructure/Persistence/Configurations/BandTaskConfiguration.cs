using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class BandTaskConfiguration : IEntityTypeConfiguration<BandTask>
{
    public void Configure(EntityTypeBuilder<BandTask> builder)
    {
        builder.HasKey(t => t.Id);

        builder.Property(t => t.Title)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(t => t.Description)
            .HasMaxLength(2000);

        builder.Property(t => t.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.Property(t => t.Priority)
            .HasConversion<string>()
            .HasMaxLength(10);

        builder.HasOne(t => t.Band)
            .WithMany()
            .HasForeignKey(t => t.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(t => t.CreatedByMusician)
            .WithMany()
            .HasForeignKey(t => t.CreatedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(t => t.Event)
            .WithMany()
            .HasForeignKey(t => t.EventId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(t => t.Assignments)
            .WithOne(a => a.BandTask)
            .HasForeignKey(a => a.BandTaskId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(t => t.BandId);
        builder.HasIndex(t => new { t.BandId, t.Status });
    }
}

public class BandTaskAssignmentConfiguration : IEntityTypeConfiguration<BandTaskAssignment>
{
    public void Configure(EntityTypeBuilder<BandTaskAssignment> builder)
    {
        builder.HasKey(a => a.Id);

        builder.HasOne(a => a.Musician)
            .WithMany()
            .HasForeignKey(a => a.MusicianId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(a => new { a.BandTaskId, a.MusicianId }).IsUnique();
    }
}
