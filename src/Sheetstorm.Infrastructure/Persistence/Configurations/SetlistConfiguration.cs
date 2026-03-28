using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence.Configurations;

public class SetlistConfiguration : IEntityTypeConfiguration<Setlist>
{
    public void Configure(EntityTypeBuilder<Setlist> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.Name)
            .IsRequired()
            .HasMaxLength(120);

        builder.Property(s => s.Description)
            .HasMaxLength(500);

        builder.Property(s => s.Type)
            .HasConversion<string>()
            .HasMaxLength(30)
            .IsRequired();

        builder.HasOne(s => s.Band)
            .WithMany()
            .HasForeignKey(s => s.BandId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(s => s.Entries)
            .WithOne(e => e.Setlist)
            .HasForeignKey(e => e.SetlistId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
