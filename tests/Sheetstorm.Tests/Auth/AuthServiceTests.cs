using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using NSubstitute;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Email;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Auth;

public class AuthServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly IConfiguration _configuration;
    private readonly IEmailService _emailService;
    private readonly AuthService _sut;

    private const string ValidPassword = "Test1234!";

    public AuthServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _emailService = Substitute.For<IEmailService>();

        var configData = new Dictionary<string, string?>
        {
            ["Jwt:Key"] = "ThisIsASuperSecretKeyForTestingPurposesOnly1234567890!",
            ["Jwt:Issuer"] = "sheetstorm-test",
            ["Jwt:Audience"] = "sheetstorm-test"
        };
        _configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(configData)
            .Build();

        _sut = new AuthService(_db, _configuration, _emailService, Substitute.For<IHostEnvironment>());
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    // ─── Register ────────────────────────────────────────────────────────────

    [Fact]
    public async Task RegisterAsync_ValidRequest_ReturnsAuthResponse()
    {
        var request = new RegisterRequest("test@example.com", ValidPassword, "Max Mustermann", "Trompete");

        var result = await _sut.RegisterAsync(request);

        Assert.NotNull(result);
        Assert.Equal("test@example.com", result.User.Email);
        Assert.Equal("Max Mustermann", result.User.DisplayName);
        Assert.False(result.User.EmailVerified);
        Assert.NotEmpty(result.AccessToken);
        Assert.NotEmpty(result.RefreshToken);
    }

    [Fact]
    public async Task RegisterAsync_StoresHashedEmailVerificationToken()
    {
        var request = new RegisterRequest("hash-test@example.com", ValidPassword, "Hash Test", null);

        // Capture the raw token sent to the email service
        string? capturedRawToken = null;
        await _emailService.SendEmailVerificationAsync(
            Arg.Any<string>(), Arg.Any<string>(), Arg.Do<string>(t => capturedRawToken = t));

        await _sut.RegisterAsync(request);

        Assert.NotNull(capturedRawToken);

        var Musician = await _db.Musicians.FirstAsync(m => m.Email == "hash-test@example.com");

        // DB must contain the SHA-256 hash, NOT the raw token
        Assert.NotEqual(capturedRawToken, Musician.EmailVerificationToken);
        Assert.Equal(HashToken(capturedRawToken), Musician.EmailVerificationToken);
    }

    [Fact]
    public async Task RegisterAsync_DuplicateEmail_ThrowsConflict()
    {
        var request = new RegisterRequest("dup@example.com", ValidPassword, "User 1", null);
        await _sut.RegisterAsync(request);

        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.RegisterAsync(new RegisterRequest("dup@example.com", ValidPassword, "User 2", null)));

        Assert.Equal("EMAIL_ALREADY_EXISTS", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task RegisterAsync_WeakPassword_ThrowsValidationError()
    {
        var request = new RegisterRequest("weak@example.com", "short", "Weak User", null);

        var ex = await Assert.ThrowsAsync<AuthException>(() => _sut.RegisterAsync(request));
        Assert.Equal("PASSWORD_TOO_WEAK", ex.ErrorCode);
    }

    // ─── Login ────────────────────────────────────────────────────────────────

    [Fact]
    public async Task LoginAsync_VerifiedUser_ReturnsTokens()
    {
        await RegisterAndVerifyUser("login@example.com", ValidPassword, "Login User");

        var result = await _sut.LoginAsync(new LoginRequest("login@example.com", ValidPassword));

        Assert.NotNull(result);
        Assert.NotEmpty(result.AccessToken);
        Assert.NotEmpty(result.RefreshToken);
        Assert.True(result.User.EmailVerified);
    }

    [Fact]
    public async Task LoginAsync_UnverifiedUser_ThrowsEmailNotVerified()
    {
        await _sut.RegisterAsync(new RegisterRequest("unverified@example.com", ValidPassword, "Unverified", null));

        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.LoginAsync(new LoginRequest("unverified@example.com", ValidPassword)));

        Assert.Equal("EMAIL_NOT_VERIFIED", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task LoginAsync_WrongPassword_ThrowsInvalidCredentials()
    {
        await _sut.RegisterAsync(new RegisterRequest("wrong@example.com", ValidPassword, "User", null));

        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.LoginAsync(new LoginRequest("wrong@example.com", "WrongPass1!")));

        Assert.Equal("INVALID_CREDENTIALS", ex.ErrorCode);
        Assert.Equal(401, ex.StatusCode);
    }

    [Fact]
    public async Task LoginAsync_NonExistentUser_ThrowsInvalidCredentials()
    {
        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.LoginAsync(new LoginRequest("ghost@example.com", ValidPassword)));

        Assert.Equal("INVALID_CREDENTIALS", ex.ErrorCode);
    }

    // ─── Verify Email ─────────────────────────────────────────────────────────

    [Fact]
    public async Task VerifyEmailAsync_ValidHashedToken_VerifiesUser()
    {
        string? capturedToken = null;
        await _emailService.SendEmailVerificationAsync(
            Arg.Any<string>(), Arg.Any<string>(), Arg.Do<string>(t => capturedToken = t));

        await _sut.RegisterAsync(new RegisterRequest("verify@example.com", ValidPassword, "Verify User", null));
        Assert.NotNull(capturedToken);

        var result = await _sut.VerifyEmailAsync(new VerifyEmailRequest(capturedToken));

        Assert.Contains("erfolgreich", result.Message);
        var Musician = await _db.Musicians.FirstAsync(m => m.Email == "verify@example.com");
        Assert.True(Musician.EmailVerified);
        Assert.Null(Musician.EmailVerificationToken);
    }

    [Fact]
    public async Task VerifyEmailAsync_InvalidToken_Throws()
    {
        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.VerifyEmailAsync(new VerifyEmailRequest("bogus_token")));

        Assert.Equal("INVALID_VERIFICATION_TOKEN", ex.ErrorCode);
    }

    [Fact]
    public async Task VerifyEmailAsync_AlreadyVerified_ReturnsAlreadyMessage()
    {
        string? capturedToken = null;
        await _emailService.SendEmailVerificationAsync(
            Arg.Any<string>(), Arg.Any<string>(), Arg.Do<string>(t => capturedToken = t));

        await _sut.RegisterAsync(new RegisterRequest("double@example.com", ValidPassword, "Double", null));
        Assert.NotNull(capturedToken);

        // Manually mark as verified but keep the token hash for the lookup
        var Musician = await _db.Musicians.FirstAsync(m => m.Email == "double@example.com");
        Musician.EmailVerified = true;
        await _db.SaveChangesAsync();

        var result = await _sut.VerifyEmailAsync(new VerifyEmailRequest(capturedToken));
        Assert.Contains("bereits", result.Message);
    }

    // ─── Refresh Token (hashed) ───────────────────────────────────────────────

    [Fact]
    public async Task RefreshAsync_ValidToken_ReturnsNewTokenPair()
    {
        await RegisterAndVerifyUser("refresh@example.com", ValidPassword, "Refresh User");
        var loginResult = await _sut.LoginAsync(new LoginRequest("refresh@example.com", ValidPassword));

        var result = await _sut.RefreshAsync(new RefreshTokenRequest(loginResult.RefreshToken));

        Assert.NotNull(result);
        Assert.NotEmpty(result.AccessToken);
        Assert.NotEmpty(result.RefreshToken);
        Assert.NotEqual(loginResult.RefreshToken, result.RefreshToken);
    }

    [Fact]
    public async Task RefreshAsync_StoresHashedTokenInDb()
    {
        await RegisterAndVerifyUser("rt-hash@example.com", ValidPassword, "RT Hash");
        var loginResult = await _sut.LoginAsync(new LoginRequest("rt-hash@example.com", ValidPassword));

        // The raw refresh token should NOT exist in the DB
        var rawExists = await _db.RefreshTokens.AnyAsync(rt => rt.Token == loginResult.RefreshToken);
        Assert.False(rawExists, "Raw refresh token must not be stored in DB");

        // The SHA-256 hash should exist
        var hashExists = await _db.RefreshTokens.AnyAsync(rt => rt.Token == HashToken(loginResult.RefreshToken));
        Assert.True(hashExists, "Hashed refresh token must be in DB");
    }

    [Fact]
    public async Task RefreshAsync_ReuseDetected_RevokesFamily()
    {
        await RegisterAndVerifyUser("reuse@example.com", ValidPassword, "Reuse User");
        var loginResult = await _sut.LoginAsync(new LoginRequest("reuse@example.com", ValidPassword));

        // First refresh succeeds
        await _sut.RefreshAsync(new RefreshTokenRequest(loginResult.RefreshToken));

        // Reusing the same token triggers family revocation
        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.RefreshAsync(new RefreshTokenRequest(loginResult.RefreshToken)));

        Assert.Equal("REFRESH_TOKEN_REUSED", ex.ErrorCode);
    }

    [Fact]
    public async Task RefreshAsync_InvalidToken_Throws()
    {
        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.RefreshAsync(new RefreshTokenRequest("rt_invalid_token")));

        Assert.Equal("INVALID_REFRESH_TOKEN", ex.ErrorCode);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private async Task RegisterAndVerifyUser(string email, string password, string name)
    {
        string? capturedToken = null;
        await _emailService.SendEmailVerificationAsync(
            Arg.Any<string>(), Arg.Any<string>(), Arg.Do<string>(t => capturedToken = t));

        await _sut.RegisterAsync(new RegisterRequest(email, password, name, null));

        // Directly verify in DB (simulates email click)
        var Musician = await _db.Musicians.FirstAsync(m => m.Email == email.ToLowerInvariant());
        Musician.EmailVerified = true;
        await _db.SaveChangesAsync();
    }
}
