---
title: Open WebUI Community Sharing Contract
description: Constructional contract to set official ENABLE_COMMUNITY_SHARING=false so private chats and prompts are not offered to a public catalog, instead of a share-CMS sidecar.
last_updated: 2026-09-17
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Open WebUI Community Sharing Contract

## Problem

TU-VM is a LAN-first private AI stack. Open WebUI can offer community sharing (prompts, models, chats) when the official `ENABLE_COMMUNITY_SHARING` flag is left at image default. Compose does not set the key. Operators who wanted a private instance can still see share affordances that point at a public catalog.

Community suggestions then propose a local share CMS, a “community portal” next to the Nginx dashboard, or rewriting Stage 32 signup (`ENABLE_SIGNUP`). Signup is first-admin bootstrap. This page is only **official community-sharing off**.

This is distinct from:

- Stage 32 `openwebui-signup-first-user-contract.md` (`ENABLE_SIGNUP` after first admin)
- Stage 32 `openwebui-compose-env-honesty-contract.md` (drop unofficial `WEBUI_*` keys)
- Stage 31 `openwebui-public-url-contract.md` (`WEBUI_URL` / public origin)
- This repo’s GitHub Issues suggestion form (the real community intake)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment | Auth + telemetry already set; no sharing flag |
| Official Open WebUI env | `ENABLE_COMMUNITY_SHARING` |
| GitHub Issues + suggestion form | Sole proposal intake for TU-VM itself |
| Stage 32 signup (expected sibling) | First-user bootstrap, not sharing |

Out of scope:

- A local share catalog or CMS
- Changing GitHub Issues as community intake
- Rewriting unofficial `WEBUI_*` cleanup (Stage 32)
- Disabling all Open WebUI tool/function community features beyond this official key

## Proposal

Set the official flag on the `open-webui` service:

```text
ENABLE_COMMUNITY_SHARING: "false"
```

If the pinned image uses a different official name in its env list, use that name—do not invent a `TU_VM_` prefix. Document that TU-VM community ideas still go to GitHub Issues, not an in-app share button.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag `false` |
| Env schema | `env.example` | Optional interpolable override defaulting false |
| Docs | CONTRIBUTING + Open WebUI playbook | Sharing off; GitHub remains intake |

### Rules

1. **Official key only.** Do not invent `TU_VM_DISABLE_SHARE`.
2. **Do not confuse with signup.** Stage 32 owns `ENABLE_SIGNUP`.
3. **Do not add a share CMS** on the landing dashboard.
4. **GitHub remains intake.** That is already the community system.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_COMMUNITY_SHARING
2. Set the flag false on the open-webui service
3. Recreate Open WebUI and confirm share-to-community affordances are gone
4. Keep GitHub Issues as the suggestion path in docs
5. Do not add a local catalog database
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Private by default | Official Open WebUI flag | Share-CMS sidecar |
| First admin | Stage 32 `ENABLE_SIGNUP` | Mixing signup into this page |
| TU-VM ideas | GitHub suggestion form | Dashboard voting |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line (+ optional `env.example`).
3. No operator-visible break except missing share buttons (desired).

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_COMMUNITY_SHARING=false` (or the pinned image’s official equivalent).
- [ ] Docs state GitHub Issues remain the community path.
- [ ] No local share catalog or voting DB is added.
- [ ] Stage 32 signup / unofficial `WEBUI_*` pages are not rewritten.

## Rollback

Remove the flag (or set `true`). Image default share affordances return. Chats remain local.

## Success metrics

- Private-instance reviews no longer file “turn off community share” as a new product.
- Contributors do not open PRs that add an in-stack share CMS.
