using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class PostConfiguration : IEntityTypeConfiguration<Post>
{
    public void Configure(EntityTypeBuilder<Post> builder)
    {
        builder.HasKey(p => p.Id);

        builder.Property(p => p.Title)
            .IsRequired()
            .HasMaxLength(120);

        builder.Property(p => p.Content)
            .IsRequired()
            .HasMaxLength(5000);

        builder.Property(p => p.Category)
            .HasMaxLength(50);

        builder.Property(p => p.IsPinned)
            .IsRequired();

        builder.HasOne(p => p.Band)
            .WithMany()
            .HasForeignKey(p => p.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(p => p.AuthorMusician)
            .WithMany()
            .HasForeignKey(p => p.AuthorMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(p => p.Comments)
            .WithOne(c => c.Post)
            .HasForeignKey(c => c.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(p => p.Reactions)
            .WithOne(r => r.Post)
            .HasForeignKey(r => r.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(p => new { p.BandId, p.IsPinned, p.CreatedAt });
    }
}
