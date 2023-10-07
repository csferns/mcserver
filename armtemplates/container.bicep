param storageAccountName string
param azureFileShareName string
param networkProfileId string

param containerRegistryName string = 'acrminecraft${unique}'
param location string = resourceGroup().location
param unique string = uniqueString(resourceGroup().id)

@description('The number of CPU cores to allocate to the container.')
param cpuCores int = 2

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int = 6

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource containerApp 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: 'aci-container-group'
  location: location
  // identity: {
  //   type: 'UserAssigned'
  //   userAssignedIdentities: {
  //     '${identity.id}': {}
  //   }
  // }
  properties: {
    imageRegistryCredentials: [
      {
        server: containerRegistry.properties.loginServer
        identity: identity.name
      }
    ] 
    containers: [
      {
        name: 'server'

        properties: {
          image: '${containerRegistry.name}.azurecr.io/samples/mcserver:latest'
          ports: [
            {
              port: 25565
              protocol: 'TCP,UDP'
            }
            // {
            //   port: 25565
            //   protocol: 'UDP'
            // }
          ]
          volumeMounts: [
            {
              name: 'filesharevolume'
              mountPath: '/minecraft'
              readOnly: false
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
    ]
    osType: 'Linux'
    subnetIds: [
      {
        id: networkProfileId
      }
    ]
    restartPolicy: 'Always'
    ipAddress: {
      type: 'Private'
      ports: [
        {
          port: 25565
          protocol: 'TCP,UDP'
        }
        // {
        //   port: 25565
        //   protocol: 'UDP'
        // }
      ]
    }
    volumes: [
      {
        name: 'filesharevolume'
        azureFile: {
          readOnly: false
          shareName: azureFileShareName
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
    ]
  }
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'aci-minecraft-identity'
  location: location 
}


// roleDefinitionId is the ID found here for AcrPull: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, containerRegistry.name, 'AcrPullSystemAssigned')
  scope: containerApp
  properties: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}
