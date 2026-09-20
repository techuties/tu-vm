---
title: Open WebUI PersistentConfig Honesty Contract
description: Constructional contract to set official ENABLE_PERSISTENT_CONFIG=false so community Compose/env contracts win over Admin UI database values, without inventing a settings-sync sidecar.
last_updated: 2026-09-20
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI PersistentConfig Honesty Contract

## Problem

Official Open WebUI env documents `ENABLE_PERSISTENT_CONFIG` (default `true`): values saved in the Admin UI **database** take precedence over environment variables for keys marked PersistentConfig.

TU-VM already proposes many Open WebUI flags as Compose source of truth (signup, community sharing, CORS, API keys, version-check, code-related keys, and more). With the default left on, a single Admin UI click silently overrides the Git-reviewed contract. The next recreate “looks like Compose is ignored,” which produces duplicate Issues and custom “settings export” sidecars.

`ENABLE_ADMIN_ANALYTICS` (Stage 36) is env-only and restart-gated; it is **not** the same switch. PersistentConfig is the framework that decides whether community env contracts stick.

This is distinct from:

- Stage 32 `openwebui-compose-env-honesty-contract.md` (unofficial `WEBUI_*` names)
- Stage 32 `openwebui-signup-first-user-contract.md` (`ENABLE_SIGNUP` value)
- Stage 33 / 34 / 35 Open WebUI product flags (what to set, not which store wins)
- Helper `/status/full` (runtime health, not Admin settings)

Official docs warn: when PersistentConfig is `false`, Admin UI edits may apply to the **current process** and are **lost on restart**. That is the intended GitOps tradeoff for this community stack.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment | Many flags; `ENABLE_PERSISTENT_CONFIG` unset (default true) |
| Official Open WebUI env | PersistentConfig precedence + warning |
| `env.example` / Compose | Community-reviewed source of truth |
| GitHub Issues + PR templates | How settings changes should land |
| Stage 32 compose-env honesty (expected sibling) | Name honesty, not store honesty |

Out of scope:

- A helper “sync Admin UI to git” product
- Dumping the Open WebUI settings table into the repo
- Rewriting Stage 32–35 product-flag pages
- Turning on `OFFLINE_MODE` as a substitute

## Proposal

Set the official store-precedence flag on the `open-webui` service:

```text
ENABLE_PERSISTENT_CONFIG: "false"
```

Document the official warning in the Open WebUI playbook: change durable settings via Compose / `.env` + PR, not the Admin UI.

Do not invent `TU_VM_WEBUI_GITOPS`. Do not add a settings exporter.

If a later Issue needs a **mixed** mode (some keys from DB), that is still official PersistentConfig `true` plus documented Admin UI steps—not a sidecar.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false |
| Env schema | `env.example` | Comment that Compose wins; Admin UI edits do not persist |
| Docs | Open WebUI playbook | GitOps path + official warning |
| CONTRIBUTING | short note | Open WebUI behavior changes go through env/PRs |

### Rules

1. **Official key only.** Match Open WebUI env docs spelling.
2. **Do not rewrite product-flag pages.** Those still name the keys to set.
3. **Do not add a settings-sync sidecar.**
4. **GitHub remains intake.** Mixed-mode / per-key DB exceptions stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_PERSISTENT_CONFIG
2. Set the flag false on the open-webui service
3. Recreate open-webui and confirm an Admin UI toggle reverts after restart
4. Add the official warning to the Open WebUI playbook
5. Do not add a settings exporter or rewrite Stage 32–35 flag pages
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Env wins over Admin UI | Official `ENABLE_PERSISTENT_CONFIG` | A sync sidecar or DB dump |
| Name honesty | Stage 32 unofficial `WEBUI_*` page | Inventing more `WEBUI_*` keys |
| Reviewable changes | GitHub PR on Compose / `.env.example` | Teaching operators to “just click Admin” |
| Tab vs pixel privacy | Stage 36 Analytics + Stage 35 Scarf | Using PersistentConfig as a telemetry flag |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + playbook warning.
3. Call out the official “Admin edits do not persist” behavior in release notes when implemented.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_PERSISTENT_CONFIG=false`.
- [ ] Playbook states the official Admin UI warning.
- [ ] No settings-sync sidecar is added.
- [ ] Stage 32–35 Open WebUI product-flag pages are not rewritten.

## Rollback

Set the flag `true` (official default) and recreate. Database-stored PersistentConfig values start winning again.

## Success metrics

- Recreating Open WebUI reapplies Compose/env contracts after Admin UI clicks.
- Community “why did my env vanish?” Issues drop; PRs cite this flag.
