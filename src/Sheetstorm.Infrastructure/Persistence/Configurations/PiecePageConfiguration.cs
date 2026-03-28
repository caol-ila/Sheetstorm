using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class PiecePageConfiguration : IEntityTypeConfiguration<PiecePage>
{
    public void Configure(EntityTypeBuilder<PiecePage> builder)
    {
        builder.HasKey(p => p.Id);

        builder.Property(p => p.StorageKey)
            .IsRequired()
            .HasMaxLength(1024);

        builder.Property(p => p.OcrText)
            .HasColumnType("text");

        // Unique constraint: one page number per Stück
        builder.HasIndex(p => new { p.PieceId, p.PageNumber })
            .IsUnique();
    }
}
