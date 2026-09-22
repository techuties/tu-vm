---
title: Open WebUI Admin Export Contract
description: Constructional contract to set official ENABLE_ADMIN_EXPORT=false so the admin panel cannot bulk-export community chats.
last_updated: 2026-09-22
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Admin Export Contract

## Problem

Official Open WebUI `ENABLE_ADMIN_EXPORT` defaults to `true`. The admin-panel export action can download data and chats. The env reference says database dumps on that action work for SQLite only, and that disabling the flag makes the export endpoints reject requests. A restart is required.

TU-VM stores Open WebUI in Postgres (`DATABASE_URL` on the `open-webui` service), so the SQLite database-dump path is already idle. Chat and data export endpoints are still on while the flag is unset. On a community VM, one admin click can download other people's conversations through the product UI.

Compose does not set the flag. Host and database access remain a separate operator path; this contract closes the in-product export surface the official docs describe.

This is distinct from:

- Stage 38 `openwebui-admin-chat-access-contract.md` (opening another user's chat in the panel)
- Stage 36 `openwebui-admin-analytics-contract.md` (Analytics tab)
- Stage 33 `openwebui-community-sharing-contract.md` (user share links)
- Stage 18 backup and Stage 22 Postgres WAL pages (operator backups, not the admin export button)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official env reference | Default `true`; export endpoints reject when `false`; restart required |
| Official hardening | Disable admin bulk export when it is not needed |
| `open-webui` `DATABASE_URL` | Postgres; SQLite database export does not apply |
| `tu-vm.sh` backup path | Operator backup framework already exists |
| GitHub Issues | Place to request a time-boxed export |

Out of scope:

- A custom export API or download portal
- Changing Postgres backup, WAL, or volume procedures
- Hiding chats inside the admin panel (companion Stage 38 chat-access contract)
- Claiming the flag removes raw database access from the host

## Proposal

Set the official flag on the `open-webui` service:

```text
ENABLE_ADMIN_EXPORT: "false"
```

Do not invent `TU_VM_NO_EXPORT`. Ship the companion chat-access flag in the same maintenance window so export and in-panel chat viewing do not reopen the same conversations on two buttons. Keep operator backups on the existing `tu-vm.sh` backup path.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false |
| Env schema | `env.example` | Comment that admin-panel export is off |
| Docs | Open WebUI playbook | Point bulk copy needs at `tu-vm.sh` backup |
| Code | Recreate Open WebUI | Export endpoints reject |

### Rules

1. **Official key only.** Match the env reference spelling.
2. **Pair with chat access.** Disable `ENABLE_ADMIN_CHAT_ACCESS` in its own contract, same window.
3. **Backups stay on tu-vm.sh.** Do not route community exports through the helper API.
4. **Postgres honesty.** Do not document a SQLite dump workaround.
5. **GitHub remains intake.** A support export is a time-boxed Issue, not a standing default.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_ADMIN_EXPORT
2. Set the flag false on the open-webui service
3. Recreate Open WebUI
4. Confirm the admin export action fails closed
5. Set ENABLE_ADMIN_CHAT_ACCESS=false in the companion contract
6. Do not add an export route to helper/uploader.py
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Close admin export | Official `ENABLE_ADMIN_EXPORT` | A custom download portal |
| Operator copies | Existing `tu-vm.sh` backup | Admin-panel export as the backup tool |
| In-panel chat viewing | Stage 38 admin chat-access contract | Treating export and chat view as one flag |
| User share links | Stage 33 community-sharing contract | Folding share links into this page |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, a recreate, and the companion chat-access flag.
3. Missing admin export buttons are expected on a community VM.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_ADMIN_EXPORT=false`.
- [ ] No helper export route or download portal is added.
- [ ] Backup scripts and Postgres WAL settings are unchanged by this contract.

## Rollback

Set the flag `true` (official default) and recreate Open WebUI. Treat that as a temporary support action and return the flag to `false` afterward.

## Success metrics

- Admin export endpoints reject requests after recreate.
- Operators still have the existing backup command for disaster recovery.
