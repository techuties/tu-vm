---
title: Debug Loopback Publish Opt-In Contract
description: Constructional contract to make 127.0.0.1 publishes for Open WebUI 8080, MinIO 9000/9001, and Pi-hole 8081 opt-in so host debug ports do not silently bypass Nginx TLS and allowlist.
last_updated: 2026-09-17
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Debug Loopback Publish Opt-In Contract

## Problem

Compose always publishes host loopback ports for debugging:

- Open WebUI `127.0.0.1:8080:8080`
- MinIO `127.0.0.1:9000:9000` and `127.0.0.1:9001:9001`
- Pi-hole admin `127.0.0.1:8081:80`

Primary access is documented as Nginx vhosts. The loopback mappings still:

1. Bypass Nginx TLS, allowlist, and vhost routing for any local process
2. Collide with other laptop stacks that also want 8080/9000
3. Stay published even when the operator never uses `mc` or a direct UI

Community suggestions then add a second reverse proxy “for debug” or rewrite Stage 12 (53/80/443 host conflicts). Stage 12 is the public edge. This page is only the **optional localhost debug publishes**.

This is distinct from:

- Stage 12 `host-port-binding-contract.md` (53 / 80 / 443 on the host)
- Stage 19 `compose-native-profiles-contract.md` (Tier 1/2 `profiles:` vs `tu-vm.sh` arrays)
- Stage 32 `nginx-server-name-domain-contract.md` (vhost `server_name` from `DOMAIN`)
- Stage 30 `minio-root-user-env-contract.md` (MinIO identity, not ports)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` / `minio` / `pihole` `ports:` | Always-on loopback publishes today |
| Nginx vhosts | Canonical operator access |
| Compose profiles (Stage 19 expected sibling) | Mechanism we can reuse, not a new orchestrator |
| `tu-vm.sh` start / doctor | Can document `--debug-ports` or a profile flag |

Out of scope:

- Changing 80/443 or Pi-hole 53 bindings (Stage 12)
- Publishing these services on `0.0.0.0`
- A Traefik/Caddy debug router
- Removing Nginx as the primary path

## Proposal

Make the four loopback mappings **opt-in**. Prefer one of these official Compose patterns (pick one; do not ship both):

1. **Profile:** move the four mappings onto a `debug-ports` profile. Default `./tu-vm.sh start` does not enable it. Operators who need `mc` or a raw UI run `docker compose --profile debug-ports up -d` (or a thin `tu-vm.sh` flag that passes the profile).
2. **Empty-port interpolation:** `ports: ["${OPENWEBUI_DEBUG_PUBLISH:-}8080:8080"]` is easy to get wrong. Prefer an explicit second compose fragment or profile over clever empty-string ports.

Document that `mc`, rclone, and helper MinIO tooling already have a path through Nginx or an ephemeral `docker compose run` client. Do not keep 9000/9001 published “just in case”.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui`, `minio`, `pihole` | Move loopback publishes behind `profiles: [debug-ports]` |
| CLI | `tu-vm.sh` | Optional `--debug-ports` that enables the profile |
| Docs | QUICK_REFERENCE + playbooks | Default is Nginx-only; debug ports are opt-in |

### Rules

1. **Do not bind debug ports on `0.0.0.0`.** Loopback only if enabled.
2. **Do not rewrite Stage 12.** 53/80/443 stay that page.
3. **Do not invent a debug reverse proxy.** Nginx remains the published edge.
4. **GitHub remains intake.** Requests for a “developer ingress mesh” stay Issues.

### Suggested contributor checklist

```text
1. Confirm default compose up does not publish 8080/9000/9001/8081
2. Confirm --profile debug-ports (or tu-vm.sh flag) restores the four mappings on 127.0.0.1
3. Confirm 80/443/53 are unchanged
4. Update QUICK_REFERENCE debug URLs to say they need the profile
5. Do not add Traefik or host network_mode for this
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Optional extra ports | Compose `profiles` | A second orchestrator |
| Operator access | Existing Nginx vhosts | Always-on localhost bypass |
| Host port conflicts | Stage 12 for 53/80/443 | Mixing public edge into this page |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: profile (or equivalent) + docs. Mention the change in release notes; local bookmarks to `:8080` will stop working until the profile is enabled.

## Acceptance criteria

- [ ] Default start does not publish 8080, 9000, 9001, or 8081.
- [ ] An explicit profile or `tu-vm.sh` flag restores 127.0.0.1 mappings.
- [ ] 53/80/443 behavior is unchanged (Stage 12).
- [ ] No extra reverse-proxy service is added.

## Rollback

Restore the four `ports:` lines on the services. Previous debug bookmarks work again.

## Success metrics

- Laptop port 8080/9000 collisions drop for default starts.
- Direct loopback access is an intentional operator choice, not a silent bypass.
