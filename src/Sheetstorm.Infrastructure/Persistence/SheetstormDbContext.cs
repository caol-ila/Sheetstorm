using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Identity;
using Sheetstorm.Domain.Music;

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
    public DbSet<Piece> Pieces => Set<Piece>();
    public DbSet<Part> Parts => Set<Part>();
    public DbSet<PartFile> PartFiles => Set<PartFile>();

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

        b.Entity<Piece>(e =>
        {
            e.ToTable("Pieces");
            e.Property(x => x.Title).HasMaxLength(300).IsRequired();
            e.Property(x => x.Subtitle).HasMaxLength(300);
            e.Property(x => x.Composer).HasMaxLength(200);
            e.Property(x => x.Arranger).HasMaxLength(200);
            e.Property(x => x.Publisher).HasMaxLength(200);
            e.Property(x => x.PublisherNumber).HasMaxLength(80);
            e.Property(x => x.KeySignature).HasMaxLength(20);
            e.Property(x => x.TimeSignature).HasMaxLength(20);
            e.Property(x => x.Genre).HasMaxLength(80);
            e.Property(x => x.Tags).HasMaxLength(500);
            e.HasIndex(x => new { x.BandId, x.Title });
            e.HasIndex(x => x.BandId);
        });

        b.Entity<Part>(e =>
        {
            e.ToTable("Parts");
            e.Property(x => x.DisplayName).HasMaxLength(200).IsRequired();
            e.Property(x => x.Transposition).HasMaxLength(8);
            e.Property(x => x.Register).HasMaxLength(20);
            e.HasOne(x => x.Piece).WithMany(x => x.Parts).HasForeignKey(x => x.PieceId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Instrument).WithMany().HasForeignKey(x => x.InstrumentId).OnDelete(DeleteBehavior.Restrict);
        });

        b.Entity<PartFile>(e =>
        {
            e.ToTable("PartFiles");
            e.Property(x => x.Kind).HasConversion<int>();
            e.Property(x => x.BlobKey).HasMaxLength(500).IsRequired();
            e.Property(x => x.OriginalFileName).HasMaxLength(300).IsRequired();
            e.HasIndex(x => x.PartId);
        });
    }
}
