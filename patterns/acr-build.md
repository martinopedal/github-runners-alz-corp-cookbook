# Building images against the private ACR

The container registry created by [`terraform-azurerm-github-runners-alz-corp`](https://github.com/martinopedal/terraform-azurerm-github-runners-alz-corp) has `publicNetworkAccess = Disabled` and is reachable only via the Private Endpoint inside your VNet. The Microsoft-managed shared ACR Tasks pool runs outside your VNet and is blocked at the data plane even when `networkRuleBypassAllowedForTasks = true` is set on the registry (verified end-to-end as of May 2026: the agent's `docker login` is rejected with `client with IP '...' is not allowed access`).

There are two supported ways to build images and push them to the registry from a workflow.

## Option 1 (recommended): `az acr build` via a dedicated VNet-joined ACR agent pool

Provision an ACR agent pool joined to a subnet in the same VNet as the registry, then pass `--agent-pool` to `az acr build`. The build runs inside your VNet, reaches the registry over the Private Endpoint, and authenticates as the runner UAMI.

```bash
az network vnet subnet create -g <rg> --vnet-name <vnet> -n snet-acragent \
  --address-prefixes 10.0.3.0/24 --private-endpoint-network-policies Disabled

SUBNET_ID=$(az network vnet subnet show -g <rg> --vnet-name <vnet> -n snet-acragent --query id -o tsv)

az acr agentpool create --registry <acr> --resource-group <rg> \
  --name vnetpool --tier S1 --count 1 --subnet-id "$SUBNET_ID"
```

Then in your workflow:

```bash
az acr build --registry <acr> --agent-pool vnetpool --image <repo>:<tag> --file Dockerfile .
```

Drop-in workflow: [`../workflows/container-build.yml`](../workflows/container-build.yml).

**Module setup:** Set `runner_acr_push_enabled = true` so the runner UAMI has `AcrPush` on the registry.

**Cost:** S1 is always-on, around USD 0.02/hour per instance with `--count 1` (no scale-to-zero). S2 is around USD 0.04/hour. The agent pool is intentionally not provisioned by the Terraform module because it is a workflow-side choice (sizing, subnet, lifecycle).

## Option 2: build inside the runner with Buildah or Kaniko

Extend the default runner image with rootless `buildah` (or `kaniko`) and push directly to the registry via the Private Endpoint. No ACR Tasks involved. Use this when policy forbids running ACR agent pool VMs or when you want every build to stay on infrastructure you control. Requires a custom runner image (pass via `custom_container_registry_images` and `use_default_container_image = false` on the module). Set `runner_acr_push_enabled = true` so the runner UAMI can authenticate to the registry for the push.

## Why not the shared ACR Tasks pool?

Microsoft documents `networkRuleBypassAllowedForTasks` as the opt-in that lets the shared task pool reach a private registry (effective June 1, 2025, see [Manage network bypass policy for tasks](https://learn.microsoft.com/azure/container-registry/manage-network-bypass-policy-for-tasks)). The module sets it. In practice (verified May 2026 against a Premium registry with `publicNetworkAccess = Disabled`), the agent's `docker login` to `<acr>.azurecr.io` is still rejected by the data-plane firewall. Until that gap is closed upstream, the shared pool is not a working path for this posture. If your ACR is not private, the shared pool works as documented.
