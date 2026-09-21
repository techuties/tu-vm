---
title: Open WebUI Code Interpreter Contract
description: Constructional contract to set official ENABLE_CODE_INTERPRETER=false so models cannot call execute_code, distinct from the chat run-button flag and pairing with Stage 36 PersistentConfig honesty.
last_updated: 2026-09-21
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Code Interpreter Contract

## Problem

Official Open WebUI tools and hardening docs document `ENABLE_CODE_INTERPRETER` as default `true`. That flag lets **models** run code as part of reasoning via the built-in `execute_code` tool (Native/agentic mode). The default engine is again legacy `pyodide`; `jupyter` remains a documented server-side option.

This is not the same switch as `ENABLE_CODE_EXECUTION`. Operators can disable the visible run button and still leave the model able to execute code in the background. Compose sets neither flag today.

This is a PersistentConfig key. Stage 36 store honesty must be implemented in **code** or an Admin UI “Code Interpreter” toggle will override Compose after restart.

This is distinct from:

- Stage 37 `openwebui-code-execution-contract.md` (human run button on code blocks)
- Stage 37 `openwebui-pip-install-frontmatter-contract.md` (frontmatter pip)
- Stage 36 PersistentConfig (store precedence)
- Stage 33 community-sharing / offline embeddings
- n8n Code node / task runners (different product)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Open WebUI tools docs | Interpreter requires `ENABLE_CODE_INTERPRETER` plus per-chat toggle |
| Official hardening | Default true; disable both execution flags if unused |
| `open-webui` environment | Flag unset (product default on) |
| MCP Gateway | Existing community tool-calling framework |
| Stage 36 PersistentConfig (expected sibling) | Makes this env value stick |

Out of scope:

- Shipping Jupyter or Open Terminal in this contract
- Hiding the chat toggle in nginx HTML
- Rewriting the run-button or pip-frontmatter pages
- Using `SAFE_MODE` as a substitute (Functions, not interpreter)

## Proposal

Set the official interpreter flag on the `open-webui` service:

```text
ENABLE_CODE_INTERPRETER: "false"
```

Do not invent `TU_VM_WEBUI_NO_EXECUTE_CODE`.

If a later Issue needs model-driven code, official hardening prefers container-isolated Open Terminal over `pyodide`/`jupyter`, and Stage 36 must remain in force so the enablement is Git-reviewed.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false |
| Env schema | `env.example` | Comment that model `execute_code` is off |
| Docs | Open WebUI playbook | Distinguish run button vs interpreter |
| Code (related) | Stage 36 store honesty | So Admin UI cannot override |

### Rules

1. **Official key only.** Match Open WebUI env / hardening spelling.
2. **Keep the run-button page separate.** Different official flag.
3. **Do not add Jupyter.**
4. **Pair with Stage 36 PersistentConfig code.**
5. **GitHub remains intake.** Interpreter-on-with-Open-Terminal stays an Issue.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_CODE_INTERPRETER
2. Set the flag false on the open-webui service
3. Recreate Open WebUI and confirm execute_code is not offered
4. Implement Stage 36 ENABLE_PERSISTENT_CONFIG=false so the value sticks
5. Do not treat this as ENABLE_CODE_EXECUTION or add Jupyter
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Disable model code | Official `ENABLE_CODE_INTERPRETER` | CSS hide of the chat toggle |
| Human run button | Stage 37 execution contract | One flag for both behaviors |
| Tool calling | Existing MCP Gateway | A second interpreter product |
| Isolated backends later | Official Open Terminal via Issue | Default Jupyter |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line plus Stage 36 store honesty.
3. Missing interpreter toggle is expected.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_CODE_INTERPRETER=false`.
- [ ] No Jupyter or Open Terminal service is added by this contract.
- [ ] The run-button page is not rewritten or merged into this file.

## Rollback

Set the flag `true` (official default) and recreate. Follow Stage 36 if a stored Admin value exists.

## Success metrics

- Recreating Open WebUI does not inject `execute_code` into new chats.
- Community “why can’t the model run Python?” answers cite this flag and MCP playbooks.
