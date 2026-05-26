# avm-res-containerregistry-agentpool (preview)

Provisions a dedicated, VNet-joined Azure Container Registry agent pool (`Microsoft.ContainerRegistry/registries/agentPools`). This is the only validated path for running `az acr build` against an ACR with `publicNetworkAccess = Disabled`: the Microsoft-managed shared ACR Tasks pool has no path to the registry data plane when the public endpoint is fully disabled, because the `AzureServices` trusted-services bypass only relaxes the registry firewall ACL when public access is set to "Selected networks", not when it is disabled outright.

This module follows the [Azure Verified Modules Resource Module specification](https://azure.github.io/Azure-Verified-Modules/specs/tf/res/) and is a preview-tracked candidate for upstreaming as `terraform-azurerm-avm-res-containerregistry-agentpool`. Until then it lives in the [github-runners-alz-corp-cookbook](https://github.com/martinopedal/github-runners-alz-corp-cookbook) repo and is consumed via `git::` source.

> **The agent pool resource is in Azure public preview.** API version pinned to `2019-06-01-preview` via `azapi`. The module will be refactored to `azurerm_container_registry_agent_pool` if/when AzureRM ships first-class support.
