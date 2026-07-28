---
title: Dev Container Contributor Environment
description: Constructional contract for a Dev Containers / Codespaces contributor environment that reuses existing doctor, smoke, and pre-push scripts.
last_updated: 2026-07-28
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Dev Container Contributor Environment

## Problem

Day-to-day contributor friction is still dominated by host setup: Docker permissions, Python tooling, Compose validation, and “which script do I run first?” Folklore spreads across issues even though the repository already ships `doctor`, `check-config`, `smoke-test`, and `pre-push-check`. Historical suggestions repeatedly asked for environment consistency; Stage 2 persona paths describe *who* arrives, but not a reusable *workspace framework*.

Without a published Dev Container contract, contributors reinvent bootstrap scripts per OS, or propose heavyweight custom installers that fight TU-VM’s Compose-first model.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh doctor` / `scripts/doctor.sh` | Environment and runtime diagnostics |
| `scripts/check-config.sh`, `smoke-test.sh`, `pre-push-check.sh` | Contributor validation path |
| `env.example` | Safe template for local `.env` |
| `.pre-commit-config.yaml` | Optional local hygiene |
| Stage 2 `persona-entry-paths.md` (open PR) | First-hour routes by persona |
| Stage 4 dashboard / supply-chain contracts | Downstream quality surfaces |
| PR #26 change-aware workflow | Path-based `contribute-check` proposal |

Out of scope:

- Replacing Docker Compose with a custom orchestrator inside the container
- Shipping production secrets or TLS material in the Dev Container image
- Requiring Codespaces for maintainers who already have a working host
- Building a TU-VM-specific IDE plugin as a prerequisite

## Proposal

Adopt the **Dev Containers** specification (VS Code Dev Containers / GitHub Codespaces)—a mature community framework—so “open workspace → validate” is one path.

### Layout (v1)

```text
.devcontainer/
  devcontainer.json
  Dockerfile          # optional; prefer mcr.microsoft.com/devcontainers/* base
  post-create.sh      # idempotent: apt/python deps only if needed
```

### `devcontainer.json` contract (illustrative)

```json
{
  "name": "tu-vm contributor",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/python:1": { "version": "3.12" }
  },
  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "customizations": {
    "vscode": {
      "extensions": ["ms-azuretools.vscode-docker", "timonwong.shellcheck"]
    }
  },
  "remoteUser": "vscode"
}
```

### Post-create expectations

1. Ensure `python3`, `docker` / Compose plugin, `openssl`, and `gh` are available.
2. Do **not** auto-copy production `.env`; document `cp env.example .env` as an explicit step.
3. Print a short “first commands” banner:

```bash
./tu-vm.sh doctor
./scripts/check-config.sh
./scripts/pre-push-check.sh
```

4. Keep post-create idempotent and offline-friendly where possible (cache package installs).

### Docker-in-Docker vs Docker-outside-Docker

| Mode | Prefer when | Notes |
|---|---|---|
| Docker-in-Docker feature | Codespaces / isolated agent VMs | Matches cloud-agent DinD caveats (`fuse-overlayfs`, `iptables-legacy`) |
| Docker socket mount | Local Dev Container on a host already running daemon | Faster image reuse; document group permissions |

Document both; default the checked-in config to DinD for portability, with a short comment on socket-mount override for advanced contributors.

### Security guardrails

- Never mount host `~/.ssh` or production secret stores by default.
- Never bake `ssl/nginx.key` into the image; generate ephemeral certs in the workspace when Tier 1 is started.
- Keep `nginx/dynamic/control_allowlist.conf` as a local-generated minimal allowlist (`allow 127.0.0.1; deny all;`) unless the contributor intentionally expands it.
- Codespaces secrets (if used) must map only to non-production test values.

### Community day-to-day workflow

| Actor | Action |
|---|---|
| New contributor | Open in Codespaces or “Reopen in Container”; run doctor + pre-push |
| Reviewer | Ask for pre-push evidence on docs/ops PRs when host variance is suspected |
| Maintainer | Bump Dev Container feature pins via Dependabot-friendly digests when practical |
| Agent / automation | Prefer the same post-create path so human and agent environments converge |

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Workspace standard | Dev Containers / Codespaces | Custom `install-all.sh` per distro |
| Validation | Existing `tu-vm.sh` + `scripts/` | Parallel bootstrap CLIs |
| Editor tooling | Published VS Code extensions | Forked IDE distributions |
| Secrets | Contributor-local `.env` from `env.example` | Image-baked credentials |

## Rollout

1. Land `.devcontainer/` with post-create banner and no Tier 1 auto-start (keeps Codespaces cheap).
2. Link from Stage 2 persona entry paths and [`CONTRIBUTING.md`](../../CONTRIBUTING.md) “Environment” section.
3. Optional follow-up: a `compose` feature profile that starts Postgres/Redis only for helper-contract work (see [Compose CI live profile](./compose-ci-live-profile.md)).
4. Record acceptance in Decision Log when maintainers standardize on DinD vs socket mount.

## Acceptance criteria

- [ ] `.devcontainer/devcontainer.json` exists and opens cleanly in VS Code Dev Containers or Codespaces.
- [ ] Post-create completes without requiring production secrets.
- [ ] Documented first commands invoke existing scripts only (no new control plane).
- [ ] SECURITY posture: no default private key or allowlist-wide-open config.
- [ ] CONTRIBUTING or persona pages link here as the supported contributor environment.

## Rollback

Remove or disable `.devcontainer/`; host-based contribution via `env.example` + existing scripts remains fully supported.

## Success metrics

- Drop in setup-related Issues tagged `needs-info` about Docker/Python bootstrap.
- Time-to-first-`pre-push-check` for new contributors measurably shorter in monthly health digest.
