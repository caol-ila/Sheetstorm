using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class MembershipConfiguration : IEntityTypeConfiguration<Membership>
{
    public void Configure(EntityTypeBuilder<Membership> builder)
    {
        builder.HasKey(m => m.Id);

        // A Musician can be member of a Band only once
        builder.HasIndex(m => new { m.MusicianId, m.BandId })
            .IsUnique();

        builder.HasOne(m => m.Musician)
            .WithMany(mu => mu.Membershipen)
            .HasForeignKey(m => m.MusicianId)
            .OnDelete(DeleteBehavior.Cascade);

        // Band side configured in BandConfiguration
    }
}
