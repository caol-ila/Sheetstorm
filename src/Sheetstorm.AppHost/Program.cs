using Sheetstorm.ServiceDefaults;

var builder = WebApplication.CreateBuilder(args);

// Add ServiceDefaults
builder.AddServiceDefaults();

var app = builder.Build();

// TODO: Replace with Aspire AppHost when SDK is installed:
// var builder = DistributedApplication.CreateBuilder(args);
// var postgres = builder.AddPostgres("postgres").WithDataVolume().AddDatabase("sheetstorm");
// var api = builder.AddProject<Projects.Sheetstorm_Api>("api").WithReference(postgres).WaitFor(postgres);
// builder.Build().Run();

app.MapGet("/", () => "Sheetstorm AppHost Placeholder - Install Aspire SDK for full functionality");

app.Run();
