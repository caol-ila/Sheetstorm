using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class VoiceConfiguration : IEntityTypeConfiguration<Voice>
{
    public void Configure(EntityTypeBuilder<Voice> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.Label)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(s => s.Instrument)
            .HasMaxLength(100);

        builder.Property(s => s.InstrumentType)
            .HasMaxLength(50);

        builder.Property(s => s.InstrumentFamily)
            .HasMaxLength(50);

        // Unique Voice label per Stück
        builder.HasIndex(s => new { s.PieceId, s.Label }).IsUnique();

        // Performance index for fallback algorithm
        builder.HasIndex(s => new { s.PieceId, s.InstrumentType, s.VoiceNumber });

        builder.HasOne(s => s.Piece)
            .WithMany(st => st.Voices)
            .HasForeignKey(s => s.PieceId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
