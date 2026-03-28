using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Auth;

namespace Sheetstorm.Api.Middleware;

/// <summary>
/// Converts AuthException and DomainException into structured JSON error responses.
/// </summary>
public class AuthExceptionMiddleware(RequestDelegate next)
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
    }
}
