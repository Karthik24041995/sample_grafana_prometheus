# Azure Kubernetes Service (AKS) Deployment Script
# This script deploys the Prometheus monitoring stack to AKS

param(
    [string]$ResourceGroupName = "rg-prometheus-aks",
    [string]$Location = "westus",
    [string]$ClusterName = "promlearn-aks"
)

$ErrorActionPreference = "Stop"

Write-Host "[INFO] Starting AKS deployment for Prometheus Learning..."
Write-Host "[INFO] Resource Group: $ResourceGroupName"
Write-Host "[INFO] Location: $Location"

# Check if Azure CLI is installed
Write-Host "[INFO] Checking Azure CLI installation..."
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "[OK] Azure CLI version: $($azVersion.'azure-cli')"
} catch {
    Write-Host "[ERROR] Azure CLI not found. Please install from: https://aka.ms/installazurecliwindows"
    exit 1
}

# Check if kubectl is installed
Write-Host "[INFO] Checking kubectl installation..."
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Host "[OK] kubectl installed: $kubectlVersion"
} catch {
    Write-Host "[WARNING] kubectl not found. Will be installed during 'az aks get-credentials'"
    Write-Host "[INFO] You can manually install from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
}

# Check if logged in to Azure
Write-Host "[INFO] Checking Azure login status..."
$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "[ERROR] Not logged in to Azure. Running 'az login'..."
    az login
    $account = az account show --output json | ConvertFrom-Json
}
Write-Host "[OK] Logged in as: $($account.user.name)"
Write-Host "[OK] Subscription: $($account.name) ($($account.id))"

# Create resource group if it doesn't exist
Write-Host "[INFO] Creating resource group..."
az group create --name $ResourceGroupName --location $Location --output none
Write-Host "[OK] Resource group created/verified"

# Validate Bicep template
Write-Host "[INFO] Validating Bicep template..."
$ErrorActionPreference = "Continue"
az deployment group validate `
    --resource-group $ResourceGroupName `
    --template-file "infra/main-aks.bicep" `
    --output json | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Bicep validation failed"
    exit 1
}
$ErrorActionPreference = "Stop"
Write-Host "[OK] Bicep template is valid"

# Deploy infrastructure
Write-Host "[INFO] Deploying AKS infrastructure (this may take 10-15 minutes)..."
$deploymentName = "aks-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"
$startTime = Get-Date

$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --template-file "infra/main-aks.bicep" `
    --output json | ConvertFrom-Json

$endTime = Get-Date
$duration = $endTime - $startTime

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Deployment failed"
    exit 1
}

Write-Host "[OK] Infrastructure deployed (Duration: $($duration.ToString('mm\:ss')))"

# Extract outputs
$aksClusterName = $deployment.properties.outputs.aksClusterName.value
$acrName = $deployment.properties.outputs.acrName.value
$acrLoginServer = $deployment.properties.outputs.acrLoginServer.value

Write-Host "[INFO] AKS Cluster: $aksClusterName"
Write-Host "[INFO] ACR: $acrName"
Write-Host "[INFO] ACR Login Server: $acrLoginServer"

# Get AKS credentials
Write-Host "[INFO] Getting AKS credentials..."
az aks get-credentials --resource-group $ResourceGroupName --name $aksClusterName --overwrite-existing
Write-Host "[OK] kubectl configured for AKS cluster"

# Verify cluster connectivity
Write-Host "[INFO] Verifying cluster connectivity..."
$nodes = kubectl get nodes --output json | ConvertFrom-Json
Write-Host "[OK] Connected to cluster with $($nodes.items.Count) node(s)"

# Build and push Docker image to ACR
Write-Host "[INFO] Building and pushing sample app to ACR..."
az acr build --registry $acrName --image sample-app:latest --file Dockerfile . --output table

# Update Kubernetes manifests with ACR name
Write-Host "[INFO] Updating Kubernetes manifests with ACR name..."
$manifestContent = Get-Content "k8s\sample-app.yaml" -Raw
$manifestContent = $manifestContent -replace "REGISTRY_NAME", $acrName
$manifestContent | Set-Content "k8s\sample-app.yaml" -NoNewline

# Apply Kubernetes manifests
Write-Host "[INFO] Deploying applications to AKS..."
kubectl apply -f k8s/namespace.yaml
Write-Host "[OK] Namespace created"

kubectl apply -f k8s/prometheus.yaml
Write-Host "[OK] Prometheus deployed"

kubectl apply -f k8s/sample-app.yaml
Write-Host "[OK] Sample app deployed"

kubectl apply -f k8s/grafana.yaml
Write-Host "[OK] Grafana deployed"

# Wait for services to get external IPs
Write-Host "[INFO] Waiting for LoadBalancer services to get external IPs (this may take a few minutes)..."
Start-Sleep -Seconds 30

$maxAttempts = 20
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "[INFO] Attempt $attempt/$maxAttempts - Checking service status..."
    
    $services = kubectl get services -n monitoring --output json | ConvertFrom-Json
    
    $sampleAppIP = ($services.items | Where-Object { $_.metadata.name -eq "sample-app" }).status.loadBalancer.ingress[0].ip
    $prometheusIP = ($services.items | Where-Object { $_.metadata.name -eq "prometheus" }).status.loadBalancer.ingress[0].ip
    $grafanaIP = ($services.items | Where-Object { $_.metadata.name -eq "grafana" }).status.loadBalancer.ingress[0].ip
    
    if ($sampleAppIP -and $prometheusIP -and $grafanaIP) {
        Write-Host "[OK] All services have external IPs"
        break
    }
    
    if ($attempt -lt $maxAttempts) {
        Start-Sleep -Seconds 15
    }
}

# Display deployment information
Write-Host ""
Write-Host "============================================"
Write-Host "DEPLOYMENT COMPLETE"
Write-Host "============================================"
Write-Host ""
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "AKS Cluster: $aksClusterName"
Write-Host "ACR: $acrName"
Write-Host ""
Write-Host "Application URLs:"
Write-Host "  Sample App:  http://${sampleAppIP}"
Write-Host "  Prometheus:  http://${prometheusIP}:9090"
Write-Host "  Grafana:     http://${grafanaIP}"
Write-Host ""
Write-Host "Grafana Credentials:"
Write-Host "  Username: admin"
Write-Host "  Password: TestPassword123!"
Write-Host ""
Write-Host "Useful Commands:"
Write-Host "  kubectl get pods -n monitoring"
Write-Host "  kubectl logs -n monitoring <pod-name>"
Write-Host "  kubectl get services -n monitoring"
Write-Host "  az aks browse --resource-group $ResourceGroupName --name $aksClusterName"
Write-Host ""
Write-Host "[OK] Deployment successful!"
