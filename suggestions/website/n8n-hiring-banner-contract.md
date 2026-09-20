---
title: n8n Hiring Banner Contract
description: Constructional contract to set official N8N_HIRING_BANNER_ENABLED=false so the editor and console do not show n8n hiring chrome, distinct from Stage 35 version notifications and Stage 34 templates.
last_updated: 2026-09-20
owner: maintainers
status: proposed
theme: community
impact: low
---

# n8n Hiring Banner Contract

## Problem

The `n8n` service does not set `N8N_HIRING_BANNER_ENABLED`. Official n8n deployment env documents that flag as a boolean that defaults to `true` and shows hiring chrome in the console/editor.

A LAN-first community VM is not a recruiting surface. Contributors should discover how to help via GitHub Issues and [`CONTRIBUTING.md`](../../CONTRIBUTING.md), not via cloud hiring copy inside the workflow editor.

This is distinct from:

- Stage 35 `n8n-version-notifications-contract.md` (`api.n8n.io/versions/` banners)
- Stage 34 `n8n-templates-disabled-contract.md` (workflow JSON gallery)
- Stage 36 `n8n-personalization-contract.md` (onboarding survey questions)
- Stage 36 `n8n-hide-usage-page-contract.md` (usage/plans license chrome)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` environment | Diagnostics and telemetry already false; hiring banner unset |
| Official n8n deployment env | `N8N_HIRING_BANNER_ENABLED` |
| GitHub Issues suggestion form | Community intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | How to help |

Out of scope:

- A custom “careers” widget on the Nginx dashboard
- CSS/`sub_filter` hides of hiring strings
- Rewriting Stage 35 version notifications or Stage 34 templates

## Proposal

Set the official flag on the `n8n` service:

```text
N8N_HIRING_BANNER_ENABLED: "false"
```

Do not invent `TU_VM_N8N_HIDE_HIRING`. Community recruiting stays on GitHub.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag false |
| Env schema | `env.example` | Optional comment that hiring chrome is off |
| Docs | n8n playbook | Point helpers at CONTRIBUTING / Issues |

### Rules

1. **Official key only.** Match n8n deployment docs spelling.
2. **Do not confuse with version banners.** Stage 35 owns `N8N_VERSION_NOTIFICATIONS_ENABLED`.
3. **Do not confuse with personalization.** Stage 36 personalization is the survey, not hiring chrome.
4. **GitHub remains intake.** Local careers-page ideas stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_HIRING_BANNER_ENABLED
2. Set the flag false on the n8n service
3. Recreate n8n and confirm the hiring banner is absent
4. Leave CONTRIBUTING.md / Issues as the help path
5. Do not add a dashboard careers widget or rewrite Stage 35
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hide hiring chrome | Official `N8N_HIRING_BANNER_ENABLED` | CSS hides or `sub_filter` |
| Community help | GitHub Issues + CONTRIBUTING | An in-editor recruiting CMS |
| Version / template chrome | Stage 35 / Stage 34 official flags | Mixing hiring with `/versions/` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line.
3. Missing hiring chrome is expected (LAN-first).

## Acceptance criteria

- [ ] `n8n` sets `N8N_HIRING_BANNER_ENABLED=false`.
- [ ] No careers CMS or CSS hide is added.
- [ ] Stage 35 version-notifications page is not rewritten.

## Rollback

Set the flag `true` (official default). Volume data remains.

## Success metrics

- Recreating n8n does not show hiring chrome.
- Community “how do I help?” questions cite Issues / CONTRIBUTING.
