---
title: Open WebUI Public URL Contract
description: Constructional contract for official WEBUI_URL so OAuth, callbacks, and generated links match the Nginx vhost instead of localhost:8080.
last_updated: 2026-09-15
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Public URL Contract

## Problem

Open WebUI is reached at `https://oweb.tu.lan` (helper status uses `https://oweb.${DOMAIN}`). Compose already sets secrets, Tika, Qdrant, and Redis, but it does **not** set official `WEBUI_URL`.

Without it, Open WebUI falls back to request-derived or localhost origins. That breaks:

- OIDC / OAuth redirect URIs
- Some webhook and tool callback bases
- Links copied from admin settings or emails
- Operators who change `DOMAIN` in `.env` while the app still thinks it lives on `127.0.0.1:8080`

The debug bind `127.0.0.1:8080:8080` stays LAN-first. `WEBUI_URL` is the **public origin** behind Nginx, not a new published port.

This is distinct from Stage 29 `openwebui-tika-service-dns-contract.md` (expected sibling): that page is internal Tika/MinIO DNS. This page is the browser-facing origin.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Nginx `oweb.tu.lan` vhost | TLS + `Host` already forwarded |
| Helper `/status` | Builds `https://oweb.{domain}` for the dashboard |
| Compose `open-webui` | No `WEBUI_URL` today |
| Official Open WebUI env | `WEBUI_URL` is the documented public base |
| `DOMAIN` in `.env` | Used by `tu-vm.sh` cert SAN and helper **if passed** |
| Stage 31 public-origin + helper-domain pages | Compose-wide `DOMAIN`; helper env wiring |
| Stage 20 IPv6 policy (expected sibling) | Dual-stack is all-or-nothing; do not rewrite |

Out of scope:

- A second identity provider or custom OAuth proxy
- Changing the localhost debug bind
- Templating every Nginx `server_name` in this PR (static `*.tu.lan` remains default)
- Rewriting Stage 29 Tika DNS

## Proposal

Set on `open-webui`:

```text
WEBUI_URL: ${WEBUI_URL:-https://oweb.${DOMAIN:-tu.lan}}
```

Add the same line to `env.example` under Open WebUI, defaulting to `https://oweb.tu.lan`.

If a contributor later implements Stage 31 `public-origin-domain-contract.md`, keep a single source: `DOMAIN` drives the default; `WEBUI_URL` remains the override for operators who publish a different name.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official `WEBUI_URL` |
| Env schema | `env.example` | Document the default and override |
| Docs | Open WebUI playbook | OAuth redirect = this URL + `/oauth/…` |
| Helper | Already emits the same URL once `DOMAIN` is passed | No second URL builder |

### Rules

1. **Use the official key.** Do not invent `OPENWEBUI_PUBLIC_URL` or a helper rewrite.
2. **HTTPS + vhost name.** Default must match Nginx, not `http://127.0.0.1:8080`.
3. **LAN-first stays.** `WEBUI_URL` does not open a WAN port.
4. **OAuth is optional.** Setting the URL does not enable SSO; it makes SSO possible without a sidecar.
5. **GitHub remains intake.** Requests for “SaaS-style custom domains” belong with the public-origin page, not a new product.

### Suggested contributor checklist

```text
1. Grep WEBUI_URL (should be absent today)
2. Add Compose interpolation with DOMAIN default
3. Add env.example + one playbook sentence for OAuth redirects
4. Confirm 127.0.0.1:8080 bind is unchanged
5. docker compose config shows https://oweb.tu.lan when DOMAIN is default
6. Do not add an OAuth provider in the same PR unless already planned
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Public origin | Official `WEBUI_URL` | App-level reverse-proxy detection hacks |
| Domain default | Existing `DOMAIN` | Hardcoding a second hostname scheme |
| TLS | Existing Nginx vhost | Terminating TLS inside Open WebUI |
| Status links | Helper `/status` | A third URL table in the dashboard JS |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + `env.example`. Safe for existing installs (adds env only).
3. Operators who already set a custom host in the Open WebUI admin DB should keep `WEBUI_URL` aligned to avoid split-brain.

## Acceptance criteria

- [ ] `open-webui` receives `WEBUI_URL` defaulting to `https://oweb.${DOMAIN:-tu.lan}`.
- [ ] `env.example` documents the key.
- [ ] Localhost debug bind is unchanged.
- [ ] No new OAuth proxy or identity service is added.
- [ ] Playbook names this URL as the OAuth redirect base.

## Rollback

Remove the env key. Open WebUI returns to request-derived origins. Admin DB settings are unchanged.

## Success metrics

- OAuth setup issues cite `WEBUI_URL` instead of “add a redirect rewriter”.
- Dashboard and app origin stay the same host string.
- Contributors stop proposing `extra_hosts` or `X-Forwarded` middleware as the public URL fix.
