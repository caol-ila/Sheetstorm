using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class GemaReportConfiguration : IEntityTypeConfiguration<GemaReport>
{
    public void Configure(EntityTypeBuilder<GemaReport> builder)
    {
        builder.HasKey(r => r.Id);

        builder.Property(r => r.Title)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(r => r.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.Property(r => r.ExportFormat)
            .HasMaxLength(20);

        builder.Property(r => r.EventLocation)
            .HasMaxLength(200);

        builder.Property(r => r.EventCategory)
            .HasMaxLength(50);

        builder.Property(r => r.Organizer)
            .HasMaxLength(200);

        builder.HasOne(r => r.Band)
            .WithMany()
            .HasForeignKey(r => r.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.Event)
            .WithMany()
            .HasForeignKey(r => r.EventId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(r => r.GeneratedByMusician)
            .WithMany()
            .HasForeignKey(r => r.GeneratedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.Setlist)
            .WithMany()
            .HasForeignKey(r => r.SetlistId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(r => r.Entries)
            .WithOne(e => e.GemaReport)
            .HasForeignKey(e => e.GemaReportId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => new { r.BandId, r.ReportDate });
    }
}
