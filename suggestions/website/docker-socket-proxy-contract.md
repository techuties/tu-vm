---
title: Docker Socket Proxy Contract
description: Constructional contract for Tecnativa docker-socket-proxy in front of helper_index, reusing a mature allowlist image instead of a raw docker.sock bind or a custom ACL.
last_updated: 2026-08-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Docker Socket Proxy Contract

## Problem

`helper_index` bind-mounts the host Docker socket:

```yaml
- /var/run/docker.sock:/var/run/docker.sock
```

Flask then speaks the full Docker API as whichever user can open that file. The helper only needs **container list / inspect / start / stop** (see `docker_get`, `docker_post`, `docker_inspect` in `uploader.py`). Images, volumes, exec, swarm, and build are unused — and dangerous if the helper is RCE'd.

Stage 18 reviews "is this socket bind justified?". Stage 25/27 `user:` + `group_add` change **who** opens the file. Neither restricts **verbs**. Writing a Flask allowlist for Docker paths would reinvent a product the community already runs: [Tecnativa docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy).

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` unix-socket session | Today's transport |
| Helper control routes | start/stop + inspect only |
| `/containers/json` in `_live_container_health` | List only |
| Stage 18 hardening baseline (expected sibling) | Socket review checklist |
| Stage 25 non-root + this stage `group_add` | Process identity |
| Stage 15/8 image pin + update map | How to pin the proxy image |
| Compose IPAM registry (Stage 18) | Next free `172.20.0.0/16` address |

Out of scope:

- A custom Flask Docker ACL or `socat` one-liner as the default
- Giving the landing page raw Docker
- Compose operations from the helper (create/build). Host `docker compose` stays the creator
- Kubernetes-style RBAC

## Proposal

Add an internal-only proxy service and point the helper at it over TCP. Remove the helper's raw socket bind.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | new `docker-socket-proxy` service | Tecnativa image, digest-pinned, `restart: unless-stopped` |
| Proxy env | CONTAINERS=1, POST=1, INFO=1 | Everything else `0` (no BUILD, EXEC, IMAGES, NETWORKS, VOLUMES, AUTH) |
| Helper | `DOCKER_HOST` / code | HTTP to `http://docker-socket-proxy:2375` instead of `requests_unixsocket` |
| Helper volumes | drop `/var/run/docker.sock` | Proxy keeps the only socket bind |
| Updater | `OFFICIAL_UPDATE_IMAGE_PAIRS` | One row for the proxy image |
| IPAM | `172.20.0.0/16` | Next free address; do not reuse `0.30` (n8n-mcp collision history) |
| Network | proxy + helper only | Do not publish `2375` on the host |

### Rules

1. **Reuse Tecnativa (or an equivalent maintained proxy).** Do not write `helper/docker_acl.py`.
2. **Never publish 2375.** The proxy stays on `ai_network` without `ports:`.
3. **Pin the image.** Same digest story as Nginx. Add the pair to `tu-vm.sh`.
4. **Least verbs.** CONTAINERS + POST + INFO is the default grant. Add IMAGES/NETWORKS only with a recorded helper call that needs them.
5. **Helper code change is in scope.** Switching `requests_unixsocket` to TCP is the implementation, not a new framework.
6. **Keep CONTROL_TOKEN.** The proxy is not an auth replacement.
7. **GitHub remains intake.** "Helper should call the Docker Go SDK" stays an Issue.

### Suggested contributor checklist

```text
1. Add docker-socket-proxy service with a digest pin and no host ports
2. Set CONTAINERS=1 POST=1 INFO=1; leave BUILD/EXEC/IMAGES at 0
3. Allocate a unique 172.20.0.0/16 address (Stage 18 registry)
4. Point helper at tcp://docker-socket-proxy:2375 and drop the socket bind
5. Add the image to OFFICIAL_UPDATE_IMAGE_PAIRS
6. Confirm /status and /control start|stop still work
7. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Verb allowlist | Tecnativa docker-socket-proxy | Custom Flask ACL / socat |
| Who opens the socket | Stage 25 `user:` + `group_add` on the **proxy** | Helper keeps the raw bind |
| Pin / bump | Existing update map | Floating `:latest` proxy |
| Authz for start/stop | Existing CONTROL_TOKEN | Proxy as login |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: proxy service + helper transport change + drop helper socket bind.
3. Keep `group_add` on the **proxy** (it owns the bind). Helper no longer needs the docker GID after the cutover.

## Acceptance criteria

- [ ] A digest-pinned socket-proxy service exists with no host `ports:`.
- [ ] Default grants are CONTAINERS/POST/INFO only.
- [ ] `helper_index` does not mount `/var/run/docker.sock`.
- [ ] `/status` and token-guarded `/control/…/start|stop` still work on a test stack.
- [ ] Unauthenticated `/control` remains 401.
- [ ] `docker compose config` still renders with current interpolation.

## Rollback

Restore the helper unix-socket bind and remove the proxy service. CONTROL_TOKEN is unchanged.

## Success metrics

- Helper CVE / RCE write-ups no longer include "full Docker API via the socket".
- Contributors add proxy env flags instead of proposing `helper/docker_acl.py`.
- Socket binds in Compose are limited to the proxy (and documented exceptions).
