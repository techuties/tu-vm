---
title: Helper Docker GID Group Add Contract
description: Constructional contract for Compose group_add of the host docker GID so a Stage 25 non-root helper can use the socket without staying root or inventing a custom ACL.
last_updated: 2026-08-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Helper Docker GID Group Add Contract

## Problem

Stage 25 asks first-party stateless services to set a numeric `user:`. `helper_index` is the exception: it bind-mounts `/var/run/docker.sock`, which is typically `root:docker` mode `660`. A non-root Flask process without the **docker group** gets `EACCES` on every `docker_get` / `docker_post`. The easy workaround — leave the helper as root — undoes Stage 25 for the process that has the largest blast radius.

Compose already has the knob: `group_add`. Docker adds supplementary groups to the container user. Passing the **host** docker GID lets `user: "1000:1000"` (or another numeric pair) open the socket without a custom ACL sidecar.

This page does not replace Stage 27 `docker-socket-proxy`. Proxy reduces **which API verbs** work. `group_add` reduces **who is root**. They stack.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `group_add` | Engine-supported supplementary groups |
| Compose `user:` | Stage 25 numeric non-root contract |
| `/var/run/docker.sock` bind on `helper_index` | Why GID matters |
| `helper/uploader.py` unix-socket session | Containers list / start / stop |
| Stage 18 `container-hardening-baseline-contract.md` (expected sibling) | cap_drop / no-new-privileges / socket review |
| Stage 25 `compose-nonroot-user-contract.md` (expected sibling) | Numeric `user:` leftover for helper |
| `env.example` | Home for `DOCKER_GID` |

Out of scope:

- Writing a custom socket ACL or `chmod 666` the host socket
- Adding the helper user to the **host** docker group as the default
- Changing CONTROL_TOKEN or control routes
- Implementing the proxy (sibling page)

## Proposal

Document and set `DOCKER_GID` from the host socket, then `group_add` it on `helper_index`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Env | `env.example` | `DOCKER_GID=` with comment `stat -c %g /var/run/docker.sock` |
| Compose | `helper_index.group_add` | `["${DOCKER_GID:?set DOCKER_GID to the host docker socket GID}"]` or a documented default |
| Compose | `helper_index.user` | Numeric, matching Stage 25 (after GID works) |
| Docs | this page + Stage 25 checklist | Helper is not exempt from `user:` once GID is set |
| Cloud agents | `AGENTS.md` / playbook | How to read the GID in Docker-in-Docker |

### Rules

1. **Do not chmod the socket.** `666` on `docker.sock` is not the community contract.
2. **Do not keep root "because 660".** Root is the leftover; `group_add` is the fix.
3. **GID is host-specific.** Defaulting to `999` is acceptable only with a comment and an `env.example` override. Prefer required interpolation once operators have the value.
4. **Numeric `user:` still required.** `group_add` without `user:` does nothing useful for a root process.
5. **Pair with Stage 18 `no-new-privileges`.** This page does not set `security_opt`.
6. **GitHub remains intake.** "Helper should use Kubernetes RBAC-style docker roles" stays an Issue.

### Suggested contributor checklist

```text
1. Add DOCKER_GID to env.example with a stat one-liner in the comment
2. Set helper_index.group_add to that GID
3. Set helper_index.user to a numeric pair (Stage 25)
4. Do not chmod 666 /var/run/docker.sock
5. Confirm /status still lists containers on a test stack
6. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Socket group | Compose `group_add` + `DOCKER_GID` | Host usermod or socket `666` |
| Non-root process | Stage 25 `user:` | Helper remains root |
| API verb allowlist | Sibling docker-socket-proxy page | A custom ACL written in Flask |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `DOCKER_GID` + `group_add` first, then numeric `user:`.
3. Optionally add the proxy in a follow-up so the helper never sees unused Docker verbs.

## Acceptance criteria

- [ ] `env.example` documents `DOCKER_GID` and how to read it.
- [ ] `helper_index` sets `group_add` from that value.
- [ ] `helper_index` sets numeric `user:` (Stage 25) once GID is wired.
- [ ] Host docker.sock mode is not changed to `666`.
- [ ] `/status` still works on a test stack.
- [ ] `docker compose config` still renders with current interpolation.

## Rollback

Remove `group_add` and restore root `user` if needed. Socket bind path is unchanged.

## Success metrics

- Helper is no longer the documented Stage 25 exception.
- Contributors stop proposing `chmod 666` in Issues.
- Non-root + GID + optional proxy is the default helper socket story.
