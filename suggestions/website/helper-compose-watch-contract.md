---
title: Helper Compose Watch Contract
description: Constructional contract for Docker Compose develop.watch (or the existing helper bind-mount) so contributors sync Flask code without baking source or replacing the Dev Container.
last_updated: 2026-08-21
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Helper Compose Watch Contract

## Problem

`helper_index` already bind-mounts live source:

```text
volumes:
  - ./helper:/app
```

There is no Compose `develop.watch` / `docker compose watch` story. Contributors who rebuild after every `uploader.py` edit, or who copy files into a baked image, lose the day-to-day loop. Community PRs tend to propose a hot-reload PaaS, Air, or replacing the helper with a watched FastAPI process.

Stage 5 covers **Dev Containers / Codespaces**. Stage 21 covers **module splits**. The bake contract (this stage) covers **OS/pip in the image**. This page is **how application files reach the running container**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./helper:/app` | Bind-mount already syncs host edits |
| `python -B -u /app/uploader.py` | Unbuffered; no Flask debug reloader today |
| `tika-minio-processor` | Built image + copied `.py` (rebuild to change code) |
| Stage 5 `devcontainer-contributor-environment.md` (expected sibling) | Editor/toolchain, not Compose watch |
| Stage 21 `helper-uploader-module-contribution-contract.md` (expected sibling) | Module layout |
| This stage `helper-index-image-bake-contract.md` | Bake deps; keep source on the mount |

Out of scope:

- Flask debug mode on LAN production (`debug=True` is not a contributor tool)
- A file-sync sidecar (Mutagen, docker-sync) as a required install
- Watching the entire repo into the helper (compose file is already `:ro` mounted for path resolution)
- Replacing Dev Container with Compose watch

## Proposal

Treat the **bind-mount as the default sync**. Document it. Add optional Compose `develop.watch` only for contributors who use `docker compose watch` and need an explicit restart when new modules appear—without a new live-reload product.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default sync | `./helper:/app` | Already live; document in CONTRIBUTING |
| Optional watch | `develop.watch` on `helper_index` | `action: sync` + `action: restart` for new files |
| Entrypoint | `python -B -u` | Keep; do not enable Flask debug in compose |
| Bake | `helper/Dockerfile` | Deps only; do not COPY over the mount in the default profile |
| Docs | CONTRIBUTING + this page | “Edit helper/*.py, refresh dashboard; no rebuild” |

### Rules

1. **Bind-mount stays the default.** Watch is an accelerator, not a replacement. Removing `./helper:/app` in favor of watch-only sync is a regression.
2. **Reuse Compose Watch.** Official `develop.watch` in Compose v2. Do not add Air, realize, or a Node file watcher for Python.
3. **Restart, do not debug-reload.** Flask’s reloader can double processes and confuse docker.sock clients. Prefer `sync+restart` if watch is added.
4. **Ignore secrets and caches.** Watch paths must be `helper/**/*.py` (and templates if any), not `.env`, `ssl/`, or `__pycache__`.
5. **Do not watch the project root into `/app`.** The existing `.:/docker-project:ro` mount is for Compose path resolution, not live editing.
6. **Distinct from Dev Container.** Watch runs on a host that already has Docker. Codespaces still follow Stage 5.
7. **GitHub remains intake.** Requests for a cloud PaaS reload stay Issues.

### Suggested contributor checklist

```text
1. Confirm ./helper:/app is present on helper_index
2. Document that Python edits do not need compose build
3. If adding develop.watch, sync helper/*.py and restart on change
4. Do not set Flask debug=True in compose
5. Do not COPY uploader.py in a way that shadows the mount
6. Leave docker.sock and allowlist mounts unchanged
7. Point editor setup at Stage 5, not this page
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Live edits | Existing bind-mount | Baking source as the only path |
| Explicit restart | Compose `develop.watch` | Air / Nodemon / a sync sidecar |
| Editor env | Stage 5 Dev Container | Treating watch as a Codespace |
| Modules | Stage 21 helper packages | A second Flask app for reload |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **docs/code**: CONTRIBUTING bullet that helper bind-mount is live; optional `develop.watch` block commented in compose.
3. Optional: smoke note that `helper/uploader.py` is mounted, not copied, in the default service.

## Acceptance criteria

- [ ] Bind-mount remains the default sync mechanism.
- [ ] Watch, if added, uses Compose `develop.watch` only.
- [ ] Flask debug is not enabled in compose.
- [ ] Bake and Dev Container contracts stay distinct.
- [ ] Secrets and the project root are not watch targets.

## Rollback

Remove `develop:` / `watch:` keys. `./helper:/app` continues to sync. Image bake and Dev Container files are unaffected.

## Success metrics

- Contributors change helper routes without `docker compose build`.
- No PR adds a live-reload sidecar or Flask debug on the LAN default.
- Bake-vs-mount confusion is answered by this page plus the bake contract.
