---
title: Helper Index Image Bake Contract
description: Constructional contract for baking helper_index OS and Python dependencies into a Dockerfile instead of apk and pip on every container start, without replacing the Flask helper or inventing a second control API.
last_updated: 2026-08-21
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Helper Index Image Bake Contract

## Problem

`helper_index` starts from stock `python:3-alpine` and installs its runtime on every boot:

```text
image: python:3-alpine
command: sh -c "apk add --no-cache docker-cli docker-cli-compose curl &&
  docker compose version &&
  pip install --no-cache-dir flask requests requests-unixsocket &&
  python -B -u /app/uploader.py"
```

That makes first (and every) start slower, depends on Alpine package mirrors and PyPI at boot, and can fail the landing-page control plane when the host is air-gapped. The document processor already uses a baked `tika-minio-processor/Dockerfile`. Community PRs that notice the delay tend to propose FastAPI rewrites, a second helper container, or baking `uploader.py` into the image so bind-mounts disappear.

Stage 21 covers **splitting** `uploader.py` into modules. This page is only the **image construction** of `ai_helper_index`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `helper_index` | Stock Alpine + apk/pip `command:` |
| `./helper:/app` bind-mount | Live Flask source for operators and contributors |
| `tika-minio-processor/Dockerfile` | In-repo pattern: Alpine + `pip` at **build** time |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | `/status/full` and route rules |
| Stage 21 `helper-uploader-module-contribution-contract.md` (expected sibling) | Python module split, not image bake |
| Stage 5 `devcontainer-contributor-environment.md` (expected sibling) | Editor environment, not Compose image |

Out of scope:

- Rewriting Flask as FastAPI / adding a second helper service
- Copying `uploader.py` into the image as the only source of truth
- Removing the docker.sock mount or changing `CONTROL_TOKEN` auth
- Baking OS packages into `tika_minio_processor` (already done)

## Proposal

Give `helper_index` the same construction as the processor: a small in-repo Dockerfile that installs `docker-cli`, Compose v2, curl, and the three Python packages once, then keep the bind-mount for application code.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Image | `helper/Dockerfile` | Mirror processor: `FROM python:3-alpine` + `RUN apk` + `pip` |
| Compose | `helper_index.build` | Replace `image: python:3-alpine` + install `command:` |
| Source | `./helper:/app` | Keep bind-mount so edits do not require rebuild |
| Entry | `command:` / `CMD` | `python -B -u /app/uploader.py` only |
| CI | smoke / compose render | `docker compose build helper_index` must stay optional in docs-only CI |

### Rules

1. **Bake dependencies, not the control plane.** OS packages and `flask` / `requests` / `requests-unixsocket` belong in the image. Application Python stays on the bind-mount unless an operator explicitly chooses a copy-in profile.
2. **Reuse the processor Dockerfile shape.** Do not introduce BuildKit bake files, a private registry, or a multi-stage Node build for a Flask helper.
3. **Keep one container.** `ai_helper_index` remains the only helper API. Module splits from Stage 21 still import from this process.
4. **Air-gap friendly after first build.** A baked image must start without hitting apk/PyPI. Document that the **build** still needs network unless the image is already present.
5. **Do not bake docker.sock or `.env`.** Secrets and the host socket stay runtime mounts.
6. **Pin or document the base.** Prefer the same digest-pin policy as other images once the Dockerfile exists; a floating `python:3-alpine` tag is acceptable only as a first step with a follow-up pin.
7. **GitHub remains intake.** Requests for a rewritten helper stack stay Issues.

### Suggested contributor checklist

```text
1. Read helper_index in docker-compose.yml
2. Add helper/Dockerfile using the tika-minio-processor pattern
3. Move apk and pip lines from command: into Dockerfile RUN
4. Keep ./helper:/app and docker.sock mounts
5. Set command/CMD to python -B -u /app/uploader.py
6. Confirm CONTROL_TOKEN and allowlist mounts are unchanged
7. Note that compose build is required once after clone
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Helper image | In-repo Alpine Dockerfile | Distroless rewrite or a second API |
| Dep install | Build-time `RUN apk` / `pip` | Boot-time `command:` package install |
| Live code | Existing `./helper:/app` bind-mount | Baking source so every edit rebuilds |
| Pattern | `tika-minio-processor/Dockerfile` | A new image factory or bake stack |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add `helper/Dockerfile`, switch `helper_index` to `build: ./helper`, drop apk/pip from `command:`.
3. Optional: `./tu-vm.sh doctor` note when helper restart exceeds a short threshold (install-on-boot smell).

## Acceptance criteria

- [ ] Boot path no longer runs `apk` or `pip`.
- [ ] Flask entrypoint and bind-mount remain.
- [ ] Dockerfile follows the existing processor pattern.
- [ ] docker.sock, allowlist, and `CONTROL_TOKEN` are unchanged.
- [ ] Air-gap start works when the image is already built.

## Rollback

Restore `image: python:3-alpine` and the install `command:`. Delete or ignore `helper/Dockerfile`. Application routes and auth are unaffected.

## Success metrics

- `ai_helper_index` reaches listening state without Alpine/PyPI on restart.
- Contributors still edit `helper/*.py` without an image rebuild.
- No PR replaces the helper with a second control-plane service.
