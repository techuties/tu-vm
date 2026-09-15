---
title: Check-Config Secret Coverage Contract
description: Constructional contract to extend existing check-config.sh so published Compose defaults and required n8n/MinIO/Pi-hole keys fail --strict the same way CONTROL_TOKEN already does.
last_updated: 2026-09-15
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Check-Config Secret Coverage Contract

## Problem

`scripts/check-config.sh` is the community day-to-day gate (`./scripts/pre-push-check.sh`, CI `--ci`, operators `--strict`). The required-key list is incomplete versus Compose published defaults:

| Key | Compose / generate-secrets default | In required list today |
|---|---|---|
| `POSTGRES_PASSWORD` | `ai_password_2024` | Yes (presence) |
| `REDIS_PASSWORD` | `redis_password_2024` | Yes (presence) |
| `WEBUI_SECRET_KEY` | `webui_secret_key_2024` | Yes (presence) |
| `CONTROL_TOKEN` | empty / CHANGE_ME | Yes |
| `AFFINE_DB_PASSWORD` | `affine_change_me` | Presence only |
| `N8N_ENCRYPTION_KEY` | `1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b` | **No** |
| `MINIO_ROOT_PASSWORD` | `minio123456` | Empty-value grep only |
| `WEBUI_JWT_SECRET_KEY` / `WEBUI_AUTH_SECRET` | `jwt_secret_key_2024` / `auth_secret_2024` | **No** |
| `PIHOLE_PASSWORD` | `SwissPiHole2024!` | **No** |
| `MCP_GATEWAY_TOKEN` | empty | Empty-value grep only |

`--strict` already flags `CHANGE_ME` / `PLACEHOLDER`. It does **not** flag the published hex encryption key or `minio123456` if someone copied Compose defaults into `.env` without the CHANGE_ME marker.

`--ci` should stay fixture-friendly (`.env_strict_ci_test` / env.example interpolation). Do not break PR CI by requiring production entropy in GitHub Actions.

This is distinct from Stage 31 `n8n-encryption-key-honesty-contract.md` (Compose `:?`). This page is the **contributor tool** that catches leftovers after generate-secrets.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/check-config.sh` | Presence + CHANGE_ME + compose config |
| `scripts/pre-push-check.sh` | Calls check-config |
| CI `check-config --ci` | Skips strict secret entropy |
| `generate-secrets` | Known insecure defaults table |
| Stage 8 secret-rotation (expected sibling) | Rotation playbook |
| Stage 12 env-schema (expected sibling) | Adding keys |
| Stage 30 n8n auth honesty (expected sibling) | Do not treat `N8N_PASSWORD` as editor login |
| Stage 27 helper `/health` (expected sibling) | Runtime probe, not this script |

Out of scope:

- Printing secret values in CI logs
- A new secrets scanner product (gitleaks as default)
- Replacing generate-secrets
- Stage 18 `no-new-privileges` (implement in **code**, not this page)

## Proposal

1. **Reuse `generate-secrets` default strings** as an insecure-values list inside check-config (no new file format unless Stage 12 already added one).
2. **`--strict`**: warn/fail if any listed key is missing **or** equals a published default.
3. **`--ci`**: keep today’s skip of entropy; still run `compose config` and syntax.
4. **Do not require `N8N_USER` / `N8N_PASSWORD` as editor secrets** (Stage 30). If Path A rename lands, check the gateway names instead.
5. **Never echo values.** Keep “values hidden”.

Suggested insecure defaults to flag (names only in docs; values stay in the script next to generate-secrets):

- `ai_password_2024`, `redis_password_2024`, `minio123456`
- `webui_secret_key_2024`, `jwt_secret_key_2024`, `auth_secret_2024`
- `1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b`
- `SwissPiHole2024!`, `affine_change_me`, `admin123`

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Scripts | `check-config.sh` | Expand keys + insecure defaults |
| CI | `.github/workflows/ci.yml` | Keep `--ci` (no entropy requirement) |
| Docs | CONTRIBUTING local checks | Mention `--strict` before first n8n/minio start |
| Tests | Optional | Fixture `.env` with CHANGE_ME still warns |

### Rules

1. **One list, two consumers.** Prefer sharing default strings with `generate-secrets` (comment “keep in sync”) rather than a YAML sidecar unless Stage 12 already exists.
2. **`--ci` stays green** on env.example interpolation.
3. **No secret printing.** Fail with key names only.
4. **Compose `:?` is complementary.** check-config helps before `up`; Compose fails at render for required keys.
5. **GitHub remains intake.** Enterprise policy engines are out of scope.

### Suggested contributor checklist

```text
1. Read generate-secrets set_env_var_if_default defaults
2. Add the same strings to check-config insecure list
3. Add N8N_ENCRYPTION_KEY to required keys for non-CI
4. Run --ci on interpolated env.example (must pass)
5. Run --strict on a .env that still has the published encryption hex (must fail)
6. Confirm output does not print the key material
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Preflight | Existing `check-config.sh` | A second `audit-secrets.sh` |
| Generation | Existing `generate-secrets` | Web UI for secret minting |
| CI | Existing `--ci` flag | Uploading operator `.env` to Actions |
| Rotation | Stage 8 playbook | Auto-rewriting live volumes |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: extend check-config in the same PR as the n8n encryption Compose `:?` change, or immediately after.
3. Mention `--strict` in CONTRIBUTING “local checks”.

## Acceptance criteria

- [ ] `--strict` flags missing `N8N_ENCRYPTION_KEY` and the published hex default.
- [ ] Published MinIO / WebUI / Pi-hole / Postgres / Redis defaults fail `--strict`.
- [ ] `--ci` still passes on the repository’s interpolated example/fixture.
- [ ] Logs never include secret values.
- [ ] `N8N_PASSWORD` is not described as the n8n editor login.

## Rollback

Revert the script. Pre-push and CI return to the shorter key list.

## Success metrics

- Clones that skip `generate-secrets` fail `--strict` before n8n stores credentials under a public key.
- CI does not become flaky on fixtures.
- Contributors extend the same list when adding a new published default.
