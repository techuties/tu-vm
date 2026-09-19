---
title: n8n Version Notifications Contract
description: Constructional contract to set official N8N_VERSION_NOTIFICATIONS_ENABLED=false so the editor does not poll api.n8n.io/versions/, distinct from Stage 34 workflow templates and from Open WebUI GitHub version checks.
last_updated: 2026-09-19
owner: maintainers
status: proposed
theme: community
impact: medium
---

# n8n Version Notifications Contract

## Problem

The `n8n` service does not set `N8N_VERSION_NOTIFICATIONS_ENABLED`. Official n8n defaults that flag to `true` and fetches version/security banners from `N8N_VERSION_NOTIFICATIONS_ENDPOINT` (`https://api.n8n.io/versions/` by default).

That is a different official surface from Stage 34 templates (`N8N_TEMPLATES_ENABLED` / `api.n8n.io` template catalog). A LAN-first community VM that already disables n8n diagnostics and telemetry still phones home for “what’s new” unless this flag is off. Contributors should hear about updates from `./tu-vm.sh update` and GitHub Releases, not from a cloud banner inside the editor.

This is distinct from:

- Stage 34 `n8n-templates-disabled-contract.md` (workflow JSON gallery, not `/versions/`)
- Stage 35 `openwebui-version-update-check-contract.md` (Open WebUI GitHub check)
- Stage 15 safe-update / digest pin workflow (how *we* bump images)
- Stage 6 airgap docs (mirrors, not this n8n poll)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` environment | `N8N_DIAGNOSTICS_ENABLED=false`, `N8N_TELEMETRY_ENABLED=false`; version notifications unset |
| Official n8n deployment env | `N8N_VERSION_NOTIFICATIONS_ENABLED`, optional endpoint / info URL |
| `./tu-vm.sh update` + Stage 15 (expected sibling) | Community-approved image bump path |
| GitHub Releases / `CHANGELOG.md` | Human “what is new” |
| GitHub Issues suggestion form | Intake if someone wants a LAN versions endpoint later |

Out of scope:

- A custom “n8n what’s new” CMS or dashboard widget
- Rewriting Stage 34 templates or Stage 15 safe-update
- Hosting `api.n8n.io/versions/` in-tree
- Pi-hole-only blocking of `api.n8n.io` as the complete fix

## Proposal

Set the official flag on the `n8n` service:

```text
N8N_VERSION_NOTIFICATIONS_ENABLED: "false"
```

If the community later wants a matching banner, reuse official `N8N_VERSION_NOTIFICATIONS_ENDPOINT` pointed at a LAN service with the same response shape. Do not add a TU-VM versions database.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag false |
| Env schema | `env.example` | Comment; optional endpoint only if a matching LAN API exists |
| Docs | n8n playbook | Updates come from `tu-vm.sh update` / Releases, not the editor banner |

### Rules

1. **Official keys only.** Do not invent `TU_VM_N8N_UPDATE_BANNER`.
2. **Do not confuse with templates.** Stage 34 owns `N8N_TEMPLATES_ENABLED`.
3. **Do not confuse with Open WebUI.** Stage 35 version-update-check is a different product key.
4. **GitHub remains intake.** Local versions-API ideas stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_VERSION_NOTIFICATIONS_ENABLED
2. Set the flag false on the n8n service
3. Recreate n8n and confirm no request to api.n8n.io/versions/
4. Point operators at tu-vm.sh update + Releases
5. Do not add a versions CMS or rewrite Stage 34 templates
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Silence cloud version banners | Official `N8N_VERSION_NOTIFICATIONS_ENABLED` | Pi-hole-only blocks |
| Ship upgrades | Stage 15 + `tu-vm.sh update` | Teaching operators to click n8n.io in the editor |
| Local banner later | Official `N8N_VERSION_NOTIFICATIONS_ENDPOINT` | A custom what’s-new product |
| Template gallery | Stage 34 templates flag | Mixing `/versions/` with workflow JSON |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + one playbook sentence.
3. Missing editor banner is expected (LAN-first).

## Acceptance criteria

- [ ] `n8n` sets `N8N_VERSION_NOTIFICATIONS_ENABLED=false`.
- [ ] Docs point at `tu-vm.sh update` / Releases.
- [ ] No versions CMS is added.
- [ ] Stage 34 templates page is not rewritten.

## Rollback

Set the flag `true` (official default). Volume data remains.

## Success metrics

- Recreating n8n does not poll `api.n8n.io/versions/`.
- Community update questions cite Releases instead of the editor banner.
