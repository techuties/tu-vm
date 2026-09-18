---
title: n8n Templates Disabled Contract
description: Constructional contract to set official N8N_TEMPLATES_ENABLED=false so the editor does not fetch workflow templates from api.n8n.io, with an optional official N8N_TEMPLATES_HOST if the community later hosts a matching catalog.
last_updated: 2026-09-18
owner: maintainers
status: proposed
theme: community
impact: high
---

# n8n Templates Disabled Contract

## Problem

The `n8n` service does not set `N8N_TEMPLATES_ENABLED`. Official n8n defaults that flag to `true` and loads the template gallery from `N8N_TEMPLATES_HOST` (`https://api.n8n.io` by default). On a LAN-first private AI VM, opening the template browser phones home and offers cloud workflows that may assume SaaS credentials, public webhooks, or nodes the operator never reviewed.

Community suggestions that “build a TU-VM template store” often propose a scraper, a Markdown CMS, or copying Stage 33 Open WebUI community-sharing work. The official switch is already there and is unset today.

This is distinct from:

- Stage 33 `openwebui-community-sharing-contract.md` (Open WebUI chat catalog, not n8n templates)
- Stage 34 `n8n-community-packages-contract.md` (npm community *nodes*, not workflow JSON)
- Stage 34 `n8n-personal-space-sharing-contract.md` (in-instance share/publish, not the public gallery)
- Stage 6 airgap docs (documentation/image mirrors, not the n8n template API)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service in `docker-compose.yml` | No templates keys today |
| Official n8n deployment env | `N8N_TEMPLATES_ENABLED`, `N8N_TEMPLATES_HOST` |
| `env.example` n8n block | Operator-facing keys; add a one-line comment |
| GitHub Issues suggestion form | Intake if someone wants a local catalog later |

Out of scope:

- A custom template CMS, scraper, or marketplace UI
- Rewriting Stage 33 Open WebUI community-sharing
- Rewriting Stage 34 community-packages or personal-space pages
- Hosting `api.n8n.io` content in-tree

## Proposal

Set the official flag on the `n8n` service:

```text
N8N_TEMPLATES_ENABLED: "false"
```

If the community later wants a shared catalog, reuse official `N8N_TEMPLATES_HOST` pointed at a LAN service that implements the same endpoints and response shape as n8n's template API. Do not add a TU-VM template database or dashboard page for that.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official `N8N_TEMPLATES_ENABLED=false` |
| Env schema | `env.example` | Comment; optional `N8N_TEMPLATES_HOST` only if a matching LAN API exists |
| Docs | n8n playbook | Template browser is off; share workflows via GitHub Issues / git, not n8n.io |

### Rules

1. **Official keys only.** Do not invent `TU_VM_N8N_TEMPLATES`.
2. **Do not confuse with community npm nodes.** Packages are a different official surface.
3. **Do not confuse with Open WebUI sharing.** Stage 33 owns `ENABLE_COMMUNITY_SHARING`.
4. **GitHub remains intake.** Requests for a local catalog stay Issues until a matching host exists.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_TEMPLATES_ENABLED
2. Set the flag false on the n8n service
3. Recreate n8n and confirm the template browser does not call api.n8n.io
4. Document git / GitHub as the workflow-share path
5. Do not add a template CMS or scraper
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Disable cloud templates | Official `N8N_TEMPLATES_ENABLED` | Blocking `api.n8n.io` only in Pi-hole |
| Local catalog later | Official `N8N_TEMPLATES_HOST` | A custom marketplace |
| Share reviewed workflows | Git + GitHub Issues | Publishing operator secrets into gallery JSON |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + one playbook sentence.
3. Call out the missing template browser in release notes (expected, LAN-first).

## Acceptance criteria

- [ ] `n8n` sets `N8N_TEMPLATES_ENABLED=false`.
- [ ] Docs mention GitHub/git as the share path.
- [ ] No template CMS or scraper is added.
- [ ] Stage 33 community-sharing and Stage 34 package/personal-space pages are not rewritten.

## Rollback

Remove the env flag (or set `true`). The official gallery returns. Volume data remains.

## Success metrics

- Recreating n8n does not request `api.n8n.io` for templates.
- Community PRs that want a catalog cite `N8N_TEMPLATES_HOST` instead of a new product.
