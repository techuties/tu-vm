---
title: Nginx Server Name Domain Contract
description: Constructional contract so Nginx server_name follows existing DOMAIN the same way tu-vm.sh already issues certificate SANs, instead of leaving static *.tu.lan vhosts after operators change the suffix.
last_updated: 2026-09-16
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Nginx Server Name Domain Contract

## Problem

`.env` already has `DOMAIN=tu.lan`. `tu-vm.sh generate_ssl_certificates` already issues `DNS:*.$domain`. Stage 31 `public-origin-domain-contract.md` (expected sibling, PR #57) interpolates Compose public URL env from `DOMAIN` and **explicitly deferred** Nginx vhosts.

`nginx/conf.d/default.conf` still hardcodes every `server_name` as `tu.lan`, `n8n.tu.lan`, `oweb.tu.lan`, `affine.tu.lan`, `ollama.tu.lan`, `pihole.tu.lan`, `minio.tu.lan`, and `api.minio.tu.lan`.

Operators who change `DOMAIN` get matching certs, Pi-hole records, and (once Stage 31 lands) app origin env, then HTTPS still fails SNI/`Host` matching because Nginx only answers `*.tu.lan`.

This is distinct from Stage 12 `nginx-edge-routing-contract.md` (how to contribute location blocks) and Stage 23 `nginx-compose-configs-contract.md` (Compose mount of conf snippets). This page is the **missing hostname rewrite** Stage 31 called out.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `DOMAIN` in `env.example` | Single operator-facing hostname suffix |
| `generate_ssl_certificates` in `tu-vm.sh` | Already DOMAIN-aware SANs |
| Pi-hole record sync in `tu-vm.sh` | Already DOMAIN-aware |
| `nginx/conf.d/default.conf` | Static `server_name` literals |
| Stage 10 TLS lifecycle (expected sibling) | Cert path and renewal |
| Stage 12 Nginx edge (expected sibling) | Contribution lane for vhosts |
| Stage 31 public-origin (expected sibling) | App URL env interpolation |
| Stage 31 helper-domain (expected sibling) | Dashboard links from `DOMAIN` |

Out of scope:

- Replacing Nginx with Traefik, Caddy, or an ACME sidecar
- A long-running `render-vhosts` daemon or Jinja product
- Rewriting Stage 31 Compose public-origin keys
- IPv6 listen policy (Stage 20 — do not rewrite)
- Changing default `tu.lan` behavior for existing LAN installs

## Proposal

Reuse the same generate-or-sed step `tu-vm.sh` already uses for certs and allowlists.

### Path A (preferred): one helper next to SSL generation

When `DOMAIN` ≠ `tu.lan` (or always, idempotently), rewrite `server_name` tokens from a **checked-in template** or from a documented `sed` over `*.tu.lan` → `*.$DOMAIN`.

Suggested shape:

```text
# tu-vm.sh (illustrative)
# 1. Keep nginx/conf.d/default.conf.tmpl (or default.conf as the tu.lan source)
# 2. envsubst or sed DOMAIN into the live default.conf that Nginx mounts
# 3. nginx -t && reload
```

Defaults stay `tu.lan`. A clone that never sets `DOMAIN` must render the same vhosts it has today.

### Path B: Compose `envsubst` at Nginx start

Only if Path A is rejected: an entrypoint that substitutes `${DOMAIN}` in a `*.tmpl` file. Do not add a second reverse-proxy image to get this.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Scripts | `tu-vm.sh` SSL/start path | Rewrite or render `server_name` from `DOMAIN` |
| Nginx | `nginx/conf.d/` | Template or documented source file |
| Env schema | `env.example` | One sentence: Nginx vhosts follow `DOMAIN` after start/generate |
| Docs | playbook | “Custom domain = DOMAIN + cert + DNS + nginx server_name” |
| Proof | `nginx -t` + `docker compose config` | Host header for `$DOMAIN` matches a server block |

### Rules

1. **One suffix.** Keep using `DOMAIN`. Do not add `NGINX_SERVER_NAME` unless an RFC proves split publishing.
2. **Defaults stay tu.lan.** Existing installs do not change behavior.
3. **Pair with certs.** Do not rewrite vhosts without the existing SAN helper (already DOMAIN-aware).
4. **No new proxy product.** Stage 12 still forbids drive-by Traefik swaps.
5. **GitHub remains intake.** Public Let’s Encrypt for arbitrary domains stays a separate RFC.

### Suggested contributor checklist

```text
1. Grep server_name in nginx/conf.d/default.conf
2. Add tu.lan → ${DOMAIN} render (template or sed) in the existing generate/start path
3. DOMAIN unset / tu.lan still matches today’s file
4. DOMAIN=example.test renders n8n.example.test (and siblings)
5. sudo docker compose exec nginx nginx -t
6. Do not change Stage 31 Compose URL keys in the same PR unless required for the demo
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hostname suffix | Existing `DOMAIN` | Per-vhost domain keys |
| Certs / DNS | Existing `tu-vm.sh` helpers | A new ACME container by default |
| Edge routing | Existing Nginx files | Traefik as a prerequisite |
| Render | `sed` / `envsubst` in start | A Kubernetes ingress controller |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** after Stage 31 Compose interpolation, or in the same operator “custom domain” PR.
3. Mention in playbooks: changing `DOMAIN` without this step is incomplete.

## Acceptance criteria

- [ ] `server_name` lines follow `${DOMAIN:-tu.lan}` after the documented generate/start step.
- [ ] Default render matches today’s `*.tu.lan` strings.
- [ ] No new reverse-proxy or ACME service is added.
- [ ] Stage 31 public-origin Compose work is not duplicated here.
- [ ] `nginx -t` remains the validation command.

## Rollback

Restore static `server_name tu.lan` lines. Reload Nginx. Certs and Compose env stay independently restorable.

## Success metrics

- Custom-domain issues cite one checklist (DOMAIN + cert + DNS + nginx) instead of “certs exist but Host header 404s”.
- Contributors stop proposing Traefik solely to get variable hostnames.
- `tu-vm.sh` remains the only renderer.
