---
title: Nginx Add-Header Inheritance Contract
description: Constructional contract so Nginx locations that set their own add_header still emit the security headers their server block already declares, using an include instead of a new proxy or headers module.
last_updated: 2026-09-26
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Nginx Add-Header Inheritance Contract

## Problem

Nginx applies `add_header` from the previous level only when the current level has **no** `add_header` of its own. Two layers in this repo trip that rule.

`nginx/nginx.conf` sets an `http`-level set (including `Content-Security-Policy` and `Permissions-Policy`). Every TLS `server` in `nginx/conf.d/default.conf` sets its own `add_header` lines, so those vhosts do **not** send the `http`-level set.

Inside a server, several locations set `add_header` again and therefore drop the **server** set (HSTS, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `X-XSS-Protection`):

| Location | What it sets today | What the response loses |
|---|---|---|
| Landing `/status/*`, `/status/updates`, `/status/announcements`, `/whitelist/auto` | `Access-Control-Allow-Origin *` and sometimes `Cache-Control` | Server HSTS and nosniff |
| Landing `/` | `Cache-Control: no-store` | Same server security headers |
| `oweb.tu.lan` `location /` | `Cache-Control: no-store` | That server's HSTS and `X-Frame-Options DENY` |
| Several `location /health` blocks | `Content-Type: text/plain` | The server security headers |

The landing page is already same-origin. Those status locations exist so the dashboard does not need CORS. `Access-Control-Allow-Origin *` is unused for that page and is what suppresses the security headers.

This is distinct from Stage 12 `nginx-edge-routing-contract.md` (keep Nginx; do not swap in Traefik or Caddy) and from Stage 19 login rate limits. Stage 38 owns Open WebUI iframe and CSP **application** settings. This page does not copy the `http`-level CSP onto Open WebUI, n8n, or AFFiNE. That CSP is not sent today, and turning it on would be a new policy.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/nginx.conf` | `http`-level headers, including a CSP that vhosts currently replace |
| `nginx/conf.d/default.conf` | Per-server headers and the locations that override them |
| Landing dashboard | Same-origin caller of `/status/*` |
| Stage 12 Nginx edge routing (expected sibling) | Keep this reverse proxy |
| Stage 19 login rate limit (expected sibling) | `limit_req`, not headers |
| Stage 38 Open WebUI iframe/CSP (expected sibling) | Application CSP, not Nginx inheritance |

Out of scope:

- The `headers-more` module or OpenResty
- A new edge proxy
- Enabling the `nginx.conf` CSP on application vhosts
- Changing `DENY` versus `SAMEORIGIN` (Pi-hole already uses `SAMEORIGIN` on purpose)
- Rewriting Stage 38

## Proposal

1. **Status and whitelist bootstrap locations.** Remove `Access-Control-Allow-Origin *` from same-origin landing proxies. With no location-level `add_header`, they inherit the landing server's security headers. Keep `Cache-Control: no-store` only by including it **together with** the full server header set.
2. **Shared snippet.** Add `nginx/snippets/server-security-headers.conf` (or an equivalent include next to `conf.d`) that contains the header lines a given server already publishes. A location that must set `Cache-Control` or `Content-Type` **includes that full snippet** and then adds its one extra header. An include counts as `add_header` at that level, so the snippet must be the full set, not a delta.
3. **Do not promote the http CSP.** Leave `Content-Security-Policy` in `nginx.conf` as-is until a separate Issue names one vhost and a tested policy. Document in the snippet comment that server-level `add_header` already hides it.
4. **Health locations.** Either drop the location `add_header` and set `default_type text/plain`, or include the snippet plus `Content-Type`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Landing status | `default.conf` | Remove unused ACAO so server headers inherit |
| App locations | `oweb`, and any location with its own `add_header` | Include the full server header set |
| Snippet | `nginx/snippets/` mounted or copied with the existing Nginx config | One include, no new module |
| Proof | `curl -sI` against a local vhost | HSTS present on `/` and on `/status/oweb` |

### Rules

1. **Inheritance is the bug.** Do not "fix" it by deleting server-level HSTS.
2. **Same-origin stays same-origin.** Do not add a CORS product for the dashboard.
3. **CSP stays opt-in per Issue.** This page restores headers the server block already lists.
4. **Frame policy stays where it is.** OWeb `DENY` and Pi-hole `SAMEORIGIN` are copied, not redesigned.
5. **GitHub remains intake.** A looser frame policy for embedding is Stage 38 or a new Issue, not a drive-by header edit.

### Suggested contributor checklist

```text
1. List every location in default.conf that contains add_header
2. Remove Access-Control-Allow-Origin * from same-origin /status proxies
3. For locations that still need an extra header, include the full server set
4. curl -sI https://127.0.0.1/ -H "Host: tu.local" and the oweb host
5. Confirm Strict-Transport-Security is present on those responses
6. Do not add headers-more or copy nginx.conf CSP onto app vhosts
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Extra response headers | Nginx `include` of the existing server set | `headers-more` or a Lua WAF |
| Dashboard data | Existing same-origin `/status/*` proxies | CORS `*` "just in case" |
| App CSP | Stage 38 Open WebUI settings | The unused `http`-level CSP string |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: snippet plus location edits, then `curl -sI` on the landing host and `oweb.tu.lan`.
3. Reload Nginx. No Compose image change is required if the snippet is bind-mounted with `conf.d`.

## Acceptance criteria

- [ ] Landing `/status/oweb` (and the other status proxies) send the landing server's HSTS and nosniff lines.
- [ ] `oweb.tu.lan` `/` sends that server's HSTS and `X-Frame-Options` together with `Cache-Control: no-store`.
- [ ] Same-origin status responses do not send `Access-Control-Allow-Origin *`.
- [ ] Application vhosts do not suddenly send the `nginx.conf` CSP.
- [ ] Pi-hole remains `SAMEORIGIN`.
- [ ] Stage 12 and Stage 38 pages are not rewritten.

## Rollback

Restore `default.conf`. Header inheritance returns to today's behavior.

## Success metrics

- A header check on `/` and `/status/full` shows the same HSTS line the server block already contains.
- Operators stop adding CORS headers to same-origin proxies to "make the dashboard work."
- No new edge product is introduced for a one-line inheritance rule.
