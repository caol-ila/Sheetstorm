using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Hosting;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Infrastructure.Email;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Auth;

public class AuthService(AppDbContext db, IConfiguration configuration, IEmailService emailService, IHostEnvironment environment) : IAuthService
{
    private const int AccessTokenExpirySeconds = 900; // 15 minutes
    private const int RefreshTokenExpiryDays = 30;
    private const int ResetTokenExpiryMinutes = 30;
    private const int ResetCooldownSeconds = 60;

    // ─── Register ────────────────────────────────────────────────────────────

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
    {
        ValidatePasswordStrength(request.Password);

        var emailLower = request.Email.Trim().ToLowerInvariant();

        if (await db.Musicians.AnyAsync(m => m.Email == emailLower))
            throw new AuthException("EMAIL_ALREADY_EXISTS", "Diese E-Mail-Adresse ist bereits registriert.", 409);

        var verificationToken = GenerateSecureToken("ev_");

        var Musician = new Musician
        {
            Name = request.DisplayName.Trim(),
            Email = emailLower,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Instrument = request.Instrument?.Trim(),
            OnboardingCompleted = false,
            EmailVerified = false,
            EmailVerificationToken = HashToken(verificationToken),
            EmailVerificationTokenExpiresAt = DateTime.UtcNow.AddHours(24)
        };

        db.Musicians.Add(Musician);
        await db.SaveChangesAsync();

        await emailService.SendEmailVerificationAsync(Musician.Email, Musician.Name, verificationToken);

        var (accessToken, refreshToken) = await CreateTokenPairAsync(Musician);
        return BuildAuthResponse(Musician, accessToken, refreshToken);
    }

    // ─── Login ────────────────────────────────────────────────────────────────

    public async Task<AuthResponse> LoginAsync(LoginRequest request)
    {
        var emailLower = request.Email.Trim().ToLowerInvariant();
        var Musician = await db.Musicians.FirstOrDefaultAsync(m => m.Email == emailLower);

        if (Musician is null || !BCrypt.Net.BCrypt.Verify(request.Password, Musician.PasswordHash))
            throw new AuthException("INVALID_CREDENTIALS", "E-Mail oder Passwort ist falsch.", 401);

        if (!Musician.EmailVerified)
            throw new AuthException("EMAIL_NOT_VERIFIED", "Bitte bestätige zuerst deine E-Mail-Adresse.", 403);

        var (accessToken, refreshToken) = await CreateTokenPairAsync(Musician);
        return BuildAuthResponse(Musician, accessToken, refreshToken);
    }

    // ─── Refresh ──────────────────────────────────────────────────────────────

    public async Task<TokenResponse> RefreshAsync(RefreshTokenRequest request)
    {
        var tokenHash = HashToken(request.RefreshToken);

        var existing = await db.RefreshTokens
            .Include(rt => rt.Musician)
            .FirstOrDefaultAsync(rt => rt.Token == tokenHash);

        if (existing is null || existing.IsRevoked || existing.ExpiresAt <= DateTime.UtcNow)
            throw new AuthException("INVALID_REFRESH_TOKEN", "Das Refresh Token ist ungültig oder abgelaufen.", 401);

        if (existing.IsUsed)
        {
            // Reuse detected — revoke entire family
            var familyTokens = await db.RefreshTokens
                .Where(rt => rt.FamilyId == existing.FamilyId)
                .ToListAsync();
            foreach (var t in familyTokens)
                t.IsRevoked = true;
            await db.SaveChangesAsync();

            throw new AuthException("REFRESH_TOKEN_REUSED",
                "Das Refresh Token wurde bereits verwendet. Alle Sessions wurden aus Sicherheitsgründen beendet.", 401);
        }

        // Mark old token as used
        existing.IsUsed = true;
        await db.SaveChangesAsync();

        // Issue new token pair in same family
        var newAccessToken = GenerateJwt(existing.Musician);
        var newRefreshToken = await CreateRefreshTokenAsync(existing.Musician, existing.FamilyId);

        return new TokenResponse(newAccessToken, newRefreshToken, "Bearer", AccessTokenExpirySeconds);
    }

    // ─── Verify Email ─────────────────────────────────────────────────────────

    public async Task<MessageResponse> VerifyEmailAsync(VerifyEmailRequest request)
    {
        var tokenHash = HashToken(request.Token);

        var Musician = await db.Musicians
            .FirstOrDefaultAsync(m => m.EmailVerificationToken == tokenHash);

        if (Musician is null ||
            Musician.EmailVerificationTokenExpiresAt is null ||
            Musician.EmailVerificationTokenExpiresAt <= DateTime.UtcNow)
            throw new AuthException("INVALID_VERIFICATION_TOKEN", "Der Bestätigungslink ist ungültig oder abgelaufen.", 400);

        if (Musician.EmailVerified)
            return new MessageResponse("E-Mail-Adresse wurde bereits bestätigt.");

        Musician.EmailVerified = true;
        Musician.EmailVerificationToken = null;
        Musician.EmailVerificationTokenExpiresAt = null;

        await db.SaveChangesAsync();

        return new MessageResponse("E-Mail-Adresse erfolgreich bestätigt.");
    }

    // ─── Forgot Password ──────────────────────────────────────────────────────

