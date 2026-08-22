---
title: Nginx Compose Configs Contract
description: Constructional contract for extracting repeated Nginx SSL and proxy snippets into include files, optionally delivered with Compose configs, without replacing edge routing or Docker-DNS rules.
last_updated: 2026-08-22
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Nginx Compose Configs Contract

## Problem

`nginx/conf.d/default.conf` is one file with sixteen `server` blocks. Each HTTPS vhost repeats the same TLS stanza (`ssl_certificate`, protocols, ciphers, session cache) and the same security headers. Contributors who add a hostname usually copy sixty lines, then drift one vhost when ciphers or HSTS change.

Stage 12 covers **what** a vhost may proxy and how allowlists work. Stage 21 covers **how** `proxy_pass` should resolve Compose service names. This page is only **how snippet files are shared** so those rules stay in one place.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/nginx.conf` | Already `include /etc/nginx/conf.d/*.conf` |
| `nginx/conf.d/default.conf` | All vhosts in one file; SSL and headers copy-pasted |
| `nginx/dynamic/control_allowlist.conf` | Existing include pattern for generated allowlists |
| Bind mounts on `nginx` | `nginx.conf`, `conf.d`, `dynamic`, `html`, `ssl` are already `:ro` |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Vhost and proxy contribution rules |
| Stage 21 `nginx-upstream-dns-contract.md` (expected sibling) | Resolver and service-name `proxy_pass` |
| Stage 13 `compose-healthcheck-contribution-contract.md` (expected sibling) | `nginx -t` remains the healthcheck |

Out of scope:

- Replacing Nginx with Caddy, Traefik, or an ingress controller
- Changing allowlist generation or control-plane routes
- Moving vhost **routing** policy (that stays Stage 12)
- Baking snippets into the `nginx` image

## Proposal

Extract repeated TLS and proxy header blocks into `nginx/snippets/` and `include` them from each server. Optionally declare those snippet files as Compose `configs:` so the mount list stays explicit. Keep bind-mounts as the default clone path.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Snippets | `nginx/snippets/ssl-params.conf`, `proxy-headers.conf` | One TLS block, one header block |
| Vhosts | `nginx/conf.d/default.conf` | `include /etc/nginx/snippets/ssl-params.conf;` |
| Compose mount | `nginx.volumes` or `configs:` | `./nginx/snippets:/etc/nginx/snippets:ro` |
| Test | existing `nginx -t` healthcheck | Reload fails closed on a bad include |

### Rules

1. **Include files, do not invent a templating language.** Native `include` is enough. Do not add `envsubst`, Jinja, or a config generator for vhosts.
2. **One concern per snippet.** TLS material and proxy headers are separate files. Location-specific timeouts stay in the vhost.
3. **Compose `configs:` is optional.** Bind-mount `./nginx/snippets` first. Use `configs:` only when a contributor needs an explicit file-id without a host path rewrite.
4. **Do not hide routing.** `server_name`, `location`, and `proxy_pass` remain in `default.conf` (or one file per vhost under `conf.d/` if a later split is accepted).
5. **Dynamic allowlist stays dynamic.** Keep `include /etc/nginx/dynamic/control_allowlist.conf` as the generated file. Do not fold it into a static snippet.
6. **GitHub remains intake.** Requests for a new reverse-proxy product stay Issues.

### Suggested contributor checklist

```text
1. Read nginx/conf.d/default.conf and count repeated ssl_certificate blocks
2. Add nginx/snippets/ssl-params.conf and proxy-headers.conf
3. Replace copied TLS/header stanzas with include lines
4. Mount ./nginx/snippets:/etc/nginx/snippets:ro on the nginx service
5. Leave nginx/dynamic and control_allowlist.conf unchanged
6. Confirm docker compose / nginx -t still validates
7. Do not change proxy_pass targets in the same PR unless Stage 21 DNS work is explicit
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Shared Nginx config | Official `include` snippets | A custom renderer or Helm chart |
| File delivery | Existing bind-mount; optional Compose `configs:` | Baking snippets into the image |
| Routing policy | Stage 12 edge-routing contract | Moving locations into snippets |
| Upstream names | Stage 21 Docker DNS contract | Putting IPs into snippet files |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add `nginx/snippets/`, replace repeated TLS/header blocks, mount the directory read-only.
3. Optional later: split `conf.d/` into one file per hostname after snippets land.

## Acceptance criteria

- [ ] HTTPS vhosts include a shared TLS snippet instead of copying ciphers.
- [ ] Security headers that are identical across vhosts live in one file.
- [ ] `nginx -t` still gates the container healthcheck.
- [ ] `nginx/dynamic/control_allowlist.conf` remains the generated include.
- [ ] No new reverse-proxy product is introduced.

## Rollback

Remove the snippets mount and restore inlined TLS/header blocks in `default.conf`. Routing and certificates are unchanged if the restored text matches today's file.

## Success metrics

- A TLS cipher or HSTS change is a one-file edit.
- New vhost PRs do not copy a sixty-line SSL stanza.
- `nginx -t` continues to fail closed on a broken include.
