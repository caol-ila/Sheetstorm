using Microsoft.Extensions.Logging;

namespace Sheetstorm.Infrastructure.Email;

/// <summary>
/// Development stub — logs emails to console instead of sending them.
/// Replace with a real SMTP / transactional email implementation in production.
/// </summary>
public class DevEmailService(ILogger<DevEmailService> logger) : IEmailService
{
    public Task SendEmailVerificationAsync(string toEmail, string displayName, string verificationToken)
    {
        logger.LogInformation(
            "[DEV EMAIL] Verify email for {Name} <{Email}>: POST /api/auth/verify-email  token={Token}",
            displayName, toEmail, verificationToken);
        return Task.CompletedTask;
    }

    public Task SendPasswordResetAsync(string toEmail, string displayName, string resetToken)
    {
        logger.LogInformation(
            "[DEV EMAIL] Password reset for {Name} <{Email}>: POST /api/auth/reset-password  token={Token}",
            displayName, toEmail, resetToken);
        return Task.CompletedTask;
    }
}
