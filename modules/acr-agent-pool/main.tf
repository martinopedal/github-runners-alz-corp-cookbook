resource "azapi_resource" "this" {
  type      = "Microsoft.ContainerRegistry/registries/agentPools@2019-06-01-preview"
  name      = var.name
  location  = var.location
  parent_id = var.container_registry_resource_id
  tags      = var.tags

  body = {
    properties = {
      count                          = var.count_instances
      tier                           = var.tier
      os                             = "Linux"
      virtualNetworkSubnetResourceId = var.virtual_network_subnet_resource_id
    }
  }

  response_export_values = ["id", "name", "properties.provisioningState"]
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}
