---
title: Podman / Rootless Contributor Path Contract
description: Constructional contract for an optional Docker-compatible Podman or rootless Docker lane that keeps docker-compose.yml and tu-vm.sh as the source of truth, distinct from the WSL2 Windows path.
last_updated: 2026-08-20
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Podman / Rootless Contributor Path Contract

## Problem

The control plane assumes a Docker Engine with a compose v2 plugin and a docker.sock that `helper_index` can mount. That is the supported path. Contributors on Fedora, RHEL, or locked-down laptops often have **Podman** or **rootless Docker** instead.

Stage 20 covers **WSL2** (Windows host → Linux VM → same bash scripts). This page is a **Linux container runtime** lane. Mixing the two produces the wrong advice (`/mnt/c` vs `DOCKER_HOST`).

Community PRs that hit “permission denied on docker.sock” tend to rewrite scripts to `podman-compose` or commit a parallel compose file.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tu-vm.sh` / `scripts/*` | Call `docker` and `docker compose` |
| `helper_index` | Mounts `/var/run/docker.sock` |
| `docker-compose.yml` | Compose spec source of truth |
| Stage 5 `devcontainer-contributor-environment.md` (expected sibling) | Codespaces / Dev Containers (Docker) |
| Stage 11 `privileged-host-ops-contract.md` (expected sibling) | Narrow sudoers, not an alternate runtime |
| Stage 18 `container-hardening-baseline-contract.md` (expected sibling) | cap_drop / docker.sock review |
| Stage 20 `wsl2-contributor-path-contract.md` (expected sibling) | Windows filesystem / line endings |

Out of scope:

- Forking every script to `podman` / `podman-compose`
- Making Podman the default in CI
- Rootless Kubernetes / Quadlet as a second product
- Changing WSL2 guidance

## Proposal

Document a **compatibility shim**: keep the Docker CLI UX, point it at a supported runtime, and list the known helper/socket limits.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Docs | CONTRIBUTING subsection | “Optional: Podman or rootless Docker” |
| Env | `DOCKER_HOST` | `unix:///run/user/$UID/podman/podman.sock` or rootless Docker socket |
| CLI | `docker` / `docker compose` | Prefer `podman-docker` aliases or Compose v2 against Podman socket |
| Helper | `helper_index` volume | Document that docker.sock must be the **same** socket the CLI uses |
| CI | Unchanged | Stay on Docker Engine unless maintainers add a second job |

### Rules

1. **Compose file stays Docker Compose spec.** Do not commit `podman-compose.yml`.
2. **Scripts stay `docker` / `docker compose`.** Wrappers or aliases belong on the contributor machine, not in the repo.
3. **One socket.** `helper_index` must see the same engine the CLI uses. A rootless socket vs a root engine is an unsupported split-brain.
4. **Name the gaps.** Rootless typically cannot bind host port 53 (Pi-hole) or 80/443 without `net.ipv4.ip_unprivileged_port_start`. Document workarounds (higher host ports + Nginx) rather than rewriting Pi-hole.
5. **Do not weaken hardening.** Rootless is not a substitute for Stage 18 cap_drop or Stage 21 LSM profiles.
6. **GitHub remains intake.** “Official Podman support” as a CI matrix stays an Issue until a maintainer owns a runner.

### Suggested contributor checklist

```text
1. Confirm this is Linux runtime, not WSL2 path issues
2. Point DOCKER_HOST at one engine
3. docker compose version && docker compose config --quiet
4. Confirm helper_index can reach that socket
5. Note privileged ports (53/80/443) before reporting a bug
6. Do not submit podman-compose rewrites
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Runtime | Docker Engine (default) or Podman socket via Docker CLI | A second script tree |
| Compose | Existing `docker-compose.yml` | `podman-compose` rewrite |
| Windows | Stage 20 WSL2 path | Mixing Podman Desktop + `/mnt/c` clones |
| Privileged ports | Documented host sysctl / port map | Disabling Pi-hole in the default file |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **docs/code**: a short CONTRIBUTING subsection plus an env example comment for `DOCKER_HOST` (no secrets).
3. Optional later: a maintainer-owned Podman smoke job—only after the socket and port-53 gaps have a written workaround.

## Acceptance criteria

- [ ] Default path remains Docker Engine + Compose v2.
- [ ] Optional Podman/rootless is documented as a compatibility shim, not a fork.
- [ ] WSL2 remains a separate contract.
- [ ] Helper docker.sock must match the CLI engine.

## Rollback

Remove the CONTRIBUTING subsection and `DOCKER_HOST` comment. Scripts that still call `docker` keep working on Docker Engine.

## Success metrics

- Contributors report socket/port gaps against this contract instead of opening rewrite PRs.
- No `podman-compose` file lands in the default tree.
- CI stays on Docker until a dedicated job is explicitly added.
