using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ShiftPlanConfiguration : IEntityTypeConfiguration<ShiftPlan>
{
    public void Configure(EntityTypeBuilder<ShiftPlan> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.Title)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(s => s.Description)
            .HasMaxLength(500);

        builder.HasOne(s => s.Band)
            .WithMany()
            .HasForeignKey(s => s.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.Event)
            .WithMany()
            .HasForeignKey(s => s.EventId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(s => s.CreatedByMusician)
            .WithMany()
            .HasForeignKey(s => s.CreatedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(s => s.Shifts)
            .WithOne(sh => sh.ShiftPlan)
            .HasForeignKey(sh => sh.ShiftPlanId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(s => s.BandId);
    }
}
