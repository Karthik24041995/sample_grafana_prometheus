// AKS Cluster module
// Deploys Azure Kubernetes Service cluster

@description('Name of the AKS cluster')
param name string

@description('Location for the cluster')
param location string

@description('Kubernetes version')
param kubernetesVersion string

@description('Number of nodes')
param nodeCount int

@description('VM size for nodes')
param vmSize string

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object = {}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${name}-dns'
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: nodeCount
        vmSize: vmSize
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: false
        type: 'VirtualMachineScaleSets'
      }
    ]
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'standard'
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
    }
  }
}

output id string = aksCluster.id
output name string = aksCluster.name
output fqdn string = aksCluster.properties.fqdn
output principalId string = aksCluster.identity.principalId
