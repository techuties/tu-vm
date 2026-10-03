---
title: Open WebUI Init Hook Unwired Contract
description: Constructional contract to run scripts/init-openwebui.sh as the Open WebUI entrypoint so the image command bash start.sh still starts the app.
last_updated: 2026-10-03
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Open WebUI Init Hook Unwired Contract

## Problem

`docker-compose.yml` bind-mounts the init script and never runs it:

```yaml
volumes:
  - ./scripts/init-openwebui.sh:/init-openwebui.sh:ro
```

The `open-webui` service has no `entrypoint` and no `command`. Git records `scripts/init-openwebui.sh` as mode `100755`. The script prints that it is applying a TikaLoader fix, then ends with:

```bash
echo "🚀 Starting Open WebUI with TikaLoader fix..."
exec "$@"
```

That `exec` only matters when the script is the entrypoint and the image command arrives as `"$@"`.

The pinned image is `ghcr.io/open-webui/open-webui@sha256:7f1b0a1a50cfbac23da3b16f96bc968fd757b26dc9e54e93813d61768ea9184e`. Its linux/amd64 manifest config blob is `sha256:dc8363bef648a0538fca54ee0723dcdb18aa4c6e5c28ec564977165949d7dab6`, fetched from GHCR on 2026-10-03:

| Field | Value |
|---|---|
| Entrypoint | empty |
| Cmd | `bash start.sh` |
| WorkingDir | `/app/backend` |
| User | `0:0` |

Docker therefore starts `bash start.sh` inside `/app/backend`. Nothing in that command reads `/init-openwebui.sh`. README still lists the file as "Open WebUI init hook".

The script already refuses to break startup when the upstream loader text has moved: if the PyPDFLoader snippet is missing it prints a warning and exits 0. That safety only helps after the script is actually invoked.

Checked by reading Compose, the script, `git ls-files -s`, and the image config blob. The container was not started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/init-openwebui.sh` | Wrapper that patches, then `exec`s the real command |
| Compose volume at `/init-openwebui.sh` | The mount, already read-only |
| Image Cmd `bash start.sh` | The process the wrapper must keep |
| `CONTENT_EXTRACTION_ENGINE` and `TIKA_SERVER_URL` | The runtime Tika settings Compose already sets |
| Stage 15 init/first-boot contract (expected sibling) | How to patch the loader idempotently |
| Stage 48 Tika readiness contract (expected sibling, PR #74) | When Tika is actually listening |

Out of scope:

- Forking `ghcr.io/open-webui/open-webui` to bake the patch
- Editing `tika-config.xml` (Stage 19, open PR #45)
- Rewriting the PyPDFLoader search string on this page
- A new first-boot service beside Open WebUI

## Proposal

Make the existing script the entrypoint and leave the image command alone.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Entrypoint | `open-webui` service | `entrypoint: ["/init-openwebui.sh"]` |
| Command | Same service | Leave `command` unset so the image Cmd `bash start.sh` becomes the script's arguments |
| Mount | Existing volume | Keep `:ro`. The script is already executable |
| Patch body | `scripts/init-openwebui.sh` | Keep the current "continue if the snippet moved" exit 0 |
| Docs | README tree line | Say the file is the container entrypoint |

Compose `entrypoint` replaces an image entrypoint. This image's entrypoint is empty, so the only process change is "run the script, then `exec`" the existing Cmd. Setting `command` as well would drop `bash start.sh` unless the new command repeats it. Prefer omitting `command`.

### Rules

1. **The wrapper execs the image Cmd.** After the patch attempt, the process image must be `bash start.sh` from `/app/backend`. Confirm with `docker inspect` `Path` and `Args` on a running container before merge.
2. **A missing snippet is a warning, not a failed boot.** Keep the exit 0 path. A changed upstream file must not make `depends_on` health fail.
3. **Re-check the Cmd when the digest changes.** `./tu-vm.sh update` bumps the pin. The entrypoint line stays. The Cmd inside the new config blob must still be what `"$@"` execs. Record the new Cmd in the pull request when it changes.
4. **Do not add a second init container.** Open WebUI is the process that needs the patched file inside its own filesystem.
5. **Leave the patch text to Stage 15.** This page only connects the mount to process 1.

### Suggested contributor checklist

```text
1. Set open-webui entrypoint to ["/init-openwebui.sh"]
2. Leave command unset and confirm image Cmd is still bash start.sh
3. Start the container and read docker inspect Path and Args
4. Confirm the log line from the script appears before Open WebUI serves /health
5. Confirm a missing PyPDFLoader snippet still reaches a healthy Open WebUI
6. Update the README line that calls the file a hook so it names the entrypoint
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| First-boot work | `scripts/init-openwebui.sh` | A derived Open WebUI image |
| Process start | Image Cmd `bash start.sh` | A hand-written start command |
| Failure mode | Existing exit 0 when the snippet moved | A crash loop on upstream drift |
| Intake | GitHub Issue | A local boot-script registry |

## Acceptance criteria

- `docker inspect` on `ai_openwebui` shows the init script as the entrypoint and `bash start.sh` as the arguments.
- Container logs include the script's start line.
- Open WebUI still becomes healthy when the loader snippet is absent.
- The Compose service still has no extra init container.

## Verification notes

Image config was read from GHCR on 2026-10-03 (linux/amd64 manifest `sha256:9856d2e55452708a5cef79cf3ca0a80f859137167b195faf46e3275b665b8d65`, config blob `sha256:dc8363bef648a0538fca54ee0723dcdb18aa4c6e5c28ec564977165949d7dab6`). Docker was not running, so the running-container inspect in the checklist is still required before the Compose change merges.

## Rollback

Remove the `entrypoint` key. The image Cmd starts Open WebUI directly again. The bind mount can stay; it is inert without the entrypoint.
