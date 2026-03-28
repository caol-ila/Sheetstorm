namespace Sheetstorm.Infrastructure.Auth;

/// <summary>
/// Domain exception for auth errors, carrying HTTP status and error code.
/// </summary>
public class AuthException(string errorCode, string message, int statusCode) : Exception(message)
{
    public string ErrorCode { get; } = errorCode;
    public int StatusCode { get; } = statusCode;
}
