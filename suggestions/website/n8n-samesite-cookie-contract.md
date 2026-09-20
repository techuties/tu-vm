---
title: n8n SameSite Cookie Contract
description: Constructional contract to set official N8N_SAMESITE_COOKIE=strict on the existing HTTPS n8n.tu.lan vhost, distinct from Stage 30 N8N_PROXY_HOPS and N8N_SECURE_COOKIE.
last_updated: 2026-09-20
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n SameSite Cookie Contract

## Problem

Stage 30 already documents the two leftover n8n proxy/cookie keys for one Nginx hop:

- `N8N_PROXY_HOPS=1`
- `N8N_SECURE_COOKIE=true`

Official n8n security env also documents `N8N_SAMESITE_COOKIE` (`strict` / `lax` / `none`, default `lax`). Compose does not set it.

The dashboard **links** to `https://n8n.tu.lan/`; it does not embed n8n in an iframe. The n8n vhost already sends `X-Frame-Options: DENY`. `strict` is therefore safe for this topology and stops the editor session cookie from being sent on cross-site top-level navigations (`lax` still would).

Community proposals that add `proxy_cookie_flags` / `proxy_cookie_path` in Nginx reinvent the official SameSite enum.

This is distinct from:

- Stage 30 `n8n-proxy-hops-cookie-contract.md` (hops + Secure flag)
- Stage 36 `openwebui-session-cookie-contract.md` (Open WebUI cookie keys)
- Stage 20 webhook vs login rate-limit zones
- Stage 34 CORS on Open WebUI (different product)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/conf.d/default.conf` `n8n.tu.lan` | TLS terminator; `X-Frame-Options: DENY`; no iframe |
| Landing dashboard | External link to n8n, not an embed |
| Official n8n security env | `N8N_SAMESITE_COOKIE` |
| Stage 30 hops/Secure (expected sibling) | One hop + `Secure`; implement in **code**, do not rewrite |
| GitHub Issues suggestion form | Intake if a future embed requires `lax` |

Out of scope:

- Rewriting Stage 30 hops / `N8N_SECURE_COOKIE`
- A cookie-rewrite sidecar or OpenResty module
- Setting `none` (requires cross-site embeds this stack does not have)
- Changing `N8N_PROTOCOL`

## Proposal

Add the official SameSite key next to the existing public URL env (and next to Stage 30 Secure/hops when those land in code):

```text
N8N_SAMESITE_COOKIE: "strict"
```

Keep hops at `1` and Secure `true` on the Stage 30 page. Do not invent `TU_VM_N8N_COOKIE_SAMESITE`.

If a later Issue embeds n8n in a first-party iframe (it should not: `X-Frame-Options: DENY`), revisit `lax` on that Issue. Do not weaken SameSite “just in case.”

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official `N8N_SAMESITE_COOKIE=strict` |
| Nginx | no change | Headers and vhost already exist |
| Docs | n8n playbook | “strict SameSite; dashboard is a link, not an embed” |

### Rules

1. **Official enum only.** Values are `strict`, `lax`, `none`.
2. **Do not rewrite Stage 30.** Hops and Secure stay on that page.
3. **Do not add Nginx cookie rewrites** for SameSite.
4. **GitHub remains intake.** Embed/`lax` exceptions stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_SAMESITE_COOKIE
2. Set the flag to strict on the n8n service
3. Recreate n8n and confirm Set-Cookie includes SameSite=Strict
4. Confirm the dashboard still opens n8n as a top-level navigation
5. Do not add proxy_cookie_path or rewrite Stage 30
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| SameSite policy | Official `N8N_SAMESITE_COOKIE` | Nginx cookie-flag modules |
| Secure + hops | Stage 30 official keys | Mixing SameSite into that page |
| Open WebUI cookies | Stage 36 Open WebUI session-cookie page | One “cookie mega-flag” |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line after (or with) Stage 30 Secure/hops.
3. Login remains on `https://n8n.tu.lan/` (first-party).

## Acceptance criteria

- [ ] `n8n` sets `N8N_SAMESITE_COOKIE=strict`.
- [ ] Nginx cookie-rewrite modules are not added.
- [ ] Stage 30 hops/Secure page is not rewritten.

## Rollback

Set the flag to `lax` (official default). Volume data remains.

## Success metrics

- Editor `Set-Cookie` includes `SameSite=Strict`.
- Community cookie PRs cite the official enum instead of Nginx rewrites.
