var builder = DistributedApplication.CreateBuilder(args);

var postgres = builder.AddPostgres("postgres")
    .WithPgAdmin()
    .WithDataVolume();

var sheetstormDb = postgres.AddDatabase("sheetstormdb");

var mailhog = builder.AddContainer("mailhog", "mailhog/mailhog")
    .WithEndpoint(port: 1025, targetPort: 1025, name: "smtp")
    .WithEndpoint(port: 8025, targetPort: 8025, name: "ui", scheme: "http");

// ─── OMR-Engine-Auswahl ───────────────────────────────────────────────────
//
// Sheetstorm hat **zwei** OMR-Engines, die parallel laufen koennen:
//
// 1. **Sheetstorm-OMR** (Rust, eigene Engine, in src/omr-rust/)
//    Schnell (~1s/Seite), produziert Detections-JSON mit Bbox-Daten und SIG.
//    Aktivieren: `--enable-omr` ODER env SHEETSTORM_ENABLE_OMR=true
//
// 2. **Audiveris** (Java, https://github.com/Audiveris/audiveris)
//    Langsamer (5-60s/Seite), produziert komplettes MusicXML (inkl. Texte).
//    Aktivieren: `--enable-audiveris` ODER env SHEETSTORM_ENABLE_AUDIVERIS=true
//
// **Welcher wird vom Web-UI verwendet?** Steuerbar via:
//
// - `--use-engine=sheetstorm` → Sheetstorm-OMR ist aktiv (Default wenn beide laufen)
// - `--use-engine=audiveris`  → Audiveris ist aktiv
// - `--use-engine=stub`       → Stub-Engine (Demo-Daten)
// - keine Angabe              → automatisch: Audiveris wenn nur Audiveris laeuft,
//                               sonst Sheetstorm-OMR
//
// Beispiele:
//   dotnet run --project src/Sheetstorm.AppHost -- --enable-omr
//   dotnet run --project src/Sheetstorm.AppHost -- --enable-audiveris
//   dotnet run --project src/Sheetstorm.AppHost -- --enable-omr --enable-audiveris --use-engine=audiveris
//
// Die Container-Images werden bei Bedarf automatisch via docker build erstellt
// (siehe EnsureContainerImageBuilt unten).

var enableAudiveris = args.Contains("--enable-audiveris")
    || string.Equals(Environment.GetEnvironmentVariable("SHEETSTORM_ENABLE_AUDIVERIS"), "true", StringComparison.OrdinalIgnoreCase);

var enableOmr = args.Contains("--enable-omr")
    || string.Equals(Environment.GetEnvironmentVariable("SHEETSTORM_ENABLE_OMR"), "true", StringComparison.OrdinalIgnoreCase);

// Gewuenschte Engine ableiten.
string? requestedEngine = null;
foreach (var a in args)
{
    if (a.StartsWith("--use-engine=", StringComparison.OrdinalIgnoreCase))
        requestedEngine = a.Substring("--use-engine=".Length).ToLowerInvariant();
}
requestedEngine ??= Environment.GetEnvironmentVariable("SHEETSTORM_USE_ENGINE")?.ToLowerInvariant();

IResourceBuilder<ContainerResource>? audiveris = null;
if (enableAudiveris)
{
    EnsureContainerImageBuilt("audiveris", "sheetstorm-audiveris");
    audiveris = builder.AddContainer("audiveris", "sheetstorm-audiveris", "dev")
        .WithEndpoint(port: 8081, targetPort: 8080, name: "http", scheme: "http")
        .WithHttpHealthCheck("/health");
}

