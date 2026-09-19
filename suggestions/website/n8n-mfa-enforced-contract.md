---
title: n8n MFA Enforced Contract
description: Constructional contract to enforce official N8N_MFA_ENFORCED_ENABLED on the shared N8N_SECURITY_POLICY_MANAGED_BY_ENV lock so community operators cannot skip two-factor, without rewriting Stage 34 personal-space sharing.
last_updated: 2026-09-19
owner: maintainers
status: proposed
theme: community
impact: high
---

# n8n MFA Enforced Contract

## Problem

The `n8n` service does not set `N8N_MFA_ENFORCED_ENABLED`. Official n8n defaults that flag to `false`, so any user on a shared LAN instance can stay on password-only. For a community-based private AI VM, the editor is a high-value target: workflow credentials, webhook URLs, and MCP-connected tools live behind that login.

Stage 34 `n8n-personal-space-sharing-contract.md` (expected sibling) already proposes the official lock `N8N_SECURITY_POLICY_MANAGED_BY_ENV=true` so personal-space publish/share can be forced off. MFA is the other documented key on that **same** official security-policy surface. Community suggestions that “add TOTP in the helper” or “put MFA in nginx” reinvent a second auth product.

This is distinct from:

- Stage 34 personal-space sharing (publish/share booleans, not MFA)
- Stage 32 `openwebui-signup-first-user-contract.md` / Open WebUI auth (different product)
- Stage 30 `n8n-auth-env-honesty-contract.md` (basic-auth / owner env honesty)
- Helper `CONTROL_TOKEN` (dashboard control plane, not n8n users)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service in `docker-compose.yml` | No security-policy or MFA keys today |
| Official n8n security-policy env | `N8N_SECURITY_POLICY_MANAGED_BY_ENV`, `N8N_MFA_ENFORCED_ENABLED` |
| Stage 34 personal-space page (expected sibling) | Owns the lock + publish/share false |
| `env.example` n8n block | Operator-facing keys; add a one-line comment |
| GitHub Issues suggestion form | Intake if someone wants recovery-code playbooks |

Out of scope:

- A custom TOTP sidecar, nginx MFA portal, or helper “enroll 2FA” API
- Rewriting Stage 34 personal-space publish/share keys
- Rewriting Stage 30 n8n auth honesty or Stage 32 Open WebUI signup
- Disabling local login in favor of a new IdP product

## Proposal

Reuse the official security-policy lock (set once with Stage 34) and add MFA enforcement:

```text
N8N_SECURITY_POLICY_MANAGED_BY_ENV: "true"
N8N_MFA_ENFORCED_ENABLED: "true"
```

If Stage 34 is implemented in the same change, keep personal-space publish/share false on that lock. Do not invent a second `TU_VM_N8N_MFA` flag.

Operators must enroll MFA at next login. Document backup codes in the n8n playbook; recovery stays official n8n owner/reset, not a TU-VM tool.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official MFA flag on the shared policy lock |
| Env schema | `env.example` | Comment that MFA is enforced when the instance is up |
| Docs | n8n playbook | Enroll 2FA before sharing the instance with the community |

### Rules

1. **Official keys only.** Do not invent project-local MFA env.
2. **One lock.** Do not add a second `*_MANAGED_BY_ENV` for MFA.
3. **Do not rewrite Stage 34.** Personal-space keys stay on that page.
4. **GitHub remains intake.** Recovery UX requests stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_MFA_ENFORCED_ENABLED
2. Set N8N_SECURITY_POLICY_MANAGED_BY_ENV=true once (shared with Stage 34)
3. Set N8N_MFA_ENFORCED_ENABLED=true
4. Recreate n8n and confirm the UI requires 2FA enrollment
5. Document official recovery; do not add a helper TOTP reset
6. Do not rewrite the Stage 34 personal-space page
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Force 2FA | Official `N8N_MFA_ENFORCED_ENABLED` | Nginx MFA or a helper TOTP app |
| Lock UI toggles | Official `N8N_SECURITY_POLICY_MANAGED_BY_ENV` | A second policy file |
| Share/publish off | Stage 34 personal-space keys | Rewriting that contract here |
| Instance login honesty | Stage 30 n8n auth env | Mixing owner password with MFA |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: two official Compose lines (lock + MFA) plus one playbook sentence.
3. Call out required 2FA enrollment in release notes (expected for shared community hosts).

## Acceptance criteria

- [ ] `n8n` sets `N8N_MFA_ENFORCED_ENABLED=true` with the official security-policy lock.
- [ ] Stage 34 personal-space page is not rewritten.
- [ ] No custom MFA sidecar or helper reset API is added.
- [ ] Playbook mentions official enrollment and recovery.

## Rollback

Set `N8N_MFA_ENFORCED_ENABLED=false` (or stop managing the policy from env). Existing TOTP enrollments remain on the volume until users remove them.

## Success metrics

- Shared-instance logins require 2FA after recreate.
- Community PRs that want “n8n MFA” cite this official key instead of a new auth product.
