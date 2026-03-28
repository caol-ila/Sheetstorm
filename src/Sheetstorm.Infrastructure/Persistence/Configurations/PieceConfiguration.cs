using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class PieceConfiguration : IEntityTypeConfiguration<Piece>
{
    public void Configure(EntityTypeBuilder<Piece> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.Title)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(s => s.Composer)
            .HasMaxLength(200);

        builder.Property(s => s.Arranger)
            .HasMaxLength(200);

        builder.Property(s => s.MusicalKey)
            .HasMaxLength(50);

        builder.Property(s => s.TimeSignature)
            .HasMaxLength(50);

        builder.Property(s => s.Description)
            .HasMaxLength(2000);

        builder.Property(s => s.OriginalFileName)
            .HasMaxLength(500);

        builder.Property(s => s.StorageKey)
            .HasMaxLength(1024);

        builder.Property(s => s.ImportStatus)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.HasOne(s => s.Band)
            .WithMany(k => k.Pieces)
            .HasForeignKey(s => s.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.Musician)
            .WithMany()
            .HasForeignKey(s => s.MusicianId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(s => s.Voices)
            .WithOne(st => st.Piece)
            .HasForeignKey(st => st.PieceId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(s => s.Pages)
            .WithOne(p => p.Piece)
            .HasForeignKey(p => p.PieceId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
