---
title: Open WebUI OpenAI API Passthrough Contract
description: Constructional contract to pin official ENABLE_OPENAI_API_PASSTHROUGH=false so the OpenAI catch-all proxy stays closed.
last_updated: 2026-09-23
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI OpenAI API Passthrough Contract

## Problem

The pinned Open WebUI image sets `ENABLE_OPENAI_API_PASSTHROUGH` from the environment in `backend/open_webui/env.py`, default `False`. The comment in that revision says the OpenAI catch-all proxy (`/{path:path}`) stays blocked unless the flag is enabled, and that the catch-all is for upstream endpoints Open WebUI does not handle itself.

Current Open WebUI env reference says the disabled catch-all returns `403 Forbidden`, and that enabling it forwards requests with the admin-configured API key and without model-level access control. Any authenticated user could then reach upstream endpoints using that key. Ollama and Responses routers do not grow a catch-all from this flag.

TU-VM's local inference path is Ollama. Compose does not pin the flag. A later `true` would publish the admin upstream key to every signed-in user without a new service.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `env.py` | Default `False`; startup read; not a `ConfigVar` |
| Open WebUI env reference | Catch-all uses the admin key and skips model access control |
| `OLLAMA_BASE_URL` | Existing local inference path |
| Stage 37 direct-connections contract (expected sibling) | A different Open WebUI surface |
| GitHub Issues | Place to enable passthrough for a named upstream |

Out of scope:

- A custom OpenAI gateway, key broker, or rate-limit proxy
- Stage 37 `ENABLE_DIRECT_CONNECTIONS` (do not rewrite that page)
- Changing `OPENAI_API_BASE_URLS` or provider keys
- Ollama routing

## Proposal

Pin the official default on the `open-webui` service:

```text
ENABLE_OPENAI_API_PASSTHROUGH: "false"
```

Do not invent `TU_VM_OPENAI_PROXY`. Enabling the catch-all needs an Issue that names the upstream path and accepts that the admin key is shared with authenticated users.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official `false` |
| Env schema | `env.example` | Comment: catch-all stays closed |
| Docs | Open WebUI playbook | Local models stay on Ollama |
| Upstream keys | Existing OpenAI connection settings | Least-privilege keys if a cloud model is added later |

### Rules

1. **Official flag.** The pinned image already defaults to false. The pin keeps a later `true` in review.
2. **Startup-only.** Recreate Open WebUI after a change.
3. **Admin key scope.** The danger is the catch-all, not the normal chat route.
4. **Ollama stays the local path.** Do not add a gateway to "make passthrough safe."
5. **GitHub remains intake.** A true value names the upstream and the key scope.

### Suggested contributor checklist

```text
1. Confirm the pinned image still defaults ENABLE_OPENAI_API_PASSTHROUGH to False
2. Set ENABLE_OPENAI_API_PASSTHROUGH=false on the open-webui service
3. Recreate Open WebUI
4. Confirm an unknown OpenAI proxy path returns 403
5. Leave direct-connection settings to Stage 37
6. Do not add an API gateway
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Catch-all proxy | Official flag left `false` | A custom OpenAI gateway |
| Local models | Existing Ollama URL | Routing chat through the catch-all |
| Cloud models | Normal Open WebUI connection entries | Sharing the admin key via `/{path:path}` |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line and an Open WebUI recreate.
3. Enabling passthrough is an Issue.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_OPENAI_API_PASSTHROUGH=false`.
- [ ] No OpenAI gateway container is added.
- [ ] Stage 37 direct-connection settings are not edited by this change.

## Rollback

Remove the pin to restore the same official default of false. Setting `true` is a reviewed Issue.

## Success metrics

- Unknown OpenAI proxy paths stay forbidden.
- Local chat continues to use Ollama.
