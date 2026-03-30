using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class ShiftConfiguration : IEntityTypeConfiguration<Shift>
{
    public void Configure(EntityTypeBuilder<Shift> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.Name)
            .IsRequired()
            .HasMaxLength(80);

        builder.Property(s => s.Description)
            .HasMaxLength(200);

        builder.HasOne(s => s.ShiftPlan)
            .WithMany(sp => sp.Shifts)
            .HasForeignKey(s => s.ShiftPlanId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.Voice)
            .WithMany()
            .HasForeignKey(s => s.VoiceId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(s => s.Assignments)
            .WithOne(a => a.Shift)
            .HasForeignKey(a => a.ShiftId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(s => s.ShiftPlanId);
    }
}
