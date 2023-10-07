param location string = resourceGroup().location
param unique string = uniqueString(resourceGroup().id)

module storage 'storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    unique: unique
  }
}

module network 'network.bicep' = {
  name: 'network'
  params: {
    location: location
  }
}

module container  'container.bicep' = {
  name: 'container'
  params: {
    azureFileShareName: storage.outputs.azureFileShareName
    storageAccountName: storage.outputs.storageAccountName
    networkProfileId: network.outputs.networkProfileId
    location: location
    unique: unique
  }
}
