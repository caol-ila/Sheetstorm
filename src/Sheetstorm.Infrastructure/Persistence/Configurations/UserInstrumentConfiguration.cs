using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class UserInstrumentConfiguration : IEntityTypeConfiguration<UserInstrument>
{
    public void Configure(EntityTypeBuilder<UserInstrument> builder)
    {
        builder.HasKey(ni => ni.Id);

        builder.Property(ni => ni.InstrumentType)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(ni => ni.InstrumentLabel)
            .IsRequired()
            .HasMaxLength(100);

        // Each instrument type only once per Musician
        builder.HasIndex(ni => new { ni.MusicianId, ni.InstrumentType }).IsUnique();

        // Performance index
        builder.HasIndex(ni => ni.MusicianId);

        builder.HasOne(ni => ni.Musician)
            .WithMany(m => m.UserInstruments)
            .HasForeignKey(ni => ni.MusicianId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
