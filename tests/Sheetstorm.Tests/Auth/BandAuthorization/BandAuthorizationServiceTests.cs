using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Auth.BandAuthorization;

public class BandAuthorizationServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly BandAuthorizationService _sut;

    public BandAuthorizationServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new BandAuthorizationService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedMembershipAsync(
        MemberRole role = MemberRole.Musician, bool isActive = true)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test User" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership
        {
            Musician = musician,
            Band = band,
            IsActive = isActive,
            Role = role
        };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    // ── RequireMembershipAsync ──────────────────────────────────────────────

    [Fact]
    public async Task RequireMembershipAsync_ActiveMember_ReturnsMembership()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);

        var result = await _sut.RequireMembershipAsync(bandId, musicianId);

        Assert.NotNull(result);
        Assert.Equal(bandId, result.BandId);
        Assert.Equal(musicianId, result.MusicianId);
        Assert.True(result.IsActive);
    }

    [Fact]
    public async Task RequireMembershipAsync_InactiveMember_Throws403()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(isActive: false);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.RequireMembershipAsync(bandId, musicianId));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task RequireMembershipAsync_NoMembership_Throws403()
    {
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.RequireMembershipAsync(Guid.NewGuid(), Guid.NewGuid()));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task AccessBand_NotMember_Returns403()
    {
        var (musicianId, _) = await SeedMembershipAsync(MemberRole.Musician);
        var otherBandId = Guid.NewGuid();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.RequireMembershipAsync(otherBandId, musicianId));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Theory]
    [InlineData(MemberRole.Musician)]
    [InlineData(MemberRole.SectionLeader)]
    [InlineData(MemberRole.Conductor)]
    [InlineData(MemberRole.SheetMusicManager)]
    [InlineData(MemberRole.Administrator)]
    public async Task RequireMembershipAsync_AllRoles_ReturnsMembership(MemberRole role)
    {
        var (musicianId, bandId) = await SeedMembershipAsync(role);

        var result = await _sut.RequireMembershipAsync(bandId, musicianId);

        Assert.Equal(role, result.Role);
    }

    // ── RequireConductorOrAdminAsync ────────────────────────────────────────

    [Fact]
    public async Task RequireConductorOrAdminAsync_Conductor_ReturnsMembership()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);

        var result = await _sut.RequireConductorOrAdminAsync(bandId, musicianId);

        Assert.Equal(MemberRole.Conductor, result.Role);
    }

    [Fact]
    public async Task RequireConductorOrAdminAsync_Administrator_ReturnsMembership()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);

        var result = await _sut.RequireConductorOrAdminAsync(bandId, musicianId);

        Assert.Equal(MemberRole.Administrator, result.Role);
    }

    [Theory]
    [InlineData(MemberRole.Musician)]
    [InlineData(MemberRole.SectionLeader)]
    [InlineData(MemberRole.SheetMusicManager)]
    public async Task RequireConductorOrAdminAsync_InsufficientRole_Throws403(MemberRole role)
    {
        var (musicianId, bandId) = await SeedMembershipAsync(role);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.RequireConductorOrAdminAsync(bandId, musicianId));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task RequireConductorOrAdminAsync_NoMembership_Throws403()
    {
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.RequireConductorOrAdminAsync(Guid.NewGuid(), Guid.NewGuid()));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    // ── RequireAdminAsync ───────────────────────────────────────────────────

    [Fact]
    public async Task RequireAdminAsync_Administrator_ReturnsMembership()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);

        var result = await _sut.RequireAdminAsync(bandId, musicianId);

        Assert.Equal(MemberRole.Administrator, result.Role);
    }

    [Theory]
    [InlineData(MemberRole.Musician)]
    [InlineData(MemberRole.SectionLeader)]
    [InlineData(MemberRole.Conductor)]
    [InlineData(MemberRole.SheetMusicManager)]
    public async Task RequireAdminAsync_NonAdmin_Throws403(MemberRole role)
    {
        var (musicianId, bandId) = await SeedMembershipAsync(role);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.RequireAdminAsync(bandId, musicianId));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task RequireAdminAsync_NoMembership_Throws403()
    {
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.RequireAdminAsync(Guid.NewGuid(), Guid.NewGuid()));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    // ── RequireRoleAsync ────────────────────────────────────────────────────

    [Fact]
    public async Task RequireRoleAsync_MatchingRole_ReturnsMembership()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.SectionLeader);

        var result = await _sut.RequireRoleAsync(
            bandId, musicianId, CancellationToken.None,
            MemberRole.SectionLeader, MemberRole.Conductor);

        Assert.Equal(MemberRole.SectionLeader, result.Role);
    }

    [Fact]
    public async Task RequireRoleAsync_NonMatchingRole_Throws403()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.RequireRoleAsync(
                bandId, musicianId, CancellationToken.None,
                MemberRole.Administrator, MemberRole.Conductor));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task RequireRoleAsync_NoMembership_Throws403()
    {
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.RequireRoleAsync(
                Guid.NewGuid(), Guid.NewGuid(), CancellationToken.None,
                MemberRole.Musician));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    // ── CancellationToken ───────────────────────────────────────────────────

    [Fact]
    public async Task RequireMembershipAsync_CancellationRequested_ThrowsOperationCanceled()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        using var cts = new CancellationTokenSource();
        await cts.CancelAsync();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(
            () => _sut.RequireMembershipAsync(bandId, musicianId, cts.Token));
    }
}
