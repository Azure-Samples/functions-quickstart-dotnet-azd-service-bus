$ErrorActionPreference = "Stop"

Write-Host "Running post-provision script..." -ForegroundColor Yellow

# Get the outputs from the deployment
$outputs = azd env get-values --output json | ConvertFrom-Json
$ServiceBusNamespace = $outputs.SERVICE_BUS_CONNECTION__fullyQualifiedNamespace
$ServiceBusQueueName = $outputs.SERVICE_BUS_QUEUE_NAME

if (-not $ServiceBusNamespace -or -not $ServiceBusQueueName) {
    throw "SERVICE_BUS_CONNECTION__fullyQualifiedNamespace or SERVICE_BUS_QUEUE_NAME is missing from the azd environment."
}

$settingsPath = ".\src\local.settings.json"
if (Test-Path $settingsPath) {
    # Never overwrite an existing local.settings.json; it may contain your own values.
    $existing = Get-Content $settingsPath -Raw
    if ($existing -notmatch [regex]::Escape($ServiceBusNamespace) -or $existing -notmatch [regex]::Escape($ServiceBusQueueName)) {
        Write-Host "src/local.settings.json already exists and was not changed. Update these values in it to use the provisioned resources:" -ForegroundColor Yellow
        Write-Host "  ServiceBusConnection__fullyQualifiedNamespace = $ServiceBusNamespace" -ForegroundColor Cyan
        Write-Host "  ServiceBusQueueName = $ServiceBusQueueName" -ForegroundColor Cyan
    }
    else {
        Write-Host "src/local.settings.json already exists and references the provisioned resources." -ForegroundColor Green
    }
}
else {
    Write-Host "Creating src/local.settings.json..." -ForegroundColor Yellow
    @{
        "IsEncrypted" = $false
        "Values" = @{
            "AzureWebJobsStorage" = "UseDevelopmentStorage=true"
            "FUNCTIONS_WORKER_RUNTIME" = "dotnet-isolated"
            "ServiceBusConnection__fullyQualifiedNamespace" = "$ServiceBusNamespace"
            "ServiceBusQueueName" = "$ServiceBusQueueName"
        }
    } | ConvertTo-Json | Out-File -FilePath $settingsPath -Encoding ascii
    Write-Host "src/local.settings.json has been created successfully!" -ForegroundColor Green
}

Write-Host "Creating/updating send-message.ps1..." -ForegroundColor Yellow

"az rest --method POST --uri 'https://$ServiceBusNamespace/$ServiceBusQueueName/messages' --headers 'Content-Type=application/atom+xml;type=entry;charset=utf-8' --body 'Hello from the CLI' --resource 'https://servicebus.azure.net'" | Out-File -FilePath ".\send-message.ps1" -Encoding ascii -Force

Write-Host "send-message.ps1 has been created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Service Bus Namespace: $ServiceBusNamespace" -ForegroundColor Cyan
Write-Host "Service Bus Queue: $ServiceBusQueueName" -ForegroundColor Cyan
Write-Host ""
Write-Host "Running locally and sending test messages from your machine require VNET_ENABLED=false." -ForegroundColor Yellow
Write-Host "You can now run the function locally with 'cd src && func start'" -ForegroundColor Green
Write-Host "Send test messages with './send-message.ps1'" -ForegroundColor Green
