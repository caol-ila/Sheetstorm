using System.Globalization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Localization;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Infrastructure.Data;
using Sheetstorm.ServiceDefaults;

var builder = WebApplication.CreateBuilder(args);

// Aspire ServiceDefaults
builder.AddServiceDefaults();

// Localization
builder.Services.AddLocalization();

// OpenAPI (.NET 10 native)
builder.Services.AddOpenApi();

// Health Checks
builder.Services.AddHealthChecks();

// CORS for Flutter Web
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:8080")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// JWT Auth (stub - no flow implementation)
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // TODO: Configure JWT validation parameters (issuer, audience, signing key)
        // This is a stub - no actual authentication flow implemented yet
        options.TokenValidationParameters = new()
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = false,
            ValidateIssuerSigningKey = false
        };
    });

// Database
builder.Services.AddDbContext<SheetstormDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection") ?? "Host=localhost;Database=sheetstorm;Username=postgres;Password=postgres"));

// Controllers
builder.Services.AddControllers();

// Global Exception Handler
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

var app = builder.Build();

// Localization middleware
var supportedCultures = new[] { new CultureInfo("de-DE"), new CultureInfo("en-US") };
app.UseRequestLocalization(new RequestLocalizationOptions
{
    DefaultRequestCulture = new RequestCulture("de-DE"),
    SupportedCultures = supportedCultures,
    SupportedUICultures = supportedCultures
});

// Exception handling
app.UseExceptionHandler();

// OpenAPI
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// CORS
app.UseCors();

// Auth
app.UseAuthentication();
app.UseAuthorization();

// Health Checks
app.MapHealthChecks("/health");

// Controllers
app.MapControllers();

// Ping endpoint
app.MapGet("/ping", () => Results.Ok(new { message = "Hallo Blaskapelle" }))
   .WithName("Ping")
   .WithOpenApi();

app.Run();

// Make Program accessible for tests
public partial class Program { }
