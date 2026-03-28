using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Infrastructure.Email;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Auth;

public class AuthService(AppDbContext db, IConfiguration configuration, IEmailService emailService) : IAuthService
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

        if (await db.Musiker.AnyAsync(m => m.Email == emailLower))
            throw new AuthException("EMAIL_ALREADY_EXISTS", "Diese E-Mail-Adresse ist bereits registriert.", 409);

        var verificationToken = GenerateSecureToken("ev_");

        var musiker = new Musiker
        {
            Name = request.DisplayName.Trim(),
            Email = emailLower,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Instrument = request.Instrument?.Trim(),
            OnboardingCompleted = false,
            EmailVerified = false,
            EmailVerificationToken = verificationToken,
            EmailVerificationTokenExpiresAt = DateTime.UtcNow.AddHours(24)
        };

        db.Musiker.Add(musiker);
        await db.SaveChangesAsync();

        await emailService.SendEmailVerificationAsync(musiker.Email, musiker.Name, verificationToken);

        var (accessToken, refreshToken) = await CreateTokenPairAsync(musiker);
        return BuildAuthResponse(musiker, accessToken, refreshToken);
    }

    // ─── Login ────────────────────────────────────────────────────────────────

    public async Task<AuthResponse> LoginAsync(LoginRequest request)
    {
        var emailLower = request.Email.Trim().ToLowerInvariant();
        var musiker = await db.Musiker.FirstOrDefaultAsync(m => m.Email == emailLower);

        if (musiker is null || !BCrypt.Net.BCrypt.Verify(request.Password, musiker.PasswordHash))
            throw new AuthException("INVALID_CREDENTIALS", "E-Mail oder Passwort ist falsch.", 401);

        var (accessToken, refreshToken) = await CreateTokenPairAsync(musiker);
        return BuildAuthResponse(musiker, accessToken, refreshToken);
    }

    // ─── Refresh ──────────────────────────────────────────────────────────────

    public async Task<TokenResponse> RefreshAsync(RefreshTokenRequest request)
    {
        var tokenHash = HashToken(request.RefreshToken);

        var existing = await db.RefreshTokens
            .Include(rt => rt.Musiker)
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
        var newAccessToken = GenerateJwt(existing.Musiker);
        var newRefreshToken = await CreateRefreshTokenAsync(existing.Musiker, existing.FamilyId);

        return new TokenResponse(newAccessToken, newRefreshToken, "Bearer", AccessTokenExpirySeconds);
    }

    // ─── Verify Email ─────────────────────────────────────────────────────────

    public async Task<MessageResponse> VerifyEmailAsync(VerifyEmailRequest request)
    {
        var musiker = await db.Musiker
            .FirstOrDefaultAsync(m => m.EmailVerificationToken == request.Token);

        if (musiker is null ||
            musiker.EmailVerificationTokenExpiresAt is null ||
            musiker.EmailVerificationTokenExpiresAt <= DateTime.UtcNow)
            throw new AuthException("INVALID_VERIFICATION_TOKEN", "Der Bestätigungslink ist ungültig oder abgelaufen.", 400);

        if (musiker.EmailVerified)
            return new MessageResponse("E-Mail-Adresse wurde bereits bestätigt.");

        musiker.EmailVerified = true;
        musiker.EmailVerificationToken = null;
        musiker.EmailVerificationTokenExpiresAt = null;

        await db.SaveChangesAsync();

        return new MessageResponse("E-Mail-Adresse erfolgreich bestätigt.");
    }

    // ─── Forgot Password ──────────────────────────────────────────────────────

    public async Task<MessageResponse> ForgotPasswordAsync(ForgotPasswordRequest request)
    {
        var emailLower = request.Email.Trim().ToLowerInvariant();
        var musiker = await db.Musiker.FirstOrDefaultAsync(m => m.Email == emailLower);

        // Always return success to prevent user enumeration
        if (musiker is null)
            return new MessageResponse("Wenn diese E-Mail registriert ist, wurde ein Reset-Link gesendet.");

        // 60-second cooldown
        if (musiker.PasswordResetRequestedAt.HasValue &&
            (DateTime.UtcNow - musiker.PasswordResetRequestedAt.Value).TotalSeconds < ResetCooldownSeconds)
            return new MessageResponse("Wenn diese E-Mail registriert ist, wurde ein Reset-Link gesendet.");

        musiker.PasswordResetToken = GenerateSecureToken("reset_");
        musiker.PasswordResetTokenExpiresAt = DateTime.UtcNow.AddMinutes(ResetTokenExpiryMinutes);
        musiker.PasswordResetRequestedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        // TODO: Send email via email service (not in scope for this issue)
        // Email would contain: /api/auth/reset-password?token={musiker.PasswordResetToken}

        return new MessageResponse("Wenn diese E-Mail registriert ist, wurde ein Reset-Link gesendet.");
    }

    // ─── Reset Password ───────────────────────────────────────────────────────

    public async Task<ResetPasswordResponse> ResetPasswordAsync(ResetPasswordRequest request)
    {
        ValidatePasswordStrength(request.NewPassword);

        var musiker = await db.Musiker.FirstOrDefaultAsync(m => m.PasswordResetToken == request.Token);

        if (musiker is null ||
            musiker.PasswordResetTokenExpiresAt is null ||
            musiker.PasswordResetTokenExpiresAt <= DateTime.UtcNow)
            throw new AuthException("INVALID_RESET_TOKEN", "Der Reset-Link ist ungültig oder abgelaufen.", 400);

        musiker.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        musiker.PasswordResetToken = null;
        musiker.PasswordResetTokenExpiresAt = null;
        musiker.PasswordResetRequestedAt = null;

        // Revoke all existing refresh tokens
        var allTokens = await db.RefreshTokens
            .Where(rt => rt.MusikerId == musiker.Id && !rt.IsRevoked)
            .ToListAsync();
        foreach (var t in allTokens)
            t.IsRevoked = true;

        await db.SaveChangesAsync();

        var (accessToken, refreshToken) = await CreateTokenPairAsync(musiker);

        return new ResetPasswordResponse(
            "Passwort erfolgreich geändert.",
            accessToken,
            refreshToken,
            "Bearer",
            AccessTokenExpirySeconds);
    }

    // ─── Private Helpers ──────────────────────────────────────────────────────

    private async Task<(string AccessToken, string RefreshToken)> CreateTokenPairAsync(Musiker musiker)
    {
        var accessToken = GenerateJwt(musiker);
        var refreshToken = await CreateRefreshTokenAsync(musiker, Guid.NewGuid());
        return (accessToken, refreshToken);
    }

    private string GenerateJwt(Musiker musiker)
    {
        var jwtSection = configuration.GetSection("Jwt");
        var key = jwtSection["Key"] ?? throw new InvalidOperationException("JWT Key not configured.");
        var issuer = jwtSection["Issuer"];
        var audience = jwtSection["Audience"];

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, musiker.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, musiker.Email),
            new Claim(JwtRegisteredClaimNames.Name, musiker.Name),
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

    private async Task<string> CreateRefreshTokenAsync(Musiker musiker, Guid familyId)
    {
        var tokenValue = GenerateSecureToken("rt_");

        var refreshToken = new RefreshToken
        {
            Token = HashToken(tokenValue),   // store SHA-256 hash, return raw value to client
            FamilyId = familyId,
            MusikerId = musiker.Id,
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

    private static void ValidatePasswordStrength(string password)
    {
        if (password.Length < 8)
            throw new AuthException("PASSWORD_TOO_WEAK", "Das Passwort muss mindestens 8 Zeichen lang sein.", 422);

        if (!password.Any(char.IsUpper))
            throw new AuthException("PASSWORD_TOO_WEAK", "Das Passwort muss mindestens einen Großbuchstaben enthalten.", 422);

        if (!password.Any(c => char.IsDigit(c) || !char.IsLetterOrDigit(c)))
            throw new AuthException("PASSWORD_TOO_WEAK", "Das Passwort muss mindestens eine Zahl oder ein Sonderzeichen enthalten.", 422);
    }

    private static AuthResponse BuildAuthResponse(Musiker musiker, string accessToken, string refreshToken)
    {
        var userDto = new UserDto(
            musiker.Id,
            musiker.Email,
            musiker.Name,
            musiker.Instrument,
            musiker.OnboardingCompleted,
            musiker.EmailVerified,
            musiker.CreatedAt);

        return new AuthResponse(userDto, accessToken, refreshToken, "Bearer", AccessTokenExpirySeconds);
    }
}
