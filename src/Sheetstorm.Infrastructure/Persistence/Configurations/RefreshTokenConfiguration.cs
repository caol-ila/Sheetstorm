using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        builder.HasKey(rt => rt.Id);

        builder.Property(rt => rt.Token)
            .IsRequired()
            .HasMaxLength(128);

        builder.HasIndex(rt => rt.Token)
            .IsUnique();

        builder.HasIndex(rt => rt.FamilyId);

        builder.Property(rt => rt.ExpiresAt).IsRequired();

        builder.HasOne(rt => rt.Musician)
            .WithMany(m => m.RefreshTokens)
            .HasForeignKey(rt => rt.MusicianId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
