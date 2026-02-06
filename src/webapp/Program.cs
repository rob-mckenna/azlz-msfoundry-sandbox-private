using System.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddHealthChecks();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
app.UseCors();

// Health check endpoints
app.MapHealthChecks("/health");
app.MapHealthChecks("/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = _ => true
});

// API endpoints
app.MapGet("/", GetInfo)
    .WithName("GetInfo")
    .WithOpenApi()
    .WithDescription("Get application information");

app.MapGet("/api/info", GetApiInfo)
    .WithName("GetApiInfo")
    .WithOpenApi()
    .WithDescription("Get detailed API information");

app.MapGet("/api/environment", GetEnvironment)
    .WithName("GetEnvironment")
    .WithOpenApi()
    .WithDescription("Get environment information");

app.MapPost("/api/echo", PostEcho)
    .WithName("PostEcho")
    .WithOpenApi()
    .WithDescription("Echo back the request body");

app.Run();

// Endpoint Handlers
static IResult GetInfo()
{
    return Results.Ok(new
    {
        application = "Azure Landing Zone - Minimal API",
        version = "1.0.0",
        status = "healthy",
        timestamp = DateTime.UtcNow,
        environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "unknown",
        hostname = Environment.MachineName
    });
}

static IResult GetApiInfo()
{
    var uptime = TimeSpan.FromMilliseconds(Environment.TickCount);
    return Results.Ok(new
    {
        application = "AZLZ Web App",
        version = "1.0.0",
        dotnetVersion = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
        osDescription = System.Runtime.InteropServices.RuntimeInformation.OSDescription,
        processorCount = Environment.ProcessorCount,
        uptime = uptime.ToString(@"hh\:mm\:ss"),
        timestamp = DateTime.UtcNow
    });
}

static IResult GetEnvironment()
{
    return Results.Ok(new
    {
        aspnetcoreEnvironment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT"),
        aspnetcoreUrls = Environment.GetEnvironmentVariable("ASPNETCORE_URLS"),
        computeArchitecture = System.Runtime.InteropServices.RuntimeInformation.ProcessArchitecture,
        userDomainName = Environment.UserDomainName,
        timestamp = DateTime.UtcNow
    });
}

static IResult PostEcho(EchoRequest request)
{
    return Results.Ok(new
    {
        echo = request.Message,
        timestamp = DateTime.UtcNow,
        receivedAt = DateTime.UtcNow
    });
}

record EchoRequest(string Message);
