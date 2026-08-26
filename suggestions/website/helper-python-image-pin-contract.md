---
title: Helper Python Image Pin Contract
description: Constructional contract for digest-pinning helper_index python:3-alpine until the Stage 22 bake lands, using the existing tu-vm.sh update map instead of a custom helper distro.
last_updated: 2026-08-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Helper Python Image Pin Contract

## Problem

`helper_index` is the only always-on first-party service that still uses a **floating tag**:

```yaml
image: python:3-alpine
```

Every other official image in Compose is digest-pinned. Nginx, Postgres, Open WebUI, and Pi-hole cannot silently retag under the operator. The helper can: a `docker compose up` after a prune, or a host that is not using a local cache, pulls whatever `python:3-alpine` means **today**. That breaks reproducibility, Stage 4/15 supply-chain gates, and the "pin then bump via `tu-vm.sh update`" story.

Stage 22 covers **baking** apk/pip into `helper/Dockerfile` so the runtime image is first-party. That bake has not landed. Until it does, the helper still needs a pin — not a new distro.

`OFFICIAL_UPDATE_IMAGE_PAIRS` in `tu-vm.sh` does **not** list `helper_index`. Safe-update cannot bump what it does not know about.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose digest pins (`image: name@sha256:…`) | Established pattern for official images |
| `OFFICIAL_UPDATE_IMAGE_PAIRS` | Tag-to-repo map used by `tu-vm.sh update` |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Pin / check / update / rollback channels |
| Stage 15 safe-update contribution contract (expected sibling) | How official pairs are maintained |
| Stage 22 `helper-index-image-bake-contract.md` (expected sibling) | Long-term first-party image |
| Stage 26 `n8n-mcp-digest-pin-contract.md` (expected sibling) | Same pin move for the last floating sidecar |

Out of scope:

- Writing `helper/Dockerfile` on this page (that is Stage 22)
- A custom "TechUties Python" base or a second updater
- Pinning `mcp-tools/*` or `tika-minio-processor` build contexts (already first-party builds)
- Changing Flask routes, CONTROL_TOKEN, or the landing dashboard

## Proposal

Pin `python:3-alpine` by digest **and** register the pair so the existing updater can refresh it.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `helper_index.image` | `python@sha256:…` (resolved from `python:3-alpine`) |
| Updater | `OFFICIAL_UPDATE_IMAGE_PAIRS` | `"helper_index\|python:3-alpine\|python"` |
| Docs | this page + Stage 15/22 checklists | Floating tags on always-on services are a defect |
| After bake | Stage 22 | Drop the Docker Hub pin; the baked image becomes the pin |

### Rules

1. **Pin the tag you already run.** Do not switch to `python:3.12-alpine` or `python:slim` as part of the pin. Tag moves belong in a bake or a dedicated issue.
2. **Reuse `tu-vm.sh update`.** Add one `OFFICIAL_UPDATE_IMAGE_PAIRS` row. Do not add `scripts/update-helper-image.sh`.
3. **Do not block Stage 22.** The pin is a bridge. When the bake lands, delete the Docker Hub pin and point Compose at the baked image digest.
4. **Record the source tag in a comment.** `# python:3-alpine; bump via: sudo ./tu-vm.sh update`
5. **GitHub remains intake.** Requests for a "signed helper distro" stay Issues until Stage 22 + Stage 21 provenance land.

### Suggested contributor checklist

```text
1. Resolve python:3-alpine to a current multi-arch digest
2. Set helper_index.image to python@sha256:…
3. Add helper_index to OFFICIAL_UPDATE_IMAGE_PAIRS
4. Do not change the apk/pip command line (Stage 22)
5. Confirm docker compose config still renders
6. Confirm ./tu-vm.sh update-check lists helper_index
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Reproducible helper base | Compose digest pin | Floating `python:3-alpine` |
| Bumping the pin | Existing `tu-vm.sh update` map | A second helper updater |
| Long-term image | Stage 22 bake | A custom public distro |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: digest + pair row first; bake later.
3. After Stage 22 merges, remove the Docker Hub pin in the same PR that introduces `helper/Dockerfile`.

## Acceptance criteria

- [ ] `helper_index.image` is digest-pinned (no floating tag).
- [ ] `OFFICIAL_UPDATE_IMAGE_PAIRS` includes `helper_index`.
- [ ] The apk/pip startup command is unchanged by this pin.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] `./tu-vm.sh update-check` can see and bump the helper image.

## Rollback

Restore `image: python:3-alpine` and drop the pair row. Volumes and Flask code are unchanged.

## Success metrics

- Helper no longer appears as the only unpinned always-on official image.
- Helper pin bumps travel through the same update PR as Nginx/Postgres.
- Stage 22 bake PRs treat this pin as deleted work, not a competing image.
