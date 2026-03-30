using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class GemaReportEntryConfiguration : IEntityTypeConfiguration<GemaReportEntry>
{
    public void Configure(EntityTypeBuilder<GemaReportEntry> builder)
    {
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Title)
            .IsRequired()
            .HasMaxLength(300);

        builder.Property(e => e.Composer)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(e => e.Arranger)
            .HasMaxLength(200);

        builder.Property(e => e.Publisher)
            .HasMaxLength(200);

        builder.Property(e => e.WorkNumber)
            .HasMaxLength(20);

        builder.HasOne(e => e.GemaReport)
            .WithMany(r => r.Entries)
            .HasForeignKey(e => e.GemaReportId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(e => e.Piece)
            .WithMany()
            .HasForeignKey(e => e.PieceId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(e => new { e.GemaReportId, e.Position })
            .IsUnique();
    }
}
