var builder = DistributedApplication.CreateBuilder(args);

var postgres = builder.AddPostgres("postgres")
    .WithPgAdmin()
    .WithDataVolume();

var sheetstormDb = postgres.AddDatabase("sheetstormdb");

var mailhog = builder.AddContainer("mailhog", "mailhog/mailhog")
    .WithEndpoint(port: 1025, targetPort: 1025, name: "smtp")
    .WithEndpoint(port: 8025, targetPort: 8025, name: "ui", scheme: "http");

// Audiveris-Sidecar.
//
// Strategie: Wir bauen das Image NUR EINMAL ueber `scripts/build-audiveris.ps1`
// (oder beim ersten AppHost-Start, wenn nicht vorhanden). Aspire startet hier
// nur den fertigen Container ueber `AddContainer(name, image)` — kein Build,
// kein Wartezeit-Verlust. Aenderungen am Dockerfile/server.py erkennt das
// Build-Skript ueber einen SHA256-Hash der Quellen unter docker/audiveris/.
// Wenn der Hash sich geaendert hat, wird neu gebaut.
//
// Aktivieren: dotnet run --project src/Sheetstorm.AppHost -- --enable-audiveris

var enableAudiveris = args.Contains("--enable-audiveris")
    || string.Equals(Environment.GetEnvironmentVariable("SHEETSTORM_ENABLE_AUDIVERIS"), "true", StringComparison.OrdinalIgnoreCase);

IResourceBuilder<ContainerResource>? audiveris = null;
if (enableAudiveris)
{
    EnsureAudiverisImageBuilt();
    audiveris = builder.AddContainer("audiveris", "sheetstorm-audiveris", "dev")
        .WithEndpoint(port: 8081, targetPort: 8080, name: "http", scheme: "http")
        .WithHttpHealthCheck("/health");
}

var apiService = builder.AddProject<Projects.Sheetstorm_ApiService>("apiservice")
    .WithHttpHealthCheck("/health")
    .WithReference(sheetstormDb)
    .WaitFor(sheetstormDb);

var web = builder.AddProject<Projects.Sheetstorm_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithHttpHealthCheck("/health")
    .WithReference(apiService)
    .WithReference(sheetstormDb)
    .WithEnvironment("Smtp__Host", mailhog.GetEndpoint("smtp").Property(Aspire.Hosting.ApplicationModel.EndpointProperty.Host))
    .WithEnvironment("Smtp__Port", mailhog.GetEndpoint("smtp").Property(Aspire.Hosting.ApplicationModel.EndpointProperty.Port))
    .WaitFor(apiService)
    .WaitFor(sheetstormDb);

if (audiveris is not null)
{
    web = web
        .WithEnvironment("Audiveris__BaseUrl", audiveris.GetEndpoint("http"))
        .WaitFor(audiveris);
}

builder.Build().Run();


// ─── Helpers ────────────────────────────────────────────────────────────

static void EnsureAudiverisImageBuilt()
{
    var dockerCtx = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", "docker", "audiveris"));
    if (!System.IO.Directory.Exists(dockerCtx))
    {
        Console.Error.WriteLine($"⚠ Audiveris-Build-Kontext nicht gefunden: {dockerCtx} — Container wird nicht gebaut.");
        return;
    }

    // Hash ueber alle Dateien im docker-Verzeichnis bilden.
    var hash = ComputeDirHash(dockerCtx);
    var stampFile = System.IO.Path.Combine(dockerCtx, ".image-hash");
    var existingHash = System.IO.File.Exists(stampFile) ? System.IO.File.ReadAllText(stampFile).Trim() : "";

    var imageExists = ImageExists("sheetstorm-audiveris:dev");
    if (imageExists && existingHash == hash)
    {
        Console.WriteLine("✓ Audiveris-Image ist aktuell (Hash unveraendert), ueberspringe Build.");
        return;
    }

    Console.WriteLine(imageExists
        ? "🔨 Audiveris-Quellen geaendert — baue Image neu …"
        : "🔨 Audiveris-Image fehlt — baue …");

    var psi = new System.Diagnostics.ProcessStartInfo("docker", $"build -t sheetstorm-audiveris:dev \"{dockerCtx}\"")
    {
        RedirectStandardOutput = false,
        RedirectStandardError = false,
        UseShellExecute = false,
    };
    var p = System.Diagnostics.Process.Start(psi)!;
    p.WaitForExit();
    if (p.ExitCode != 0)
    {
        Console.Error.WriteLine($"❌ docker build fehlgeschlagen (Exit {p.ExitCode}). Audiveris-Container wird ggf. nicht starten.");
        return;
    }

    System.IO.File.WriteAllText(stampFile, hash);
    Console.WriteLine("✓ Audiveris-Image gebaut.");
}

static bool ImageExists(string imageRef)
{
    try
    {
        var psi = new System.Diagnostics.ProcessStartInfo("docker", $"image inspect {imageRef}")
        {
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        var p = System.Diagnostics.Process.Start(psi)!;
        p.WaitForExit();
        return p.ExitCode == 0;
    }
    catch { return false; }
}

static string ComputeDirHash(string dir)
{
    using var sha = System.Security.Cryptography.SHA256.Create();
    var sb = new System.Text.StringBuilder();
    foreach (var f in System.IO.Directory.GetFiles(dir).OrderBy(f => f))
    {
        // .image-hash selbst ueberspringen
        if (System.IO.Path.GetFileName(f) == ".image-hash") continue;
        sb.Append(System.IO.Path.GetFileName(f));
        sb.Append('|');
        sb.Append(Convert.ToHexString(sha.ComputeHash(System.IO.File.ReadAllBytes(f))));
        sb.Append('\n');
    }
    return Convert.ToHexString(sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(sb.ToString())));
}
