---
title: Open WebUI HTTP Client Timeout Contract
description: Constructional contract to pin official AIOHTTP_CLIENT_TIMEOUT=600 so unset does not mean an unlimited total timeout on Ollama and OpenAI calls.
last_updated: 2026-09-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI HTTP Client Timeout Contract

## Problem

The pinned Open WebUI revision reads `AIOHTTP_CLIENT_TIMEOUT` in `backend/open_webui/env.py`. The default string is empty. An empty string becomes `None`. A value that fails `int()` becomes `300`. The string `0` is truthy, so it becomes a zero-second timeout.

`backend/open_webui/routers/ollama.py` `send_request` passes `aiohttp.ClientTimeout(total=AIOHTTP_CLIENT_TIMEOUT)`. Chat completion uses that helper, including streamed replies. `backend/open_webui/routers/openai.py` uses the same total timeout on generation routes. In aiohttp 3.13.5 (pinned in this image's `requirements.txt`), `total=None` means no total timeout.

`AIOHTTP_CLIENT_TIMEOUT_MODEL_LIST` is a different key and already defaults to 10 seconds. `AIOHTTP_CLIENT_TIMEOUT_TOOL_SERVER`, when empty, inherits `AIOHTTP_CLIENT_TIMEOUT`, so an unset client timeout also leaves tool-server calls without a total timeout.

Compose does not set the key. A hung Ollama or tool-server socket can hold the Open WebUI worker until the container is restarted.

Stage 39 owns `AIOHTTP_CLIENT_ALLOW_REDIRECTS`. This page owns the total timeout only.

The chat route comment in this revision says a local generation is often 30–60 seconds and longer. The parse-error fallback of 300 seconds will cut a slow local model. Six hundred seconds is a finite cap with room above that comment, and operators raise the same official key when a model needs longer.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `env.py` | Empty → `None`; invalid → 300; `0` → 0 |
| Ollama `send_request` | `ClientTimeout(total=AIOHTTP_CLIENT_TIMEOUT)` for chat |
| OpenAI router | Same total timeout on generation routes |
| Model-list timeout | Separate key, default 10 seconds |
| Tool-server timeout | Inherits the client timeout when its own key is empty |
| Nginx `location /api/mcp/` | `proxy_read_timeout 120s` for browser calls through `oweb.tu.lan` |
| Stage 39 redirects contract (expected sibling) | Redirect following, not duration |
| Stage 33 keep-alive contract (expected sibling) | Ollama unload, not the HTTP client |

Out of scope:

- A proxy that times out Ollama on TU-VM's behalf
- Changing `AIOHTTP_CLIENT_ALLOW_REDIRECTS`
- Changing the model-list 10 second key
- Changing the Nginx 120 second MCP proxy timeout (edge routing stays on its own contract)
- `0` as a "disable" value (it is a zero timeout)

## Proposal

Pin a finite official timeout on the `open-webui` service:

```text
AIOHTTP_CLIENT_TIMEOUT: "600"
```

Leave `AIOHTTP_CLIENT_TIMEOUT_MODEL_LIST` unset so listing stays at 10 seconds. Leave `AIOHTTP_CLIENT_TIMEOUT_TOOL_SERVER` unset so tool calls inherit 600 seconds. Do not set `0`. Do not leave the client timeout empty.

Browser calls that enter through `https://oweb.tu.lan/api/mcp/` still follow Nginx `proxy_read_timeout 120s`. That path is separate from Open WebUI's own client.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | `AIOHTTP_CLIENT_TIMEOUT: "600"` |
| Env schema | `env.example` | Comment that empty means no total timeout and `0` means zero seconds |
| Docs | Open WebUI playbook | Raise 600 on an Issue when a local model needs longer |
| Edge | Nginx MCP location | Leave the 120s proxy read timeout on the edge contract |

### Rules

1. **Official key only.** The routers already pass it to `ClientTimeout`.
2. **Empty stays forbidden.** Empty is `None`.
3. **`0` stays forbidden.** It is a zero-second timeout, not "disabled".
4. **Model listing stays on its own key.** Do not point `AIOHTTP_CLIENT_TIMEOUT_MODEL_LIST` at 600.
5. **Redirects stay on the Stage 39 page.**

### Suggested contributor checklist

```text
1. Confirm env.py still maps empty to None and invalid integers to 300
2. Set AIOHTTP_CLIENT_TIMEOUT=600 on the open-webui service
3. Recreate Open WebUI
4. Confirm a normal local chat still completes
5. Confirm model listing still uses the 10 second key
6. Leave AIOHTTP_CLIENT_ALLOW_REDIRECTS and the Nginx MCP timeout unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Upstream time limit | Official `AIOHTTP_CLIENT_TIMEOUT` | A timing proxy |
| Model listing | Existing 10 second key | Reusing the chat timeout |
| Longer generations | An Issue that raises 600 | Removing the key |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, an `env.example` comment, and an Open WebUI recreate.
3. A longer cap needs an Issue.

## Acceptance criteria

- [ ] `open-webui` sets `AIOHTTP_CLIENT_TIMEOUT=600`.
- [ ] Compose does not set the key to empty or `0`.
- [ ] Model-list timeout is still the separate 10 second default.
- [ ] No timeout proxy is added.

## Rollback

Remove the key to restore `None` (no total timeout). Prefer a higher positive integer over removal when a model is slow.

## Success metrics

- A stuck upstream call ends within 600 seconds.
- Model listing remains on the short key.
