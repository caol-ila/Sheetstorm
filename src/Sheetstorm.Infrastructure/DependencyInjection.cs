using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Email;
using Sheetstorm.Infrastructure.KapelleManagement;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Stimmen;

namespace Sheetstorm.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection not configured.");

        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(
                connectionString,
                npgsql => npgsql.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName)));

        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IEmailService, DevEmailService>();
        services.AddScoped<IKapelleService, KapelleService>();
        services.AddScoped<IStimmenService, StimmenService>();

        return services;
    }
}
