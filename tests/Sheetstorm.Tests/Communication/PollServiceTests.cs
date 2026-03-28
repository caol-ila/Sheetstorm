using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Polls;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Polls;

namespace Sheetstorm.Tests.Communication;

public class PollServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly PollService _sut;

    public PollServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new PollService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId, Guid pollId)> SeedPollAsync(MemberRole role = MemberRole.Conductor, bool isClosed = false)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test Musician" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = role, IsActive = true };
        var poll = new Poll
        {
            Band = band,
            CreatedByMusician = musician,
            Question = "Test Poll?",
            IsAnonymous = false,
            IsMultipleChoice = false,
            IsClosed = isClosed
        };
        var option1 = new PollOption { Poll = poll, Text = "Option 1", Position = 0 };
        var option2 = new PollOption { Poll = poll, Text = "Option 2", Position = 1 };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        _db.Polls.Add(poll);
        _db.PollOptions.AddRange(option1, option2);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id, poll.Id);
    }

    private async Task<Guid> SeedMemberAsync(Guid bandId, MemberRole role = MemberRole.Musician)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Member" };
        var membership = new Membership { MusicianId = musician.Id, BandId = bandId, Role = role, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return musician.Id;
    }

    // ── GetAllAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task GetAllAsync_ValidMember_ReturnsAllPolls()
    {
        var (musicianId, bandId, pollId) = await SeedPollAsync();

        var result = await _sut.GetAllAsync(bandId, musicianId, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal(pollId, result[0].Id);
    }

    [Fact]
    public async Task GetAllAsync_OrdersByCreatedDate()
    {
        var (musicianId, bandId, _) = await SeedPollAsync();
        var poll1 = new Poll { BandId = bandId, CreatedByMusicianId = musicianId, Question = "Newer?", CreatedAt = DateTime.UtcNow.AddMinutes(1) };
        _db.Polls.Add(poll1);
        await _db.SaveChangesAsync();

        var result = await _sut.GetAllAsync(bandId, musicianId, CancellationToken.None);

        Assert.Equal(poll1.Id, result[0].Id);
    }

    [Fact]
    public async Task GetAllAsync_NotMember_ThrowsDomainException()
    {
        var (_, bandId, _) = await SeedPollAsync();
        var stranger = Guid.NewGuid();

        await Assert.ThrowsAsync<DomainException>(() => _sut.GetAllAsync(bandId, stranger, CancellationToken.None));
    }

    // ── GetByIdAsync ──────────────────────────────────────────────────────────

    [Fact]
    public async Task GetByIdAsync_ValidPoll_ReturnsDetailWithOptions()
    {
        var (musicianId, bandId, pollId) = await SeedPollAsync();

        var result = await _sut.GetByIdAsync(bandId, pollId, musicianId, CancellationToken.None);

        Assert.Equal(pollId, result.Id);
        Assert.Equal(2, result.Options.Count);
        Assert.Equal("Option 1", result.Options[0].Text);
    }

    [Fact]
    public async Task GetByIdAsync_CalculatesPercentages()
    {
        var (musicianId, bandId, pollId) = await SeedPollAsync();
        var options = await _db.PollOptions.Where(o => o.PollId == pollId).ToListAsync();
        var vote = new PollVote { PollOptionId = options[0].Id, MusicianId = musicianId };
        _db.PollVotes.Add(vote);
        await _db.SaveChangesAsync();

        var result = await _sut.GetByIdAsync(bandId, pollId, musicianId, CancellationToken.None);

        Assert.Equal(1, result.TotalVotes);
        Assert.Equal(100.0, result.Options[0].VotePercentage);
        Assert.Equal(0.0, result.Options[1].VotePercentage);
    }

    [Fact]
    public async Task GetByIdAsync_PollNotFound_ThrowsDomainException()
    {
        var (musicianId, bandId, _) = await SeedPollAsync();

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetByIdAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));
    }

    // ── CreateAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAsync_AdminRole_CreatesPoll()
    {
        var musician = new Musician { Email = "admin@test.com", Name = "Admin" };
        var band = new Band { Name = "Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = MemberRole.Administrator, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();

        var request = new CreatePollRequest("Question?", new[] { "A", "B" }, false, false, null);
        var result = await _sut.CreateAsync(band.Id, request, musician.Id, CancellationToken.None);

        Assert.Equal("Question?", result.Question);
        Assert.Equal(2, result.Options.Count);
    }

    [Fact]
    public async Task CreateAsync_SectionLeaderRole_CreatesPoll()
    {
        var musician = new Musician { Email = "leader@test.com", Name = "Leader" };
        var band = new Band { Name = "Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = MemberRole.SectionLeader, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();

        var request = new CreatePollRequest("Question?", new[] { "A", "B" }, false, false, null);
        var result = await _sut.CreateAsync(band.Id, request, musician.Id, CancellationToken.None);

        Assert.Equal("Question?", result.Question);
    }

    [Fact]
    public async Task CreateAsync_RegularMember_ThrowsForbidden()
    {
        var musician = new Musician { Email = "member@test.com", Name = "Member" };
        var band = new Band { Name = "Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = MemberRole.Musician, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();

        var request = new CreatePollRequest("Question?", new[] { "A", "B" }, false, false, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAsync(band.Id, request, musician.Id, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task CreateAsync_LessThanTwoOptions_ThrowsValidationError()
    {
        var (musicianId, bandId, _) = await SeedPollAsync(MemberRole.Administrator);

        var request = new CreatePollRequest("Question?", new[] { "Only one" }, false, false, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAsync(bandId, request, musicianId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    // ── DeleteAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteAsync_Creator_DeletesPoll()
    {
        var (musicianId, bandId, pollId) = await SeedPollAsync();

        await _sut.DeleteAsync(bandId, pollId, musicianId, CancellationToken.None);

        var exists = await _db.Polls.AnyAsync(p => p.Id == pollId);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteAsync_Admin_DeletesAnyPoll()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var adminId = await SeedMemberAsync(bandId, MemberRole.Administrator);

        await _sut.DeleteAsync(bandId, pollId, adminId, CancellationToken.None);

        var exists = await _db.Polls.AnyAsync(p => p.Id == pollId);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteAsync_NotCreatorNotAdmin_ThrowsForbidden()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var otherId = await SeedMemberAsync(bandId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteAsync(bandId, pollId, otherId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── VoteAsync ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task VoteAsync_ValidSingleChoice_RecordsVote()
    {
        var (musicianId, bandId, pollId) = await SeedPollAsync();
        var options = await _db.PollOptions.Where(o => o.PollId == pollId).ToListAsync();
        var otherId = await SeedMemberAsync(bandId);

        var request = new VotePollRequest(new[] { options[0].Id });
        await _sut.VoteAsync(bandId, pollId, request, otherId, CancellationToken.None);

        var vote = await _db.PollVotes.FirstOrDefaultAsync(v => v.PollOptionId == options[0].Id && v.MusicianId == otherId);
        Assert.NotNull(vote);
    }

    [Fact]
    public async Task VoteAsync_MultipleChoice_RecordsMultipleVotes()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var poll = await _db.Polls.FindAsync(pollId);
        poll!.IsMultipleChoice = true;
        await _db.SaveChangesAsync();

        var options = await _db.PollOptions.Where(o => o.PollId == pollId).ToListAsync();
        var voterId = await SeedMemberAsync(bandId);

        var request = new VotePollRequest(new[] { options[0].Id, options[1].Id });
        await _sut.VoteAsync(bandId, pollId, request, voterId, CancellationToken.None);

        var votes = await _db.PollVotes.Where(v => v.MusicianId == voterId).ToListAsync();
        Assert.Equal(2, votes.Count);
    }

    [Fact]
    public async Task VoteAsync_SingleChoiceMultipleOptions_ThrowsValidationError()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var options = await _db.PollOptions.Where(o => o.PollId == pollId).ToListAsync();
        var voterId = await SeedMemberAsync(bandId);

        var request = new VotePollRequest(new[] { options[0].Id, options[1].Id });
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.VoteAsync(bandId, pollId, request, voterId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
    }

    [Fact]
    public async Task VoteAsync_ClosedPoll_ThrowsConflict()
    {
        var (_, bandId, pollId) = await SeedPollAsync(MemberRole.Conductor, true);
        var options = await _db.PollOptions.Where(o => o.PollId == pollId).ToListAsync();
        var voterId = await SeedMemberAsync(bandId);

        var request = new VotePollRequest(new[] { options[0].Id });
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.VoteAsync(bandId, pollId, request, voterId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task VoteAsync_ExpiredPoll_ThrowsConflict()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var poll = await _db.Polls.FindAsync(pollId);
        poll!.ExpiresAt = DateTime.UtcNow.AddDays(-1);
        await _db.SaveChangesAsync();

        var options = await _db.PollOptions.Where(o => o.PollId == pollId).ToListAsync();
        var voterId = await SeedMemberAsync(bandId);

        var request = new VotePollRequest(new[] { options[0].Id });
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.VoteAsync(bandId, pollId, request, voterId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
    }

    [Fact]
    public async Task VoteAsync_ChangeVote_ReplacesExisting()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var options = await _db.PollOptions.Where(o => o.PollId == pollId).ToListAsync();
        var voterId = await SeedMemberAsync(bandId);
        
        var vote = new PollVote { PollOptionId = options[0].Id, MusicianId = voterId };
        _db.PollVotes.Add(vote);
        await _db.SaveChangesAsync();

        var request = new VotePollRequest(new[] { options[1].Id });
        await _sut.VoteAsync(bandId, pollId, request, voterId, CancellationToken.None);

        var votes = await _db.PollVotes.Where(v => v.MusicianId == voterId).ToListAsync();
        Assert.Single(votes);
        Assert.Equal(options[1].Id, votes[0].PollOptionId);
    }

    [Fact]
    public async Task VoteAsync_InvalidOptionId_ThrowsValidationError()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var voterId = await SeedMemberAsync(bandId);

        var request = new VotePollRequest(new[] { Guid.NewGuid() });
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.VoteAsync(bandId, pollId, request, voterId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
    }

    // ── CloseAsync ────────────────────────────────────────────────────────────

    [Fact]
    public async Task CloseAsync_Creator_ClosesPoll()
    {
        var (musicianId, bandId, pollId) = await SeedPollAsync();

        await _sut.CloseAsync(bandId, pollId, musicianId, CancellationToken.None);

        var poll = await _db.Polls.FindAsync(pollId);
        Assert.True(poll!.IsClosed);
    }

    [Fact]
    public async Task CloseAsync_Admin_ClosesAnyPoll()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var adminId = await SeedMemberAsync(bandId, MemberRole.Administrator);

        await _sut.CloseAsync(bandId, pollId, adminId, CancellationToken.None);

        var poll = await _db.Polls.FindAsync(pollId);
        Assert.True(poll!.IsClosed);
    }

    [Fact]
    public async Task CloseAsync_Conductor_ClosesAnyPoll()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var conductorId = await SeedMemberAsync(bandId, MemberRole.Conductor);

        await _sut.CloseAsync(bandId, pollId, conductorId, CancellationToken.None);

        var poll = await _db.Polls.FindAsync(pollId);
        Assert.True(poll!.IsClosed);
    }

    [Fact]
    public async Task CloseAsync_NotAuthorized_ThrowsForbidden()
    {
        var (_, bandId, pollId) = await SeedPollAsync();
        var memberId = await SeedMemberAsync(bandId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CloseAsync(bandId, pollId, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }
}
