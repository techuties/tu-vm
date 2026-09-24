---
title: Open WebUI JWT Expiry Contract
description: Constructional contract to pin official JWT_EXPIRES_IN=4w and to forbid 0 and -1, both of which disable expiry in the pinned Open WebUI image.
last_updated: 2026-09-24
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI JWT Expiry Contract

## Problem

The pinned Open WebUI image sets `JWT_EXPIRES_IN` as a `ConfigVar` (`auth.jwt_expiry`). The default string is `4w`.

`backend/open_webui/utils/misc.py` `parse_duration` returns `None` when the string is `0` or `-1`. Callers treat `None` as no expiry. The startup warning in `config.py` mentions only `-1`. `0` is the same footgun without that log line.

Compose does not set the key. A later "convenience" edit to `-1` or `0` would mint session tokens that do not expire, on a UI reached through `oweb.tu.lan` with `WEBUI_AUTH=true`.

Four weeks is the upstream default and matches day-to-day use on a single operator machine. This page pins that default in Compose so the non-expiring values are an explicit change, not an empty slot.

This is not Stage 36 cookie `Secure` / `SameSite`. Those keys describe the cookie attributes. This key is the token lifetime.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `config.py` | Default `4w`; warning text covers `-1` only |
| Pinned `parse_duration` | `0` and `-1` both return `None` |
| `WEBUI_SECRET_KEY` | Official session secret (Stage 32 honesty). Rotating it invalidates tokens regardless of this duration |
| Stage 36 session cookie contract (expected sibling) | `Secure` and `SameSite`, not lifetime |
| Stage 36 PersistentConfig (expected sibling) | Stored admin values override this ConfigVar |
| GitHub Issues | Place to choose a shorter lifetime |

Out of scope:

- A custom session table, refresh-token service, or login gateway
- Shortening `4w` to a daily re-login (that is an Issue if a shared machine needs it)
- Stage 8 secret rotation procedure
- OAuth session limits (`OAUTH_MAX_SESSIONS_PER_USER`); OAuth signup stays off unless an Issue asks for it

## Proposal

Pin the official default on the `open-webui` service:

```text
JWT_EXPIRES_IN: "4w"
```

`parse_duration` accepts `ms`, `s`, `m`, `h`, `d`, and `w`. `4w` is four weeks. Do not set `0` or `-1`.

The key is a `ConfigVar`. After the first successful start, a stored admin value wins over a later Compose edit unless Stage 36 PersistentConfig is implemented in **code**.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | `JWT_EXPIRES_IN: "4w"` |
| Env schema | `env.example` | Comment that `0` and `-1` disable expiry |
| Docs | Open WebUI playbook | Shorter lifetimes are an Issue, not a silent Compose edit |
| Persistence | Stage 36 | Implement in code so the pin survives Admin saves |

### Rules

1. **Official key only.** Do not add a session store.
2. **Never `0` or `-1`.** Both mean no expiry in this revision. The log warning covers only `-1`.
3. **Keep `4w` unless an Issue says otherwise.** Daily re-login is friction, not a default.
4. **Cookie flags stay on the Stage 36 page.**
5. **GitHub remains intake** for `12h`, `7d`, or another `parse_duration` string.

### Suggested contributor checklist

```text
1. Confirm parse_duration still returns None for 0 and -1
2. Set JWT_EXPIRES_IN=4w on the open-webui service
3. Recreate Open WebUI
4. Confirm a fresh login token carries an expiry about four weeks out
5. Confirm 0 and -1 are absent from Compose and env.example
6. Leave Stage 36 cookie Secure / SameSite unchanged
7. If Admin already stored a lifetime, apply Stage 36 in code or update the stored config on purpose
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Token lifetime | Official `JWT_EXPIRES_IN` | A session database |
| Cookie attributes | Stage 36 cookie contract | Folding Secure/SameSite into this page |
| Secret rotation | Existing `WEBUI_SECRET_KEY` | A second JWT secret (Stage 32 already rejected `WEBUI_JWT_SECRET_KEY`) |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, an `env.example` comment, and an Open WebUI recreate.
3. A shorter lifetime needs an Issue.

## Acceptance criteria

- [ ] `open-webui` sets `JWT_EXPIRES_IN=4w`.
- [ ] Compose and `env.example` do not set `0` or `-1`.
- [ ] Stage 36 cookie keys are not edited here.
- [ ] No session service is added.

## Rollback

Remove the key to restore the same image default (`4w`). Do not roll back by setting `-1`.

## Success metrics

- New tokens expire.
- A search of Compose finds no non-expiring `JWT_EXPIRES_IN`.
