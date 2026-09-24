---
title: Open WebUI Active User Count Contract
description: Constructional contract to pin official ENABLE_PUBLIC_ACTIVE_USERS_COUNT=false so the user menu and /api/usage stay admin-only.
last_updated: 2026-09-24
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Open WebUI Active User Count Contract

## Problem

The pinned Open WebUI image reads `ENABLE_PUBLIC_ACTIVE_USERS_COUNT` in `backend/open_webui/env.py`. The default is `True`. It is a startup environment read, not a `ConfigVar`.

`GET /api/usage` returns `user_count` and `model_ids` (models currently in use). When the flag is true, any verified user can call it. When the flag is false, the handler returns 403 unless `user.role == 'admin'`.

The sidebar user menu in that revision (`src/lib/components/layout/Sidebar/UserMenu.svelte`) shows **Active Users** and a tooltip of running model ids when the flag is on, or when the signed-in role is admin.

Compose does not set the flag. On a shared LAN install, every account can see how many people are active and which model ids are loaded. TU-VM's community model is GitHub for proposals, not a presence directory inside the chat UI.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `env.py` | Default `True`; startup read |
| Pinned `main.py` `/api/usage` | Non-admins are rejected only when the flag is false |
| Pinned user menu | Renders the count and model-id tooltip |
| `WEBUI_AUTH: "true"` | Accounts already exist; this is not anonymous mode |
| Stage 38 `DEFAULT_USER_ROLE` (expected sibling) | Pending role; a different privacy surface |
| GitHub Issues | Place to show the count to every member |

Out of scope:

- A presence service, websocket roster, or analytics warehouse
- Stage 35 Scarf / version-check telemetry
- Stage 36 admin analytics
- Hiding the count from admins (the image still shows it to `role=admin`)

## Proposal

Pin the official flag on the `open-webui` service:

```text
ENABLE_PUBLIC_ACTIVE_USERS_COUNT: "false"
```

Admins keep the menu entry and `/api/usage`. Other roles get 403 and do not see the count. Because the read is in `env.py`, a container recreate picks up the Compose value without a database migration. Stage 36 PersistentConfig does not store this flag.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | The flag above |
| Env schema | `env.example` | Comment that admins still see usage |
| Docs | Open WebUI playbook | Community coordination stays on GitHub Issues, not the user menu |

### Rules

1. **Official flag only.** Do not filter `/api/usage` in Nginx.
2. **Admins still see usage.** Do not patch the menu to hide it from `role=admin`.
3. **Not a ConfigVar.** Do not document an Admin toggle that this revision does not have.
4. **GitHub remains intake** if a household wants the count visible to every account.

### Suggested contributor checklist

```text
1. Confirm env.py still defaults ENABLE_PUBLIC_ACTIVE_USERS_COUNT to True
2. Set the flag false on the open-webui service
3. Recreate Open WebUI
4. As a non-admin, confirm /api/usage returns 403 and the menu omits Active Users
5. As an admin, confirm the count still loads
6. Do not add a presence service
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Who is active | Official flag, admin-only | A roster microservice |
| Community discussion | GitHub Issues | Chat-UI presence |
| Admin operations | Existing `/api/usage` for admins | A second metrics scraper for this count |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, an `env.example` comment, and an Open WebUI recreate.
3. Showing the count to every member needs an Issue.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_PUBLIC_ACTIVE_USERS_COUNT=false`.
- [ ] Non-admin `/api/usage` is 403.
- [ ] Admin usage remains available.
- [ ] No presence service is added.

## Rollback

Remove the key to restore the image default (`true`), which shows the count and model ids to every verified user. That rollback is a reviewed Issue.

## Success metrics

- Shared accounts no longer see other members' activity or loaded model ids in the user menu.
- Admins can still read `/api/usage` when they are debugging a loaded model.
