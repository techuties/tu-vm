---
title: Open WebUI Default User Role Contract
description: Constructional contract to pin official DEFAULT_USER_ROLE=pending so new Open WebUI accounts wait for admin approval.
last_updated: 2026-09-22
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Default User Role Contract

## Problem

Official Open WebUI `DEFAULT_USER_ROLE` defaults to `pending`: new accounts have no product access until an admin activates them. The other documented options are `user` (immediate regular access) and `admin` (immediate administrator). The env reference marks this key as a `ConfigVar`.

Compose does not pin the value. On a shared LAN, an Admin UI save or a later image default can move new accounts to `user` or `admin` without a Git review. Stage 32 `openwebui-signup-first-user-contract.md` owns whether `ENABLE_SIGNUP` is on. It mentions `DEFAULT_USER_ROLE` only as an optional follow-up. This page is that follow-up.

Pending is the community gate: a guest on the same SSID can still create an account when signup is open, and an admin still has to approve it.

This is distinct from:

- Stage 32 `openwebui-signup-first-user-contract.md` (signup on/off and first admin)
- Stage 37 `openwebui-password-validation-contract.md` (password shape)
- Stage 36 `openwebui-persistent-config-honesty-contract.md` (which store wins for ConfigVar keys)
- `WEBUI_AUTH` already set `true` in Compose (authentication required; role still unset)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official env reference | `pending` / `user` / `admin`; default `pending`; ConfigVar |
| Official hardening | Pin `DEFAULT_USER_ROLE=pending` |
| `open-webui` environment | Key unset |
| Stage 32 signup contract (expected sibling) | First admin, then `ENABLE_SIGNUP` |
| Stage 36 PersistentConfig (expected sibling) | Keeps ConfigVar env values from Admin UI drift |

Out of scope:

- An invitation service, approval mailbox, or local user database
- OAuth, SCIM, or group sync (`DEFAULT_GROUP_ID` stays untouched)
- Rewriting the signup or password-validation pages
- Setting the role to `admin` for convenience

## Proposal

Pin the official default on the `open-webui` service:

```text
DEFAULT_USER_ROLE: "pending"
```

Do not invent `TU_VM_APPROVAL_ROLE`. The first account created on an empty database remains the operator admin, as Stage 32 describes. Later accounts stay `pending` until that admin approves them in the existing Open WebUI users panel.

Because the key is a `ConfigVar`, implement Stage 36 `ENABLE_PERSISTENT_CONFIG=false` in **code** or an Admin UI save can replace the Compose pin.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official role `pending` |
| Env schema | `env.example` | Comment that new accounts wait for approval |
| Docs | Open WebUI playbook | Point admins at the existing users panel |
| Code (related) | Stage 36 store honesty | So Admin UI cannot silently switch the role |

### Rules

1. **Official values only.** `pending`, `user`, or `admin`. This contract pins `pending`.
2. **Signup stays on Stage 32.** Do not flip `ENABLE_SIGNUP` in this change.
3. **Do not build an approval app.** Open WebUI already has the pending overlay and users panel.
4. **Pair with Stage 36.** ConfigVar values stick only when the persistent store does not override env.
5. **GitHub remains intake.** A household that wants `user` by default files an Issue.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents DEFAULT_USER_ROLE=pending
2. Set the key on the open-webui service
3. Implement Stage 36 ENABLE_PERSISTENT_CONFIG=false so the pin sticks
4. Create a second account and confirm the role is pending
5. Approve that account from the existing admin users panel
6. Do not add an invitation service
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| New-account gate | Official `DEFAULT_USER_ROLE=pending` | A custom approval service |
| Signup switch | Stage 32 `ENABLE_SIGNUP` | Folding signup policy into this page |
| Env vs Admin UI | Stage 36 PersistentConfig **code** | A settings-sync sidecar |
| Password floor | Stage 37 password-validation contract | Treating role and password as one flag |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line plus Stage 36 store honesty.
3. Admins approve people from the Open WebUI users panel.

## Acceptance criteria

- [ ] `open-webui` sets `DEFAULT_USER_ROLE=pending`.
- [ ] `ENABLE_SIGNUP` is unchanged by this contract.
- [ ] No invitation or approval service is added.

## Rollback

Set `DEFAULT_USER_ROLE` to `user` only through a reviewed change, or remove the key to restore the image default. If PersistentConfig is still true, follow Stage 36 rollback notes so a stored Admin value does not linger.

## Success metrics

- A second self-signup account cannot chat until an admin approves it.
- The first operator account can still administer the instance.
