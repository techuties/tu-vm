---
title: Nginx Tmpfs Runtime Contract
description: Constructional contract for official Nginx tmpfs mounts on /run, /var/run, /tmp, and /var/cache/nginx so Stage 23 read_only can land without a writable rootfs.
last_updated: 2026-08-30
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Nginx Tmpfs Runtime Contract

## Problem

Stage 23 `read-only-rootfs-proxy-contract.md` asks for `read_only: true` on `nginx`. The official `nginx` image still writes:

- `/var/run/nginx.pid` (and `/run/nginx.pid`)
- `/var/cache/nginx` (proxy/fastcgi/client-body temp)
- `/tmp` (some modules and `client_body_temp` fallback)

Today `docker-compose.yml` bind-mounts config, HTML, TLS, and `nginx_logs` only. There is **no** `tmpfs:`. Turning on `read_only` without those mounts makes `nginx -t` and reload fail, which is the current healthcheck.

Stage 23 is the **policy** (read-only rootfs). Stage 26 `processor-tmpfs-status-share-contract.md` is the Tika/helper scratch file, not the proxy. This page is the leftover **runtime directories** the official image expects.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `nginx` volumes | `nginx.conf`, `conf.d`, `dynamic`, `html`, `ssl`, `nginx_logs` |
| Healthcheck `nginx -t` | Fails if pid/temp paths are not writable |
| Official Nginx Docker image layout | `/var/cache/nginx`, `/var/run`, `/tmp` |
| Stage 23 `read-only-rootfs-proxy-contract.md` (expected sibling) | `read_only: true` policy |
| Stage 23 `nginx-compose-configs-contract.md` (expected sibling) | Snippets / Compose `configs:` |
| `ulimits.nofile` already on `nginx` | Keep; unrelated to tmpfs |

Out of scope:

- LSM / AppArmor profiles (Stage 21)
- Replacing bind-mounted HTML with an image bake
- A second log shipper (Stage 11 / 22)
- `tmpfs` on Postgres or Redis data dirs

## Proposal

Add Compose `tmpfs` (or `volumes` of type `tmpfs`) for the official writable paths, then land Stage 23 `read_only: true` in the same or a follow-up PR.

```yaml
nginx:
  read_only: true
  tmpfs:
    - /run
    - /var/run
    - /tmp
    - /var/cache/nginx
```

Keep `nginx_logs` as a named volume (or the existing bind) so access logs survive restart. Do not put `/var/log/nginx` on tmpfs unless an operator override asks for it.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose `nginx` | `tmpfs` + later `read_only` | Official image paths only |
| Nginx config | `nginx.conf` / `conf.d` | Confirm `pid` and temp paths stay under those dirs |
| Healthcheck | existing `nginx -t` | Must pass after `read_only` |
| Docs | this page + Stage 23 | Read-only PRs must include tmpfs |

### Rules

1. **Reuse official paths.** Do not invent `/scratch/nginx` and rewrite `nginx.conf` unless the upstream image changes.
2. **Logs stay on a volume.** tmpfs is for pid/cache/temp, not the operator audit trail.
3. **Do not tmpfs bind-mounted config.** `conf.d` and `dynamic` remain read-only binds.
4. **Pair with Stage 23.** A tmpfs-only PR is acceptable; a `read_only` PR without tmpfs is not.
5. **GitHub remains intake.** Requests for “writable root so we can apt install in the proxy” are out of scope.

### Suggested contributor checklist

```text
1. Add tmpfs for /run, /var/run, /tmp, /var/cache/nginx
2. Confirm nginx.conf pid and client_body_temp live under those paths
3. docker compose up -d nginx && docker exec ai_nginx nginx -t
4. Add read_only: true (this PR or the Stage 23 follow-up)
5. Reload via kill -HUP or nginx -s reload and re-run nginx -t
6. Confirm /usr/share/nginx/html and /etc/nginx/ssl stay read-only binds
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Writable runtime | Compose `tmpfs` | Privileged writable rootfs |
| Persistent logs | Existing `nginx_logs` volume | Shipping logs to the helper |
| Policy | Stage 23 `read_only` | A custom hardened nginx fork |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: tmpfs first (no behavior change), then `read_only: true`.
3. If a module writes elsewhere, add that path to tmpfs rather than disabling `read_only`.

## Acceptance criteria

- [ ] `nginx` declares tmpfs for `/run`, `/var/run`, `/tmp`, and `/var/cache/nginx`.
- [ ] `nginx -t` succeeds with `read_only: true`.
- [ ] HTML, TLS, and `conf.d` binds remain `:ro`.
- [ ] Access/error logs still land on `nginx_logs` (not tmpfs).
- [ ] `docker compose config` still renders.

## Rollback

Remove `tmpfs` and `read_only`. The image root becomes writable again. Certificates and HTML binds are unchanged.

## Success metrics

- Stage 23 reviews treat a `read_only` nginx PR without tmpfs as incomplete.
- Reload/healthcheck failures after hardening go to zero.
- No new “nginx helper sidecar” appears to manage pid files.
