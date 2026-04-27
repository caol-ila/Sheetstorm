var builder = DistributedApplication.CreateBuilder(args);

var postgres = builder.AddPostgres("postgres")
    .WithPgAdmin()
    .WithDataVolume();

var sheetstormDb = postgres.AddDatabase("sheetstormdb");

var mailhog = builder.AddContainer("mailhog", "mailhog/mailhog")
    .WithEndpoint(port: 1025, targetPort: 1025, name: "smtp")
    .WithEndpoint(port: 8025, targetPort: 8025, name: "ui", scheme: "http");

var apiService = builder.AddProject<Projects.Sheetstorm_ApiService>("apiservice")
    .WithHttpHealthCheck("/health")
    .WithReference(sheetstormDb)
    .WaitFor(sheetstormDb);

builder.AddProject<Projects.Sheetstorm_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithHttpHealthCheck("/health")
    .WithReference(apiService)
    .WithReference(sheetstormDb)
    .WithEnvironment("Smtp__Host", mailhog.GetEndpoint("smtp").Property(Aspire.Hosting.ApplicationModel.EndpointProperty.Host))
    .WithEnvironment("Smtp__Port", mailhog.GetEndpoint("smtp").Property(Aspire.Hosting.ApplicationModel.EndpointProperty.Port))
    .WaitFor(apiService)
    .WaitFor(sheetstormDb);

builder.Build().Run();
