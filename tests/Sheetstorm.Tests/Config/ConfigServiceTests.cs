using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Config;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Config;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Config;

public class ConfigServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly ConfigService _sut;

    private static JsonElement Json(string raw) => JsonDocument.Parse(raw).RootElement.Clone();

    public ConfigServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new ConfigService(_db, new BandAuthorizationService(_db));
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> CreateAdminAsync()
    {
        var Musician = new Musician { Name = "Admin", Email = $"admin-{Guid.NewGuid()}@test.de", PasswordHash = "x" };
        var band = new Band { Name = "Testkapelle" };
        _db.Musicians.Add(Musician);
        _db.Bands.Add(band);
        await _db.SaveChangesAsync();

        _db.Memberships.Add(new Membership
        {
            MusicianId = Musician.Id,
            BandId = band.Id,
            Role = MemberRole.Administrator,
            IsActive = true
        });
        await _db.SaveChangesAsync();

        return (Musician.Id, band.Id);
    }

    private async Task<Guid> AddMemberAsync(Guid bandId, MemberRole rolle = MemberRole.Musician)
    {
        var Musician = new Musician { Name = "Musician", Email = $"m-{Guid.NewGuid()}@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        _db.Memberships.Add(new Membership
        {
            MusicianId = Musician.Id,
            BandId = bandId,
            Role = rolle,
            IsActive = true
        });
        await _db.SaveChangesAsync();

        return Musician.Id;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Band CONFIG CRUD
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetBandConfigAsync_ValidKey_PersistsEntry()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        var result = await _sut.SetBandConfigAsync(
            bandId, "band.name", new SetConfigValueRequest(Json("\"Meine Band\"")), adminId);

        Assert.True(result.Success);
        Assert.Equal("Meine Band", result.NewValue.GetString());
        Assert.Null(result.OldValue);
        var stored = await _db.ConfigBand.SingleAsync(c => c.BandId == bandId && c.Key == "band.name");
        Assert.Equal("\"Meine Band\"", stored.Value);
    }

    [Fact]
    public async Task SetBandConfigAsync_UpdateExisting_ReturnsOldValue()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetBandConfigAsync(bandId, "band.name", new SetConfigValueRequest(Json("\"Alt\"")), adminId);

        var result = await _sut.SetBandConfigAsync(
            bandId, "band.name", new SetConfigValueRequest(Json("\"Neu\"")), adminId);

        Assert.True(result.Success);
        Assert.Equal("Alt", result.OldValue!.Value.GetString());
        Assert.Equal("Neu", result.NewValue.GetString());
    }

    [Fact]
    public async Task GetBandConfigAsync_ReturnsPersisted()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetBandConfigAsync(bandId, "band.name", new SetConfigValueRequest(Json("\"Test\"")), adminId);
        await _sut.SetBandConfigAsync(bandId, "band.location", new SetConfigValueRequest(Json("\"Wien\"")), adminId);

        var list = await _sut.GetBandConfigAsync(bandId, adminId);

        Assert.Equal(2, list.Count);
        Assert.Contains(list, e => e.Key == "band.name" && e.Value.GetString() == "Test");
        Assert.Contains(list, e => e.Key == "band.location" && e.Value.GetString() == "Wien");
    }

    [Fact]
    public async Task DeleteBandConfigAsync_RemovesEntry()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetBandConfigAsync(bandId, "band.name", new SetConfigValueRequest(Json("\"Test\"")), adminId);

        await _sut.DeleteBandConfigAsync(bandId, "band.name", adminId);

        var stored = await _db.ConfigBand.FirstOrDefaultAsync(c => c.BandId == bandId && c.Key == "band.name");
        Assert.Null(stored);
    }

    [Fact]
    public async Task DeleteBandConfigAsync_NotFound_Throws404()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteBandConfigAsync(bandId, "band.name", adminId));

        Assert.Equal("CONFIG_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task SetBandConfigAsync_NonAdmin_Throws403()
    {
        var (_, bandId) = await CreateAdminAsync();
        var musicianId = await AddMemberAsync(bandId, MemberRole.Musician);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetBandConfigAsync(bandId, "band.name",
                new SetConfigValueRequest(Json("\"x\"")), musicianId));

        Assert.Equal(403, ex.StatusCode);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // NUTZER CONFIG CRUD
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetUserConfigAsync_ValidKey_PersistsEntry()
    {
        var Musician = new Musician { Name = "User", Email = "user@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        var result = await _sut.SetUserConfigAsync(
            Musician.Id, "user.theme", new SetConfigValueRequest(Json("\"dark\"")));

        Assert.True(result.Success);
        Assert.Equal("dark", result.NewValue.GetString());
        Assert.Null(result.OldValue);
    }

    [Fact]
    public async Task GetUserConfigAsync_ReturnsUserEntries()
    {
        var Musician = new Musician { Name = "User", Email = "user2@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        await _sut.SetUserConfigAsync(Musician.Id, "user.theme", new SetConfigValueRequest(Json("\"light\"")));
        await _sut.SetUserConfigAsync(Musician.Id, "user.language", new SetConfigValueRequest(Json("\"en\"")));

        var list = await _sut.GetUserConfigAsync(Musician.Id);

        Assert.Equal(2, list.Count);
        Assert.Contains(list, e => e.Key == "user.theme" && e.Value.GetString() == "light");
        Assert.Contains(list, e => e.Key == "user.language" && e.Value.GetString() == "en");
    }

    [Fact]
    public async Task SetUserConfigAsync_UpdateExisting_IncrementsVersion()
    {
        var Musician = new Musician { Name = "User", Email = "ver@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        await _sut.SetUserConfigAsync(Musician.Id, "user.theme", new SetConfigValueRequest(Json("\"dark\"")));
        await _sut.SetUserConfigAsync(Musician.Id, "user.theme", new SetConfigValueRequest(Json("\"light\"")));

        var entry = await _db.ConfigUser.SingleAsync(c => c.MusicianId == Musician.Id && c.Key == "user.theme");
        Assert.Equal(2, entry.Version);
    }

    [Fact]
    public async Task DeleteUserConfigAsync_RemovesEntry()
    {
        var Musician = new Musician { Name = "User", Email = "del@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        await _sut.SetUserConfigAsync(Musician.Id, "user.theme", new SetConfigValueRequest(Json("\"dark\"")));
        await _sut.DeleteUserConfigAsync(Musician.Id, "user.theme");

        var stored = await _db.ConfigUser.FirstOrDefaultAsync(
            c => c.MusicianId == Musician.Id && c.Key == "user.theme");
        Assert.Null(stored);
    }

    [Fact]
    public async Task DeleteUserConfigAsync_NotFound_Throws404()
    {
        var Musician = new Musician { Name = "User", Email = "delnf@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteUserConfigAsync(Musician.Id, "user.theme"));

        Assert.Equal("CONFIG_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // 3-LEVEL OVERRIDE RESOLUTION
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetResolvedConfigAsync_NoOverrides_UsesDefault()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var theme = resolved.Single(r => r.Key == "user.theme");
        Assert.Equal("system", theme.Value.GetString());
        Assert.Equal("default", theme.Level);
        Assert.False(theme.PolicyEnforced);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_KapelleSet_NutzerNot_UsesKapelle()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        // Band.sprache falls through to nutzer.sprache via equivalent-key lookup
        await _sut.SetBandConfigAsync(bandId, "band.language",
            new SetConfigValueRequest(Json("\"fr\"")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var sprache = resolved.Single(r => r.Key == "user.language");
        Assert.Equal("fr", sprache.Value.GetString());
        Assert.Equal("Band", sprache.Level);
        Assert.False(sprache.PolicyEnforced);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_NutzerAndKapelleSet_NutzerWins()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetBandConfigAsync(bandId, "band.language",
            new SetConfigValueRequest(Json("\"fr\"")), adminId);
        await _sut.SetUserConfigAsync(adminId, "user.language",
            new SetConfigValueRequest(Json("\"it\"")));

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var sprache = resolved.Single(r => r.Key == "user.language");
        Assert.Equal("it", sprache.Value.GetString());
        Assert.Equal("user", sprache.Level);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_KapelleKeyOnlyFromKapelleLevel()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetBandConfigAsync(bandId, "band.concert_pitch",
            new SetConfigValueRequest(Json("440")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var kammerton = resolved.Single(r => r.Key == "band.concert_pitch");
        Assert.Equal(440, kammerton.Value.GetInt32());
        Assert.Equal("Band", kammerton.Level);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_MissingKapelleKey_UsesRegistryDefault()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var kammerton = resolved.Single(r => r.Key == "band.concert_pitch");
        Assert.Equal(442, kammerton.Value.GetInt32());
        Assert.Equal("default", kammerton.Level);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // POLICY SYSTEM
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetPolicyAsync_ForceLocaleTrue_BlocksNutzerSpracheOverride()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetUserConfigAsync(adminId, "user.language",
            new SetConfigValueRequest(Json("\"it\"")));
        await _sut.SetPolicyAsync(bandId, "policy.force_locale",
            new SetConfigValueRequest(Json("true")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var sprache = resolved.Single(r => r.Key == "user.language");
        Assert.True(sprache.PolicyEnforced);
        Assert.NotEqual("user", sprache.Level);
    }

    [Fact]
    public async Task SetPolicyAsync_ForceLocaleFalse_AllowsNutzerSpracheOverride()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetUserConfigAsync(adminId, "user.language",
            new SetConfigValueRequest(Json("\"it\"")));
        await _sut.SetPolicyAsync(bandId, "policy.force_locale",
            new SetConfigValueRequest(Json("false")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var sprache = resolved.Single(r => r.Key == "user.language");
        Assert.False(sprache.PolicyEnforced);
        Assert.Equal("user", sprache.Level);
        Assert.Equal("it", sprache.Value.GetString());
    }

    [Fact]
    public async Task SetPolicyAsync_AllowUserAiKeysFalse_BlocksAiProviderOverride()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetUserConfigAsync(adminId, "user.ai.provider",
            new SetConfigValueRequest(Json("\"openai_vision\"")));
        await _sut.SetPolicyAsync(bandId, "policy.allow_user_ai_keys",
            new SetConfigValueRequest(Json("false")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var aiProvider = resolved.Single(r => r.Key == "user.ai.provider");
        Assert.True(aiProvider.PolicyEnforced);
        Assert.NotEqual("user", aiProvider.Level);
    }

    [Fact]
    public async Task SetPolicyAsync_AllowUserAiKeysTrue_AllowsAiProviderOverride()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetUserConfigAsync(adminId, "user.ai.provider",
            new SetConfigValueRequest(Json("\"openai_vision\"")));
        await _sut.SetPolicyAsync(bandId, "policy.allow_user_ai_keys",
            new SetConfigValueRequest(Json("true")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var aiProvider = resolved.Single(r => r.Key == "user.ai.provider");
        Assert.False(aiProvider.PolicyEnforced);
        Assert.Equal("user", aiProvider.Level);
    }

    [Fact]
    public async Task SetPolicyAsync_NonAdmin_Throws403()
    {
        var (_, bandId) = await CreateAdminAsync();
        var musicianId = await AddMemberAsync(bandId, MemberRole.Musician);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetPolicyAsync(bandId, "policy.force_locale",
                new SetConfigValueRequest(Json("true")), musicianId));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task GetPoliciesAsync_ReturnsSetPolicies()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetPolicyAsync(bandId, "policy.force_locale",
            new SetConfigValueRequest(Json("true")), adminId);

        var policies = await _sut.GetPoliciesAsync(bandId, adminId);

        Assert.Single(policies);
        Assert.Equal("policy.force_locale", policies[0].Key);
        Assert.Equal(JsonValueKind.True, policies[0].Value.ValueKind);
    }

    [Fact]
    public async Task GetPoliciesAsync_NonAdmin_Throws403()
    {
        var (_, bandId) = await CreateAdminAsync();
        var musicianId = await AddMemberAsync(bandId, MemberRole.Musician);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetPoliciesAsync(bandId, musicianId));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task DeletePolicyAsync_RemovesPolicy()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetPolicyAsync(bandId, "policy.force_locale",
            new SetConfigValueRequest(Json("true")), adminId);

        await _sut.DeletePolicyAsync(bandId, "policy.force_locale", adminId);

        var stored = await _db.ConfigPolicies.FirstOrDefaultAsync(
            p => p.BandId == bandId && p.Key == "policy.force_locale");
        Assert.Null(stored);
    }

    [Fact]
    public async Task DeletePolicyAsync_NotFound_Throws404()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeletePolicyAsync(bandId, "policy.force_locale", adminId));

        Assert.Equal("POLICY_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_IncludesPoliciesAsEntries()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetPolicyAsync(bandId, "policy.force_locale",
            new SetConfigValueRequest(Json("true")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(bandId, adminId);

        var forceLocale = resolved.SingleOrDefault(r => r.Key == "policy.force_locale");
        Assert.NotNull(forceLocale);
        Assert.Equal("policy", forceLocale.Level);
        Assert.Equal(JsonValueKind.True, forceLocale.Value.ValueKind);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // AUDIT LOGGING
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetBandConfigAsync_CreatesAuditLog()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        await _sut.SetBandConfigAsync(bandId, "band.name",
            new SetConfigValueRequest(Json("\"Test\"")), adminId);

        var audit = await _db.ConfigAudit.SingleAsync(
            a => a.Key == "band.name" && a.Level == "band");
        Assert.Equal(bandId, audit.BandId);
        Assert.Equal(adminId, audit.MusicianId);
        Assert.Null(audit.OldValue);
        Assert.Equal("\"Test\"", audit.NewValue);
        Assert.True(audit.Timestamp > DateTime.UtcNow.AddMinutes(-1));
    }

    [Fact]
    public async Task SetBandConfigAsync_Update_AuditLogHasOldAndNewValue()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetBandConfigAsync(bandId, "band.name",
            new SetConfigValueRequest(Json("\"Alt\"")), adminId);
        await _sut.SetBandConfigAsync(bandId, "band.name",
            new SetConfigValueRequest(Json("\"Neu\"")), adminId);

        var audits = await _db.ConfigAudit
            .Where(a => a.Key == "band.name" && a.Level == "band")
            .OrderBy(a => a.Timestamp)
            .ToListAsync();

        Assert.Equal(2, audits.Count);
        Assert.Null(audits[0].OldValue);
        Assert.Equal("\"Alt\"", audits[1].OldValue);
        Assert.Equal("\"Neu\"", audits[1].NewValue);
    }

    [Fact]
    public async Task SetUserConfigAsync_CreatesAuditLog()
    {
        var Musician = new Musician { Name = "User", Email = "audit@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        await _sut.SetUserConfigAsync(Musician.Id, "user.theme",
            new SetConfigValueRequest(Json("\"dark\"")));

        var audit = await _db.ConfigAudit.SingleAsync(
            a => a.Key == "user.theme" && a.Level == "user");
        Assert.Equal(Musician.Id, audit.MusicianId);
        Assert.Null(audit.OldValue);
        Assert.Equal("\"dark\"", audit.NewValue);
    }

    [Fact]
    public async Task SetPolicyAsync_CreatesAuditLog()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        await _sut.SetPolicyAsync(bandId, "policy.force_locale",
            new SetConfigValueRequest(Json("true")), adminId);

        var audit = await _db.ConfigAudit.SingleAsync(
            a => a.Key == "policy.force_locale" && a.Level == "policy");
        Assert.Equal(bandId, audit.BandId);
        Assert.Equal(adminId, audit.MusicianId);
        Assert.Equal("true", audit.NewValue);
    }

    [Fact]
    public async Task DeleteBandConfigAsync_AuditLogsOldValueWithNullNewValue()
    {
        var (adminId, bandId) = await CreateAdminAsync();
        await _sut.SetBandConfigAsync(bandId, "band.name",
            new SetConfigValueRequest(Json("\"Wird gelöscht\"")), adminId);

        await _sut.DeleteBandConfigAsync(bandId, "band.name", adminId);

        var deleteAudit = await _db.ConfigAudit
            .Where(a => a.Key == "band.name" && a.NewValue == null)
            .SingleAsync();
        Assert.Equal("\"Wird gelöscht\"", deleteAudit.OldValue);
        Assert.Null(deleteAudit.NewValue);
    }

    [Fact]
    public async Task DeleteUserConfigAsync_AuditLogsOldValue()
    {
        var Musician = new Musician { Name = "User", Email = "auddel@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();
        await _sut.SetUserConfigAsync(Musician.Id, "user.theme",
            new SetConfigValueRequest(Json("\"dark\"")));

        await _sut.DeleteUserConfigAsync(Musician.Id, "user.theme");

        var deleteAudit = await _db.ConfigAudit
            .Where(a => a.Key == "user.theme" && a.NewValue == null)
            .SingleAsync();
        Assert.Equal("\"dark\"", deleteAudit.OldValue);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetBandConfigAsync_UnknownKey_Throws400()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetBandConfigAsync(bandId, "unbekannt.schluessel",
                new SetConfigValueRequest(Json("\"x\"")), adminId));

        Assert.Equal("INVALID_CONFIG_KEY", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task SetBandConfigAsync_NutzerLevelKey_Throws400()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetBandConfigAsync(bandId, "user.theme",
                new SetConfigValueRequest(Json("\"dark\"")), adminId));

        Assert.Equal("INVALID_CONFIG_KEY", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task SetBandConfigAsync_WrongType_Throws422()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        // Band.name expects String, not a number
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetBandConfigAsync(bandId, "band.name",
                new SetConfigValueRequest(Json("42")), adminId));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetBandConfigAsync_IntBelowMin_Throws422()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        // Band.kammerton MinValue=415
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetBandConfigAsync(bandId, "band.concert_pitch",
                new SetConfigValueRequest(Json("400")), adminId));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetBandConfigAsync_IntAboveMax_Throws422()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        // Band.kammerton MaxValue=466
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetBandConfigAsync(bandId, "band.concert_pitch",
                new SetConfigValueRequest(Json("500")), adminId));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetUserConfigAsync_InvalidEnumValue_Throws422()
    {
        var Musician = new Musician { Name = "User", Email = "valenum@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        // nutzer.theme only allows "dark", "light", "system"
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetUserConfigAsync(Musician.Id, "user.theme",
                new SetConfigValueRequest(Json("\"blau\""))));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetUserConfigAsync_FloatBelowMin_Throws422()
    {
        var Musician = new Musician { Name = "User", Email = "valfloat@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        // nutzer.spielmodus.half_page_ratio MinFloat=0.3
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetUserConfigAsync(Musician.Id, "user.performance_mode.half_page_ratio",
                new SetConfigValueRequest(Json("0.1"))));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetUserConfigAsync_FloatAboveMax_Throws422()
    {
        var Musician = new Musician { Name = "User", Email = "valfmax@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        // nutzer.spielmodus.half_page_ratio MaxFloat=0.7
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetUserConfigAsync(Musician.Id, "user.performance_mode.half_page_ratio",
                new SetConfigValueRequest(Json("0.9"))));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetUserConfigAsync_UnknownKey_Throws400()
    {
        var Musician = new Musician { Name = "User", Email = "valunk@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetUserConfigAsync(Musician.Id, "kein.schluessel",
                new SetConfigValueRequest(Json("\"x\""))));

        Assert.Equal("INVALID_CONFIG_KEY", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task SetUserConfigAsync_KapelleLevelKey_Throws400()
    {
        var Musician = new Musician { Name = "User", Email = "valkap@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetUserConfigAsync(Musician.Id, "band.name",
                new SetConfigValueRequest(Json("\"x\""))));

        Assert.Equal("INVALID_CONFIG_KEY", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task SetPolicyAsync_NonPolicyKey_Throws400()
    {
        var (adminId, bandId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetPolicyAsync(bandId, "band.name",
                new SetConfigValueRequest(Json("\"x\"")), adminId));

        Assert.Equal("INVALID_POLICY_KEY", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // CONFIG KEY REGISTRY (Pure Unit Tests — no DB)
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public void ConfigKeyRegistry_UnknownKey_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("nicht.vorhanden", Json("\"x\""));
        Assert.NotNull(error);
        Assert.Contains("Unknown", error);
    }

    [Fact]
    public void ConfigKeyRegistry_BoolTypeMismatch_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("band.ai.enabled", Json("\"ja\""));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_ValidBool_ReturnsNull()
    {
        var error = ConfigKeyRegistry.Validate("band.ai.enabled", Json("true"));
        Assert.Null(error);
    }

    [Fact]
    public void ConfigKeyRegistry_IntOutOfRange_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("band.concert_pitch", Json("414"));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_ValidInt_ReturnsNull()
    {
        var error = ConfigKeyRegistry.Validate("band.concert_pitch", Json("440"));
        Assert.Null(error);
    }

    [Fact]
    public void ConfigKeyRegistry_InvalidEnumValue_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("user.theme", Json("\"blau\""));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_ValidEnumValue_ReturnsNull()
    {
        var error = ConfigKeyRegistry.Validate("user.theme", Json("\"dark\""));
        Assert.Null(error);
    }

    [Fact]
    public void ConfigKeyRegistry_FloatBelowMin_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("user.performance_mode.half_page_ratio", Json("0.1"));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_FloatAboveMax_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("user.performance_mode.half_page_ratio", Json("0.9"));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_ValidFloat_ReturnsNull()
    {
        var error = ConfigKeyRegistry.Validate("user.performance_mode.half_page_ratio", Json("0.5"));
        Assert.Null(error);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // EDGE CASES
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetBandConfigAsync_NonMember_ThrowsNotFound()
    {
        var (_, bandId) = await CreateAdminAsync();
        var stranger = new Musician { Name = "X", Email = "stranger@test.de", PasswordHash = "x" };
        _db.Musicians.Add(stranger);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetBandConfigAsync(bandId, stranger.Id));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task MultiKapelleUser_SeparateConfigsPerKapelle()
    {
        var Musician = new Musician { Name = "MultiUser", Email = "multi@test.de", PasswordHash = "x" };
        var kapelle1 = new Band { Name = "Alpha" };
        var kapelle2 = new Band { Name = "Beta" };
        _db.Musicians.Add(Musician);
        _db.Bands.AddRange(kapelle1, kapelle2);
        await _db.SaveChangesAsync();

        var admin1 = new Musician { Name = "A1", Email = "a1@test.de", PasswordHash = "x" };
        var admin2 = new Musician { Name = "A2", Email = "a2@test.de", PasswordHash = "x" };
        _db.Musicians.AddRange(admin1, admin2);
        await _db.SaveChangesAsync();

        _db.Memberships.AddRange(
            new Membership { MusicianId = admin1.Id, BandId = kapelle1.Id, Role = MemberRole.Administrator, IsActive = true },
            new Membership { MusicianId = admin2.Id, BandId = kapelle2.Id, Role = MemberRole.Administrator, IsActive = true },
            new Membership { MusicianId = Musician.Id, BandId = kapelle1.Id, Role = MemberRole.Musician, IsActive = true },
            new Membership { MusicianId = Musician.Id, BandId = kapelle2.Id, Role = MemberRole.Musician, IsActive = true }
        );
        await _db.SaveChangesAsync();

        await _sut.SetBandConfigAsync(kapelle1.Id, "band.name",
            new SetConfigValueRequest(Json("\"Band Alpha\"")), admin1.Id);
        await _sut.SetBandConfigAsync(kapelle2.Id, "band.name",
            new SetConfigValueRequest(Json("\"Band Beta\"")), admin2.Id);

        var resolved1 = await _sut.GetResolvedConfigAsync(kapelle1.Id, Musician.Id);
        var resolved2 = await _sut.GetResolvedConfigAsync(kapelle2.Id, Musician.Id);

        var name1 = resolved1.Single(r => r.Key == "band.name");
        var name2 = resolved2.Single(r => r.Key == "band.name");

        Assert.Equal("Band Alpha", name1.Value.GetString());
        Assert.Equal("Band Beta", name2.Value.GetString());
    }

    [Fact]
    public async Task MultiKapelleUser_PolicyOnlyAffectsItsKapelle()
    {
        var Musician = new Musician { Name = "PolicyUser", Email = "policy-multi@test.de", PasswordHash = "x" };
        var kapelle1 = new Band { Name = "Locked" };
        var kapelle2 = new Band { Name = "Free" };
        _db.Musicians.Add(Musician);
        _db.Bands.AddRange(kapelle1, kapelle2);
        await _db.SaveChangesAsync();

        var admin1 = new Musician { Name = "A1", Email = "pm-a1@test.de", PasswordHash = "x" };
        var admin2 = new Musician { Name = "A2", Email = "pm-a2@test.de", PasswordHash = "x" };
        _db.Musicians.AddRange(admin1, admin2);
        await _db.SaveChangesAsync();

        _db.Memberships.AddRange(
            new Membership { MusicianId = admin1.Id, BandId = kapelle1.Id, Role = MemberRole.Administrator, IsActive = true },
            new Membership { MusicianId = admin2.Id, BandId = kapelle2.Id, Role = MemberRole.Administrator, IsActive = true },
            new Membership { MusicianId = Musician.Id, BandId = kapelle1.Id, Role = MemberRole.Musician, IsActive = true },
            new Membership { MusicianId = Musician.Id, BandId = kapelle2.Id, Role = MemberRole.Musician, IsActive = true }
        );
        await _db.SaveChangesAsync();

        await _sut.SetUserConfigAsync(Musician.Id, "user.language", new SetConfigValueRequest(Json("\"it\"")));
        // Lock locale in kapelle1 only
        await _sut.SetPolicyAsync(kapelle1.Id, "policy.force_locale",
            new SetConfigValueRequest(Json("true")), admin1.Id);

        var resolved1 = await _sut.GetResolvedConfigAsync(kapelle1.Id, Musician.Id);
        var resolved2 = await _sut.GetResolvedConfigAsync(kapelle2.Id, Musician.Id);

        var sprache1 = resolved1.Single(r => r.Key == "user.language");
        var sprache2 = resolved2.Single(r => r.Key == "user.language");

        Assert.True(sprache1.PolicyEnforced);    // Locked in kapelle1
        Assert.False(sprache2.PolicyEnforced);   // Free in kapelle2
        Assert.Equal("user", sprache2.Level);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // SYNC — CONCURRENT UPDATE / VERSION CONFLICT
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SyncUserConfigAsync_NewEntry_Applied()
    {
        var Musician = new Musician { Name = "Sync", Email = "sync@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEntry("user.theme", Json("\"dark\""), 1, DateTime.UtcNow)
        });

        var resp = await _sut.SyncUserConfigAsync(Musician.Id, req);

        Assert.Single(resp.Applied);
        Assert.Equal("user.theme", resp.Applied[0].Key);
        Assert.Empty(resp.Conflicts);
    }

    [Fact]
    public async Task SyncUserConfigAsync_ClientVersionNewer_ClientWins()
    {
        var Musician = new Musician { Name = "Sync2", Email = "sync2@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        _db.ConfigUser.Add(new ConfigUser
        {
            MusicianId = Musician.Id, Key = "user.theme", Value = "\"light\"", Version = 1
        });
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEntry("user.theme", Json("\"dark\""), 5, DateTime.UtcNow)
        });

        var resp = await _sut.SyncUserConfigAsync(Musician.Id, req);

        Assert.Single(resp.Applied);
        Assert.Empty(resp.Conflicts);
        var stored = await _db.ConfigUser.SingleAsync(
            c => c.MusicianId == Musician.Id && c.Key == "user.theme");
        Assert.Equal(5, stored.Version);
        Assert.Equal("\"dark\"", stored.Value);
    }

    [Fact]
    public async Task SyncUserConfigAsync_ServerVersionNewer_Conflict()
    {
        var Musician = new Musician { Name = "Sync3", Email = "sync3@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        _db.ConfigUser.Add(new ConfigUser
        {
            MusicianId = Musician.Id, Key = "user.theme", Value = "\"dark\"", Version = 10
        });
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEntry("user.theme", Json("\"light\""), 3, DateTime.UtcNow)
        });

        var resp = await _sut.SyncUserConfigAsync(Musician.Id, req);

        Assert.Empty(resp.Applied);
        Assert.Single(resp.Conflicts);
        Assert.Equal("user.theme", resp.Conflicts[0].Key);
        Assert.Equal(10, resp.Conflicts[0].ServerVersion);
    }

    [Fact]
    public async Task SyncUserConfigAsync_SameVersionNewerClientTimestamp_ClientWins()
    {
        var Musician = new Musician { Name = "Sync4", Email = "sync4@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        _db.ConfigUser.Add(new ConfigUser
        {
            MusicianId = Musician.Id, Key = "user.theme", Value = "\"light\"", Version = 2
        });
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEntry("user.theme", Json("\"dark\""), 2, DateTime.UtcNow.AddMinutes(5))
        });

        var resp = await _sut.SyncUserConfigAsync(Musician.Id, req);

        Assert.Single(resp.Applied);
        Assert.Empty(resp.Conflicts);
    }

    [Fact]
    public async Task SyncUserConfigAsync_UnknownKey_SkippedSilently()
    {
        var Musician = new Musician { Name = "Sync5", Email = "sync5@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEntry("kein.schluessel", Json("\"x\""), 1, DateTime.UtcNow)
        });

        var resp = await _sut.SyncUserConfigAsync(Musician.Id, req);

        Assert.Empty(resp.Applied);
        Assert.Empty(resp.Conflicts);
    }

    [Fact]
    public async Task SyncUserConfigAsync_KapelleLevelKey_SkippedSilently()
    {
        var Musician = new Musician { Name = "Sync6", Email = "sync6@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEntry("band.name", Json("\"x\""), 1, DateTime.UtcNow)
        });

        var resp = await _sut.SyncUserConfigAsync(Musician.Id, req);

        Assert.Empty(resp.Applied);
        Assert.Empty(resp.Conflicts);
    }

    [Fact]
    public async Task SyncUserConfigAsync_ServerChangesReturnedForFullSync()
    {
        var Musician = new Musician { Name = "Sync7", Email = "sync7@test.de", PasswordHash = "x" };
        _db.Musicians.Add(Musician);
        await _db.SaveChangesAsync();

        // Pre-seed server entry
        _db.ConfigUser.Add(new ConfigUser
        {
            MusicianId = Musician.Id, Key = "user.language", Value = "\"fr\"", Version = 3
        });
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEntry("user.theme", Json("\"dark\""), 1, DateTime.UtcNow)
        });

        var resp = await _sut.SyncUserConfigAsync(Musician.Id, req);

        // ServerChanges must include all entries (both the new and the pre-seeded)
        Assert.Equal(2, resp.ServerChanges.Count);
        Assert.Contains(resp.ServerChanges, e => e.Key == "user.language");
        Assert.Contains(resp.ServerChanges, e => e.Key == "user.theme");
    }
}
