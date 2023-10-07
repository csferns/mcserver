param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-aci-minecraft'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }

  resource subnet 'subnets@2023-05-01' = {
    name: 'vnet-subnet-aci-minecraft'
    properties: {
      addressPrefix: '10.0.0.0/24'
      delegations: [
        {
          name: 'DelegationService'
          properties: {
            serviceName: 'Microsoft.ContainerInstance/containerGroups'
          }
        }
      ]
    }
  }
}

resource networkProfile 'Microsoft.Network/networkProfiles@2023-05-01' = {
  name: 'vnet-profile-aci-minecraft'
  location: location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: 'eth0'
        properties: {
          ipConfigurations: [
            {
              name: 'ipconfigprofile1'
              properties: {
                subnet: {
                  id: vnet::subnet.id
                }
              }
            }
          ]
        }
      }
    ]
  }
}

output networkProfileId string = networkProfile.id
