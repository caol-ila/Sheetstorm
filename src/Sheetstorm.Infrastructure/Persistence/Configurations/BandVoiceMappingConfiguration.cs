using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class BandVoiceMappingConfiguration : IEntityTypeConfiguration<BandVoiceMapping>
{
    public void Configure(EntityTypeBuilder<BandVoiceMapping> builder)
    {
        builder.HasKey(m => m.Id);

        builder.Property(m => m.Instrument).IsRequired().HasMaxLength(100);
        builder.Property(m => m.Voice).IsRequired().HasMaxLength(100);

        // One entry per instrument per Band
        builder.HasIndex(m => new { m.BandId, m.Instrument }).IsUnique();

        builder.HasOne(m => m.Band)
            .WithMany(k => k.VoiceMappings)
            .HasForeignKey(m => m.BandId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
