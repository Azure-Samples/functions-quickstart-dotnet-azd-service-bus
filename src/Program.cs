using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Azure.Monitor.OpenTelemetry.Exporter;
using Microsoft.Azure.Functions.Worker.OpenTelemetry;
using OpenTelemetry;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services => {
#if DEBUG
        if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING")))
        {
            services.AddOpenTelemetry()
                .UseFunctionsWorkerDefaults()
                .UseAzureMonitorExporter();
        }
#else
        services.AddOpenTelemetry()
            .UseFunctionsWorkerDefaults()
            .UseAzureMonitorExporter();
#endif
    })
    .Build();

host.Run();