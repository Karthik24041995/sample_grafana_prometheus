// Main Bicep file for Prometheus + Grafana monitoring on AKS
// Deploys Azure Kubernetes Service with sample app, Prometheus, and Grafana

targetScope = 'resourceGroup'

// Parameters
@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, test, prod)')
@maxLength(10)
param environmentName string = 'dev'

@description('Base name for all resources')
@maxLength(20)
param baseName string = 'promlearn'

@description('Kubernetes version')
param kubernetesVersion string = '1.31'

@description('Node count for AKS')
@minValue(1)
@maxValue(5)
param nodeCount int = 2

@description('VM size for AKS nodes')
param vmSize string = 'Standard_B2s'

// Variables
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, location))
var shortToken = substring(resourceToken, 0, 6)
var tags = {
  Environment: environmentName
  Project: 'Prometheus-Learning'
  ManagedBy: 'Bicep'
}

// Log Analytics Workspace for AKS
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'log-analytics-deployment'
  params: {
    name: '${baseName}-logs-${shortToken}'
    location: location
    tags: tags
  }
}

// Azure Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'container-registry-deployment'
  params: {
    name: '${baseName}acr${shortToken}'
    location: location
    tags: tags
  }
}

// AKS Cluster
module aksCluster 'modules/aks-cluster.bicep' = {
  name: 'aks-cluster-deployment'
  params: {
    name: '${baseName}-aks-${shortToken}'
    location: location
    kubernetesVersion: kubernetesVersion
    nodeCount: nodeCount
    vmSize: vmSize
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

// Grant AKS permission to pull from ACR
module acrRoleAssignment 'modules/acr-role-assignment.bicep' = {
  name: 'acr-role-assignment'
  params: {
    acrName: containerRegistry.outputs.name
    aksPrincipalId: aksCluster.outputs.principalId
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output location string = location
output acrName string = containerRegistry.outputs.name
output acrLoginServer string = containerRegistry.outputs.loginServer
output aksClusterName string = aksCluster.outputs.name
output aksFqdn string = aksCluster.outputs.fqdn
output aksResourceId string = aksCluster.outputs.id
output logAnalyticsWorkspaceId string = logAnalytics.outputs.id
