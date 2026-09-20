---
title: n8n Personalization Contract
description: Constructional contract to set official N8N_PERSONALIZATION_ENABLED=false so n8n does not ask personalisation survey questions, distinct from Stage 34 personal-space sharing and from Stage 36 hiring chrome.
last_updated: 2026-09-20
owner: maintainers
status: proposed
theme: community
impact: medium
---

# n8n Personalization Contract

## Problem

The `n8n` service does not set `N8N_PERSONALIZATION_ENABLED`. Official n8n deployment env documents that flag as a boolean that defaults to `true` and asks users personalisation questions, then customises the editor from the answers.

Those questions are a product-analytics / onboarding survey, not workflow configuration. A community LAN VM already disables n8n diagnostics and telemetry; leaving the survey on still collects role/use-case answers inside the editor and trains first-run UX on cloud assumptions.

This is distinct from:

- Stage 34 `n8n-personal-space-sharing-contract.md` (publish/share from personal space)
- Stage 36 `n8n-hiring-banner-contract.md` (recruiting chrome)
- Stage 35 `n8n-mfa-enforced-contract.md` (security-policy lock)
- Stage 32 first-user / signup honesty on Open WebUI (different product)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` environment | `N8N_DIAGNOSTICS_ENABLED=false`, `N8N_TELEMETRY_ENABLED=false`; personalization unset |
| Official n8n deployment env | `N8N_PERSONALIZATION_ENABLED` |
| GitHub Issues suggestion form | Intake for editor UX experiments |
| Playbooks | Operator first-run path |

Out of scope:

- A custom TU-VM onboarding wizard
- Rewriting Stage 34 personal-space keys
- Storing survey answers in the helper API

## Proposal

Set the official flag on the `n8n` service:

```text
N8N_PERSONALIZATION_ENABLED: "false"
```

Keep first-run operator guidance in playbooks and README. Do not invent `TU_VM_N8N_SURVEY`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag false |
| Env schema | `env.example` | Comment that the n8n survey is off |
| Docs | n8n playbook | First workflow via playbooks, not the in-app survey |

### Rules

1. **Official key only.** Match n8n deployment docs spelling.
2. **Do not confuse with personal space.** Stage 34 owns publish/share flags.
3. **Do not confuse with hiring.** Stage 36 hiring banner is editor chrome, not questions.
4. **GitHub remains intake.** Local onboarding-wizard ideas stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_PERSONALIZATION_ENABLED
2. Set the flag false on the n8n service
3. Recreate n8n and confirm no personalisation question flow
4. Point first-run operators at playbooks
5. Do not add a helper survey or rewrite Stage 34 personal-space
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Skip the survey | Official `N8N_PERSONALIZATION_ENABLED` | A custom onboarding product |
| First-run help | Existing playbooks + README | Storing answers in Postgres as “profiles” |
| Personal-space ACL | Stage 34 official security-policy keys | Mixing survey with sharing |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line.
3. Existing n8n users keep their workflows; only the survey is skipped.

## Acceptance criteria

- [ ] `n8n` sets `N8N_PERSONALIZATION_ENABLED=false`.
- [ ] No custom onboarding wizard is added.
- [ ] Stage 34 personal-space page is not rewritten.

## Rollback

Set the flag `true` (official default). Volume data remains.

## Success metrics

- New n8n sessions skip personalisation questions.
- Community first-run PRs cite playbooks instead of an in-app survey.
