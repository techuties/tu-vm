---
title: Open WebUI Direct Connections Contract
description: Constructional contract to pin official ENABLE_DIRECT_CONNECTIONS=false so users cannot send personal provider API keys through the Open WebUI backend.
last_updated: 2026-09-21
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Direct Connections Contract

## Problem

Official Open WebUI hardening documents `ENABLE_DIRECT_CONNECTIONS` (default `false`). When enabled, users configure their own model-provider API keys and endpoints in the browser. Those connections are made **from the Open WebUI backend**, so the user’s key is sent to the TU-VM server.

The product default is already false, but Compose does not pin it. A single Admin UI change (and PersistentConfig default true) would let community users drop personal OpenAI/Anthropic keys onto the shared LAN host—exactly the secret-handling path [`SECURITY.md`](../../SECURITY.md) and the suggestion form try to avoid.

This is distinct from:

- Stage 32 `openwebui-signup-first-user-contract.md` (who can create accounts)
- Stage 34 `openwebui-api-keys-endpoint-contract.md` (Open WebUI’s own API keys)
- Stage 33 `openwebui-offline-embeddings-contract.md` (HuggingFace/offline models)
- Stage 37 password-validation page (password floor, not provider keys)
- Ollama / `OLLAMA_BASE_URL` already on the service (server-side local models)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Open WebUI hardening | `ENABLE_DIRECT_CONNECTIONS=false`; keys hit the backend |
| `open-webui` environment | Flag unset (default false, not pinned) |
| `OLLAMA_BASE_URL` | Existing local model path |
| Stage 36 PersistentConfig (expected sibling) | Stops Admin UI from enabling this silently |
| GitHub Issues + SECURITY.md | How extra providers should be requested |

Out of scope:

- A custom “BYO key” proxy on the helper API
- Rewriting Stage 34 Open WebUI API-key endpoints
- Disabling Ollama or OpenAI-*compatible local routers that admins configure in Compose
- Inventing `TU_VM_WEBUI_NO_BYO_KEYS`

## Proposal

Pin the official flag on the `open-webui` service:

```text
ENABLE_DIRECT_CONNECTIONS: "false"
```

Server-side providers stay Compose/Admin-maintainer owned (Ollama today). Personal cloud keys stay off the shared host.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | Official flag false (pinned) |
| Env schema | `env.example` | Comment that BYO provider keys are off |
| Docs | Open WebUI playbook | Point extra-provider requests at Issues |
| Code (related) | Stage 36 store honesty | So Admin UI cannot flip this |

### Rules

1. **Official key only.** Match Open WebUI hardening spelling.
2. **Pin the default.** Unset is not the same as reviewed-false.
3. **Do not confuse with Stage 34 API keys.** Those are Open WebUI tokens, not upstream provider keys.
4. **Do not add a key-proxy sidecar.**
5. **GitHub remains intake.** Extra server-side providers stay Issues / PRs.

### Suggested contributor checklist

```text
1. Confirm the pinned Open WebUI image documents ENABLE_DIRECT_CONNECTIONS
2. Pin the flag false on the open-webui service
3. Recreate Open WebUI and confirm user BYO-connection UI is absent
4. Implement Stage 36 ENABLE_PERSISTENT_CONFIG=false so the pin sticks
5. Do not add a helper key-proxy or rewrite Stage 34 API-key pages
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Block BYO provider keys | Official `ENABLE_DIRECT_CONNECTIONS` | A custom proxy or CSS hide |
| Local models | Existing Ollama Compose wiring | Teaching users to paste cloud keys |
| Open WebUI API tokens | Stage 34 official flags | Mixing those with upstream keys |
| Env vs Admin UI | Stage 36 PersistentConfig **code** | A settings-sync sidecar |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line plus Stage 36 store honesty.
3. Missing BYO-connection UI is expected.

## Acceptance criteria

- [ ] `open-webui` sets `ENABLE_DIRECT_CONNECTIONS=false`.
- [ ] No key-proxy sidecar is added.
- [ ] Stage 34 API-key pages are not rewritten.

## Rollback

Set the flag `true` only after an accepted Issue that documents key handling. Recreate Open WebUI.

## Success metrics

- Recreating Open WebUI does not offer user-level provider-key fields.
- “Can I paste my OpenAI key?” questions cite Issues / SECURITY, not a new proxy.
