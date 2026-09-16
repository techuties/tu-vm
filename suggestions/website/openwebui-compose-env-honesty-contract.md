---
title: Open WebUI Compose Env Honesty Contract
description: Constructional contract to stop advertising unofficial Open WebUI Compose keys (WEBUI_JWT_SECRET_KEY, WEBUI_AUTH_SECRET, WEBUI_RATE_LIMIT*) that the pinned image may ignore, and to keep official WEBUI_SECRET_KEY as the real secret.
last_updated: 2026-09-16
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Open WebUI Compose Env Honesty Contract

## Problem

`open-webui` Compose currently sets several `WEBUI_*` keys that look official:

| Key today | Likely status vs official Open WebUI |
|---|---|
| `WEBUI_SECRET_KEY` | Official session/JWT secret |
| `WEBUI_AUTH` | Official |
| `WEBUI_JWT_SECRET_KEY` | Not a documented official key (duplicate of the real secret) |
| `WEBUI_AUTH_SECRET` | Not a documented official key |
| `WEBUI_RATE_LIMIT` / `WEBUI_RATE_LIMIT_WINDOW` | Not documented official rate-limit env |

`generate-secrets` and Stage 31 `check-config-secret-coverage-contract.md` already treat `WEBUI_JWT_SECRET_KEY` / `WEBUI_AUTH_SECRET` as if they were live secrets. Operators rotate three values and only one is consumed. Rate-limit keys suggest Nginx or Flask limits; edge limits actually live in `nginx/conf.d`.

This is distinct from Stage 31 `env-example-dead-keys-contract.md` (keys that appear only in `env.example` and are never passed to a container). These keys **are** passed to Open WebUI—they may simply do nothing.

Also distinct from Stage 31 `openwebui-public-url-contract.md` (`WEBUI_URL`) and Stage 32 signup (`ENABLE_SIGNUP`).

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment | Advertises the unofficial keys |
| `env.example` | `WEBUI_SECRET_KEY`, `WEBUI_JWT_SECRET_KEY`, `WEBUI_AUTH_SECRET` |
| `generate-secrets` / check-config | Stage 31 wants them in `--strict` |
| Nginx `conf.d` | Real rate limits |
| Official Open WebUI env docs | Source of truth for the pinned digest |
| Stage 10 Open WebUI contribution (expected sibling) | Broader config lane |
| Stage 31 dead env.example keys (expected sibling) | Unused example-only knobs |

Out of scope:

- Implementing a Flask rate limiter “because `WEBUI_RATE_LIMIT` exists”
- Rewriting Stage 31 `WEBUI_URL`
- Rewriting Stage 32 signup
- Adding Authentik because unused auth secret names exist

## Proposal

### Path A (preferred): delete unofficial keys

Remove `WEBUI_JWT_SECRET_KEY`, `WEBUI_AUTH_SECRET`, `WEBUI_RATE_LIMIT`, and `WEBUI_RATE_LIMIT_WINDOW` from Compose and `env.example`. Keep `WEBUI_SECRET_KEY` + `WEBUI_AUTH`. Drop the extra generate-secrets / check-config entries **or** keep them only as aliases that write `WEBUI_SECRET_KEY`.

### Path B: keep a key only with proof

A key may stay if the same PR cites the pinned Open WebUI env docs and a runtime check (`docker compose exec` / upstream settings) that the process reads it.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Path A delete or Path B cite |
| Env schema | `env.example` | Align with Compose |
| Scripts | `generate-secrets`, `check-config.sh` | One real WebUI secret |
| Docs | README | Rate limits → Nginx; session secret → `WEBUI_SECRET_KEY` |

### Rules

1. **Official docs win.** If the pinned image does not list the key, it does not belong in Compose.
2. **Do not invent products** to justify `WEBUI_RATE_LIMIT`.
3. **One session secret.** `WEBUI_SECRET_KEY` is enough unless upstream splits JWT.
4. **Stage 31 check-config** should not flag ghosts after Path A.
5. **GitHub remains intake.** New official keys arrive via Issue + docs cite.

### Suggested contributor checklist

```text
1. Open official env docs for the pinned Open WebUI digest
2. Grep WEBUI_JWT_SECRET_KEY WEBUI_AUTH_SECRET WEBUI_RATE_LIMIT
3. Remove unofficial keys or cite proof they are read
4. Keep WEBUI_SECRET_KEY + WEBUI_AUTH (+ Stage 31 WEBUI_URL, Stage 32 ENABLE_SIGNUP)
5. Align generate-secrets / check-config lists
6. nginx rate limits stay in conf.d
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Session secret | Official `WEBUI_SECRET_KEY` | Parallel JWT/auth secret env |
| HTTP rate limits | Existing Nginx config | Flask middleware “to use the env” |
| Schema discipline | Stage 12 + this honesty pass | Growing Compose env as a wishlist |
| Secret preflight | Stage 31 check-config | Flagging deleted keys forever |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Path A Compose/`env.example`/scripts alignment.
3. If Stage 31 check-config code lands first, update its unofficial WebUI names in the same follow-up.

## Acceptance criteria

- [ ] Unofficial keys are removed or proven live against the pinned image docs.
- [ ] `WEBUI_SECRET_KEY` remains the documented session secret.
- [ ] No new rate-limit or SSO product is added to justify leftover names.
- [ ] Stage 31 `WEBUI_URL` and dead `env.example` pages are not rewritten.

## Rollback

Restore the previous Compose env block. Runtime for official keys is unchanged.

## Success metrics

- Operators rotate one WebUI secret, not three.
- Issues titled “I set WEBUI_RATE_LIMIT and nothing happened” decline.
- check-config `--strict` matches keys the process actually reads.
