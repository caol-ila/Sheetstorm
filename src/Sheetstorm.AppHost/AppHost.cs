var builder = DistributedApplication.CreateBuilder(args);

var postgres = builder.AddPostgres("postgres")
    .WithPgAdmin()
    .WithDataVolume();

var sheetstormDb = postgres.AddDatabase("sheetstormdb");

var mailhog = builder.AddContainer("mailhog", "mailhog/mailhog")
    .WithEndpoint(port: 1025, targetPort: 1025, name: "smtp")
    .WithEndpoint(port: 8025, targetPort: 8025, name: "ui", scheme: "http");

// Audiveris-Sidecar: Container wird aus docker/audiveris/Dockerfile gebaut.
// Aktivieren mit: dotnet run --project src/Sheetstorm.AppHost -- --enable-audiveris
// (Erst-Build des Containers dauert mehrere Minuten und braucht ~1 GB Speicher.)
var enableAudiveris = args.Contains("--enable-audiveris")
    || string.Equals(Environment.GetEnvironmentVariable("SHEETSTORM_ENABLE_AUDIVERIS"), "true", StringComparison.OrdinalIgnoreCase);

IResourceBuilder<ContainerResource>? audiveris = null;
if (enableAudiveris)
{
    audiveris = builder.AddContainer("audiveris", "sheetstorm-audiveris")
        .WithDockerfile("../../docker/audiveris")
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
