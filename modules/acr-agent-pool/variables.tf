variable "container_registry_resource_id" {
  type        = string
  description = "Resource ID of the existing Premium ACR to attach the agent pool to. When chained with the root module, pass `module.<name>.container_registry_resource_id`."

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.ContainerRegistry/registries/[^/]+$", var.container_registry_resource_id))
    error_message = "container_registry_resource_id must be a valid ACR resource ID."
  }
}

variable "virtual_network_resource_id" {
  type        = string
  description = "Resource ID of the existing VNet that hosts the ACR Private Endpoint. The agent pool subnet is created in this VNet."

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.virtual_network_resource_id))
    error_message = "virtual_network_resource_id must be a valid VNet resource ID."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the agent pool. Must match the VNet's region."
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet to create for the agent pool."
  default     = "snet-acragent"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the agent pool subnet. Must not overlap with other subnets in the VNet."
}

variable "agent_pool_name" {
  type        = string
  description = "Name of the ACR agent pool."
  default     = "vnetpool"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{3,20}$", var.agent_pool_name))
    error_message = "Agent pool name must be 3-20 alphanumeric characters."
  }
}

variable "agent_pool_tier" {
  type        = string
  description = "ACR agent pool tier. S1 = 2 vCPU / 3 GiB (around USD 0.02/hr per instance). S2 = 4 vCPU / 8 GiB. S3 = 8 vCPU / 16 GiB. I6 = isolated."
  default     = "S1"

  validation {
    condition     = contains(["S1", "S2", "S3", "I6"], var.agent_pool_tier)
    error_message = "agent_pool_tier must be one of S1, S2, S3, I6."
  }
}

variable "agent_pool_count" {
  type        = number
  description = "Number of always-on instances. ACR agent pools do not scale to zero, so cost = tier * count * uptime."
  default     = 1

  validation {
    condition     = var.agent_pool_count >= 1 && var.agent_pool_count <= 10
    error_message = "agent_pool_count must be between 1 and 10."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the subnet and agent pool."
  default     = null
}
