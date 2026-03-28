using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class MusicianConfiguration : IEntityTypeConfiguration<Musician>
{
    public void Configure(EntityTypeBuilder<Musician> builder)
    {
        builder.HasKey(m => m.Id);

        builder.Property(m => m.Email)
            .IsRequired()
            .HasMaxLength(256);

        builder.HasIndex(m => m.Email)
            .IsUnique();

        builder.Property(m => m.Name)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(m => m.PasswordHash)
            .IsRequired();

        builder.Property(m => m.Instrument)
            .HasMaxLength(100);

        builder.Property(m => m.PasswordResetToken)
            .HasMaxLength(128);

        builder.HasIndex(m => m.PasswordResetToken)
            .IsUnique()
            .HasFilter("\"PasswordResetToken\" IS NOT NULL");
    }
}
