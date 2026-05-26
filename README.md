# github-runners-alz-corp-cookbook

Patterns, recipes and drop-in workflows for self-hosted GitHub Actions runners deployed with [`martinopedal/terraform-azurerm-github-runners-alz-corp`](https://github.com/martinopedal/terraform-azurerm-github-runners-alz-corp).

The module provisions the platform (runners, ACR, UAMI, networking, optional webhook scaling). This repo documents how to **use** that platform from a workflow: building container images, running Terraform with managed identity, and similar end-to-end patterns that depend on choices outside the module's scope (subnets, agent pools, registry network policy).

Everything here is validated against the private posture the module ships by default: `publicNetworkAccess = Disabled` on ACR, runners on Azure Container Apps Jobs, egress through a central Azure Firewall.

## Contents

| Pattern | File | What it shows |
| --- | --- | --- |
| Build images and push to private ACR | [`patterns/acr-build.md`](./patterns/acr-build.md) | The two validated paths (VNet-joined ACR agent pool and in-runner Buildah), and why the shared ACR Tasks pool is not a working option. |
| Container build workflow | [`workflows/container-build.yml`](./workflows/container-build.yml) | Drop-in `.github/workflows/container-build.yml` using `az acr build --agent-pool`. |

## Prerequisites

You have a working deployment of [`terraform-azurerm-github-runners-alz-corp`](https://github.com/martinopedal/terraform-azurerm-github-runners-alz-corp) with:

- Runners registered to your GitHub org or repo and reachable via labels (default: `[self-hosted, linux, alz-corp]`).
- ACR created by the module (`container_registry_creation_enabled = true`, default).
- `runner_acr_push_enabled = true` set on the module, so the runner UAMI has `AcrPush` on the registry.

That is the minimum the patterns in this repo assume.

## License

MIT. See [LICENSE](./LICENSE).
