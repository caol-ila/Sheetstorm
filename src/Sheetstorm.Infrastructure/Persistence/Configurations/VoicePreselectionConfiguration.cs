using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class VoicePreselectionConfiguration : IEntityTypeConfiguration<VoicePreselection>
{
    public void Configure(EntityTypeBuilder<VoicePreselection> builder)
    {
        builder.HasKey(sv => sv.Id);

        builder.Property(sv => sv.VoiceLabel)
            .IsRequired()
            .HasMaxLength(100);

        // One default Voice per Musician + Band + Instrument
        builder.HasIndex(sv => new { sv.MusicianId, sv.BandId, sv.UserInstrumentID }).IsUnique();

        // Performance index for Band lookups
        builder.HasIndex(sv => new { sv.MusicianId, sv.BandId });

        builder.HasOne(sv => sv.Musician)
            .WithMany()
            .HasForeignKey(sv => sv.MusicianId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(sv => sv.Band)
            .WithMany()
            .HasForeignKey(sv => sv.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(sv => sv.UserInstrument)
            .WithMany(ni => ni.Preselections)
            .HasForeignKey(sv => sv.UserInstrumentID)
            .OnDelete(DeleteBehavior.NoAction);
    }
}
