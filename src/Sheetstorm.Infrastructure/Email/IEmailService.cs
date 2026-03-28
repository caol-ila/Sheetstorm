namespace Sheetstorm.Infrastructure.Email;

public interface IEmailService
{
    Task SendEmailVerificationAsync(string toEmail, string displayName, string verificationToken);
    Task SendPasswordResetAsync(string toEmail, string displayName, string resetToken);
}
