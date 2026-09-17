---
title: n8n Block Env Access In Node Contract
description: Constructional contract to set official N8N_BLOCK_ENV_ACCESS_IN_NODE so Code nodes cannot read Compose secrets from process.env, instead of adding a workflow sandbox VM.
last_updated: 2026-09-17
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Block Env Access In Node Contract

## Problem

The `n8n` service injects `DB_POSTGRESDB_PASSWORD`, `N8N_ENCRYPTION_KEY`, and other secrets as container environment. Official n8n Code nodes can read `process.env` unless `N8N_BLOCK_ENV_ACCESS_IN_NODE` is set. A shared LAN instance then lets any workflow author dump the platform database password.

Community suggestions that “sandbox n8n” often propose a second VM, a custom env-redacting proxy, or copying Stage 31 encryption-key work. The official switch is already there and is unset today.

This is distinct from:

- Stage 31 `n8n-encryption-key-honesty-contract.md` (require a real key; do not publish a hex default)
- Stage 32 `n8n-settings-file-permissions-contract.md` (config file mode on `~/.n8n`)
- Stage 32 `n8n-runners-enabled-contract.md` (task-runner process isolation, not env visibility)
- Stage 30 `n8n-auth-env-honesty-contract.md` (gateway `N8N_USER` / `N8N_PASSWORD`)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service in `docker-compose.yml` | Injects DB + encryption env today |
| Official n8n env | `N8N_BLOCK_ENV_ACCESS_IN_NODE` |
| Stage 31 encryption key (expected sibling) | At-rest credential key; still visible in env if Code can read it |
| Stage 32 runners (expected sibling) | JS isolation; not a substitute for this flag |
| `env.example` n8n block | Operator-facing keys; add a one-line comment |

Out of scope:

- A workflow sandbox VM or gVisor product
- Rewriting Stage 31 `N8N_ENCRYPTION_KEY:?`
- Rewriting Stage 32 runners or settings-file permissions
- Removing DB env from the n8n container (n8n still needs it)

## Proposal

Set the official flag on the `n8n` service:

```text
N8N_BLOCK_ENV_ACCESS_IN_NODE: "true"
```

Document that existing community workflows which read `process.env` for secrets must move those values to n8n credentials or workflow static data. Do not add a TU-VM env-injection helper that re-exposes Compose secrets to Code nodes.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag `true` |
| Env schema | `env.example` | Comment only (no extra interpolated key) |
| Docs | n8n playbook | Code-node env reads fail after this flag; use credentials |

### Rules

1. **Official key only.** Do not invent `TU_VM_N8N_HIDE_ENV`.
2. **Do not confuse with encryption key honesty.** Stage 31 owns requiring the key; this page owns Code-node visibility.
3. **Do not confuse with task runners.** Stage 32 owns `N8N_RUNNERS_ENABLED`.
4. **GitHub remains intake.** Requests for a workflow VM stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_BLOCK_ENV_ACCESS_IN_NODE
2. Add the env flag on the n8n service
3. Recreate n8n and verify a Code node cannot print process.env.N8N_ENCRYPTION_KEY
4. Document the credentials migration for workflows that read env today
5. Do not add a sandbox VM or env-redacting sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hide Compose secrets from Code | Official n8n env flag | Custom proxy or VM |
| Credential storage | Built-in n8n credentials | Re-injecting `.env` into nodes |
| Process isolation | Stage 32 official runners | A second worker fleet |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + one playbook sentence.
3. Call out workflow breakage in release notes if any local Code nodes read `process.env`.

## Acceptance criteria

- [ ] `n8n` sets `N8N_BLOCK_ENV_ACCESS_IN_NODE=true`.
- [ ] Docs mention migrating Code nodes off `process.env`.
- [ ] No sandbox VM or env-redacting sidecar is added.
- [ ] Stage 30–32 n8n pages are not rewritten.

## Rollback

Remove the env flag. Code nodes can read process env again. Volume data remains.

## Success metrics

- A sample Code node cannot print `N8N_ENCRYPTION_KEY` or the Postgres password.
- Hardening PRs cite this flag instead of new sandbox products.
