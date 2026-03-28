using Amazon.S3;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Email;
using Sheetstorm.Infrastructure.Import;
using Sheetstorm.Infrastructure.KapelleManagement;
using Sheetstorm.Infrastructure.Persistence;

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

        // Import pipeline
        services.AddScoped<IImportService, ImportService>();
        services.AddScoped<IAiMetadataService, StubAiMetadataService>();
        services.AddScoped<IStorageService, MinioStorageService>();

        // S3-compatible storage client (MinIO local, AWS S3 production)
        var storageEndpoint = configuration["Storage:Endpoint"] ?? "http://localhost:9000";
        var accessKey = configuration["Storage:AccessKey"] ?? "minioadmin";
        var secretKey = configuration["Storage:SecretKey"] ?? "minioadmin";

        services.AddSingleton<IAmazonS3>(_ => new AmazonS3Client(
            accessKey,
            secretKey,
            new AmazonS3Config
            {
                ServiceURL = storageEndpoint,
                ForcePathStyle = true
            }));

        return services;
    }
}
