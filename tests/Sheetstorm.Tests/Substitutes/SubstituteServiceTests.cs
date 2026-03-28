using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Substitutes;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Substitutes;

namespace Sheetstorm.Tests.Substitutes;

public class SubstituteServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly SubstituteService _sut;

    public SubstituteServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new SubstituteService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedMemberAsync(MemberRole role = MemberRole.Conductor)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test Musician" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = role, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    private async Task<Guid> SeedAdditionalMemberAsync(Guid bandId, MemberRole role = MemberRole.Musician)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Additional Member" };
        var membership = new Membership { MusicianId = musician.Id, BandId = bandId, Role = role, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return musician.Id;
    }

    // ── CreateAccessAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAccessAsync_Conductor_CreatesToken()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);

        var request = new CreateSubstituteAccessRequest("John Doe", "john@test.com", null, null, DateTime.UtcNow.AddDays(2), "Trumpet", "For rehearsal");
        var result = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);

        Assert.Equal("John Doe", result.Name);
        Assert.NotNull(result.Token);
        Assert.NotNull(result.Link);
        Assert.Contains("sheetstorm.io", result.Link);
    }

    [Fact]
    public async Task CreateAccessAsync_Admin_CreatesToken()
    {
        var (adminId, bandId) = await SeedMemberAsync(MemberRole.Administrator);

        var request = new CreateSubstituteAccessRequest("Jane Doe", null, null, null, null, null, null);
        var result = await _sut.CreateAccessAsync(bandId, request, adminId, CancellationToken.None);

        Assert.Equal("Jane Doe", result.Name);
        Assert.True(result.ExpiresAt > DateTime.UtcNow);
    }

    [Fact]
    public async Task CreateAccessAsync_TokenIsUnique()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);

        var request1 = new CreateSubstituteAccessRequest("User 1", null, null, null, null, null, null);
        var result1 = await _sut.CreateAccessAsync(bandId, request1, conductorId, CancellationToken.None);

        var request2 = new CreateSubstituteAccessRequest("User 2", null, null, null, null, null, null);
        var result2 = await _sut.CreateAccessAsync(bandId, request2, conductorId, CancellationToken.None);

        Assert.NotEqual(result1.Token, result2.Token);
    }

    [Fact]
    public async Task CreateAccessAsync_RegularMember_ThrowsForbidden()
    {
        var (memberId, bandId) = await SeedMemberAsync(MemberRole.Musician);

        var request = new CreateSubstituteAccessRequest("Test", null, null, null, null, null, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAccessAsync(bandId, request, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task CreateAccessAsync_ExpiryInPast_ThrowsValidationError()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);

        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(-1), null, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    // ── ValidateTokenAsync ────────────────────────────────────────────────────

    [Fact]
    public async Task ValidateTokenAsync_ValidToken_ReturnsDetails()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateSubstituteAccessRequest("Test User", null, null, null, DateTime.UtcNow.AddDays(1), "Trombone", null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);

        var result = await _sut.ValidateTokenAsync(created.Token, CancellationToken.None);

        Assert.Equal("Test User", result.Name);
        Assert.Equal("Trombone", result.Instrument);
        Assert.Equal(bandId, result.BandId);
    }

    [Fact]
    public async Task ValidateTokenAsync_UpdatesLastAccessedAt()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);

        await _sut.ValidateTokenAsync(created.Token, CancellationToken.None);

        var access = await _db.SubstituteAccesses.FindAsync(created.Id);
        Assert.NotNull(access!.LastAccessedAt);
    }

    [Fact]
    public async Task ValidateTokenAsync_InvalidToken_ThrowsNotFound()
    {
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.ValidateTokenAsync("invalid-token", CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task ValidateTokenAsync_RevokedToken_ThrowsForbidden()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);
        await _sut.RevokeAccessAsync(bandId, created.Id, conductorId, CancellationToken.None);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.ValidateTokenAsync(created.Token, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task ValidateTokenAsync_ExpiredToken_ThrowsForbidden()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddSeconds(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);
        await Task.Delay(1500);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.ValidateTokenAsync(created.Token, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(410, ex.StatusCode);
    }

    // ── RevokeAccessAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task RevokeAccessAsync_Conductor_RevokesAccess()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);

        await _sut.RevokeAccessAsync(bandId, created.Id, conductorId, CancellationToken.None);

        var access = await _db.SubstituteAccesses.FindAsync(created.Id);
        Assert.NotNull(access!.RevokedAt);
        Assert.False(access.IsActive);
    }

    [Fact]
    public async Task RevokeAccessAsync_Admin_RevokesAccess()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var adminId = await SeedAdditionalMemberAsync(bandId, MemberRole.Administrator);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);

        await _sut.RevokeAccessAsync(bandId, created.Id, adminId, CancellationToken.None);

        var access = await _db.SubstituteAccesses.FindAsync(created.Id);
        Assert.NotNull(access!.RevokedAt);
    }

    [Fact]
    public async Task RevokeAccessAsync_RegularMember_ThrowsForbidden()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var memberId = await SeedAdditionalMemberAsync(bandId, MemberRole.Musician);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.RevokeAccessAsync(bandId, created.Id, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task RevokeAccessAsync_AlreadyRevoked_ThrowsConflict()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);
        await _sut.RevokeAccessAsync(bandId, created.Id, conductorId, CancellationToken.None);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.RevokeAccessAsync(bandId, created.Id, conductorId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    // ── GetActiveAccessesAsync ────────────────────────────────────────────────

    [Fact]
    public async Task GetActiveAccessesAsync_ReturnsAllAccesses()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request1 = new CreateSubstituteAccessRequest("User 1", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var request2 = new CreateSubstituteAccessRequest("User 2", null, null, null, DateTime.UtcNow.AddDays(2), null, null);
        await _sut.CreateAccessAsync(bandId, request1, conductorId, CancellationToken.None);
        await _sut.CreateAccessAsync(bandId, request2, conductorId, CancellationToken.None);

        var result = await _sut.GetActiveAccessesAsync(bandId, conductorId, CancellationToken.None);

        Assert.Equal(2, result.Count);
    }

    [Fact]
    public async Task GetActiveAccessesAsync_IncludesRevokedAndExpired()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request1 = new CreateSubstituteAccessRequest("Active", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created1 = await _sut.CreateAccessAsync(bandId, request1, conductorId, CancellationToken.None);
        var request2 = new CreateSubstituteAccessRequest("Revoked", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created2 = await _sut.CreateAccessAsync(bandId, request2, conductorId, CancellationToken.None);
        await _sut.RevokeAccessAsync(bandId, created2.Id, conductorId, CancellationToken.None);

        var result = await _sut.GetActiveAccessesAsync(bandId, conductorId, CancellationToken.None);

        Assert.Equal(2, result.Count);
        Assert.True(result.Any(a => a.RevokedAt.HasValue));
    }

    // ── ExtendAccessAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task ExtendAccessAsync_Conductor_ExtendsExpiry()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);

        var newExpiry = DateTime.UtcNow.AddDays(5);
        var extendRequest = new ExtendSubstituteAccessRequest(newExpiry);
        var result = await _sut.ExtendAccessAsync(bandId, created.Id, extendRequest, conductorId, CancellationToken.None);

        Assert.Equal(newExpiry, result.ExpiresAt);
        Assert.True(result.IsActive);
    }

    [Fact]
    public async Task ExtendAccessAsync_RevokedAccess_ThrowsConflict()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);
        await _sut.RevokeAccessAsync(bandId, created.Id, conductorId, CancellationToken.None);

        var extendRequest = new ExtendSubstituteAccessRequest(DateTime.UtcNow.AddDays(5));
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.ExtendAccessAsync(bandId, created.Id, extendRequest, conductorId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
    }

    [Fact]
    public async Task ExtendAccessAsync_ExpiryInPast_ThrowsValidationError()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateSubstituteAccessRequest("Test", null, null, null, DateTime.UtcNow.AddDays(1), null, null);
        var created = await _sut.CreateAccessAsync(bandId, request, conductorId, CancellationToken.None);

        var extendRequest = new ExtendSubstituteAccessRequest(DateTime.UtcNow.AddDays(-1));
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.ExtendAccessAsync(bandId, created.Id, extendRequest, conductorId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
    }
}
