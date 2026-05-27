# Public Repo Fork Security

Public GitHub repositories accept pull requests from untrusted contributors. Those PRs can change workflow YAML files. If your workflow runs on self-hosted runners, an attacker can submit a malicious PR that executes code with your runner's IAM — accessing secrets, key vaults, private endpoints, and the underlying Azure VNet.

This recipe shows how to route untrusted PRs to GitHub-hosted runners (`ubuntu-latest`) while keeping maintainer pushes and same-repo PRs on self-hosted infrastructure.

## The attack surface

### pull_request trigger

The `pull_request` event checks out the attacker's branch and runs their YAML. If the workflow specifies `runs-on: [self-hosted, ...]`, the attacker's steps execute with:

- Access to repository secrets
- The runner's managed identity (if the runner VM/Container has one)
- Network access to private endpoints on the runner's VNet
- Any environment variables or tools installed on the runner

The most common exploit is exfiltrating `AZURE_CLIENT_ID` + `GITHUB_TOKEN` or key vault URLs from environment variables, then using them outside the workflow to escalate privileges.

### pull_request_target and trusted code paths

`pull_request_target` checks out the base branch (typically `main`), not the attacker's fork. The YAML is trusted. But if your workflow installs dependencies from the PR's `package.json`, runs `make` targets from the PR's `Makefile`, or evaluates `${{ github.event.pull_request.title }}` in a script without sanitization, the attacker still has a code execution path.

Even with `pull_request_target`, you need runner selection gates.

## The pattern

GitHub's recommended approach is a two-job workflow. Job 1 decides which runner to use based on the event type and PR source. Job 2 uses that decision.

### Job 1: decide-runner (always GitHub-hosted)

This job runs on `ubuntu-latest`. It inspects `github.event_name`, `github.event.pull_request.head.repo.full_name`, and PR labels to decide whether the PR is trusted.

**Trusted contexts (use self-hosted):**
- `push` events — maintainer direct push
- `pull_request` where `head.repo.full_name == github.repository` — PR from a branch in the same repo, not a fork
- Fork PRs with a specific label applied by a maintainer (e.g., `safe-to-test-on-self-hosted`)

**Untrusted contexts (use GitHub-hosted):**
- `pull_request` where `head.repo.full_name != github.repository` — fork PR
- Any fork PR without the safe-label

The decision is output as a JSON array of runner labels.

### Job 2: build (uses the decided runner)

```yaml
needs: decide-runner
runs-on: ${{ fromJSON(needs.decide-runner.outputs.runner-labels) }}
```

This ensures untrusted PRs never reach self-hosted infrastructure.

## Reusable workflow

This cookbook provides a reusable workflow at `.github/workflows/decide-runner.yml`. Call it from your workflows:

```yaml
jobs:
  decide-runner:
    uses: martinopedal/github-runners-alz-corp-cookbook/.github/workflows/decide-runner.yml@v1
    with:
      self-hosted-labels: '["self-hosted", "personal", "pub", "linux"]'
      fallback-runner: 'ubuntu-latest'
      safe-label: 'safe-to-test-on-self-hosted'

  build:
    needs: decide-runner
    runs-on: ${{ fromJSON(needs.decide-runner.outputs.runner-labels) }}
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          npm install
          npm test
```

### Inputs

| Input | Default | Description |
|---|---|---|
| `self-hosted-labels` | `["self-hosted", "personal", "pub", "linux"]` | JSON array of labels for your self-hosted runners |
| `fallback-runner` | `ubuntu-latest` | Runner to use for untrusted PRs |
| `safe-label` | `safe-to-test-on-self-hosted` | Label that allows fork PRs to use self-hosted runners when applied by a maintainer |

### Outputs

| Output | Description |
|---|---|
| `runner-labels` | JSON array of runner labels. Pass to `runs-on: ${{ fromJSON(...) }}` |

## The safe-label override

Fork PRs are untrusted by default. If a maintainer reviews the PR and confirms it is safe (no malicious code, no secret exfiltration, no suspicious network calls), they can add the `safe-to-test-on-self-hosted` label. The next workflow run will use self-hosted infrastructure.

Use this sparingly. Most fork PRs do not need self-hosted runners. Reserve it for PRs that test infrastructure-specific behavior (VNet integration, private ACR access, etc.).

## Example: migrating an existing workflow

**Before** (unsafe):

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: [self-hosted, personal, pub, linux]
    steps:
      - uses: actions/checkout@v4
      - run: npm test
```

**After** (fork-safe):

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  decide-runner:
    uses: martinopedal/github-runners-alz-corp-cookbook/.github/workflows/decide-runner.yml@v1
    with:
      self-hosted-labels: '["self-hosted", "personal", "pub", "linux"]'

  test:
    needs: decide-runner
    runs-on: ${{ fromJSON(needs.decide-runner.outputs.runner-labels) }}
    steps:
      - uses: actions/checkout@v4
      - run: npm test
```

### Concurrency group

The `concurrency` block cancels in-progress runs when a new commit is pushed to the same PR. This prevents runner exhaustion when an attacker opens many PRs or pushes many commits rapidly.

The `cancel-in-progress` applies only to PRs (`github.event.pull_request.number`), not to `main` branch pushes (`github.ref`).

## When to use this pattern

**Use when:**
- Your repo is public
- You accept PRs from forks
- You run workflows on self-hosted runners
- Those runners have network access to private resources (VNets, key vaults, private ACRs)

**Skip when:**
- Your repo is private (forks cannot be opened without collaborator access)
- You only use GitHub-hosted runners (no IAM or network exposure)
- You do not accept external contributions

## References

- [GitHub Security Hardening — Using self-hosted runners in public repositories](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#using-self-hosted-runners-in-public-repositories)
- [GitHub Actions: Preventing pwn requests](https://securitylab.github.com/research/github-actions-preventing-pwn-requests/)
