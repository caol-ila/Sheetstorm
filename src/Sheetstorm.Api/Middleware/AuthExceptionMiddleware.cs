using Sheetstorm.Domain.Auth;
using Sheetstorm.Infrastructure.Auth;

namespace Sheetstorm.Api.Middleware;

/// <summary>
/// Converts AuthException into a structured JSON error response.
/// </summary>
public class AuthExceptionMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (AuthException ex)
        {
            context.Response.StatusCode = ex.StatusCode;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new ErrorResponse(ex.ErrorCode, ex.Message));
        }
    }
}