IResourceBuilder<ContainerResource>? omr = null;
if (enableOmr)
{
    EnsureContainerImageBuilt("sheetstorm-omr", "sheetstorm-omr");
    omr = builder.AddContainer("sheetstorm-omr", "sheetstorm-omr", "dev")
        .WithEndpoint(port: 8091, targetPort: 8091, name: "http", scheme: "http")
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

// Engine-URLs verfuegbar machen — egal welche aktiv ist, beide URLs werden
// gesetzt damit das Web-Projekt notfalls beide ansprechen kann (z.B. fuer
// Comparison-View in der UI).
if (audiveris is not null)
{
    web = web
        .WithEnvironment("Audiveris__BaseUrl", audiveris.GetEndpoint("http"))
        .WaitFor(audiveris);
}
if (omr is not null)
{
    web = web
        .WithEnvironment("Omr__BaseUrl", omr.GetEndpoint("http"))
        .WaitFor(omr);
}

// Active-Provider explizit setzen.
// Logik:
//   1. Wenn requestedEngine gesetzt → genau diese Engine aktivieren (sofern URL da)
//   2. Sonst: Wenn beide laufen → Sheetstorm-OMR (schneller, neuere Engine)
//   3. Sonst: nur die laufende Engine
//   4. Sonst: Stub (kein Provider gesetzt)
string? activeProvider = (requestedEngine, omr is not null, audiveris is not null) switch
{
    ("audiveris", _, true) => "audiveris",
    ("audiveris", _, false) => null, // gewuenscht aber nicht da → fallback Stub
    ("sheetstorm", true, _) => "sheetstorm",
    ("sheetstorm", false, _) => null,
    ("stub", _, _) => null,
    (null, true, _) => "sheetstorm",
    (null, false, true) => "audiveris",
    _ => null,
};

if (activeProvider is not null)
{
    web = web.WithEnvironment("Omr__Provider", activeProvider);
    Console.WriteLine($"⚡ Web-Frontend nutzt OMR-Engine: {activeProvider.ToUpperInvariant()}");
}
else if (enableOmr || enableAudiveris)
{
    Console.WriteLine("⚠ OMR-Engine erwuenscht aber nicht verfuegbar — Web faellt auf Stub zurueck.");
}

builder.Build().Run();


// ─── Helpers ────────────────────────────────────────────────────────────

static void EnsureContainerImageBuilt(string subdir, string imageName)
{
    var dockerCtx = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", "docker", subdir));
    var dockerfilePath = System.IO.Path.Combine(dockerCtx, "Dockerfile");
    if (!System.IO.File.Exists(dockerfilePath))
    {
        Console.Error.WriteLine($"⚠ Dockerfile nicht gefunden: {dockerfilePath} — Container wird nicht gebaut.");
        return;
    }

    // Build-Kontext = Repo-Root (für Sheetstorm-OMR; Audiveris baut alles inline).
    // Wir nehmen den Repo-Root, der drei Ebenen über docker/ liegt.
    var repoRoot = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
    var hash = ComputeDirHash(dockerCtx, includeRepoSrc: subdir == "sheetstorm-omr" ? System.IO.Path.Combine(repoRoot, "src", "omr-rust") : null);
    var stampFile = System.IO.Path.Combine(dockerCtx, ".image-hash");
    var existingHash = System.IO.File.Exists(stampFile) ? System.IO.File.ReadAllText(stampFile).Trim() : "";

    var imageRef = $"{imageName}:dev";
    var imageExists = ImageExists(imageRef);
    if (imageExists && existingHash == hash)
    {
        Console.WriteLine($"✓ {imageRef} ist aktuell, ueberspringe Build.");
        return;
    }

    Console.WriteLine(imageExists
        ? $"🔨 {imageRef}: Quellen geaendert — baue neu …"
        : $"🔨 {imageRef}: Image fehlt — baue …");

    // Build-Kontext: für sheetstorm-omr brauchen wir den Repo-Root, sonst dockerCtx.
    var buildCtx = subdir == "sheetstorm-omr" ? repoRoot : dockerCtx;
    var dockerfileArg = subdir == "sheetstorm-omr"
        ? $"-f \"{System.IO.Path.Combine(dockerCtx, "Dockerfile")}\""
        : "";

    var psi = new System.Diagnostics.ProcessStartInfo(
        "docker",
        $"build -t {imageRef} {dockerfileArg} \"{buildCtx}\"")
    {
        RedirectStandardOutput = false,
        RedirectStandardError = false,
        UseShellExecute = false,
    };
    var p = System.Diagnostics.Process.Start(psi)!;
    p.WaitForExit();
    if (p.ExitCode != 0)
    {
        Console.Error.WriteLine($"❌ docker build fehlgeschlagen (Exit {p.ExitCode}). {imageRef} wird ggf. nicht starten.");
        return;
    }

    System.IO.File.WriteAllText(stampFile, hash);
    Console.WriteLine($"✓ {imageRef} gebaut.");
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

static string ComputeDirHash(string dir, string? includeRepoSrc = null)
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
    if (includeRepoSrc is not null && System.IO.Directory.Exists(includeRepoSrc))
    {
        foreach (var f in System.IO.Directory.GetFiles(includeRepoSrc, "*", System.IO.SearchOption.AllDirectories)
            .Where(p => !p.Contains(System.IO.Path.DirectorySeparatorChar + "target" + System.IO.Path.DirectorySeparatorChar))
            .OrderBy(f => f))
        {
            var rel = System.IO.Path.GetRelativePath(includeRepoSrc, f);
            sb.Append(rel);
            sb.Append('|');
            sb.Append(Convert.ToHexString(sha.ComputeHash(System.IO.File.ReadAllBytes(f))));
            sb.Append('\n');
        }
    }
    return Convert.ToHexString(sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(sb.ToString())));
}
