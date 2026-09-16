---
title: Open WebUI Signup First-User Contract
description: Constructional contract to use official ENABLE_SIGNUP and first-admin bootstrap so a LAN Open WebUI does not stay open for new accounts after the operator exists—distinct from the Tika init patch.
last_updated: 2026-09-16
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Signup First-User Contract

## Problem

Compose sets `WEBUI_AUTH: "true"` but does **not** set official Open WebUI `ENABLE_SIGNUP` (or a documented first-user path). Upstream defaults typically allow the first visitor to become admin and may leave signup enabled afterward.

On a LAN-first private AI stack that is reachable from any device that can resolve `oweb.tu.lan` (or the Stage 31 `WEBUI_URL`), that means a second household laptop or a guest on the same SSID can create another account unless the operator finds the Admin toggle.

`scripts/init-openwebui.sh` only patches PDF/Tika loader code. Stage 15 `open-webui-init-firstboot-contract.md` (expected sibling) is that patch lane. This page is **account-bootstrap honesty**, not loader repair.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Open WebUI Compose `WEBUI_AUTH` | Auth required; does not define signup |
| Official Open WebUI env | `ENABLE_SIGNUP`, `DEFAULT_USER_ROLE`, `WEBUI_SECRET_KEY` |
| `scripts/init-openwebui.sh` | TikaLoader patch only |
| Stage 10 Open WebUI contribution (expected sibling) | Broader config lane |
| Stage 15 init/first-boot (expected sibling) | Idempotent loader patch |
| Stage 31 `WEBUI_URL` (expected sibling) | Public origin; not signup |
| Stage 8 secret-rotation (expected sibling) | Rotating `WEBUI_SECRET_KEY` |

Out of scope:

- Baking a first user into a forked Open WebUI image
- OAuth/OIDC/SSO as a prerequisite (LAN operators use local accounts)
- Rewriting the Tika init script to create users
- Disabling `WEBUI_AUTH` “to make demos easier”

## Proposal

1. **Document the first visitor.** The first created account is the admin. Playbooks should say: create it from a trusted device immediately after first `up`.
2. **Set official env after bootstrap.** Default recommendation for this project: `ENABLE_SIGNUP=false` once the admin exists. Fresh clones may leave signup on **only** for the first boot, then flip it.
3. **Do not invent a user-provisioner.** Official Open WebUI has no TU-VM-specific REST user factory. If a future official bootstrap env appears, use that—do not write `helper/uploader.py` user CRUD.
4. **Optional `DEFAULT_USER_ROLE`.** If signup stays on for a household, set a pending/user role rather than implicit admin. Cite upstream names only.

Illustrative Compose (after first admin, or from day one on a shared LAN):

```text
WEBUI_AUTH: "true"
ENABLE_SIGNUP: ${ENABLE_SIGNUP:-false}
```

Fresh install note: set `ENABLE_SIGNUP=true` for the first account, then `false`. Prefer documenting that flip over a custom helper.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official `ENABLE_SIGNUP` with a LAN-safe default |
| Env schema | `env.example` | Comment: first user is admin; then disable signup |
| Docs | playbook / README | First-login checklist |
| Init | `init-openwebui.sh` | **Do not** add user creation here |

### Rules

1. **Official keys only.** `ENABLE_SIGNUP` / `DEFAULT_USER_ROLE` — not a home-grown `TU_VM_CREATE_ADMIN`.
2. **Auth stays on.** Do not set `WEBUI_AUTH=false` to skip this work.
3. **Init stays Tika.** Stage 15 remains the patch contract.
4. **No SSO product.** GitHub Issues remain intake for OIDC requests.
5. **LAN honesty.** Signup-off is the private-AI default after the operator exists.

### Suggested contributor checklist

```text
1. Confirm ENABLE_SIGNUP is an official Open WebUI env key for the pinned image
2. Add Compose interpolation with a documented default
3. Add env.example comment for first-admin then disable
4. Do not patch users in init-openwebui.sh
5. Playbook: create admin from a trusted device, then set ENABLE_SIGNUP=false
6. Recreate open-webui; existing users in the Postgres volume remain
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Account switch | Official Open WebUI env + Admin UI | Forked image with baked users |
| First-boot files | Existing `init-openwebui.sh` for Tika only | Mixing identity into the PDF patch |
| Public URL | Stage 31 `WEBUI_URL` | localhost cookie workarounds |
| Identity provider | Local accounts | Mandatory Authentik/Keycloak |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Compose + `env.example` + one playbook paragraph.
3. Call out in release notes: existing installs that already have users should set `ENABLE_SIGNUP=false` to match the new default.

## Acceptance criteria

- [ ] Compose sets official `ENABLE_SIGNUP` (documented default).
- [ ] Docs state first visitor becomes admin and how to lock signup.
- [ ] `init-openwebui.sh` is not used as a user-provisioner.
- [ ] No SSO or forked Open WebUI image is introduced.
- [ ] Stage 31 `WEBUI_URL` is not rewritten.

## Rollback

Remove the env keys. Open WebUI returns to upstream signup defaults. Existing users in Postgres remain.

## Success metrics

- Fewer “someone on my LAN created a second admin” issues.
- Contributors stop proposing custom first-user APIs on the helper.
- Playbooks mention signup in the same breath as `generate-secrets`.
