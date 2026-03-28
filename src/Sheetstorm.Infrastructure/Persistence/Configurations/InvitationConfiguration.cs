using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class InvitationConfiguration : IEntityTypeConfiguration<Invitation>
{
    public void Configure(EntityTypeBuilder<Invitation> builder)
    {
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Code)
            .IsRequired()
            .HasMaxLength(20);

        builder.HasIndex(e => e.Code)
            .IsUnique();

        builder.HasOne(e => e.CreatedBy)
            .WithMany()
            .HasForeignKey(e => e.CreatedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(e => e.RedeemedBy)
            .WithMany()
            .HasForeignKey(e => e.RedeemedByMusicianId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.SetNull);

        // Band side configured in BandConfiguration
    }
}
