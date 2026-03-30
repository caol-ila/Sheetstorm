using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class SubstituteAccessConfiguration : IEntityTypeConfiguration<SubstituteAccess>
{
    public void Configure(EntityTypeBuilder<SubstituteAccess> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.Token)
            .IsRequired()
            .HasMaxLength(128);

        builder.Property(s => s.Name)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(s => s.Email)
            .HasMaxLength(200);

        builder.Property(s => s.Instrument)
            .HasMaxLength(100);

        builder.Property(s => s.Note)
            .HasMaxLength(200);

        builder.HasOne(s => s.Band)
            .WithMany()
            .HasForeignKey(s => s.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.Voice)
            .WithMany()
            .HasForeignKey(s => s.VoiceId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(s => s.Event)
            .WithMany()
            .HasForeignKey(s => s.EventId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(s => s.GrantedByMusician)
            .WithMany()
            .HasForeignKey(s => s.GrantedByMusicianId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(s => s.Token)
            .IsUnique();

        builder.HasIndex(s => new { s.BandId, s.IsActive });
    }
}
