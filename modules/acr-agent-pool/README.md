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

S1 is always-on (no scale-to-zero), roughly USD 0.02/hr per instance. With the default `count = 1` that is around USD 15/month. S2 is roughly USD 0.04/hr.

## Why this exists as a separate submodule

The platform module ships ACR with `publicNetworkAccess = Disabled`. The Microsoft-managed shared ACR Tasks pool is rejected at the registry data plane even with `networkRuleBypassAllowedForTasks = true` set on the registry (verified May 2026). A dedicated VNet-joined agent pool is the only validated `az acr build` path against this posture.

This is shipped as a separate submodule in the cookbook (not as part of the platform module) so customers using in-runner Buildah or any other build pattern do not get an always-on agent pool they did not ask for.
