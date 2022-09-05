@description('The location where we will deploy our resources to. Default is the location of the resource group')
param location string = resourceGroup().location

@description('Name of our application.')
param applicationName string = uniqueString(resourceGroup().id)

@description('Name of the App Service Plan')
param appServicePlanName string = '${applicationName}-asp'

@description('Name of the App Service')
param appServiceName string = '${applicationName}-web'

@description('Name of the Redis Cache to deploy')
param redisCacheName string = '${applicationName}-redis'

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
    size: 'P1v3'
    family: 'Pv3'
    capacity: 3
  }
  kind: 'app'
  properties: {
    zoneRedundant: true
  }
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
  }
}

resource config 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'connectionstrings'
  parent: appService
  properties: {
    TeamContext: {
      value: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${database.name};User Id=${sqlServer.properties.administratorLogin};Password=${sqlServer.properties.administratorLoginPassword};'
      type: 'SQLServer'
    }
  }
}

resource appSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: appService
  properties: {
    CacheConnection: '${cache.name}.redis.cache.windows.net,abortConnect=false,ssl=true,password=${cache.listKeys().primaryKey}'
    minTlsVersion: '1.2'
    ftpsState: 'FtpsOnly' 
  }
}

resource cache 'Microsoft.Cache/redis@2021-06-01' = {
  name: redisCacheName
  location: location
  properties: {
    sku: {
      capacity: 3
      family: 'P'
      name: 'Premium'
    }
  }
  zones: [
    '3'
  ]
}

resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: '${applicationName}-sql'
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: 'P@ssw0rd123'
    version: '12.0'
  }
}

resource database 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  name: 'ContosoTeamsDatabase'
  parent: sqlServer
  location: location
  properties: {
  }
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource firewallRules 'Microsoft.Sql/servers/firewallRules@2022-02-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}
