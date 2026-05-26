# Submodule: `acr-agent-pool`

Provisions a dedicated, VNet-joined ACR agent pool so workflows running on the private runners deployed by [`terraform-azurerm-github-runners-alz-corp`](https://github.com/martinopedal/terraform-azurerm-github-runners-alz-corp) can call `az acr build` against an ACR with `publicNetworkAccess = Disabled`.

This submodule lives in the cookbook (separate from the platform module) so customers using in-runner Buildah or any other build pattern pay no complexity tax. Wire it in only when you need it.

## What it creates

- One subnet in your existing VNet (default name `snet-acragent`, you choose the CIDR).
- One ACR agent pool (default `S1`, count `1`) joined to that subnet.

## What it does not create

- The VNet (you provide an existing one).
- RBAC on the ACR for the build identity (the root module's `runner_acr_push_enabled = true` handles AcrPush on the runner UAMI).

## Usage

```hcl
module "runners" {
  source = "github.com/martinopedal/terraform-azurerm-github-runners-alz-corp"

  # ... your existing inputs ...
  runner_acr_push_enabled = true
}

module "acr_agent_pool" {
  source = "github.com/martinopedal/github-runners-alz-corp-cookbook//modules/acr-agent-pool"

  container_registry_resource_id = module.runners.container_registry_resource_id
  virtual_network_resource_id    = azurerm_virtual_network.this.id
  location                       = "swedencentral"
  subnet_address_prefixes        = ["10.0.3.0/24"]
}
```

Then in your workflow:

```bash
az acr build \
  --registry ${{ vars.ACR_NAME }} \
  --agent-pool ${{ vars.ACR_AGENT_POOL }} \
  --image my-app:${{ github.sha }} \
  --file Dockerfile .
```

Workflow drop-in: [`container-build.yml`](https://github.com/martinopedal/github-runners-alz-corp-cookbook/blob/main/workflows/container-build.yml) in the companion cookbook.

## Cost

Dedicated agent pools are in **public preview** and billed per vCPU per second of instance allocation. With the default `count = 1` an S1 instance (2 vCPU) is allocated continuously. Scale-to-zero is supported by the service (`az acr agentpool update --count 0`) but is not automated by this submodule. Check the current rate on the [ACR pricing page](https://azure.microsoft.com/en-us/pricing/details/container-registry/) under "Dedicated agent pool billing" before committing to a tier.

Tiers: **S1** (2 vCPU, 3 GB), **S2** (4 vCPU, 8 GB), **S3** (8 vCPU, 16 GB), **I6** isolated (64 vCPU, 216 GB).

## Why this exists as a separate submodule

The platform module ships ACR with `publicNetworkAccess = Disabled`. When the registry's public endpoint is fully disabled, the Microsoft-managed shared ACR Tasks pool has no path to the registry data plane: the "allow trusted Azure services" bypass (`networkRuleBypassOptions = AzureServices`) only relaxes the firewall ACL when public access is set to "Selected networks", not when it is disabled outright. A dedicated VNet-joined agent pool resolving the registry through its Private Endpoint is the validated `az acr build` path against this posture.

This is shipped as a separate submodule in the cookbook (not as part of the platform module) so customers using in-runner Buildah or any other build pattern do not get an always-on agent pool they did not ask for.
