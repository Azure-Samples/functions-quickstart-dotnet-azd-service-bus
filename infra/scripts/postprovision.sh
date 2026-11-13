#!/bin/bash
set -e

echo "Running post-provision script..."

# Get the outputs from the deployment
output=$(azd env get-values)

# Parse outputs
while IFS= read -r line; do
    if [[ $line == SERVICE_BUS_CONNECTION__fullyQualifiedNamespace=* ]]; then
        ServiceBusNamespace=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    elif [[ $line == SERVICE_BUS_QUEUE_NAME=* ]]; then
        ServiceBusQueueName=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    fi
done <<< "$output"

if [ -z "$ServiceBusNamespace" ] || [ -z "$ServiceBusQueueName" ]; then
    echo "SERVICE_BUS_CONNECTION__fullyQualifiedNamespace or SERVICE_BUS_QUEUE_NAME is missing from the azd environment." >&2
    exit 1
fi

settingsPath=./src/local.settings.json
if [ -f "$settingsPath" ]; then
    # Never overwrite an existing local.settings.json; it may contain your own values.
    if grep -qF "$ServiceBusNamespace" "$settingsPath" && grep -qF "$ServiceBusQueueName" "$settingsPath"; then
        echo "src/local.settings.json already exists and references the provisioned resources."
    else
        echo "src/local.settings.json already exists and was not changed. Update these values in it to use the provisioned resources:"
        echo "  ServiceBusConnection__fullyQualifiedNamespace = $ServiceBusNamespace"
        echo "  ServiceBusQueueName = $ServiceBusQueueName"
    fi
else
    echo "Creating src/local.settings.json..."
    cat > "$settingsPath" << EOF
{
    "IsEncrypted": false,
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
        "ServiceBusConnection__fullyQualifiedNamespace": "$ServiceBusNamespace",
        "ServiceBusQueueName": "$ServiceBusQueueName"
    }
}
EOF
    echo "src/local.settings.json has been created successfully!"
fi

echo "Creating/updating send-message.sh..."

echo "az rest --method POST --uri \"https://$ServiceBusNamespace/$ServiceBusQueueName/messages\" --headers \"Content-Type=application/atom+xml;type=entry;charset=utf-8\" --body \"Hello from the CLI\" --resource \"https://servicebus.azure.net\"" > ./send-message.sh
chmod +x ./send-message.sh

echo "send-message.sh has been created successfully!"
echo ""
echo "Service Bus Namespace: $ServiceBusNamespace"
echo "Service Bus Queue: $ServiceBusQueueName"
echo ""
echo "Running locally and sending test messages from your machine require VNET_ENABLED=false."
echo "You can now run the function locally with 'cd src && func start'"
echo "Send test messages with './send-message.sh'"
