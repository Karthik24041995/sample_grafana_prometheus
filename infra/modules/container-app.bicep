// Container App module
// Deploys a single container application

@description('Name of the Container App')
param name string

@description('Location for the Container App')
param location string

@description('Container Apps Environment resource ID')
param containerAppsEnvironmentId string

@description('Container image to deploy')
param containerImage string

@description('Container port')
param containerPort int

@description('Target port for ingress')
param targetPort int

@description('Whether the app is externally accessible')
param external bool = true

@description('Minimum number of replicas')
param minReplicas int = 1

@description('Maximum number of replicas')
param maxReplicas int = 3

@description('Resource tags')
param tags object = {}

@description('Environment variables')
param env array = []

@description('Secrets for the container app')
param secrets array = []

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      ingress: {
        external: external
        targetPort: targetPort
        transport: 'http'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      secrets: secrets
    }
    template: {
      containers: [
        {
          name: name
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: env
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

output id string = containerApp.id
output name string = containerApp.name
output fqdn string = containerApp.properties.configuration.ingress.fqdn
output latestRevisionName string = containerApp.properties.latestRevisionName
