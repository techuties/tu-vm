---
title: Open WebUI CORS Origin Contract
description: Constructional contract to set official CORS_ALLOW_ORIGIN to the oweb.${DOMAIN} HTTPS origin instead of the implicit star, without adding a CORS microservice.
last_updated: 2026-09-18
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Open WebUI CORS Origin Contract

## Problem

The `open-webui` service does not set `CORS_ALLOW_ORIGIN`. Official Open WebUI defaults that key to `*`, and the project logs a warning when the star is in effect. Any website a LAN user visits can then make browser calls to `https://oweb.tu.lan` if that user still has a session cookie.

Community suggestions that “fix Open WebUI CORS” often propose a dedicated cors-proxy container, extra Nginx `add_header` products, or copying Stage 31 public-origin / `WEBUI_URL` work. `WEBUI_URL` tells the app its public URL; it does not replace the official CORS allowlist.

This is distinct from:

- Stage 31 `openwebui-public-url-contract.md` / `public-origin-domain-contract.md` (`WEBUI_URL` and n8n/AFFiNE/MinIO public URLs)
- Stage 32 `nginx-server-name-domain-contract.md` (Nginx `server_name` rewrite)
- Nginx landing-page same-origin status proxies in `nginx/conf.d/default.conf` (already avoid CORS for `/status`)
- Stage 30 `n8n-proxy-hops-cookie-contract.md` (n8n `N8N_PROXY_HOPS` / cookies, not Open WebUI CORS)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment | Auth and RAG keys; no `CORS_ALLOW_ORIGIN` |
| Official Open WebUI env | `CORS_ALLOW_ORIGIN` (semicolon-separated origins) |
| `DOMAIN` in `env.example` | `tu.lan` default; Stage 31 owns interpolating public URLs |
| Nginx `oweb.tu.lan` vhost | Browser origin operators actually use |

Out of scope:

- A CORS sidecar or extra Nginx CORS module product
- Rewriting Stage 31 `WEBUI_URL` / DOMAIN public origins
- Rewriting Stage 32 nginx `server_name`
- Changing landing-page same-origin status proxies

## Proposal

Set the official allowlist from the same `DOMAIN` Stage 31 already uses:

```text
CORS_ALLOW_ORIGIN: https://oweb.${DOMAIN:-tu.lan}
```

If a community tool must call Open WebUI from another HTTPS vhost, append that origin with a semicolon (official separator). Do not set `*`. Do not add `http://127.0.0.1:8080` unless Stage 33 debug-loopback profile is enabled *and* someone is developing against the raw port.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official `CORS_ALLOW_ORIGIN` |
| Env schema | `env.example` | Comment; reuse `DOMAIN` |
| Docs | Open WebUI playbook | Browsers may only use the `oweb.` origin |

### Rules

1. **Official key only.** Do not invent `TU_VM_WEBUI_CORS`.
2. **Do not confuse with `WEBUI_URL`.** Stage 31 owns the public URL string.
3. **Do not confuse with Nginx server_name.** Stage 32 owns vhost names.
4. **HTTPS origin.** Match `N8N_PROTOCOL` / landing TLS; do not advertise `http://oweb.`.
5. **GitHub remains intake.** Extra origins are Issues, not a dashboard form.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents CORS_ALLOW_ORIGIN
2. Set the origin to https://oweb.${DOMAIN:-tu.lan}
3. Recreate Open WebUI and confirm a foreign-origin fetch is rejected
4. Confirm oweb.${DOMAIN} still loads (same-origin)
5. Do not add a CORS microservice
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Limit browser origins | Official `CORS_ALLOW_ORIGIN` | A proxy that strips Origin |
| Public URL string | Stage 31 `WEBUI_URL` **code** | Duplicating that page |
| Landing status widgets | Existing Nginx same-origin proxies | Opening `*` so the dashboard can scrape oweb |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + one playbook sentence.
3. Call out broken third-party browser mashups in release notes.

## Acceptance criteria

- [ ] `open-webui` sets `CORS_ALLOW_ORIGIN` to `https://oweb.${DOMAIN:-tu.lan}` (plus any documented extras).
- [ ] The value is not `*`.
- [ ] Docs mention how to append another origin.
- [ ] No CORS sidecar is added.
- [ ] Stage 31 / 32 origin pages are not rewritten.

## Rollback

Remove the env key (official default `*`). Session cookies become usable from any browser origin again.

## Success metrics

- Open WebUI no longer logs the star-CORS warning after recreate.
- Community mashup PRs add a semicolon origin instead of proposing a CORS product.
