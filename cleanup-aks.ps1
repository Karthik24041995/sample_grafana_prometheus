# Azure AKS Cleanup Script
# This script removes all AKS resources

param(
    [string]$ResourceGroupName = "rg-prometheus-aks",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "[INFO] Azure AKS Cleanup Script"
Write-Host "[INFO] Resource Group: $ResourceGroupName"
Write-Host ""

# Check if resource group exists
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "[INFO] Resource group '$ResourceGroupName' does not exist. Nothing to clean up."
    exit 0
}

# Confirmation prompt unless -Force is specified
if (-not $Force) {
    Write-Host "[WARNING] This will delete the following resources:"
    Write-Host "  - AKS Cluster"
    Write-Host "  - Azure Container Registry"
    Write-Host "  - Log Analytics Workspace"
    Write-Host "  - All associated resources"
    Write-Host ""
    $confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "[INFO] Cleanup cancelled by user"
        exit 0
    }
}

# Delete resource group
Write-Host "[INFO] Deleting resource group '$ResourceGroupName'..."
az group delete --name $ResourceGroupName --yes --no-wait

Write-Host "[OK] Deletion initiated. Resources will be removed in the background."
Write-Host "[INFO] You can check status with: az group show --name $ResourceGroupName"
