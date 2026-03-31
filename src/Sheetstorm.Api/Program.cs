using System.Text;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;
using Sheetstorm.Api.Hubs;
using Sheetstorm.Api.Middleware;
using Sheetstorm.Infrastructure;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Seeding;

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();

// OpenAPI / Swagger
builder.Services.AddOpenApi();

// Health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("database");

// JWT Authentication
var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSection["Key"] ?? throw new InvalidOperationException("JWT Key not configured.");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // CRITICAL: Prevent ASP.NET from remapping 'sub' to ClaimTypes.NameIdentifier.
        // Without this, User.FindFirstValue(JwtRegisteredClaimNames.Sub) returns null
        // and all authenticated endpoints crash with ArgumentNullException.
        options.MapInboundClaims = false;

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSection["Issuer"],
            ValidAudience = jwtSection["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.FromSeconds(30)
        };
        // Support JWT in SignalR WebSocket connections via query string
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = ctx =>
            {
                var accessToken = ctx.Request.Query["access_token"];
                var path = ctx.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                    ctx.Token = accessToken;
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();

// Rate limiting — 10 requests per 15 minutes per IP for auth endpoints
builder.Services.AddRateLimiter(options =>
{
    options.AddPolicy("auth", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(15),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0
            }));

    // Substitute-token validation: brute-force protection for short tokens
    options.AddPolicy("substitute-validate", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0
            }));

    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = async (context, _) =>
    {
        context.HttpContext.Response.ContentType = "application/json";
        await context.HttpContext.Response.WriteAsJsonAsync(
            new { error = "TOO_MANY_ATTEMPTS", message = "Zu viele Versuche. Bitte warte 15 Minuten." });
    };
});

// SignalR (Realtime: WebSocket fallback for Metronome + Annotation sync)
builder.Services.AddSignalR();

// EF Core + PostgreSQL (registered in Infrastructure)
builder.Services.AddInfrastructure(builder.Configuration);

// Demo-Seeder (nur im Development-Modus aktiv)
builder.Services.AddScoped<DemoDataSeeder>();

// CORS — build allowed-origins list from config and optional env-var override
var corsOriginsFromConfig = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? [];

var corsEnvVar = Environment.GetEnvironmentVariable("CORS_ALLOWED_ORIGINS");
if (!string.IsNullOrWhiteSpace(corsEnvVar))
{
    var envOrigins = corsEnvVar.Split(',',
        StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
    corsOriginsFromConfig = [.. corsOriginsFromConfig.Concat(envOrigins).Distinct()];
}

builder.Services.AddCors(options =>
{
    options.AddPolicy("DevPolicy", policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());

    options.AddPolicy("ProdPolicy", policy =>
    {
        if (corsOriginsFromConfig.Length > 0)
            policy.WithOrigins(corsOriginsFromConfig).AllowAnyMethod().AllowAnyHeader();
        else
            policy.SetIsOriginAllowed(_ => false);
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseCors("DevPolicy");

    // Demo-User für lokale Entwicklung seeden
    using (var scope = app.Services.CreateScope())
    {
        var seeder = scope.ServiceProvider.GetRequiredService<DemoDataSeeder>();
        await seeder.SeedAsync();
    }
}
else
{
    app.UseCors("ProdPolicy");
}

app.UseHttpsRedirection();
app.UseRateLimiter();
app.UseMiddleware<RequestLoggingMiddleware>();
app.UseMiddleware<AuthExceptionMiddleware>();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health");

// SignalR hubs
app.MapHub<SongBroadcastHub>("/hubs/song-broadcast");
// app.MapHub<MetronomeHub>("/hubs/metronome");
// app.MapHub<AnnotationHub>("/hubs/annotations");

app.Run();

// Expose Program to the test project via WebApplicationFactory<Program>
public partial class Program { }
