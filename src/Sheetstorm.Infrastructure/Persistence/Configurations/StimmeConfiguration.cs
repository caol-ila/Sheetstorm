using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class StimmeConfiguration : IEntityTypeConfiguration<Stimme>
{
    public void Configure(EntityTypeBuilder<Stimme> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.Bezeichnung)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(s => s.Instrument)
            .HasMaxLength(100);

        builder.Property(s => s.InstrumentTyp)
            .HasMaxLength(50);

        builder.Property(s => s.InstrumentFamilie)
            .HasMaxLength(50);

        // Unique Stimme label per Stück
        builder.HasIndex(s => new { s.StueckID, s.Bezeichnung }).IsUnique();

        // Performance index for fallback algorithm
        builder.HasIndex(s => new { s.StueckID, s.InstrumentTyp, s.StimmenNummer });

        builder.HasOne(s => s.Stueck)
            .WithMany(st => st.Stimmen)
            .HasForeignKey(s => s.StueckID)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
