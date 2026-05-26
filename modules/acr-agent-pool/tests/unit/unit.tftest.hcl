variables {
  container_registry_resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/acrtest"
  virtual_network_subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
  location                           = "swedencentral"
  name                               = "vnetpool"
  enable_telemetry                   = false
}

provider "azurerm" {
  features {}
}

run "valid_inputs" {
  command = plan

  assert {
    condition     = azapi_resource.this.type == "Microsoft.ContainerRegistry/registries/agentPools@2019-06-01-preview"
    error_message = "Wrong azapi resource type."
  }

  assert {
    condition     = azapi_resource.this.parent_id == var.container_registry_resource_id
    error_message = "parent_id must equal container_registry_resource_id."
  }

  assert {
    condition     = azapi_resource.this.body.properties.virtualNetworkSubnetResourceId == var.virtual_network_subnet_resource_id
    error_message = "Subnet ID not propagated to agent pool body."
  }

  assert {
    condition     = azapi_resource.this.body.properties.os == "Linux"
    error_message = "Agent pool OS must be Linux."
  }
}

run "invalid_acr_id_rejected" {
  command = plan

  variables {
    container_registry_resource_id = "not-a-resource-id"
  }

  expect_failures = [
    var.container_registry_resource_id,
  ]
}

run "invalid_subnet_id_rejected" {
  command = plan

  variables {
    virtual_network_subnet_resource_id = "/subscriptions/x/resourceGroups/y/providers/Microsoft.Storage/storageAccounts/z"
  }

  expect_failures = [
    var.virtual_network_subnet_resource_id,
  ]
}

run "invalid_tier_rejected" {
  command = plan

  variables {
    tier = "S5"
  }

  expect_failures = [
    var.tier,
  ]
}

run "invalid_count_rejected" {
  command = plan

  variables {
    count_instances = 99
  }

  expect_failures = [
    var.count_instances,
  ]
}
