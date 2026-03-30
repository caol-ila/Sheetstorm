using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class PollVoteConfiguration : IEntityTypeConfiguration<PollVote>
{
    public void Configure(EntityTypeBuilder<PollVote> builder)
    {
        builder.HasKey(v => v.Id);

        builder.HasOne(v => v.PollOption)
            .WithMany(o => o.Votes)
            .HasForeignKey(v => v.PollOptionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(v => v.Musician)
            .WithMany()
            .HasForeignKey(v => v.MusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(v => new { v.PollOptionId, v.MusicianId });
    }
}
