using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class KapelleStimmenMappingConfiguration : IEntityTypeConfiguration<KapelleStimmenMapping>
{
    public void Configure(EntityTypeBuilder<KapelleStimmenMapping> builder)
    {
        builder.HasKey(m => m.Id);

        builder.Property(m => m.Instrument).IsRequired().HasMaxLength(100);
        builder.Property(m => m.Stimme).IsRequired().HasMaxLength(100);

        // One entry per instrument per Kapelle
        builder.HasIndex(m => new { m.KapelleId, m.Instrument }).IsUnique();

        builder.HasOne(m => m.Kapelle)
            .WithMany(k => k.StimmenMappings)
            .HasForeignKey(m => m.KapelleId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
