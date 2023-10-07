param location string = resourceGroup().location
param unique string = uniqueString(resourceGroup().id)

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'sestorage${unique}' 
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowBlobPublicAccess: false
  }

  resource fileServices 'fileServices@2023-01-01' = {
    name: 'default'
    
    resource share 'shares@2023-01-01'=  {
      name: 'vol'
      properties: {
        accessTier: 'Hot'
      }
    }
  }
}

output storageAccountName string = storageAccount.name
output azureFileShareName string = storageAccount::fileServices::share.name
