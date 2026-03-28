using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class PostReactionConfiguration : IEntityTypeConfiguration<PostReaction>
{
    public void Configure(EntityTypeBuilder<PostReaction> builder)
    {
        builder.HasKey(r => r.Id);

        builder.Property(r => r.ReactionType)
            .IsRequired()
            .HasMaxLength(20);

        builder.HasOne(r => r.Post)
            .WithMany(p => p.Reactions)
            .HasForeignKey(r => r.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.Musician)
            .WithMany()
            .HasForeignKey(r => r.MusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(r => new { r.PostId, r.MusicianId })
            .IsUnique();
    }
}
