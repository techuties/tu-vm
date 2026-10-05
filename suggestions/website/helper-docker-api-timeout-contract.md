---
title: Helper Docker API Timeout Contract
description: Constructional contract so helper container stop waits long enough for the Engine's default stop, instead of failing the HTTP client at 5 seconds.
last_updated: 2026-10-05
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Helper Docker API Timeout Contract

## Problem

Dashboard Start and Stop call `control_service`, which talks to the Docker Engine over the socket:

```python
def docker_post(path):
    url = f"http+unix://{requests.utils.quote(DOCKER_SOCK, safe='')}" + path
    return DOCKER_SESSION.post(url, timeout=5)
```

Stop uses that helper with no wait parameter:

```python
r = docker_post(f"/containers/{container}/stop")
```

`POST /containers/{id}/stop` accepts `t`, the number of seconds to wait before the daemon kills the process. When `t` is omitted and the container has no stop timeout, the Linux daemon default is 10 seconds. `docker-compose.yml` sets no `stop_grace_period` on these services, so that default applies unless the daemon's own `default-stop-timeout` was changed.

The HTTP client timeout is 5 seconds. For a container that does not exit inside that window, `requests` raises before the Engine returns 204. `control_service` catches the exception and answers:

```python
return jsonify({'ok': False, 'error': str(e)}), 500
```

The landing page then shows that body as a failure and re-enables the buttons. The daemon can still be waiting out its own 10 second stop. A second click races that in-flight stop.

Start uses the same 5 second client. Start usually returns as soon as the process is created, so stop is the call that systematically exceeds the client. Both calls should share one budget that is longer than the wait the request asks for.

Checked on 2026-10-05 in `helper/uploader.py` (`docker_post`, `docker_get`, the stop branch of `control_service`) and `docker-compose.yml` (no `stop_grace_period`). The button was not clicked against a live daemon.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker_post` / `docker_get` | The only Engine client the helper has |
| `control_service` stop branch | The call that omits `t` |
| Dashboard `controlService` | Surfaces a non-OK body as `Failed:` |
| Compose `restart` and `depends_on` | Unchanged. Stage 50 owns AFFiNE start going through `docker compose up` |
| Stage 50 `affine-compose-start-contract.md` (expected sibling, open PR #76) | Which command starts AFFiNE. Not the HTTP timeout on the socket client |
| Stage 42 `helper-control-service-allowlist-contract.md` (expected sibling, open PR #68) | Which names may be started. Not how long the call waits |

Out of scope:

- Replacing the socket client with a shell-out to `docker stop`
- Adding `stop_grace_period` for every service in one pass
- The AFFiNE dependency group (Stage 50)
- The control allowlist (Stage 42, PR #68)

## Proposal

Keep the unix-socket client. Make the stop request's wait shorter than the client timeout, and set that client timeout in one place.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Stop URL | `control_service` | Call `/containers/{id}/stop?t=10` only if the client timeout is greater than 10. A matching pair that fits today's code is `t=8` and `timeout=20` on that POST |
| Client | `docker_post` | Pass a timeout argument so status GETs can stay short while stop is long. Do not leave stop on the 5 second default |
| Start | start branch | Use the longer POST timeout as well, so a slow daemon response is not reported as a failed start |
| Errors | `except` around the POST | On timeout, return a message that names the container and says the Engine call timed out. Keep HTTP 500 so the dashboard still shows failure when the daemon truly did not answer |
| Compose | unchanged | Do not add a second orchestrator |

### Rules

1. **The client waits longer than `t`.** If `t` is 8, the POST timeout is at least 15 seconds so the 204 can arrive.
2. **Pass `t` explicitly.** Do not depend on the Engine default staying at 10 while the client stays at 5.
3. **GETs stay short.** `docker_get` for inspect and `/containers/json` can keep a few-second timeout. Only the start and stop POSTs need the longer budget.
4. **Do not shell out.** `./tu-vm.sh stop-service` remains the Compose path. The dashboard handler stays on the Engine API it already uses, except where Stage 50 replaces the AFFiNE start command.
5. **Do not widen the allowlist.** Timeout changes apply only to names `control_service` already accepts.
6. **A timeout is still an error.** Returning 200 because the request was sent is how a later refresh lies about state. The dashboard poll after a real 204 is the success path.

### Suggested contributor checklist

```text
1. Read docker_post timeout and the stop URL
2. Pass t and a longer POST timeout with timeout > t
3. Stop a running Tier 2 container from the dashboard and confirm HTTP 200 and a 204 from the Engine
4. Confirm a missing container still returns 404
5. Confirm docker_get inspect still uses a short timeout
6. Do not add a docker CLI wrapper
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stop | Engine `POST /containers/{id}/stop?t=` | `subprocess` `docker stop` |
| Start | Same client, longer POST budget | A new controller |
| Operator CLI | `./tu-vm.sh stop-service` | Duplicating that shell path inside Flask |
| Failure | Existing dashboard `Failed:` toast | Reporting success on timeout |

## Acceptance criteria

- The stop request includes an explicit `t`.
- The POST timeout used for that request is greater than `t`.
- A container that exits within `t` returns the helper's existing success JSON (`ok: true`).
- A client timeout still returns a non-OK JSON body.
- `docker_get` is not raised to the stop budget.
- No new process runner is added to `helper/uploader.py`.

## Verification notes

Read `docker_post(..., timeout=5)` and the stop path with no `t` on 2026-10-05. Compose has no `stop_grace_period`. Docker's CLI reference documents a 10 second Linux default when the container has no stop timeout. The live button was not pressed.

## Rollback

Restore `timeout=5` and the stop path with no `t`.
