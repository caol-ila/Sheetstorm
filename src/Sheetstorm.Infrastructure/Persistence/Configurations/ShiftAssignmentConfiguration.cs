using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ShiftAssignmentConfiguration : IEntityTypeConfiguration<ShiftAssignment>
{
    public void Configure(EntityTypeBuilder<ShiftAssignment> builder)
    {
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.Property(a => a.Notes)
            .HasMaxLength(200);

        builder.HasOne(a => a.Shift)
            .WithMany(s => s.Assignments)
            .HasForeignKey(a => a.ShiftId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(a => a.Musician)
            .WithMany()
            .HasForeignKey(a => a.MusicianId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(a => a.AssignedByMusician)
            .WithMany()
            .HasForeignKey(a => a.AssignedByMusicianId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(a => new { a.ShiftId, a.MusicianId })
            .IsUnique();
    }
}
