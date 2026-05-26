locals {
  vnet_parts = split("/", var.virtual_network_resource_id)
  vnet_rg    = local.vnet_parts[4]
  vnet_name  = local.vnet_parts[length(local.vnet_parts) - 1]
}

resource "azurerm_subnet" "agent_pool" {
  name                              = var.subnet_name
  resource_group_name               = local.vnet_rg
  virtual_network_name              = local.vnet_name
  address_prefixes                  = var.subnet_address_prefixes
  private_endpoint_network_policies = "Disabled"
}

resource "azapi_resource" "agent_pool" {
  type      = "Microsoft.ContainerRegistry/registries/agentPools@2019-06-01-preview"
  name      = var.agent_pool_name
  location  = var.location
  parent_id = var.container_registry_resource_id

  body = {
    properties = {
      count                          = var.agent_pool_count
      tier                           = var.agent_pool_tier
      os                             = "Linux"
      virtualNetworkSubnetResourceId = azurerm_subnet.agent_pool.id
    }
  }

  tags = var.tags

  response_export_values = ["properties.provisioningState"]
}
