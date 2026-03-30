using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class PollConfiguration : IEntityTypeConfiguration<Poll>
{
    public void Configure(EntityTypeBuilder<Poll> builder)
    {
        builder.HasKey(p => p.Id);

        builder.Property(p => p.Question)
            .IsRequired()
            .HasMaxLength(250);

        builder.Property(p => p.IsAnonymous)
            .IsRequired();

        builder.Property(p => p.IsMultipleChoice)
            .IsRequired();

        builder.Property(p => p.IsClosed)
            .IsRequired();

        builder.HasOne(p => p.Band)
            .WithMany()
            .HasForeignKey(p => p.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(p => p.CreatedByMusician)
            .WithMany()
            .HasForeignKey(p => p.CreatedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(p => p.Options)
            .WithOne(o => o.Poll)
            .HasForeignKey(o => o.PollId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(p => new { p.BandId, p.IsClosed });
    }
}
