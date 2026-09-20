---
title: Open WebUI Admin Analytics Contract
description: Constructional contract to set official ENABLE_ADMIN_ANALYTICS=false so the admin Analytics tab and its API router stay off, distinct from Stage 35 SCARF_NO_ANALYTICS.
last_updated: 2026-09-20
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Open WebUI Admin Analytics Contract

## Problem

Open WebUI already sets `ANONYMIZED_TELEMETRY=false` and `DO_NOT_TRACK=true`. Stage 35 adds official `SCARF_NO_ANALYTICS=true` for install/package pixels.

It does **not** set `ENABLE_ADMIN_ANALYTICS`. Official Open WebUI env documents that flag as a boolean that defaults to `true` and controls whether the admin-panel **Analytics** tab is visible and whether the analytics API router is mounted. Disabling the tab is not a substitute for Scarf, and Scarf is not a substitute for the tab.

Community suggestions that “delete the Analytics nav in nginx HTML” or “proxy-filter `/api/v1/analytics`” reinvent an official env.

This is distinct from:

- Stage 35 `openwebui-scarf-analytics-contract.md` (Scarf pixels, not the admin tab)
- Stage 35 `openwebui-version-update-check-contract.md` (GitHub version badge)
- Stage 33 `openwebui-community-sharing-contract.md` (chat catalog)
- Helper `/status/full` (operator health, not user-chat analytics)

Official docs also note that hiding the tab does not erase historical rows already in Postgres; it removes the in-product surface. That is enough for a LAN community default.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment | DNT + anonymized telemetry set; admin Analytics unset |
| Official Open WebUI env | `ENABLE_ADMIN_ANALYTICS` (restart required; not PersistentConfig) |
| Stage 35 Scarf (expected sibling) | Third privacy switch; implement in **code**, do not rewrite |
| GitHub Issues suggestion form | Intake if someone wants DB purge of old analytics rows |

Out of scope:

- A custom analytics product on the landing dashboard
- Rewriting Stage 35 Scarf or version-check pages
- Nginx HTML surgery on the Open WebUI admin chrome
- Deleting Open WebUI Postgres tables

## Proposal

Set the official flag on the `open-webui` service:

```text
ENABLE_ADMIN_ANALYTICS: "false"
```

Keep DNT / anonymized telemetry / (Stage 35) Scarf. Do not invent `TU_VM_DISABLE_ADMIN_CHARTS`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false |
| Env schema | `env.example` | Comment that the admin Analytics tab is off |
| Docs | Open WebUI playbook | Operator health stays on `/status/*` and playbooks |

### Rules

1. **Official key only.** Match Open WebUI env docs spelling.
2. **Do not confuse with Scarf.** Stage 35 owns `SCARF_NO_ANALYTICS`.
3. **Do not filter routes in Nginx** as the primary control.
4. **GitHub remains intake.** Historical-row purge ideas stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_ADMIN_ANALYTICS
2. Set the flag false on the open-webui service
3. Recreate open-webui and confirm the admin Analytics tab is gone
4. Leave DNT / anonymized telemetry / Scarf on their own keys
5. Do not rewrite Stage 35 Scarf or add a dashboard charts product
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hide admin Analytics | Official `ENABLE_ADMIN_ANALYTICS` | Nginx HTML / API filters |
| Scarf / install pixels | Stage 35 official Scarf key | Mixing Scarf with this tab |
| Operator health | Existing `/status/*` + playbooks | Rebuilding charts in helper |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + recreate.
3. Admins lose the tab only; chats and models stay.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_ADMIN_ANALYTICS=false`.
- [ ] No custom analytics UI is added.
- [ ] Stage 35 Scarf page is not rewritten.

## Rollback

Set the flag `true` (official default) and recreate. Volume data remains.

## Success metrics

- Recreating Open WebUI hides the admin Analytics tab.
- Community privacy PRs cite this key for the tab and Stage 35 for Scarf.
