---
title: Public Origin Domain Contract
description: Constructional contract to interpolate existing DOMAIN into n8n, AFFiNE, and MinIO public URLs instead of hardcoding *.tu.lan in Compose.
last_updated: 2026-09-15
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Public Origin Domain Contract

## Problem

`.env` already has `DOMAIN=tu.lan`. `tu-vm.sh` uses it for certificate SANs. The helper **intends** to build `https://n8n.{domain}` style links. Compose still hardcodes public origins:

| Service | Hardcoded today |
|---|---|
| n8n | `N8N_HOST: n8n.tu.lan`, `WEBHOOK_URL` / `N8N_EDITOR_BASE_URL` `https://n8n.tu.lan/` |
| affine / affine_migration | `AFFINE_SERVER_HOST: affine.tu.lan`, `AFFINE_SERVER_EXTERNAL_URL: https://affine.tu.lan` |
| minio | `MINIO_SERVER_URL: https://api.minio.tu.lan`, `MINIO_BROWSER_REDIRECT_URL: https://minio.tu.lan` |

`env.example` already lists the MinIO console URLs, but Compose does not interpolate them. Operators who change `DOMAIN` get valid certs and (once Stage 31 helper-domain lands) dashboard links, while n8n webhooks and the MinIO console redirect still point at `*.tu.lan`.

This is distinct from Stage 31 `openwebui-public-url-contract.md` (official `WEBUI_URL` key) and Stage 30 `minio-root-user-env-contract.md` (identity, not console URL).

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `DOMAIN` in `env.example` | Single operator-facing hostname suffix |
| `generate_ssl_certificates` | SAN `DNS:*.$domain` |
| Helper `/status` | Builds service URLs from `DOMAIN` when the env is present |
| Nginx `server_name` | Static `*.tu.lan` in `nginx/conf.d/default.conf` |
| Stage 30 MinIO root user (expected sibling) | `MINIO_ROOT_USER` interpolation |
| Stage 30 n8n proxy hops (expected sibling) | Cookies/hops behind the existing vhost |
| Stage 31 Open WebUI public URL | Official app key for oweb |

Out of scope:

- A Jinja/nginx templating product or new `render-vhosts` daemon
- Changing Pi-hole local DNS record generation (already DOMAIN-aware in `tu-vm.sh`)
- IPv6 dual-stack (Stage 20 — do not rewrite)
- Replacing Nginx with Traefik/Caddy for automatic hostnames

## Proposal

Interpolate Compose public URL env from `DOMAIN`, with `tu.lan` as default:

```text
N8N_HOST: n8n.${DOMAIN:-tu.lan}
WEBHOOK_URL: https://n8n.${DOMAIN:-tu.lan}/
N8N_EDITOR_BASE_URL: https://n8n.${DOMAIN:-tu.lan}/
AFFINE_SERVER_HOST: affine.${DOMAIN:-tu.lan}
AFFINE_SERVER_EXTERNAL_URL: https://affine.${DOMAIN:-tu.lan}
MINIO_SERVER_URL: ${MINIO_SERVER_URL:-https://api.minio.${DOMAIN:-tu.lan}}
MINIO_BROWSER_REDIRECT_URL: ${MINIO_BROWSER_REDIRECT_URL:-https://minio.${DOMAIN:-tu.lan}}
```

**Nginx vhosts stay static `*.tu.lan` until a maintainer explicitly adds a generate-or-sed step** that already matches how allowlists and certs are produced. Do not invent a second reverse-proxy. Document: changing `DOMAIN` without matching `server_name` lines is incomplete.

Optional later (same contract, not a new page): a `tu-vm.sh` snippet that rewrites `server_name` when `DOMAIN` ≠ `tu.lan`, using the existing ssl/DNS helpers.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | n8n, affine*, minio | Interpolate `DOMAIN` |
| Env schema | `env.example` | Note that Nginx vhosts still default to tu.lan |
| Docs | playbook | “Custom domain = DOMAIN + cert + DNS + nginx server_name” |
| Helper | Stage 31 helper-domain page | Pass `DOMAIN` so status URLs match |

### Rules

1. **One suffix.** Do not add `N8N_DOMAIN`, `AFFINE_DOMAIN`, and `MINIO_DOMAIN` unless an RFC proves split publishing.
2. **Defaults stay tu.lan.** Existing LAN installs do not change behavior.
3. **Do not template Nginx in the first code PR** unless the same change updates certs and Pi-hole records (already in `tu-vm.sh`).
4. **MinIO console URLs are env, not a new MinIO feature.** Distinct from Stage 23 ILM and Stage 24 SSE.
5. **GitHub remains intake.** “Automatic Let’s Encrypt for custom domains” is a different product.

### Suggested contributor checklist

```text
1. Grep hardcoded .tu.lan in docker-compose.yml public URL keys
2. Interpolate DOMAIN with tu.lan default
3. Keep env.example MINIO_* URLs aligned
4. Do not change nginx/conf.d/default.conf in the first PR unless DOMAIN rewrite is in scope
5. docker compose config with DOMAIN=example.test shows n8n.example.test
6. Default DOMAIN unset still renders n8n.tu.lan
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hostname suffix | Existing `DOMAIN` | Per-service domain keys |
| Certs / DNS | Existing `tu-vm.sh` helpers | A new ACME container by default |
| Edge routing | Existing Nginx files | Traefik as a prerequisite |
| App public URL | Official n8n / AFFiNE / MinIO env | HTML rewrite proxies |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Compose interpolation only (behavior-identical for default `tu.lan`).
3. Follow-up (optional): nginx `server_name` rewrite behind the same `DOMAIN` key.

## Acceptance criteria

- [ ] n8n, AFFiNE, and MinIO public URL env interpolate `${DOMAIN:-tu.lan}`.
- [ ] Default render matches today’s `*.tu.lan` strings.
- [ ] No new reverse-proxy or ACME service is added.
- [ ] Docs state that Nginx `server_name` is a separate step.
- [ ] Stage 30 MinIO root-user work is not duplicated.

## Rollback

Restore hardcoded `*.tu.lan`. Running containers pick up the previous strings on recreate.

## Success metrics

- Custom-domain issues mention one checklist (DOMAIN + cert + DNS + nginx) instead of scattered host literals.
- `docker compose config` is the source of truth for app origins.
- Contributors stop adding parallel `VIRTUAL_HOST` schemes (Pi-hole leftover names stay on Stage 30 FTLCONF).
