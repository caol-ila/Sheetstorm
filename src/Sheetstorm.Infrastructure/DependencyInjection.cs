using Amazon.S3;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Sheetstorm.Infrastructure.Attendance;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.BandManagement;
using Sheetstorm.Infrastructure.Communication;
using Sheetstorm.Infrastructure.Config;
using Sheetstorm.Infrastructure.Email;
using Sheetstorm.Infrastructure.Events;
using Sheetstorm.Infrastructure.Gema;
using Sheetstorm.Infrastructure.Import;
using Sheetstorm.Infrastructure.MediaLinks;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Polls;
using Sheetstorm.Infrastructure.Setlists;
using Sheetstorm.Infrastructure.Shifts;
using Sheetstorm.Infrastructure.Substitutes;
using Sheetstorm.Infrastructure.Voices;

namespace Sheetstorm.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        var useInMemory = string.IsNullOrEmpty(connectionString) 
            || connectionString.Contains("CHANGE_ME")
            || configuration.GetValue<bool>("UseInMemoryDatabase");

        services.AddDbContext<AppDbContext>(options =>
        {
            if (useInMemory)
                options.UseInMemoryDatabase("SheetstormDev");
            else
                options.UseNpgsql(
                    connectionString!,
                    npgsql => npgsql.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName));
        });

        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IEmailService, DevEmailService>();
        services.AddScoped<IBandService, BandService>();
        services.AddScoped<IConfigService, ConfigService>();
        services.AddScoped<IVoiceService, VoiceService>();
        services.AddScoped<ISetlistService, SetlistService>();
        services.AddScoped<IMediaLinkService, MediaLinkService>();
        services.AddScoped<IPostService, PostService>();
        services.AddScoped<IPollService, PollService>();
        services.AddScoped<IAttendanceService, AttendanceService>();
        services.AddScoped<IEventService, EventService>();
        services.AddScoped<IGemaService, GemaService>();
        services.AddScoped<ISubstituteService, SubstituteService>();
        services.AddScoped<IShiftService, ShiftService>();

        // Import pipeline
        services.AddScoped<IImportService, ImportService>();
        services.AddScoped<IAiMetadataService, StubAiMetadataService>();

        // Storage: local filesystem in dev, MinIO/S3 in production
        if (useInMemory)
        {
            services.AddScoped<IStorageService>(sp =>
            {
                var storagePath = Path.Combine(AppContext.BaseDirectory, "storage");
                var logger = sp.GetRequiredService<ILogger<LocalFileStorageService>>();
                return new LocalFileStorageService(storagePath, logger);
            });
        }
        else
        {
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
        }

        return services;
    }
}
