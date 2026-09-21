---
title: n8n Onboarding Flow Disabled Contract
description: Constructional contract to set official N8N_ONBOARDING_FLOW_DISABLED=true so new-workflow editor tips stay off, distinct from Stage 36 personalization survey and Stage 34 templates.
last_updated: 2026-09-21
owner: maintainers
status: proposed
theme: community
impact: low
---

# n8n Onboarding Flow Disabled Contract

## Problem

The `n8n` service does not set `N8N_ONBOARDING_FLOW_DISABLED`. Official n8n workflow env documents that boolean as defaulting to `false`, which shows onboarding tips when a contributor creates a new workflow.

A LAN-first community VM already teaches operators through [`CONTRIBUTING.md`](../../CONTRIBUTING.md), [`docs/playbooks/`](../../docs/playbooks/README.md), and GitHub Issues. In-editor product tips compete with those paths and look like a second onboarding product.

This is distinct from:

- Stage 36 `n8n-personalization-contract.md` (`N8N_PERSONALIZATION_ENABLED` survey questions)
- Stage 36 `n8n-hiring-banner-contract.md` (hiring chrome)
- Stage 34 `n8n-templates-disabled-contract.md` (workflow JSON gallery)
- Stage 35 `n8n-version-notifications-contract.md` (`api.n8n.io/versions/` banners)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` environment | Diagnostics and telemetry already false; onboarding tips unset |
| Official n8n workflow env | `N8N_ONBOARDING_FLOW_DISABLED` |
| Playbooks + CONTRIBUTING | How operators learn the stack |
| GitHub Issues suggestion form | Community intake |

Out of scope:

- A custom “first workflow” wizard on the Nginx dashboard
- CSS/`sub_filter` hides of tip strings
- Rewriting Stage 36 personalization or Stage 34 templates

## Proposal

Set the official flag on the `n8n` service:

```text
N8N_ONBOARDING_FLOW_DISABLED: "true"
```

Do not invent `TU_VM_N8N_SKIP_TIPS`. Community onboarding stays on playbooks and GitHub.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag true |
| Env schema | `env.example` | Optional comment that editor tips are off |
| Docs | n8n playbook | Point first-workflow help at playbooks / Issues |

### Rules

1. **Official key only.** Match n8n workflow env spelling.
2. **Do not confuse with personalization.** Stage 36 owns the survey.
3. **Do not confuse with templates.** Stage 34 owns the gallery.
4. **GitHub remains intake.** Local wizard ideas stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_ONBOARDING_FLOW_DISABLED
2. Set the flag true on the n8n service
3. Recreate n8n and confirm new-workflow tips are absent
4. Leave playbooks / Issues as the first-workflow path
5. Do not add a dashboard wizard or rewrite Stage 36 personalization
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hide editor tips | Official `N8N_ONBOARDING_FLOW_DISABLED` | CSS hides or `sub_filter` |
| First-workflow help | Playbooks + GitHub Issues | An in-editor CMS |
| Survey / templates | Stage 36 / Stage 34 official flags | Mixing tips with those products |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line.
3. Missing tips are expected (docs-first community).

## Acceptance criteria

- [ ] `n8n` sets `N8N_ONBOARDING_FLOW_DISABLED=true`.
- [ ] No first-workflow CMS or CSS hide is added.
- [ ] Stage 36 personalization page is not rewritten.

## Rollback

Set the flag `false` (official default). Volume data remains.

## Success metrics

- Recreating n8n does not show new-workflow onboarding tips.
- “How do I start a workflow?” questions cite playbooks / Issues.
