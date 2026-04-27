using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Identity;

namespace Sheetstorm.Infrastructure.Persistence;

public sealed class SheetstormDbContext(DbContextOptions<SheetstormDbContext> options)
    : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>(options)
{
    public DbSet<Band> Bands => Set<Band>();
    public DbSet<Membership> Memberships => Set<Membership>();
    public DbSet<MembershipInstrument> MembershipInstruments => Set<MembershipInstrument>();
    public DbSet<Instrument> Instruments => Set<Instrument>();
    public DbSet<BandInvitation> BandInvitations => Set<BandInvitation>();
    public DbSet<BandJoinCode> BandJoinCodes => Set<BandJoinCode>();
    public DbSet<BandJoinRequest> BandJoinRequests => Set<BandJoinRequest>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);

        // Identity-Tabellen ins eigene Schema, damit Domain-Tabellen klar getrennt sind.
        foreach (var et in b.Model.GetEntityTypes())
        {
            var t = et.GetTableName();
            if (t is not null && t.StartsWith("AspNet", StringComparison.Ordinal))
            {
                et.SetTableName(t.Replace("AspNet", "Identity"));
            }
        }

        b.Entity<Band>(e =>
        {
            e.ToTable("Bands");
            e.Property(x => x.Slug).HasMaxLength(64).IsRequired();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.Country).HasMaxLength(2).IsRequired();
            e.HasIndex(x => x.Slug).IsUnique();
        });

        b.Entity<Membership>(e =>
        {
            e.ToTable("Memberships");
            e.HasIndex(x => new { x.BandId, x.UserId }).IsUnique();
            e.HasOne(x => x.Band).WithMany(x => x.Memberships)
                .HasForeignKey(x => x.BandId).OnDelete(DeleteBehavior.Cascade);
            e.Property(x => x.Roles).HasConversion<int>();
            e.Property(x => x.Status).HasConversion<int>();
        });

        b.Entity<MembershipInstrument>(e =>
        {
            e.ToTable("MembershipInstruments");
            e.HasOne(x => x.Instrument).WithMany()
                .HasForeignKey(x => x.InstrumentId).OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => new { x.MembershipId, x.InstrumentId, x.Transposition }).IsUnique();
        });

        b.Entity<Instrument>(e =>
        {
            e.ToTable("Instruments");
            e.Property(x => x.Family).HasConversion<int>();
            e.Property(x => x.Name).HasMaxLength(120).IsRequired();
            e.Property(x => x.DefaultTransposition).HasMaxLength(8);
            e.HasIndex(x => new { x.Family, x.Name, x.DefaultTransposition }).IsUnique();
        });

        b.Entity<BandInvitation>(e =>
        {
            e.ToTable("BandInvitations");
            e.HasOne(x => x.Band).WithMany(x => x.Invitations)
                .HasForeignKey(x => x.BandId).OnDelete(DeleteBehavior.Cascade);
            e.Property(x => x.Email).HasMaxLength(256).IsRequired();
            e.Property(x => x.TokenHash).HasMaxLength(128).IsRequired();
            e.Property(x => x.RolesToGrant).HasConversion<int>();
            e.HasIndex(x => x.TokenHash);
        });

        b.Entity<BandJoinCode>(e =>
        {
            e.ToTable("BandJoinCodes");
            e.HasOne(x => x.Band).WithMany(x => x.JoinCodes)
                .HasForeignKey(x => x.BandId).OnDelete(DeleteBehavior.Cascade);
            e.Property(x => x.CodeHash).HasMaxLength(128).IsRequired();
            e.HasIndex(x => x.CodeHash);
        });

        b.Entity<BandJoinRequest>(e =>
        {
            e.ToTable("BandJoinRequests");
            e.HasOne(x => x.Band).WithMany()
                .HasForeignKey(x => x.BandId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => new { x.BandId, x.UserId, x.JoinCodeId }).IsUnique();
        });
    }
}
