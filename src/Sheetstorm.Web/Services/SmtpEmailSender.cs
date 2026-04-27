using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.UI.Services;
using Microsoft.Extensions.Options;
using MimeKit;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Web.Services;

public sealed class SmtpOptions
{
    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 1025;
    public string FromAddress { get; set; } = "noreply@sheetstorm.local";
    public string FromName { get; set; } = "Sheetstorm";
    public bool UseSsl { get; set; } = false;
    public string? Username { get; set; }
    public string? Password { get; set; }
}

public sealed class SmtpEmailSender(IOptions<SmtpOptions> options, ILogger<SmtpEmailSender> log)
    : IEmailSender, IEmailSender<ApplicationUser>
{
    private readonly SmtpOptions _opt = options.Value;

    public async Task SendEmailAsync(string email, string subject, string htmlMessage)
    {
        var msg = new MimeMessage();
        msg.From.Add(new MailboxAddress(_opt.FromName, _opt.FromAddress));
        msg.To.Add(MailboxAddress.Parse(email));
        msg.Subject = subject;
        msg.Body = new BodyBuilder { HtmlBody = htmlMessage }.ToMessageBody();

        using var client = new SmtpClient();
        try
        {
            await client.ConnectAsync(_opt.Host, _opt.Port,
                _opt.UseSsl ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.None);
            if (!string.IsNullOrEmpty(_opt.Username))
            {
                await client.AuthenticateAsync(_opt.Username, _opt.Password);
            }
            await client.SendAsync(msg);
            await client.DisconnectAsync(true);
            log.LogInformation("E-Mail gesendet an {Email}: {Subject}", email, subject);
        }
        catch (Exception ex)
        {
            log.LogError(ex, "E-Mail-Versand fehlgeschlagen an {Email}", email);
            throw;
        }
    }

    public Task SendConfirmationLinkAsync(ApplicationUser user, string email, string confirmationLink)
        => SendEmailAsync(email, "Sheetstorm — E-Mail bestätigen",
            $"<p>Hallo {System.Net.WebUtility.HtmlEncode(user.DisplayName)},</p>" +
            $"<p>bitte bestätige deine E-Mail-Adresse mit einem Klick:</p>" +
            $"<p><a href=\"{confirmationLink}\">E-Mail bestätigen</a></p>");

    public Task SendPasswordResetLinkAsync(ApplicationUser user, string email, string resetLink)
        => SendEmailAsync(email, "Sheetstorm — Passwort zurücksetzen",
            $"<p>Hallo {System.Net.WebUtility.HtmlEncode(user.DisplayName)},</p>" +
            $"<p>du kannst dein Passwort hier zurücksetzen:</p>" +
            $"<p><a href=\"{resetLink}\">Passwort zurücksetzen</a></p>");

    public Task SendPasswordResetCodeAsync(ApplicationUser user, string email, string resetCode)
        => SendEmailAsync(email, "Sheetstorm — Reset-Code",
            $"<p>Dein Reset-Code: <strong>{resetCode}</strong></p>");
}
