---
title: Open WebUI Session Cookie Contract
description: Constructional contract to set official WEBUI_SESSION_COOKIE_SAME_SITE=strict and WEBUI_SESSION_COOKIE_SECURE=true (plus matching auth-cookie keys) on the existing HTTPS oweb vhost, distinct from Stage 30/36 n8n cookie keys.
last_updated: 2026-09-20
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Session Cookie Contract

## Problem

Open WebUI is reached only through Nginx (`oweb.tu.lan` on 443) with `WEBUI_AUTH=true`. Official Open WebUI hardening docs document four cookie keys that Compose does not set:

| Key | Upstream default | Why it matters here |
|---|---|---|
| `WEBUI_SESSION_COOKIE_SECURE` | `false` | Browser speaks HTTPS to Nginx; the container listens on HTTP inside the mesh. Without `true`, session cookies may omit `Secure`. |
| `WEBUI_SESSION_COOKIE_SAME_SITE` | `lax` | Dashboard **links** to Open WebUI; it does not iframe it. `strict` is the hardening default. |
| `WEBUI_AUTH_COOKIE_SAME_SITE` | follows session | Keep auth cookies aligned so login and session do not diverge. |
| `WEBUI_AUTH_COOKIE_SECURE` | follows session Secure | Same HTTPS-behind-proxy reason as session Secure. |

Community proposals that add Nginx `proxy_cookie_flags` reinvent these official keys.

This is distinct from:

- Stage 30 `n8n-proxy-hops-cookie-contract.md` (`N8N_SECURE_COOKIE` + hops)
- Stage 36 `n8n-samesite-cookie-contract.md` (`N8N_SAMESITE_COOKIE`)
- Stage 34 `openwebui-cors-origin-contract.md` (CORS allow-origin, not cookies)
- Stage 32 unofficial `WEBUI_*` honesty (do not invent new `WEBUI_RATE_LIMIT` style keys)

Official docs warn that `SameSite=strict` can break **OAuth** callback cookies. This stack uses local `WEBUI_AUTH`, not `ENABLE_OAUTH_SIGNUP`. If a later Issue adds OAuth, that Issue must switch SameSite back to `lax`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment | Auth on; cookie SameSite/Secure unset |
| `nginx/conf.d/default.conf` `oweb.tu.lan` | TLS terminator |
| Official Open WebUI hardening + env docs | The four cookie keys |
| Stage 32 compose-env honesty (expected sibling) | Reject unofficial `WEBUI_*` names |
| GitHub Issues suggestion form | Intake for OAuth / `lax` exceptions |

Out of scope:

- A cookie-rewrite sidecar
- Enabling OAuth in this contract
- Rewriting n8n cookie pages
- Inventing `WEBUI_COOKIE_POLICY`

## Proposal

Set the official hardening quartet on the `open-webui` service:

```text
WEBUI_SESSION_COOKIE_SECURE: "true"
WEBUI_SESSION_COOKIE_SAME_SITE: "strict"
WEBUI_AUTH_COOKIE_SECURE: "true"
WEBUI_AUTH_COOKIE_SAME_SITE: "strict"
```

Do not set SameSite `none`. Do not add Nginx cookie modules.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | The four official keys |
| Nginx | no change | TLS vhost already exists |
| Docs | Open WebUI playbook | “strict+Secure; OAuth requires lax” |

### Rules

1. **Official names only.** These four keys are documented; do not add rate-limit-style `WEBUI_*` inventions.
2. **Do not rewrite n8n cookie pages.** Different product, different keys.
3. **OAuth is a later Issue.** `strict` assumes local password auth.
4. **GitHub remains intake.** Embed/`lax` exceptions stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents the four cookie keys
2. Set Secure=true and SameSite=strict on session and auth cookies
3. Recreate open-webui and confirm Set-Cookie includes Secure and SameSite=Strict
4. Confirm local login on https://oweb.tu.lan/ still works
5. Do not add proxy_cookie_flags or enable OAuth in the same PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Open WebUI cookie flags | Official hardening keys | Nginx cookie rewrites |
| n8n cookies | Stage 30 Secure + Stage 36 SameSite | One shared cookie helper |
| CORS | Stage 34 `CORS_ALLOW_ORIGIN` | Mixing CORS with Set-Cookie |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: four Compose lines + recreate.
3. Operators re-login once; sessions are cookies.

## Acceptance criteria

- [ ] `open-webui` sets the four official cookie keys as above.
- [ ] Nginx cookie-rewrite modules are not added.
- [ ] n8n cookie pages are not rewritten.
- [ ] Docs note the OAuth/`lax` exception.

## Rollback

Remove the four keys (upstream defaults: Secure `false`, SameSite `lax`). Volume data remains; users sign in again.

## Success metrics

- Open WebUI `Set-Cookie` includes `Secure` and `SameSite=Strict`.
- Community cookie PRs cite official Open WebUI keys instead of Nginx rewrites.
