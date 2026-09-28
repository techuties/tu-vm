---
title: Helper Image Build Contract
description: Constructional contract to build helper_index from a lockfile, using the processor Dockerfile pattern, instead of apk and pip on every container start.
last_updated: 2026-09-28
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Helper Image Build Contract

## Problem

`helper_index` is the only Compose service whose `image:` is not a digest pin, other than `n8n-mcp` (that tag is the [image update compare](./image-update-compare-contract.md) contract). The helper line is:

```text
image: python:3-alpine
command: sh -c "apk add --no-cache docker-cli docker-cli-compose curl && docker compose version && pip install --no-cache-dir flask requests requests-unixsocket && python -B -u /app/uploader.py"
```

Every start downloads Alpine packages and three Python distributions from the network, as root, in a container that also mounts the Docker socket. A registry or index outage makes the landing page fail even when `uploader.py` has not changed. The install set is unpinned, so two starts on the same day can run different Flask builds.

`tika-minio-processor/Dockerfile` already installs from `requirements.txt` at build time. The helper should follow that file, not a second packaging design.

`uploader.py` talks to the Docker HTTP API through `requests-unixsocket`. The start command’s `docker compose version` is a connectivity print. It is not how start/stop is implemented. The image does not need the Docker CLI for the current API.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tika-minio-processor/Dockerfile` | Build pattern: Alpine base, `requirements.txt`, `pip` at build, `CMD` the script |
| `tika-minio-processor/requirements.txt` | Lockfile shape to copy |
| `helper/uploader.py` imports | `flask`, `requests`, `requests-unixsocket` |
| `docker-compose.yml` `helper_index` | Switch from `image:` plus a shell install to `build: ./helper` |
| Stage 18 helper control-auth (expected sibling, open PR #44) | Socket stays; this page does not redesign control auth |

Out of scope:

- Replacing Flask
- Vendoring Alpine or running a private package proxy
- Pinning every other Compose image again (they are already digest-pinned)
- Removing the Docker socket

## Proposal

Build a helper image the same way the processor image is built.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Dependencies | `helper/requirements.txt` | Pin `flask`, `requests`, and `requests-unixsocket` to the versions you install and import-check |
| Image | `helper/Dockerfile` | Match the processor: `apk` only for what the running app needs, `pip install -r requirements.txt`, copy `uploader.py` |
| Compose | `helper_index` | `build: ./helper`. Drop the `apk` / `pip` / `docker compose version` shell. `command` can stay the processor style: `python -B -u /app/uploader.py` |
| CLI | omit `docker-cli` and `docker-cli-compose` | The Unix-socket client is the control path |
| CI | existing `docker compose config` check | The build section must render. A full image build can stay a maintainer step until CI runners are ready to build it |

### Rules

1. **No package install in `command`.** Runtime start does not call `apk` or `pip`.
2. **Pins live in `helper/requirements.txt`.** Do not leave bare distribution names in the Dockerfile.
3. **Follow the processor Dockerfile.** Same base family is fine. Do not introduce a second base OS or a multi-stage framework for one script.
4. **Do not bake secrets into the image.** No `COPY` of `.env`, `ssl/`, or `nginx/dynamic`.
5. **Keep `./helper:/app` only until the image copies `uploader.py`.** After the image contains the script, a bind of the source tree is a developer convenience, not a requirement. Do not also mount the repository root (see the project-mount contract).
6. **Record the base digest** in Compose once the Dockerfile’s `FROM` is chosen, the same way other services use `@sha256:`. Do not leave `python:3-alpine` floating on the service that replaced it.

### Suggested contributor checklist

```text
1. Add helper/requirements.txt with pinned flask, requests, requests-unixsocket
2. Add helper/Dockerfile modeled on tika-minio-processor/Dockerfile
3. Point helper_index at build: ./helper and delete the install shell
4. Import-check uploader.py inside the built image
5. Confirm docker compose config renders
6. Do not COPY .env or ssl into the image
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Python deps | `requirements.txt` + image build, as the processor does | `pip install` on every start |
| Base image | Digest-pinned Alpine Python, same family as the processor | An unpinned `python:3-alpine` tag in Compose |
| Docker control | `requests-unixsocket` already in `uploader.py` | Installing `docker-cli` to print a version |
| Supply chain | Existing Trivy workflow can later scan the built image | A new scanner just for this service |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add the Dockerfile and lockfile, then switch Compose, in one change so `main` never has a `build` key without a Dockerfile.
3. Recreate `ai_helper_index`. The first start should not contact a package index.

## Acceptance criteria

- [ ] `helper_index` `command` does not invoke `apk` or `pip`.
- [ ] `helper/requirements.txt` pins the three imported distributions.
- [ ] `docker compose config` renders `helper_index` from `build: ./helper`.
- [ ] The image starts `uploader.py` and `GET /health` returns ok.
- [ ] The image build context does not contain `.env` or `ssl/`.
- [ ] The Docker socket and Stage 18 auth behavior are unchanged.

## Rollback

Restore the `image: python:3-alpine` service definition and recreate the container. The Dockerfile can stay unused. Docs-only publication needs no runtime rollback.

## Success metrics

- A package-index outage no longer takes down the landing helper.
- Two restarts on the same commit run the same Flask build.
- Reviewers can see helper dependencies in git, next to the processor lockfile they already know.
