---
title: Open WebUI Scarf Analytics Contract
description: Constructional contract to set official SCARF_NO_ANALYTICS=true so Open WebUI does not phone home via Scarf, completing the existing DO_NOT_TRACK / ANONYMIZED_TELEMETRY pair without a custom telemetry blocker.
last_updated: 2026-09-19
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Open WebUI Scarf Analytics Contract

## Problem

Open WebUI already sets official privacy flags:

```text
ANONYMIZED_TELEMETRY: "false"
DO_NOT_TRACK: "true"
```

It does **not** set `SCARF_NO_ANALYTICS`. Official Open WebUI deployment docs and the upstream `.env.example` treat Scarf as a **third** switch. `DO_NOT_TRACK` is not a substitute: Scarf package/install analytics can still fire unless `SCARF_NO_ANALYTICS=true`.

Community suggestions that “block scarf.sh in Pi-hole” or “wrap the image to strip pixels” reinvent an official env the project already follows for the other two keys.

This is distinct from:

- Stage 33 `openwebui-community-sharing-contract.md` (chat catalog, not install analytics)
- Stage 33 `openwebui-offline-embeddings-contract.md` (Hugging Face model fetch)
- Stage 35 `openwebui-version-update-check-contract.md` (GitHub version probe, not Scarf)
- n8n `N8N_DIAGNOSTICS_ENABLED` / `N8N_TELEMETRY_ENABLED` (already false on `n8n`)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment in `docker-compose.yml` | `DO_NOT_TRACK` + `ANONYMIZED_TELEMETRY` set; Scarf missing |
| Official Open WebUI env / upstream `.env.example` | `SCARF_NO_ANALYTICS=true` next to the other two |
| `env.example` Open WebUI block | Operator-facing comment home |
| Pi-hole (Stage 9 hygiene) | Optional extra DNS block; not the primary control |
| GitHub Issues suggestion form | Intake if someone wants admin-analytics UI off (`ENABLE_ADMIN_ANALYTICS`) |

Out of scope:

- A custom telemetry proxy or dashboard “privacy mode” product
- Rewriting Stage 33 community-sharing or offline-embeddings pages
- Blocking Scarf only in Pi-hole and calling the Compose gap closed
- Changing n8n diagnostics (already off)

## Proposal

Add the official third flag on the `open-webui` service:

```text
SCARF_NO_ANALYTICS: "true"
```

Keep the two existing keys. Do not invent `TU_VM_DISABLE_TELEMETRY`. If a later Issue wants the admin Analytics **tab** hidden, that is official `ENABLE_ADMIN_ANALYTICS=false` (in-product UI, not Scarf) and should be a separate small PR.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official `SCARF_NO_ANALYTICS=true` |
| Env schema | `env.example` | One-line comment that all three official privacy keys are set in Compose |
| Docs | Open WebUI playbook | Privacy defaults; Pi-hole blocklists are extra, not required |

### Rules

1. **Official key only.** Match upstream `.env.example` spelling.
2. **Do not drop `DO_NOT_TRACK`.** Scarf is additive, not a replacement.
3. **Do not rewrite Stage 33.** Sharing and HF offline stay on those pages.
4. **GitHub remains intake.** Admin-analytics tab requests stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image reads SCARF_NO_ANALYTICS
2. Set SCARF_NO_ANALYTICS=true next to DO_NOT_TRACK
3. Recreate open-webui and confirm no Scarf beacon on first paint / pip path
4. Leave ANONYMIZED_TELEMETRY=false and DO_NOT_TRACK=true
5. Do not add a Pi-hole-only “fix” or a telemetry sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Disable Scarf | Official `SCARF_NO_ANALYTICS` | Image patches or pixel scrapers |
| Honor DNT | Existing `DO_NOT_TRACK` | A second DNT wrapper |
| Hide admin charts | Official `ENABLE_ADMIN_ANALYTICS` (later Issue) | Removing the tab in nginx HTML |
| Model/version phone-home | Stage 33 HF offline + Stage 35 version-check | One “offline mega-flag” product |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line.
3. No operator-facing breaking change.

## Acceptance criteria

- [ ] `open-webui` sets `SCARF_NO_ANALYTICS=true`.
- [ ] Existing `DO_NOT_TRACK` and `ANONYMIZED_TELEMETRY` remain.
- [ ] No custom telemetry blocker is added.
- [ ] Stage 33 pages are not rewritten.

## Rollback

Remove the key (upstream default is already `true` in recent images; pinning the value keeps older digests honest).

## Success metrics

- Recreating Open WebUI does not contact Scarf collectors.
- Community PRs that want “more privacy” cite the official third key instead of a Pi-hole-only workaround.
