---
title: n8n Encryption Key Honesty Contract
description: Constructional contract so N8N_ENCRYPTION_KEY is a required operator secret, not a public Compose default that silently encrypts credentials.
last_updated: 2026-09-01
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Encryption Key Honesty Contract

## Problem

`env.example` treats `N8N_ENCRYPTION_KEY` as a placeholder that `./tu-vm.sh generate-secrets` must replace:

```text
N8N_ENCRYPTION_KEY=CHANGE_ME_32_CHAR_ENCRYPTION_KEY
```

Compose still ships a real-looking hex fallback:

```yaml
N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY:-1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b}
```

`generate-secrets` even uses that same hex string as the “default” it will replace. Anyone who starts n8n from Compose without a generated `.env` encrypts credentials, workflow secrets, and binary-data keys with a value that is already in the public repository.

Operators then propose a key-management sidecar, a HashiCorp Vault container, or a custom n8n image that “generates a key on first boot.” Official n8n already has one required env key. The gap is honesty: no silent public default.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service `N8N_ENCRYPTION_KEY` | Official n8n credential encryption |
| `env.example` | Placeholder `CHANGE_ME_32_CHAR_ENCRYPTION_KEY` |
| `./tu-vm.sh generate-secrets` | Replaces the placeholder and the Compose default |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Rotation playbook |
| Stage 12 `env-schema-contribution-contract.md` (expected sibling) | How keys are named and added |
| Stage 22 `compose-secrets-contribution-contract.md` (expected sibling) | Optional `*_FILE`; `.env` stays the clone path |
| Stage 30 `n8n-auth-env-honesty-contract.md` (expected sibling) | Login vs gateway keys — not this encryption key |

Out of scope:

- A Vault / OpenBao / SOPS sidecar for this one key
- Restoring deprecated n8n basic auth
- Changing how n8n stores credentials once a real key is set
- Rewriting Stage 8 rotation or Stage 30 login-honesty pages

## Proposal

### Path A (preferred): fail closed

1. Compose: `${N8N_ENCRYPTION_KEY:?Set N8N_ENCRYPTION_KEY in .env}` (same pattern as `AFFINE_DB_PASSWORD`).
2. Keep `generate-secrets` as the only writer of a random 32-byte hex (or longer) value.
3. `check-config` / `--strict`: treat the published hex default and `CHANGE_ME_*` as failing values.

### Path B: keep interpolation, delete the public default

If fail-closed is too sharp for first-boot docs:

```yaml
N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}
```

Document that an empty key is invalid. Do **not** put a hex literal back in Compose.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Path A or B — no public default |
| Env schema | `env.example` | Keep the CHANGE_ME placeholder; say it encrypts n8n credentials |
| Scripts | `generate-secrets` | Always write a random key; stop treating the hex literal as a “known default” operators should keep |
| Docs | README n8n row | One sentence: rotating this key invalidates stored credentials unless n8n is reset |

### Rules

1. **One official key.** n8n’s `N8N_ENCRYPTION_KEY` is the framework. Do not add a second encryptor.
2. **No public default.** A value that appears in git is not a secret.
3. **Rotation is a break-glass playbook**, not a new product. Point at Stage 8.
4. **GitHub remains intake.** Requests for “enterprise KMS for n8n” need a demonstrated multi-host requirement.

### Suggested contributor checklist

```text
1. Grep N8N_ENCRYPTION_KEY (Compose, env.example, tu-vm.sh, check-config)
2. Remove the hex fallback from Compose
3. Confirm generate-secrets still writes a unique key
4. Confirm check-config fails on CHANGE_ME and the old hex default
5. docker compose config still renders when .env has a real key
6. Do not add Vault, SOPS, or a keygen sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Credential encryption | Official n8n `N8N_ENCRYPTION_KEY` | A second crypto service |
| First-boot secret | `generate-secrets` + `.env` | A value committed in Compose |
| Optional file secrets | Stage 22 `*_FILE` later | Rewriting the clone path |
| Rotation | Stage 8 playbook | Silent key rewrite on every `up` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in a focused Compose + `generate-secrets` PR (Path A).
3. Mention in release notes: existing stacks that already have a unique `.env` value are unchanged; stacks using the published hex default should rotate and accept that stored n8n credentials must be re-entered.

## Acceptance criteria

- [ ] Compose has no published hex default for `N8N_ENCRYPTION_KEY`.
- [ ] `env.example` still documents the key as required and operator-generated.
- [ ] `generate-secrets` writes a unique value and does not recommend keeping the old hex default.
- [ ] No Vault / keygen sidecar is added.
- [ ] Stage 30 n8n login honesty is not rewritten.

## Rollback

Restore the previous Compose interpolation. n8n data volumes that already used a unique key stay valid.

## Success metrics

- Fewer “n8n credentials reset after clone” surprises caused by a shared default.
- Contributors stop proposing a secrets-manager container for this single key.
- `check-config --strict` catches leftover published defaults.
