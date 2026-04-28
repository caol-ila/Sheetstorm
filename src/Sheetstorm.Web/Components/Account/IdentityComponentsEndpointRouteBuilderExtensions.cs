using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Routing;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Web.Components.Account;

internal static class IdentityComponentsEndpointRouteBuilderExtensions
{
    public static IEndpointConventionBuilder MapAdditionalIdentityEndpoints(this IEndpointRouteBuilder endpoints)
    {
        ArgumentNullException.ThrowIfNull(endpoints);

        var accountGroup = endpoints.MapGroup("/Account");

        accountGroup.MapPost("/Logout", async (SignInManager<ApplicationUser> signInManager) =>
        {
            await signInManager.SignOutAsync();
            return TypedResults.LocalRedirect("~/");
        });

        // GET-Variante: nach Account-Löschung wo User nichts mehr hat
        accountGroup.MapGet("/Logout-After-Delete", async (SignInManager<ApplicationUser> signInManager) =>
        {
            await signInManager.SignOutAsync();
            return TypedResults.LocalRedirect("~/?deleted=1");
        });

        return accountGroup;
    }
}
