---
title: Compose Secrets Contribution Contract
description: Constructional contract for optional Docker Compose secrets files versus plaintext .env interpolation, without replacing env.example, generate-secrets, or the secret-rotation playbook.
last_updated: 2026-08-21
owner: maintainers
status: proposed
theme: security
impact: high
---

# Compose Secrets Contribution Contract

## Problem

Almost every password in `docker-compose.yml` is interpolated from `.env`:

```text
POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-ai_password_2024}
REDIS_PASSWORD: ${REDIS_PASSWORD:-redis_password_2024}
CONTROL_TOKEN: ${CONTROL_TOKEN:-}
```

`./tu-vm.sh generate-secrets` rewrites `.env`. Compose native `secrets:` (file or external) is unused. Community PRs that notice plaintext env tend to propose Vault, Bitwarden, or SOPS as a required control plane, or to commit encrypted blobs that agents cannot render.

Stage 12 covers **env.example schema**. Stage 8 covers **rotation hygiene**. This page is only **how secrets are mounted into containers**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `env.example` / `.env` | Operator source of truth today |
| `tu-vm.sh generate-secrets` | Fills `CHANGE_ME_*` defaults |
| `create_backup()` | Copies `.env` into the archive |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Rotate and document lifecycle |
| Stage 12 `env-schema-contribution-contract.md` (expected sibling) | Which keys exist and how to add them |
| Stage 18 `helper-control-auth-contract.md` (expected sibling) | `CONTROL_TOKEN` header path |

Out of scope:

- Replacing `generate-secrets` with a cloud KMS
- Requiring SOPS/age for every contributor clone
- Moving `CONTROL_TOKEN` checks out of the helper
- Printing secret values in CI logs or suggestion pages

## Proposal

Keep `.env` as the portable default. Allow an **opt-in** Compose `secrets:` lane for the few high-value credentials (Postgres, Redis, `CONTROL_TOKEN`, MinIO root) so they appear as files under `/run/secrets/` instead of process-visible environment, without a Vault service.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default | `.env` + interpolation | Clone / `generate-secrets` still works offline |
| Opt-in | `secrets:` + `_FILE` env where the image supports it | Postgres `POSTGRES_PASSWORD_FILE` pattern |
| Files | `secrets/*.txt` gitignored | Local files; never committed |
| Backup | `create_backup()` | If secrets files exist, include them next to `.env` |
| Docs | `env.example` comments | Point to this contract; do not duplicate keys |

### Rules

1. **`.env` remains the onboarding path.** A first-time `cp env.example .env && ./tu-vm.sh generate-secrets` must keep working without `secrets:`.
2. **Reuse Compose secrets, not a new product.** Official `secrets:` file sources. No Vault, Docker Swarm-only external stores, or a TU-VM secret API.
3. **Prefer image-native `*_FILE`.** Postgres and similar official images already read password files. Do not wrap every service in a custom entrypoint just to hide env.
4. **Gitignore secret files.** Add `secrets/` (or the chosen path) to `.gitignore`. Example names may live in docs, not real values.
5. **Do not dual-write conflicting values.** If `secrets:` is on, interpolation defaults must not silently override the file. Document one winner per key.
6. **Backup stays secret-safe.** Archives already copy `.env`; do not invent a second secret store. Remind operators that backup tarballs contain credentials (Stage 18).
7. **GitHub remains intake.** Requests for org-wide Vault stay Issues.

### Suggested contributor checklist

```text
1. Read env.example and generate-secrets
2. Keep CHANGE_ME defaults and interpolation working
3. If adding secrets:, use file: sources and gitignore them
4. Prefer POSTGRES_PASSWORD_FILE (and peers) over a custom entrypoint
5. Do not commit secret values or CI fixtures that are real passwords
6. Update create_backup() only if new files must be restored
7. Leave CONTROL_TOKEN auth behavior unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Onboarding | `env.example` + `generate-secrets` | Vault / Bitwarden as a prerequisite |
| In-container hide | Compose `secrets:` + `*_FILE` | A custom secret sidecar |
| Rotation | Stage 8 playbook | A second rotation CLI |
| Schema | Stage 12 env contract | A parallel key catalog |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: gitignore + documented opt-in `secrets:` for Postgres first (image already supports `_FILE`).
3. Optional: `check-config` warning when both a secret file and a non-default env value are set.

## Acceptance criteria

- [ ] Default clone path still uses `.env` only.
- [ ] Opt-in `secrets:` reuses Compose, not a new product.
- [ ] Secret files are gitignored.
- [ ] Rotation and env-schema contracts remain the lifecycle/schema sources.
- [ ] No secret values appear in repo or CI logs.

## Rollback

Remove `secrets:` blocks and `_FILE` env. `.env` interpolation continues. Helper auth and allowlist behavior are unaffected.

## Success metrics

- New contributors never need Vault to start Tier 1.
- Operators who opt in can keep passwords off `docker inspect` env.
- Backup/restore still has a single credential story.
