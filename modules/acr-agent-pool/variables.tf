variable "container_registry_resource_id" {
  type        = string
  description = "The resource ID of the parent Premium Azure Container Registry. The agent pool is created as a child resource of this registry and must be in the same region."
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.ContainerRegistry/registries/[^/]+$", var.container_registry_resource_id))
    error_message = "container_registry_resource_id must be a valid ACR resource ID (/subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerRegistry/registries/...)."
  }
}

variable "location" {
  type        = string
  description = "Azure region where the agent pool should be deployed. Must match the region of the parent container registry."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the agent pool. Must be 3 to 20 alphanumeric characters."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{3,20}$", var.name))
    error_message = "name must be 3 to 20 alphanumeric characters."
  }
}

variable "virtual_network_subnet_resource_id" {
  type        = string
  description = "The resource ID of an existing subnet to join the agent pool to. The subnet must be in a VNet that can reach the ACR Private Endpoint. The consumer is responsible for creating and delegating the subnet (no AVM Res module provisions networking)."
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.virtual_network_subnet_resource_id))
    error_message = "virtual_network_subnet_resource_id must be a valid subnet resource ID."
  }
}

variable "count_instances" {
  type        = number
  default     = 1
  description = "Number of allocated instances. Set to 0 to scale to zero between jobs (manual via `az acr agentpool update --count 0`). Range 0 to 10."
  nullable    = false

  validation {
    condition     = var.count_instances >= 0 && var.count_instances <= 10
    error_message = "count_instances must be between 0 and 10."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'CanNotDelete' or 'ReadOnly'."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "tier" {
  type        = string
  default     = "S1"
  description = "Agent pool tier. S1 (2 vCPU, 3 GB), S2 (4 vCPU, 8 GB), S3 (8 vCPU, 16 GB), I6 isolated (64 vCPU, 216 GB)."
  nullable    = false

  validation {
    condition     = contains(["S1", "S2", "S3", "I6"], var.tier)
    error_message = "tier must be one of S1, S2, S3 or I6."
  }
}
