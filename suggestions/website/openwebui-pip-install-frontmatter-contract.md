---
title: Open WebUI Pip Frontmatter Requirements Contract
description: Constructional contract to set official ENABLE_PIP_INSTALL_FRONTMATTER_REQUIREMENTS=false so Tools and Functions cannot auto-pip install declared packages at runtime.
last_updated: 2026-09-21
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Pip Frontmatter Requirements Contract

## Problem

Official Open WebUI hardening documents that Tools and Functions may declare Python dependencies in frontmatter and, by default, those packages are installed automatically via pip. Compose already sets conservative `PIP_OPTIONS` / `PIP_DISABLE_PIP_VERSION_CHECK` because Open WebUI can hang on boot while installing tool deps. It does **not** set `ENABLE_PIP_INSTALL_FRONTMATTER_REQUIREMENTS`.

On a community VM, any user who can create or import a Tool can pull arbitrary packages at runtime. That bypasses digest-pinned images, Dependabot/Trivy review, and the “reuse official frameworks, do not add sidecars” rule.

`SAFE_MODE` only deactivates Functions at startup; `ENABLE_PLUGINS=false` is a stronger product-off switch. This contract keeps the Tools surface available for reviewed community plugins while stopping automatic pip.

This is distinct from:

- Stage 37 code-execution / code-interpreter pages (chat/model code, not Tool frontmatter)
- Stage 34 n8n community packages (n8n npm, not Open WebUI pip)
- Stage 32 unofficial `WEBUI_*` honesty (wrong names, not pip)
- Existing `PIP_OPTIONS` timeouts (hang protection, not an allow/deny)
- Stage 36 PersistentConfig (store precedence for this flag)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Open WebUI hardening | `ENABLE_PIP_INSTALL_FRONTMATTER_REQUIREMENTS=false` |
| `open-webui` environment | `PIP_OPTIONS` hang guards; frontmatter pip unset |
| Digest-pinned Compose images | Supply-chain baseline |
| GitHub Issues + PR templates | How a new Tool dependency should land |
| Stage 36 PersistentConfig (expected sibling) | Makes this env value stick |

Out of scope:

- A pip-cache container or vendored wheelhouse
- Setting `ENABLE_PLUGINS=false` (hides Tools entirely)
- Using `SAFE_MODE=true` as the standing default (recovery lever, not policy)
- Rewriting Stage 34 n8n community-package pages

## Proposal

Set the official flag on the `open-webui` service:

```text
ENABLE_PIP_INSTALL_FRONTMATTER_REQUIREMENTS: "false"
```

Keep existing `PIP_OPTIONS` timeouts. Reviewed Tool dependencies belong in a Dockerfile/image bump or an accepted Issue—not a live pip from chat.

Do not invent `TU_VM_WEBUI_NO_PIP`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false |
| Env schema | `env.example` | Comment that Tool frontmatter pip is off |
| Docs | Open WebUI playbook | How to request a Tool dependency via PR |
| Code (related) | Stage 36 store honesty | So Admin UI cannot re-enable pip |

### Rules

1. **Official key only.** Match Open WebUI hardening spelling.
2. **Keep PIP_OPTIONS.** Timeouts stay; they are not this contract.
3. **Do not confuse with n8n community packages.** Stage 34 owns npm.
4. **Do not hide Tools** unless a later Issue chooses `ENABLE_PLUGINS`.
5. **GitHub remains intake.** New Python deps stay PRs / image pins.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_PIP_INSTALL_FRONTMATTER_REQUIREMENTS
2. Set the flag false on the open-webui service
3. Recreate Open WebUI and confirm a Tool with requirements: does not pip install
4. Implement Stage 36 ENABLE_PERSISTENT_CONFIG=false so the value sticks
5. Do not add a pip-cache service or rewrite Stage 34 n8n package pages
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Block live pip | Official `ENABLE_PIP_INSTALL_FRONTMATTER_REQUIREMENTS` | A wheelhouse sidecar |
| Reviewed deps | Image pin + PR | Teaching users to “just add requirements:” |
| Hang protection | Existing `PIP_OPTIONS` | Removing timeouts because pip is off |
| Chat/model code | Stage 37 execution / interpreter flags | One “no code” mega-flag |
| n8n npm | Stage 34 official flags | Mixing pip with community nodes |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line plus Stage 36 store honesty.
3. Note in the playbook that Tool authors must PR image/deps changes.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_PIP_INSTALL_FRONTMATTER_REQUIREMENTS=false`.
- [ ] Existing `PIP_OPTIONS` hang guards remain.
- [ ] No pip-cache sidecar is added.
- [ ] Stage 34 n8n community-package page is not rewritten.

## Rollback

Set the flag `true` (official default) and recreate. Follow Stage 36 if Admin UI stored a value.

## Success metrics

- Recreating Open WebUI does not pip-install Tool frontmatter on boot or import.
- “How do I add a Python package for a Tool?” questions cite a PR / image pin.
