---
title: Image Update Compare Contract
description: Constructional contract so the daily checkup compares registry manifest digests for the Compose image lines operators actually run.
last_updated: 2026-09-28
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Image Update Compare Contract

## Problem

`scripts/daily-checkup.sh` `check_for_updates` decides `docker_updates` like this:

```text
local_digest = docker inspect --format '{{.Id}}' of a tag
remote_digest = buildx imagetools (or manifest inspect) digest for that tag and platform
outdated when both are non-empty and unequal
```

Those two values are different kinds of identifier. `.Id` is the image config id. `imagetools` prints the registry manifest digest for one platform. They are not supposed to be equal for a fully updated image, so a tag that happens to exist locally is reported as outdated.

The tag list is also a second inventory. It names `postgres:15-alpine`, `redis:alpine`, `qdrant/qdrant:latest`, `ollama/ollama:latest`, and other floating tags. On 2026-09-28 `docker-compose.yml` has 17 `image:` lines. Fifteen are `name@sha256:…` pins. `docker inspect postgres:15-alpine` does not see `postgres@sha256:…` unless that tag was pulled separately. Those pins are skipped (`local_digest` empty), so the dashboard reports no Docker updates while the pin is stale.

The two lines that are not digest-pinned are `python:3-alpine` (helper) and `ghcr.io/czlonkowski/n8n-mcp:latest`. Neither is in the checkup’s tag array, so the only floating production tags are invisible to the check.

`.github/dependabot.yml` already runs weekly for `package-ecosystem: github-actions`. The same file is the community’s update framework. It does not yet watch Docker images. Do not add Watchtower, Diun, or another updater container for a compare the checkup script can do.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/daily-checkup.sh` `check_for_updates` | Script to fix; it already shells out to `docker buildx imagetools` |
| `docker-compose.yml` `image:` lines | Source of truth for what the stack runs |
| `tu-vm.sh` update path | Operator command that should consume the same definition of “outdated” |
| `.github/dependabot.yml` | Existing updater. Add a `docker` ecosystem entry rather than a new bot |
| [Helper image build](./helper-image-build-contract.md) | Removes the floating `python:3-alpine` service image once the helper is built |
| Stage 26 n8n-mcp digest notes (expected sibling, open PR #52) | That stage records the n8n-mcp pin policy. This page does not restate the listener or restart rules |

Out of scope:

- Auto-pulling or auto-applying image updates from cron
- Changing digest pins inside this docs change
- A private registry mirror
- Re-implementing Trivy (the config scan workflow already exists)

## Proposal

Teach the checkup to read Compose, and let Dependabot open digest-bump PRs.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Inventory | `check_for_updates` | Parse `image:` from `docker-compose.yml`. Delete the hard-coded tag array. |
| Local id | `docker image inspect` | Use `RepoDigests`, not `.Id`. |
| Remote id | existing `get_remote_digest` | For a pin `name@sha256:…`, remember the digest in the file. “Running what Compose says” is a match against `RepoDigests`. Upstream drift is the digest of the **tracked tag** for that image, compared to the pin. |
| Tracked tags | one map in the checkup or comments next to pins | Only where a pin replaced a tag the project still wants to follow (`postgres:15-alpine`, and so on). Do not invent tags the file never used. |
| Floating tags | `n8n-mcp:latest` and, until the image contract lands, `python:3-alpine` | Compare `RepoDigests` to `get_remote_digest` for that same reference. |
| Community PRs | `.github/dependabot.yml` | Add `package-ecosystem: docker` on `/` with a weekly interval, next to the Actions entry. |

### Rules

1. **Never compare `.Id` to a manifest digest.** Both sides of the equality must be registry manifest digests.
2. **Compose is the inventory.** A new service is checked because its `image:` line exists, not because someone edited a second list.
3. **A missing local tag is not “up to date”.** If the file pins `repo@sha256:abc` and `RepoDigests` does not contain `abc`, say the image is not present. If the tracked tag’s current manifest digest differs from `abc`, say an update exists.
4. **Do not pull images** in the daily checkup. `imagetools` / `manifest inspect` are already the no-download path.
5. **Do not add an updater container.** Applying updates stays `./tu-vm.sh update`.
6. **Dependabot opens PRs; it does not restart the LAN.** Operators still merge and run the existing update command.
7. **Leave n8n-mcp auth and restart policy** to Stage 26. This page only requires that its Compose reference is visible to the compare.

### Suggested contributor checklist

```text
1. Replace the tag array with image: lines from docker-compose.yml
2. Read RepoDigests for the local side
3. Add a fixture where .Id != manifest digest and assert it is not, by itself, an update
4. Add a fixture where the pin digest differs from the tracked tag digest and assert an update
5. Add dependabot docker ecosystem without removing the github-actions entry
6. Confirm the checkup still writes the same JSON keys
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Discover newer digests | `docker buildx imagetools`, already called in this script | A new update daemon |
| Reviewable bumps | Dependabot `docker` in the existing `.github/dependabot.yml` | Hand-maintained tag lists |
| Apply on the LAN | `./tu-vm.sh update` | Cron that pulls `:latest` |
| What is running | Compose `image:` plus `RepoDigests` | `docker inspect` `.Id` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Fix the compare and the JSON keys in `daily-checkup.sh` before adding Dependabot, so the dashboard and the PRs use the same notion of drift.
3. Add the Dependabot docker block in a small follow-up. It will open its own PRs; it should not be mixed with a script bugfix if that makes review harder.

## Acceptance criteria

- [ ] The checkup does not read `.Id` for update decisions.
- [ ] Every Compose `image:` line is considered, including `ghcr.io/czlonkowski/n8n-mcp:latest`.
- [ ] An image whose config id differs from its manifest digest is not marked outdated for that reason alone.
- [ ] A pin whose digest differs from the tracked tag’s platform manifest digest is marked outdated.
- [ ] The script does not `docker pull`.
- [ ] `.github/dependabot.yml` still updates GitHub Actions, and a docker ecosystem entry is present.
- [ ] Update JSON keys consumed by the landing page stay the same.

## Rollback

Restore the previous `check_for_updates` function. Remove the docker ecosystem block if it is noisy. Docs-only publication needs no runtime rollback.

## Success metrics

- Digest-pinned services show up in the daily result when their tracked tag has moved.
- A healthy, fully pinned stack is not reported outdated solely because config ids and manifest digests differ.
- Image bumps arrive as Dependabot PRs the maintainers already know how to review.
