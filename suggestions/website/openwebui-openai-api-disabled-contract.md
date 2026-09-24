---
title: Open WebUI OpenAI API Toggle Contract
description: Constructional contract to pin official ENABLE_OPENAI_API=false so an empty base URL does not call https://api.openai.com/v1. Distinct from Stage 39 passthrough.
last_updated: 2026-09-24
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI OpenAI API Toggle Contract

## Problem

The pinned Open WebUI image defaults `ENABLE_OPENAI_API` to `True`. It is a `ConfigVar` (`openai.enable`) in `backend/open_webui/config.py`.

In that same file, an empty `OPENAI_API_BASE_URL` is replaced with `https://api.openai.com/v1` before `OPENAI_API_BASE_URLS` is built. `backend/open_webui/routers/openai.py` `get_all_models_responses` returns immediately when the toggle is false. When the toggle is true, it requests each configured base URL, including that default.

TU-VM inference is Ollama (`OLLAMA_BASE_URL: http://ollama:11434`). Compose does not set `ENABLE_OPENAI_API` or an OpenAI base URL, so model refresh can still call `api.openai.com` with an empty key.

This is not Stage 39 `ENABLE_OPENAI_API_PASSTHROUGH`. That flag is the catch-all proxy (`/{path:path}`), default `False`, and it is not a `ConfigVar`. This page is the connections toggle that decides whether the OpenAI router runs at all.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pinned `config.py` | Empty base URL becomes `https://api.openai.com/v1`; toggle default `True` |
| Pinned `routers/openai.py` | Skips model listing when `ENABLE_OPENAI_API` is false |
| `OLLAMA_BASE_URL` | Existing local inference path |
| Stage 39 passthrough contract (expected sibling) | Catch-all proxy, already default false |
| Stage 37 direct connections (expected sibling) | A different surface |
| Stage 36 PersistentConfig (expected sibling) | Stored admin values override this ConfigVar |
| GitHub Issues | Place to add a named cloud provider |

Out of scope:

- A custom OpenAI gateway, key broker, or model catalog cache
- Changing `ENABLE_OPENAI_API_PASSTHROUGH` (Stage 39)
- Removing the Ollama router
- `BYPASS_MODEL_ACCESS_CONTROL` (default false; leave it)

## Proposal

Pin the official toggle on the `open-webui` service:

```text
ENABLE_OPENAI_API: "false"
```

Leave `OPENAI_API_BASE_URL` unset. Do not set it to an empty string and expect the default substitution to disappear; the image fills `https://api.openai.com/v1` when the string is empty. The toggle is what stops the request.

A later cloud provider is an Issue: set the official base URL and key, then turn `ENABLE_OPENAI_API` back on. Because this key is a `ConfigVar`, an Admin save wins over a later Compose edit unless Stage 36 PersistentConfig is implemented in **code**.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | `ENABLE_OPENAI_API: "false"` |
| Env schema | `env.example` | Comment that Ollama does not need this toggle |
| Docs | Open WebUI playbook | Cloud models are opt-in |
| Persistence | Stage 36 | Implement in code so the pin survives Admin saves |

### Rules

1. **Official toggle only.** Do not add a proxy that filters `api.openai.com`.
2. **Do not clear the URL and call the job done.** Empty still becomes the public default in this revision.
3. **Ollama stays.** `ENABLE_OLLAMA_API` remains at its default `true` with the existing `OLLAMA_BASE_URL`.
4. **Passthrough stays on the Stage 39 page.**
5. **GitHub remains intake** for a named upstream.

### Suggested contributor checklist

```text
1. Confirm the pinned config.py still substitutes https://api.openai.com/v1 when OPENAI_API_BASE_URL is empty
2. Set ENABLE_OPENAI_API=false on the open-webui service
3. Recreate Open WebUI
4. Confirm model refresh does not request api.openai.com
5. Confirm Ollama models still list
6. Leave ENABLE_OPENAI_API_PASSTHROUGH on the Stage 39 contract
7. If Admin → Connections already stored the toggle, apply Stage 36 in code or update the stored config on purpose
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local models | Existing Ollama URL | An OpenAI-compatible shim |
| Cloud opt-in | Official `ENABLE_OPENAI_API` | A domain blocklist sidecar |
| Catch-all proxy | Stage 39 passthrough pin | Folding passthrough into this page |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, an `env.example` comment, and an Open WebUI recreate.
3. Turning the toggle on needs an Issue that names the provider.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_OPENAI_API=false`.
- [ ] `OLLAMA_BASE_URL` is unchanged.
- [ ] `ENABLE_OPENAI_API_PASSTHROUGH` is not edited on this page.
- [ ] No OpenAI proxy or model-catalog service is added.

## Rollback

Remove the key to restore the image default (`true`), which calls `https://api.openai.com/v1` when no base URL is set. That rollback is a reviewed Issue, not a silent default.

## Success metrics

- Model refresh stays on the LAN Ollama URL.
- Operators who want a cloud model have one official switch to request.
