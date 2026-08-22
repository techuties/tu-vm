---
title: Read-Only Rootfs Proxy Contract
description: Constructional contract for running stateless proxies with a read-only root filesystem and tmpfs for pid/cache, without replacing AppArmor, seccomp, or the existing cap_drop baseline.
last_updated: 2026-08-22
owner: maintainers
status: proposed
theme: security
impact: medium
---

# Read-Only Rootfs Proxy Contract

## Problem

`nginx` already bind-mounts its config, HTML, and TLS material read-only, but the container root filesystem is writable. A compromised worker can still write to image paths. Community hardening PRs often jump to `privileged: false` copies, `user: root` debates, or custom AppArmor profiles before locking the writable surface.

Stage 18 covers **cap_drop / no-new-privileges / docker.sock review**. Stage 21 covers **optional AppArmor/seccomp profiles**. This page is only **read-only rootfs plus tmpfs** for stateless proxies.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx` volumes | `nginx.conf`, `conf.d`, `dynamic`, `html`, `ssl` already `:ro` |
| `nginx_logs` volume | Writable logs; do not put these on the rootfs |
| Healthcheck | `nginx -t` (needs config mounts, not a writable image) |
| Stage 18 `container-hardening-baseline-contract.md` (expected sibling) | Capabilities and docker.sock |
| Stage 21 `apparmor-seccomp-profile-contract.md` (expected sibling) | LSM profiles |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | What the proxy may expose |

Out of scope:

- Read-only rootfs on stateful services (`postgres`, `minio`, `qdrant`, `open-webui`)
- Changing the Nginx user or dropping `NET_BIND_SERVICE` in the same change
- Replacing Stage 18 capability review
- Distroless or custom Nginx images as a prerequisite

## Proposal

Set `read_only: true` on `nginx` (and later other stateless proxies) and add `tmpfs` for `/var/run`, `/var/cache/nginx`, and `/tmp` so the official image can still write its pid and cache. Keep `nginx_logs` as the log volume.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Compose | `nginx.read_only` + `tmpfs` | Container cannot write `/etc/nginx` image paths |
| Volumes | existing `:ro` binds + `nginx_logs` | Config stays bind-mounted; logs stay on a volume |
| Test | `nginx -t` and a request to `/health` | Pid and cache tmpfs are sufficient |
| Docs | CONTRIBUTING or playbook | List which services may use read-only rootfs |

### Rules

1. **Stateless proxies first.** `nginx` is the pilot. Do not flip `read_only` on databases or anything that writes into the image.
2. **Name the writable paths.** Official Nginx needs pid, cache, and often `/tmp`. Use `tmpfs` with explicit destinations, not a writable root exception.
3. **Logs stay on `nginx_logs`.** Do not send access logs to tmpfs.
4. **Orthogonal to LSM.** AppArmor/seccomp remain Stage 21. A read-only rootfs PR must not require `apparmor:unconfined`.
5. **Do not fight bind-mounts.** Config and TLS remain host mounts. Read-only rootfs does not replace `:ro` on those mounts.
6. **Pi-hole and helper are not this page.** Helper needs docker.sock and writable dynamic allowlist. Pi-hole is stateful.
7. **GitHub remains intake.** Requests for gVisor or a custom hardened image stay Issues.

### Suggested contributor checklist

```text
1. Read the nginx service in docker-compose.yml
2. Add read_only: true
3. Add tmpfs for /var/run, /var/cache/nginx, and /tmp
4. Keep nginx_logs and existing :ro config mounts
5. Confirm nginx -t and /health still succeed
6. Do not change cap_drop or AppArmor in the same PR
7. Document that stateful services are out of scope
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Immutable image | Compose `read_only` + `tmpfs` | A custom Nginx Dockerfile |
| Config | Existing bind-mounts | Baking `default.conf` into the image |
| Process hardening | Stage 18 caps, then this page, then Stage 21 LSM | One PR that does all three |
| Logs | `nginx_logs` volume | Logging to a tmpfs that vanishes |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `read_only` + tmpfs on `nginx` only.
3. After a release, consider the same pattern for other stateless proxies if any are added.

## Acceptance criteria

- [ ] `nginx` root filesystem is read-only at runtime.
- [ ] Pid, cache, and `/tmp` are tmpfs.
- [ ] Config, TLS, and HTML mounts remain read-only binds.
- [ ] Access/error logs still persist on `nginx_logs`.
- [ ] No AppArmor or capability change is required for this to work.

## Rollback

Remove `read_only` and the extra tmpfs entries. Bind-mounts and the image pin stay as they are.

## Success metrics

- A write to an image path inside `ai_nginx` fails.
- `nginx -t` and `/health` stay green after restart.
- Hardening PRs stop proposing a custom Nginx image just to lock the rootfs.
