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
builder.Services.AddScoped<EventOrgaService>();
builder.Services.AddScoped<PollService>();
builder.Services.AddScoped<PdfPageImageService>();
builder.Services.AddScoped<PushNotificationService>();

// OMR-Engine-Auswahl:
//   Omr:Provider=sheetstorm  → SheetstormOmrEngine (Rust-Sidecar, Default wenn URL gesetzt)
//   Omr:Provider=audiveris   → AudiverisOmrEngine (Java-Sidecar, Legacy)
//   <leer>                   → StubOmrEngine (entwicklungs-only, returned Demo-Daten)
//
// Beide Provider haben dieselbe HTTP-API (POST /recognize multipart, GET /health).
var omrProvider = (builder.Configuration["Omr:Provider"] ?? "").ToLowerInvariant();
var omrUrl = builder.Configuration["Omr:BaseUrl"] ?? builder.Configuration["ConnectionStrings:sheetstorm-omr"];
var audiverisUrl = builder.Configuration["Audiveris:BaseUrl"]
    ?? builder.Configuration["ConnectionStrings:audiveris"];

#pragma warning disable EXTEXP0001 // Resilience-Handler-Remove ist als experimental markiert, funktioniert aber stabil

// Wenn Sheetstorm-OMR explizit gewählt wurde oder Audiveris fehlt aber Sheetstorm-URL da ist
if ((omrProvider == "sheetstorm" || string.IsNullOrEmpty(audiverisUrl)) && !string.IsNullOrEmpty(omrUrl))
{
    builder.Services.AddHttpClient("sheetstorm-omr", c =>
    {
        c.BaseAddress = new Uri(omrUrl);
        c.Timeout = TimeSpan.FromMinutes(15);
    }).RemoveAllResilienceHandlers();
    builder.Services.AddScoped<IOmrEngine, SheetstormOmrEngine>();
}
else if (!string.IsNullOrEmpty(audiverisUrl))
{
    builder.Services.AddHttpClient("audiveris", c =>
    {
        c.BaseAddress = new Uri(audiverisUrl);
        c.Timeout = TimeSpan.FromMinutes(15);
    }).RemoveAllResilienceHandlers();
    builder.Services.AddScoped<IOmrEngine, AudiverisOmrEngine>();
}
else
{
    builder.Services.AddScoped<IOmrEngine, StubOmrEngine>();
}
#pragma warning restore EXTEXP0001

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

// Forwarded-Headers fuer Reverse-Proxy / Dev-Tunnels (devtunnels.ms,
// trycloudflare.com, ngrok). Sonst nimmt Kestrel den lokalen Hostnamen
// und Login-Redirects landen auf https://localhost statt der Tunnel-URL.
app.UseForwardedHeaders(new Microsoft.AspNetCore.Builder.ForwardedHeadersOptions
{
    ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedFor
                     | Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedProto
                     | Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedHost,
    KnownNetworks = { },
    KnownProxies = { },
});

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

// Poll-CSV-Export
app.MapGet("/api/polls/{pollId:guid}/export.csv", async (
    Guid pollId,
    Sheetstorm.Web.Application.PollService polls,
    System.Security.Claims.ClaimsPrincipal user,
    Microsoft.AspNetCore.Identity.UserManager<Sheetstorm.Infrastructure.Persistence.ApplicationUser> userManager,
    CancellationToken ct) =>
{
    var u = await userManager.GetUserAsync(user);
    if (u is null) return Results.Unauthorized();
    var csv = await polls.ExportCsvAsync(pollId, ct);
    return Results.Text(csv, "text/csv; charset=utf-8");
}).RequireAuthorization();

// Conductor-Public-Key-Endpoints fuer BLE/Sync-Pairing.
// PUT: Dirigent meldet seinen Public-Key beim Event-Start.
// GET: Mitglieder holen ihn beim Verbinden ab — ohne den Key wird kein
// Schedule-Paket akzeptiert.
app.MapPut("/api/events/{eventId:guid}/conductor-key", async (
    Guid eventId,
    Sheetstorm.Web.ConductorKeyDto dto,
    Sheetstorm.Web.Application.ConductorSyncService sync,
    System.Security.Claims.ClaimsPrincipal user,
    Microsoft.AspNetCore.Identity.UserManager<Sheetstorm.Infrastructure.Persistence.ApplicationUser> userManager,
    Sheetstorm.Infrastructure.Persistence.SheetstormDbContext db,
    CancellationToken ct) =>
{
    var u = await userManager.GetUserAsync(user);
    if (u is null) return Results.Unauthorized();
    var ev = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
        .FirstOrDefaultAsync(db.Events.Where(e => e.Id == eventId), ct);
    if (ev is null) return Results.NotFound();
    // Nur Dirigenten/Admins/Owner duerfen einen Key registrieren
    var membership = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
        .FirstOrDefaultAsync(db.Memberships.Where(m => m.BandId == ev.BandId && m.UserId == u.Id), ct);
    if (membership is null) return Results.Forbid();
    var allowed = (membership.Roles & (Sheetstorm.Domain.Identity.BandRole.Dirigent | Sheetstorm.Domain.Identity.BandRole.Admin | Sheetstorm.Domain.Identity.BandRole.Owner)) != 0;
    if (!allowed) return Results.Forbid();

    await sync.StartAsync(eventId, u.Id, dto.PublicKeyBase64, ct);
    return Results.NoContent();
}).RequireAuthorization();

app.MapGet("/api/events/{eventId:guid}/conductor-key", async (
    Guid eventId,
    Sheetstorm.Web.Application.ConductorSyncService sync,
    System.Security.Claims.ClaimsPrincipal user,
    Microsoft.AspNetCore.Identity.UserManager<Sheetstorm.Infrastructure.Persistence.ApplicationUser> userManager,
    Sheetstorm.Infrastructure.Persistence.SheetstormDbContext db,
    CancellationToken ct) =>
{
    var u = await userManager.GetUserAsync(user);
    if (u is null) return Results.Unauthorized();
    var ev = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
        .FirstOrDefaultAsync(db.Events.Where(e => e.Id == eventId), ct);
    if (ev is null) return Results.NotFound();
    var isMember = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions
        .AnyAsync(db.Memberships.Where(m => m.BandId == ev.BandId && m.UserId == u.Id), ct);
    if (!isMember) return Results.Forbid();
    var session = await sync.GetActiveAsync(eventId, ct);
    if (session?.PublicKeyBase64 is null) return Results.NotFound();
    return Results.Json(new { publicKey = session.PublicKeyBase64 });
}).RequireAuthorization();

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
