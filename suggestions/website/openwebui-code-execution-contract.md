---
title: Open WebUI Code Execution Contract
description: Constructional contract to set official ENABLE_CODE_EXECUTION=false so chat code-block run buttons stay off, pairing with Stage 36 PersistentConfig honesty and remaining distinct from the code-interpreter flag.
last_updated: 2026-09-21
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Code Execution Contract

## Problem

Official Open WebUI hardening documents `ENABLE_CODE_EXECUTION` as default `true`. That flag turns on **in-chat code-block run buttons**. The default engine is legacy `pyodide` (browser/WebAssembly). A `jupyter` engine is also documented and has direct server-side access if enabled.

TU-VM is a shared LAN community stack. Unreviewed run buttons invite “just execute this snippet” workflows that bypass playbooks, MCP Gateway, and LangGraph write guards. Compose does not set the flag today.

This is a PersistentConfig key. Without Stage 36 `ENABLE_PERSISTENT_CONFIG=false` **code**, an Admin UI click can silently re-enable execution after a Git-reviewed disable.

This is distinct from:

- Stage 37 `openwebui-code-interpreter-contract.md` (`ENABLE_CODE_INTERPRETER` / model `execute_code`)
- Stage 37 `openwebui-pip-install-frontmatter-contract.md` (Tools frontmatter pip)
- Stage 36 `openwebui-persistent-config-honesty-contract.md` (which store wins)
- Stage 33 `n8n-block-env-access-in-node-contract.md` (n8n Code node)
- MCP Playwright / Browserless (browser automation, not chat run buttons)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Open WebUI hardening | `ENABLE_CODE_EXECUTION` default true; disable if unused |
| `open-webui` environment | Flag unset (product default on) |
| MCP Gateway + playbooks | Existing execution frameworks |
| Stage 36 PersistentConfig (expected sibling) | Makes this env value stick |
| GitHub Issues | Place to request Open Terminal later |

Out of scope:

- Shipping a Jupyter service or Open Terminal stack in this contract
- CSS hides of the run button
- Rewriting the interpreter or pip-frontmatter pages
- Treating `SAFE_MODE` as a substitute (Safe Mode is Functions, not this flag)

## Proposal

Set the official run-button flag on the `open-webui` service:

```text
ENABLE_CODE_EXECUTION: "false"
```

Do not invent `TU_VM_WEBUI_NO_RUN`. Do not add Jupyter “for completeness.”

If a later Issue needs isolated execution, official hardening prefers **Open Terminal** (container-isolated) over `pyodide` or `jupyter`—that is a new proposal, not this page.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false |
| Env schema | `env.example` | Comment that chat run buttons are off |
| Docs | Open WebUI playbook | Pair with PersistentConfig warning |
| Code (related) | Stage 36 store honesty | So Admin UI cannot override |

### Rules

1. **Official key only.** Match Open WebUI hardening spelling.
2. **Do not fold interpreter into this page.** That is a separate official flag.
3. **Do not add Jupyter.** Server-side Jupyter is out of default scope.
4. **Pair with Stage 36.** PersistentConfig must be implemented in **code** or Admin UI wins.
5. **GitHub remains intake.** Open Terminal requests stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_CODE_EXECUTION
2. Set the flag false on the open-webui service
3. Recreate Open WebUI and confirm code-block run buttons are absent
4. Implement Stage 36 ENABLE_PERSISTENT_CONFIG=false so the value sticks
5. Do not add Jupyter or rewrite the interpreter page
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Disable run buttons | Official `ENABLE_CODE_EXECUTION` | CSS hide or a custom jail |
| Isolated execution later | Official Open Terminal via Issue | Default Jupyter sidecar |
| Env vs Admin UI | Stage 36 PersistentConfig **code** | A settings-sync sidecar |
| Model-driven code | Stage 37 interpreter contract | Mixing the two flags |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line plus Stage 36 store honesty.
3. Missing run buttons are expected on a LAN community VM.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_CODE_EXECUTION=false`.
- [ ] No Jupyter or Open Terminal service is added by this contract.
- [ ] Interpreter and pip-frontmatter pages are not rewritten.

## Rollback

Set the flag `true` (official default) and recreate. If PersistentConfig is still true, Admin UI may already have a stored value—follow Stage 36 rollback notes.

## Success metrics

- Recreating Open WebUI does not show code-block run buttons.
- Execution requests cite MCP playbooks or a new Open Terminal Issue, not a Jupyter compose service.
