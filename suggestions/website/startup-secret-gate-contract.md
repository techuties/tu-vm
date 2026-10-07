---
title: Startup Secret Gate Contract
description: Constructional contract so tu-vm.sh start and validate notice every published default that generate_secrets already knows how to replace.
last_updated: 2026-10-07
owner: maintainers
status: proposed
theme: security
impact: high
---

# Startup Secret Gate Contract

## Problem

`./tu-vm.sh start` decides whether to generate secrets with `env_has_insecure_values`. `./tu-vm.sh` security validation uses a second, shorter grep. `generate_secrets` already replaces a longer list. The three lists do not match, so a `.env` can keep a published encryption key and still look clean at start.

`set_env_var_if_default` replaces these when `generate_secrets` actually runs:

| Key | Published default it replaces |
|---|---|
| `POSTGRES_PASSWORD` | `ai_password_2024` |
| `REDIS_PASSWORD` | `redis_password_2024` |
| `MINIO_ROOT_PASSWORD` | `minio123456` |
| `WEBUI_SECRET_KEY` | `webui_secret_key_2024` |
| `WEBUI_JWT_SECRET_KEY` | `jwt_secret_key_2024` |
| `WEBUI_AUTH_SECRET` | `auth_secret_2024` |
| `N8N_PASSWORD` | `admin123` |
| `N8N_ENCRYPTION_KEY` | `1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b` |
| `PIHOLE_PASSWORD` | `SwissPiHole2024!` |
| `CONTROL_TOKEN` | empty |
| `MCP_GATEWAY_TOKEN` | empty |
| `AFFINE_DB_PASSWORD` | `affine_change_me` |

`env_has_insecure_values` flags only `CHANGE_ME*`, `ai_password_2024`, `redis_password_2024`, `minio123456`, `admin123`, and `affine_change_me`.

Replayed with that awk on 2026-10-07. Exit 0 means the start gate would treat the file as insecure:

| `.env` body | Gate result |
|---|---|
| `POSTGRES_PASSWORD=ai_password_2024` | flagged |
| `MINIO_ROOT_PASSWORD=minio123456` | flagged |
| `N8N_ENCRYPTION_KEY=1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b` and a unique Postgres password | not flagged |
| `WEBUI_SECRET_KEY=webui_secret_key_2024` and a unique Postgres password | not flagged |
| `PIHOLE_PASSWORD=SwissPiHole2024!` and a unique Postgres password | not flagged |
| `WEBUI_JWT_SECRET_KEY=jwt_secret_key_2024` | not flagged |

An operator who rotated Postgres and left the n8n key gets no start-time warning and no automatic `generate_secrets` pass. n8n keeps encrypting credentials with the key that is in git. Compose still supplies that hex string when `N8N_ENCRYPTION_KEY` is unset. This gate is the path that runs when the key is set to that same string.

`validate_security` then searches for `CHANGE_ME` and the regex `password_2024|admin123|test123`. On 2026-10-07 that regex matched `ai_password_2024` and did not match `minio123456`, `webui_secret_key_2024`, `jwt_secret_key_2024`, `auth_secret_2024`, `SwissPiHole2024!`, or the n8n hex key. `./tu-vm.sh` can report "Security validation passed" while MinIO is still `minio123456`, because `minio123456` is invisible to this grep even though the start gate can see it.

Stage 31 (open PR #57) extends `scripts/check-config.sh` so CI `--strict` fails on these same defaults. Stage 31's n8n page requires the encryption key in Compose. This page is the operator gate inside `tu-vm.sh` that runs before CI. The two gates should recognize one list. They should not each invent their own.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `env_has_insecure_values` | Decides whether `check_env_file` calls `generate_secrets` |
| `validate_security` | The later "weak password" grep |
| `set_env_var_if_default` | The defaults `generate_secrets` already replaces |
| `generate_secrets` | The rotator. It should run when any of those defaults is still present |
| Stage 31 `check-config-secret-coverage-contract.md` (expected sibling, open PR #57) | CI and `scripts/check-config.sh` |
| Stage 31 `n8n-encryption-key-honesty-contract.md` (expected sibling, open PR #57) | Compose must not fall back to the public hex key |
| `env.example` | The template new clones copy |

Out of scope:

- A vault, SOPS, or another secret store
- Printing generated passwords. `generate_secrets` already prints them for the operator
- Changing check-config.sh in this page (Stage 31)
- Rotating a key that is already unique

## Proposal

One list of published defaults, used by `env_has_insecure_values` and `validate_security`, matching the strings `set_env_var_if_default` already replaces.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Start gate | `env_has_insecure_values` | Also flag the WebUI secrets, `SwissPiHole2024!`, the n8n hex key, and an empty `CONTROL_TOKEN` or `MCP_GATEWAY_TOKEN` |
| Validate | `validate_security` | Flag that same list, including `minio123456`, instead of only `password_2024\|admin123\|test123` |
| Source of truth | Next to `set_env_var_if_default` | Keep the strings in one shell array both functions read, so check-config can mirror it when Stage 31 lands |
| Behavior | `check_env_file` | Keep calling `generate_secrets` when the gate matches. Do not add a second rotator |

### Rules

1. **A unique Postgres password does not hide other defaults.** The n8n key, the WebUI secrets, and the Pi-hole password are each enough to flag the file.
2. **`minio123456` fails validation** the same way it already fails the start gate.
3. **Empty control tokens count.** `CONTROL_TOKEN=` and `MCP_GATEWAY_TOKEN=` are the values `generate_secrets` already fills.
4. **Unique values stay quiet.** A key that is not in the published list and is not a `CHANGE_ME*` marker is left alone.

### Suggested contributor checklist

```text
1. A .env with only N8N_ENCRYPTION_KEY set to the published hex string makes env_has_insecure_values succeed (insecure)
2. The same file makes validate_security return 1
3. A .env with MINIO_ROOT_PASSWORD=minio123456 fails validate_security
4. A .env whose secrets are all outside the published list still passes both checks
5. check_env_file on a file that contains webui_secret_key_2024 invokes generate_secrets
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Detect defaults | The strings `generate_secrets` already replaces | A new scanner binary |
| Replace them | `generate_secrets` | A second writer for `.env` |
| CI | Stage 31 `check-config.sh` | Teaching `tu-vm.sh` to shell out to a new tool |
