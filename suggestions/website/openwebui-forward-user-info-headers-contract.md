---
title: Open WebUI Forward User Info Headers Contract
description: Constructional contract to pin official ENABLE_FORWARD_USER_INFO_HEADERS=false so Open WebUI does not attach user identity to outbound model and tool calls.
last_updated: 2026-09-23
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Forward User Info Headers Contract

## Problem

The pinned Open WebUI image sets `ENABLE_FORWARD_USER_INFO_HEADERS` from the environment in `backend/open_webui/env.py`, default `False`. It is not a `ConfigVar`. When the flag is true, Open WebUI attaches the signed-in user's name, id, email, and role to outbound calls, and attaches chat or message ids on a narrower set of backends.

Current Open WebUI env reference lists those backends as OpenAI, Ollama, and Anthropic connections, tool servers, and external embedding, reranking, web-search, audio, image, and document-loader services. TU-VM already runs Ollama, the MCP gateway, and Tika on the Compose network. Compose does not pin the flag, so a later edit can start sending account emails to every tool without a review.

Custom headers configured on an individual connection are a separate feature. The same env reference says they are sent even when this flag is false. This page does not build a header filter.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `env.py` | Default `False`; startup read |
| Open WebUI env reference | Which headers go to which backends |
| Ollama, MCP gateway, Tika | In-network callers that would receive identity if the flag flips |
| GitHub Issues | Place to enable forwarding for a named backend |

Out of scope:

- A header-stripping proxy or identity broker
- Setting `FORWARD_USER_INFO_HEADER_JWT_SECRET` (only meaningful when forwarding is on)
- Renaming `X-OpenWebUI-User-*` headers
- Stage 37 direct-connection or code-execution keys

## Proposal

Pin the official default on the `open-webui` service:

```text
ENABLE_FORWARD_USER_INFO_HEADERS: "false"
```

Do not invent `TU_VM_STRIP_USER_HEADERS`. Turning the flag on needs an Issue that names the backend and why it must see email or role. Per-connection custom headers stay available for that case and do not require this global flag.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official `false` |
| Env schema | `env.example` | Comment: global identity headers stay off |
| Docs | Open WebUI playbook | Point per-tool identity at connection headers, not this flag |
| Tools | MCP gateway | No new auth protocol |

### Rules

1. **Official flag.** The default in this image is already false. The pin makes a later `true` visible in review.
2. **Startup-only.** Recreate the container after a change. There is no Admin toggle for this key in `env.py`.
3. **Do not set the JWT secret "just in case".** That secret is for the enabled path.
4. **Per-connection headers remain the narrow tool.** Use them when one backend needs a value.
5. **GitHub remains intake.** Enabling the global flag names the consumer.

### Suggested contributor checklist

```text
1. Confirm the pinned image still defaults ENABLE_FORWARD_USER_INFO_HEADERS to False
2. Set ENABLE_FORWARD_USER_INFO_HEADERS=false on the open-webui service
3. Recreate Open WebUI
4. Confirm outbound Ollama and tool calls do not grow X-OpenWebUI-User-* headers
5. Do not add a header-stripping proxy
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Global identity headers | Official flag left `false` | A filtering sidecar |
| One backend needs a header | Per-connection custom headers | Flipping the global flag |
| Tool auth | Existing MCP gateway | A new identity broker |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line and an Open WebUI recreate.
3. Enabling forwarding is an Issue, not a drive-by env edit.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_FORWARD_USER_INFO_HEADERS=false`.
- [ ] `FORWARD_USER_INFO_HEADER_JWT_SECRET` is not introduced by this change.
- [ ] No header-filter proxy is added.

## Rollback

Remove the pin to restore the same official default of false. Setting `true` is a reviewed Issue.

## Success metrics

- Model and tool calls from Open WebUI do not carry user email or role headers.
- Contributors can still add a header on one connection when an Issue asks for it.
