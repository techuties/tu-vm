---
title: Container Hardening Baseline
description: Constructional contract for community Compose hardening—additive cap_drop, no-new-privileges, and docker.sock review—without a second security product or breaking helper control.
last_updated: 2026-08-13
owner: maintainers
status: proposed
theme: security
impact: high
---

# Container Hardening Baseline

## Problem

`docker-compose.yml` currently sets user-facing security through network isolation, localhost binds, Nginx TLS/headers, and secrets in `.env`. It does **not** declare `cap_drop`, `security_opt: no-new-privileges`, `read_only` root filesystems, or non-root `user:` on most services. `helper_index` mounts `/var/run/docker.sock` (required for dashboard start/stop). Playwright MCP and fetch tools add extra attack surface.

Stage 11 covers **host** privileged ops (sudoers, cron). Stage 12 covers access modes and Nginx routing. Stage 4 covers image CVE scans. Community Compose PRs still need a **container hardening baseline** so “make it work” does not add `privileged: true`, extra sockets, or dropped seccomp.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `ai_network` bridge + no host network (typical) | Isolation |
| Nginx TLS, CSP, HSTS, `limit_req` zones | Edge hardening |
| `CONTROL_TOKEN` + allowlist | Control-plane auth |
| `helper_index` docker.sock mount | Necessary for Compose control; high impact |
| `scripts/tu-vm.sh validate-security` | `.env` perms, CHANGE_ME, TLS files, UFW present |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Image CVEs / SBOM |
| Stage 11 `privileged-host-ops-contract.md` (expected sibling) | Host sudoers—not container caps |
| Stage 11 `autonomous-write-guard-policy.md` (expected sibling) | Operator write-guard flags |
| Stage 12 `access-mode-and-firewall-contract.md` (expected sibling) | Host firewall postures |
| This Stage 18 MCP sandbox + control-auth pages | Adjacent application sandboxes |

Out of scope:

- Mandatory AppArmor/SELinux policy packs as a merge gate for every distro
- Removing docker.sock from helper without a replacement control API
- `privileged: true` as a community convenience
- User-namespace remapping as a silent default (breaks many volume perms)

## Proposal

Publish a **container hardening baseline** for PRs that add or change Compose security-relevant keys.

### Baseline (additive, default-deny for dangerous keys)

| Control | Community default | Notes |
|---|---|---|
| `privileged` | Forbidden unless a documented exception | Helper sock is not a reason to go privileged |
| `pid: host` / `network_mode: host` | Forbidden for new services | Conflicts with IPAM and Pi-hole DNS |
| `cap_add` | Justify each capability | Prefer `cap_drop: [ALL]` plus minimal add |
| `security_opt` | Prefer `no-new-privileges:true` | Do not disable seccomp |
| `read_only` | Opt-in where the image allows tmpfs | Do not break Postgres/Open WebUI data dirs |
| docker.sock | Helper only | New mounts require security review |
| `user:` | Prefer non-root when the image supports it | Document UID/volume ownership |

`validate-security` stays a **host/config** check (`.env` 600, no `CHANGE_ME`, TLS present). It is not a substitute for Compose hardening.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Dangerous keys | `docker-compose.yml` | PR calls out `privileged`, host net, extra caps, extra sockets |
| Additive hardening | same file | `cap_drop` / `no-new-privileges` on services that still start |
| Helper socket | `helper_index` volumes | Do not replicate the mount to MCP/n8n/Open WebUI |
| Host checks | `validate-security` | Secret-safe; no printing `.env` values |
| Image CVEs | Stage 4 Trivy | Hardening does not replace scanning |

### Rules

1. **No new `privileged: true`.** Exceptions need a security note, rollback, and why caps are insufficient.
2. **No host network for new services.** It bypasses `ai_network` IPAM and Pi-hole DNS.
3. **docker.sock stays on helper** (and documented exceptions). MCP filesystem/fetch/playwright must not receive it.
4. **Additive hardening must not break Tier 1 start.** Test `quickstart` portable or compose health after `cap_drop`.
5. **Do not disable seccomp** (`security_opt: seccomp:unconfined`) to fix a bug without a tracked issue.
6. **`validate-security` never prints secret values**—only missing keys, weak placeholder patterns, perms, TLS presence.
7. **GitHub remains intake.** Full CIS/STIG automation products stay Issues unless accepted.

### Suggested contributor checklist

```text
1. Avoid privileged, host network, and extra docker.sock mounts
2. If adding capabilities, list why and prefer cap_drop ALL plus extras
3. Try no-new-privileges on new services
4. Run sudo docker compose config --quiet and a portable start smoke when caps change
5. Keep validate-security output secret-safe
6. Cross-check MCP sandbox rules for tool images
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Edge TLS/headers | Existing Nginx config | A second WAF appliance |
| Host firewall | Stage 12 access modes | Container `network_mode: host` |
| Image vulns | Stage 4 Trivy | Hardening theater without scans |
| Host sudo | Stage 11 privileged-host-ops | Granting containers the same sudoers |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: start with `no-new-privileges` on new/low-risk services; helper sock documented in Compose comments.
3. Optional CI grep for `privileged:` and `docker.sock` outside `helper_index`.

## Acceptance criteria

- [ ] New `privileged` and host-network services are disallowed by default.
- [ ] docker.sock policy is helper-only unless explicitly reviewed.
- [ ] Additive `cap_drop` / `no-new-privileges` is the contribution direction.
- [ ] `validate-security` remains secret-safe and host/config-scoped.
- [ ] Hardening PRs must still boot portable Tier 1.

## Rollback

Revert Compose keys independently if a service fails to start. Docs-only publication needs no runtime rollback.

## Success metrics

- No merged community service with `privileged: true` or extra docker.sock.
- New sidecars ship with `no-new-privileges` where compatible.
- Helper control keeps working without spreading the socket mount.
