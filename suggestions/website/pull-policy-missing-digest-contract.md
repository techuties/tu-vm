---
title: Pull Policy on Digest Pins Contract
description: Constructional contract for Compose pull_policy missing on digest-pinned official images so daily up does not re-pull, using the existing tu-vm.sh update channel instead of a pull daemon.
last_updated: 2026-08-27
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Pull Policy on Digest Pins Contract

## Problem

Almost every official service is already **digest-pinned**:

```yaml
image: nginx@sha256:7e8ff0a32da368869608f285124b4375b901401d88f5027865d8f88984d35d38
```

Compose still defaults to `pull_policy: policy` / engine pull behavior that can contact the registry on `docker compose up` even when the digest is already local. On a laptop that is the opposite of the energy story: radio wake, rate limits, and failed `up` when the LAN is offline.

`tu-vm.sh update` is already the **intentional** pull channel. Daily start should reuse local layers.

This is not Stage 8 image-update channels, Stage 15 safe-update, Stage 21 multi-arch, or Stage 26/27 pin leftovers. Those decide *which digest*. This page decides *when Compose is allowed to fetch*.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Digest pins in `docker-compose.yml` | Reproducible official images |
| `OFFICIAL_UPDATE_IMAGE_PAIRS` + `./tu-vm.sh update` | Explicit bump and pull |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Pin / check / update / rollback |
| Stage 6 `airgap-docs-mirror.md` (expected sibling) | Offline operator path |
| Compose spec `pull_policy` | `always` / `missing` / `never` / `build` |

Out of scope:

- Floating tags (`python:3-alpine`, `n8n-mcp:latest`) — Stage 26/27 pins
- Cosign / provenance — Stage 22
- Watchtower, Diun, or a custom pull cron
- Changing `BUILD_REQUIRED_SERVICES` build contexts

## Proposal

Set `pull_policy: missing` on every **digest-pinned official** service. Keep first-party `build:` services on Compose default (build locally).

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | each official `image: …@sha256:` service | `pull_policy: missing` |
| DRY | Stage 28 `x-*` anchors | Optional `x-pull-digest: &pull-digest` merge |
| Update | `tu-vm.sh update` / `safe-update.sh` | Continue to pull explicitly; do not honor `missing` |
| Docs | this page + Stage 8 checklist | Daily `up` must not require registry |

### Rules

1. **Digest pin first.** Do not add `pull_policy: missing` to a floating tag. That hides surprise retags.
2. **Do not use `never` as the default.** Contributors and new clones still need the first pull. `missing` covers both.
3. **Do not add a pull daemon.** Watchtower-on-start fights energy limits and the pin map.
4. **Build services stay local.** `mcp_gateway`, `langgraph_supervisor`, `tika_minio_processor`, and `mcp-tools/*` use `build:`. `pull_policy: build` is optional, not required.
5. **GitHub remains intake.** Requests for “auto-pull latest every morning” stay Issues until someone proposes an energy budget.

### Suggested contributor checklist

```text
1. List services whose image line contains @sha256:
2. Add pull_policy: missing to each (or via x- anchor)
3. Leave build: services unchanged
4. Confirm ./tu-vm.sh update still pulls a bumped digest
5. Confirm docker compose config still renders
6. Confirm a second compose up with no network does not attempt a pull
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| First pull / clone | `pull_policy: missing` | `always` on laptop start |
| Bumping a pin | Existing `tu-vm.sh update` | Watchtower or a second updater |
| Air-gap day two | Local digest + `missing` | Registry-dependent `up` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add the key next to existing pins; optional YAML anchor with the Stage 28 DRY contract.
3. Document in `./tu-vm.sh update` help that update is the only pull path.

## Acceptance criteria

- [ ] Every digest-pinned official service has `pull_policy: missing`.
- [ ] No floating-tag service receives `missing` as a substitute for a pin.
- [ ] `./tu-vm.sh update` still fetches a new digest when the pair map changes.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] A second `compose up` with the image already present does not contact the registry.

## Rollback

Delete the `pull_policy` keys. Digests, volumes, and the update map are unchanged.

## Success metrics

- Laptop `up` works offline after the first successful pull.
- Image traffic appears on `update`, not on every dashboard start.
- Stage 26/27 pin PRs add `pull_policy: missing` in the same change.
