---
title: AppArmor / Seccomp Profile Contract
description: Constructional contract for optional Linux Security Module profiles on Compose services, layered on existing resource limits, without replacing Stage 18 cap_drop or inventing a custom LSM.
last_updated: 2026-08-20
owner: maintainers
status: proposed
theme: security
impact: medium
---

# AppArmor / Seccomp Profile Contract

## Problem

`docker-compose.yml` sets memory/CPU `deploy.resources` and some services mount `docker.sock`, but there are **no** `security_opt`, AppArmor, or seccomp stanzas. Stage 18 asks for additive `cap_drop` / `no-new-privileges` / forbidding extra docker.sock mounts. Those are capability bits, not LSM profiles.

Community PRs that want “more hardening” tend to paste a random `security_opt: [apparmor=unconfined]` (weaker), commit a huge custom seccomp JSON, or require a non-distro LSM.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` | Resource limits; no `security_opt` / `cap_drop` today |
| `helper_index` | Needs docker.sock—any profile must allow that API |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Image CVEs, not runtime LSM |
| Stage 11 `privileged-host-ops-contract.md` (expected sibling) | Host sudoers |
| Stage 18 `container-hardening-baseline-contract.md` (expected sibling) | cap_drop / no-new-privileges / docker.sock review |
| Stage 18 `mcp-tool-sandbox-contribution-contract.md` (expected sibling) | MCP tool mounts, not host LSM |

Out of scope:

- Replacing Stage 18 capability rules
- Writing a project-owned AppArmor parser or kernel module
- `privileged: true` as a hardening shortcut
- SELinux policy modules unless a maintainer on an SELinux distro owns them

## Proposal

Layer **optional, distro-default LSM profiles** on top of Stage 18 capability hygiene.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Capabilities | Compose `cap_drop` / `security_opt: [no-new-privileges:true]` | Stage 18—do this first |
| AppArmor | `security_opt: [apparmor:docker-default]` | Distro/engine default, not `unconfined` |
| Seccomp | `security_opt: [seccomp=…/profile.json]` or Docker default | Only when a syscall block is proven |
| Exceptions | Per-service comments | helper_index / Pi-hole / privileged host ops listed |
| CI | `docker compose config --quiet` | Invalid `security_opt` fails render |

### Rules

1. **Stage 18 first.** Do not add LSM profiles to a service that still runs as full root with extra docker.sock mounts and no `no-new-privileges`.
2. **Prefer engine defaults.** `docker-default` AppArmor and the default seccomp profile are the starting point. Custom JSON is allowed only with a comment citing the syscall that broke production.
3. **Never set `apparmor=unconfined` or `seccomp=unconfined`** to “make it work” in a merged PR. Use a named exception issue instead.
4. **helper_index is special.** Profiles must still allow unix-socket HTTP to the Docker API. If a profile breaks control-plane status, revert that service only.
5. **One concern per PR.** Do not mix LSM, IPAM, and backup changes.
6. **GitHub remains intake.** Requests for gVisor / Kata stay Issues.

### Suggested contributor checklist

```text
1. Read Stage 18 hardening baseline
2. Add no-new-privileges / cap_drop before LSM
3. Use docker-default AppArmor unless a named profile is required
4. Do not commit apparmor=unconfined
5. Recreate the service and hit /status/full (or the service healthcheck)
6. Document any extra syscall in the PR, not in a new LSM repo
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Capabilities | Stage 18 Compose keys | A custom entrypoint wrapper |
| AppArmor | Engine/distro default profile | Project-authored kernel modules |
| Seccomp | Docker default, then a tiny JSON delta | Copying a 2000-line profile from a blog |
| Isolation extras | Existing resource limits + Fetch CIDR deny | gVisor as a prerequisite |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `security_opt: ["no-new-privileges:true"]` on Tier 1 services that do not need extra privileges, then opt into `apparmor:docker-default` where the host supports it.
3. Optional: a playbook note that AppArmor is a no-op on some kernels (WSL2, some cloud images)—failure mode is “profile ignored,” not stack down.

## Acceptance criteria

- [ ] LSM work is additive to Stage 18, not a replacement.
- [ ] Default profiles are preferred over custom JSON.
- [ ] `unconfined` is forbidden in merged compose without an Issue-linked exception.
- [ ] helper_index docker.sock remains functional.

## Rollback

Remove the `security_opt` list from the affected service. Capability drops can stay. No data-volume change.

## Success metrics

- New services land with `no-new-privileges` and default LSM, not `unconfined`.
- Control-plane routes still work after helper_index profile experiments.
- Custom seccomp files are rare and justified in the PR body.
