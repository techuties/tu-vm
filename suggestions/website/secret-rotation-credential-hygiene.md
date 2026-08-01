---
title: Secret Rotation and Credential Hygiene
description: Day-to-day community contract for rotating TU-VM credentials with generate-secrets, .env discipline, and SECURITY.md—without inventing a secrets platform.
last_updated: 2026-08-01
owner: maintainers
status: proposed
theme: security
impact: high
---

# Secret Rotation and Credential Hygiene

## Problem

Operators and contributors need a clear, repeatable way to create, rotate, and invalidate credentials (Postgres, MinIO, Open WebUI, helper tokens, TLS material). Historical suggestions sometimes propose Vault-like platforms or paste secrets into Issues for “help debugging.” Day-to-day life needs a **hygiene contract** that reuses `./tu-vm.sh generate-secrets`, `.env` patterns, and [`SECURITY.md`](../../SECURITY.md).

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh generate-secrets` | Creates/refreshes secure passwords and keys |
| `env.example` | Documented variable names and comments |
| `./tu-vm.sh check-config` / `doctor` | Surfaces missing or weak config without printing secrets |
| [`SECURITY.md`](../../SECURITY.md) | Private vulnerability reporting path |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Allowlist / control-plane safety |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Backup before destructive changes |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | No secrets in JSON responses |
| Privacy-safe support bundle proposal (PR #25) | Redacted diagnostics for sharing |

Out of scope:

- Mandatory HashiCorp Vault / cloud KMS for single-host LAN installs
- Storing production `.env` values in the git repository or suggestion pages
- Public Issue forms that accept secret fields
- Auto-rotating every credential on a schedule without operator consent

## Proposal

Publish a **rotation playbook** as website markdown and a `docs/playbooks/` anchor.

### Rotation classes

| Class | Examples | Cadence guidance |
|---|---|---|
| Bootstrap secrets | First `generate-secrets` after `env.example` copy | Once per install; re-run when compromised |
| Service passwords | DB, MinIO, app admin | Rotate after shared-access incidents or staff changes |
| Control tokens | Helper / API tokens | Rotate when devices leave the LAN trust boundary |
| TLS material | `ssl/nginx.crt` / `nginx.key` | Renew before expiry; document self-signed vs imported certs |

### Rules

1. **Never commit `.env` or live certs.** Treat suggestion markdown as public.
2. **Backup first.** Run `./tu-vm.sh backup` (or Stage 6 drill) before rotation that breaks running services.
3. **Rotate with restart notes.** Document which containers must recreate to pick up new env.
4. **Redact when sharing.** Prefer doctor JSON + support-bundle patterns; strip tokens.
5. **Security issues stay private.** Use SECURITY.md, not the suggestion Issue form.
6. **CI must not echo secrets.** Keep existing PR template checkboxes honest.

### Suggested playbook steps (website living section)

1. `./tu-vm.sh backup`
2. Identify variables in `env.example` for the service class
3. `./tu-vm.sh generate-secrets` (or targeted manual edit when only one value changes)
4. Recreate affected services via documented compose/`tu-vm.sh` commands
5. `./scripts/check-config.sh` and `./scripts/smoke-test.sh --live` when nginx tier is up
6. Invalidate old credentials (revoke tokens, change upstream passwords if mirrored)

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Generation | Existing `generate-secrets` | Ad-hoc `openssl rand` snippets with no restart map |
| Sharing diagnostics | Redacted doctor / support bundle | Screenshots of `.env` |
| Reporting leaks | SECURITY.md | Public Issues with secret contents |
| Proof | check-config + smoke | “Dashboard still loads” alone |

## Rollout

1. Land this page under `suggestions/website/`.
2. Add `#playbook-secret-rotation` to [`docs/playbooks/README.md`](../../docs/playbooks/README.md) when implementing.
3. Link from CONTRIBUTING security checklist and Stage 5 control-plane contract.
4. Optionally add `tu-vm.sh secrets-status` that reports **presence/age metadata only** (never values).

## Acceptance criteria

- [ ] Website page lists rotation classes and commands without sample secret values.
- [ ] Playbook (when implemented) requires backup before rotation.
- [ ] Doctor/check-config paths remain free of secret material in output.
- [ ] Suggestion Issue template continues to forbid secret pastes (document the rule here).
- [ ] Helper/dashboard contracts stay aligned: no tokens in `/status/full`.

## Rollback

Documentation-only rollback is trivial. If a `secrets-status` command is added later, gate it behind explicit flags and remove without touching Compose images.

## Success metrics

- Zero public Issues that contain live credentials after this guidance is linked from CONTRIBUTING.
- Operators complete rotations using playbook steps instead of ad-hoc container exec password resets.
- Faster incident recovery when a laptop leaves the trusted LAN.
