using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Events;
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
    public DbSet<OfflineWish> OfflineWishes => Set<OfflineWish>();
    public DbSet<OmrJob> OmrJobs => Set<OmrJob>();
    public DbSet<Annotation> Annotations => Set<Annotation>();
    public DbSet<PushSubscription> PushSubscriptions => Set<PushSubscription>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<EventAttendance> EventAttendances => Set<EventAttendance>();
    public DbSet<SetList> SetLists => Set<SetList>();
    public DbSet<SetListItem> SetListItems => Set<SetListItem>();
    public DbSet<EventSyncSession> EventSyncSessions => Set<EventSyncSession>();
    public DbSet<EventShift> EventShifts => Set<EventShift>();
    public DbSet<ShiftAssignment> ShiftAssignments => Set<ShiftAssignment>();
    public DbSet<EventDay> EventDays => Set<EventDay>();
    public DbSet<EventStation> EventStations => Set<EventStation>();
    public DbSet<EventContribution> EventContributions => Set<EventContribution>();
    public DbSet<EventContributionPledge> EventContributionPledges => Set<EventContributionPledge>();
    public DbSet<EventPoll> EventPolls => Set<EventPoll>();
    public DbSet<PollOption> PollOptions => Set<PollOption>();
    public DbSet<PollResponse> PollResponses => Set<PollResponse>();

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

        b.Entity<Event>(e =>
        {
            e.ToTable("Events");
            e.Property(x => x.Type).HasConversion<int>();
            e.Property(x => x.Title).HasMaxLength(300).IsRequired();
            e.Property(x => x.Location).HasMaxLength(300);
            e.Property(x => x.DressCode).HasMaxLength(120);
            e.HasIndex(x => new { x.BandId, x.StartUtc });
            e.HasOne(x => x.SetList).WithMany().HasForeignKey(x => x.SetListId).OnDelete(DeleteBehavior.SetNull);
        });

        b.Entity<EventAttendance>(e =>
        {
            e.ToTable("EventAttendances");
            e.Property(x => x.Status).HasConversion<int>();
            e.HasOne(x => x.Event).WithMany(x => x.Attendances).HasForeignKey(x => x.EventId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => new { x.EventId, x.UserId }).IsUnique();
        });

        b.Entity<SetList>(e =>
        {
            e.ToTable("SetLists");
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.HasIndex(x => x.BandId);
        });

        b.Entity<SetListItem>(e =>
        {
            e.ToTable("SetListItems");
            e.HasOne<SetList>().WithMany(s => s.Items).HasForeignKey(x => x.SetListId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Piece).WithMany().HasForeignKey(x => x.PieceId).OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => new { x.SetListId, x.Position });
        });

        b.Entity<EventSyncSession>(e =>
        {
            e.ToTable("EventSyncSessions");
            e.Property(x => x.CurrentPieceId).HasMaxLength(40);
            e.Property(x => x.CurrentPieceTitle).HasMaxLength(300);
            e.HasOne(x => x.Event).WithMany().HasForeignKey(x => x.EventId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.EventId);
        });

        b.Entity<OfflineWish>(e =>
        {
            e.ToTable("OfflineWishes");
            e.HasIndex(x => new { x.UserId, x.PieceId }).IsUnique();
            e.HasIndex(x => x.UserId);
        });

        b.Entity<OmrJob>(e =>
        {
            e.ToTable("OmrJobs");
            e.Property(x => x.Status).HasConversion<int>();
            e.Property(x => x.OriginalFileName).HasMaxLength(300).IsRequired();
            e.Property(x => x.InputBlobKey).HasMaxLength(500).IsRequired();
            e.Property(x => x.SuggestedTitle).HasMaxLength(300);
            e.Property(x => x.SuggestedComposer).HasMaxLength(200);
            e.HasIndex(x => new { x.BandId, x.Status });
            e.HasIndex(x => x.CreatedById);
        });

        b.Entity<Annotation>(e =>
        {
            e.ToTable("Annotations");
            e.HasIndex(x => new { x.PartId, x.UserId, x.Page }).IsUnique();
        });

        b.Entity<PushSubscription>(e =>
        {
            e.ToTable("PushSubscriptions");
            e.Property(x => x.Endpoint).HasMaxLength(500).IsRequired();
            e.Property(x => x.P256dhKey).HasMaxLength(200).IsRequired();
            e.Property(x => x.AuthKey).HasMaxLength(200).IsRequired();
            e.HasIndex(x => x.UserId);
            e.HasIndex(x => x.Endpoint).IsUnique();
        });

        b.Entity<EventShift>(e =>
        {
            e.ToTable("EventShifts");
            e.Property(x => x.Title).HasMaxLength(200).IsRequired();
            e.Property(x => x.Notes).HasMaxLength(2000);
            e.HasOne(x => x.Event).WithMany().HasForeignKey(x => x.EventId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.EventId);
            e.HasIndex(x => x.EventDayId);
            e.HasIndex(x => x.StationId);
        });

        b.Entity<ShiftAssignment>(e =>
        {
            e.ToTable("ShiftAssignments");
            e.HasOne(x => x.Shift).WithMany(s => s.Assignments).HasForeignKey(x => x.ShiftId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => new { x.ShiftId, x.UserId }).IsUnique();
        });

        b.Entity<EventDay>(e =>
        {
            e.ToTable("EventDays");
            e.Property(x => x.Theme).HasMaxLength(200);
            e.HasIndex(x => x.EventId);
        });

        b.Entity<EventStation>(e =>
        {
            e.ToTable("EventStations");
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.Description).HasMaxLength(1000);
            e.Property(x => x.IconKey).HasMaxLength(64);
            e.HasIndex(x => x.EventId);
        });

        b.Entity<EventContribution>(e =>
        {
            e.ToTable("EventContributions");
            e.Property(x => x.Title).HasMaxLength(200).IsRequired();
            e.Property(x => x.Description).HasMaxLength(1000);
            e.HasIndex(x => x.EventId);
        });

        b.Entity<EventContributionPledge>(e =>
        {
            e.ToTable("EventContributionPledges");
            e.Property(x => x.What).HasMaxLength(500);
            e.HasOne(x => x.Contribution).WithMany(c => c.Pledges).HasForeignKey(x => x.ContributionId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => new { x.ContributionId, x.UserId });
        });

        b.Entity<EventPoll>(e =>
        {
            e.ToTable("EventPolls");
            e.Property(x => x.Title).HasMaxLength(300).IsRequired();
            e.Property(x => x.Description).HasMaxLength(2000);
            e.HasIndex(x => x.EventId);
            e.HasIndex(x => x.BandId);
        });

        b.Entity<PollOption>(e =>
        {
            e.ToTable("PollOptions");
            e.Property(x => x.Label).HasMaxLength(300).IsRequired();
            e.HasOne(x => x.Poll).WithMany(p => p.Options).HasForeignKey(x => x.PollId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.PollId);
        });

        b.Entity<PollResponse>(e =>
        {
            e.ToTable("PollResponses");
            e.Property(x => x.FreeTextAnswer).HasMaxLength(2000);
            e.Property(x => x.Size).HasMaxLength(40);
            e.HasOne(x => x.Poll).WithMany(p => p.Responses).HasForeignKey(x => x.PollId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Option).WithMany().HasForeignKey(x => x.OptionId).OnDelete(DeleteBehavior.SetNull);
            e.HasIndex(x => new { x.PollId, x.UserId });
        });
    }
}
