---
title: n8n Hide Usage Page Contract
description: Constructional contract to set official N8N_HIDE_USAGE_PAGE=true so the editor does not show usage/plans license chrome, distinct from Stage 34 templates and Stage 35 version notifications.
last_updated: 2026-09-20
owner: maintainers
status: proposed
theme: community
impact: medium
---

# n8n Hide Usage Page Contract

## Problem

The `n8n` service does not set `N8N_HIDE_USAGE_PAGE`. Official n8n license env documents that flag as a boolean that defaults to `false` and keeps the usage/plans page visible in the app.

That page is cloud-license chrome. A community self-hosted VM does not sell plans and already pins images via `./tu-vm.sh update`. Leaving the page on invites “activate a license” / “view usage” detours that do not apply to this LAN topology.

This is distinct from:

- Stage 34 `n8n-templates-disabled-contract.md` (workflow JSON gallery)
- Stage 35 `n8n-version-notifications-contract.md` (`/versions/` poll)
- Stage 36 `n8n-hiring-banner-contract.md` (recruiting chrome)
- Stage 35 Swagger UI (API playground, not license UI)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` environment | No license/usage keys set |
| Official n8n license env | `N8N_HIDE_USAGE_PAGE` |
| `./tu-vm.sh update` + Stage 15 (expected sibling) | How this community ships upgrades |
| GitHub Releases / `CHANGELOG.md` | Human “what is new” |

Out of scope:

- Activating or storing `N8N_LICENSE_ACTIVATION_KEY` in-repo
- A custom billing/usage dashboard
- Rewriting Stage 34 templates or Stage 35 version notifications
- Disabling the n8n public API (MCP needs it)

## Proposal

Set the official flag on the `n8n` service:

```text
N8N_HIDE_USAGE_PAGE: "true"
```

Do not invent `TU_VM_N8N_HIDE_BILLING`. Do not commit license keys. If a later operator has an n8n license, they can set the official license env in **local** `.env` and turn this flag back to `false` on that host.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag true |
| Env schema | `env.example` | Comment that usage/plans chrome is hidden by default |
| Docs | n8n playbook | Upgrades via `tu-vm.sh update`, not the usage page |

### Rules

1. **Official key only.** Match n8n license env spelling.
2. **Do not commit license keys.** `.env` stays local.
3. **Do not confuse with templates or versions.** Those stay on Stage 34 / 35.
4. **GitHub remains intake.** Local usage-meter ideas stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_HIDE_USAGE_PAGE
2. Set the flag true on the n8n service
3. Recreate n8n and confirm the usage/plans page is hidden
4. Point operators at tu-vm.sh update / Releases
5. Do not add a billing portal or rewrite Stage 34 / 35
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hide usage/plans | Official `N8N_HIDE_USAGE_PAGE` | CSS hides or a license portal |
| Ship upgrades | Stage 15 + `tu-vm.sh update` | Teaching operators to open n8n usage |
| License later | Official license env in local `.env` | Checking license secrets into git |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line.
3. Missing usage chrome is expected (self-hosted community).

## Acceptance criteria

- [ ] `n8n` sets `N8N_HIDE_USAGE_PAGE=true`.
- [ ] No license key is added to the repository.
- [ ] Stage 34 templates and Stage 35 version pages are not rewritten.

## Rollback

Set the flag `false` (official default). Volume data remains.

## Success metrics

- Recreating n8n does not show usage/plans chrome.
- Community upgrade questions cite Releases instead of the usage page.
