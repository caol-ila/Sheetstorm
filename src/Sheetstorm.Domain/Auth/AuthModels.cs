using System.ComponentModel.DataAnnotations;

namespace Sheetstorm.Domain.Auth;

public record RegisterRequest(
    [Required][EmailAddress] string Email,
    [Required][MinLength(8)] string Password,
    [Required][StringLength(100, MinimumLength = 2)] string DisplayName,
    string? Instrument
);

public record LoginRequest(
    [Required][EmailAddress] string Email,
    [Required] string Password
);

public record RefreshTokenRequest(
    [Required] string RefreshToken
);

public record ForgotPasswordRequest(
    [Required][EmailAddress] string Email
);

public record ResetPasswordRequest(
    [Required] string Token,
    [Required][MinLength(8)] string NewPassword
);

public record UserDto(
    Guid Id,
    string Email,
    string DisplayName,
    string? Instrument,
    bool OnboardingCompleted,
    bool EmailVerified,
    DateTime CreatedAt
);

public record AuthResponse(
    UserDto User,
    string AccessToken,
    string RefreshToken,
    string TokenType,
    int ExpiresIn
);

public record TokenResponse(
    string AccessToken,
    string RefreshToken,
    string TokenType,
    int ExpiresIn
);

public record MessageResponse(string Message);

public record ResetPasswordResponse(
    string Message,
    string AccessToken,
    string RefreshToken,
    string TokenType,
    int ExpiresIn
);

public record VerifyEmailRequest(
    [Required] string Token
);

public record ErrorResponse(string Error, string Message);
