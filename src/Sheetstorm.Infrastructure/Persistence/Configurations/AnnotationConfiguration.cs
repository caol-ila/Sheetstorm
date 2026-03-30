using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class AnnotationConfiguration : IEntityTypeConfiguration<Annotation>
{
    public void Configure(EntityTypeBuilder<Annotation> builder)
    {
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Level)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.Property(a => a.Version)
            .HasDefaultValue(1L);

        builder.HasOne(a => a.PiecePage)
            .WithMany()
            .HasForeignKey(a => a.PiecePageId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(a => a.Voice)
            .WithMany()
            .HasForeignKey(a => a.VoiceId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(a => a.Band)
            .WithMany()
            .HasForeignKey(a => a.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(a => a.CreatedByMusician)
            .WithMany()
            .HasForeignKey(a => a.CreatedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(a => a.Elements)
            .WithOne(e => e.Annotation)
            .HasForeignKey(e => e.AnnotationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(a => new { a.PiecePageId, a.Level, a.VoiceId, a.BandId });
    }
}
