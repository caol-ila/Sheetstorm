using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.UI.Services;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Web;
using Sheetstorm.Web.Application;
using Sheetstorm.Web.Components;
using Sheetstorm.Web.Components.Account;
using Sheetstorm.Web.Services;

var builder = WebApplication.CreateBuilder(args);

// Add service defaults & Aspire client integrations.
builder.AddServiceDefaults();

// PostgreSQL via Aspire — connection name "sheetstormdb" matches AppHost.cs
builder.AddNpgsqlDbContext<SheetstormDbContext>("sheetstormdb", configureDbContextOptions: opt =>
{
    // In Dev: PendingModelChanges-Warning ignorieren (zb wenn Snapshot von alter Session im DB-Volume liegt)
    if (builder.Environment.IsDevelopment())
    {
        opt.ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
    }
});

// Identity
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddScoped<IdentityUserAccessor>();
builder.Services.AddScoped<IdentityRedirectManager>();
builder.Services.AddScoped<AuthenticationStateProvider, IdentityRevalidatingAuthenticationStateProvider>();

builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = IdentityConstants.ApplicationScheme;
        options.DefaultSignInScheme = IdentityConstants.ExternalScheme;
    })
    .AddIdentityCookies();

builder.Services.AddAuthorizationBuilder();

builder.Services.AddIdentityCore<ApplicationUser>(options =>
    {
        // In Development einfache Passwörter erlauben für Demo-Accounts
        if (builder.Environment.IsDevelopment())
        {
            options.SignIn.RequireConfirmedAccount = false;
            options.Password.RequiredLength = 4;
            options.Password.RequireDigit = false;
            options.Password.RequireLowercase = false;
            options.Password.RequireUppercase = false;
            options.Password.RequireNonAlphanumeric = false;
        }
        else
        {
            options.SignIn.RequireConfirmedAccount = true;
            options.Password.RequiredLength = 8;
        }
        options.User.RequireUniqueEmail = true;
    })
    .AddRoles<IdentityRole<Guid>>()
    .AddEntityFrameworkStores<SheetstormDbContext>()
    .AddSignInManager()
    .AddDefaultTokenProviders();

builder.Services.Configure<SmtpOptions>(builder.Configuration.GetSection("Smtp"));
builder.Services.Configure<VapidOptions>(builder.Configuration.GetSection("Vapid"));
builder.Services.AddSingleton<IEmailSender<ApplicationUser>, SmtpEmailSender>();
builder.Services.AddSingleton<IEmailSender, SmtpEmailSender>();

// Application services
builder.Services.AddScoped<BandService>();
builder.Services.AddScoped<PieceService>();
builder.Services.AddScoped<EventService>();
builder.Services.AddScoped<SetListService>();
builder.Services.AddScoped<ConductorSyncService>();
builder.Services.AddScoped<OfflineService>();
builder.Services.AddScoped<OmrService>();
builder.Services.AddScoped<AnnotationService>();
builder.Services.AddScoped<ShiftService>();
builder.Services.AddScoped<PushNotificationService>();

// OMR-Engine: wenn Audiveris-URL konfiguriert -> echter Adapter, sonst Stub
var audiverisUrl = builder.Configuration["Audiveris:BaseUrl"]
    ?? builder.Configuration["ConnectionStrings:audiveris"];
if (!string.IsNullOrEmpty(audiverisUrl))
{
    builder.Services.AddHttpClient("audiveris", c => c.BaseAddress = new Uri(audiverisUrl));
    builder.Services.AddScoped<IOmrEngine, AudiverisOmrEngine>();
}
else
{
    builder.Services.AddScoped<IOmrEngine, StubOmrEngine>();
}

builder.Services.AddHostedService<OmrBackgroundWorker>();
builder.Services.AddHostedService<EventReminderWorker>();
builder.Services.AddSingleton<LocalFileStore>();

builder.Services.AddSignalR();

