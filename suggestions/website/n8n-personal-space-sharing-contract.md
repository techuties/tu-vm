---
title: n8n Personal Space Sharing Contract
description: Constructional contract to turn off official n8n personal-space publishing and sharing with security-policy env keys, instead of building a share-catalog UI.
last_updated: 2026-09-18
owner: maintainers
status: proposed
theme: community
impact: medium
---

# n8n Personal Space Sharing Contract

## Problem

Official n8n can let users publish and share resources from their personal space (`N8N_PERSONAL_SPACE_PUBLISHING_ENABLED` and `N8N_PERSONAL_SPACE_SHARING_ENABLED`, both default `true`). On a multi-user LAN instance that is still a *private* AI platform, those defaults invite in-product distribution of workflows that may contain credentials, webhook URLs, or customer data.

Community suggestions that “add a TU-VM workflow gallery” often propose a dashboard catalog or copying Stage 33 Open WebUI `ENABLE_COMMUNITY_SHARING`. That flag is a different product. n8n already has security-policy environment variables and a `N8N_SECURITY_POLICY_MANAGED_BY_ENV` lock so the UI cannot silently turn sharing back on.

This is distinct from:

- Stage 33 `openwebui-community-sharing-contract.md` (Open WebUI public catalog)
- Stage 34 `n8n-templates-disabled-contract.md` (cloud template *fetch*)
- Stage 34 `n8n-community-packages-contract.md` (npm nodes)
- Stage 30 `n8n-auth-env-honesty-contract.md` (gateway `N8N_USER` / `N8N_PASSWORD`)
- Stage 32 `openwebui-signup-first-user-contract.md` (who can create accounts)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service in `docker-compose.yml` | No security-policy keys today |
| Official n8n security env | `N8N_SECURITY_POLICY_MANAGED_BY_ENV`, `N8N_PERSONAL_SPACE_PUBLISHING_ENABLED`, `N8N_PERSONAL_SPACE_SHARING_ENABLED` |
| Official n8n security env | `N8N_MFA_ENFORCED_ENABLED` (related, out of scope unless a later stage) |
| GitHub + git | Existing community share path for reviewed workflows |

Out of scope:

- A TU-VM share catalog, gallery page, or voting UI
- Rewriting Stage 33 Open WebUI community-sharing
- Rewriting Stage 34 templates or community-packages
- Forcing MFA on this page (worth a future contract; do not overload)

## Proposal

Lock the official security policy from environment variables:

```text
N8N_SECURITY_POLICY_MANAGED_BY_ENV: "true"
N8N_PERSONAL_SPACE_PUBLISHING_ENABLED: "false"
N8N_PERSONAL_SPACE_SHARING_ENABLED: "false"
```

Confirm the pinned n8n digest documents these keys (they landed on the official security env page). If the digest is older and ignores them, keep this contract proposed and bump via Stage 15 safe-update rather than inventing a UI patch.

Community sharing of *reviewed* workflows stays on GitHub Issues and git, matching the templates contract.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official security-policy lock + both flags false |
| Env schema | `env.example` | Comment only |
| Docs | n8n playbook | In-product share/publish is off; use git |

### Rules

1. **Official keys only.** Do not invent `TU_VM_N8N_GALLERY`.
2. **Lock the UI.** Set `N8N_SECURITY_POLICY_MANAGED_BY_ENV=true` so settings cannot override.
3. **Do not confuse with Open WebUI sharing.** Stage 33 owns `ENABLE_COMMUNITY_SHARING`.
4. **Do not confuse with templates.** Templates are inbound from `api.n8n.io`.
5. **GitHub remains intake.** Requests to re-enable sharing stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents the personal-space security-policy keys
2. Set managed-by-env true and both sharing/publishing flags false
3. Recreate n8n and confirm share/publish controls are off or read-only
4. Document git as the workflow-share path
5. Do not add a gallery UI
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stop in-product share | Official personal-space flags | A hide-CSS patch |
| Keep settings from flipping | Official `N8N_SECURITY_POLICY_MANAGED_BY_ENV` | A helper that rewrites the DB |
| Reviewed distribution | GitHub Issues + git | A local voting catalog |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: three Compose lines + one playbook sentence.
3. Call out missing share/publish buttons in release notes (expected).

## Acceptance criteria

- [ ] `n8n` sets both personal-space flags to `false`.
- [ ] `N8N_SECURITY_POLICY_MANAGED_BY_ENV` is `true` when the image supports it.
- [ ] Docs point workflow sharing at GitHub/git.
- [ ] No gallery UI is added.
- [ ] Stage 33 Open WebUI sharing and Stage 34 templates/packages pages are not rewritten.

## Rollback

Remove the three keys (official defaults re-enable personal-space share/publish). Volume data remains.

## Success metrics

- Share/publish from personal space is unavailable on a default n8n start.
- Community “gallery” PRs are closed as duplicates of this official-key approach plus GitHub intake.
