---
title: n8n Proxy Hops and Cookie Contract
description: Constructional contract for official n8n N8N_PROXY_HOPS and N8N_SECURE_COOKIE so the existing Nginx TLS vhost does not need a cookie-rewrite sidecar.
last_updated: 2026-08-31
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Proxy Hops and Cookie Contract

## Problem

n8n is reached only through Nginx (`n8n.tu.lan` on 443). Compose already sets the public URL correctly:

- `N8N_HOST: n8n.tu.lan`
- `N8N_PROTOCOL: https`
- `WEBHOOK_URL` / `N8N_EDITOR_BASE_URL: https://n8n.tu.lan/`

Nginx already forwards `X-Forwarded-Proto`, `X-Forwarded-For`, `Host`, and WebSocket upgrade headers.

Two official n8n keys are missing:

| Key | Why it matters here |
|---|---|
| `N8N_PROXY_HOPS` | n8n trusts `X-Forwarded-*` only for N hops. Default `0` treats the container connection as the client. Rate limits, IP allow-lists inside n8n, and webhook IP logic see `172.20.0.0/16` instead of the LAN client. |
| `N8N_SECURE_COOKIE` | Editor cookies should be `Secure` because the browser speaks HTTPS to Nginx even though n8n itself listens on HTTP inside the mesh. |

Without these, operators hit "cookie not set" / webhook URL confusion and propose a second reverse proxy or `proxy_cookie_path` hacks.

Stage 20 is the webhook vs login rate-limit **zone split**. Stage 12 is Nginx edge routing. This page is leftover **n8n env for one hop**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/conf.d/default.conf` `n8n.tu.lan` | TLS terminator + `X-Forwarded-*` |
| Compose n8n public URL env | Already HTTPS-correct |
| Official n8n `N8N_PROXY_HOPS` | Trust N proxy hops |
| Official n8n `N8N_SECURE_COOKIE` | `Secure` flag on auth cookies |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Vhost contribution rules |
| Stage 20 `n8n-webhook-login-zone-split-contract.md` (expected sibling) | `limit_req` zones, not cookies |
| Stage 28 `n8n-healthz-when-started-contract.md` (expected sibling) | Probe only |

Out of scope:

- A second proxy (Caddy, Traefik) in front of n8n
- `sub_filter` / cookie-rewrite modules
- Changing `N8N_PROTOCOL` to HTTP (would break editor URLs)
- n8n SSO / SAML

## Proposal

Add the two official keys next to the existing public URL env:

```yaml
N8N_PROXY_HOPS: "1"
N8N_SECURE_COOKIE: "true"
```

One hop is correct: browser → Nginx → n8n. Do not set hops to `2` unless a second proxy is introduced (it is not).

Do not add `N8N_EXPRESS_TRUST_PROXY` aliases or custom Express config. n8n documents `N8N_PROXY_HOPS` as the supported switch.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n.environment` | The two keys |
| Nginx | no change | Headers already exist |
| Docs | this page + n8n playbook note | "one hop, Secure cookies" |
| CI | `docker compose config` | Confirm interpolation |

### Rules

1. **Official env names only.** No `proxy_cookie_path` in Nginx for this.
2. **Hops = 1** for the current topology. Bump only with a documented extra hop.
3. **Do not listen n8n on 443.** Nginx remains the TLS terminator.
4. **Do not weaken `N8N_PROTOCOL: https`.** Cookies and editor URLs stay HTTPS.
5. **GitHub remains intake.** Requests for "put n8n on host network" are out of scope.

### Suggested contributor checklist

```text
1. Confirm Nginx still sets X-Forwarded-Proto $scheme on n8n.tu.lan
2. Add N8N_PROXY_HOPS=1 and N8N_SECURE_COOKIE=true
3. Recreate ai_n8n; login at https://n8n.tu.lan
4. Confirm the session cookie is Secure and the editor stays on https
5. Trigger a test webhook; remote IP should not be 172.20.0.18 (nginx) only
6. docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Trust forwarded headers | Official `N8N_PROXY_HOPS` | A custom Express patch |
| Secure cookies | Official `N8N_SECURE_COOKIE` | Nginx cookie rewrite |
| TLS | Existing Nginx vhost | n8n-in-container certs |
| Webhook vs login limits | Stage 20 zone split | Mixing hops into rate-limit config |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose PR; no Nginx change required if headers already match.
3. Recreate n8n so the process picks up the new env (not a reload).

## Acceptance criteria

- [ ] `N8N_PROXY_HOPS` is `1` and `N8N_SECURE_COOKIE` is `true` on `n8n`.
- [ ] Nginx `X-Forwarded-Proto` / `Host` headers stay as they are.
- [ ] Editor login at `https://n8n.tu.lan` sets a `Secure` cookie.
- [ ] No second reverse proxy or cookie-rewrite module is added.
- [ ] Stage 20 reviews do not treat this as a rate-limit change.

## Rollback

Delete the two keys and recreate n8n. Workflow data on `n8n_data` is unchanged.

## Success metrics

- Fewer "I have to enable insecure cookies" issues on LAN HTTPS.
- Contributors stop proposing Traefik "just for n8n cookies".
- Webhook IP logs show the LAN client, not only the Nginx mesh address.
