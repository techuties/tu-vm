---
title: Open WebUI Tool-Call Iteration Contract
description: Constructional contract to pin official CHAT_RESPONSE_MAX_TOOL_CALL_ITERATIONS=8 and to forbid -1, which removes the cap in the pinned Open WebUI image.
last_updated: 2026-09-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Tool-Call Iteration Contract

## Problem

The pinned Open WebUI revision reads `CHAT_RESPONSE_MAX_TOOL_CALL_ITERATIONS` in `backend/open_webui/env.py`. The fallback is `CHAT_RESPONSE_MAX_TOOL_CALL_RETRIES`, then the string `256`. An empty string also becomes `256`. The value `-1` is stored as `None`.

Chat middleware imports that constant. While it is `None`, or while the iteration counter is below it, the model may call tools again. When the counter reaches a finite cap, middleware logs `Tool-call iteration limit reached` and returns `Tool-call limit reached (N iterations).`

Compose does not set the key. A model wired to the MCP gateway can therefore run 256 tool rounds in one chat reply. That walks n8n, the knowledge base, and the gateway quotas (`TENANT_REQUESTS_PER_MINUTE`, `TENANT_DAILY_WRITES`) without a human stopping the turn.

This revision's `backend/open_webui/config.py` does not reference the key. The cap is the process environment, so a Compose pin applies at container start. Stage 36 PersistentConfig is a sibling for ConfigVars; it is not required for this key.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `env.py` | Default 256; `-1` means unlimited |
| Pinned chat middleware | Stops the loop and returns the limit error |
| MCP gateway quotas | Per-tenant rate and daily write caps already exist |
| Stage 37 code-execution contract (expected sibling) | Interpreter and code-exec toggles, not tool rounds |
| Stage 40 runner payload (expected sibling) | n8n runner body size, not chat tool rounds |
| GitHub Issues | Place to raise the cap for a specific workflow |

Out of scope:

- A custom tool-call watchdog, middleware fork, or second gateway
- Turning Tools off with `ENABLE_PLUGINS=false` (that hides the community tool catalog)
- Stage 37 code execution and code interpreter
- Changing tenant quotas in the same change

## Proposal

Pin a small official cap on the `open-webui` service:

```text
CHAT_RESPONSE_MAX_TOOL_CALL_ITERATIONS: "8"
```

Eight rounds covers a normal operator loop (list, inspect, draft, update, verify) and stops a stuck model before it spends the daily write budget. Raise the same key from an Issue when a named workflow needs more rounds. Do not set `-1`. Do not leave the key empty: empty keeps the image default of 256.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | `CHAT_RESPONSE_MAX_TOOL_CALL_ITERATIONS: "8"` |
| Env schema | `env.example` | Comment that `-1` disables the cap and empty means 256 |
| Docs | Open WebUI playbook | How to raise the cap for one workflow via an Issue |
| Gateway | existing quotas | Leave rate limits on their own page |

### Rules

1. **Official key only.** Middleware already enforces it.
2. **Never `-1`.** That value becomes `None` and the loop does not stop.
3. **Never an empty value.** Empty is parsed as 256.
4. **Keep 8 unless an Issue says otherwise.** A one-off workflow can ask for a higher positive integer.
5. **GitHub remains intake** for that higher integer.

### Suggested contributor checklist

```text
1. Confirm env.py still maps -1 to None and empty to 256
2. Set CHAT_RESPONSE_MAX_TOOL_CALL_ITERATIONS=8 on the open-webui service
3. Recreate Open WebUI
4. Run a tool-using chat and confirm a forced loop stops with the iteration error
5. Confirm -1 is absent from Compose and env.example
6. Leave ENABLE_PLUGINS, code execution, and gateway quotas unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Loop cap | Official iteration env | A sidecar that kills chats |
| More rounds | An Issue that changes this integer | `-1` |
| Abuse budget | Existing gateway quotas | A new rate-limit service |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, an `env.example` comment, and an Open WebUI recreate.
3. A higher cap needs an Issue.

## Acceptance criteria

- [ ] `open-webui` sets `CHAT_RESPONSE_MAX_TOOL_CALL_ITERATIONS=8`.
- [ ] Compose and `env.example` do not set `-1` or an empty string.
- [ ] A looping tool chat stops with the official limit error.
- [ ] No watchdog service is added.

## Rollback

Remove the key to restore the image default of 256. Do not roll back by setting `-1`.

## Success metrics

- A stuck tool loop ends within 8 rounds.
- A search of Compose finds no unlimited tool-call setting.
