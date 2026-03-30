using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class AttendanceRecordConfiguration : IEntityTypeConfiguration<AttendanceRecord>
{
    public void Configure(EntityTypeBuilder<AttendanceRecord> builder)
    {
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Date)
            .IsRequired();

        builder.Property(a => a.Status)
            .HasConversion<string>()
            .HasMaxLength(30)
            .IsRequired();

        builder.Property(a => a.Notes)
            .HasMaxLength(500);

        builder.HasOne(a => a.Band)
            .WithMany()
            .HasForeignKey(a => a.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(a => a.Musician)
            .WithMany()
            .HasForeignKey(a => a.MusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(a => a.RecordedByMusician)
            .WithMany()
            .HasForeignKey(a => a.RecordedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(a => new { a.BandId, a.MusicianId, a.Date });
        builder.HasIndex(a => new { a.BandId, a.Date });
    }
}
