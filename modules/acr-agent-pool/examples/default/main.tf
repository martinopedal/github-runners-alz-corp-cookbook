terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "this" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-avm-res-acragentpool-${random_string.this.result}"
  location = "swedencentral"
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${random_string.this.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "agent_pool" {
  name                              = "snet-acragent"
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = ["10.0.3.0/24"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_container_registry" "this" {
  name                          = "acr${random_string.this.result}example"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  sku                           = "Premium"
  public_network_access_enabled = false
}

module "acr_agent_pool" {
  source = "../.."

  name                               = "vnetpool"
  location                           = azurerm_resource_group.this.location
  container_registry_resource_id     = azurerm_container_registry.this.id
  virtual_network_subnet_resource_id = azurerm_subnet.agent_pool.id

  tags = {
    example = "default"
  }
}

output "agent_pool_name" {
  value = module.acr_agent_pool.name
}

output "agent_pool_resource_id" {
  value = module.acr_agent_pool.resource_id
}
