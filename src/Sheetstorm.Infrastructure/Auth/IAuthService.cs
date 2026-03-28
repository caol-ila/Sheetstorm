using Sheetstorm.Domain.Auth;

namespace Sheetstorm.Infrastructure.Auth;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest request);
    Task<AuthResponse> LoginAsync(LoginRequest request);
    Task<TokenResponse> RefreshAsync(RefreshTokenRequest request);
    Task<MessageResponse> ForgotPasswordAsync(ForgotPasswordRequest request);
    Task<ResetPasswordResponse> ResetPasswordAsync(ResetPasswordRequest request);
}