// Active band scope (per-circuit)
builder.Services.AddScoped<ActiveBandState>();

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddOutputCache();

builder.Services.AddHttpClient<WeatherApiClient>(client =>
    {
        client.BaseAddress = new("https+http://apiservice");
    });

var app = builder.Build();

// Ensure DB schema + seed
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<SheetstormDbContext>();
    await db.Database.MigrateAsync();
    await SeedRunner.RunAsync(db);

    if (app.Environment.IsDevelopment())
    {
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var fileStore = scope.ServiceProvider.GetRequiredService<LocalFileStore>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        await DemoSeed.RunAsync(db, userManager, fileStore, logger, app.Environment);
    }
}

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseAntiforgery();

app.UseOutputCache();

app.MapStaticAssets();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

// Identity-Endpoints für Logout etc. (Razor-Form-Posts)
app.MapAdditionalIdentityEndpoints();

// Datei-Download (PDFs, etc.)
app.MapGet("/files/parts/{partId:guid}/{fileId:guid}", async (
    Guid partId, Guid fileId,
    HttpContext http,
    Sheetstorm.Infrastructure.Persistence.SheetstormDbContext db,
    Sheetstorm.Web.Services.LocalFileStore store,
    CancellationToken ct) =>
{
    var f = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
        .FirstOrDefaultAsync(db.PartFiles.Where(x => x.Id == fileId && x.PartId == partId), ct);
    if (f is null) return Results.NotFound();
    if (!store.Exists(f.BlobKey)) return Results.NotFound();
    var stream = store.OpenRead(f.BlobKey);
    var mime = store.GetMimeType(f.OriginalFileName);
    var asDownload = http.Request.Query.ContainsKey("download");
    if (asDownload)
    {
        return Results.File(stream, mime, f.OriginalFileName, enableRangeProcessing: true);
    }
    // Default: inline serving (kein Content-Disposition: attachment) — wichtig fuer
    // <embed>/<iframe>-PDF-Anzeige und MusicXML-Fetch ohne Browser-Download.
    var safe = System.Net.WebUtility.UrlEncode(f.OriginalFileName);
    http.Response.Headers["Content-Disposition"] = $"inline; filename=\"{safe}\"; filename*=UTF-8''{safe}";
    return Results.File(stream, mime, enableRangeProcessing: true);
}).RequireAuthorization();

// SignalR Hub
app.MapHub<Sheetstorm.Web.Hubs.ConductorSyncHub>("/hubs/conductor-sync").RequireAuthorization();

// iCal-Export pro Verein (Token-basiert wäre Phase 2; aktuell Auth-required)
app.MapGet("/api/bands/{slug}/calendar.ics", async (
    string slug,
    System.Security.Claims.ClaimsPrincipal user,
    Microsoft.AspNetCore.Identity.UserManager<Sheetstorm.Infrastructure.Persistence.ApplicationUser> userManager,
    Sheetstorm.Infrastructure.Persistence.SheetstormDbContext db,
    CancellationToken ct) =>
{
    var u = await userManager.GetUserAsync(user);
    if (u is null) return Results.Unauthorized();

    var band = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
        .FirstOrDefaultAsync(db.Bands.Where(b => b.Slug == slug), ct);
    if (band is null) return Results.NotFound();

    var isMember = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
        .AnyAsync(db.Memberships.Where(m => m.BandId == band.Id && m.UserId == u.Id), ct);
    if (!isMember) return Results.Forbid();

    var events = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
        .ToListAsync(db.Events.Where(e => e.BandId == band.Id).OrderBy(e => e.StartUtc), ct);

    var ics = Sheetstorm.Web.Application.ICalExporter.Build(band.Name, events);
    return Results.Text(ics, "text/calendar; charset=utf-8");
}).RequireAuthorization();

// Push-Subscription registrieren (für Phase 2 echte Web-Push-Anbindung)
app.MapGet("/api/push/vapid-public-key", (Sheetstorm.Web.Application.PushNotificationService svc) =>
{
    return svc.PublicKey is null ? Results.NoContent() : Results.Text(svc.PublicKey);
});

