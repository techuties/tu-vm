---
title: TLS Certificate Lifecycle Contract
description: Constructional contract for community contributions and operator day-to-day TLS lifecycle that reuses existing generate_ssl_certificates helpers instead of inventing a certificate platform.
last_updated: 2026-08-03
owner: maintainers
status: proposed
theme: security
impact: high
---

# TLS Certificate Lifecycle Contract

## Problem

HTTPS for the Nginx control plane depends on `ssl/nginx.crt` and `ssl/nginx.key`. Historical suggestions jump to full ACME control planes, public CA automation that assumes internet exposure, or committing certificates into git. Operators still need a clear **lifecycle contract** for generate, replace, renew, and trust-store guidance that stays LAN-first.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `generate_ssl_certificates()` in `tu-vm.sh` | Self-signed cert creation on start |
| `ssl/nginx.crt` / `ssl/nginx.key` | Runtime material (local, not committed) |
| Nginx TLS config in `nginx/conf.d/default.conf` | Cipher and vhost binding |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Allowlist / control-plane security |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Broader secret lifecycle |
| Stage 6 `airgap-docs-mirror.md` (expected sibling) | Offline operator docs |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |

Out of scope:

- Forcing every home-lab install onto public Let’s Encrypt with inbound 80/443 from the internet
- Storing private keys in git, Issues, or automation memory
- Replacing Nginx with a third-party edge proxy as a prerequisite for TLS
- Treating browser warnings on self-signed LAN certs as product defects requiring telemetry

## Proposal

Publish a **TLS certificate lifecycle contract** with explicit operator modes.

### Modes

| Mode | Who | Behavior |
|---|---|---|
| **Self-signed (default)** | Most LAN operators | `tu-vm.sh` generates long-lived self-signed certs; browsers warn; document trust import |
| **Private CA** | Homelab with internal CA | Replace `ssl/` files with CA-signed cert/key; keep key permissions tight |
| **Public CA / ACME** | Intentionally exposed hosts only | Optional documented path; never the silent default; requires Decision Log if changing product defaults |

### Rules

1. **Keys never land in git.** `.gitignore` remains authoritative; PRs that add `*.key` fail review.
2. **Replace, do not dual-write.** Document the stop → replace `ssl/` → reload/restart Nginx sequence.
3. **Permissions.** Private keys stay operator-readable only (`600` guidance).
4. **No secret exfiltration.** Support bundles (PR #25 direction) must redact key material.
5. **Control plane unchanged.** TLS work must not widen allowlists (Stage 5 contract).
6. **Community docs over agents.** Website pages teach renewal; do not embed live certs in markdown.
7. **Air-gap friendly.** Self-signed and private CA modes must work offline.

### Suggested playbook shape

```text
#playbook-tls-lifecycle
1. Identify mode (self-signed / private CA / public CA)
2. Backup existing ssl/nginx.crt and ssl/nginx.key to an operator-local safe path
3. Install replacement files with correct permissions
4. Restart or reload nginx via tu-vm.sh / compose
5. Verify https://<host>/ with expected certificate fingerprint
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Default LAN TLS | Existing `generate_ssl_certificates` | Custom cert microservice |
| Public CA (optional) | Documented ACME client chosen by operator | Hard dependency on one SaaS CA API |
| Trust UX | Short browser import notes | Disabling TLS to “fix warnings” |
| Rotation | Stage 8 secret hygiene patterns | Pasting PEMs into chat |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-tls-lifecycle` to `docs/playbooks/README.md` when implementing.
3. Cross-link Stage 5 control-plane and Stage 8 secret pages.
4. Keep README warning about self-signed certs synchronized with this contract.

## Acceptance criteria

- [ ] Modes distinguish default self-signed vs private CA vs optional public CA.
- [ ] Docs explicitly forbid committing private keys.
- [ ] Replace/reload sequence is documented with verification steps.
- [ ] Public CA is never implied as the required default for LAN installs.
- [ ] TLS guidance references control-plane allowlist constraints.

## Rollback

Restore previous `ssl/nginx.crt` and `ssl/nginx.key` from operator backup; restart Nginx. Self-signed regeneration remains available via existing start helpers when files are absent.

## Success metrics

- Fewer Issues asking where to put certificates or whether to disable HTTPS.
- Zero accidental key commits attributed to missing guidance.
- Optional ACME setups are documented as advanced, not default.
