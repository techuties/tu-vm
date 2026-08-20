---
title: Helper Uploader Module Contribution Contract
description: Constructional contract for splitting helper/uploader.py into importable modules while keeping one Flask app, one /status/full contract, and the existing helper_index container.
last_updated: 2026-08-20
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Helper Uploader Module Contribution Contract

## Problem

`helper/uploader.py` is a single Flask module (~1000 lines) that owns Docker socket calls, allowlist I/O, announcements, update checks, service control, and every `/status/*` probe. The landing dashboard and Nginx `proxy_pass http://helper_index:9001/…` depend on this file remaining the process entrypoint.

Stage 7 describes how to evolve the **HTTP contract** (`/status/full` shape, fixtures, helper-contract-check). It does not tell contributors how to add a Python module without forking a second app.

Community PRs that need a new helper concern tend to append more functions to `uploader.py`, or propose FastAPI / a rewrite in a new package.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` | Sole Flask app; `app.run(host='0.0.0.0', port=9001)` |
| `helper/chat-context/` | Seed text/JSON, not Python packages |
| `docker-compose.yml` `helper_index` | `python -B -u /app/uploader.py` in `python:3-alpine` |
| `fixtures/status-full-contract.json` | Canonical `/status/full` shape |
| `scripts/validate_status_full_contract.py` | Static contract check |
| `scripts/helper-contract-check.sh` | Live JSON probes when the helper is up |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | Route and payload compatibility |
| Stage 17 `helper-contract-check-contribution-contract.md` (expected sibling) | Live probe script |
| Stage 18 `helper-control-auth-contract.md` (expected sibling) | `CONTROL_TOKEN` / 401 behavior |

Out of scope:

- Replacing Flask with FastAPI, Quart, or a new language
- A second helper container or port
- Changing `/status/full` fields (use Stage 7)
- Moving control-plane auth (use Stage 18)

## Proposal

Allow **in-tree Python modules** under `helper/` that `uploader.py` imports, so day-to-day contributions stay reviewable without a rewrite.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Entrypoint | `helper/uploader.py` | Stays the Compose command target |
| Packages | `helper/*.py` or `helper/lib/` | Importable modules, no new process |
| Routes | Existing `@app.route` | New routes register on the same `app` |
| Tests | `python3 -m py_compile helper/*.py` | Syntax gate in CI/smoke |
| Contract | Existing fixtures + helper-contract-check | Behavior unchanged after a split |

### Suggested first split (optional, incremental)

| Module | Owns |
|---|---|
| `docker_client.py` | `docker_get` / `docker_post` / `docker_inspect` / unix-socket session |
| `allowlist.py` | Read/write `control_allowlist.conf` and IP normalization |
| `auth.py` | `_authorized` / `CONTROL_TOKEN` header-first checks |
| `status_probes.py` | Per-service `/status/<name>` helpers |
| `uploader.py` | Flask `app`, route table, `if __name__` |

Do not split everything in one PR. Move one cohesive concern, keep imports lazy-safe, and prove `/status/full` still matches the fixture.

### Rules

1. **One process.** Compose must still run `python -B -u /app/uploader.py`.
2. **One `app`.** Modules may receive the Flask app or register blueprints; they must not start a second server.
3. **No new dependencies** unless the Alpine `pip install` line in Compose is updated in the same PR.
4. **Contract first.** Any split that changes JSON keys fails `validate_status_full_contract.py` and helper-contract-check.
5. **Stdlib + current pip set.** Flask, requests, requests-unixsocket only unless justified.
6. **GitHub remains intake.** “Rewrite the helper in FastAPI” stays an Issue, not a drive-by module PR.

### Suggested contributor checklist

```text
1. Read Stage 7 helper API contract and the fixture
2. Pick one cohesive concern (docker client, allowlist, or probes)
3. Add helper/<module>.py and import it from uploader.py
4. Keep CONTROL_TOKEN and docker.sock behavior identical
5. python3 -m py_compile helper/*.py
6. Run validate_status_full_contract.py
7. If helper is up, run helper-contract-check.sh
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| HTTP framework | Existing Flask app | FastAPI / a second service |
| Docker API | Existing unix-socket session | docker-py unless Compose pip changes |
| Validation | Existing fixture + helper-contract-check | A new OpenAPI portal |
| Packaging | Plain modules next to `uploader.py` | Publishing `helper` to PyPI |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: extract one module (docker client is the smallest) and add `python3 -m py_compile helper/*.py` to CI/smoke if missing.
3. Optional: a one-line `helper/README` listing module ownership (only if maintainers want it; do not create a second docs tree).

## Acceptance criteria

- [ ] `uploader.py` remains the Compose entrypoint.
- [ ] New Python lives under `helper/` and is imported, not copy-pasted.
- [ ] `/status/full` fixture and auth behavior stay stable.
- [ ] FastAPI / second helper container are out of scope.

## Rollback

Delete the new module and inline the functions back into `uploader.py`. Restore the previous Compose command if it changed. Nginx routes are unaffected.

## Success metrics

- Helper PRs can land without growing a single file unbounded.
- `py_compile` covers every helper module in CI.
- Dashboard status and control routes keep working after each extract.
