using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class NutzerInstrumentConfiguration : IEntityTypeConfiguration<NutzerInstrument>
{
    public void Configure(EntityTypeBuilder<NutzerInstrument> builder)
    {
        builder.HasKey(ni => ni.Id);

        builder.Property(ni => ni.InstrumentTyp)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(ni => ni.InstrumentBezeichnung)
            .IsRequired()
            .HasMaxLength(100);

        // Each instrument type only once per Musiker
        builder.HasIndex(ni => new { ni.MusikerID, ni.InstrumentTyp }).IsUnique();

        // Performance index
        builder.HasIndex(ni => ni.MusikerID);

        builder.HasOne(ni => ni.Musiker)
            .WithMany(m => m.NutzerInstrumente)
            .HasForeignKey(ni => ni.MusikerID)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
