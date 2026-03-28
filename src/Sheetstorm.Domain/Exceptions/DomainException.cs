namespace Sheetstorm.Domain.Exceptions;

/// <summary>
/// Exception for domain-level errors (not-found, conflict, validation).
/// Carries HTTP status and error code for middleware translation.
/// </summary>
public class DomainException(string errorCode, string message, int statusCode) : Exception(message)
{
    public string ErrorCode { get; } = errorCode;
    public int StatusCode { get; } = statusCode;
}
