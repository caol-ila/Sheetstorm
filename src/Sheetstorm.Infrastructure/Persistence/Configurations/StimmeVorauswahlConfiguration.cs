using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class StimmeVorauswahlConfiguration : IEntityTypeConfiguration<StimmeVorauswahl>
{
    public void Configure(EntityTypeBuilder<StimmeVorauswahl> builder)
    {
        builder.HasKey(sv => sv.Id);

        builder.Property(sv => sv.StimmeBezeichnung)
            .IsRequired()
            .HasMaxLength(100);

        // One default Stimme per Musiker + Kapelle + Instrument
        builder.HasIndex(sv => new { sv.MusikerID, sv.KapelleID, sv.NutzerInstrumentID }).IsUnique();

        // Performance index for Kapelle lookups
        builder.HasIndex(sv => new { sv.MusikerID, sv.KapelleID });

        builder.HasOne(sv => sv.Musiker)
            .WithMany()
            .HasForeignKey(sv => sv.MusikerID)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(sv => sv.Kapelle)
            .WithMany()
            .HasForeignKey(sv => sv.KapelleID)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(sv => sv.NutzerInstrument)
            .WithMany(ni => ni.Vorauswahlen)
            .HasForeignKey(sv => sv.NutzerInstrumentID)
            .OnDelete(DeleteBehavior.NoAction);
    }
}
