---
title: Redis Healthcheck Auth Env Contract
description: Constructional contract for REDISCLI_AUTH (or redis-cli --no-auth-warning) so the platform Redis probe does not put the password on the process argv.
last_updated: 2026-08-30
owner: maintainers
status: proposed
theme: security
impact: high
---

# Redis Healthcheck Auth Env Contract

## Problem

Platform Redis already uses `--requirepass`. The healthcheck then puts that password on the **command line**:

```yaml
test: ["CMD-SHELL", "redis-cli -a \"${REDIS_PASSWORD:-redis_password_2024}\" ping | grep -q PONG || exit 1"]
```

Anyone who can `docker inspect ai_redis`, read `compose` config output, or see `/proc/<pid>/cmdline` during the probe sees the secret. `ps` inside the container does too. This is distinct from “Redis has no ACL file” (Stage 24) and distinct from “AFFiNE Redis has no password” (Stage 28).

Official `redis-cli` reads `REDISCLI_AUTH`. That is the framework we should reuse.

`affine_redis` currently has no password (Stage 28). When that lands, its probe must use the same env pattern — not a second `-a` copy.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `redis` `command` `--requirepass ${REDIS_PASSWORD}` | Real auth |
| Healthcheck `redis-cli -a ... ping` | Leaks argv |
| Official Redis `REDISCLI_AUTH` | Password via environment |
| Stage 24 `redis-acl-users-contract.md` (expected sibling) | Optional ACL **users** file |
| Stage 28 `affine-redis-requirepass-contract.md` (expected sibling) | Give AFFiNE Redis a password |
| `env.example` `REDIS_PASSWORD` | Clone-path secret |

Out of scope:

- Removing `requirepass`
- Sharing `ai_redis` with AFFiNE
- A helper `/status/redis` that runs `INFO` with the password
- Switching the probe to a TCP connect without AUTH (false healthy)

## Proposal

Keep `CMD-SHELL` if needed for `grep`, but stop passing `-a`.

```yaml
healthcheck:
  test:
    [
      "CMD-SHELL",
      "REDISCLI_AUTH=\"${REDIS_PASSWORD:-redis_password_2024}\" redis-cli ping | grep -q PONG || exit 1",
    ]
  interval: 180s
  timeout: 10s
  retries: 2
```

Prefer a `CMD` exec form if the image entrypoint can inject `REDISCLI_AUTH` via Compose `environment` **only for the probe**. Compose cannot set probe-only env natively, so inlining `REDISCLI_AUTH=...` in the test is acceptable. It still appears in compose config, but **not** in `ps` argv as `-a <password>`.

When Stage 28 requirepass lands:

```yaml
# affine_redis
test: ["CMD-SHELL", "REDISCLI_AUTH=\"${AFFINE_REDIS_PASSWORD}\" redis-cli ping | grep -q PONG || exit 1"]
```

Do not leave `redis-cli ping` unauthenticated on a passworded instance (false unhealthy or false healthy depending on `default_user`).

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose `redis` | `healthcheck.test` | `REDISCLI_AUTH`, no `-a` |
| Compose `affine_redis` | after Stage 28 | same pattern |
| Docs | this page + Stage 24 | ACL file does not fix argv leak |
| CI | none | No secret in logs; do not print `compose config` in public CI artifacts |

### Rules

1. **Use `REDISCLI_AUTH`.** Do not add `-a` on new probes.
2. **Still require PONG.** A TCP open is not liveness.
3. **Do not log the test string** in smoke scripts.
4. **Stage 24 ACL is additive.** An ACL user for healthchecks (`healthcheck` + `+ping`) is a later tightening, not a blocker.
5. **GitHub remains intake.** Requests for a Redis exporter on Tier 1 stay Stage 19 opt-in.

### Suggested contributor checklist

```text
1. Replace redis-cli -a with REDISCLI_AUTH=... redis-cli ping
2. Keep grep -q PONG (or redis-cli --raw)
3. Do not print the interpolated command in scripts
4. After Stage 28, apply the same pattern to affine_redis
5. Confirm docker compose config still renders
6. docker inspect healthcheck and confirm -a is gone
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| CLI auth | Official `REDISCLI_AUTH` | `redis-cli -a` or `printf` to a world-readable file |
| User separation | Stage 24 ACL file | A custom auth proxy in front of Redis |
| AFFiNE Redis | Stage 28 `requirepass` + this probe | Sharing platform Redis |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one-line healthcheck change on `redis`.
3. Recreate or restart `ai_redis` so the new test is picked up.

## Acceptance criteria

- [ ] Platform Redis healthcheck has no `-a` flag.
- [ ] Probe still expects `PONG` using `REDISCLI_AUTH`.
- [ ] Steady-state `interval` remains 180s.
- [ ] No Redis password is added to helper JSON or dashboard HTML.
- [ ] `docker compose config` still renders.

## Rollback

Restore the `-a` test string. Auth and data are unchanged. The argv leak returns.

## Success metrics

- `docker inspect ai_redis --format '{{json .Config.Healthcheck}}'` contains no `-a`.
- Contributors copy `REDISCLI_AUTH` into any new Redis probe (including AFFiNE).
- Secret-rotation reviews stop flagging the healthcheck as a second password leak path.
