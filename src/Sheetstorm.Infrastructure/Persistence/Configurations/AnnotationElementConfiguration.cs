using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class AnnotationElementConfiguration : IEntityTypeConfiguration<AnnotationElement>
{
    public void Configure(EntityTypeBuilder<AnnotationElement> builder)
    {
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Tool)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.Property(e => e.Points)
            .HasColumnType("jsonb");

        builder.Property(e => e.Text)
            .HasMaxLength(200);

        builder.Property(e => e.StampCategory)
            .HasMaxLength(50);

        builder.Property(e => e.StampValue)
            .HasMaxLength(50);

        builder.Property(e => e.Opacity)
            .HasDefaultValue(1.0);

        builder.Property(e => e.StrokeWidth)
            .HasDefaultValue(3.0);

        builder.Property(e => e.Version)
            .HasDefaultValue(1L);

        builder.Property(e => e.IsDeleted)
            .HasDefaultValue(false);

        builder.HasOne(e => e.CreatedByMusician)
            .WithMany()
            .HasForeignKey(e => e.CreatedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(e => e.AnnotationId);
    }
}
