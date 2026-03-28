using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class SetlistEntryConfiguration : IEntityTypeConfiguration<SetlistEntry>
{
    public void Configure(EntityTypeBuilder<SetlistEntry> builder)
    {
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Position)
            .IsRequired();

        builder.Property(e => e.IsPlaceholder)
            .IsRequired();

        builder.Property(e => e.PlaceholderTitle)
            .HasMaxLength(150);

        builder.Property(e => e.PlaceholderComposer)
            .HasMaxLength(100);

        builder.Property(e => e.Notes)
            .HasMaxLength(250);

        builder.HasOne(e => e.Setlist)
            .WithMany(s => s.Entries)
            .HasForeignKey(e => e.SetlistId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(e => e.Piece)
            .WithMany()
            .HasForeignKey(e => e.PieceId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(e => new { e.SetlistId, e.Position });
    }
}
