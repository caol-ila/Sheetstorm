using Microsoft.AspNetCore.Identity;

namespace Sheetstorm.Infrastructure.Persistence;

/// <summary>
/// Anwendungsspezifische Erweiterung des ASP.NET Identity-Users.
/// Identity verwaltet Email/PW/Confirmation, hier kommen Profil-Felder hin.
/// </summary>
public sealed class ApplicationUser : IdentityUser<Guid>
{
    public string DisplayName { get; set; } = default!;
    public string? AvatarBlobKey { get; set; }
    public string PreferredCulture { get; set; } = "de-DE";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
