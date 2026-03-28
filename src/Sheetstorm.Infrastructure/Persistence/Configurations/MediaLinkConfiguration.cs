using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class MediaLinkConfiguration : IEntityTypeConfiguration<MediaLink>
{
    public void Configure(EntityTypeBuilder<MediaLink> builder)
    {
        builder.HasKey(m => m.Id);

        builder.Property(m => m.Url)
            .IsRequired()
            .HasMaxLength(2048);

        builder.Property(m => m.Type)
            .HasConversion<string>()
            .HasMaxLength(30)
            .IsRequired();

        builder.Property(m => m.Title)
            .HasMaxLength(200);

        builder.Property(m => m.Description)
            .HasMaxLength(500);

        builder.Property(m => m.ThumbnailUrl)
            .HasMaxLength(2048);

        builder.HasOne(m => m.Piece)
            .WithMany()
            .HasForeignKey(m => m.PieceId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(m => m.Band)
            .WithMany()
            .HasForeignKey(m => m.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(m => m.AddedByMusician)
            .WithMany()
            .HasForeignKey(m => m.AddedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(m => new { m.PieceId, m.Url })
            .IsUnique();
    }
}
