using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class StueckConfiguration : IEntityTypeConfiguration<Stueck>
{
    public void Configure(EntityTypeBuilder<Stueck> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.Titel)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(s => s.Komponist)
            .HasMaxLength(200);

        builder.Property(s => s.Arrangeur)
            .HasMaxLength(200);

        builder.Property(s => s.Tonart)
            .HasMaxLength(50);

        builder.Property(s => s.Taktart)
            .HasMaxLength(50);

        builder.Property(s => s.Beschreibung)
            .HasMaxLength(2000);

        builder.Property(s => s.OriginalDateiname)
            .HasMaxLength(500);

        builder.Property(s => s.StorageKey)
            .HasMaxLength(1024);

        builder.Property(s => s.ImportStatus)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.HasOne(s => s.Kapelle)
            .WithMany(k => k.Stuecke)
            .HasForeignKey(s => s.KapelleID)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.Musiker)
            .WithMany()
            .HasForeignKey(s => s.MusikerID)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(s => s.Stimmen)
            .WithOne(st => st.Stueck)
            .HasForeignKey(st => st.StueckID)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(s => s.Seiten)
            .WithOne(p => p.Stueck)
            .HasForeignKey(p => p.StueckID)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
