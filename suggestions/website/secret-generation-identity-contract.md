---
title: Secret Generation Identity Contract
description: Constructional contract so generate_secrets writes a distinct value for each placeholder and the printed card matches the file.
last_updated: 2026-10-10
owner: maintainers
status: proposed
theme: security
impact: high
---

# Secret Generation Identity Contract

## Problem

`./tu-vm.sh generate-secrets` builds a separate password for Postgres, Redis, n8n, Pi-hole, and MinIO. The first edit of `.env` then stores the Postgres password in all of those keys.

`env.example` uses the same placeholder on six assignments:

| Key | Placeholder in `env.example` |
|---|---|
| `POSTGRES_PASSWORD` | `CHANGE_ME_SECURE_PASSWORD` |
| `REDIS_PASSWORD` | `CHANGE_ME_SECURE_PASSWORD` |
| `N8N_PASSWORD` | `CHANGE_ME_SECURE_PASSWORD` |
| `MINIO_ROOT_PASSWORD` | `CHANGE_ME_SECURE_PASSWORD` |
| `KB_MINIO_SECRET_KEY` | `CHANGE_ME_SECURE_PASSWORD` |
| `PIHOLE_PASSWORD` | `CHANGE_ME_SECURE_PASSWORD` |

`generate_secrets` runs this replace across the whole file before `set_env_var_if_default`:

```bash
sed -i "s/CHANGE_ME_SECURE_PASSWORD/$postgres_pass/g" "$ENV_FILE"
```

A later line tries to put the MinIO password on the first remaining placeholder:

```bash
sed -i "0,/CHANGE_ME_SECURE_PASSWORD/s//$minio_pass/" "$ENV_FILE"
```

That placeholder is already gone, so the line changes nothing.

`set_env_var_if_default` replaces a key only when it is missing, empty, or still equal to its published default (`redis_password_2024`, `admin123`, `minio123456`, `SwissPiHole2024!`, and the others). After the global replace, Redis, n8n, MinIO, and Pi-hole hold the Postgres password, so the setter leaves them. `KB_MINIO_SECRET_KEY` is not in the setter at all.

Replayed on 2026-10-10 against a copy of `env.example`. Distinct markers stood in for each `openssl` value (`PG`, `RD`, `N8`, `PH`, `MI`, `AF`, and the key markers). No generated secret was printed.

| Key | In the file after the function's rules | Marker the function prints |
|---|---|---|
| `POSTGRES_PASSWORD` | `PG` | `PG` |
| `REDIS_PASSWORD` | `PG` | `RD` |
| `N8N_PASSWORD` | `PG` | `N8` |
| `MINIO_ROOT_PASSWORD` | `PG` | `MI` |
| `KB_MINIO_SECRET_KEY` | `PG` | not printed |
| `PIHOLE_PASSWORD` | `PG` | `PH` |
| `AFFINE_DB_PASSWORD` | replaced, because it is still `affine_change_me` | not printed |
| `MCP_PROOF_SIGNING_KEY` | `CHANGE_ME_PROOF_HMAC` | not printed |

An operator who follows the card cannot sign in to MinIO, n8n, or Pi-hole. Redis rejects the printed password. The knowledge-base key matches MinIO only because both copies are the Postgres password. One leak unlocks the database, the cache, workflow credentials, object storage, and the resolver admin password.

`MCP_PROOF_SIGNING_KEY` is never assigned. `_sign_proof` in `mcp-gateway/app.py` HMACs the proof with that environment value whenever it is non-empty. Compose passes `${MCP_PROOF_SIGNING_KEY:-}` through. A first-run `.env` therefore signs proofs with the string published in git. `env_has_insecure_values` matches `^CHANGE_ME`, so every later `./tu-vm.sh start` warns again, and running `generate-secrets` again still leaves the marker.

`check_env_file` calls `generate_secrets` when it creates `.env` from `env.example`. That is the path new clones take. This page is that writer. Stage 53 (open PR #79) owns the start gate's comparison list. Stage 31 (open PR #57) owns `scripts/check-config.sh`. Neither page changes the global replace.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `generate_secrets` | The only writer that should fill placeholders |
| `set_env_var_if_default` | Per-key replace that already knows each published default |
| `env.example` | The template the global replace collapses |
| `_sign_proof` | Uses `MCP_PROOF_SIGNING_KEY` as an HMAC key |
| Stage 53 `startup-secret-gate-contract.md` (expected sibling, open PR #79) | Which defaults the start gate should notice |
| Stage 31 `check-config-secret-coverage-contract.md` (expected sibling, open PR #57) | CI warning for leftover `CHANGE_ME` |

Out of scope:

- A vault, SOPS, or another secret store
- Changing the start-gate list (Stage 53) or `scripts/check-config.sh` (Stage 31)
- Printing passwords into logs, cron, or this website
- Rotating a value that is already unique

## Proposal

Delete the global `CHANGE_ME_SECURE_PASSWORD` replace. Call `set_env_var_if_default` with the value generated for that key. Add the two keys the setter skips today.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Writer | `generate_secrets` | Remove both `sed` calls that target `CHANGE_ME_SECURE_PASSWORD` |
| Per key | `set_env_var_if_default` | Pass `redis_pass`, `n8n_pass`, `minio_pass`, and `pihole_pass` for those keys |
| Knowledge base | same function | Set `KB_MINIO_SECRET_KEY` from `minio_pass` when it is `CHANGE_ME_SECURE_PASSWORD` or empty |
| Proofs | same function | Set `MCP_PROOF_SIGNING_KEY` from a new `openssl rand -hex 32` value when it is empty or starts with `CHANGE_ME` |
| Card | the echo block at the end of `generate_secrets` | Print the value just written for that key |

### Rules

1. **Each service gets its own value.** After a first run from `env.example`, `REDIS_PASSWORD`, `N8N_PASSWORD`, `MINIO_ROOT_PASSWORD`, and `PIHOLE_PASSWORD` differ from `POSTGRES_PASSWORD` and from each other.
2. **The card matches the file.** The MinIO, n8n, Pi-hole, and Redis lines are the strings now stored on those keys.
3. **The proof key is generated.** `MCP_PROOF_SIGNING_KEY=CHANGE_ME_PROOF_HMAC` does not survive `generate_secrets`.
4. **Unique values stay.** A second run does not replace a password that is no longer a placeholder.

### Suggested contributor checklist

```text
1. Copy env.example to a temp file and run the writer against that copy
2. REDIS_PASSWORD, N8N_PASSWORD, MINIO_ROOT_PASSWORD, and PIHOLE_PASSWORD are four different non-placeholder values
3. KB_MINIO_SECRET_KEY equals MINIO_ROOT_PASSWORD and does not equal POSTGRES_PASSWORD
4. MCP_PROOF_SIGNING_KEY does not start with CHANGE_ME
5. The MinIO password printed by the function equals MINIO_ROOT_PASSWORD in the file
6. A second run leaves those unique values unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Fill placeholders | `set_env_var_if_default` | One `sed` for every `CHANGE_ME_SECURE_PASSWORD` |
| Proof key | `openssl rand -hex 32`, already used for the gateway token | The published placeholder as an HMAC key |
| Detect leftovers | Stage 53 start gate and Stage 31 check-config | A new scanner |