    public async Task<MessageResponse> ForgotPasswordAsync(ForgotPasswordRequest request)
    {
        var emailLower = request.Email.Trim().ToLowerInvariant();
        var Musician = await db.Musicians.FirstOrDefaultAsync(m => m.Email == emailLower);

        // Always return success to prevent user enumeration
        if (Musician is null)
            return new MessageResponse("Wenn diese E-Mail registriert ist, wurde ein Reset-Link gesendet.");

        // 60-second cooldown
        if (Musician.PasswordResetRequestedAt.HasValue &&
            (DateTime.UtcNow - Musician.PasswordResetRequestedAt.Value).TotalSeconds < ResetCooldownSeconds)
            return new MessageResponse("Wenn diese E-Mail registriert ist, wurde ein Reset-Link gesendet.");

        Musician.PasswordResetToken = GenerateSecureToken("reset_");
        Musician.PasswordResetTokenExpiresAt = DateTime.UtcNow.AddMinutes(ResetTokenExpiryMinutes);
        Musician.PasswordResetRequestedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        // TODO: Send email via email service (not in scope for this issue)
        // Email would contain: /api/auth/reset-password?token={Musician.PasswordResetToken}

        return new MessageResponse("Wenn diese E-Mail registriert ist, wurde ein Reset-Link gesendet.");
    }

    // ─── Reset Password ───────────────────────────────────────────────────────

    public async Task<ResetPasswordResponse> ResetPasswordAsync(ResetPasswordRequest request)
    {
        ValidatePasswordStrength(request.NewPassword);

        var Musician = await db.Musicians.FirstOrDefaultAsync(m => m.PasswordResetToken == request.Token);

        if (Musician is null ||
            Musician.PasswordResetTokenExpiresAt is null ||
            Musician.PasswordResetTokenExpiresAt <= DateTime.UtcNow)
            throw new AuthException("INVALID_RESET_TOKEN", "Der Reset-Link ist ungültig oder abgelaufen.", 400);

        Musician.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        Musician.PasswordResetToken = null;
        Musician.PasswordResetTokenExpiresAt = null;
        Musician.PasswordResetRequestedAt = null;

        // Revoke all existing refresh tokens
        var allTokens = await db.RefreshTokens
            .Where(rt => rt.MusicianId == Musician.Id && !rt.IsRevoked)
            .ToListAsync();
        foreach (var t in allTokens)
            t.IsRevoked = true;

        await db.SaveChangesAsync();

        var (accessToken, refreshToken) = await CreateTokenPairAsync(Musician);

        return new ResetPasswordResponse(
            "Passwort erfolgreich geändert.",
            accessToken,
            refreshToken,
            "Bearer",
            AccessTokenExpirySeconds);
    }

    // ─── Private Helpers ──────────────────────────────────────────────────────

    private async Task<(string AccessToken, string RefreshToken)> CreateTokenPairAsync(Musician Musician)
    {
        var accessToken = GenerateJwt(Musician);
        var refreshToken = await CreateRefreshTokenAsync(Musician, Guid.NewGuid());
        return (accessToken, refreshToken);
    }

    private string GenerateJwt(Musician Musician)
    {
        var jwtSection = configuration.GetSection("Jwt");
        var key = jwtSection["Key"] ?? throw new InvalidOperationException("JWT Key not configured.");
        var issuer = jwtSection["Issuer"];
        var audience = jwtSection["Audience"];

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, Musician.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, Musician.Email),
            new Claim(JwtRegisteredClaimNames.Name, Musician.Name),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var creds = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddSeconds(AccessTokenExpirySeconds),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private async Task<string> CreateRefreshTokenAsync(Musician Musician, Guid familyId)
    {
        var tokenValue = GenerateSecureToken("rt_");

        var refreshToken = new RefreshToken
        {
            Token = HashToken(tokenValue),   // store SHA-256 hash, return raw value to client
            FamilyId = familyId,
            MusicianId = Musician.Id,
            ExpiresAt = DateTime.UtcNow.AddDays(RefreshTokenExpiryDays)
        };

        db.RefreshTokens.Add(refreshToken);
        await db.SaveChangesAsync();

        return tokenValue;
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    private static string GenerateSecureToken(string prefix = "")
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return prefix + Convert.ToBase64String(bytes)
            .Replace('+', '-').Replace('/', '_').TrimEnd('=');
    }

    private void ValidatePasswordStrength(string password)
    {
        // Im Development-Modus wird die Passwort-Policy gelockert,
        // damit einfache Test-Passwörter wie "demo" funktionieren.
        if (environment.IsDevelopment())
            return;

        if (password.Length < 8)
            throw new AuthException("PASSWORD_TOO_WEAK", "Das Passwort muss mindestens 8 Zeichen lang sein.", 422);

        if (!password.Any(char.IsUpper))
            throw new AuthException("PASSWORD_TOO_WEAK", "Das Passwort muss mindestens einen Großbuchstaben enthalten.", 422);

        if (!password.Any(c => char.IsDigit(c) || !char.IsLetterOrDigit(c)))
            throw new AuthException("PASSWORD_TOO_WEAK", "Das Passwort muss mindestens eine Zahl oder ein Sonderzeichen enthalten.", 422);
    }

    private static AuthResponse BuildAuthResponse(Musician Musician, string accessToken, string refreshToken)
    {
        var userDto = new UserDto(
            Musician.Id,
            Musician.Email,
            Musician.Name,
            Musician.Instrument,
            Musician.OnboardingCompleted,
            Musician.EmailVerified,
            Musician.CreatedAt);

        return new AuthResponse(userDto, accessToken, refreshToken, "Bearer", AccessTokenExpirySeconds);
    }
}
