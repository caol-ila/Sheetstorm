using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Auth;

namespace Sheetstorm.Api.Middleware;

/// <summary>
/// Converts AuthException and DomainException into structured JSON error responses.
/// Includes a catch-all for unexpected exceptions to prevent information leakage.
/// </summary>
public class AuthExceptionMiddleware(RequestDelegate next, ILogger<AuthExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (DomainException ex)
        {
            context.Response.StatusCode = ex.StatusCode;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new ErrorResponse(ex.ErrorCode, ex.Message));
        }
        catch (AuthException ex)
        {
            context.Response.StatusCode = ex.StatusCode;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new ErrorResponse(ex.ErrorCode, ex.Message));
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled exception processing {Method} {Path}", context.Request.Method, context.Request.Path);
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new ErrorResponse("INTERNAL_ERROR", "An unexpected error occurred."));
        }
    }
}
