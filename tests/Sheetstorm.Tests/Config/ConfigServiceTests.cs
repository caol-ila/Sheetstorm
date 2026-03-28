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
        _sut = new ConfigService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musikerId, Guid kapelleId)> CreateAdminAsync()
    {
        var musiker = new Musiker { Name = "Admin", Email = $"admin-{Guid.NewGuid()}@test.de", PasswordHash = "x" };
        var kapelle = new Kapelle { Name = "Testkapelle" };
        _db.Musiker.Add(musiker);
        _db.Kapellen.Add(kapelle);
        await _db.SaveChangesAsync();

        _db.Mitgliedschaften.Add(new Mitgliedschaft
        {
            MusikerID = musiker.Id,
            KapelleID = kapelle.Id,
            Rolle = MitgliedRolle.Administrator,
            IstAktiv = true
        });
        await _db.SaveChangesAsync();

        return (musiker.Id, kapelle.Id);
    }

    private async Task<Guid> AddMemberAsync(Guid kapelleId, MitgliedRolle rolle = MitgliedRolle.Musiker)
    {
        var musiker = new Musiker { Name = "Musiker", Email = $"m-{Guid.NewGuid()}@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        _db.Mitgliedschaften.Add(new Mitgliedschaft
        {
            MusikerID = musiker.Id,
            KapelleID = kapelleId,
            Rolle = rolle,
            IstAktiv = true
        });
        await _db.SaveChangesAsync();

        return musiker.Id;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // KAPELLE CONFIG CRUD
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetKapelleConfigAsync_ValidKey_PersistsEntry()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        var result = await _sut.SetKapelleConfigAsync(
            kapelleId, "kapelle.name", new ConfigWertSetzenRequest(Json("\"Meine Kapelle\"")), adminId);

        Assert.True(result.Success);
        Assert.Equal("Meine Kapelle", result.NeuerWert.GetString());
        Assert.Null(result.AlterWert);
        var stored = await _db.ConfigKapelle.SingleAsync(c => c.KapelleId == kapelleId && c.Schluessel == "kapelle.name");
        Assert.Equal("\"Meine Kapelle\"", stored.Wert);
    }

    [Fact]
    public async Task SetKapelleConfigAsync_UpdateExisting_ReturnsAlterWert()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.name", new ConfigWertSetzenRequest(Json("\"Alt\"")), adminId);

        var result = await _sut.SetKapelleConfigAsync(
            kapelleId, "kapelle.name", new ConfigWertSetzenRequest(Json("\"Neu\"")), adminId);

        Assert.True(result.Success);
        Assert.Equal("Alt", result.AlterWert!.Value.GetString());
        Assert.Equal("Neu", result.NeuerWert.GetString());
    }

    [Fact]
    public async Task GetKapelleConfigAsync_ReturnsPersisted()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.name", new ConfigWertSetzenRequest(Json("\"Test\"")), adminId);
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.ort", new ConfigWertSetzenRequest(Json("\"Wien\"")), adminId);

        var list = await _sut.GetKapelleConfigAsync(kapelleId, adminId);

        Assert.Equal(2, list.Count);
        Assert.Contains(list, e => e.Schluessel == "kapelle.name" && e.Wert.GetString() == "Test");
        Assert.Contains(list, e => e.Schluessel == "kapelle.ort" && e.Wert.GetString() == "Wien");
    }

    [Fact]
    public async Task DeleteKapelleConfigAsync_RemovesEntry()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.name", new ConfigWertSetzenRequest(Json("\"Test\"")), adminId);

        await _sut.DeleteKapelleConfigAsync(kapelleId, "kapelle.name", adminId);

        var stored = await _db.ConfigKapelle.FirstOrDefaultAsync(c => c.KapelleId == kapelleId && c.Schluessel == "kapelle.name");
        Assert.Null(stored);
    }

    [Fact]
    public async Task DeleteKapelleConfigAsync_NotFound_Throws404()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteKapelleConfigAsync(kapelleId, "kapelle.name", adminId));

        Assert.Equal("CONFIG_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task SetKapelleConfigAsync_NonAdmin_Throws403()
    {
        var (_, kapelleId) = await CreateAdminAsync();
        var musikerId = await AddMemberAsync(kapelleId, MitgliedRolle.Musiker);

        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.SetKapelleConfigAsync(kapelleId, "kapelle.name",
                new ConfigWertSetzenRequest(Json("\"x\"")), musikerId));

        Assert.Equal(403, ex.StatusCode);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // NUTZER CONFIG CRUD
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetNutzerConfigAsync_ValidKey_PersistsEntry()
    {
        var musiker = new Musiker { Name = "User", Email = "user@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        var result = await _sut.SetNutzerConfigAsync(
            musiker.Id, "nutzer.theme", new ConfigWertSetzenRequest(Json("\"dark\"")));

        Assert.True(result.Success);
        Assert.Equal("dark", result.NeuerWert.GetString());
        Assert.Null(result.AlterWert);
    }

    [Fact]
    public async Task GetNutzerConfigAsync_ReturnsUserEntries()
    {
        var musiker = new Musiker { Name = "User", Email = "user2@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        await _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.theme", new ConfigWertSetzenRequest(Json("\"light\"")));
        await _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.sprache", new ConfigWertSetzenRequest(Json("\"en\"")));

        var list = await _sut.GetNutzerConfigAsync(musiker.Id);

        Assert.Equal(2, list.Count);
        Assert.Contains(list, e => e.Schluessel == "nutzer.theme" && e.Wert.GetString() == "light");
        Assert.Contains(list, e => e.Schluessel == "nutzer.sprache" && e.Wert.GetString() == "en");
    }

    [Fact]
    public async Task SetNutzerConfigAsync_UpdateExisting_IncrementsVersion()
    {
        var musiker = new Musiker { Name = "User", Email = "ver@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        await _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.theme", new ConfigWertSetzenRequest(Json("\"dark\"")));
        await _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.theme", new ConfigWertSetzenRequest(Json("\"light\"")));

        var entry = await _db.ConfigNutzer.SingleAsync(c => c.MusikerId == musiker.Id && c.Schluessel == "nutzer.theme");
        Assert.Equal(2, entry.Version);
    }

    [Fact]
    public async Task DeleteNutzerConfigAsync_RemovesEntry()
    {
        var musiker = new Musiker { Name = "User", Email = "del@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        await _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.theme", new ConfigWertSetzenRequest(Json("\"dark\"")));
        await _sut.DeleteNutzerConfigAsync(musiker.Id, "nutzer.theme");

        var stored = await _db.ConfigNutzer.FirstOrDefaultAsync(
            c => c.MusikerId == musiker.Id && c.Schluessel == "nutzer.theme");
        Assert.Null(stored);
    }

    [Fact]
    public async Task DeleteNutzerConfigAsync_NotFound_Throws404()
    {
        var musiker = new Musiker { Name = "User", Email = "delnf@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteNutzerConfigAsync(musiker.Id, "nutzer.theme"));

        Assert.Equal("CONFIG_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // 3-LEVEL OVERRIDE RESOLUTION
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetResolvedConfigAsync_NoOverrides_UsesDefault()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var theme = resolved.Single(r => r.Schluessel == "nutzer.theme");
        Assert.Equal("system", theme.Wert.GetString());
        Assert.Equal("default", theme.Ebene);
        Assert.False(theme.PolicyEnforced);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_KapelleSet_NutzerNot_UsesKapelle()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        // kapelle.sprache falls through to nutzer.sprache via equivalent-key lookup
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.sprache",
            new ConfigWertSetzenRequest(Json("\"fr\"")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var sprache = resolved.Single(r => r.Schluessel == "nutzer.sprache");
        Assert.Equal("fr", sprache.Wert.GetString());
        Assert.Equal("kapelle", sprache.Ebene);
        Assert.False(sprache.PolicyEnforced);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_NutzerAndKapelleSet_NutzerWins()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.sprache",
            new ConfigWertSetzenRequest(Json("\"fr\"")), adminId);
        await _sut.SetNutzerConfigAsync(adminId, "nutzer.sprache",
            new ConfigWertSetzenRequest(Json("\"it\"")));

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var sprache = resolved.Single(r => r.Schluessel == "nutzer.sprache");
        Assert.Equal("it", sprache.Wert.GetString());
        Assert.Equal("nutzer", sprache.Ebene);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_KapelleKeyOnlyFromKapelleLevel()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.kammerton",
            new ConfigWertSetzenRequest(Json("440")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var kammerton = resolved.Single(r => r.Schluessel == "kapelle.kammerton");
        Assert.Equal(440, kammerton.Wert.GetInt32());
        Assert.Equal("kapelle", kammerton.Ebene);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_MissingKapelleKey_UsesRegistryDefault()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var kammerton = resolved.Single(r => r.Schluessel == "kapelle.kammerton");
        Assert.Equal(442, kammerton.Wert.GetInt32());
        Assert.Equal("default", kammerton.Ebene);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // POLICY SYSTEM
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetPolicyAsync_ForceLocaleTrue_BlocksNutzerSpracheOverride()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetNutzerConfigAsync(adminId, "nutzer.sprache",
            new ConfigWertSetzenRequest(Json("\"it\"")));
        await _sut.SetPolicyAsync(kapelleId, "policy.force_locale",
            new ConfigWertSetzenRequest(Json("true")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var sprache = resolved.Single(r => r.Schluessel == "nutzer.sprache");
        Assert.True(sprache.PolicyEnforced);
        Assert.NotEqual("nutzer", sprache.Ebene);
    }

    [Fact]
    public async Task SetPolicyAsync_ForceLocaleFalse_AllowsNutzerSpracheOverride()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetNutzerConfigAsync(adminId, "nutzer.sprache",
            new ConfigWertSetzenRequest(Json("\"it\"")));
        await _sut.SetPolicyAsync(kapelleId, "policy.force_locale",
            new ConfigWertSetzenRequest(Json("false")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var sprache = resolved.Single(r => r.Schluessel == "nutzer.sprache");
        Assert.False(sprache.PolicyEnforced);
        Assert.Equal("nutzer", sprache.Ebene);
        Assert.Equal("it", sprache.Wert.GetString());
    }

    [Fact]
    public async Task SetPolicyAsync_AllowUserAiKeysFalse_BlocksAiProviderOverride()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetNutzerConfigAsync(adminId, "nutzer.ai.provider",
            new ConfigWertSetzenRequest(Json("\"openai_vision\"")));
        await _sut.SetPolicyAsync(kapelleId, "policy.allow_user_ai_keys",
            new ConfigWertSetzenRequest(Json("false")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var aiProvider = resolved.Single(r => r.Schluessel == "nutzer.ai.provider");
        Assert.True(aiProvider.PolicyEnforced);
        Assert.NotEqual("nutzer", aiProvider.Ebene);
    }

    [Fact]
    public async Task SetPolicyAsync_AllowUserAiKeysTrue_AllowsAiProviderOverride()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetNutzerConfigAsync(adminId, "nutzer.ai.provider",
            new ConfigWertSetzenRequest(Json("\"openai_vision\"")));
        await _sut.SetPolicyAsync(kapelleId, "policy.allow_user_ai_keys",
            new ConfigWertSetzenRequest(Json("true")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var aiProvider = resolved.Single(r => r.Schluessel == "nutzer.ai.provider");
        Assert.False(aiProvider.PolicyEnforced);
        Assert.Equal("nutzer", aiProvider.Ebene);
    }

    [Fact]
    public async Task SetPolicyAsync_NonAdmin_Throws403()
    {
        var (_, kapelleId) = await CreateAdminAsync();
        var musikerId = await AddMemberAsync(kapelleId, MitgliedRolle.Musiker);

        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.SetPolicyAsync(kapelleId, "policy.force_locale",
                new ConfigWertSetzenRequest(Json("true")), musikerId));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task GetPoliciesAsync_ReturnsSetPolicies()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetPolicyAsync(kapelleId, "policy.force_locale",
            new ConfigWertSetzenRequest(Json("true")), adminId);

        var policies = await _sut.GetPoliciesAsync(kapelleId, adminId);

        Assert.Single(policies);
        Assert.Equal("policy.force_locale", policies[0].Schluessel);
        Assert.Equal(JsonValueKind.True, policies[0].Wert.ValueKind);
    }

    [Fact]
    public async Task GetPoliciesAsync_NonAdmin_Throws403()
    {
        var (_, kapelleId) = await CreateAdminAsync();
        var musikerId = await AddMemberAsync(kapelleId, MitgliedRolle.Musiker);

        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.GetPoliciesAsync(kapelleId, musikerId));

        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task DeletePolicyAsync_RemovesPolicy()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetPolicyAsync(kapelleId, "policy.force_locale",
            new ConfigWertSetzenRequest(Json("true")), adminId);

        await _sut.DeletePolicyAsync(kapelleId, "policy.force_locale", adminId);

        var stored = await _db.ConfigPolicies.FirstOrDefaultAsync(
            p => p.KapelleId == kapelleId && p.Schluessel == "policy.force_locale");
        Assert.Null(stored);
    }

    [Fact]
    public async Task DeletePolicyAsync_NotFound_Throws404()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeletePolicyAsync(kapelleId, "policy.force_locale", adminId));

        Assert.Equal("POLICY_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task GetResolvedConfigAsync_IncludesPoliciesAsEntries()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetPolicyAsync(kapelleId, "policy.force_locale",
            new ConfigWertSetzenRequest(Json("true")), adminId);

        var resolved = await _sut.GetResolvedConfigAsync(kapelleId, adminId);

        var forceLocale = resolved.SingleOrDefault(r => r.Schluessel == "policy.force_locale");
        Assert.NotNull(forceLocale);
        Assert.Equal("policy", forceLocale.Ebene);
        Assert.Equal(JsonValueKind.True, forceLocale.Wert.ValueKind);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // AUDIT LOGGING
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetKapelleConfigAsync_CreatesAuditLog()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.name",
            new ConfigWertSetzenRequest(Json("\"Test\"")), adminId);

        var audit = await _db.ConfigAudit.SingleAsync(
            a => a.Schluessel == "kapelle.name" && a.Ebene == "kapelle");
        Assert.Equal(kapelleId, audit.KapelleId);
        Assert.Equal(adminId, audit.MusikerId);
        Assert.Null(audit.AlterWert);
        Assert.Equal("\"Test\"", audit.NeuerWert);
        Assert.True(audit.Zeitstempel > DateTime.UtcNow.AddMinutes(-1));
    }

    [Fact]
    public async Task SetKapelleConfigAsync_Update_AuditLogHasOldAndNewValue()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.name",
            new ConfigWertSetzenRequest(Json("\"Alt\"")), adminId);
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.name",
            new ConfigWertSetzenRequest(Json("\"Neu\"")), adminId);

        var audits = await _db.ConfigAudit
            .Where(a => a.Schluessel == "kapelle.name" && a.Ebene == "kapelle")
            .OrderBy(a => a.Zeitstempel)
            .ToListAsync();

        Assert.Equal(2, audits.Count);
        Assert.Null(audits[0].AlterWert);
        Assert.Equal("\"Alt\"", audits[1].AlterWert);
        Assert.Equal("\"Neu\"", audits[1].NeuerWert);
    }

    [Fact]
    public async Task SetNutzerConfigAsync_CreatesAuditLog()
    {
        var musiker = new Musiker { Name = "User", Email = "audit@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        await _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.theme",
            new ConfigWertSetzenRequest(Json("\"dark\"")));

        var audit = await _db.ConfigAudit.SingleAsync(
            a => a.Schluessel == "nutzer.theme" && a.Ebene == "nutzer");
        Assert.Equal(musiker.Id, audit.MusikerId);
        Assert.Null(audit.AlterWert);
        Assert.Equal("\"dark\"", audit.NeuerWert);
    }

    [Fact]
    public async Task SetPolicyAsync_CreatesAuditLog()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        await _sut.SetPolicyAsync(kapelleId, "policy.force_locale",
            new ConfigWertSetzenRequest(Json("true")), adminId);

        var audit = await _db.ConfigAudit.SingleAsync(
            a => a.Schluessel == "policy.force_locale" && a.Ebene == "policy");
        Assert.Equal(kapelleId, audit.KapelleId);
        Assert.Equal(adminId, audit.MusikerId);
        Assert.Equal("true", audit.NeuerWert);
    }

    [Fact]
    public async Task DeleteKapelleConfigAsync_AuditLogsOldValueWithNullNeuerWert()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();
        await _sut.SetKapelleConfigAsync(kapelleId, "kapelle.name",
            new ConfigWertSetzenRequest(Json("\"Wird gelöscht\"")), adminId);

        await _sut.DeleteKapelleConfigAsync(kapelleId, "kapelle.name", adminId);

        var deleteAudit = await _db.ConfigAudit
            .Where(a => a.Schluessel == "kapelle.name" && a.NeuerWert == null)
            .SingleAsync();
        Assert.Equal("\"Wird gelöscht\"", deleteAudit.AlterWert);
        Assert.Null(deleteAudit.NeuerWert);
    }

    [Fact]
    public async Task DeleteNutzerConfigAsync_AuditLogsOldValue()
    {
        var musiker = new Musiker { Name = "User", Email = "auddel@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();
        await _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.theme",
            new ConfigWertSetzenRequest(Json("\"dark\"")));

        await _sut.DeleteNutzerConfigAsync(musiker.Id, "nutzer.theme");

        var deleteAudit = await _db.ConfigAudit
            .Where(a => a.Schluessel == "nutzer.theme" && a.NeuerWert == null)
            .SingleAsync();
        Assert.Equal("\"dark\"", deleteAudit.AlterWert);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SetKapelleConfigAsync_UnknownKey_Throws400()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetKapelleConfigAsync(kapelleId, "unbekannt.schluessel",
                new ConfigWertSetzenRequest(Json("\"x\"")), adminId));

        Assert.Equal("INVALID_CONFIG_KEY", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task SetKapelleConfigAsync_NutzerLevelKey_Throws400()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetKapelleConfigAsync(kapelleId, "nutzer.theme",
                new ConfigWertSetzenRequest(Json("\"dark\"")), adminId));

        Assert.Equal("INVALID_CONFIG_KEY", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task SetKapelleConfigAsync_WrongType_Throws422()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        // kapelle.name expects String, not a number
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetKapelleConfigAsync(kapelleId, "kapelle.name",
                new ConfigWertSetzenRequest(Json("42")), adminId));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetKapelleConfigAsync_IntBelowMin_Throws422()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        // kapelle.kammerton MinValue=415
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetKapelleConfigAsync(kapelleId, "kapelle.kammerton",
                new ConfigWertSetzenRequest(Json("400")), adminId));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetKapelleConfigAsync_IntAboveMax_Throws422()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        // kapelle.kammerton MaxValue=466
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetKapelleConfigAsync(kapelleId, "kapelle.kammerton",
                new ConfigWertSetzenRequest(Json("500")), adminId));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetNutzerConfigAsync_InvalidEnumValue_Throws422()
    {
        var musiker = new Musiker { Name = "User", Email = "valenum@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        // nutzer.theme only allows "dark", "light", "system"
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.theme",
                new ConfigWertSetzenRequest(Json("\"blau\""))));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetNutzerConfigAsync_FloatBelowMin_Throws422()
    {
        var musiker = new Musiker { Name = "User", Email = "valfloat@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        // nutzer.spielmodus.half_page_ratio MinFloat=0.3
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.spielmodus.half_page_ratio",
                new ConfigWertSetzenRequest(Json("0.1"))));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetNutzerConfigAsync_FloatAboveMax_Throws422()
    {
        var musiker = new Musiker { Name = "User", Email = "valfmax@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        // nutzer.spielmodus.half_page_ratio MaxFloat=0.7
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.spielmodus.half_page_ratio",
                new ConfigWertSetzenRequest(Json("0.9"))));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task SetNutzerConfigAsync_UnknownKey_Throws400()
    {
        var musiker = new Musiker { Name = "User", Email = "valunk@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetNutzerConfigAsync(musiker.Id, "kein.schluessel",
                new ConfigWertSetzenRequest(Json("\"x\""))));

        Assert.Equal("INVALID_CONFIG_KEY", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task SetNutzerConfigAsync_KapelleLevelKey_Throws400()
    {
        var musiker = new Musiker { Name = "User", Email = "valkap@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetNutzerConfigAsync(musiker.Id, "kapelle.name",
                new ConfigWertSetzenRequest(Json("\"x\""))));

        Assert.Equal("INVALID_CONFIG_KEY", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task SetPolicyAsync_NonPolicyKey_Throws400()
    {
        var (adminId, kapelleId) = await CreateAdminAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetPolicyAsync(kapelleId, "kapelle.name",
                new ConfigWertSetzenRequest(Json("\"x\"")), adminId));

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
        Assert.Contains("Unbekannter", error);
    }

    [Fact]
    public void ConfigKeyRegistry_BoolTypeMismatch_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("kapelle.ai.enabled", Json("\"ja\""));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_ValidBool_ReturnsNull()
    {
        var error = ConfigKeyRegistry.Validate("kapelle.ai.enabled", Json("true"));
        Assert.Null(error);
    }

    [Fact]
    public void ConfigKeyRegistry_IntOutOfRange_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("kapelle.kammerton", Json("414"));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_ValidInt_ReturnsNull()
    {
        var error = ConfigKeyRegistry.Validate("kapelle.kammerton", Json("440"));
        Assert.Null(error);
    }

    [Fact]
    public void ConfigKeyRegistry_InvalidEnumValue_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("nutzer.theme", Json("\"blau\""));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_ValidEnumValue_ReturnsNull()
    {
        var error = ConfigKeyRegistry.Validate("nutzer.theme", Json("\"dark\""));
        Assert.Null(error);
    }

    [Fact]
    public void ConfigKeyRegistry_FloatBelowMin_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("nutzer.spielmodus.half_page_ratio", Json("0.1"));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_FloatAboveMax_ReturnsError()
    {
        var error = ConfigKeyRegistry.Validate("nutzer.spielmodus.half_page_ratio", Json("0.9"));
        Assert.NotNull(error);
    }

    [Fact]
    public void ConfigKeyRegistry_ValidFloat_ReturnsNull()
    {
        var error = ConfigKeyRegistry.Validate("nutzer.spielmodus.half_page_ratio", Json("0.5"));
        Assert.Null(error);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // EDGE CASES
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task GetKapelleConfigAsync_NonMember_ThrowsNotFound()
    {
        var (_, kapelleId) = await CreateAdminAsync();
        var stranger = new Musiker { Name = "X", Email = "stranger@test.de", PasswordHash = "x" };
        _db.Musiker.Add(stranger);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetKapelleConfigAsync(kapelleId, stranger.Id));

        Assert.Equal("KAPELLE_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task MultiKapelleUser_SeparateConfigsPerKapelle()
    {
        var musiker = new Musiker { Name = "MultiUser", Email = "multi@test.de", PasswordHash = "x" };
        var kapelle1 = new Kapelle { Name = "Alpha" };
        var kapelle2 = new Kapelle { Name = "Beta" };
        _db.Musiker.Add(musiker);
        _db.Kapellen.AddRange(kapelle1, kapelle2);
        await _db.SaveChangesAsync();

        var admin1 = new Musiker { Name = "A1", Email = "a1@test.de", PasswordHash = "x" };
        var admin2 = new Musiker { Name = "A2", Email = "a2@test.de", PasswordHash = "x" };
        _db.Musiker.AddRange(admin1, admin2);
        await _db.SaveChangesAsync();

        _db.Mitgliedschaften.AddRange(
            new Mitgliedschaft { MusikerID = admin1.Id, KapelleID = kapelle1.Id, Rolle = MitgliedRolle.Administrator, IstAktiv = true },
            new Mitgliedschaft { MusikerID = admin2.Id, KapelleID = kapelle2.Id, Rolle = MitgliedRolle.Administrator, IstAktiv = true },
            new Mitgliedschaft { MusikerID = musiker.Id, KapelleID = kapelle1.Id, Rolle = MitgliedRolle.Musiker, IstAktiv = true },
            new Mitgliedschaft { MusikerID = musiker.Id, KapelleID = kapelle2.Id, Rolle = MitgliedRolle.Musiker, IstAktiv = true }
        );
        await _db.SaveChangesAsync();

        await _sut.SetKapelleConfigAsync(kapelle1.Id, "kapelle.name",
            new ConfigWertSetzenRequest(Json("\"Band Alpha\"")), admin1.Id);
        await _sut.SetKapelleConfigAsync(kapelle2.Id, "kapelle.name",
            new ConfigWertSetzenRequest(Json("\"Band Beta\"")), admin2.Id);

        var resolved1 = await _sut.GetResolvedConfigAsync(kapelle1.Id, musiker.Id);
        var resolved2 = await _sut.GetResolvedConfigAsync(kapelle2.Id, musiker.Id);

        var name1 = resolved1.Single(r => r.Schluessel == "kapelle.name");
        var name2 = resolved2.Single(r => r.Schluessel == "kapelle.name");

        Assert.Equal("Band Alpha", name1.Wert.GetString());
        Assert.Equal("Band Beta", name2.Wert.GetString());
    }

    [Fact]
    public async Task MultiKapelleUser_PolicyOnlyAffectsItsKapelle()
    {
        var musiker = new Musiker { Name = "PolicyUser", Email = "policy-multi@test.de", PasswordHash = "x" };
        var kapelle1 = new Kapelle { Name = "Locked" };
        var kapelle2 = new Kapelle { Name = "Free" };
        _db.Musiker.Add(musiker);
        _db.Kapellen.AddRange(kapelle1, kapelle2);
        await _db.SaveChangesAsync();

        var admin1 = new Musiker { Name = "A1", Email = "pm-a1@test.de", PasswordHash = "x" };
        var admin2 = new Musiker { Name = "A2", Email = "pm-a2@test.de", PasswordHash = "x" };
        _db.Musiker.AddRange(admin1, admin2);
        await _db.SaveChangesAsync();

        _db.Mitgliedschaften.AddRange(
            new Mitgliedschaft { MusikerID = admin1.Id, KapelleID = kapelle1.Id, Rolle = MitgliedRolle.Administrator, IstAktiv = true },
            new Mitgliedschaft { MusikerID = admin2.Id, KapelleID = kapelle2.Id, Rolle = MitgliedRolle.Administrator, IstAktiv = true },
            new Mitgliedschaft { MusikerID = musiker.Id, KapelleID = kapelle1.Id, Rolle = MitgliedRolle.Musiker, IstAktiv = true },
            new Mitgliedschaft { MusikerID = musiker.Id, KapelleID = kapelle2.Id, Rolle = MitgliedRolle.Musiker, IstAktiv = true }
        );
        await _db.SaveChangesAsync();

        await _sut.SetNutzerConfigAsync(musiker.Id, "nutzer.sprache", new ConfigWertSetzenRequest(Json("\"it\"")));
        // Lock locale in kapelle1 only
        await _sut.SetPolicyAsync(kapelle1.Id, "policy.force_locale",
            new ConfigWertSetzenRequest(Json("true")), admin1.Id);

        var resolved1 = await _sut.GetResolvedConfigAsync(kapelle1.Id, musiker.Id);
        var resolved2 = await _sut.GetResolvedConfigAsync(kapelle2.Id, musiker.Id);

        var sprache1 = resolved1.Single(r => r.Schluessel == "nutzer.sprache");
        var sprache2 = resolved2.Single(r => r.Schluessel == "nutzer.sprache");

        Assert.True(sprache1.PolicyEnforced);    // Locked in kapelle1
        Assert.False(sprache2.PolicyEnforced);   // Free in kapelle2
        Assert.Equal("nutzer", sprache2.Ebene);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // SYNC — CONCURRENT UPDATE / VERSION CONFLICT
    // ══════════════════════════════════════════════════════════════════════════

    [Fact]
    public async Task SyncNutzerConfigAsync_NewEntry_Applied()
    {
        var musiker = new Musiker { Name = "Sync", Email = "sync@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEintrag("nutzer.theme", Json("\"dark\""), 1, DateTime.UtcNow)
        });

        var resp = await _sut.SyncNutzerConfigAsync(musiker.Id, req);

        Assert.Single(resp.Applied);
        Assert.Equal("nutzer.theme", resp.Applied[0].Schluessel);
        Assert.Empty(resp.Conflicts);
    }

    [Fact]
    public async Task SyncNutzerConfigAsync_ClientVersionNewer_ClientWins()
    {
        var musiker = new Musiker { Name = "Sync2", Email = "sync2@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        _db.ConfigNutzer.Add(new ConfigNutzer
        {
            MusikerId = musiker.Id, Schluessel = "nutzer.theme", Wert = "\"light\"", Version = 1
        });
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEintrag("nutzer.theme", Json("\"dark\""), 5, DateTime.UtcNow)
        });

        var resp = await _sut.SyncNutzerConfigAsync(musiker.Id, req);

        Assert.Single(resp.Applied);
        Assert.Empty(resp.Conflicts);
        var stored = await _db.ConfigNutzer.SingleAsync(
            c => c.MusikerId == musiker.Id && c.Schluessel == "nutzer.theme");
        Assert.Equal(5, stored.Version);
        Assert.Equal("\"dark\"", stored.Wert);
    }

    [Fact]
    public async Task SyncNutzerConfigAsync_ServerVersionNewer_Conflict()
    {
        var musiker = new Musiker { Name = "Sync3", Email = "sync3@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        _db.ConfigNutzer.Add(new ConfigNutzer
        {
            MusikerId = musiker.Id, Schluessel = "nutzer.theme", Wert = "\"dark\"", Version = 10
        });
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEintrag("nutzer.theme", Json("\"light\""), 3, DateTime.UtcNow)
        });

        var resp = await _sut.SyncNutzerConfigAsync(musiker.Id, req);

        Assert.Empty(resp.Applied);
        Assert.Single(resp.Conflicts);
        Assert.Equal("nutzer.theme", resp.Conflicts[0].Schluessel);
        Assert.Equal(10, resp.Conflicts[0].ServerVersion);
    }

    [Fact]
    public async Task SyncNutzerConfigAsync_SameVersionNewerClientTimestamp_ClientWins()
    {
        var musiker = new Musiker { Name = "Sync4", Email = "sync4@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        _db.ConfigNutzer.Add(new ConfigNutzer
        {
            MusikerId = musiker.Id, Schluessel = "nutzer.theme", Wert = "\"light\"", Version = 2
        });
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEintrag("nutzer.theme", Json("\"dark\""), 2, DateTime.UtcNow.AddMinutes(5))
        });

        var resp = await _sut.SyncNutzerConfigAsync(musiker.Id, req);

        Assert.Single(resp.Applied);
        Assert.Empty(resp.Conflicts);
    }

    [Fact]
    public async Task SyncNutzerConfigAsync_UnknownKey_SkippedSilently()
    {
        var musiker = new Musiker { Name = "Sync5", Email = "sync5@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEintrag("kein.schluessel", Json("\"x\""), 1, DateTime.UtcNow)
        });

        var resp = await _sut.SyncNutzerConfigAsync(musiker.Id, req);

        Assert.Empty(resp.Applied);
        Assert.Empty(resp.Conflicts);
    }

    [Fact]
    public async Task SyncNutzerConfigAsync_KapelleLevelKey_SkippedSilently()
    {
        var musiker = new Musiker { Name = "Sync6", Email = "sync6@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEintrag("kapelle.name", Json("\"x\""), 1, DateTime.UtcNow)
        });

        var resp = await _sut.SyncNutzerConfigAsync(musiker.Id, req);

        Assert.Empty(resp.Applied);
        Assert.Empty(resp.Conflicts);
    }

    [Fact]
    public async Task SyncNutzerConfigAsync_ServerChangesReturnedForFullSync()
    {
        var musiker = new Musiker { Name = "Sync7", Email = "sync7@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        // Pre-seed server entry
        _db.ConfigNutzer.Add(new ConfigNutzer
        {
            MusikerId = musiker.Id, Schluessel = "nutzer.sprache", Wert = "\"fr\"", Version = 3
        });
        await _db.SaveChangesAsync();

        var req = new ConfigSyncRequest(new[]
        {
            new ConfigSyncEintrag("nutzer.theme", Json("\"dark\""), 1, DateTime.UtcNow)
        });

        var resp = await _sut.SyncNutzerConfigAsync(musiker.Id, req);

        // ServerChanges must include all entries (both the new and the pre-seeded)
        Assert.Equal(2, resp.ServerChanges.Count);
        Assert.Contains(resp.ServerChanges, e => e.Schluessel == "nutzer.sprache");
        Assert.Contains(resp.ServerChanges, e => e.Schluessel == "nutzer.theme");
    }
}
