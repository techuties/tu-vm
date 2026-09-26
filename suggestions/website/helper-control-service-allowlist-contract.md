---
title: Helper Control Service Allowlist Contract
description: Constructional contract to reject unknown /control service names before they are sent to the Docker Engine API, reusing the existing name map and CONTROL_TOKEN check.
last_updated: 2026-09-26
owner: maintainers
status: proposed
theme: security
impact: high
---

# Helper Control Service Allowlist Contract

## Problem

`POST /control/<service>/<action>` in `helper/uploader.py` authenticates with `CONTROL_TOKEN`, then looks up `service` in `name_map`. When the name is missing, the handler uses the raw path segment as a Docker container name:

```text
container_info = name_map.get(service)
if container_info:
    container, compose_service = container_info
else:
    container = service
    compose_service = service
```

`docker_post(f"/containers/{container}/start")` then talks to the host socket mounted at `/var/run/docker.sock`. A caller who already has the control token and passes the Nginx allowlist can start or stop **any** container the engine can see, including containers that are not part of TU-VM. A typo does not return 400. It becomes a Docker API call.

Stage 18 `helper-control-auth-contract.md` (expected sibling) owns the token, the 401 when the token is missing, and the preference for `X-Control-Token`. This page only closes the **name fallthrough**. It does not remove dashboard control of `postgres`, `nginx`, or the other names already in the map.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` `name_map` | The allowlist that already exists |
| `_authorized()` | Deny when `CONTROL_TOKEN` is empty; compare when it is set |
| `scripts/helper-contract-check.sh` | Unauthenticated `POST /control/nginx/stop` must stay 401 |
| Nginx `location /control/` | Source-IP allowlist in front of the helper |
| Stage 18 helper control-auth (expected sibling) | Token and 401 behavior |
| Stage 5 control-plane contribution (expected sibling) | Allowlist file and include |
| Stage 17 helper-contract-check (expected sibling) | How to extend the probe |

Out of scope:

- OAuth, SSO, or a second control API
- Removing intentional map entries (`postgres`, `redis`, `nginx`, helper, processor, MCP tools)
- A policy engine that decides which operator may stop which container
- Changing Docker socket proxy work from Stage 27

## Proposal

After `_authorized` succeeds, if `service` is not a key of `name_map`, return **400** with `unknown service` and do not call Docker. Keep using the mapped container name for the Engine API path. Do not interpolate the request path into `/containers/...`.

Auth stays first. An unknown name **without** a token remains **401**, so anonymous callers do not learn which names are valid.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Handler | `control_service` | 400 on map miss; no Docker call |
| Probe | `scripts/helper-contract-check.sh` | With the helper up, unknown name + token → 400; no token → 401 |
| Docs | playbook or this page | Dashboard names are the map, not arbitrary container IDs |

### Rules

1. **The map is the allowlist.** New dashboard buttons add a map entry in the same PR.
2. **Auth before the map.** Missing token stays 401 even for unknown names.
3. **No path interpolation.** The Engine URL is built only from mapped container names.
4. **Do not shrink the map** in this change. Stopping Postgres from the dashboard is existing behavior.
5. **GitHub remains intake.** A request to control a new container is an Issue, then a map entry.

### Suggested contributor checklist

```text
1. Read control_service and the else branch that assigns container = service
2. Return 400 when name_map.get(service) is missing, after _authorized
3. Leave unauthenticated /control/nginx/stop as 401
4. Add a contract-check note for /control/not-a-real-container/start
5. Do not add a new orchestrator or SSO
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Who may call | Existing `CONTROL_TOKEN` + Nginx allowlist | SSO |
| Which names | Existing `name_map` | Raw path segment as a container ID |
| Proof | Existing `helper-contract-check.sh` | A new test framework |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: the 400 branch in `control_service`, then extend the contract check when `ai_helper_index` is up.
3. Roll back by restoring the previous else branch. Mapped names behave as they do today.

## Acceptance criteria

- [ ] Unknown `service` with a valid token returns 400 and does not call the Docker socket.
- [ ] Unknown `service` without a token returns 401.
- [ ] `POST /control/nginx/stop` without a token still returns 401.
- [ ] Names already in `name_map` still start and stop the mapped container.
- [ ] Stage 18 token rules are not rewritten.

## Rollback

Restore the else branch. Mapped dashboard buttons keep working.

## Success metrics

- A mistyped service name is a 400, not a Docker 404 against an unrelated container.
- Contract-check output names both the 401 case and the unknown-name case.
- Issues titled "the dashboard stopped a container I did not add" decline.
