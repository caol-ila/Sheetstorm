using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Musician> Musicians => Set<Musician>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Band> Bands => Set<Band>();
    public DbSet<Membership> Memberships => Set<Membership>();
    public DbSet<Invitation> Invitations => Set<Invitation>();
    public DbSet<BandVoiceMapping> BandVoiceMappings => Set<BandVoiceMapping>();
    public DbSet<Piece> Pieces => Set<Piece>();
    public DbSet<Voice> Voices => Set<Voice>();
    public DbSet<SheetMusic> SheetMusic => Set<SheetMusic>();
    public DbSet<PiecePage> PiecePages => Set<PiecePage>();
    public DbSet<ConfigBand> ConfigBand => Set<ConfigBand>();
    public DbSet<ConfigUser> ConfigUser => Set<ConfigUser>();
    public DbSet<ConfigPolicy> ConfigPolicies => Set<ConfigPolicy>();
    public DbSet<ConfigAudit> ConfigAudit => Set<ConfigAudit>();
    public DbSet<UserInstrument> UserInstruments => Set<UserInstrument>();
    public DbSet<VoicePreselection> VoicePreselections => Set<VoicePreselection>();
    public DbSet<Setlist> Setlists => Set<Setlist>();
    public DbSet<SetlistEntry> SetlistEntries => Set<SetlistEntry>();
    public DbSet<MediaLink> MediaLinks => Set<MediaLink>();
    public DbSet<Post> Posts => Set<Post>();
    public DbSet<PostComment> PostComments => Set<PostComment>();
    public DbSet<PostReaction> PostReactions => Set<PostReaction>();
    public DbSet<Poll> Polls => Set<Poll>();
    public DbSet<PollOption> PollOptions => Set<PollOption>();
    public DbSet<PollVote> PollVotes => Set<PollVote>();
    public DbSet<AttendanceRecord> AttendanceRecords => Set<AttendanceRecord>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<EventRsvp> EventRsvps => Set<EventRsvp>();
    public DbSet<GemaReport> GemaReports => Set<GemaReport>();
    public DbSet<GemaReportEntry> GemaReportEntries => Set<GemaReportEntry>();
    public DbSet<SubstituteAccess> SubstituteAccesses => Set<SubstituteAccess>();
    public DbSet<ShiftPlan> ShiftPlans => Set<ShiftPlan>();
    public DbSet<Shift> Shifts => Set<Shift>();
    public DbSet<ShiftAssignment> ShiftAssignments => Set<ShiftAssignment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        UpdateAuditFields();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void UpdateAuditFields()
    {
        var now = DateTime.UtcNow;
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            if (entry.State == EntityState.Added)
                entry.Entity.CreatedAt = now;
            if (entry.State is EntityState.Added or EntityState.Modified)
                entry.Entity.UpdatedAt = now;
        }
    }
}
