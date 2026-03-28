using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class EventConfiguration : IEntityTypeConfiguration<Event>
{
    public void Configure(EntityTypeBuilder<Event> builder)
    {
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Title)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(e => e.Description)
            .HasMaxLength(1000);

        builder.Property(e => e.EventType)
            .HasConversion<string>()
            .HasMaxLength(30);

        builder.Property(e => e.Location)
            .HasMaxLength(200);

        builder.Property(e => e.RepeatRule)
            .HasMaxLength(100);

        builder.Property(e => e.Notes)
            .HasMaxLength(500);

        builder.Property(e => e.DressCode)
            .HasMaxLength(100);

        builder.Property(e => e.MeetingPoint)
            .HasMaxLength(200);

        builder.HasOne(e => e.Band)
            .WithMany()
            .HasForeignKey(e => e.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(e => e.Setlist)
            .WithMany()
            .HasForeignKey(e => e.SetlistId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(e => e.CreatedByMusician)
            .WithMany()
            .HasForeignKey(e => e.CreatedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(e => e.Rsvps)
            .WithOne(r => r.Event)
            .HasForeignKey(r => r.EventId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(e => new { e.BandId, e.StartDate });
    }
}
