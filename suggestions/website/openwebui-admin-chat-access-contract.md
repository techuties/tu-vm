---
title: Open WebUI Admin Chat Access Contract
description: Constructional contract to set official ENABLE_ADMIN_CHAT_ACCESS=false so admins do not open other users' chats from the admin panel.
last_updated: 2026-09-22
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Admin Chat Access Contract

## Problem

Official Open WebUI `ENABLE_ADMIN_CHAT_ACCESS` defaults to `true`. Admins can open other users' chats from the admin panel, and the matching endpoints accept those requests. The env reference is explicit: this toggle controls the in-product surface. An admin who can reach Postgres can still read rows on the host. That host path is an operator break-glass action, not the everyday community UI.

Compose leaves the flag unset, so the default stays on. A shared TU-VM is a community system: household and teammate chats should not be one click away in the admin panel.

The same reference documents a narrow exception. Admins can still retrieve a chat marked internal (sub-agent, timer, or note-attached) by id, because those chats are omitted from lists, search, and exports. This contract does not claim those internal chats disappear.

This is distinct from:

- Stage 38 `openwebui-admin-export-contract.md` (bulk export button)
- Stage 36 `openwebui-admin-analytics-contract.md` (Analytics tab and router)
- Stage 33 `openwebui-community-sharing-contract.md` (links a user chooses to share)
- `BYPASS_ADMIN_ACCESS_CONTROL` (workspace list/selector visibility; a different official key)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official env reference | Default `true`; endpoints reject when `false`; internal-chat exception |
| Official hardening | Documents the flag next to export and role settings |
| `open-webui` environment | Flag unset (product default on) |
| Postgres on `DATABASE_URL` | Host-level read remains an operator action |
| GitHub Issues | Place to request temporary moderation access |

Out of scope:

- A moderation queue, audit product, or chat-redaction service
- Setting `BYPASS_ADMIN_ACCESS_CONTROL` in this change
- Rewriting the Analytics contract
- Claiming the flag is a cryptographic tenant boundary

## Proposal

Set the official flag on the `open-webui` service:

```text
ENABLE_ADMIN_CHAT_ACCESS: "false"
```

Do not invent `TU_VM_HIDE_CHATS`. Ship Stage 38 `ENABLE_ADMIN_EXPORT=false` in the same window so the export button cannot reopen the conversations this flag hides. Leave `BYPASS_ADMIN_ACCESS_CONTROL` at the product default until a separate Issue asks to change workspace selectors. The official text says that flag is a UI-clutter control, not a security boundary.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false |
| Env schema | `env.example` | Comment that admins do not browse other chats |
| Docs | Open WebUI playbook | Note the internal-chat-by-id exception |
| Code | Recreate Open WebUI | Other-user chat endpoints reject |

### Rules

1. **Official key only.** Match the env reference spelling.
2. **Pair with export.** `ENABLE_ADMIN_EXPORT=false` is the companion contract.
3. **State the internal-chat exception.** Sub-agent, timer, and note chats remain retrievable by id.
4. **Do not sell this as tenant isolation.** Separate tenants need separate Open WebUI instances.
5. **GitHub remains intake.** Temporary moderation access is an Issue with an expiry.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_ADMIN_CHAT_ACCESS
2. Set the flag false on the open-webui service
3. Recreate Open WebUI
4. Confirm the admin panel cannot open another user's normal chat
5. Set ENABLE_ADMIN_EXPORT=false in the companion contract
6. Document the internal-chat-by-id exception in the playbook
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Hide other users' chats in the panel | Official `ENABLE_ADMIN_CHAT_ACCESS` | A custom moderation UI |
| Bulk download | Stage 38 admin-export contract | One boolean for both surfaces |
| Usage charts | Stage 36 admin Analytics contract | Hiding Analytics inside this flag |
| Real tenant split | A separate Open WebUI instance | Treating this flag as isolation |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, a recreate, and the companion export flag.
3. Admins keep user-management and their own chats.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_ADMIN_CHAT_ACCESS=false`.
- [ ] No moderation queue or redaction service is added.
- [ ] `BYPASS_ADMIN_ACCESS_CONTROL` and the Analytics flag are unchanged by this contract.

## Rollback

Set the flag `true` (official default) and recreate Open WebUI for a documented moderation window, then return it to `false`.

## Success metrics

- The admin panel does not open another user's normal chats.
- The playbook states the internal-chat-by-id exception so operators are not surprised.
