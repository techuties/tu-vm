---
title: n8n-mcp Digest Pin Contract
description: Constructional contract for digest-pinning ghcr.io/czlonkowski/n8n-mcp instead of a floating :latest tag, using the existing safe-update pin map.
last_updated: 2026-08-25
owner: maintainers
status: proposed
theme: security
impact: high
---

# n8n-mcp Digest Pin Contract

## Problem

`n8n_mcp` is the only official sidecar still declared as a **floating tag**:

```yaml
image: ghcr.io/czlonkowski/n8n-mcp:latest
```

Every other first-party registry image in `docker-compose.yml` uses `name@sha256:…`. `tu-vm.sh` already lists `n8n_mcp` in `OFFICIAL_UPDATE_IMAGE_PAIRS`, so the **update path exists** — Compose just never received the pin that `./tu-vm.sh update` is designed to refresh.

A floating `:latest` means two operators on the same git revision can run different binaries. That breaks community reproduction, CI, and the "pin then update" story in Stage 8/15.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `n8n_mcp` | Floating `:latest` today |
| `tu-vm.sh` `OFFICIAL_UPDATE_IMAGE_PAIRS` | `n8n_mcp\|ghcr.io/czlonkowski/n8n-mcp:latest\|…` already present |
| Stage 8 `image-update-channel-policy.md` (expected sibling) | Pin / check / update / rollback channels |
| Stage 15 `safe-update-contribution-contract.md` (expected sibling) | How to extend the pin map |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Trivy / SBOM, not this pin |
| Stage 14 `n8n-mcp-sidecar-contribution-contract.md` (expected sibling) | Sidecar behavior, not image mutability |

Out of scope:

- A second updater, Renovate bot, or GitHub Action that rewrites compose on a schedule
- Changing n8n-mcp auth, `MCP_MODE`, or gateway `n8n_mcp_*` tools
- Pinning first-party **builds** (`tika_minio_processor`, `mcp-tools/*`) — those are Dockerfiles
- Replacing Stage 22 helper bake (`python:3-alpine`) on this page

## Proposal

Pin `n8n_mcp` the same way `browserless` and `n8n` are pinned. Keep `./tu-vm.sh update` as the only supported bump path.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Compose | `n8n_mcp.image` | `ghcr.io/czlonkowski/n8n-mcp@sha256:…` |
| Update map | `OFFICIAL_UPDATE_IMAGE_PAIRS` | Already lists the tag + repo; no new pair |
| Docs | this page + Stage 15 checklist | New official images ship pinned, not `:latest` |

### Rules

1. **Ship a digest, not a tag.** `:latest` is allowed only as the **upstream refresh source** in `OFFICIAL_UPDATE_IMAGE_PAIRS`.
2. **Do not add a second updater.** `./tu-vm.sh update` / `update-check` / `update-rollback` already exist.
3. **Do not invent a digest bot.** Community PRs that only bump the pin are welcome; a cron rewriter is not required.
4. **Record the pin comment.** Match neighboring services: "Pin to digest for update safety; bump via `sudo ./tu-vm.sh update`."
5. **Multi-arch stays Stage 21.** If the digest is amd64-only, say so in the PR; do not add a second image name here.
6. **GitHub remains intake.** Requests for "always pull latest on start" stay Issues (and should be declined).

### Suggested contributor checklist

```text
1. Resolve ghcr.io/czlonkowski/n8n-mcp:latest to a current digest
2. Replace the compose image with name@sha256:…
3. Confirm OFFICIAL_UPDATE_IMAGE_PAIRS already contains n8n_mcp
4. Do not add a new update script or workflow
5. Confirm docker compose config still renders
6. Run tu-vm.sh update-check and confirm n8n_mcp is listed
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Pin + bump | Existing `tu-vm.sh update` pin map | Floating `:latest` in Compose |
| CVE scan | Stage 4 Trivy on pinned images | Treating `:latest` as "always patched" |
| Sidecar behavior | Stage 14 n8n-mcp contract | Mixing auth/tool changes into this PR |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: pin `n8n_mcp` in Compose; leave the update pair as-is.
3. Mention the digest in the PR so operators can diff after the first `update`.

## Acceptance criteria

- [ ] `n8n_mcp` uses `image: ghcr.io/czlonkowski/n8n-mcp@sha256:…`.
- [ ] `OFFICIAL_UPDATE_IMAGE_PAIRS` still lists `n8n_mcp` (no duplicate updater).
- [ ] No new scheduled rewriter or Renovate config is added for this gap.
- [ ] `docker compose config` still renders.
- [ ] `./tu-vm.sh update-check` still reports the sidecar.

## Rollback

Restore `ghcr.io/czlonkowski/n8n-mcp:latest`. Volumes and tokens are unchanged.

## Success metrics

- Two clones of the same revision run the same n8n-mcp binary.
- Community reproduction bugs citing "sidecar behaves differently" drop.
- Contributors pin new official images instead of shipping `:latest`.
