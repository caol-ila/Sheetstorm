using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Moq;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Email;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Tests.Helpers;
using Xunit;

namespace Sheetstorm.Tests.Auth;

public class AuthServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly AuthService _sut;

    private const string ValidPassword = "Password1!";
    private const string ValidEmail = "test@example.com";
    private const string ValidDisplayName = "Test User";

    public AuthServiceTests()
    {
        _db = TestDbContextFactory.Create();
        var emailService = new Mock<IEmailService>().Object;
        var environment = new Mock<IHostEnvironment>();
        _sut = new AuthService(_db, TestJwtConfig.Create(), emailService, environment.Object);
    }

    // ─── Register ────────────────────────────────────────────────────────────

    [Fact]
    public async Task Register_ValidInput_CreatesUserWithHashedPassword()
    {
        var request = new RegisterRequest(ValidEmail, ValidPassword, ValidDisplayName, null);

        await _sut.RegisterAsync(request);

        var Musician = await _db.Musicians.SingleAsync();
        Assert.Equal(ValidEmail, Musician.Email);
        Assert.Equal(ValidDisplayName, Musician.Name);
        Assert.False(Musician.OnboardingCompleted);
        Assert.NotEqual(ValidPassword, Musician.PasswordHash);
        Assert.True(BCrypt.Net.BCrypt.Verify(ValidPassword, Musician.PasswordHash));
    }

    [Fact]
    public async Task Register_ValidInput_ReturnsAccessTokenAndRefreshToken()
    {
        var request = new RegisterRequest(ValidEmail, ValidPassword, ValidDisplayName, null);

        var response = await _sut.RegisterAsync(request);

        Assert.NotEmpty(response.AccessToken);
        Assert.NotEmpty(response.RefreshToken);
        Assert.Equal("Bearer", response.TokenType);
        Assert.Equal(900, response.ExpiresIn);
    }

    [Fact]
    public async Task Register_DuplicateEmail_ThrowsAuthExceptionEmailAlreadyExists()
    {
        var request = new RegisterRequest(ValidEmail, ValidPassword, ValidDisplayName, null);
        await _sut.RegisterAsync(request);

        var ex = await Assert.ThrowsAsync<AuthException>(() => _sut.RegisterAsync(request));

        Assert.Equal("EMAIL_ALREADY_EXISTS", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task Register_MixedCaseEmail_StoresNormalizedLowercase()
    {
        var request = new RegisterRequest("Test@EXAMPLE.COM", ValidPassword, ValidDisplayName, null);

        await _sut.RegisterAsync(request);

        var Musician = await _db.Musicians.SingleAsync();
        Assert.Equal("test@example.com", Musician.Email);
    }

    [Fact]
    public async Task Register_WeakPasswordTooShort_ThrowsPasswordTooWeak()
    {
        var request = new RegisterRequest(ValidEmail, "short", ValidDisplayName, null);

        var ex = await Assert.ThrowsAsync<AuthException>(() => _sut.RegisterAsync(request));

        Assert.Equal("PASSWORD_TOO_WEAK", ex.ErrorCode);
        Assert.Equal(422, ex.StatusCode);
    }

    [Fact]
    public async Task Register_WeakPasswordNoUppercase_ThrowsPasswordTooWeak()
    {
        var request = new RegisterRequest(ValidEmail, "alllower1!", ValidDisplayName, null);

        var ex = await Assert.ThrowsAsync<AuthException>(() => _sut.RegisterAsync(request));

        Assert.Equal("PASSWORD_TOO_WEAK", ex.ErrorCode);
    }

    [Fact]
    public async Task Register_WeakPasswordNoDigitOrSpecial_ThrowsPasswordTooWeak()
    {
        var request = new RegisterRequest(ValidEmail, "OnlyLetters", ValidDisplayName, null);

        var ex = await Assert.ThrowsAsync<AuthException>(() => _sut.RegisterAsync(request));

        Assert.Equal("PASSWORD_TOO_WEAK", ex.ErrorCode);
    }

    // ─── Login ────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Login_ValidCredentials_ReturnsJwtAndRefreshToken()
    {
        await RegisterDefaultUser();
        var loginRequest = new LoginRequest(ValidEmail, ValidPassword);

        var response = await _sut.LoginAsync(loginRequest);

        Assert.NotNull(response);
        Assert.NotEmpty(response.AccessToken);
        Assert.NotEmpty(response.RefreshToken);
        Assert.Equal("Bearer", response.TokenType);
        Assert.Equal(ValidEmail, response.User.Email);
    }

    [Fact]
    public async Task Login_WrongPassword_ThrowsInvalidCredentials()
    {
        await RegisterDefaultUser();
        var loginRequest = new LoginRequest(ValidEmail, "WrongPassword1!");

        var ex = await Assert.ThrowsAsync<AuthException>(() => _sut.LoginAsync(loginRequest));

        Assert.Equal("INVALID_CREDENTIALS", ex.ErrorCode);
        Assert.Equal(401, ex.StatusCode);
    }

    [Fact]
    public async Task Login_NonExistentUser_ThrowsSameInvalidCredentials()
    {
        // Must not distinguish "user not found" from "wrong password" (no enumeration)
        var loginRequest = new LoginRequest("nobody@example.com", ValidPassword);

        var ex = await Assert.ThrowsAsync<AuthException>(() => _sut.LoginAsync(loginRequest));

        Assert.Equal("INVALID_CREDENTIALS", ex.ErrorCode);
        Assert.Equal(401, ex.StatusCode);
    }

    // ─── Refresh ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task Refresh_ValidToken_ReturnsNewJwtAndNewRefreshToken()
    {
        var authResponse = await RegisterDefaultUser();
        var refreshRequest = new RefreshTokenRequest(authResponse.RefreshToken);

        var tokenResponse = await _sut.RefreshAsync(refreshRequest);

        Assert.NotNull(tokenResponse);
        Assert.NotEmpty(tokenResponse.AccessToken);
        Assert.NotEmpty(tokenResponse.RefreshToken);
        Assert.NotEqual(authResponse.AccessToken, tokenResponse.AccessToken);
        Assert.NotEqual(authResponse.RefreshToken, tokenResponse.RefreshToken);
    }

    [Fact]
    public async Task Refresh_ExpiredToken_ThrowsInvalidRefreshToken()
    {
        var authResponse = await RegisterDefaultUser();

        var dbToken = await _db.RefreshTokens.SingleAsync();
        dbToken.ExpiresAt = DateTime.UtcNow.AddDays(-1);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.RefreshAsync(new RefreshTokenRequest(authResponse.RefreshToken)));

        Assert.Equal("INVALID_REFRESH_TOKEN", ex.ErrorCode);
        Assert.Equal(401, ex.StatusCode);
    }

    [Fact]
    public async Task Refresh_RevokedToken_ThrowsInvalidRefreshToken()
    {
        var authResponse = await RegisterDefaultUser();

        var dbToken = await _db.RefreshTokens.SingleAsync();
        dbToken.IsRevoked = true;
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.RefreshAsync(new RefreshTokenRequest(authResponse.RefreshToken)));

        Assert.Equal("INVALID_REFRESH_TOKEN", ex.ErrorCode);
        Assert.Equal(401, ex.StatusCode);
    }

    [Fact]
    public async Task Refresh_TokenReuse_RevokesEntireFamilyAndThrows()
    {
        var authResponse = await RegisterDefaultUser();

        // Normal first refresh — consumes the original token
        await _sut.RefreshAsync(new RefreshTokenRequest(authResponse.RefreshToken));

        // Reuse of already-used token triggers reuse detection
        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.RefreshAsync(new RefreshTokenRequest(authResponse.RefreshToken)));

        Assert.Equal("REFRESH_TOKEN_REUSED", ex.ErrorCode);
        Assert.Equal(401, ex.StatusCode);

        // All tokens in the family must be revoked
        var anyNotRevoked = await _db.RefreshTokens.AnyAsync(t => !t.IsRevoked);
        Assert.False(anyNotRevoked);
    }

    // ─── Password Reset ───────────────────────────────────────────────────────

    [Fact]
    public async Task ForgotPassword_ValidEmail_GeneratesTokenWithThirtyMinuteExpiry()
    {
        await RegisterDefaultUser();
        var before = DateTime.UtcNow;

        await _sut.ForgotPasswordAsync(new ForgotPasswordRequest(ValidEmail));

        var Musician = await _db.Musicians.SingleAsync();
        Assert.NotNull(Musician.PasswordResetToken);
        Assert.NotNull(Musician.PasswordResetTokenExpiresAt);
        Assert.True(Musician.PasswordResetTokenExpiresAt > before.AddMinutes(29));
        Assert.True(Musician.PasswordResetTokenExpiresAt <= before.AddMinutes(31));
    }

    [Fact]
    public async Task ForgotPassword_UnknownEmail_ReturnsSameMessageToPreventEnumeration()
    {
        var response = await _sut.ForgotPasswordAsync(
            new ForgotPasswordRequest("unknown@example.com"));

        Assert.NotNull(response.Message);
        Assert.NotEmpty(response.Message);
    }

    [Fact]
    public async Task ResetPassword_ValidToken_ChangesPasswordAndRevokesAllRefreshTokens()
    {
        await RegisterDefaultUser();
        await _sut.ForgotPasswordAsync(new ForgotPasswordRequest(ValidEmail));

        var Musician = await _db.Musicians.SingleAsync();
        var resetToken = Musician.PasswordResetToken!;
        const string newPassword = "NewPassword1!";

        // Capture the token IDs created before reset
        var tokenIdsBefore = await _db.RefreshTokens
            .Where(t => t.MusicianId == Musician.Id)
            .Select(t => t.Id)
            .ToListAsync();

        var response = await _sut.ResetPasswordAsync(new ResetPasswordRequest(resetToken, newPassword));

        Assert.NotNull(response);
        Assert.NotEmpty(response.AccessToken);
        Assert.NotEmpty(response.RefreshToken);

        var updatedMusiker = await _db.Musicians.SingleAsync();
        Assert.Null(updatedMusiker.PasswordResetToken);
        Assert.Null(updatedMusiker.PasswordResetTokenExpiresAt);
        Assert.True(BCrypt.Net.BCrypt.Verify(newPassword, updatedMusiker.PasswordHash));

        // All tokens that existed BEFORE the reset should now be revoked
        var revokedTokens = await _db.RefreshTokens
            .Where(t => tokenIdsBefore.Contains(t.Id))
            .ToListAsync();
        Assert.True(revokedTokens.All(t => t.IsRevoked));
    }

    [Fact]
    public async Task ResetPassword_ExpiredToken_ThrowsInvalidResetToken()
    {
        await RegisterDefaultUser();
        await _sut.ForgotPasswordAsync(new ForgotPasswordRequest(ValidEmail));

        var Musician = await _db.Musicians.SingleAsync();
        Musician.PasswordResetTokenExpiresAt = DateTime.UtcNow.AddMinutes(-1);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.ResetPasswordAsync(
                new ResetPasswordRequest(Musician.PasswordResetToken!, "NewPassword1!")));

        Assert.Equal("INVALID_RESET_TOKEN", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_InvalidToken_ThrowsInvalidResetToken()
    {
        var ex = await Assert.ThrowsAsync<AuthException>(
            () => _sut.ResetPasswordAsync(new ResetPasswordRequest("bogus_token", "NewPassword1!")));

        Assert.Equal("INVALID_RESET_TOKEN", ex.ErrorCode);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private async Task<AuthResponse> RegisterDefaultUser()
    {
        var request = new RegisterRequest(ValidEmail, ValidPassword, ValidDisplayName, null);
        var response = await _sut.RegisterAsync(request);
        // Mark email as verified so login tests don't hit the email-verification guard
        var Musician = await _db.Musicians.SingleAsync(m => m.Email == ValidEmail);
        Musician.EmailVerified = true;
        await _db.SaveChangesAsync();
        return response;
    }

    public void Dispose() => _db.Dispose();
}
