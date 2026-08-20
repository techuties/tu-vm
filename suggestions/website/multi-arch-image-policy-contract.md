---
title: Multi-Arch Image Policy Contract
description: Constructional contract for digest-pinned images that remain usable on linux/amd64 and linux/arm64 without a second compose file or a separate ARM product.
last_updated: 2026-08-20
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Multi-Arch Image Policy Contract

## Problem

Compose images are digest-pinned (good for supply chain). Digests are usually **single-architecture**. `scripts/daily-checkup.sh` already detects `linux/arm64` when checking for updates, but `docker-compose.yml` does not declare `platform:` and there is no documented rule for contributors who add or bump an image on Apple Silicon, Raspberry Pi, or ARM cloud hosts.

Community PRs that hit `exec format error` tend to propose `docker-compose.arm64.yml`, dropping digest pins, or maintaining a fork.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` | Digest-pinned images; no `platform:` keys |
| `scripts/daily-checkup.sh` | `uname -m` → `linux/amd64` / `linux/arm64` / `linux/arm/v7` |
| `scripts/safe-update.sh` | Pin map for check/apply/rollback |
| Stage 2 `hardware-compatibility-matrix.md` (expected sibling) | Host/RAM/GPU fit, not image arch |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | CVE / SBOM, not multi-arch |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Pin / update / rollback channels |
| Stage 15 `safe-update-contribution-contract.md` (expected sibling) | How to change the pin map |
| Stage 20 `wsl2-contributor-path-contract.md` (expected sibling) | Windows host path, not CPU arch |

Out of scope:

- A second compose file per architecture
- Building every upstream image in this repository
- Dropping digest pins to “float on latest”
- GPU / CUDA image variants (Stage 10)

## Proposal

Treat **multi-arch digest selection** as part of the existing pin/update channel, not a new product line.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Pins | `docker-compose.yml` `image:` | Prefer a **multi-arch index digest** when the publisher provides one |
| Host hint | Optional `platform: linux/${arch}` | Only when the image is single-arch and the host is known |
| Checkup | `daily-checkup.sh` | Already passes `--platform`; keep it aligned with pins |
| Update | `safe-update.sh` pin map | Record arch support next to the digest |
| Docs | CONTRIBUTING or playbook note | How to verify `docker buildx imagetools inspect` |

### Rules

1. **One compose file.** Do not add `docker-compose.arm64.yml`. Overrides stay local (Stage 8).
2. **Prefer index digests.** If the registry manifest list covers `linux/amd64` and `linux/arm64`, pin that index digest so both hosts pull the correct blob.
3. **Do not silently drop pins.** Floating tags are not an architecture strategy.
4. **Declare incompatibilities.** If an image is amd64-only, say so in the hardware matrix / pin map rather than failing at `docker compose up`.
5. **Checkup stays host-aware.** `uname -m` mapping already exists; new images must be added to that list with a platform that the publisher supports.
6. **GitHub remains intake.** Requests for an official ARM appliance image stay Issues.

### Suggested contributor checklist

```text
1. docker buildx imagetools inspect IMAGE@sha256:…
2. Confirm linux/amd64 and linux/arm64 (or document the gap)
3. Update docker-compose.yml digest in the same PR as safe-update pin map
4. Do not add a second compose file
5. If single-arch, note it in the hardware matrix / checkup list
6. Run compose config --quiet
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Pins | Existing digest + safe-update map | Latest tags / unpinned ARM fork |
| Arch detect | Existing `daily-checkup.sh` `uname -m` | A new inventory service |
| Host fit | Stage 2 hardware matrix | Separate ARM documentation site |
| Local exceptions | Stage 8 compose override | Committed `docker-compose.arm64.yml` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: document arch coverage in the safe-update pin map, and fix the next digest bump that is amd64-only by choosing a multi-arch index digest when available.
3. Optional: CI job on `linux/amd64` only remains the default; do not require ARM runners to land docs.

## Acceptance criteria

- [ ] One compose file remains the source of truth.
- [ ] Digest pins stay required.
- [ ] Multi-arch index digests are preferred when publishers provide them.
- [ ] amd64-only images are documented, not papered over with a second compose file.

## Rollback

Restore the previous digest. Remove any `platform:` key added for a failed experiment. Checkup platform detection can remain.

## Success metrics

- ARM hosts fail at pin-selection time with a documented gap, not with `exec format error` after pull.
- Image-bump PRs record arch coverage next to the digest.
- No second compose file lands in the default tree.
