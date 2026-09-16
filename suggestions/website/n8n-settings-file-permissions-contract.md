---
title: n8n Settings File Permissions Contract
description: Constructional contract to set official N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS so n8n’s config file mode is enforced instead of ignored startup warnings or a custom chmod sidecar.
last_updated: 2026-09-16
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# n8n Settings File Permissions Contract

## Problem

Current n8n images warn when `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` is unset. Compose does not set the official key. The `n8n_data` volume holds `~/.n8n` including encryption-adjacent settings.

Community suggestions that “harden n8n” often propose extra sidecars, `chmod` loops in `tu-vm.sh`, or copying Stage 30 cookie/hops work. The official switch is already there.

This is distinct from:

- Stage 30 `n8n-proxy-hops-cookie-contract.md` (proxy hops / secure cookie)
- Stage 30 `n8n-auth-env-honesty-contract.md` (gateway `N8N_USER` / `N8N_PASSWORD`)
- Stage 31 `n8n-encryption-key-honesty-contract.md` (at-rest credential key)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service | `n8n_data:/home/node/.n8n` |
| Official n8n env | `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` |
| Stage 25 non-root user (expected sibling) | Container user; not this file-mode flag |
| Stage 29 n8n binary volume (expected sibling) | Binary data / prune |
| Stage 31 encryption key (expected sibling) | Credential encryption |

Out of scope:

- A cron `chmod` sidecar
- Rewriting Stage 31 encryption-key `:?`
- Changing the n8n image user beyond Stage 25
- Host-bind-mounting `~/.n8n` from the operator home directory

## Proposal

Set the official flag on the `n8n` service:

```text
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS: "true"
```

If a community clone already has a too-open settings file, n8n may refuse to start until the operator fixes mode on the volume. Document that recovery (`docker compose run` + `chmod` on the named volume path, or official n8n guidance)—do not add a TU-VM repair daemon.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag `true` |
| Env schema | `env.example` | Optional comment only (no extra key unless interpolated) |
| Docs | n8n playbook | Startup warning → this flag; recovery if start fails |

### Rules

1. **Official key only.** Do not invent `TU_VM_N8N_CHMOD`.
2. **Do not confuse with encryption key.** Stage 31 owns `N8N_ENCRYPTION_KEY`.
3. **Do not confuse with hops/cookies.** Stage 30 owns proxy/cookie honesty.
4. **GitHub remains intake.** Requests for an n8n config ConfigMap product stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS
2. Add the env flag on the n8n service
3. Recreate n8n on a fresh volume — no startup permission warning
4. Document recovery if an old volume has a world-readable config file
5. Do not add a chmod sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| File mode policy | Official n8n env | Custom repair container |
| Credential secrecy | Stage 31 encryption key | Mixing keys into this flag |
| Process user | Stage 25 non-root contract | Running n8n as root to “fix” modes |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + one playbook sentence.
3. Mention possible first-start failure on older volumes in release notes.

## Acceptance criteria

- [ ] `n8n` sets `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true`.
- [ ] Docs mention recovery for pre-existing loose file modes.
- [ ] No chmod sidecar or extra volume helper is added.
- [ ] Stage 30/31 n8n pages are not rewritten.

## Rollback

Remove the env flag. n8n returns to warning-without-enforcement. Volume data remains.

## Success metrics

- Fresh n8n starts no longer log the permissions-enforcement warning.
- Hardening PRs cite this flag instead of new sidecars.
