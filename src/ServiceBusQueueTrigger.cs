using System;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace ServiceBusProcessor
{
    public class ServiceBusQueueTrigger
    {
        private readonly ILogger<ServiceBusQueueTrigger> _logger;

        public ServiceBusQueueTrigger(ILogger<ServiceBusQueueTrigger> logger)
        {
            _logger = logger;
        }

        [Function("ServiceBusQueueTrigger")]
        public async Task Run([ServiceBusTrigger("%ServiceBusQueueName%", Connection = "ServiceBusConnection")] 
            string messageBody, FunctionContext context)
        {
            _logger.LogInformation("C# ServiceBus Queue trigger start processing a message: {messageBody}", messageBody);
            
            // Simulate processing time with a 30-second delay to demonstrate scaling behavior
            await Task.Delay(TimeSpan.FromSeconds(30));
            
            _logger.LogInformation("C# ServiceBus Queue trigger end processing a message");
        }
    }
}