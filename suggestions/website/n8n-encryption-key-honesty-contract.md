---
title: n8n Encryption Key Honesty Contract
description: Constructional contract so N8N_ENCRYPTION_KEY is required, unique per install, and never the published Compose default that encrypts n8n credentials at rest.
last_updated: 2026-09-15
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Encryption Key Honesty Contract

## Problem

n8n encrypts stored credentials with `N8N_ENCRYPTION_KEY`. Compose currently supplies a **public default**:

```text
N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY:-1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b}
```

`env.example` tells operators to set `CHANGE_ME_32_CHAR_ENCRYPTION_KEY`. `./tu-vm.sh generate-secrets` replaces that marker **and** the published hex default. Operators who start n8n from Compose without generating secrets (or who copy only `docker-compose.yml`) encrypt every workflow credential with a key that lives in git.

`scripts/check-config.sh` does not require `N8N_ENCRYPTION_KEY` and does not fail on the published hex string.

This is distinct from Stage 30 `n8n-auth-env-honesty-contract.md` (expected sibling): that page is about `N8N_USER` / `N8N_PASSWORD` being gateway-only. This page is about the **at-rest encryption key**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service env | Interpolates the key; ships the published default |
| `env.example` | `CHANGE_ME_32_CHAR_ENCRYPTION_KEY` placeholder |
| `generate-secrets` | Writes a 64-char hex key; replaces the published default |
| n8n `n8n_data` volume | Encrypted credentials bound to the key used at first write |
| Stage 8 secret-rotation (expected sibling) | Rotation playbook; changing this key **orphans** existing credentials |
| Stage 12 env-schema (expected sibling) | How required keys are named |
| Stage 30 n8n auth honesty (expected sibling) | Editor login ≠ gateway basic auth |
| `check-config.sh` | Secret presence; does not list this key today |

Out of scope:

- A second secrets manager or Vault sidecar
- Re-encrypting existing n8n credentials automatically
- Restoring deprecated n8n basic auth
- Rewriting Stage 30 proxy hops / cookies or Stage 29 binary-data prune

## Proposal

1. **Remove the Compose default.** Require `${N8N_ENCRYPTION_KEY:?Set N8N_ENCRYPTION_KEY in .env}` (same pattern as `AFFINE_DB_PASSWORD`).
2. **Keep `generate-secrets` as the happy path.** It already produces `openssl rand -hex 32`.
3. **Teach check-config.** Treat the published hex and `CHANGE_ME_32_CHAR_ENCRYPTION_KEY` as insecure in `--strict` (see Stage 31 `check-config-secret-coverage-contract.md`).
4. **Document immutability.** After the first n8n start that wrote credentials, rotating the key without an official n8n export/import **breaks** stored credentials. Do not invent a custom re-encrypt tool.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Drop `:-1e2f3a4b…`; require the env key |
| Env schema | `env.example` | Keep CHANGE_ME; add one sentence: required before first n8n start |
| Scripts | `check-config.sh` | Require the key; flag the published default |
| Docs | n8n playbook + README | “Do not change after first credential save unless you export first” |

### Rules

1. **No published default in Compose.** A missing key must fail `compose up`, not silently encrypt with git history.
2. **One key per install.** Do not share the example hex across community clones.
3. **Rotation is a data migration.** Point operators at n8n export/import; do not write a TU-VM re-encrypt utility.
4. **GitHub remains intake.** Requests for HashiCorp Vault as the n8n key store need a separate RFC.
5. **Do not confuse this key with `N8N_PASSWORD`.** Stage 30 already covers that honesty gap.

### Suggested contributor checklist

```text
1. Grep 1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b (Compose, scripts, docs)
2. Change n8n env to required interpolation
3. Confirm generate-secrets still writes a 64-char hex value
4. Add check-config coverage for missing / published default
5. docker compose config fails without the key (same as AFFINE_DB_PASSWORD)
6. Existing installs that already have a unique .env key keep working
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Key generation | Existing `generate-secrets` + openssl | A new key-service container |
| Fail closed | Compose `:?` required interpolation | A helper that invents a key at boot |
| Rotation | Official n8n export/import | Custom credential rewriter |
| Detection | `check-config.sh --strict` | Printing the live key in logs |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in one PR: Compose `:?` + check-config + one playbook sentence.
3. Mention in release notes: installs that never ran `generate-secrets` must set a unique key **before** the next n8n start if they already stored credentials under the published default (those credentials are already weak).

## Acceptance criteria

- [ ] Compose no longer embeds `1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b` as a default.
- [ ] `docker compose config` fails when `N8N_ENCRYPTION_KEY` is unset (after env interpolation).
- [ ] `generate-secrets` still replaces CHANGE_ME and the historical default.
- [ ] `check-config.sh --strict` flags the published default and a missing key.
- [ ] Docs state that changing the key orphans existing n8n credentials.

## Rollback

Restore the Compose `:-` default. Existing `n8n_data` volumes keep working with whatever key they were created with.

## Success metrics

- Fresh clones cannot start n8n without a unique encryption key.
- Fewer “all my n8n credentials broke after I regenerated .env” issues.
- The published hex string disappears from `docker compose config` output.