app.MapPost("/api/push/subscribe", async (
    Sheetstorm.Web.PushSubscriptionDto dto,
    System.Security.Claims.ClaimsPrincipal user,
    Microsoft.AspNetCore.Identity.UserManager<Sheetstorm.Infrastructure.Persistence.ApplicationUser> userManager,
    Sheetstorm.Infrastructure.Persistence.SheetstormDbContext db,
    CancellationToken ct) =>
{
    var u = await userManager.GetUserAsync(user);
    if (u is null) return Results.Unauthorized();
    var existing = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
        .FirstOrDefaultAsync(db.PushSubscriptions.Where(p => p.Endpoint == dto.Endpoint), ct);
    if (existing is null)
    {
        db.PushSubscriptions.Add(Sheetstorm.Domain.Identity.PushSubscription.Create(u.Id, dto.Endpoint, dto.P256dh, dto.Auth));
        await db.SaveChangesAsync(ct);
    }
    return Results.NoContent();
}).RequireAuthorization();

// Annotationen (CRUD via REST)
app.MapGet("/api/parts/{partId:guid}/annotations/{page:int}", async (
    Guid partId, int page,
    System.Security.Claims.ClaimsPrincipal user,
    Microsoft.AspNetCore.Identity.UserManager<Sheetstorm.Infrastructure.Persistence.ApplicationUser> userManager,
    Sheetstorm.Web.Application.AnnotationService svc,
    CancellationToken ct) =>
{
    var u = await userManager.GetUserAsync(user);
    if (u is null) return Results.Unauthorized();
    var a = await svc.GetAsync(partId, u.Id, page, ct);
    return a is null ? Results.NotFound() : Results.Ok(new { layerJson = a.LayerJson, version = a.Version });
}).RequireAuthorization();

app.MapPut("/api/parts/{partId:guid}/annotations/{page:int}", async (
    Guid partId, int page,
    Sheetstorm.Web.AnnotationSaveDto dto,
    System.Security.Claims.ClaimsPrincipal user,
    Microsoft.AspNetCore.Identity.UserManager<Sheetstorm.Infrastructure.Persistence.ApplicationUser> userManager,
    Sheetstorm.Web.Application.AnnotationService svc,
    CancellationToken ct) =>
{
    var u = await userManager.GetUserAsync(user);
    if (u is null) return Results.Unauthorized();
    await svc.SaveAsync(partId, u.Id, page, dto.LayerJson, ct);
    return Results.NoContent();
}).RequireAuthorization();

// Offline-API für Service Worker
app.MapGet("/api/offline/urls", async (
    System.Security.Claims.ClaimsPrincipal user,
    Microsoft.AspNetCore.Identity.UserManager<Sheetstorm.Infrastructure.Persistence.ApplicationUser> userManager,
    Sheetstorm.Web.Application.OfflineService svc,
    CancellationToken ct) =>
{
    var u = await userManager.GetUserAsync(user);
    if (u is null) return Results.Unauthorized();
    var list = await svc.GetUrlsToCacheAsync(u.Id, ct);
    return Results.Ok(list);
}).RequireAuthorization();

app.MapPost("/api/offline/{pieceId:guid}/toggle", async (
    Guid pieceId, bool offline,
    System.Security.Claims.ClaimsPrincipal user,
    Microsoft.AspNetCore.Identity.UserManager<Sheetstorm.Infrastructure.Persistence.ApplicationUser> userManager,
    Sheetstorm.Web.Application.OfflineService svc,
    CancellationToken ct) =>
{
    var u = await userManager.GetUserAsync(user);
    if (u is null) return Results.Unauthorized();
    await svc.SetAsync(u.Id, pieceId, offline, ct);
    return Results.NoContent();
}).RequireAuthorization();

app.MapDefaultEndpoints();

app.Run();
