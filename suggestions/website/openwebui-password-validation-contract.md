---
title: Open WebUI Password Validation Contract
description: Constructional contract to set official ENABLE_PASSWORD_VALIDATION=true plus the documented regex and hint so community accounts share one password floor, distinct from Stage 32 signup.
last_updated: 2026-09-21
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Open WebUI Password Validation Contract

## Problem

Official Open WebUI hardening documents `ENABLE_PASSWORD_VALIDATION` as default `false`. TU-VM already requires `WEBUI_AUTH=true` and proposes Stage 32 `ENABLE_SIGNUP` for first-user / community signup, but Compose does not set a password-complexity floor.

A community LAN still has shared workstations, tailnet access, and the suggestion that operators generate strong secrets via `./tu-vm.sh generate-secrets`. Without the official validator, local accounts can be `password` while Postgres/n8n secrets are rotated—uneven day-to-day hygiene.

This is distinct from:

- Stage 32 `openwebui-signup-first-user-contract.md` (whether signup exists)
- Stage 35 n8n MFA (`N8N_MFA_ENFORCED_ENABLED`, different product)
- Stage 36 session-cookie flags (transport, not password strength)
- Helper `CONTROL_TOKEN` (dashboard control plane, not Open WebUI users)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Open WebUI hardening | `ENABLE_PASSWORD_VALIDATION`, `PASSWORD_VALIDATION_REGEX_PATTERN`, `PASSWORD_VALIDATION_HINT` |
| `open-webui` environment | Auth on; validation unset |
| `./tu-vm.sh generate-secrets` | Existing secret-generation tool |
| Stage 32 signup (expected sibling) | Who may register |
| Stage 36 PersistentConfig (expected sibling) | Makes these env values stick |

Out of scope:

- A custom auth microservice or LDAP/OIDC stack
- Changing `WEBUI_AUTH` off
- Rewriting Stage 32 signup or Stage 35 n8n MFA
- Inventing `TU_VM_WEBUI_PASSWORD_POLICY`

## Proposal

Set the official trio on the `open-webui` service, matching the hardening example:

```text
ENABLE_PASSWORD_VALIDATION: "true"
PASSWORD_VALIDATION_REGEX_PATTERN: "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^\\w\\s]).{8,}$"
PASSWORD_VALIDATION_HINT: "Minimum 8 characters with uppercase, lowercase, number, and special character."
```

Keep the regex in Compose / `env.example` as reviewed text. Do not add a policy engine.

These keys are PersistentConfig-backed. Implement Stage 36 store honesty in **code** or Admin UI can clear the floor.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official three keys |
| Env schema | `env.example` | Same values plus comment |
| Docs | Open WebUI playbook | First-user password rules |
| Code (related) | Stage 32 signup + Stage 36 store | Combined community account path |

### Rules

1. **Official keys only.** Match Open WebUI hardening names and example policy unless an Issue changes the regex.
2. **Do not confuse with signup.** Stage 32 owns `ENABLE_SIGNUP`.
3. **Do not confuse with n8n MFA.** Stage 35 owns that product.
4. **Do not add LDAP/OIDC** unless a later Issue adopts those official modules.
5. **GitHub remains intake.** Policy exceptions stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_PASSWORD_VALIDATION
2. Set the official trio on the open-webui service
3. Recreate Open WebUI and confirm a weak password is rejected
4. Implement Stage 36 ENABLE_PERSISTENT_CONFIG=false so the floor sticks
5. Do not add an auth service or rewrite Stage 32 signup
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Password floor | Official validation keys | A custom auth service |
| Account creation | Stage 32 `ENABLE_SIGNUP` | Mixing signup with complexity |
| Session cookies | Stage 36 cookie contract | Treating cookies as a password policy |
| Secret generation | Existing `tu-vm.sh generate-secrets` | A second password-manager product |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: three Compose lines plus Stage 36 store honesty.
3. Call out the new password hint in the Open WebUI playbook when implemented.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_PASSWORD_VALIDATION=true` and the official regex/hint.
- [ ] No auth microservice is added.
- [ ] Stage 32 signup and Stage 35 n8n MFA pages are not rewritten.

## Rollback

Set `ENABLE_PASSWORD_VALIDATION=false` (official default) and recreate. Existing users keep their hashes; only new/changed passwords are affected while the flag is on.

## Success metrics

- Recreating Open WebUI rejects a password that fails the official hint.
- Community “what password do I need?” answers cite the playbook hint, not a local wiki.
