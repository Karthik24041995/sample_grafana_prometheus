// AKS to ACR role assignment module
// Grants AKS the ability to pull images from ACR

@description('Name of the ACR')
param acrName string

@description('Principal ID of the AKS managed identity')
param aksPrincipalId string

// Reference existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// AcrPull role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Grant AcrPull role to AKS managed identity
resource aksAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, aksPrincipalId, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: aksPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = aksAcrPull.id
